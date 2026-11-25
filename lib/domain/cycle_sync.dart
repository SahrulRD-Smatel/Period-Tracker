// lib/domain/cycle_sync.dart
// Logika penghubung antara catatan harian (DayNote) & riwayat haid (PeriodLog). Murni Dart.
import 'cycle_engine.dart';
import 'day_note.dart';

enum PeriodStartStatus { added, movedEpisode, alreadyRecorded }

bool _sameLogs(List<PeriodLog> a, List<PeriodLog> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final ae = a[i].end == null ? null : dateOnly(a[i].end!);
    final be = b[i].end == null ? null : dateOnly(b[i].end!);
    if (dateOnly(a[i].start) != dateOnly(b[i].start) || ae != be) return false;
  }
  return true;
}

/// Cari PeriodLog dalam episode haid yang sama (< [minGapDays] dari [date]).
PeriodLog? findSameEpisodeLog(
  List<PeriodLog> logs,
  DateTime date, {
  int minGapDays = 15,
}) {
  final d = dateOnly(date);
  final clean = normalizePeriodLogs(logs, minGapDays: minGapDays);
  PeriodLog? best;
  var bestDiff = minGapDays;
  for (final l in clean) {
    final diff = d.difference(l.start).inDays.abs();
    if (diff < bestDiff) {
      bestDiff = diff;
      best = l;
    }
  }
  return best;
}

/// Mengatur hari pertama haid ke [date]. Bila ada log di episode yang sama (< [minGapDays] hari),
/// tanggal mulainya digeser ke [date] tanpa menciptakan siklus ganda yang merusak hitungan hari ke-N.
({List<PeriodLog> logs, PeriodStartStatus status, DateTime? previousStart}) setPeriodStart(
  List<PeriodLog> logs,
  DateTime date, {
  int minGapDays = 15,
}) {
  final d = dateOnly(date);
  final clean = normalizePeriodLogs(logs, minGapDays: minGapDays);
  final hadDuplicates = !_sameLogs(
    [...logs]..sort((a, b) => dateOnly(a.start).compareTo(dateOnly(b.start))),
    clean,
  );
  final same = findSameEpisodeLog(clean, d, minGapDays: minGapDays);
  if (same == null) {
    final next = normalizePeriodLogs([...clean, PeriodLog(start: d)], minGapDays: minGapDays);
    return (logs: next, status: PeriodStartStatus.added, previousStart: null);
  }
  if (same.start == d) {
    return (
      logs: clean,
      status: hadDuplicates ? PeriodStartStatus.movedEpisode : PeriodStartStatus.alreadyRecorded,
      previousStart: null,
    );
  }

  final preservedEnd =
      same.end != null && !same.end!.isBefore(d) ? same.end : null;
  final next = normalizePeriodLogs(
    [
      for (final l in clean)
        if (l.start == same.start) PeriodLog(start: d, end: preservedEnd) else l,
    ],
    minGapDays: minGapDays,
  );
  return (
    logs: next,
    status: PeriodStartStatus.movedEpisode,
    previousStart: same.start,
  );
}

/// Cari tanggal tes ovulasi positif (LH/BBT) terbaru pada siklus berjalan.
DateTime? latestConfirmedOvulation(List<PeriodLog> logs, Iterable<DayNote> notes) {
  final clean = normalizePeriodLogs(logs);
  if (clean.isEmpty) return null;
  final lastStart = clean.last.start;

  DateTime? latest;
  for (final n in notes) {
    if (!n.ovulationPositive) continue;
    final d = dateOnly(n.date);
    if (d.isBefore(lastStart)) continue;
    if (latest == null || d.isAfter(latest)) {
      latest = d;
    }
  }
  return latest;
}

/// Cari PeriodLog yang mencakup tanggal [date] (berdasarkan [end] atau [defaultPeriodLen]).
PeriodLog? logContainingDate(
  List<PeriodLog> logs,
  DateTime date, {
  int defaultPeriodLen = 5,
}) {
  final d = dateOnly(date);
  for (final l in normalizePeriodLogs(logs)) {
    final s = dateOnly(l.start);
    final e = l.end != null ? dateOnly(l.end!) : s.add(Duration(days: defaultPeriodLen - 1));
    if (!d.isBefore(s) && !d.isAfter(e)) return l;
  }
  return null;
}

/// Cari haid aktif yang belum ditandai selesai (masih dalam rentang wajar < [maxDays]).
PeriodLog? activeOpenPeriod(
  List<PeriodLog> logs,
  DateTime date, {
  int maxDays = 10,
}) {
  final clean = normalizePeriodLogs(logs);
  if (clean.isEmpty) return null;
  final d = dateOnly(date);
  for (final l in clean.reversed) {
    final s = dateOnly(l.start);
    if (!d.isBefore(s) && d.difference(s).inDays < maxDays) {
      return l.end == null ? l : null;
    }
  }
  return null;
}

/// Apakah pencatatan aliran haid pada [date] layak ditawarkan/otomatis dicatat sebagai awal haid baru.
bool shouldAutoStartPeriod(
  List<PeriodLog> logs,
  DateTime date,
  FlowLevel? flow, {
  int defaultPeriodLen = 5,
}) {
  if (flow == null || flow == FlowLevel.spotting) return false;
  final clean = normalizePeriodLogs(logs);
  if (logContainingDate(clean, date, defaultPeriodLen: defaultPeriodLen) != null) return false;
  final d = dateOnly(date);
  for (final l in clean) {
    final s = dateOnly(l.start);
    final diff = d.difference(s).inDays;
    if (diff >= 0 && diff < 15) return false; // masih siklus sama (<15 hari diabaikan engine)
    if (diff < 0 && diff > -4) return false; // terlalu dekat sebelum haid berikutnya
  }
  return true;
}
