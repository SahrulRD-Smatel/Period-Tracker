// test/day_view_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mens_app/domain/cycle_engine.dart';
import 'package:mens_app/domain/day_view.dart';

void main() {
  const engine = CycleEngine();
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);

  DayView? view(List<PeriodLog> logs, DateTime date, DateTime today) => dayViewFor(
        date,
        engine: engine,
        logs: logs,
        prediction: engine.predict(logs),
        today: today,
      );

  test('hari haid yang sudah berlalu = tercatat; prediksi haid berikutnya = bukan tercatat', () {
    final logs = [PeriodLog(start: d(1, 1))];
    expect(view(logs, d(1, 2), d(1, 10))!.logged, isTrue);
    final next = view(logs, d(1, 29), d(1, 10))!;
    expect(next.phase, CyclePhase.menstrual);
    expect(next.logged, isFalse);
  });

  test('ovulasi & masa subur dari prediksi', () {
    final logs = [PeriodLog(start: d(1, 1))];
    expect(view(logs, d(1, 15), d(1, 10))!.phase, CyclePhase.ovulation);
    expect(view(logs, d(1, 12), d(1, 10))!.isFertile, isTrue);
  });

  test('lama haid memakai tanggal selesai yang dicatat', () {
    final logs = [PeriodLog(start: d(1, 1), end: d(1, 3))];
    expect(view(logs, d(1, 3), d(1, 10))!.phase, CyclePhase.menstrual);
    expect(view(logs, d(1, 4), d(1, 10))!.phase, CyclePhase.follicular);
  });

  test('di luar data & prediksi -> null', () {
    final logs = [PeriodLog(start: d(1, 1))];
    expect(view(logs, DateTime.utc(2025, 12, 31), d(1, 10)), isNull);
    expect(view(logs, DateTime.utc(2026, 12, 25), d(1, 10)), isNull);
    expect(view([], d(1, 5), d(1, 10)), isNull);
  });
}
