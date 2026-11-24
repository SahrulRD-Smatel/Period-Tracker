// lib/data/cycle_repository.dart
// Penyimpanan riwayat haid. Saat ini: SharedPreferences (JSON berversi dari backup.dart).
// Nanti bisa diganti Drift/SQLite dengan mengimplementasi interface yang sama.
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/backup.dart';
import '../domain/cycle_engine.dart';

abstract class CycleRepository {
  List<PeriodLog> load();
  Future<void> save(List<PeriodLog> logs);
}

class PrefsCycleRepository implements CycleRepository {
  static const _key = 'period_logs_v1';
  final SharedPreferences _prefs;
  PrefsCycleRepository(this._prefs);

  @override
  List<PeriodLog> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return importBackup(raw);
    } catch (_) {
      // Data rusak: simpan salinannya supaya tidak hilang diam-diam, lalu mulai kosong.
      _prefs.setString('${_key}_corrupt', raw);
      return [];
    }
  }

  @override
  Future<void> save(List<PeriodLog> logs) => _prefs.setString(_key, exportBackup(logs));
}
