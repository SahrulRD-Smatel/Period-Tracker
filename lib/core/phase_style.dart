// lib/core/phase_style.dart
// SATU-SATUNYA tempat yang memetakan CyclePhase -> warna/ikon/teks.
// Menambah fase baru? Perbarui di sini + legenda kalender + tes.
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../domain/cycle_engine.dart';
import 'theme.dart';

class PhaseStyle {
  final String label, hint;
  final Color color, onColor;
  final IconData icon;
  const PhaseStyle({
    required this.label,
    required this.hint,
    required this.color,
    required this.onColor,
    required this.icon,
  });
}

PhaseStyle phaseStyle(CyclePhase p) => switch (p) {
      CyclePhase.menstrual => const PhaseStyle(
          label: 'Menstruasi',
          hint: 'Istirahat cukup dan jaga dirimu dengan baik.',
          color: AppColors.rose,
          onColor: AppColors.white,
          icon: PhosphorIconsFill.drop,
        ),
      CyclePhase.follicular => const PhaseStyle(
          label: 'Fase folikular',
          hint: 'Energi biasanya mulai naik.',
          color: AppColors.petal,
          onColor: AppColors.mauve,
          icon: PhosphorIconsFill.flower,
        ),
      CyclePhase.fertile => const PhaseStyle(
          label: 'Masa subur',
          hint: 'Peluang hamil lebih tinggi pada hari-hari ini.',
          color: AppColors.lilac,
          onColor: AppColors.mauve,
          icon: PhosphorIconsFill.heart,
        ),
      CyclePhase.ovulation => const PhaseStyle(
          label: 'Ovulasi',
          hint: 'Perkiraan hari ovulasi (puncak masa subur).',
          color: AppColors.honey,
          onColor: AppColors.mauve,
          icon: PhosphorIconsFill.sparkle,
        ),
      CyclePhase.luteal => const PhaseStyle(
          label: 'Fase luteal',
          hint: 'Sebagian orang mengalami PMS di fase ini.',
          color: AppColors.peach,
          onColor: AppColors.mauve,
          icon: PhosphorIconsFill.moon,
        ),
      CyclePhase.delayed => const PhaseStyle(
          label: 'Terlambat',
          hint: 'Haid melewati perkiraan. Catat tanggalnya bila sudah datang.',
          color: AppColors.mist,
          onColor: AppColors.mauve,
          icon: PhosphorIconsFill.hourglassLow,
        ),
    };

