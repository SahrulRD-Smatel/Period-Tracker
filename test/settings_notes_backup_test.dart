// test/settings_notes_backup_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/app_settings.dart';
import 'package:period_tracker/domain/backup.dart';
import 'package:period_tracker/domain/cycle_engine.dart';
import 'package:period_tracker/domain/day_note.dart';
import 'package:period_tracker/domain/full_backup.dart';

void main() {
  DateTime d(int m, int day) => DateTime.utc(2026, m, day);

  group('AppSettings', () {
    test('JSON bolak-balik', () {
      const s = AppSettings(
        cycleLength: 30,
        periodLength: 6,
        onboardingDone: true,
        remindDaysBefore: 3,
        remindPeriodDayOf: false,
        remindOvulationDayOf: false,
      );
      final back = AppSettings.fromJson(s.toJson());
      expect(back.cycleLength, 30);
      expect(back.periodLength, 6);
      expect(back.onboardingDone, isTrue);
      expect(back.remindDaysBefore, 3);
      expect(back.remindPeriodDayOf, isFalse);
      expect(back.remindOvulationDayOf, isFalse);
    });

    test('nilai di luar rentang dijepit, kunci hilang = default', () {
      final s = AppSettings.fromJson({'cycleLength': 100, 'periodLength': 0});
      expect(s.cycleLength, kCycleMax);
      expect(s.periodLength, kPeriodMin);
      expect(s.lutealLength, 14);
      expect(s.onboardingDone, isFalse);
      expect(s.remindPeriodDayOf, isTrue);
      expect(s.remindOvulationDayOf, isTrue);
    });

    test('dipetakan ke CycleSettings untuk engine', () {
      final c = const AppSettings(cycleLength: 32, periodLength: 4, lutealLength: 13).toCycleSettings();
      expect(c.defaultCycleLength, 32);
      expect(c.defaultPeriodLength, 4);
      expect(c.lutealLength, 13);
    });
  });

  group('DayNote', () {
    test('JSON bolak-balik & isEmpty', () {
      final n = DayNote(
        date: d(1, 2),
        flow: FlowLevel.heavy,
        symptoms: {'kram', 'lelah'},
        moods: {'sedih'},
        note: ' tidur cepat ',
      );
      final back = DayNote.fromJson(n.toJson());
      expect(back.date, d(1, 2));
      expect(back.flow, FlowLevel.heavy);
      expect(back.symptoms, {'kram', 'lelah'});
      expect(back.moods, {'sedih'});
      expect(back.note, 'tidur cepat');
      expect(DayNote(date: d(1, 3)).isEmpty, isTrue);
      expect(DayNote(date: d(1, 3), note: '   ').isEmpty, isTrue);
      expect(n.isEmpty, isFalse);
    });
  });

  group('Cadangan lengkap v2', () {
    test('ekspor lalu impor', () {
      final json = exportFullBackup(
        periods: [PeriodLog(start: d(1, 1), end: d(1, 5))],
        notes: [DayNote(date: d(1, 2), flow: FlowLevel.medium, symptoms: {'kram'})],
        settings: const AppSettings(cycleLength: 30, onboardingDone: true),
      );
      final back = importFullBackup(json);
      expect(back.periods.single.end, d(1, 5));
      expect(back.notes.single.flow, FlowLevel.medium);
      expect(back.notes.single.symptoms, {'kram'});
      expect(back.settings!.cycleLength, 30);
    });

    test('kompatibel dengan cadangan v1 (hanya riwayat haid)', () {
      final v1 = exportBackup([PeriodLog(start: d(1, 1))]);
      final back = importFullBackup(v1);
      expect(back.periods.length, 1);
      expect(back.notes, isEmpty);
      expect(back.settings, isNull);
    });

    test('teks rusak / versi tak dikenal ditolak', () {
      expect(() => importFullBackup('bukan json'), throwsFormatException);
      expect(() => importFullBackup('{"version":99}'), throwsFormatException);
      expect(() => importFullBackup('[]'), throwsFormatException);
      expect(() => importFullBackup('{"version":2,"periods":[{"start":123}]}'), throwsFormatException);
    });
  });
}
