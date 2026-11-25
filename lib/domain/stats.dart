// lib/domain/stats.dart
// Statistik riwayat siklus + ringkasan gejala/mood untuk layar Statistik. Murni Dart.
import 'cycle_engine.dart';
import 'day_note.dart';

enum Regularity { unknown, regular, varied, irregular }

class CycleRecord {
  final DateTime start;
  final int length;
  final int? periodLength;
  final CycleOutcome? outcome; // null bila data belum cukup (< 3 siklus)
  const CycleRecord(this.start, this.length, this.periodLength, this.outcome);
}

class TagCount {
  final String id;
  final int count;
  const TagCount(this.id, this.count);
}

class CycleStats {
  final List<CycleRecord> cycles; // terlama -> terbaru
  final double? avgCycle;
  final int? minCycle, maxCycle;
  final double? avgPeriod;
  final int onTime, early, late;
  final Regularity regularity;
  final List<TagCount> topSymptoms;
  final List<TagCount> topMoods;
  final int totalNotes;

  const CycleStats({
    this.cycles = const [],
    this.avgCycle,
    this.minCycle,
    this.maxCycle,
    this.avgPeriod,
    this.onTime = 0,
    this.early = 0,
    this.late = 0,
    this.regularity = Regularity.unknown,
    this.topSymptoms = const [],
    this.topMoods = const [],
    this.totalNotes = 0,
  });

  bool get hasData => cycles.isNotEmpty;
  bool get hasOutcomes => cycles.length >= 3;
}

class _Raw {
  final DateTime start;
  final int len;
  final int? period;
  const _Raw(this.start, this.len, this.period);
}

List<TagCount> _topTags(Iterable<Iterable<String>> groups, {int limit = 5}) {
  final counts = <String, int>{};
  for (final g in groups) {
    for (final id in g) {
      counts[id] = (counts[id] ?? 0) + 1;
    }
  }
  final list = [for (final e in counts.entries) TagCount(e.key, e.value)]
    ..sort((a, b) => b.count != a.count ? b.count.compareTo(a.count) : a.id.compareTo(b.id));
  return list.length > limit ? list.sublist(0, limit) : list;
}

/// Hanya siklus dengan panjang 15..60 hari yang dihitung (sama seperti engine).
/// "Tepat waktu / cepat / terlambat" dibandingkan dengan median seluruh siklus, margin 2 hari.
CycleStats computeStats(
  CycleEngine engine,
  List<PeriodLog> logs, {
  List<DayNote> notes = const [],
}) {
  final topSymptoms = _topTags(notes.map((n) => n.symptoms));
  final topMoods = _topTags(notes.map((n) => n.moods));
  final totalNotes = notes.where((n) => !n.isEmpty).length;

  final byStart = <DateTime, PeriodLog>{};
  for (final l in logs) {
    byStart[dateOnly(l.start)] = l;
  }
  final starts = byStart.keys.toList()..sort();

  final raws = <_Raw>[];
  for (var i = 1; i < starts.length; i++) {
    final len = starts[i].difference(starts[i - 1]).inDays;
    if (len < 15 || len > 60) continue;
    raws.add(_Raw(starts[i - 1], len, byStart[starts[i - 1]]!.length));
  }

  final periodLens = <int>[];
  for (final l in byStart.values) {
    final n = l.length;
    if (n != null && n >= 1 && n <= 10) periodLens.add(n);
  }
  final avgPeriod =
      periodLens.isEmpty ? null : periodLens.reduce((a, b) => a + b) / periodLens.length;

  if (raws.isEmpty) {
    return CycleStats(
      avgPeriod: avgPeriod,
      topSymptoms: topSymptoms,
      topMoods: topMoods,
      totalNotes: totalNotes,
    );
  }

  final lengths = raws.map((r) => r.len).toList();
  final sorted = [...lengths]..sort();
  final mid = sorted.length ~/ 2;
  final double median =
      sorted.length.isOdd ? sorted[mid].toDouble() : (sorted[mid - 1] + sorted[mid]) / 2;
  final expected = median.round();
  final enough = raws.length >= 3;

  var onTime = 0, early = 0, late = 0;
  final cycles = <CycleRecord>[];
  for (final r in raws) {
    CycleOutcome? o;
    if (enough) {
      o = engine.classifyCycle(actualLength: r.len, expectedLength: expected);
      switch (o) {
        case CycleOutcome.onTime:
          onTime++;
        case CycleOutcome.early:
          early++;
        case CycleOutcome.late:
          late++;
      }
    }
    cycles.add(CycleRecord(r.start, r.len, r.period, o));
  }

  final minC = sorted.first, maxC = sorted.last;
  final range = maxC - minC;
  final regularity = !enough
      ? Regularity.unknown
      : range <= 7
          ? Regularity.regular
          : range <= 14
              ? Regularity.varied
              : Regularity.irregular;

  return CycleStats(
    cycles: cycles,
    avgCycle: lengths.reduce((a, b) => a + b) / lengths.length,
    minCycle: minC,
    maxCycle: maxC,
    avgPeriod: avgPeriod,
    onTime: onTime,
    early: early,
    late: late,
    regularity: regularity,
    topSymptoms: topSymptoms,
    topMoods: topMoods,
    totalNotes: totalNotes,
  );
}
