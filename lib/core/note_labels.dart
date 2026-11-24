// lib/core/note_labels.dart
// Label Indonesia untuk ID gejala/mood/aliran, gaya hasil siklus, dan keteraturan.
import 'package:flutter/material.dart';

import '../domain/cycle_engine.dart';
import '../domain/day_note.dart';
import '../domain/stats.dart';
import 'theme.dart';

const kSymptoms = <String, String>{
  'kram': 'Kram perut',
  'sakit_kepala': 'Sakit kepala',
  'payudara': 'Nyeri payudara',
  'jerawat': 'Jerawat',
  'kembung': 'Kembung',
  'lelah': 'Mudah lelah',
  'mual': 'Mual',
  'punggung': 'Nyeri punggung',
  'nafsu_makan': 'Nafsu makan naik',
};

const kMoods = <String, String>{
  'senang': '😊 Senang',
  'tenang': '😌 Tenang',
  'sensitif': '🥹 Sensitif',
  'sedih': '😢 Sedih',
  'kesal': '😠 Kesal',
  'cemas': '😰 Cemas',
};

const kFlowLabels = <FlowLevel, String>{
  FlowLevel.spotting: 'Bercak',
  FlowLevel.light: 'Ringan',
  FlowLevel.medium: 'Sedang',
  FlowLevel.heavy: 'Deras',
};

String symptomLabel(String id) => kSymptoms[id] ?? id;
String moodLabel(String id) => kMoods[id] ?? id;

class OutcomeStyle {
  final String label;
  final Color color, onColor;
  const OutcomeStyle(this.label, this.color, this.onColor);
}

OutcomeStyle outcomeStyle(CycleOutcome o) => switch (o) {
      CycleOutcome.onTime => const OutcomeStyle('Tepat waktu', AppColors.rose, AppColors.white),
      CycleOutcome.early => const OutcomeStyle('Lebih cepat', AppColors.lilac, AppColors.mauve),
      CycleOutcome.late => const OutcomeStyle('Terlambat', AppColors.honey, AppColors.mauve),
    };

String regularityLabel(Regularity r) => switch (r) {
      Regularity.unknown => 'Belum cukup data',
      Regularity.regular => 'Teratur',
      Regularity.varied => 'Cukup bervariasi',
      Regularity.irregular => 'Tidak teratur',
    };
