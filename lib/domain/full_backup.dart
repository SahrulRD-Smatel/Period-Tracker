// lib/domain/full_backup.dart
// Cadangan lengkap (v3): riwayat haid + catatan harian + setelan + surat cinta + checklist perhatian.
// Tetap kompatibel membaca cadangan v1 dan v2.
import 'dart:convert';

import 'app_settings.dart';
import 'backup.dart';
import 'cycle_engine.dart';
import 'day_note.dart';
import 'love_notes.dart';

const fullBackupVersion = 3;

class BackupData {
  final List<PeriodLog> periods;
  final List<DayNote> notes;
  final AppSettings? settings; // null untuk cadangan v1
  final List<LoveNote> loveNotes;
  final List<String> careCheckedIds;
  const BackupData(
    this.periods,
    this.notes,
    this.settings, {
    this.loveNotes = const [],
    this.careCheckedIds = const [],
  });
}

String exportFullBackup({
  required List<PeriodLog> periods,
  required List<DayNote> notes,
  required AppSettings settings,
  List<LoveNote> loveNotes = const [],
  List<String> careCheckedIds = const [],
}) =>
    jsonEncode({
      'version': fullBackupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'periods': [for (final l in periods) periodToJson(l)],
      'notes': [for (final n in notes) n.toJson()],
      'settings': settings.toJson(),
      'loveNotes': [for (final ln in loveNotes) ln.toJson()],
      'careCheckedIds': careCheckedIds,
    });

/// Melempar [FormatException] bila teks bukan cadangan yang valid.
BackupData importFullBackup(String json) {
  try {
    final dynamic map = jsonDecode(json);
    if (map is! Map) throw const FormatException('Format cadangan tidak dikenali');
    final v = map['version'];
    if (v == backupVersion) return BackupData(importBackup(json), const [], null);
    if ((v != 2 && v != fullBackupVersion) || map['periods'] is! List) {
      throw const FormatException('Format cadangan tidak dikenali');
    }
    return BackupData(
      [for (final p in map['periods'] as List) periodFromJson(p as Map)],
      [for (final n in (map['notes'] as List? ?? const [])) DayNote.fromJson(n as Map)],
      map['settings'] is Map ? AppSettings.fromJson(map['settings'] as Map) : null,
      loveNotes: [for (final ln in (map['loveNotes'] as List? ?? const [])) LoveNote.fromJson(ln as Map)],
      careCheckedIds: [for (final id in (map['careCheckedIds'] as List? ?? const [])) id as String],
    );
  } on TypeError {
    throw const FormatException('Isi cadangan rusak');
  }
}
