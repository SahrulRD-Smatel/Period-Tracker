// test/cycle_engine_test.dart
// Ganti `mens_app` dengan nama package di pubspec.yaml kamu.
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/cycle_engine.dart';

void main() {
  const engine = CycleEngine();
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);
  PeriodLog p(int m, int day) => PeriodLog(start: d(m, day));

  test('data minim -> pakai default 28 hari, ovulasi = haid berikutnya - 14', () {
    final r = engine.predict([p(1, 1)])!;
    expect(r.cycleLength, 28);
    expect(r.nextPeriod, d(1, 29));
    expect(r.current.ovulation, d(1, 15));
    expect(r.current.fertileStart, d(1, 10));
    expect(r.current.fertileEnd, d(1, 16));
    expect(r.confidence, Confidence.low);
  });

  test('siklus teratur 28 hari -> prediksi tepat, keyakinan naik', () {
    final r = engine.predict([p(1, 1), p(1, 29), p(2, 26), p(3, 26)])!;
    expect(r.cycleLength, 28);
    expect(r.nextPeriod, d(4, 23));
  });

  test('haid telat 1 minggu -> jadwal berikutnya ikut bergeser, panjang siklus tetap 28', () {
    // seharusnya 23 Apr, aktual 30 Apr (35 hari)
    final r = engine.predict([p(1, 1), p(1, 29), p(2, 26), p(3, 26), p(4, 30)])!;
    expect(r.cycleLength, 28); // median tahan terhadap 1 siklus telat
    expect(r.nextPeriod, d(5, 28)); // bukan 21 Mei -> ikut bergeser 1 minggu
  });

  test('ovulasi terkonfirmasi (tes LH) menggeser prediksi haid', () {
    final r = engine.predict([p(1, 1)], confirmedOvulation: d(1, 20))!;
    expect(r.ovulationConfirmed, isTrue);
    expect(r.current.ovulation, d(1, 20));
    expect(r.nextPeriod, d(2, 3));
  });

  test('tingkat keterlambatan', () {
    final r = engine.predict([p(1, 1)])!; // prediksi 29 Jan, margin 3 -> batas 1 Feb
    expect(engine.assessLateness(r, d(1, 29)), Lateness.none);
    expect(engine.assessLateness(r, d(1, 31)), Lateness.withinMargin);
    expect(engine.assessLateness(r, d(2, 3)), Lateness.late);
    expect(engine.assessLateness(r, d(2, 5)), Lateness.veryLate); // 7 hari
    expect(engine.assessLateness(r, d(4, 2)), Lateness.seeDoctor); // >= 90 hari
  });

  test('fase per hari', () {
    final r = engine.predict([p(1, 1)])!;
    DayInfo? at(int m, int day) => engine.infoOn(r, d(m, day), today: d(1, 10));
    expect(at(1, 3)!.phase, CyclePhase.menstrual);
    expect(at(1, 8)!.phase, CyclePhase.follicular);
    expect(at(1, 12)!.phase, CyclePhase.fertile);
    expect(at(1, 12)!.isFertile, isTrue);
    expect(at(1, 15)!.phase, CyclePhase.ovulation);
    expect(at(1, 20)!.phase, CyclePhase.luteal);
  });

  test('haid terlambat & belum dicatat -> hari lewat = delayed, masa depan = null', () {
    final r = engine.predict([p(1, 1)])!;
    expect(engine.infoOn(r, d(2, 3), today: d(2, 3))!.phase, CyclePhase.delayed);
    expect(engine.infoOn(r, d(2, 10), today: d(2, 3)), isNull);
  });

  test('klasifikasi siklus: cepat / tepat / telat', () {
    CycleOutcome c(int a) => engine.classifyCycle(actualLength: a, expectedLength: 28);
    expect(c(24), CycleOutcome.early);
    expect(c(28), CycleOutcome.onTime);
    expect(c(30), CycleOutcome.onTime);
    expect(c(35), CycleOutcome.late);
  });

  test('input ganda <15 hari digabungkan ke hari pertama episode & hormati end eksplisit', () {
    final merged = engine.predict([
      PeriodLog(start: d(11, 21)),
      PeriodLog(start: d(11, 25), end: d(11, 25)),
    ])!;
    expect(merged.lastPeriodStart, d(11, 21));
    expect(merged.current.periodEnd, d(11, 25));
    expect(engine.infoOn(merged, d(11, 25), today: d(11, 25))!.cycleDay, 5);
    expect(engine.infoOn(merged, d(11, 25), today: d(11, 25))!.phase, CyclePhase.menstrual);
    expect(engine.infoOn(merged, d(11, 26), today: d(11, 25))!.phase, CyclePhase.follicular);
  });
}
