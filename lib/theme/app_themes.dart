// lib/theme/app_themes.dart
import 'package:flutter/material.dart';

import 'game_colors.dart';

enum AppThemeId { classic, wood, bw }

/// Material theme factory.
///
/// Notes:
/// - The `classic` palette matches your screenshot's dark navy theme.
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
        elevation: 0,
        centerTitle: true,
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
        // Updated to match your screenshot's dark navy theme
        if (b == Brightness.dark) {
          return const ColorScheme.dark(
            primary: Color(0xFF8B7BDD),         // Purple (highlight/Your move)
            secondary: Color(0xFF87CEEB),       // Light blue (Player A pieces)
            tertiary: Color(0xFFFFA54F),        // Orange (Player B pieces)
            onPrimary: Colors.white,
            surface: Color(0xFF0A0E1A),         // Dark navy background
            onSurface: Color(0xFFF5F6FA),       // Light text
            surfaceVariant: Color(0xFF1E2736),
            surfaceContainerHighest: Color(0xFF2A3444),
            onSurfaceVariant: Color(0xFFCED6E4),
            outline: Color(0xFF4A5568),
            outlineVariant: Color(0xFF2D3748),
            shadow: Colors.black,
            error: Color(0xFFFF6B6B),
            onError: Colors.white,
          );
        }
        // Light mode version of classic
        return const ColorScheme.light(
          primary: Color(0xFF6B5CE7),           // Lighter purple for light mode
          secondary: Color(0xFF4A9FD8),         // Darker blue for visibility
          tertiary: Color(0xFFFF8C42),          // Darker orange for visibility
          onPrimary: Colors.white,
          surface: Color(0xFFF5F6FA),           // Light background
          onSurface: Color(0xFF1A1F2E),         // Dark text
          surfaceVariant: Color(0xFFE8ECFF),
          surfaceContainerHighest: Color(0xFFDCE2F5),
          onSurfaceVariant: Color(0xFF4A5568),
          outline: Color(0xFFB8C2D9),
          outlineVariant: Color(0xFFD1DAED),
          shadow: Color(0xFF1A1F2E),
          error: Color(0xFFE53E3E),
          onError: Colors.white,
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
            primary: Color(0xFFF2F2F2),      // Light gray buttons
            onPrimary: Color(0xFF000000),    // Black text on light buttons
            surface: Color(0xFF090909),
            onSurface: Color(0xFFF2F2F2),
            surfaceContainerHighest: Color(0xFF141414),
            outline: Color(0xFF2A2A2A),
          );
        }
        return const ColorScheme.light(
          primary: Color(0xFF1A1A1A),        // Dark buttons
          onPrimary: Color(0xFFFFFFFF),      // White text on dark buttons
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
        return b == Brightness.dark
            ? const GameColors.bwDark()
            : const GameColors.bwLight();
    }
  }
}