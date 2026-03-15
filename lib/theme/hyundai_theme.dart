import 'package:flutter/material.dart';

class HyundaiColors {
  // Official Hyundai brand palette
  static const Color primary = Color(0xFF002C5F); // Hyundai Navy Blue
  static const Color accent = Color(0xFF00AAD2); // Hyundai Sky Blue
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGrey = Color(0xFFF4F5F7);
  static const Color midGrey = Color(0xFFB0B7C3);
  static const Color darkGrey = Color(0xFF3D4451);
  static const Color success = Color(0xFF00C896);
  static const Color warning = Color(0xFFFFB400);
  static const Color error = Color(0xFFE8003D);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF0F2F5);
}

ThemeData hyundaiTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: HyundaiColors.primary,
      primary: HyundaiColors.primary,
      secondary: HyundaiColors.accent,
      surface: HyundaiColors.cardBg,
      error: HyundaiColors.error,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: HyundaiColors.scaffoldBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: HyundaiColors.primary,
      foregroundColor: HyundaiColors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: HyundaiColors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: HyundaiColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HyundaiColors.primary,
        foregroundColor: HyundaiColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HyundaiColors.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HyundaiColors.primary, width: 2),
      ),
      labelStyle: const TextStyle(color: HyundaiColors.darkGrey),
      prefixIconColor: HyundaiColors.midGrey,
    ),
  );
}
