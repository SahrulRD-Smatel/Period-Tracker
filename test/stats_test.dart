// test/stats_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mens_app/domain/cycle_engine.dart';
import 'package:mens_app/domain/stats.dart';

void main() {
  const engine = CycleEngine();
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);
  PeriodLog p(int m, int day, {int? endDay}) =>
      PeriodLog(start: d(m, day), end: endDay == null ? null : d(m, endDay));

  test('belum ada siklus bila haid tercatat < 2', () {
    expect(computeStats(engine, []).hasData, isFalse);
    expect(computeStats(engine, [p(1, 1)]).hasData, isFalse);
  });

  test('ringkasan, keteraturan, dan klasifikasi (satu siklus telat 1 minggu)', () {
    // panjang: 28, 28, 28, 35  -> median 28
    final s = computeStats(engine, [
      p(1, 1, endDay: 5),
      p(1, 29, endDay: 31),
      p(2, 26),
      p(3, 26),
      p(4, 30),
    ]);
    expect(s.cycles.map((c) => c.length).toList(), [28, 28, 28, 35]);
    expect(s.avgCycle, closeTo(29.75, 0.001));
    expect(s.minCycle, 28);
    expect(s.maxCycle, 35);
    expect(s.onTime, 3);
    expect(s.late, 1);
    expect(s.early, 0);
    expect(s.regularity, Regularity.regular); // rentang 7 hari
    expect(s.avgPeriod, closeTo(4, 0.001)); // (5 + 3) / 2
    expect(s.hasOutcomes, isTrue);
  });

  test('< 3 siklus: tidak ada klasifikasi', () {
    final s = computeStats(engine, [p(1, 1), p(1, 29), p(2, 26)]);
    expect(s.cycles.length, 2);
    expect(s.hasOutcomes, isFalse);
    expect(s.cycles.first.outcome, isNull);
    expect(s.regularity, Regularity.unknown);
  });

  test('selisih di luar 15..60 hari diabaikan', () {
    final s = computeStats(engine, [p(1, 1), p(1, 10)]); // 9 hari
    expect(s.hasData, isFalse);
  });
}
