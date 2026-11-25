// lib/data/local_store.dart
// Penyimpanan lokal (SharedPreferences, JSON) untuk setelan, catatan harian,
// surat cinta, checklist perhatian, status pasangan, konfigurasi server, dan PIN kunci app.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/day_note.dart';
import '../domain/love_notes.dart';
import '../domain/partner_models.dart';

abstract class SettingsRepository {
  AppSettings load();
  Future<void> save(AppSettings s);
}

class PrefsSettingsRepository implements SettingsRepository {
  static const _key = 'app_settings_v1';
  final SharedPreferences _prefs;
  PrefsSettingsRepository(this._prefs);

  @override
  AppSettings load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map);
    } catch (_) {
      return const AppSettings();
    }
  }

  @override
  Future<void> save(AppSettings s) => _prefs.setString(_key, jsonEncode(s.toJson()));
}

abstract class NotesRepository {
  List<DayNote> load();
  Future<void> save(List<DayNote> notes);
}

class PrefsNotesRepository implements NotesRepository {
  static const _key = 'day_notes_v1';
  final SharedPreferences _prefs;
  PrefsNotesRepository(this._prefs);

  @override
  List<DayNote> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return [];
    try {
      return [for (final n in jsonDecode(raw) as List) DayNote.fromJson(n as Map)];
    } catch (_) {
      _prefs.setString('${_key}_corrupt', raw);
      return [];
    }
  }

  @override
  Future<void> save(List<DayNote> notes) =>
      _prefs.setString(_key, jsonEncode([for (final n in notes) n.toJson()]));
}

abstract class LoveNotesRepository {
  List<LoveNote> load();
  Future<void> save(List<LoveNote> notes);
}

class PrefsLoveNotesRepository implements LoveNotesRepository {
  static const _key = 'love_notes_v1';
  final SharedPreferences _prefs;
  PrefsLoveNotesRepository(this._prefs);

  @override
  List<LoveNote> load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return [
        LoveNote(
          id: 'seed_1',
          sender: 'Pasangan',
          message: 'Hai manis 🎀 Selamat datang di Siklusku. Di sini aku ingin kamu merasa '
              'selalu ditemani dan disayangi setiap hari, terutama saat tubuhmu lelah atau '
              'kram. Peluk hangat untukmu hari ini! 🥰',
          createdAt: DateTime.now(),
          isRead: false,
          trigger: LoveNoteTrigger.anytime,
        ),
      ];
    }
    try {
      return [for (final n in jsonDecode(raw) as List) LoveNote.fromJson(n as Map)];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<void> save(List<LoveNote> notes) =>
      _prefs.setString(_key, jsonEncode([for (final n in notes) n.toJson()]));
}

abstract class CareChecklistRepository {
  Set<String> load();
  Future<void> save(Set<String> ids);
}

class PrefsCareChecklistRepository implements CareChecklistRepository {
  static const _key = 'care_checked_v1';
  final SharedPreferences _prefs;
  PrefsCareChecklistRepository(this._prefs);

  @override
  Set<String> load() => (_prefs.getStringList(_key) ?? const []).toSet();

  @override
  Future<void> save(Set<String> ids) =>
      _prefs.setStringList(_key, ids.toList()..sort());
}

abstract class PartnerStateRepository {
  PartnerState load();
  Future<void> save(PartnerState state);
  Future<void> clear();
}

class PrefsPartnerStateRepository implements PartnerStateRepository {
  static const _key = 'partner_state_v1';
  final SharedPreferences _prefs;
  PrefsPartnerStateRepository(this._prefs);

  @override
  PartnerState load() {
    final raw = _prefs.getString(_key);
    if (raw == null) return const PartnerState();
    try {
      return PartnerState.fromJson(jsonDecode(raw) as Map);
    } catch (_) {
      return const PartnerState();
    }
  }

  @override
  Future<void> save(PartnerState state) =>
      _prefs.setString(_key, jsonEncode(state.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}

const kDefaultSupabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://cmkhribdlgcqmchommke.supabase.co',
);
const kDefaultSupabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'sb_publishable_PUWijKYNxCqhkOimuw0Vow_fX-yN5Aj',
);

