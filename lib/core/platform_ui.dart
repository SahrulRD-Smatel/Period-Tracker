// lib/core/platform_ui.dart
// Gaya antarmuka: iOS modern (Cupertino) atau Android modern (Material 3).
// `auto` mengikuti platform perangkat; iOS/Android bisa dipaksa untuk pratinjau (mis. di Windows).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UiStyle { auto, ios, android }

/// Pilihan gaya tampilan. Disimpan di memori: kembali ke Otomatis saat aplikasi dibuka ulang.
final uiStyleProvider = StateProvider<UiStyle>((ref) => UiStyle.auto);

TargetPlatform? platformOverrideFor(UiStyle s) => switch (s) {
      UiStyle.ios => TargetPlatform.iOS,
      UiStyle.android => TargetPlatform.android,
      UiStyle.auto => null,
    };

/// True bila tampilan yang aktif bergaya iOS (iOS / macOS). Selain itu gaya Material.
bool isCupertino(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
}
