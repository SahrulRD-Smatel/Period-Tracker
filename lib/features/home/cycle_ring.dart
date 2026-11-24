// lib/features/home/cycle_ring.dart
// Cincin siklus: satu busur per hari, diwarnai per fase, dengan penanda "hari ini" bercahaya.
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
    const stroke = 18.0;
    const gap = 0.055;
    final center = size.center(Offset.zero);
    final radius = math.min(size.width, size.height) / 2 - stroke - 4;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / n;

    // 1. Lingkaran dasar halus (track) di belakang busur
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = AppColors.petal.withValues(alpha: 0.45);
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Busur-busur warna fase harian
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < n; i++) {
      arc.color = dayColors[i];
      canvas.drawArc(rect, -math.pi / 2 + i * sweep + gap / 2, sweep - gap, false, arc);
    }

    // 3. Penanda "Hari Ini" dengan efek glow mewah
    final idx = math.min(math.max(currentIndex, 0), n - 1);
    final angle = -math.pi / 2 + (idx + 0.5) * sweep;
    final pos = center + Offset(math.cos(angle), math.sin(angle)) * radius;

    // Halo cahaya luar
    canvas.drawCircle(
      pos,
      22,
      Paint()..color = AppColors.rose.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      pos,
      17,
      Paint()..color = AppColors.rose.withValues(alpha: 0.35),
    );

    // Manik utama putih dengan bayangan
    canvas.drawCircle(
      pos,
      13,
      Paint()
        ..color = AppColors.white
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1),
    );

    // Border rose tegas
    canvas.drawCircle(
      pos,
      13,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..color = AppColors.rose,
    );

    // Titik pusat rose berkilau
    canvas.drawCircle(pos, 5, Paint()..color = AppColors.rose);
    canvas.drawCircle(pos - const Offset(1.2, 1.2), 1.6, Paint()..color = AppColors.white);
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
    this.size = 246,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cahaya ambient lembut di dalam cincin
            Container(
              width: size * 0.72,
              height: size * 0.72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.petal.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                  radius: 0.85,
                ),
              ),
            ),
            CustomPaint(
              size: Size.square(size),
              painter: CycleRingPainter(dayColors: dayColors, currentIndex: currentIndex),
            ),
            center,
          ],
        ),
      );
}
