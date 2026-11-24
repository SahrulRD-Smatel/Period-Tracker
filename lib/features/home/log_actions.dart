// lib/features/home/log_actions.dart
// Aksi pencatatan haid yang dipakai Beranda & Kalender.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/formatters.dart';

Future<void> logPeriodStart(BuildContext context, WidgetRef ref, DateTime date) async {
  final added = await ref.read(periodLogsProvider.notifier).addStart(date);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(added
          ? 'Tercatat: haid mulai ${fmtDayMonth(date)} 🎀'
          : 'Tanggal itu sudah tercatat'),
    ),
  );
}

Future<void> pickAndLogPeriodStart(BuildContext context, WidgetRef ref) async {
  final today = ref.read(todayProvider);
  final picked = await showDatePicker(
    context: context,
    initialDate: today,
    firstDate: today.subtract(const Duration(days: 365)),
    lastDate: today,
    helpText: 'Hari pertama haid',
  );
  if (picked == null || !context.mounted) return;
  await logPeriodStart(context, ref, picked);
}
