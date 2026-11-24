// lib/notifications/scheduler.dart
// Jadwalkan notifikasi lokal haid & masa subur tepat jam 08:00 pagi waktu lokal.
import 'package:flutter/foundation.dart';
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

final _plugin = FlutterLocalNotificationsPlugin();

class NotificationScheduler {
  NotificationScheduler._();

  static Future<void> init() async {
    // Inisialisasi timezone
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tzlib.setLocalLocation(tzlib.getLocation(tzInfo.identifier));
    } catch (_) {
      // Fallback ke UTC bila gagal (misalnya di desktop/test)
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

      // Minta izin Android 13+
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
      }
    } catch (_) {
      // Abaikan di lingkungan test
    }
  }

  /// Jadwalkan ulang semua notifikasi berdasarkan prediksi dan setelan.
  static Future<void> scheduleFromPrediction(
    CyclePrediction prediction,
    AppSettings s,
  ) async {
    try {
      await cancelAll();

      final now = tzlib.TZDateTime.now(tzlib.local);

      // 1. Pengingat Haid Akan Datang (H-N, jam 08:00 pagi)
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
          await _plugin.zonedSchedule(
            _idPeriod,
            s.discreetNotifications ? 'Pengingat' : 'Haid akan segera datang',
            s.discreetNotifications
                ? 'Pengingat jadwalmu.'
                : 'Haid diperkirakan ${s.remindDaysBefore} hari lagi. Siap-siap ya!',
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // 2. Pengingat Masa Subur Akan Datang (H-N, jam 08:00 pagi)
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
          await _plugin.zonedSchedule(
            _idFertile,
            s.discreetNotifications ? 'Pengingat' : 'Masa subur hampir tiba',
            s.discreetNotifications
                ? 'Pengingat jadwalmu.'
                : 'Masa subur dimulai $daysStr!',
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
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
          await _plugin.zonedSchedule(
            _idPeriodDayOf,
            s.discreetNotifications ? 'Pengingat' : 'Haid diperkirakan mulai hari ini 🌸',
            s.discreetNotifications
                ? 'Pengingat jadwal hari ini.'
                : 'Hari pertama haid diperkirakan hari ini. Siapkan perlengkapan dan jaga kenyamanan tubuhmu ya!',
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }

      // 4. Hari-H Ovulasi (Puncak Masa Subur - Pagi jam 08:00)
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
          await _plugin.zonedSchedule(
            _idOvulationDayOf,
            s.discreetNotifications ? 'Pengingat' : 'Puncak masa subur hari ini ✨',
            s.discreetNotifications
                ? 'Pengingat jadwal hari ini.'
                : 'Hari ini perkiraan ovulasi (puncak masa subur). Semoga harimu menyenangkan dan berenergi!',
            scheduled,
            NotificationDetails(
              android: AndroidNotificationDetails(
                _channelId,
                _channelName,
                importance: Importance.high,
                priority: Priority.high,
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    } catch (_) {
      // Abaikan bila di lingkungan test atau platform tanpa dukungan notifikasi
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (_) {
      // Abaikan di lingkungan test
    }
  }
}
