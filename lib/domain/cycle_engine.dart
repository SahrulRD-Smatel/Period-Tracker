// lib/domain/cycle_engine.dart
// Logika murni Dart (tanpa dependensi Flutter) -> mudah dites & dipakai ulang.
//
// Prinsip utama:
// 1. Prediksi SELALU dijangkarkan ke tanggal haid AKTUAL terakhir.
//    Jadi kalau haid telat 1 minggu, jadwal bulan depan otomatis ikut bergeser.
// 2. Panjang siklus dipelajari dari riwayat (median 6 siklus terakhir),
//    bukan dikunci 28 hari. Satu siklus telat tidak langsung merusak rata-rata.
// 3. Ovulasi dihitung MUNDUR dari haid berikutnya (fase luteal ~14 hari),
//    bukan "hari ke-14". Siklus 21 hari -> ovulasi ~hari ke-8, siklus 35 -> ~hari ke-22.
// 4. Hasilnya berupa RENTANG + tingkat keyakinan, bukan satu tanggal pasti.

import 'dart:math' as math;

enum CyclePhase { menstrual, follicular, fertile, ovulation, luteal, delayed }

enum Lateness { none, withinMargin, late, veryLate, seeDoctor }

enum CycleOutcome { early, onTime, late }

enum Confidence { low, medium, high }

/// Normalisasi ke tanggal saja (UTC) supaya aman dari masalah jam/DST.
DateTime dateOnly(DateTime d) => DateTime.utc(d.year, d.month, d.day);
DateTime _plus(DateTime d, int days) => d.add(Duration(days: days));

class CycleSettings {
  final int defaultCycleLength; // dipakai saat data belum cukup
  final int defaultPeriodLength;
  final int lutealLength; // ovulasi -> haid berikutnya (relatif stabil, ~12-16)
  const CycleSettings({
    this.defaultCycleLength = 28,
    this.defaultPeriodLength = 5,
    this.lutealLength = 14,
  });
}

class PeriodLog {
  final DateTime start;
  final DateTime? end;
  const PeriodLog({required this.start, this.end});

  int? get length =>
      end == null ? null : dateOnly(end!).difference(dateOnly(start)).inDays + 1;
}

class DayInfo {
  final CyclePhase phase;
  final int cycleDay;
  final bool isFertile; // bisa true bersamaan dengan fase menstrual (siklus pendek)
  const DayInfo(this.phase, this.cycleDay, this.isFertile);
}

/// Satu siklus (dari hari pertama haid sampai sehari sebelum haid berikutnya).
class CycleWindow {
  final DateTime periodStart, periodEnd, nextPeriodStart;
  final DateTime ovulation, fertileStart, fertileEnd;
  const CycleWindow({
    required this.periodStart,
    required this.periodEnd,
    required this.nextPeriodStart,
    required this.ovulation,
    required this.fertileStart,
    required this.fertileEnd,
  });

  bool _in(DateTime d, DateTime a, DateTime b) => !d.isBefore(a) && !d.isAfter(b);

  bool contains(DateTime d) => !d.isBefore(periodStart) && d.isBefore(nextPeriodStart);
  bool isFertile(DateTime d) => _in(d, fertileStart, fertileEnd);

  CyclePhase phaseOf(DateTime d) {
    if (_in(d, periodStart, periodEnd)) return CyclePhase.menstrual;
    if (d == ovulation) return CyclePhase.ovulation;
    if (isFertile(d)) return CyclePhase.fertile;
    if (d.isBefore(fertileStart)) return CyclePhase.follicular;
    return CyclePhase.luteal;
  }
}

class CyclePrediction {
  final DateTime lastPeriodStart;
  final int cycleLength, periodLength, marginDays;
  final Confidence confidence;
  final bool ovulationConfirmed;
  final List<CycleWindow> windows; // [siklus berjalan, siklus-siklus berikutnya...]

  const CyclePrediction({
    required this.lastPeriodStart,
    required this.cycleLength,
    required this.periodLength,
    required this.marginDays,
    required this.confidence,
    required this.ovulationConfirmed,
    required this.windows,
  });

  CycleWindow get current => windows.first;
  DateTime get nextPeriod => current.nextPeriodStart;
  DateTime get nextPeriodEarliest => _plus(nextPeriod, -marginDays);
  DateTime get nextPeriodLatest => _plus(nextPeriod, marginDays);

  /// Jendela subur terdekat yang belum lewat (untuk ditampilkan / dibagikan ke pasangan).
  CycleWindow? upcomingFertileWindow(DateTime today) {
    final t = dateOnly(today);
    for (final w in windows) {
      if (!w.fertileEnd.isBefore(t)) return w;
    }
    return null;
  }
}

