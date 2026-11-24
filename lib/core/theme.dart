// lib/core/theme.dart
// Tema default: PUTIH + PINK COQUETTE. Semua warna aplikasi HARUS diambil dari AppColors.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();
  static const white = Color(0xFFFFFFFF);
  static const blush = Color(0xFFFFF5F8); // latar layar
  static const blushWarm = Color(0xFFFFF9FB); // highlight atas kanvas
  static const blushDeeper = Color(0xFFFFF0F5); // bayangan bawah kanvas
  static const petal = Color(0xFFFFE3EC); // pink sangat muda
  static const ribbon = Color(0xFFFFC8DD); // pita / border kartu
  static const pink = Color(0xFFF4A6C0); // pink lembut
  static const rose = Color(0xFFE8587F); // aksen utama (tombol, menstruasi)
  static const roseLight = Color(0xFFFF6B92); // gradient atas tombol
  static const roseDeep = Color(0xFFD6436C); // gradient bawah tombol
  static const lilac = Color(0xFFD8C7F5); // masa subur
  static const honey = Color(0xFFF5C26B); // ovulasi
  static const peach = Color(0xFFFFD6C9); // fase luteal
  static const mist = Color(0xFFC9B6BE); // terlambat / netral
  static const danger = Color(0xFFC62E4D); // aksi destruktif (hapus/cabut)
  static const mauve = Color(0xFF4A303B); // teks utama (lebih pekat & berkelas)
  static const mauveSoft = Color(0xFF8E6B7A); // teks sekunder
  static const shadow = Color(0x26E8587F); // bayangan rose 15%

  // Warna-warna mewah turunan untuk kedalaman Dribbble / Figma
  static const cardBorder = Color(0x38FFB6CE); // garis tepi kartu halus berkilau
  static const cardBorderSubtle = Color(0x20FFB6CE); // garis tepi sangat halus
  static const cardHighlight = Color(0x99FFFFFF); // pantulan cahaya atas
  static const glassWhite = Color(0xF2FFFFFF); // 95% putih susu untuk efek kaca
  static const glassPetal = Color(0xCCFFEBF2); // kaca pink muda
  static const shadowDiffuse = Color(0x18E8587F); // bayangan lembut menyebar
  static const shadowContact = Color(0x0C4A303B); // bayangan kontak dasar

  // Gradien modern siap pakai
  static const primaryGradient = LinearGradient(
    colors: [roseLight, rose],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroCardGradient = LinearGradient(
    colors: [white, Color(0xFFFFF7FB)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const softCardGradient = LinearGradient(
    colors: [Color(0xFFFFF9FC), Color(0xFFFFEEF5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const canvasGradient = LinearGradient(
    colors: [blushWarm, blush, blushDeeper],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 1.0],
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

ThemeData buildAppTheme() {
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: -0.2),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.rose,
        side: const BorderSide(color: AppColors.pink, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    switchTheme: SwitchThemeData(
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
