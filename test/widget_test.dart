// test/widget_test.dart
// Smoke test: onboarding -> Beranda -> semua tab bisa dibuka.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mens_app/app.dart';
import 'package:mens_app/application/providers.dart';
import 'package:mens_app/domain/app_settings.dart';
import 'package:mens_app/domain/backup.dart';
import 'package:mens_app/domain/cycle_engine.dart';
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
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
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
    // onboarding selesai tanpa tanggal haid -> Beranda menampilkan keadaan kosong
    expect(find.text('Catat haid terakhir'), findsOneWidget);
  });

  testWidgets('dengan data: Beranda menampilkan Hari ke-N dan semua tab bisa dibuka', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final today = dateOnly(DateTime.now());
    final logs = exportBackup([PeriodLog(start: today.subtract(const Duration(days: 9)))]);
    await pumpApp(tester, {'period_logs_v1': logs, 'app_settings_v1': _settingsDone});

    expect(find.text('Hari ke-'), findsOneWidget);
    expect(find.text('Haid mulai hari ini'), findsOneWidget);

    await openTab(tester, 'Kalender');
    expect(find.text('Warna menunjukkan fase siklusmu'), findsOneWidget);

    await openTab(tester, 'Statistik');
    expect(find.text('Pola siklusmu dari waktu ke waktu'), findsOneWidget);
    expect(find.text('Belum ada statistik'), findsOneWidget); // baru 1 haid tercatat

    await openTab(tester, 'Pasangan');
    expect(find.text('Buat kode undangan'), findsOneWidget);

    await openTab(tester, 'Setelan');
    expect(find.text('Atur siklus, pengingat, dan datamu'), findsOneWidget);
  });

  testWidgets('alur pasangan (demo): buat kode, lalu tersambung', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await pumpApp(tester, {'app_settings_v1': _settingsDone});
    await openTab(tester, 'Pasangan');

    final createButton = find.text('Buat kode undangan');
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(createButton);
    await tester.pumpAndSettle();
    expect(find.text('Kode undanganmu'), findsOneWidget);

    final demoButton = find.text('Demo: anggap pasangan sudah menerima');
    await tester.ensureVisible(demoButton);
    await tester.tap(demoButton);
    await tester.pumpAndSettle();
    expect(find.text('Terhubung dengan Pasangan 💞'), findsOneWidget);
  });
}
