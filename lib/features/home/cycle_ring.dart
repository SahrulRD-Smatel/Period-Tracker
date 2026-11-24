// lib/features/home/cycle_ring.dart
// Cincin siklus gaya Cyra: jalur abu, busur gradien pink berujung bulat sampai "hari ini",
// dan knob putih berbingkai pink. dayColors tetap diterima (panjangnya = jumlah hari siklus).
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class CycleRingPainter extends CustomPainter {
  final List<Color> dayColors;
  final int currentIndex; // 0-based; di luar rentang akan dijepit (mis. saat terlambat)
  const CycleRingPainter({required this.dayColors, required this.currentIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final n = dayColors.length;
    if (n == 0) return;
    const stroke = 30.0;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke / 2 - 10;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = AppColors.track,
    );

    final idx = math.min(math.max(currentIndex, 0), n - 1);
    final sweep = 2 * math.pi * (idx + 1) / n;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweep,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..shader = const SweepGradient(
          colors: [AppColors.roseLight, AppColors.rose],
          transform: GradientRotation(-math.pi / 2),
        ).createShader(rect),
    );

    final angle = -math.pi / 2 + sweep;
    final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(
      pos + const Offset(0, 3),
      20,
      Paint()
        ..color = AppColors.shadowDiffuse
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(pos, 20, Paint()..color = AppColors.white);
    canvas.drawCircle(
      pos,
      17.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..color = AppColors.rose,
    );
  }

  @override
  bool shouldRepaint(CycleRingPainter old) =>
      old.currentIndex != currentIndex || !listEquals(old.dayColors, dayColors);
}

class CycleRing extends StatelessWidget {
  final List<Color> dayColors;
  final int currentIndex;
  final Widget center;
  final double size;
  const CycleRing({
    super.key,
    required this.dayColors,
    required this.currentIndex,
    required this.center,
    this.size = 240,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size.square(size),
              painter: CycleRingPainter(dayColors: dayColors, currentIndex: currentIndex),
            ),
            center,
          ],
        ),
      );
}
