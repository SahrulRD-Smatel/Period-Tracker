// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/local_store.dart';
import 'data/supabase_partner_repository.dart';
import 'notifications/scheduler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');

  try {
    await NotificationScheduler.init();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();

  // Inisialisasi sinkronisasi 2 HP (Supabase) otomatis bila sudah dikonfigurasi
  final serverConfig = PrefsServerConfigRepository(prefs).load();
  if (serverConfig.isConfigured) {
    try {
      await SupabaseService.connect(
        url: serverConfig.supabaseUrl,
        publishableKey: serverConfig.supabaseAnonKey,
      );
    } catch (_) {
      // Tetap lanjutkan aplikasi (offline-first); user bisa menyambung ulang di tab Pasangan
    }
  }

  runApp(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MensApp(),
    ),
  );
}
