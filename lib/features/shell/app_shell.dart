// lib/features/shell/app_shell.dart
// Kerangka navigasi khas platform:
//  - iOS: tab bar melayang berkaca buram (blur) dengan label.
//  - Android: Material 3 NavigationBar dengan indikator pil.
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_icons/phosphor_icons.dart';

import '../../core/app_scaffold.dart';
import '../../core/platform_ui.dart';
import '../../core/theme.dart';
import '../calendar/calendar_screen.dart';
import '../home/home_screen.dart';
import '../partner/partner_screen.dart';
import '../settings/settings_screen.dart';
import '../stats/stats_screen.dart';

typedef _Tab = (IconData, IconData, String);

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

  static const List<_Tab> _tabs = [
    (PhosphorIconsRegular.heartbeat, PhosphorIconsFill.heartbeat, 'Beranda'),
    (PhosphorIconsRegular.calendarDots, PhosphorIconsFill.calendarDots, 'Kalender'),
    (PhosphorIconsRegular.chartBar, PhosphorIconsFill.chartBar, 'Statistik'),
    (PhosphorIconsRegular.users, PhosphorIconsFill.users, 'Pasangan'),
    (PhosphorIconsRegular.gear, PhosphorIconsFill.gear, 'Setelan'),
  ];

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final ios = isCupertino(context);
    return AppScaffold(
      // Beranda memakai pita pink Cyra; layar lain memakai latar polos supaya judul besar terbaca.
      background: _index == 0 ? null : AppColors.blush,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 280),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: ios
          ? _IosTabBar(index: _index, tabs: _tabs, onTap: _select)
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              height: 68,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final t in _tabs)
                  NavigationDestination(
                    icon: Icon(t.$1),
                    selectedIcon: Icon(t.$2),
                    label: t.$3,
                    tooltip: t.$3,
                  ),
              ],
            ),
    );
  }
}

class _IosTabBar extends StatelessWidget {
  final int index;
  final List<_Tab> tabs;
  final ValueChanged<int> onTap;
  const _IosTabBar({required this.index, required this.tabs, required this.onTap});

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              boxShadow: const [
                BoxShadow(color: AppColors.shadowDiffuse, blurRadius: 24, offset: Offset(0, 8)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  height: 66,
                  color: AppColors.white.withValues(alpha: 0.86),
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++)
                        Expanded(
                          child: _IosTab(
                            icon: i == index ? tabs[i].$2 : tabs[i].$1,
                            label: tabs[i].$3,
                            selected: i == index,
                            onTap: () => onTap(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _IosTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _IosTab({
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
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 24, color: selected ? AppColors.rose : AppColors.mauveSoft),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.rose : AppColors.mauveSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
