// test/romantic_features_widget_test.dart
// Uji interaksi fitur romantis: Amplop surat cinta di Beranda & Care Checklist di Pasangan.
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
import 'package:period_tracker/domain/love_notes.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpRomanticApp(
  WidgetTester tester, {
  List<LoveNote>? initialLoveNotes,
}) async {
  final today = dateOnly(DateTime.now());
  final logs = exportBackup([PeriodLog(start: today.subtract(const Duration(days: 1)))]);
  final settingsDone = jsonEncode(const AppSettings(onboardingDone: true).toJson());

  final prefsValues = <String, Object>{
    'period_logs_v1': logs,
    'app_settings_v1': settingsDone,
  };

  if (initialLoveNotes != null) {
    prefsValues['love_notes_v1'] =
        jsonEncode([for (final n in initialLoveNotes) n.toJson()]);
  }

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

void main() {
  setUpAll(() async => initializeDateFormatting('id_ID'));

  testWidgets('amplop surat cinta muncul di Beranda, bisa dibuka dan diberi reaksi', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final testNote = LoveNote(
      id: 'romance_1',
      sender: 'Dhani',
      message: 'Semangat ya cantik, istirahat yang banyak hari ini 🥰',
      createdAt: DateTime.now(),
      isRead: false,
      trigger: LoveNoteTrigger.anytime,
    );

    await _pumpRomanticApp(tester, initialLoveNotes: [testNote]);

    // Amplop surat cinta terlihat di Beranda
    expect(find.text('Surat Cinta 💌'), findsOneWidget);
    expect(find.text('BARU'), findsOneWidget);

    // Buka surat cinta
    await tester.tap(find.text('Surat Cinta 💌'));
    await tester.pumpAndSettle();

    // Modal terbuka dan menampilkan pesan
    expect(find.text('Semangat ya cantik, istirahat yang banyak hari ini 🥰'), findsOneWidget);

    // Kirim reaksi '💖'
    await tester.tap(find.text('💖'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Reaksi kamu: 💖'), findsAtLeastNWidgets(1));
  });

  testWidgets('checklist perhatian di tab Pasangan bisa dicentang', (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await _pumpRomanticApp(tester);

    // Buka tab Pasangan
    await tester.tap(find.byTooltip('Pasangan'));
    await tester.pumpAndSettle();

    // Hubungkan pasangan demo
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Buat kode undangan'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Demo: anggap pasangan sudah menerima'));
    await tester.pumpAndSettle();

    // Gulir ke bawah di tab Pasangan
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
    await tester.pumpAndSettle();

    // Checklist perhatian muncul
    expect(find.text('Checklist Perhatian Romantis 🎀'), findsOneWidget);
    expect(find.textContaining('Perhatian terwujud: 0'), findsOneWidget);

    // Centang aksi perhatian pertama
    final firstItem = find.text('Sajikan Minuman Hangat');
    await tester.ensureVisible(firstItem);
    await tester.pumpAndSettle();
    await tester.tap(firstItem);
    await tester.pumpAndSettle();

    // Progress bertambah & tetap tersimpan walau pindah tab
    expect(find.textContaining('Perhatian terwujud: 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Beranda'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Pasangan'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Perhatian terwujud: 1'), findsOneWidget);
  });
}
