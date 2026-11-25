// lib/application/data_actions.dart
// Aksi data lintas fitur: cadangan lengkap, pemulihan, hapus semua.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_settings.dart';
import '../domain/full_backup.dart';
import '../notifications/scheduler.dart';
import 'providers.dart';

String buildBackupJson(WidgetRef ref) => exportFullBackup(
      periods: ref.read(periodLogsProvider),
      notes: ref.read(notesProvider).values.toList(),
      settings: ref.read(settingsProvider),
      loveNotes: ref.read(loveNotesProvider),
      careCheckedIds: ref.read(careChecklistProvider).toList()..sort(),
    );

Future<void> restoreBackup(WidgetRef ref, BackupData d) async {
  await ref.read(periodLogsProvider.notifier).replaceAll(d.periods);
  await ref.read(notesProvider.notifier).replaceAll(d.notes);
  if (d.loveNotes.isNotEmpty) {
    await ref.read(loveNotesProvider.notifier).replaceAll(d.loveNotes);
  }
  if (d.careCheckedIds.isNotEmpty) {
    await ref.read(careChecklistProvider.notifier).replaceAll(d.careCheckedIds.toSet());
  }
  final AppSettings s = d.settings ?? ref.read(settingsProvider);
  await ref.read(settingsProvider.notifier).replace(s.copyWith(onboardingDone: true));

  final p = ref.read(predictionProvider);
  if (p != null && (s.remindPeriod || s.remindFertile)) {
    await NotificationScheduler.scheduleFromPrediction(p, s);
  } else {
    await NotificationScheduler.cancelAll();
  }
  await ref.read(partnerProvider.notifier).pushSnapshotIfOwner();
}

/// Menghapus semua data lokal & memutus tautan pasangan. Kembali ke onboarding.
Future<void> wipeAllData(WidgetRef ref) async {
  await ref.read(periodLogsProvider.notifier).replaceAll(const []);
  await ref.read(notesProvider.notifier).replaceAll(const []);
  await ref.read(loveNotesProvider.notifier).replaceAll(const []);
  await ref.read(careChecklistProvider.notifier).replaceAll(const {});
  await ref.read(partnerProvider.notifier).revoke();
  await ref.read(partnerProvider.notifier).resetLocalCache();
  await ref.read(appPinRepositoryProvider).clear();
  await ref.read(settingsProvider.notifier).replace(const AppSettings());
  await NotificationScheduler.cancelAll();
}
