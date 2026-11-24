// lib/features/shell/app_shell.dart
// Kerangka navigasi bawah bergaya floating frosted-glass dock iOS.
import 'dart:ui';

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

  @override
  Widget build(BuildContext context) => AppScaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: KeyedSubtree(
            key: ValueKey(_index),
            child: _screens[_index],
          ),
        ),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowDiffuse,
                  blurRadius: 26,
                  offset: Offset(0, 8),
                  spreadRadius: -4,
                ),
                BoxShadow(
                  color: AppColors.shadowContact,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: AppColors.cardBorder, width: 1.2),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      backgroundColor: Colors.transparent,
                      indicatorColor: AppColors.petal,
                      indicatorShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: AppColors.ribbon, width: 1),
                      ),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return TextStyle(
                          fontSize: 11.5,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? AppColors.rose : AppColors.mauveSoft,
                          letterSpacing: -0.2,
                        );
                      }),
                      iconTheme: WidgetStateProperty.resolveWith((states) {
                        final selected = states.contains(WidgetState.selected);
                        return IconThemeData(
                          size: 22,
                          color: selected ? AppColors.rose : AppColors.mauveSoft,
                        );
                      }),
                    ),
                    child: NavigationBar(
                      selectedIndex: _index,
                      onDestinationSelected: (i) => setState(() => _index = i),
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      height: 66,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(PhosphorIconsRegular.heartbeat),
                          selectedIcon: Icon(PhosphorIconsFill.heartbeat, color: AppColors.rose),
                          label: 'Beranda',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsRegular.calendarDots),
                          selectedIcon: Icon(PhosphorIconsFill.calendarDots, color: AppColors.rose),
                          label: 'Kalender',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsRegular.chartBar),
                          selectedIcon: Icon(PhosphorIconsFill.chartBar, color: AppColors.rose),
                          label: 'Statistik',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsRegular.users),
                          selectedIcon: Icon(PhosphorIconsFill.users, color: AppColors.rose),
                          label: 'Pasangan',
                        ),
                        NavigationDestination(
                          icon: Icon(PhosphorIconsRegular.gear),
                          selectedIcon: Icon(PhosphorIconsFill.gear, color: AppColors.rose),
                          label: 'Setelan',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ).animate().fadeIn(duration: 350.ms),
      );
}
