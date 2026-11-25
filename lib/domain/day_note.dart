// lib/domain/day_note.dart
// Catatan harian: aliran haid, tes ovulasi positif, gejala, suasana hati, teks bebas. Murni Dart.
// `symptoms` & `moods` menyimpan ID (lihat core/note_labels.dart untuk label Indonesia).
import 'backup.dart' show isoDate, parseIsoDate;
import 'cycle_engine.dart';

enum FlowLevel { spotting, light, medium, heavy }

class DayNote {
  final DateTime date;
  final FlowLevel? flow;
  final bool ovulationPositive;
  final Set<String> symptoms, moods;
  final String note;

  DayNote({
    required DateTime date,
    this.flow,
    this.ovulationPositive = false,
    Set<String>? symptoms,
    Set<String>? moods,
    this.note = '',
  })  : date = dateOnly(date),
        symptoms = symptoms ?? const <String>{},
        moods = moods ?? const <String>{};

  bool get isEmpty =>
      flow == null &&
      !ovulationPositive &&
      symptoms.isEmpty &&
      moods.isEmpty &&
      note.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'date': isoDate(date),
        if (flow != null) 'flow': flow!.name,
        if (ovulationPositive) 'ovulationPositive': true,
        if (symptoms.isNotEmpty) 'symptoms': (symptoms.toList()..sort()),
        if (moods.isNotEmpty) 'moods': (moods.toList()..sort()),
        if (note.trim().isNotEmpty) 'note': note.trim(),
      };

  factory DayNote.fromJson(Map<dynamic, dynamic> j) {
    final f = j['flow'] as String?;
    return DayNote(
      date: parseIsoDate(j['date'] as String),
      flow: FlowLevel.values.where((e) => e.name == f).firstOrNull,
      ovulationPositive: j['ovulationPositive'] as bool? ?? false,
      symptoms: {for (final s in (j['symptoms'] as List? ?? const [])) s as String},
      moods: {for (final s in (j['moods'] as List? ?? const [])) s as String},
      note: j['note'] as String? ?? '',
    );
  }
}
