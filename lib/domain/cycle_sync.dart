// lib/domain/cycle_sync.dart
// Logika penghubung antara catatan harian (DayNote) & riwayat haid (PeriodLog). Murni Dart.
import 'cycle_engine.dart';
import 'day_note.dart';

/// Cari tanggal tes ovulasi positif (LH/BBT) terbaru pada siklus berjalan.
DateTime? latestConfirmedOvulation(List<PeriodLog> logs, Iterable<DayNote> notes) {
  if (logs.isEmpty) return null;
  var lastStart = dateOnly(logs.first.start);
  for (final l in logs.skip(1)) {
    final s = dateOnly(l.start);
    if (s.isAfter(lastStart)) lastStart = s;
  }

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
  for (final l in logs) {
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
  if (logs.isEmpty) return null;
  final d = dateOnly(date);
  final sorted = [...logs]..sort((a, b) => a.start.compareTo(b.start));
  for (final l in sorted.reversed) {
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
  if (logContainingDate(logs, date, defaultPeriodLen: defaultPeriodLen) != null) return false;
  final d = dateOnly(date);
  for (final l in logs) {
    final s = dateOnly(l.start);
    final diff = d.difference(s).inDays;
    if (diff >= 0 && diff < 15) return false; // masih siklus sama (<15 hari diabaikan engine)
    if (diff < 0 && diff > -4) return false; // terlalu dekat sebelum haid berikutnya
  }
  return true;
}
