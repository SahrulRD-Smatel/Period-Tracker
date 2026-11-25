// test/love_notes_and_care_guide_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:period_tracker/domain/care_guide.dart';
import 'package:period_tracker/domain/cycle_engine.dart';
import 'package:period_tracker/domain/love_notes.dart';

void main() {
  group('LoveNote', () {
    test('JSON bolak-balik', () {
      final now = DateTime.utc(2026, 11, 24, 12, 0);
      final note = LoveNote(
        id: 'n1',
        sender: 'Dhani',
        message: 'Semangat ya sayang 🌸',
        createdAt: now,
        isRead: false,
        trigger: LoveNoteTrigger.menstrual,
        reaction: '💖',
      );

      final json = note.toJson();
      final back = LoveNote.fromJson(json);

      expect(back.id, 'n1');
      expect(back.sender, 'Dhani');
      expect(back.message, 'Semangat ya sayang 🌸');
      expect(back.createdAt, now);
      expect(back.isRead, isFalse);
      expect(back.trigger, LoveNoteTrigger.menstrual);
      expect(back.reaction, '💖');
    });

    test('relevansi fase: anytime relevan untuk semua fase', () {
      final note = LoveNote(
        id: 'n2',
        message: 'Kapan saja',
        createdAt: DateTime.now(),
        trigger: LoveNoteTrigger.anytime,
      );

      expect(note.isRelevantForPhase(CyclePhase.menstrual), isTrue);
      expect(note.isRelevantForPhase(CyclePhase.luteal), isTrue);
      expect(note.isRelevantForPhase(CyclePhase.follicular), isTrue);
      expect(note.isRelevantForPhase(null), isTrue);
    });

    test('relevansi fase: menstrual & luteal cocok dengan fase bersangkutan', () {
      final noteMenstrual = LoveNote(
        id: 'n3',
        message: 'Haid',
        createdAt: DateTime.now(),
        trigger: LoveNoteTrigger.menstrual,
      );
      expect(noteMenstrual.isRelevantForPhase(CyclePhase.menstrual), isTrue);
      expect(noteMenstrual.isRelevantForPhase(CyclePhase.luteal), isFalse);

      final noteLuteal = LoveNote(
        id: 'n4',
        message: 'PMS',
        createdAt: DateTime.now(),
        trigger: LoveNoteTrigger.luteal,
      );
      expect(noteLuteal.isRelevantForPhase(CyclePhase.luteal), isTrue);
      expect(noteLuteal.isRelevantForPhase(CyclePhase.menstrual), isFalse);
    });
  });

  group('careGuideForPhase', () {
    test('fase menstruasi menyediakan aksi perhatian kram & kenyamanan', () {
      final items = careGuideForPhase(CyclePhase.menstrual);
      expect(items, isNotEmpty);
      expect(items.any((i) => i.id == 'm_tea'), isTrue);
      expect(items.any((i) => i.id == 'm_compress'), isTrue);
    });

    test('fase luteal (PMS) menyediakan aksi mendengar & camilan manis', () {
      final items = careGuideForPhase(CyclePhase.luteal);
      expect(items, isNotEmpty);
      expect(items.any((i) => i.id == 'l_listen'), isTrue);
      expect(items.any((i) => i.id == 'l_sweet'), isTrue);
    });

    test('fase subur / ovulasi menyediakan aksi kencan romantis', () {
      final items = careGuideForPhase(CyclePhase.fertile);
      expect(items, isNotEmpty);
      expect(items.any((i) => i.id == 'o_special'), isTrue);
    });
  });
}