class ServerConfig {
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String displayName;
  final bool cloudEnabled;

  const ServerConfig({
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.displayName = 'Pasangan',
    this.cloudEnabled = true,
  });

  bool get isConfigured =>
      cloudEnabled &&
      supabaseUrl.trim().startsWith('https://') &&
      supabaseAnonKey.trim().isNotEmpty;

  ServerConfig copyWith({
    String? supabaseUrl,
    String? supabaseAnonKey,
    String? displayName,
    bool? cloudEnabled,
  }) =>
      ServerConfig(
        supabaseUrl: supabaseUrl ?? this.supabaseUrl,
        supabaseAnonKey: supabaseAnonKey ?? this.supabaseAnonKey,
        displayName: displayName ?? this.displayName,
        cloudEnabled: cloudEnabled ?? this.cloudEnabled,
      );

  Map<String, dynamic> toJson() => {
        'supabaseUrl': supabaseUrl.trim(),
        'supabaseAnonKey': supabaseAnonKey.trim(),
        'displayName': displayName.trim().isEmpty ? 'Pasangan' : displayName.trim(),
        'cloudEnabled': cloudEnabled,
      };

  factory ServerConfig.fromJson(Map<dynamic, dynamic> j) => ServerConfig(
        supabaseUrl: (j['supabaseUrl'] as String?)?.trim() ?? '',
        supabaseAnonKey: (j['supabaseAnonKey'] as String?)?.trim() ?? '',
        displayName: (j['displayName'] as String?)?.trim().isNotEmpty == true
            ? (j['displayName'] as String).trim()
            : 'Pasangan',
        cloudEnabled: j['cloudEnabled'] as bool? ?? true,
      );
}

abstract class ServerConfigRepository {
  ServerConfig load();
  Future<void> save(ServerConfig config);
}

class PrefsServerConfigRepository implements ServerConfigRepository {
  static const _key = 'supabase_config_v1';
  final SharedPreferences _prefs;
  PrefsServerConfigRepository(this._prefs);

  @override
  ServerConfig load() {
    final raw = _prefs.getString(_key);
    if (raw == null) {
      return const ServerConfig(
        supabaseUrl: kDefaultSupabaseUrl,
        supabaseAnonKey: kDefaultSupabaseAnonKey,
        cloudEnabled: true,
      );
    }
    try {
      final parsed = ServerConfig.fromJson(jsonDecode(raw) as Map);
      if (parsed.cloudEnabled && !parsed.isConfigured && kDefaultSupabaseUrl.isNotEmpty) {
        return parsed.copyWith(
          supabaseUrl: kDefaultSupabaseUrl,
          supabaseAnonKey: kDefaultSupabaseAnonKey,
        );
      }
      return parsed;
    } catch (_) {
      return const ServerConfig(
        supabaseUrl: kDefaultSupabaseUrl,
        supabaseAnonKey: kDefaultSupabaseAnonKey,
        cloudEnabled: true,
      );
    }
  }

  @override
  Future<void> save(ServerConfig config) =>
      _prefs.setString(_key, jsonEncode(config.toJson()));
}

/// Penyimpan PIN 4-digit fallback lokal (di-hash agar tidak tersimpan polos).
class PrefsAppPinRepository {
  static const _key = 'app_lock_pin_v1';
  final SharedPreferences _prefs;
  PrefsAppPinRepository(this._prefs);

  static String _hash(String pin) {
    var h = 0x811c9dc5;
    for (final unit in 'siklusku_salt_$pin'.codeUnits) {
      h ^= unit;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  bool get hasPin => (_prefs.getString(_key) ?? '').isNotEmpty;

  bool verify(String pin) {
    final saved = _prefs.getString(_key);
    if (saved == null || saved.isEmpty) return false;
    return saved == _hash(pin);
  }

  Future<void> savePin(String pin) => _prefs.setString(_key, _hash(pin));

  Future<void> clear() => _prefs.remove(_key);
}
