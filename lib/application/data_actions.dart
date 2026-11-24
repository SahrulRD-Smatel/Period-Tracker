// lib/application/data_actions.dart
// Aksi data lintas fitur: cadangan, pemulihan, hapus semua.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_settings.dart';
import '../domain/full_backup.dart';
import 'providers.dart';

String buildBackupJson(WidgetRef ref) => exportFullBackup(
      periods: ref.read(periodLogsProvider),
      notes: ref.read(notesProvider).values.toList(),
      settings: ref.read(settingsProvider),
    );

Future<void> restoreBackup(WidgetRef ref, BackupData d) async {
  await ref.read(periodLogsProvider.notifier).replaceAll(d.periods);
  await ref.read(notesProvider.notifier).replaceAll(d.notes);
  final AppSettings s = d.settings ?? ref.read(settingsProvider);
  // onboardingDone = true: pengguna yang memulihkan data jelas bukan pengguna baru.
  await ref.read(settingsProvider.notifier).replace(s.copyWith(onboardingDone: true));
}

/// Menghapus semua data. Setelan dikembalikan ke default, sehingga aplikasi kembali ke onboarding.
/// Jangan memakai `ref`/`context` setelah fungsi ini selesai (layar pemanggil akan terlepas).
Future<void> wipeAllData(WidgetRef ref) async {
  await ref.read(periodLogsProvider.notifier).replaceAll(const []);
  await ref.read(notesProvider.notifier).replaceAll(const []);
  await ref.read(partnerProvider.notifier).revoke();
  await ref.read(settingsProvider.notifier).replace(const AppSettings());
}
