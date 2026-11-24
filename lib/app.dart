// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'core/app_lock.dart';
import 'core/theme.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'notifications/scheduler.dart';

class MensApp extends ConsumerStatefulWidget {
  const MensApp({super.key});

  @override
  ConsumerState<MensApp> createState() => _MensAppState();
}

class _MensAppState extends ConsumerState<MensApp> with WidgetsBindingObserver {
  bool _locked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Hitung ulang "hari ini" setiap aplikasi kembali ke foreground (ganti hari).
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayProvider);
      // Kunci layar bila fitur kunci aktif
      if (ref.read(settingsProvider).appLock) {
        setState(() => _locked = true);
      }
    }
    // Re-schedule notifikasi setiap kali app aktif kembali
    if (state == AppLifecycleState.resumed) {
      final prediction = ref.read(predictionProvider);
      final settings = ref.read(settingsProvider);
      if (prediction != null && (settings.remindPeriod || settings.remindFertile)) {
        NotificationScheduler.scheduleFromPrediction(prediction, settings);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Siklusku',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('id'),
      supportedLocales: const [Locale('id'), Locale('en')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: settings.onboardingDone
          ? AppLockOverlay(
              locked: _locked && settings.appLock,
              onUnlock: () => setState(() => _locked = false),
              child: const AppShell(),
            )
          : const OnboardingScreen(),
    );
  }
}
