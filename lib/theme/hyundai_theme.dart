/// Kona-inspired theme: warm fawn/sandstone tones for light and dark modes.
///
// Time-stamp: <Monday 2026-03-17 00:00:00 +1100 Graham Williams>
///
/// Copyright (C) 2026, Togaware Pty Ltd
///
/// Licensed under the GNU General Public License, Version 3 (the "License");
///
/// License: https://opensource.org/license/gpl-3-0
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU General Public License as published by the Free Software
// Foundation, either version 3 of the License, or (at your option) any later
// version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
// details.
//
// You should have received a copy of the GNU General Public License along with
// this program.  If not, see <https://opensource.org/license/gpl-3-0>.
///
/// Authors: Claude, Graham Williams

library;

import 'package:flutter/material.dart';

/// Kona-inspired colour palette.
///
/// Primary tones are drawn from the Kona's "Velvet Dune" / sandstone exterior
/// and the warm taupe interior trim. Accent is a muted terracotta/copper to
/// complement the fawn without clashing. Neutrals are warm-grey rather than
/// cold blue-grey.
class HyundaiColors {
  // ── Primary / brand ──────────────────────────────────────────────────────
  /// Warm dark taupe — replaces Hyundai navy as the primary brand colour.
  static const Color primary = Color(0xFF4A3728);

  /// Muted terracotta/copper — replaces cyan as the accent.
  static const Color accent = Color(0xFFB5714A);

  // ── Neutrals (warm-grey family) ───────────────────────────────────────────
  static const Color white      = Color(0xFFFFFFFF);
  static const Color lightGrey  = Color(0xFFF5F2EE); // warm off-white
  static const Color midGrey    = Color(0xFFAA9E95);  // warm mid-tone
  static const Color darkGrey   = Color(0xFF3D342C);  // warm dark

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color success    = Color(0xFF5A8A5A);  // muted sage green
  static const Color warning    = Color(0xFFCC8C30);  // warm amber
  static const Color error      = Color(0xFFB03030);  // muted red

  // ── Surface ───────────────────────────────────────────────────────────────
  static const Color cardBg     = Color(0xFFFFFFFF);
  static const Color scaffoldBg = Color(0xFFF0EBE4);  // warm fawn/sand
}

ThemeData hyundaiLightTheme() => hyundaiTheme(Brightness.light);
ThemeData hyundaiDarkTheme()  => hyundaiTheme(Brightness.dark);

ThemeData hyundaiTheme([Brightness brightness = Brightness.light]) {
  final isDark = brightness == Brightness.dark;

  final colorScheme = isDark
      ? const ColorScheme.dark(
          primary:                 HyundaiColors.accent,
          secondary:               HyundaiColors.primary,
          surface:                 Color(0xFF2A2218),  // dark warm brown
          surfaceContainerHighest: Color(0xFF352D22),  // slightly lighter
          onSurface:               Color(0xFFF0E8DC),  // warm off-white
          onSurfaceVariant:        Color(0xFFAA9E95),
          outlineVariant:          Color(0xFF4A3C30),
          error:                   HyundaiColors.error,
        )
      : ColorScheme.fromSeed(
          seedColor:  HyundaiColors.primary,
          primary:    HyundaiColors.primary,
          secondary:  HyundaiColors.accent,
          surface:    HyundaiColors.cardBg,
          error:      HyundaiColors.error,
          brightness: Brightness.light,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor:
        isDark ? const Color(0xFF1C1510) : HyundaiColors.scaffoldBg,
    appBarTheme: const AppBarTheme(
      backgroundColor: HyundaiColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: isDark ? const Color(0xFF2A2218) : HyundaiColors.cardBg,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HyundaiColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      fillColor: isDark ? const Color(0xFF352D22) : HyundaiColors.lightGrey,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isDark
            ? const BorderSide(color: Color(0xFF5A4A38), width: 1)
            : BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: isDark
            ? const BorderSide(color: Color(0xFF5A4A38), width: 1)
            : BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? HyundaiColors.accent : HyundaiColors.primary,
          width: 2,
        ),
      ),
      labelStyle: TextStyle(
          color: isDark ? Colors.white70 : HyundaiColors.darkGrey),
      hintStyle: TextStyle(
          color: isDark ? Colors.white38 : HyundaiColors.midGrey),
      prefixIconColor:
          isDark ? Colors.white54 : HyundaiColors.midGrey,
    ),
  );
}
