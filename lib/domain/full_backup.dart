// lib/domain/full_backup.dart
// Cadangan lengkap (v2): riwayat haid + catatan harian + setelan.
// Juga bisa membaca cadangan v1 (hanya riwayat haid).
import 'dart:convert';

import 'app_settings.dart';
import 'backup.dart';
import 'cycle_engine.dart';
import 'day_note.dart';

const fullBackupVersion = 2;

class BackupData {
  final List<PeriodLog> periods;
  final List<DayNote> notes;
  final AppSettings? settings; // null untuk cadangan v1
  const BackupData(this.periods, this.notes, this.settings);
}

String exportFullBackup({
  required List<PeriodLog> periods,
  required List<DayNote> notes,
  required AppSettings settings,
}) =>
    jsonEncode({
      'version': fullBackupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'periods': [for (final l in periods) periodToJson(l)],
      'notes': [for (final n in notes) n.toJson()],
      'settings': settings.toJson(),
    });

/// Melempar [FormatException] bila teks bukan cadangan yang valid.
BackupData importFullBackup(String json) {
  try {
    final dynamic map = jsonDecode(json);
    if (map is! Map) throw const FormatException('Format cadangan tidak dikenali');
    final v = map['version'];
    if (v == backupVersion) return BackupData(importBackup(json), const [], null);
    if (v != fullBackupVersion || map['periods'] is! List) {
      throw const FormatException('Format cadangan tidak dikenali');
    }
    return BackupData(
      [for (final p in map['periods'] as List) periodFromJson(p as Map)],
      [for (final n in (map['notes'] as List? ?? const [])) DayNote.fromJson(n as Map)],
      map['settings'] is Map ? AppSettings.fromJson(map['settings'] as Map) : null,
    );
  } on TypeError {
    throw const FormatException('Isi cadangan rusak');
  }
}
