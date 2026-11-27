// lib/core/theme.dart
// Tema default: PUTIH + PINK COQUETTE. Semua warna aplikasi HARUS diambil dari AppColors.
import 'package:flutter/cupertino.dart' show CupertinoThemeData;
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const white = Color(0xFFFFFFFF);
  static const whiteSoft = Color(0xEBFFFFFF); // putih lembut 92% untuk subjudul di atas pink
  static const transparent = Color(0x00000000);
  static const blush = Color(0xFFFFF1F4); // latar layar
  static const blushWarm = Color(0xFFFFF9FB); // highlight atas kanvas
  static const blushDeeper = Color(0xFFFFF0F5); // bayangan bawah kanvas
  static const petal = Color(0xFFFFD9E1); // pink sangat muda
  static const ribbon = Color(0xFFFFB9C9); // pita / border kartu
  static const pink = Color(0xFFFF9BAE); // pink lembut
  static const rose = Color(0xFFFF6F8B); // aksen utama (tombol, menstruasi)
  static const roseLight = Color(0xFFFF9BAE); // gradient atas tombol
  static const roseDeep = Color(0xFFF2587A); // gradient bawah tombol
  static const lilac = Color(0xFFE6DCFF); // masa subur
  static const honey = Color(0xFFFFD98A); // ovulasi
  static const peach = Color(0xFFD8E6FF); // fase luteal (biru pastel ala Cyra)
  static const mist = Color(0xFFE3E3E6); // terlambat / netral
  static const danger = Color(0xFFC62E4D); // aksi destruktif (hapus/cabut)
  static const mauve = Color(0xFF1B1B1F); // teks utama (lebih pekat & berkelas)
  static const mauveSoft = Color(0xFF8D8D95); // teks sekunder
  static const shadow = Color(0x26FF6F8B); // bayangan rose 15%
  static const track = Color(0xFFF2F2F3); // jalur cincin siklus (Cyra)
  static const dock = Color(0xFF1C1C20); // dock navigasi gelap (Cyra)

  // Warna-warna mewah turunan untuk kedalaman Dribbble / Figma
  static const cardBorder = Color(0x38FFB6CE); // garis tepi kartu halus berkilau
  static const cardBorderSubtle = Color(0x20FFB6CE); // garis tepi sangat halus
  static const cardHighlight = Color(0x99FFFFFF); // pantulan cahaya atas
  static const glassWhite = Color(0xF2FFFFFF); // 95% putih susu untuk efek kaca
  static const glassPetal = Color(0xCCFFEBF2); // kaca pink muda
  static const shadowDiffuse = Color(0x1FFF6F8B); // bayangan lembut menyebar
  static const shadowContact = Color(0x0C1B1B1F); // bayangan kontak dasar
  static const petalGradientEnd = Color(0xFFFFD4E2); // ujung gradien kelopak
  static const dialogShadow = Color(0x1FDD869E); // bayangan dialog lembut

  // Gradien modern siap pakai
  static const primaryGradient = LinearGradient(
    colors: [roseLight, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCardGradient = LinearGradient(
    colors: [white, Color(0xFFFFFFFF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const softCardGradient = LinearGradient(
    colors: [Color(0xFFFFF9FC), Color(0xFFFFEEF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const canvasGradient = LinearGradient(
    colors: [roseDeep, rose, petal, white],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.42, 0.72, 1.0],
  );
}

/// Gaya judul modern coquette: geometric clean sans-serif berbobot mantap.
const kHeading = TextStyle(
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  color: AppColors.mauve,
);

const kSubheading = TextStyle(
  fontWeight: FontWeight.w600,
  fontSize: 16,
  letterSpacing: -0.2,
  color: AppColors.mauve,
);

const kSmall = TextStyle(
  color: AppColors.mauveSoft,
  fontSize: 13,
  height: 1.4,
  fontWeight: FontWeight.w400,
);

const kMicroCaps = TextStyle(
  color: AppColors.mauveSoft,
  fontSize: 11,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.4,
);

ThemeData buildAppTheme({TargetPlatform? platform}) {
  final p = platform ?? defaultTargetPlatform;
  final ios = p == TargetPlatform.iOS || p == TargetPlatform.macOS;
  final scheme = ColorScheme.fromSeed(seedColor: AppColors.pink).copyWith(
    primary: AppColors.rose,
    onPrimary: AppColors.white,
    secondary: AppColors.pink,
    onSecondary: AppColors.mauve,
    surface: AppColors.white,
    onSurface: AppColors.mauve,
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.blush,
    platform: platform,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AppColors.mauve, displayColor: AppColors.mauve),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.rose,
        foregroundColor: AppColors.white,
        elevation: 4,
        shadowColor: AppColors.shadowDiffuse,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rose,
        side: const BorderSide(color: AppColors.pink, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    splashFactory: ios ? NoSplash.splashFactory : null,
    cupertinoOverrideTheme: const CupertinoThemeData(primaryColor: AppColors.rose),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.blush,
      surfaceTintColor: AppColors.transparent,
      foregroundColor: AppColors.mauve,
      scrolledUnderElevation: 0,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      surfaceTintColor: AppColors.transparent,
      indicatorColor: AppColors.petal,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? AppColors.rose : AppColors.mauve),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => TextStyle(
          fontSize: 12,
          fontWeight: s.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          color: s.contains(WidgetState.selected) ? AppColors.mauve : AppColors.mauveSoft,
        ),
      ),
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.all(AppColors.transparent),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? AppColors.rose : AppColors.ribbon,
      ),
      thumbColor: WidgetStateProperty.all(AppColors.white),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.mauve,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
  );
}
