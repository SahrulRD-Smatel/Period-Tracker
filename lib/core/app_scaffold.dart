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
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
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
      backgroundColor: background ?? AppColors.white,
      body: Stack(
        children: [
          if (background == null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topInset + 176,
              child: const DecoratedBox(
                decoration: BoxDecoration(gradient: AppColors.canvasGradient),
              ),
            ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: body,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
