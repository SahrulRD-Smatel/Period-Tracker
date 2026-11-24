// lib/core/widgets.dart
// Komponen UI bersama bergaya coquette mewah (Dribbble / Figma tier).
import 'package:flutter/material.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import 'theme.dart';

/// Kartu bernuansa mewah dengan kedalaman berlapis (gradient + dual-shadow + micro-border).
class PinkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Gradient? gradient;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? customShadow;

  const PinkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color = AppColors.white,
    this.gradient,
    this.border,
    this.borderRadius = 26,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? (color == AppColors.white ? AppColors.heroCardGradient : null);

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveGradient == null ? color : null,
        gradient: effectiveGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ?? Border.all(color: AppColors.cardBorder, width: 1.2),
        boxShadow: customShadow ??
            const [
              BoxShadow(
                color: AppColors.shadowDiffuse,
                blurRadius: 22,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.shadowContact,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
      ),
      child: child,
    );
  }
}

/// Pita coquette vektor murni (tanpa ketergantungan emoji sistem operasi / Windows).
class CoquetteBow extends StatelessWidget {
  final double size;
  final Color? color;
  const CoquetteBow({super.key, this.size = 28, this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _BowPainter(color: color ?? AppColors.rose),
        ),
      );
}

class _BowPainter extends CustomPainter {
  final Color color;
  const _BowPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Center knot
    final knotRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.44), width: w * 0.22, height: h * 0.22),
      Radius.circular(w * 0.08),
    );

    // Left loop
    final leftLoop = Path()
      ..moveTo(w * 0.45, h * 0.44)
      ..cubicTo(w * 0.35, h * 0.16, w * 0.06, h * 0.16, w * 0.06, h * 0.44)
      ..cubicTo(w * 0.06, h * 0.64, w * 0.35, h * 0.56, w * 0.45, h * 0.46)
      ..close();

    // Right loop
    final rightLoop = Path()
      ..moveTo(w * 0.55, h * 0.44)
      ..cubicTo(w * 0.65, h * 0.16, w * 0.94, h * 0.16, w * 0.94, h * 0.44)
      ..cubicTo(w * 0.94, h * 0.64, w * 0.65, h * 0.56, w * 0.55, h * 0.46)
      ..close();

    // Left tail
    final leftTail = Path()
      ..moveTo(w * 0.42, h * 0.50)
      ..quadraticBezierTo(w * 0.30, h * 0.70, w * 0.20, h * 0.90)
      ..lineTo(w * 0.33, h * 0.86)
      ..lineTo(w * 0.44, h * 0.90)
      ..quadraticBezierTo(w * 0.44, h * 0.70, w * 0.48, h * 0.52)
      ..close();

    // Right tail
    final rightTail = Path()
      ..moveTo(w * 0.58, h * 0.50)
      ..quadraticBezierTo(w * 0.70, h * 0.70, w * 0.80, h * 0.90)
      ..lineTo(w * 0.67, h * 0.86)
      ..lineTo(w * 0.56, h * 0.90)
      ..quadraticBezierTo(w * 0.56, h * 0.70, w * 0.52, h * 0.52)
      ..close();

    canvas.drawPath(leftTail, paint);
    canvas.drawPath(rightTail, paint);
    canvas.drawPath(leftLoop, paint);
    canvas.drawPath(rightLoop, paint);
    canvas.drawRRect(knotRect, paint);
  }

  @override
  bool shouldRepaint(covariant _BowPainter oldDelegate) => oldDelegate.color != color;
}

/// Header bergaya iOS premium dengan badge pita mengambang dan tipografi berkelas.
class BowHeader extends StatelessWidget {
  final String title, subtitle;
  final Widget? trailing;

  const BowHeader({
    super.key,
    this.title = 'Siklusku',
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.petal, Color(0xFFFFD4E2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white, width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowDiffuse,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const CoquetteBow(size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: kHeading.copyWith(fontSize: 24, letterSpacing: -0.5)),
                const SizedBox(height: 2),
                Text(subtitle, style: kSmall),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      );
}

class IconBubble extends StatelessWidget {
  final IconData icon;
  final Color color, onColor;
  final double size;

  const IconBubble({
    super.key,
    required this.icon,
    required this.color,
    required this.onColor,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.28),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(icon, color: onColor, size: size * 0.5),
      );
}

class PhaseChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color, onColor;
  const PhaseChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onColor,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: onColor.withValues(alpha: 0.18), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: onColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: onColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      );
}

