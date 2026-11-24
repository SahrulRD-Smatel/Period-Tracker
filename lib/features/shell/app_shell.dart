// lib/features/shell/app_shell.dart
// Kerangka navigasi gaya Cyra: dock hitam melayang berisi tombol bulat (5 tab, semua fitur tetap ada).
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../core/app_scaffold.dart';
import '../../core/theme.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_screen.dart';
import '../partner/partner_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    CalendarScreen(),
    StatsScreen(),
    PartnerScreen(),
    SettingsScreen(),
  ];

  static const _tabs = <(IconData, IconData, String)>[
    (PhosphorIconsRegular.heartbeat, PhosphorIconsFill.heartbeat, 'Beranda'),
    (PhosphorIconsRegular.calendarDots, PhosphorIconsFill.calendarDots, 'Kalender'),
    (PhosphorIconsRegular.chartBar, PhosphorIconsFill.chartBar, 'Statistik'),
    (PhosphorIconsRegular.users, PhosphorIconsFill.users, 'Pasangan'),
    (PhosphorIconsRegular.gear, PhosphorIconsFill.gear, 'Setelan'),
  ];

  @override
  Widget build(BuildContext context) => AppScaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Center(
            heightFactor: 1,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.dock,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.dock.withValues(alpha: 0.28),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < _tabs.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    _DockButton(
                      icon: i == _index ? _tabs[i].$2 : _tabs[i].$1,
                      label: _tabs[i].$3,
                      selected: i == _index,
                      onTap: () => setState(() => _index = i),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms),
      );
}

class _DockButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DockButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selected,
        label: label,
        child: Tooltip(
          message: label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? AppColors.rose : AppColors.white,
              ),
              child: Icon(icon, size: 22, color: selected ? AppColors.white : AppColors.mauve),
            ),
          ),
        ),
      );
}
