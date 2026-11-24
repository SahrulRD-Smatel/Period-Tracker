// lib/domain/day_view.dart
// Apa yang ditampilkan kalender untuk satu tanggal. Murni Dart.
import 'cycle_engine.dart';

class DayView {
  final CyclePhase phase;
  final bool isFertile;
  final bool logged; // true = haid yang sudah tercatat/berlalu, false = prediksi
  final int? cycleDay;
  const DayView(this.phase, this.isFertile, this.logged, this.cycleDay);
}

/// Prioritas: (1) hari haid yang tercatat, (2) prediksi engine, (3) tidak ada info (null).
DayView? dayViewFor(
  DateTime date, {
  required CycleEngine engine,
  required List<PeriodLog> logs,
  required CyclePrediction? prediction,
  required DateTime today,
}) {
  final d = dateOnly(date), t = dateOnly(today);
  final periodLen = prediction?.periodLength ?? engine.s.defaultPeriodLength;

  for (final l in logs) {
    final s = dateOnly(l.start);
    final e = l.end != null ? dateOnly(l.end!) : s.add(Duration(days: periodLen - 1));
    if (!d.isBefore(s) && !d.isAfter(e)) {
      return DayView(CyclePhase.menstrual, false, !d.isAfter(t), d.difference(s).inDays + 1);
    }
  }

  if (prediction == null) return null;
  final info = engine.infoOn(prediction, d, today: t);
  if (info == null) return null;
  return DayView(info.phase, info.isFertile, false, info.cycleDay);
}
