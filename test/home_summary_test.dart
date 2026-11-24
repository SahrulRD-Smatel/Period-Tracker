// test/home_summary_test.dart
// Ganti `mens_app` dengan nama package di pubspec.yaml kamu bila berbeda.
import 'package:flutter_test/flutter_test.dart';
import 'package:mens_app/domain/cycle_engine.dart';
import 'package:mens_app/domain/home_summary.dart';

void main() {
  const engine = CycleEngine();
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);
  final r = engine.predict([PeriodLog(start: d(1, 1))])!; // prediksi haid 29 Jan

  test('hari ke-N, fase, dan hitung mundur', () {
    final s = summarizeHome(engine, r, d(1, 10))!;
    expect(s.cycleDay, 10);
    expect(s.phase, CyclePhase.fertile);
    expect(s.daysUntilPeriod, 19);
    expect(s.lateness, Lateness.none);
    expect(s.fertileStatus, FertileStatus.ongoing);
  });

  test('masa subur akan datang (hitung mundur ke awal masa subur)', () {
    final s = summarizeHome(engine, r, d(1, 5))!;
    expect(s.phase, CyclePhase.menstrual);
    expect(s.fertileStatus, FertileStatus.upcoming);
    expect(s.daysUntilFertile, 5); // 10 Jan - 5 Jan
  });

  test('setelah masa subur lewat -> menunjuk ke masa subur siklus berikutnya', () {
    final s = summarizeHome(engine, r, d(1, 20))!;
    expect(s.phase, CyclePhase.luteal);
    expect(s.fertileStatus, FertileStatus.upcoming);
    expect(s.daysUntilFertile, 18); // 7 Feb - 20 Jan
  });

  test('haid terlambat: hari ke-N terus bertambah, masa subur disembunyikan', () {
    final s = summarizeHome(engine, r, d(2, 3))!;
    expect(s.cycleDay, 34);
    expect(s.phase, CyclePhase.delayed);
    expect(s.daysUntilPeriod, -5);
    expect(s.lateness, Lateness.late);
    expect(s.fertileStatus, FertileStatus.unknown);
  });

  test('tanggal sebelum haid terakhir -> null', () {
    expect(summarizeHome(engine, r, DateTime.utc(2025, 12, 31)), isNull);
  });
}
