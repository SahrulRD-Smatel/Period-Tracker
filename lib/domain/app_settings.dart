// lib/domain/app_settings.dart
// Setelan pengguna. Murni Dart. Dipakai juga untuk membentuk CycleSettings milik engine.
import 'cycle_engine.dart';

const kCycleMin = 21, kCycleMax = 45;
const kPeriodMin = 2, kPeriodMax = 10;
const kLutealMin = 10, kLutealMax = 16;

int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

class AppSettings {
  final int cycleLength; // perkiraan awal panjang siklus (dipakai saat data masih sedikit)
  final int periodLength; // perkiraan awal lama haid
  final int lutealLength; // jarak ovulasi -> haid berikutnya
  final bool onboardingDone;
  final bool remindPeriod, remindFertile;
  final bool remindPeriodDayOf; // pengingat tepat di hari H haid
  final bool remindOvulationDayOf; // pengingat tepat di hari H ovulasi
  final int remindDaysBefore; // 1..3
  final bool discreetNotifications; // teks notifikasi netral
  final bool appLock; // kunci biometrik / PIN

  const AppSettings({
    this.cycleLength = 28,
    this.periodLength = 5,
    this.lutealLength = 14,
    this.onboardingDone = false,
    this.remindPeriod = true,
    this.remindFertile = true,
    this.remindPeriodDayOf = true,
    this.remindOvulationDayOf = true,
    this.remindDaysBefore = 2,
    this.discreetNotifications = true,
    this.appLock = false,
  });

  AppSettings copyWith({
    int? cycleLength,
    int? periodLength,
    int? lutealLength,
    bool? onboardingDone,
    bool? remindPeriod,
    bool? remindFertile,
    bool? remindPeriodDayOf,
    bool? remindOvulationDayOf,
    int? remindDaysBefore,
    bool? discreetNotifications,
    bool? appLock,
  }) =>
      AppSettings(
        cycleLength: cycleLength ?? this.cycleLength,
        periodLength: periodLength ?? this.periodLength,
        lutealLength: lutealLength ?? this.lutealLength,
        onboardingDone: onboardingDone ?? this.onboardingDone,
        remindPeriod: remindPeriod ?? this.remindPeriod,
        remindFertile: remindFertile ?? this.remindFertile,
        remindPeriodDayOf: remindPeriodDayOf ?? this.remindPeriodDayOf,
        remindOvulationDayOf: remindOvulationDayOf ?? this.remindOvulationDayOf,
        remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
        discreetNotifications: discreetNotifications ?? this.discreetNotifications,
        appLock: appLock ?? this.appLock,
      );

  CycleSettings toCycleSettings() => CycleSettings(
        defaultCycleLength: cycleLength,
        defaultPeriodLength: periodLength,
        lutealLength: lutealLength,
      );

  Map<String, dynamic> toJson() => {
        'cycleLength': cycleLength,
        'periodLength': periodLength,
        'lutealLength': lutealLength,
        'onboardingDone': onboardingDone,
        'remindPeriod': remindPeriod,
        'remindFertile': remindFertile,
        'remindPeriodDayOf': remindPeriodDayOf,
        'remindOvulationDayOf': remindOvulationDayOf,
        'remindDaysBefore': remindDaysBefore,
        'discreetNotifications': discreetNotifications,
        'appLock': appLock,
      };

  /// Toleran: kunci yang hilang memakai nilai default, angka dijepit ke rentang valid.
  factory AppSettings.fromJson(Map<dynamic, dynamic> j) => AppSettings(
        cycleLength: _clamp((j['cycleLength'] as num?)?.toInt() ?? 28, kCycleMin, kCycleMax),
        periodLength: _clamp((j['periodLength'] as num?)?.toInt() ?? 5, kPeriodMin, kPeriodMax),
        lutealLength: _clamp((j['lutealLength'] as num?)?.toInt() ?? 14, kLutealMin, kLutealMax),
        onboardingDone: j['onboardingDone'] as bool? ?? false,
        remindPeriod: j['remindPeriod'] as bool? ?? true,
        remindFertile: j['remindFertile'] as bool? ?? true,
        remindPeriodDayOf: j['remindPeriodDayOf'] as bool? ?? true,
        remindOvulationDayOf: j['remindOvulationDayOf'] as bool? ?? true,
        remindDaysBefore: _clamp((j['remindDaysBefore'] as num?)?.toInt() ?? 2, 1, 3),
        discreetNotifications: j['discreetNotifications'] as bool? ?? true,
        appLock: j['appLock'] as bool? ?? false,
      );
}
