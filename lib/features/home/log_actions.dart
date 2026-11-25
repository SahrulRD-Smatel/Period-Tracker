// lib/features/home/log_actions.dart
// Aksi pencatatan haid yang dipakai Beranda & Kalender.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/dialogs.dart';
import '../../core/formatters.dart';
import '../../domain/cycle_engine.dart';
import '../../domain/cycle_sync.dart';

Future<void> logPeriodStart(
  BuildContext context,
  WidgetRef ref,
  DateTime date, {
  bool confirmForwardShift = true,
}) async {
  final d = dateOnly(date);
  final logs = ref.read(periodLogsProvider);
  final existing = findSameEpisodeLog(logs, d);

  if (confirmForwardShift && existing != null && d.isAfter(existing.start)) {
    final dayNum = d.difference(existing.start).inDays + 1;
    final ok = await confirmDialog(
      context,
      title: 'Ubah hari pertama haid?',
      message:
          'Saat ini haid tercatat mulai ${fmtDayMonth(existing.start)} (hari ke-$dayNum). '
          'Yakin mau geser hari pertamanya ke ${fmtDayMonth(d)}?',
      confirmLabel: 'Geser ke ${fmtDayMonth(d)}',
    );
    if (!ok) return;
  }

  final res = await ref.read(periodLogsProvider.notifier).setOrUpdateStart(d);
  if (res.status != PeriodStartStatus.alreadyRecorded) {
    final today = ref.read(todayProvider);
    final selected = ref.read(selectedHomeDateProvider);
    if (selected.isBefore(d)) {
      ref.read(selectedHomeDateProvider.notifier).select(today);
    }
  }
  if (!context.mounted) return;
  final String msg;
  if (res.status == PeriodStartStatus.added) {
    msg = 'Tercatat: haid mulai ${fmtDayMonth(d)} 🎀';
  } else if (res.status == PeriodStartStatus.movedEpisode) {
    msg = res.previousStart != null
        ? 'Hari pertama haid diperbarui ke ${fmtDayMonth(d)} 🎀'
        : 'Hari pertama haid disinkronkan ke ${fmtDayMonth(d)} 🎀';
  } else {
    msg = 'Hari pertama haid sudah tercatat ${fmtDayMonth(d)}';
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}

Future<void> pickAndLogPeriodStart(BuildContext context, WidgetRef ref) async {
  final today = ref.read(todayProvider);
  final first = today.subtract(const Duration(days: 365));
  final logs = ref.read(periodLogsProvider);
  var initial = today;
  if (logs.isNotEmpty) {
    final latest = dateOnly(logs.last.start);
    if (!latest.isBefore(first) && !latest.isAfter(today) && today.difference(latest).inDays < 15) {
      initial = latest;
    }
  }

  final picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: today,
    helpText: 'Hari pertama haid',
  );
  if (picked == null || !context.mounted) return;
  // Pengguna eksplisit memilih "Hari pertama haid" dari kalender -> langsung terapkan ke episode aktif.
  await logPeriodStart(context, ref, picked, confirmForwardShift: false);
  ref.read(selectedHomeDateProvider.notifier).resetToToday();
}
