// lib/features/stats/cycle_bars.dart
// Diagram batang panjang siklus modern (tanpa paket grafik).
// Area abu = rentang normal 21-35 hari; garis putus-putus = rata-rata.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/note_labels.dart';
import '../../core/theme.dart';
import '../../domain/stats.dart';

class CycleBarsPainter extends CustomPainter {
  final List<CycleRecord> cycles;
  final List<String> labels; // label sumbu-x, sepanjang cycles
  final double avg;
  const CycleBarsPainter({required this.cycles, required this.labels, required this.avg});

  void _text(
    Canvas c,
    String s,
    Offset center, {
    double size = 11,
    Color color = AppColors.mauveSoft,
    FontWeight w = FontWeight.w500,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          color: color,
          fontSize: size,
          fontWeight: w,
          letterSpacing: -0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (cycles.isEmpty) return;
    const padL = 10.0, padR = 10.0, padT = 24.0, padB = 28.0;
    final w = size.width - padL - padR;
    final h = size.height - padT - padB;
    final maxLen = cycles.map((c) => c.length).reduce(math.max);
    final maxV = math.max(40, maxLen + 4).toDouble();
    double y(num v) => padT + h * (1 - v / maxV);

    // Rentang normal 21-35 hari dengan sudut melengkung halus
    final normalRect = Rect.fromLTRB(padL, y(35), size.width - padR, y(21));
    canvas.drawRRect(
      RRect.fromRectAndRadius(normalRect, const Radius.circular(14)),
      Paint()..color = AppColors.track,
    );

    // Batang-batang siklus
    final n = cycles.length;
    final slot = w / n;
    final barW = math.min(28.0, slot * 0.62);

    for (var i = 0; i < n; i++) {
      final c = cycles[i];
      final cx = padL + slot * (i + 0.5);
      final color = c.outcome == null ? AppColors.rose : outcomeStyle(c.outcome!).color;

      final barRect = Rect.fromLTRB(cx - barW / 2, y(c.length), cx + barW / 2, y(0));
      final barRRect = RRect.fromRectAndCorners(
        barRect,
        topLeft: const Radius.circular(12),
        topRight: const Radius.circular(12),
        bottomLeft: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );

      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [color.withValues(alpha: 0.85), color],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(barRect);

      canvas.drawRRect(barRRect, barPaint);

      _text(
        canvas,
        '${c.length}',
        Offset(cx, y(c.length) - 10),
        size: 11.5,
        color: AppColors.mauve,
        w: FontWeight.w800,
      );

      _text(
        canvas,
        labels[i],
        Offset(cx, size.height - 10),
        size: 11,
        color: AppColors.mauveSoft,
        w: FontWeight.w600,
      );
    }

    // Garis rata-rata (putus-putus)
    final line = Paint()
      ..color = AppColors.mauveSoft.withValues(alpha: 0.7)
      ..strokeWidth = 1.6;
    final ay = y(avg);
    var x = padL;
    while (x < size.width - padR) {
      canvas.drawLine(Offset(x, ay), Offset(math.min(x + 6, size.width - padR), ay), line);
      x += 11;
    }
  }

  @override
  bool shouldRepaint(CycleBarsPainter old) => true;
}
