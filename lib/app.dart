// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'application/providers.dart';
import 'core/app_lock.dart';
import 'core/platform_ui.dart';
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
    // Kunci langsung saat cold start jika appLock aktif!
    _locked = ref.read(settingsProvider).appLock;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncNotifications();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _syncNotifications() {
    final prediction = ref.read(predictionProvider);
    final settings = ref.read(settingsProvider);
    if (prediction != null && (settings.remindPeriod || settings.remindFertile)) {
      NotificationScheduler.scheduleFromPrediction(prediction, settings);
    } else if (!settings.remindPeriod && !settings.remindFertile) {
      NotificationScheduler.cancelAll();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(todayProvider);
      if (ref.read(settingsProvider).appLock) {
        setState(() => _locked = true);
      }
      _syncNotifications();
      ref.read(partnerProvider.notifier).syncWithServer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    ref.listen(predictionProvider, (_, next) {
      final s = ref.read(settingsProvider);
      if (next != null && (s.remindPeriod || s.remindFertile)) {
        NotificationScheduler.scheduleFromPrediction(next, s);
      } else if (!s.remindPeriod && !s.remindFertile) {
        NotificationScheduler.cancelAll();
      }
    });

    ref.listen(settingsProvider, (_, next) {
      final p = ref.read(predictionProvider);
      if (p != null && (next.remindPeriod || next.remindFertile)) {
        NotificationScheduler.scheduleFromPrediction(p, next);
      } else if (!next.remindPeriod && !next.remindFertile) {
        NotificationScheduler.cancelAll();
      }
    });

    // Setiap kali ringkasan siklus berubah, otomatis kirim snapshot ke pasangan (bila owner tersambung)
    ref.listen(homeSummaryProvider, (_, __) {
      ref.read(partnerProvider.notifier).pushSnapshotIfOwner();
    });

    return MaterialApp(
      title: 'Siklusku',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(platform: platformOverrideFor(ref.watch(uiStyleProvider))),
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
