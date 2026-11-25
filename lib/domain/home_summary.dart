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

/// Null bila tanggal [onDate] (atau [today]) sebelum haid terakhir atau di luar rentang yang dapat dihitung.
HomeSummary? summarizeHome(
  CycleEngine engine,
  CyclePrediction p,
  DateTime today, {
  DateTime? onDate,
}) {
  final t = dateOnly(today);
  final d = dateOnly(onDate ?? today);
  final info = engine.infoOn(p, d, today: t);
  if (info == null) return null;

  // Saat haid terlambat, ovulasi siklus ini tidak bisa diperkirakan -> sembunyikan.
  final overdue = t.isAfter(p.nextPeriod);
  final w = overdue ? null : p.upcomingFertileWindow(d);
  CycleWindow? winForDate;
  if (!overdue) {
    for (final cw in p.windows) {
      if (cw.contains(d)) {
        winForDate = cw;
        break;
      }
    }
  }
  final targetNextPeriod = winForDate?.nextPeriodStart ?? p.nextPeriod;

  var status = FertileStatus.unknown;
  var daysToFertile = 0;
  if (w != null) {
    if (d.isBefore(w.fertileStart)) {
      status = FertileStatus.upcoming;
      daysToFertile = w.fertileStart.difference(d).inDays;
    } else {
      status = FertileStatus.ongoing;
    }
  }

  return HomeSummary(
    cycleDay: info.cycleDay,
    phase: info.phase,
    daysUntilPeriod: overdue && !d.isBefore(p.nextPeriod)
        ? p.nextPeriod.difference(d).inDays
        : targetNextPeriod.difference(d).inDays,
    nextPeriod: targetNextPeriod,
    periodEarliest: targetNextPeriod.add(Duration(days: -p.marginDays)),
    periodLatest: targetNextPeriod.add(Duration(days: p.marginDays)),
    lateness: overdue && !d.isBefore(p.nextPeriod)
        ? engine.assessLateness(p, t)
        : Lateness.none,
    confidence: p.confidence,
    fertileStatus: status,
    daysUntilFertile: daysToFertile,
    fertileStart: w?.fertileStart,
    fertileEnd: w?.fertileEnd,
    ovulation: w?.ovulation,
  );
}
