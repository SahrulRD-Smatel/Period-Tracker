// lib/data/local_store.dart
// Penyimpanan setelan & catatan harian (SharedPreferences, JSON). Bisa diganti Drift nanti.
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/app_settings.dart';
import '../domain/day_note.dart';
import '../domain/love_notes.dart';

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
      _prefs.setString('${_key}_corrupt', raw); // jangan hilang diam-diam
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
      // Seed pesan cinta pertama kali
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
