// lib/core/adaptive.dart
// Komponen adaptif. iOS: judul besar yang menciut, kartu inset-grouped, kontrol Cupertino.
// Android: Material 3 (large top app bar, SegmentedButton, bottom sheet berhandle).
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'platform_ui.dart';
import 'theme.dart';

/// Halaman dengan bilah judul besar khas platform. Isi dibangun penuh (bukan lazy) supaya
/// layar-layar kecil ini tetap sederhana dan mudah dites.
class AdaptivePage extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget> children;
  const AdaptivePage({super.key, required this.title, this.subtitle, required this.children});

  @override
  Widget build(BuildContext context) {
    final ios = isCupertino(context);
    return CustomScrollView(
      slivers: [
        if (ios)
          CupertinoSliverNavigationBar(
            transitionBetweenRoutes: false,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.blush.withValues(alpha: 0.92),
            largeTitle: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.mauve),
            ),
            middle: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.mauve),
            ),
          )
        else
          SliverAppBar.large(
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.blush,
            surfaceTintColor: AppColors.transparent,
            foregroundColor: AppColors.mauve,
            title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(subtitle!, style: kSmall),
                  ),
                ...children,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Kartu pengelompok. iOS: sudut 18 + garis tipis (inset grouped). Android: sudut 28 tonal.
class GroupCard extends StatelessWidget {
  final Widget child;
  const GroupCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final ios = isCupertino(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: ios ? 16 : 20, vertical: ios ? 14 : 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(ios ? 18 : 28),
        border: ios ? Border.all(color: AppColors.track, width: 0.8) : null,
        boxShadow: ios
            ? null
            : const [BoxShadow(color: AppColors.shadowContact, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: child,
    );
  }
}

class GroupDivider extends StatelessWidget {
  final double height;
  const GroupDivider(this.height, {super.key});

  @override
  Widget build(BuildContext context) {
    final ios = isCupertino(context);
    return Divider(
      height: height,
      thickness: ios ? 0.6 : 1,
      color: ios ? AppColors.mist.withValues(alpha: 0.5) : AppColors.petal,
    );
  }
}

/// Pilihan segmen. iOS: sliding segmented control. Android: Material 3 SegmentedButton.
class AdaptiveSegmented<T extends Object> extends StatelessWidget {
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;
  const AdaptiveSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (isCupertino(context)) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          thumbColor: AppColors.white,
          backgroundColor: AppColors.track,
          children: {
            for (final e in options.entries)
              e.key: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  e.value,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.mauve,
                  ),
                ),
              ),
          },
          onValueChanged: (v) {
            if (v == null) return;
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<T>(
        showSelectedIcon: false,
        segments: [
          for (final e in options.entries)
            ButtonSegment<T>(
              value: e.key,
              label: Text(e.value, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
        ],
        selected: {value},
        onSelectionChanged: (s) => onChanged(s.first),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? AppColors.petal : AppColors.white,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (st) => st.contains(WidgetState.selected) ? AppColors.roseDeep : AppColors.mauve,
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: AppColors.ribbon)),
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet khas platform: iOS bersudut 16 + grabber, Android Material 3 bersudut 28 + drag handle.
Future<T?> showAppSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  final ios = isCupertino(context);
  return showModalBottomSheet<T>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    showDragHandle: !ios,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(ios ? 16 : 28)),
    ),
    builder: ios
        ? (ctx) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: AppColors.mist,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Flexible(child: builder(ctx)),
              ],
            )
        : builder,
  );
}

/// Pemilih tanggal: iOS = roda tanggal di popup bawah, Android = dialog kalender Material.
Future<DateTime?> pickDateAdaptive(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
  required DateTime last,
  required String help,
}) async {
  if (!isCupertino(context)) {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: help,
    );
  }
  DateTime local(DateTime d) => DateTime(d.year, d.month, d.day);
  var chosen = local(initial);
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => Material(
      color: AppColors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 330,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: Row(
                  children: [
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Batal', style: TextStyle(color: AppColors.mauveSoft)),
                    ),
                    Expanded(
                      child: Text(
                        help,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    CupertinoButton(
                      onPressed: () => Navigator.of(ctx).pop(chosen),
                      child: const Text(
                        'Pilih',
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.rose),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: local(initial),
                  minimumDate: local(first),
                  maximumDate: local(last),
                  onDateTimeChanged: (d) => chosen = d,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
