import 'package:flutter/material.dart';

import 'game_colors.dart';

class AppThemes {
  // --- WOOD --------------------------------------------------------------
  static final ThemeData woodLight = _themeFromScheme(
    const ColorScheme.light(
      primary: Color(0xFF6D4C41),
      secondary: Color(0xFFBCAAA4),
      surface: Color(0xFFF5F2EE),
      background: Color(0xFFFDFBF8),
      error: Color(0xFFB00020),
    ),
    gameColors: const GameColors(
      playerA: Color(0xFF3E2723),
      playerB: Color(0xFFD7CCC8),
      cpu: Color(0xFF8D6E63),
      highlight: Color(0xFFFFD54F),
      forbidden: Color(0xFFEF5350),
    ),
  );

  static final ThemeData woodDark = _themeFromScheme(
    const ColorScheme.dark(
      primary: Color(0xFFD7CCC8),
      secondary: Color(0xFF8D6E63),
      surface: Color(0xFF1C1412),
      background: Color(0xFF120C0B),
      error: Color(0xFFCF6679),
    ),
    gameColors: const GameColors(
      playerA: Color(0xFF4E342E),
      playerB: Color(0xFFECEFF1),
      cpu: Color(0xFFBCAAA4),
      highlight: Color(0xFFFFD54F),
      forbidden: Color(0xFFEF5350),
    ),
  );

  // --- BLACK & WHITE -----------------------------------------------------
  static final ThemeData bwLight = _themeFromScheme(
    const ColorScheme.light(
      primary: Colors.black,
      secondary: Color(0xFF424242),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF6F6F6),
      error: Color(0xFFB00020),
    ),
    gameColors: const GameColors(
      playerA: Colors.black,
      playerB: Colors.white,
      cpu: Color(0xFF616161),
      highlight: Color(0xFF90A4AE),
      forbidden: Color(0xFFEF5350),
    ),
  );

  static final ThemeData bwDark = _themeFromScheme(
    const ColorScheme.dark(
      primary: Colors.white,
      secondary: Color(0xFFBDBDBD),
      surface: Color(0xFF111111),
      background: Color(0xFF000000),
      error: Color(0xFFCF6679),
    ),
    gameColors: const GameColors(
      playerA: Colors.white,
      playerB: Color(0xFFBDBDBD),
      cpu: Color(0xFF9E9E9E),
      highlight: Color(0xFF90A4AE),
      forbidden: Color(0xFFEF5350),
    ),
  );

  // --- CLASSIC (ORIGINAL) -----------------------------------------------
  static final ThemeData classicLight = _themeFromScheme(
    const ColorScheme.light(
      primary: Color(0xFF141826),
      secondary: Color(0xFF4DD0E1),
      surface: Color(0xFFFFFFFF),
      background: Color(0xFFF7F8FB),
      error: Color(0xFFB00020),
    ),
    gameColors: const GameColors(
      playerA: Color(0xFF4FC3F7),
      playerB: Color(0xFFFF4081),
      cpu: Color(0xFFFFC107),
      highlight: Color(0xFFB39DDB),
      forbidden: Color(0xFFFF5252),
    ),
  );

  static final ThemeData classicDark = _themeFromScheme(
    const ColorScheme.dark(
      primary: Color(0xFF4DD0E1),
      secondary: Color(0xFFCE93D8),
      surface: Color(0xFF050814),
      background: Color(0xFF02030A),
      error: Color(0xFFCF6679),
    ),
    gameColors: const GameColors(
      playerA: Color(0xFF29B6F6),
      playerB: Color(0xFFFF5C93),
      cpu: Color(0xFFFFD54F),
      highlight: Color(0xFF7E57C2),
      forbidden: Color(0xFFFF5252),
    ),
  );

  // --- BASE --------------------------------------------------------------

  static ThemeData _themeFromScheme(
    ColorScheme scheme, {
    required GameColors gameColors,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.background,
      extensions: <ThemeExtension<dynamic>>[gameColors],
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.background,
        foregroundColor: scheme.onBackground,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        labelLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );

    return base.copyWith(
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.secondary,
          side: BorderSide(color: scheme.secondary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surface,
        labelStyle: TextStyle(color: scheme.onSurface),
        selectedColor: scheme.primary.withOpacity(0.16),
      ),
    );
  }
}