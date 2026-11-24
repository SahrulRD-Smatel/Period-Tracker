// lib/core/app_scaffold.dart
// Semua layar WAJIB memakai AppScaffold (bukan Scaffold langsung) supaya konten
// tidak tertutup Dynamic Island / notch / home indicator di iPhone,
// maupun punch-hole & gesture bar di Android.
import 'package:flutter/material.dart';

import 'theme.dart';

class AppScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? bottomNavigationBar;
  final Color? background;
  final double maxWidth;

  const AppScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.background,
    this.maxWidth = 480,
  });

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar != null
            ? Align(
                alignment: Alignment.bottomCenter,
                heightFactor: 1.0,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: bottomNavigationBar,
                ),
              )
            : null,
        backgroundColor: background ?? AppColors.blush,
        // SafeArea aman dipakai bersama AppBar / BottomNavigationBar:
        // Scaffold sudah menghapus inset yang ia tangani sendiri.
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: body,
            ),
          ),
        ),
      );
}
