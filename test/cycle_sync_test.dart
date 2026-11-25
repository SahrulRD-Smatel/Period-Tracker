// test/cycle_sync_test.dart
// Tes keterhubungan antar fitur lokal: sinkronisasi aliran haid/ovulasi, statistik gejala,
// backup v3, persistensi checklist/pasangan, dan cold-start AppLock.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:period_tracker/app.dart';
import 'package:period_tracker/application/providers.dart';
import 'package:period_tracker/domain/app_settings.dart';
import 'package:period_tracker/domain/cycle_engine.dart';
import 'package:period_tracker/domain/cycle_sync.dart';
import 'package:period_tracker/domain/day_note.dart';
import 'package:period_tracker/domain/full_backup.dart';
import 'package:period_tracker/domain/love_notes.dart';
import 'package:period_tracker/domain/partner_models.dart';
import 'package:period_tracker/domain/stats.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  DateTime d(int y, int m, int day) => DateTime.utc(y, m, day);

  setUpAll(() async => initializeDateFormatting('id_ID'));

  group('cycle_sync domain', () {
    test('latestConfirmedOvulation hanya mengambil tes positif di siklus berjalan', () {
      final logs = [
        PeriodLog(start: d(2026, 1, 1)),
        PeriodLog(start: d(2026, 2, 1)),
      ];
      final notes = [
        DayNote(date: d(2026, 1, 14), ovulationPositive: true), // siklus lama -> diabaikan
        DayNote(date: d(2026, 2, 16), ovulationPositive: true),
      ];
      expect(latestConfirmedOvulation(logs, notes), d(2026, 2, 16));
    });

    test('shouldAutoStartPeriod menolak bercak atau jarak <15 hari', () {
      final logs = [PeriodLog(start: d(2026, 3, 1))];
      expect(shouldAutoStartPeriod(logs, d(2026, 3, 10), FlowLevel.medium), isFalse);
      expect(shouldAutoStartPeriod(logs, d(2026, 3, 29), FlowLevel.spotting), isFalse);
      expect(shouldAutoStartPeriod(logs, d(2026, 3, 29), FlowLevel.medium), isTrue);
    });

    test('activeOpenPeriod mengembalikan log yang belum selesai (<10 hari)', () {
      final logs = [PeriodLog(start: d(2026, 4, 1))];
      expect(activeOpenPeriod(logs, d(2026, 4, 4))?.start, d(2026, 4, 1));
      expect(activeOpenPeriod([PeriodLog(start: d(2026, 4, 1), end: d(2026, 4, 4))], d(2026, 4, 4)), isNull);
    });
  });

  group('stats & backup v3 & partner json', () {
    test('computeStats meringkas gejala dan mood tersering meski siklus < 2', () {
      final stats = computeStats(
        const CycleEngine(),
        [PeriodLog(start: d(2026, 5, 1))],
        notes: [
          DayNote(date: d(2026, 5, 1), symptoms: {'kram', 'lelah'}, moods: {'sensitif'}),
          DayNote(date: d(2026, 5, 2), symptoms: {'kram'}, moods: {'sensitif', 'tenang'}),
        ],
      );
      expect(stats.totalNotes, 2);
      expect(stats.topSymptoms.first.id, 'kram');
      expect(stats.topSymptoms.first.count, 2);
      expect(stats.topMoods.first.id, 'sensitif');
    });

    test('exportFullBackup v3 menyimpan & memulihkan loveNotes dan careCheckedIds', () {
      final json = exportFullBackup(
        periods: [PeriodLog(start: d(2026, 1, 1))],
        notes: [],
        settings: const AppSettings(onboardingDone: true),
        loveNotes: [
          LoveNote(
            id: 'ln1',
            sender: 'Sahrul',
            message: 'Semangat Ruru!',
            createdAt: d(2026, 1, 2),
          ),
        ],
        careCheckedIds: const ['m_tea', 'm_rest'],
      );
      final back = importFullBackup(json);
      expect(back.loveNotes.single.message, 'Semangat Ruru!');
      expect(back.careCheckedIds, ['m_tea', 'm_rest']);
    });

    test('PartnerState JSON bolak-balik mempertahankan role, linkId, flags, dan snapshot', () {
      final st = PartnerState(
        role: PartnerRole.viewer,
        linked: true,
        linkId: 'uuid-123',
        partnerName: 'Ruru',
        myName: 'Sahrul',
        flags: const ShareFlags(phase: true, fertileWindow: false, nextPeriod: true),
        snapshot: PartnerSnapshot(
          phase: CyclePhase.menstrual,
          cycleDay: 2,
          nextPeriod: d(2026, 6, 1),
          updatedAt: d(2026, 5, 5),
        ),
      );
      final back = PartnerState.fromJson(st.toJson());
      expect(back.role, PartnerRole.viewer);
      expect(back.linked, isTrue);
      expect(back.linkId, 'uuid-123');
      expect(back.partnerName, 'Ruru');
      expect(back.flags.fertileWindow, isFalse);
      expect(back.snapshot?.phase, CyclePhase.menstrual);
    });
  });

  group('widget integration fixes', () {
    testWidgets('Catat gejala aliran deras otomatis menambah haid & tampil di Beranda', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsDone = jsonEncode(const AppSettings(onboardingDone: true).toJson());
      SharedPreferences.setMockInitialValues({'app_settings_v1': settingsDone});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: const MensApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Mulai dari keadaan kosong, klik hari ini di week strip untuk buka LogScreen
      final today = dateOnly(DateTime.now());
      await tester.tap(find.text('${today.day}'.padLeft(2, '0')));
      await tester.pumpAndSettle();

      // Pilih aliran 'Sedang' -> switch 'Tandai hari pertama haid' otomatis muncul dan aktif
      await tester.tap(find.text('Sedang'));
      await tester.pumpAndSettle();
      expect(find.text('Tandai hari pertama haid'), findsOneWidget);

      await tester.tap(find.text('Simpan'));
      await tester.pumpAndSettle();

      // Beranda langsung memperbarui ring menampilkan Menstruasi Hari ke-1!
      expect(find.text('Hari haid ke-'), findsOneWidget);
      expect(find.text('Menstruasi'), findsOneWidget);
    });

    testWidgets('AppLock aktif mengunci layar saat cold start & membuka dengan PIN 4-angka', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 932);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final settingsLocked = jsonEncode(const AppSettings(onboardingDone: true, appLock: true).toJson());
      SharedPreferences.setMockInitialValues({'app_settings_v1': settingsLocked});
      final prefs = await SharedPreferences.getInstance();
      // Simpan PIN fallback lokal 2580
      final pinRepo = ProviderContainer(
        overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
      ).read(appPinRepositoryProvider);
      await pinRepo.savePin('2580');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPrefsProvider.overrideWithValue(prefs)],
          child: const MensApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Harus langsung terkunci saat pertama kali buka (cold start!)
      expect(find.text('Siklusku terkunci'), findsOneWidget);

      for (final d in const ['2', '5', '8', '0']) {
        await tester.tap(find.text(d));
        await tester.pumpAndSettle();
      }

      // Setelah PIN benar -> masuk ke Beranda
      expect(find.text('Siklusku terkunci'), findsNothing);
      expect(find.text('Catat haid terakhir'), findsOneWidget);
    });
  });
}
