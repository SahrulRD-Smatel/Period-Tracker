// lib/notifications/scheduler.dart
// Penjadwalan notifikasi lokal tepat jam 08:00 waktu lokal dengan fallback inexact alarm
// serta pemeriksaan jujur dukungan platform (Android / iOS / macOS vs Windows / Web).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tzlib;

import '../domain/app_settings.dart';
import '../domain/cycle_engine.dart';

const _channelId = 'siklusku_reminders';
const _channelName = 'Pengingat Siklusku';
const _idPeriod = 1;
const _idFertile = 2;
const _idPeriodDayOf = 3;
const _idOvulationDayOf = 4;
const _idTest = 99;

final _plugin = FlutterLocalNotificationsPlugin();

class NotificationScheduleResult {
  final bool supported;
  final int scheduledCount;
  final bool usedInexactFallback;
  final bool permissionDenied;
  final String? errorMessage;

  const NotificationScheduleResult({
    this.supported = true,
    this.scheduledCount = 0,
    this.usedInexactFallback = false,
    this.permissionDenied = false,
    this.errorMessage,
  });
}

class NotificationScheduler {
  NotificationScheduler._();

  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  static NotificationScheduleResult lastResult = const NotificationScheduleResult();

  static Future<void> init() async {
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tzlib.setLocalLocation(tzlib.getLocation(tzInfo.identifier));
    } catch (_) {}

    if (!isSupportedPlatform) {
      lastResult = const NotificationScheduleResult(supported: false);
      return;
    }

    try {
      const android = AndroidInitializationSettings('@drawable/ic_notification');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const settings = InitializationSettings(android: android, iOS: darwin);
      await _plugin.initialize(settings);

      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidPlugin?.requestNotificationsPermission();
        if (granted == false) {
          lastResult = const NotificationScheduleResult(permissionDenied: true);
        }
      }
    } catch (_) {}
  }

  static Future<bool> _scheduleOne({
    required int id,
    required String title,
    required String body,
    required tzlib.TZDateTime scheduled,
    required ValueNotifier<bool> usedInexact,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    } on PlatformException {
      // Fallback otomatis saat izin SCHEDULE_EXACT_ALARM belum diaktifkan di Android 14+
      usedInexact.value = true;
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return true;
    }
  }

  /// Jadwalkan ulang semua notifikasi berdasarkan prediksi dan setelan.
  static Future<NotificationScheduleResult> scheduleFromPrediction(
    CyclePrediction prediction,
    AppSettings s,
  ) async {
    if (!isSupportedPlatform) {
      return lastResult = const NotificationScheduleResult(supported: false);
    }

    try {
      await cancelAll();
      final now = tzlib.TZDateTime.now(tzlib.local);
      var count = 0;
      final usedInexact = ValueNotifier<bool>(false);

      // 1. Pengingat Haid Akan Datang (H-N, jam 08:00)
      if (s.remindPeriod) {
        final target = prediction.current.nextPeriodStart
            .subtract(Duration(days: s.remindDaysBefore));
        final scheduled = tzlib.TZDateTime(
          tzlib.local,
          target.year,
          target.month,
          target.day,
          8,
          0,
        );
        if (scheduled.isAfter(now)) {
          await _scheduleOne(
            id: _idPeriod,
            title: s.discreetNotifications ? 'Pengingat' : 'Haid akan segera datang',
            body: s.discreetNotifications
                ? 'Pengingat jadwalmu.'
                : 'Haid diperkirakan ${s.remindDaysBefore} hari lagi. Siap-siap ya!',
            scheduled: scheduled,
            usedInexact: usedInexact,
          );
          count++;
        }
      }

      // 2. Pengingat Masa Subur Akan Datang (H-N, jam 08:00)
      if (s.remindFertile) {
        final target = prediction.current.fertileStart
            .subtract(Duration(days: s.remindDaysBefore));
        final scheduled = tzlib.TZDateTime(
          tzlib.local,
          target.year,
          target.month,
          target.day,
          8,
          0,
        );
        if (scheduled.isAfter(now)) {
          final daysStr = s.remindDaysBefore == 1
              ? 'besok'
              : '${s.remindDaysBefore} hari lagi';
          await _scheduleOne(
            id: _idFertile,
            title: s.discreetNotifications ? 'Pengingat' : 'Masa subur hampir tiba',
            body: s.discreetNotifications
                ? 'Pengingat jadwalmu.'
                : 'Masa subur dimulai $daysStr!',
            scheduled: scheduled,
            usedInexact: usedInexact,
          );
          count++;
        }
      }

      // 3. Hari-H Haid (Pagi jam 08:00)
      if (s.remindPeriod && s.remindPeriodDayOf) {
        final pDate = prediction.current.nextPeriodStart;
        final scheduled = tzlib.TZDateTime(
          tzlib.local,
          pDate.year,
          pDate.month,
          pDate.day,
          8,
          0,
        );
        if (scheduled.isAfter(now)) {
          await _scheduleOne(
            id: _idPeriodDayOf,
            title: s.discreetNotifications ? 'Pengingat' : 'Perkiraan haid hari ini 🌸',
            body: s.discreetNotifications
                ? 'Pengingat jadwal hari ini.'
                : 'Haidmu diperkirakan mulai hari ini. Jaga kesehatan & istirahat yang cukup ya!',
            scheduled: scheduled,
            usedInexact: usedInexact,
          );
          count++;
        }
      }

      // 4. Hari-H Ovulasi (Pagi jam 08:00)
      if (s.remindFertile && s.remindOvulationDayOf) {
        final oDate = prediction.current.ovulation;
        final scheduled = tzlib.TZDateTime(
          tzlib.local,
          oDate.year,
          oDate.month,
          oDate.day,
          8,
          0,
        );
        if (scheduled.isAfter(now)) {
          await _scheduleOne(
            id: _idOvulationDayOf,
            title: s.discreetNotifications ? 'Pengingat' : 'Puncak masa subur hari ini ✨',
            body: s.discreetNotifications
                ? 'Pengingat jadwal hari ini.'
                : 'Hari ini perkiraan ovulasi (puncak masa subur). Semoga harimu menyenangkan!',
            scheduled: scheduled,
            usedInexact: usedInexact,
          );
          count++;
        }
      }

      return lastResult = NotificationScheduleResult(
        supported: true,
        scheduledCount: count,
        usedInexactFallback: usedInexact.value,
      );
    } catch (e) {
      return lastResult = NotificationScheduleResult(
        supported: true,
        errorMessage: e.toString(),
      );
    }
  }

  /// Mengirim notifikasi uji coba langsung untuk memastikan izin sistem berjalan.
  static Future<bool> sendTestNotification({bool discreet = true}) async {
    if (!isSupportedPlatform) return false;
    try {
      await _plugin.show(
        _idTest,
        discreet ? 'Pengingat Siklusku' : 'Tes Notifikasi Siklusku 🎀',
        discreet
            ? 'Notifikasi pengingat siap bekerja di perangkat ini.'
            : 'Mantap! Pengingat haid & masa subur aktif di perangkatmu 💕',
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> cancelAll() async {
    if (!isSupportedPlatform) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }
}
