// lib/domain/home_summary.dart
// Ringkasan untuk layar Beranda. Murni Dart (tanpa Flutter) agar mudah dites.
import 'cycle_engine.dart';

enum FertileStatus { upcoming, ongoing, unknown }

class HomeSummary {
  final int cycleDay; // hari ke-N sejak hari pertama haid terakhir (1-based)
  final CyclePhase phase;
  final int daysUntilPeriod; // >0 mendatang, 0 hari ini, <0 terlambat
  final DateTime nextPeriod, periodEarliest, periodLatest;
  final Lateness lateness;
  final Confidence confidence;
  final FertileStatus fertileStatus;
  final int daysUntilFertile; // hanya bermakna bila fertileStatus == upcoming
  final DateTime? fertileStart, fertileEnd, ovulation;

  const HomeSummary({
    required this.cycleDay,
    required this.phase,
    required this.daysUntilPeriod,
    required this.nextPeriod,
    required this.periodEarliest,
    required this.periodLatest,
    required this.lateness,
    required this.confidence,
    required this.fertileStatus,
    required this.daysUntilFertile,
    this.fertileStart,
    this.fertileEnd,
    this.ovulation,
  });
}

/// Null bila tanggal [today] sebelum haid terakhir yang tercatat (data tak masuk akal).
HomeSummary? summarizeHome(CycleEngine engine, CyclePrediction p, DateTime today) {
  final t = dateOnly(today);
  final info = engine.infoOn(p, t, today: t);
  if (info == null) return null;

  // Saat haid terlambat, ovulasi siklus ini tidak bisa diperkirakan -> sembunyikan.
  final overdue = t.isAfter(p.nextPeriod);
  final w = overdue ? null : p.upcomingFertileWindow(t);

  var status = FertileStatus.unknown;
  var daysToFertile = 0;
  if (w != null) {
    if (t.isBefore(w.fertileStart)) {
      status = FertileStatus.upcoming;
      daysToFertile = w.fertileStart.difference(t).inDays;
    } else {
      status = FertileStatus.ongoing;
    }
  }

  return HomeSummary(
    cycleDay: info.cycleDay,
    phase: info.phase,
    daysUntilPeriod: p.nextPeriod.difference(t).inDays,
    nextPeriod: p.nextPeriod,
    periodEarliest: p.nextPeriodEarliest,
    periodLatest: p.nextPeriodLatest,
    lateness: engine.assessLateness(p, t),
    confidence: p.confidence,
    fertileStatus: status,
    daysUntilFertile: daysToFertile,
    fertileStart: w?.fertileStart,
    fertileEnd: w?.fertileEnd,
    ovulation: w?.ovulation,
  );
}
