// lib/domain/backup.dart
// Ekspor / impor riwayat haid (format v1) + helper tanggal & JSON yang dipakai berkas lain.
// Untuk cadangan lengkap (catatan harian + setelan) lihat full_backup.dart (v2).
import 'dart:convert';

import 'cycle_engine.dart';

const backupVersion = 1;

/// 'yyyy-MM-dd' dari tanggal (UTC, tanpa jam).
String isoDate(DateTime d) => dateOnly(d).toIso8601String().substring(0, 10);

/// Kebalikan [isoDate]; hasilnya selalu tanggal UTC tanpa jam.
DateTime parseIsoDate(String s) => dateOnly(DateTime.parse(s));

Map<String, dynamic> periodToJson(PeriodLog l) => {
      'start': isoDate(l.start),
      if (l.end != null) 'end': isoDate(l.end!),
    };

PeriodLog periodFromJson(Map<dynamic, dynamic> p) => PeriodLog(
      start: parseIsoDate(p['start'] as String),
      end: p['end'] == null ? null : parseIsoDate(p['end'] as String),
    );

String exportBackup(List<PeriodLog> logs) => jsonEncode({
      'version': backupVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'periods': [for (final l in logs) periodToJson(l)],
    });

/// Melempar [FormatException] bila berkas bukan cadangan yang valid / versinya tak dikenal.
List<PeriodLog> importBackup(String json) {
  final dynamic map = jsonDecode(json);
  if (map is! Map || map['version'] != backupVersion || map['periods'] is! List) {
    throw const FormatException('Format cadangan tidak dikenali');
  }
  return [for (final p in map['periods'] as List) periodFromJson(p as Map)];
}