/// Menggabungkan input ganda dalam episode haid yang sama (< [minGapDays] hari).
/// Setiap episode memakai tanggal mulai paling awal dan tanggal selesai terjauh yang valid.
List<PeriodLog> normalizePeriodLogs(List<PeriodLog> logs, {int minGapDays = 15}) {
  if (logs.isEmpty) return const [];
  final sorted = [
    for (final l in logs)
      PeriodLog(
        start: dateOnly(l.start),
        end: l.end == null || dateOnly(l.end!).isBefore(dateOnly(l.start))
            ? null
            : dateOnly(l.end!),
      ),
  ]..sort((a, b) => a.start.compareTo(b.start));

  final out = <PeriodLog>[];
  var groupStart = sorted.first.start;
  var groupEnd = sorted.first.end;

  for (final l in sorted.skip(1)) {
    if (l.start.difference(groupStart).inDays < minGapDays) {
      if (l.end != null) {
        if (groupEnd == null || l.end!.isAfter(groupEnd)) groupEnd = l.end;
      } else if (groupEnd != null && l.start.isAfter(groupEnd)) {
        // Ada catatan mulai baru setelah tanggal selesai di episode yang sama tanpa tanggal selesai.
        groupEnd = null;
      }
    } else {
      out.add(PeriodLog(start: groupStart, end: groupEnd));
      groupStart = l.start;
      groupEnd = l.end;
    }
  }
  out.add(PeriodLog(start: groupStart, end: groupEnd));
  return out;
}

class CycleEngine {
  final CycleSettings s;
  const CycleEngine([this.s = const CycleSettings()]);

  List<DateTime> _starts(List<PeriodLog> logs) =>
      [for (final l in normalizePeriodLogs(logs)) l.start];

  /// Jarak antar hari pertama haid berurutan.
  /// <15 hari  = kemungkinan spotting / input ganda  -> diabaikan
  /// >60 hari  = kemungkinan ada haid yang tak tercatat -> diabaikan
  List<int> cycleLengths(List<PeriodLog> logs) {
    final st = _starts(logs);
    final out = <int>[];
    for (var i = 1; i < st.length; i++) {
      final len = st[i].difference(st[i - 1]).inDays;
      if (len >= 15 && len <= 60) out.add(len);
    }
    return out;
  }

  /// Median 6 siklus terakhir (tahan terhadap 1 siklus yang telat/maju).
  /// Data < 3 siklus dicampur dengan nilai default.
  int estimateCycleLength(List<int> lengths) {
    final recent = lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    if (recent.isEmpty) return s.defaultCycleLength;
    if (recent.length < 3) {
      final sum = recent.fold<int>(0, (a, b) => a + b) +
          s.defaultCycleLength * (3 - recent.length);
      return (sum / 3).round();
    }
    final sorted = [...recent]..sort();
    final mid = sorted.length ~/ 2;
    final double median =
        sorted.length.isOdd ? sorted[mid].toDouble() : (sorted[mid - 1] + sorted[mid]) / 2;
    return median.round();
  }

  int estimatePeriodLength(List<PeriodLog> logs) {
    final sorted = [...logs]..sort((a, b) => a.start.compareTo(b.start));
    final ls = <int>[];
    for (final l in sorted) {
      final n = l.length;
      if (n != null && n >= 1 && n <= 10) ls.add(n);
    }
    if (ls.isEmpty) return s.defaultPeriodLength;
    final recent = ls.length > 6 ? ls.sublist(ls.length - 6) : ls;
    return (recent.reduce((a, b) => a + b) / recent.length).round();
  }

  double _stdDev(List<int> xs) {
    if (xs.length < 2) return 0;
    final mean = xs.reduce((a, b) => a + b) / xs.length;
    final v = xs.map((x) => math.pow(x - mean, 2)).reduce((a, b) => a + b) / xs.length;
    return math.sqrt(v);
  }

