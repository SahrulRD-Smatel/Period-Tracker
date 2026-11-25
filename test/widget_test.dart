// test/widget_test.dart
// Smoke test: onboarding -> Beranda Cyra -> semua tab bisa dibuka -> alur pasangan & persistensi.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:period_tracker/app.dart';
import 'package:period_tracker/application/providers.dart';
import 'package:period_tracker/domain/app_settings.dart';
import 'package:period_tracker/domain/backup.dart';
import 'package:period_tracker/domain/cycle_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpApp(WidgetTester tester, Map<String, Object> prefsValues) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      child: const MensApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> openTab(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip(label));
  await tester.pumpAndSettle();
}

final _settingsDone = jsonEncode(const AppSettings(onboardingDone: true).toJson());

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('pengguna baru melihat onboarding lalu masuk ke Beranda', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(tester, {});
    expect(find.text('Selamat datang di Siklusku'), findsOneWidget);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
    }
    expect(find.text('Siap!'), findsOneWidget);

    await tester.tap(find.text('Mulai'));
    await tester.pumpAndSettle();
    expect(find.text('Catat haid terakhir'), findsOneWidget);
  });

  testWidgets('dengan data: Beranda menampilkan ring Cyra, aksi, dan semua tab bisa dibuka', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final today = dateOnly(DateTime.now());
    final logs = exportBackup([PeriodLog(start: today.subtract(const Duration(days: 9)))]);
    await pumpApp(tester, {'period_logs_v1': logs, 'app_settings_v1': _settingsDone});

    expect(find.text('Ovulasi dalam'), findsOneWidget); // hari ke-10 -> ovulasi 5 hari lagi
    expect(find.text('Haid mulai'), findsOneWidget);

    await openTab(tester, 'Kalender');
    expect(find.text('Warna menunjukkan fase siklusmu'), findsOneWidget);

    await openTab(tester, 'Statistik');
    expect(find.text('Pola siklusmu dari waktu ke waktu'), findsOneWidget);
    expect(find.text('Belum ada statistik'), findsOneWidget);

    await openTab(tester, 'Pasangan');
    expect(find.text('Buat kode undangan'), findsOneWidget);

    await openTab(tester, 'Setelan');
    expect(find.text('Atur siklus, pengingat, dan datamu'), findsOneWidget);
  });

  testWidgets('saat haid hari ke-1: cincin menampilkan Hari haid ke- bukan Ovulasi dalam', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final today = dateOnly(DateTime.now());
    final logs = exportBackup([PeriodLog(start: today)]);
    await pumpApp(tester, {'period_logs_v1': logs, 'app_settings_v1': _settingsDone});

    expect(find.text('Hari haid ke-'), findsOneWidget);
    expect(find.text('Menstruasi'), findsOneWidget);
  });

  testWidgets('alur pasangan (demo): buat kode, tersambung, dan bertahan saat pindah tab', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(tester, {'app_settings_v1': _settingsDone});
    await openTab(tester, 'Pasangan');

    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat kode undangan'));
    await tester.pumpAndSettle();
    expect(find.text('Kode undanganmu'), findsOneWidget);

    final demoButton = find.text('Demo: anggap pasangan sudah menerima');
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pumpAndSettle();
    expect(find.text('Terhubung dengan Pasangan 💞'), findsOneWidget);

    // Pindah tab lalu kembali -> status tersambung TIDAK hilang
    await openTab(tester, 'Beranda');
    await openTab(tester, 'Pasangan');
    expect(find.text('Terhubung dengan Pasangan 💞'), findsOneWidget);
  });
}
