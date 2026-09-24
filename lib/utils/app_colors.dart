import 'package:flutter/material.dart';

/// EsselWorld / Water Kingdom brand colors — teal/blue from the
/// waterfall logo as primary, red from the EsselWorld wordmark as
/// the accent/alert color.
class AppColors {
  // Primary — Water Kingdom teal/blue
  static const Color primary = Color(0xFF0E7C86); // deep teal
  static const Color primaryLight = Color(0xFF4FB3BF);
  static const Color primaryDark = Color(0xFF075158);

  // Accent — EsselWorld red
  static const Color accent = Color(0xFFD32F2F);
  static const Color accentLight = Color(0xFFEF5350);

  // Supporting
  static const Color background = Color(0xFFF3F8F9); // faint teal-white
  static const Color surface = Colors.white;
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F); // reuses brand red

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        error: error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
      ),
    );
  }
}