  /// [confirmedOvulation]: tanggal ovulasi hasil tes LH / suhu basal tubuh (opsional).
  /// Kalau ada, prediksi haid berikutnya dihitung dari situ -> jauh lebih akurat,
  /// terutama saat siklus sedang mundur.
  CyclePrediction? predict(
    List<PeriodLog> logs, {
    DateTime? confirmedOvulation,
    int monthsAhead = 3,
  }) {
    final clean = normalizePeriodLogs(logs);
    if (clean.isEmpty) return null;

    final lastLog = clean.last;
    final last = lastLog.start;
    final lengths = cycleLengths(clean);
    final recent = lengths.length > 6 ? lengths.sublist(lengths.length - 6) : lengths;
    final cycleLen = estimateCycleLength(lengths);
    final periodLen = estimatePeriodLength(clean);
    final sd = _stdDev(recent);

    var margin = recent.length < 3 ? 3 : math.min(7, math.max(2, sd.ceil()));
    final confidence = (recent.length >= 6 && sd <= 2)
        ? Confidence.high
        : (recent.length >= 3 && sd <= 4)
            ? Confidence.medium
            : Confidence.low;

    var next = _plus(last, cycleLen);
    var ovulation = _plus(next, -s.lutealLength);
    var confirmed = false;
    final co = confirmedOvulation == null ? null : dateOnly(confirmedOvulation);
    if (co != null && !co.isBefore(last)) {
      ovulation = co;
      next = _plus(co, s.lutealLength);
      confirmed = true;
      margin = 2;
    }

    final currentPeriodEnd = (lastLog.end != null && !lastLog.end!.isBefore(last))
        ? (lastLog.end!.isBefore(next) ? lastLog.end! : _plus(next, -1))
        : null;
    final windows = <CycleWindow>[
      _window(last, next, ovulation, periodLen, explicitPeriodEnd: currentPeriodEnd),
    ];
    final horizon = _plus(next, monthsAhead * 31);
    var start = next;
    while (start.isBefore(horizon)) {
      final nextStart = _plus(start, cycleLen);
      windows.add(_window(start, nextStart, _plus(nextStart, -s.lutealLength), periodLen));
      start = nextStart;
    }

    return CyclePrediction(
      lastPeriodStart: last,
      cycleLength: cycleLen,
      periodLength: periodLen,
      marginDays: margin,
      confidence: confidence,
      ovulationConfirmed: confirmed,
      windows: windows,
    );
  }

  CycleWindow _window(
    DateTime start,
    DateTime next,
    DateTime ov,
    int periodLen, {
    DateTime? explicitPeriodEnd,
  }) =>
      CycleWindow(
        periodStart: start,
        periodEnd: explicitPeriodEnd ?? _plus(start, periodLen - 1),
        nextPeriodStart: next,
        ovulation: ov,
        fertileStart: _plus(ov, -5), // sperma bertahan hingga ~5 hari
        fertileEnd: _plus(ov, 1), // sel telur ~12-24 jam
      );

  /// Status keterlambatan saat haid belum dicatat.
  Lateness assessLateness(CyclePrediction p, DateTime today) {
    final t = dateOnly(today);
    if (t.difference(p.lastPeriodStart).inDays >= 90) return Lateness.seeDoctor;
    final daysLate = t.difference(p.nextPeriod).inDays;
    if (daysLate >= 7) return Lateness.veryLate; // anjurkan tes kehamilan / cek penyebab
    if (t.isAfter(p.nextPeriodLatest)) return Lateness.late;
    if (daysLate > 0) return Lateness.withinMargin;
    return Lateness.none;
  }

  /// Info satu hari untuk kalender / kartu "hari ini".
  /// Kalau haid sudah lewat dari prediksi dan belum dicatat, hari-hari setelahnya
  /// ditandai `delayed`, dan masa depan dianggap belum diketahui (null)
  /// sampai pengguna mencatat haid yang sebenarnya.
  DayInfo? infoOn(CyclePrediction p, DateTime date, {required DateTime today}) {
    final d = dateOnly(date), t = dateOnly(today);
    if (d.isBefore(p.lastPeriodStart)) return null;

    final overdue = t.isAfter(p.nextPeriod);
    if (overdue && !d.isBefore(p.nextPeriod)) {
      return d.isAfter(t)
          ? null
          : DayInfo(CyclePhase.delayed, d.difference(p.lastPeriodStart).inDays + 1, false);
    }
    for (final w in p.windows) {
      if (w.contains(d)) {
        return DayInfo(w.phaseOf(d), d.difference(w.periodStart).inDays + 1, w.isFertile(d));
      }
    }
    return null;
  }

  /// Klasifikasi siklus yang sudah selesai: lebih cepat / tepat waktu / terlambat.
  CycleOutcome classifyCycle({
    required int actualLength,
    required int expectedLength,
    int margin = 2,
  }) {
    final diff = actualLength - expectedLength;
    if (diff < -margin) return CycleOutcome.early;
    if (diff > margin) return CycleOutcome.late;
    return CycleOutcome.onTime;
  }
}