// ======================= komponen tambahan =======================

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
        child: Text(text, style: kHeading.copyWith(fontSize: 20, letterSpacing: -0.4)),
      );
}

/// Tombol mewah dengan gradien rose dan bayangan glowing yang empuk.
class PinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;
  final bool fullWidth;

  const PinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;

    final child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(
            icon,
            size: 19,
            color: isSecondary ? AppColors.rose : AppColors.white,
          ),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: !enabled
                ? AppColors.mist
                : (isSecondary ? AppColors.rose : AppColors.white),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        decoration: BoxDecoration(
          color: !enabled
              ? AppColors.petal.withValues(alpha: 0.5)
              : (isSecondary ? AppColors.petal : null),
          gradient: (!enabled || isSecondary) ? null : AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          border: isSecondary
              ? Border.all(color: AppColors.ribbon, width: 1.4)
              : null,
          boxShadow: (!enabled || isSecondary)
              ? null
              : const [
                  BoxShadow(
                    color: AppColors.shadowDiffuse,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: child,
      ),
    );
  }
}

/// Chip pilihan interaktif (aliran, gejala, mood).
class PinkChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const PinkChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? null : AppColors.white,
            gradient: selected ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.transparent : AppColors.ribbon,
              width: 1.4,
            ),
            boxShadow: selected
                ? const [
                    BoxShadow(
                      color: AppColors.shadowDiffuse,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ]
                : const [
                    BoxShadow(
                      color: AppColors.shadowContact,
                      blurRadius: 4,
                      offset: Offset(0, 1),
                    ),
                  ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.white : AppColors.mauve,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
        ),
      );
}

/// Label kecil non-interaktif bertekstur modern.
class TagChip extends StatelessWidget {
  final String label;
  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.petal,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.ribbon.withValues(alpha: 0.5), width: 1),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.mauve,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

/// Baris dengan tombol − / + untuk angka bulat.
class StepperTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int value, min, max;
  final String unit;
  final ValueChanged<int> onChanged;
  const StepperTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.unit,
    required this.onChanged,
  });

  Widget _btn(IconData icon, bool enabled, VoidCallback onTap) => Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: AppColors.shadowContact,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 18),
          style: IconButton.styleFrom(
            backgroundColor: enabled ? AppColors.petal : AppColors.blush,
            foregroundColor: enabled ? AppColors.rose : AppColors.mist,
            padding: const EdgeInsets.all(8),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (subtitle != null) Text(subtitle!, style: kSmall),
              ],
            ),
          ),
          _btn(PhosphorIconsRegular.minus, value > min, () => onChanged(value - 1)),
          SizedBox(
            width: 76,
            child: Center(
              child: Text(
                '$value $unit',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  letterSpacing: -0.3,
                  color: AppColors.mauve,
                ),
              ),
            ),
          ),
          _btn(PhosphorIconsRegular.plus, value < max, () => onChanged(value + 1)),
        ],
      );
}

/// Baris dengan saklar modern adaptif.
class SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  const SwitchRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (subtitle != null) Text(subtitle!, style: kSmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      );
}

/// Kotak statistik bernuansa glassmorphic untuk layar statistik.
class StatTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const StatTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => PinkCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: AppColors.petal,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: AppColors.rose),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: kSmall.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: kHeading.copyWith(
                fontSize: 22,
                letterSpacing: -0.6,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
}

class ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  const ActionRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: danger ? AppColors.danger.withValues(alpha: 0.1) : AppColors.petal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: danger ? AppColors.danger : AppColors.rose,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: danger ? AppColors.danger : AppColors.mauve,
                  ),
                ),
              ),
              const Icon(PhosphorIconsRegular.caretRight, color: AppColors.mist, size: 16),
            ],
          ),
        ),
      );
}
