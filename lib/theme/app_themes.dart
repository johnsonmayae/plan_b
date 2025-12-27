// lib/theme/app_themes.dart
import 'package:flutter/material.dart';

import 'game_colors.dart';

enum AppThemeId { classic, wood, bw }

/// Material theme factory.
///
/// Notes:
/// - The `classic` palette is kept stable (your original colorway).
/// - Game piece colors come from the `GameColors` ThemeExtension.
class AppThemes {
  static ThemeData light(AppThemeId id) => _build(id, Brightness.light);
  static ThemeData dark(AppThemeId id) => _build(id, Brightness.dark);

  static ThemeData _build(AppThemeId id, Brightness brightness) {
    final cs = _colorScheme(id, brightness);
    final gc = _gameColors(id, brightness);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      extensions: <ThemeExtension<dynamic>>[gc],
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: _pillElevated(cs),
      outlinedButtonTheme: _pillOutlined(cs),
      textButtonTheme: _pillText(cs),
      sliderTheme: SliderThemeData(
        showValueIndicator: ShowValueIndicator.never,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static ElevatedButtonThemeData _pillElevated(ColorScheme cs) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }

  static OutlinedButtonThemeData _pillOutlined(ColorScheme cs) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        foregroundColor: cs.onSurface,
        side: BorderSide(color: cs.outline.withOpacity(0.55)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
    );
  }

  static TextButtonThemeData _pillText(ColorScheme cs) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        foregroundColor: cs.onSurface,
        textStyle: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }

  static ColorScheme _colorScheme(AppThemeId id, Brightness b) {
    switch (id) {
      case AppThemeId.classic:
        // This matches the original "Plan B" dark, high-contrast look.
        if (b == Brightness.dark) {
          return const ColorScheme.dark(
            primary: Color(0xFF6E7BFF),
            onPrimary: Colors.white,
            surface: Color(0xFF070A14),
            onSurface: Color(0xFFE8ECFF),
            surfaceContainerHighest: Color(0xFF10162C),
            outline: Color(0xFF2A355F),
          );
        }
        return const ColorScheme.light(
          primary: Color(0xFF3E4BFF),
          onPrimary: Colors.white,
          surface: Color(0xFFF4F6FF),
          onSurface: Color(0xFF0B1022),
          surfaceContainerHighest: Color(0xFFE6EAFF),
          outline: Color(0xFFC7D0FF),
        );

      case AppThemeId.wood:
        if (b == Brightness.dark) {
          return const ColorScheme.dark(
            primary: Color(0xFFB37B4F),
            onPrimary: Colors.white,
            surface: Color(0xFF0C0A08),
            onSurface: Color(0xFFF1E8DE),
            surfaceContainerHighest: Color(0xFF1A1410),
            outline: Color(0xFF3B2C22),
          );
        }
        return const ColorScheme.light(
          primary: Color(0xFF9B5D2E),
          onPrimary: Colors.white,
          surface: Color(0xFFF7F1EA),
          onSurface: Color(0xFF20140C),
          surfaceContainerHighest: Color(0xFFECE0D3),
          outline: Color(0xFFD8C5B1),
        );

      case AppThemeId.bw:
        if (b == Brightness.dark) {
          return const ColorScheme.dark(
            primary: Color(0xFFF2F2F2),
            onPrimary: Color(0xFF0F0F0F),
            surface: Color(0xFF090909),
            onSurface: Color(0xFFF2F2F2),
            surfaceContainerHighest: Color(0xFF141414),
            outline: Color(0xFF2A2A2A),
          );
        }
        return const ColorScheme.light(
          primary: Color(0xFF111111),
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF111111),
          surfaceContainerHighest: Color(0xFFF2F2F2),
          outline: Color(0xFFCCCCCC),
        );
    }
  }

  static GameColors _gameColors(AppThemeId id, Brightness b) {
    switch (id) {
      case AppThemeId.classic:
        return const GameColors.classic();
      case AppThemeId.wood:
        return const GameColors.wood();
      case AppThemeId.bw:
        return (b == Brightness.dark)
            ? const GameColors.bwDark()
            : const GameColors.bwLight();
    }
  }
}
