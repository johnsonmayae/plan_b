// lib/theme.dart
import 'package:flutter/material.dart';
// Using bundled font files declared in pubspec.yaml instead of google_fonts

ThemeData buildPlanBTheme() {
  // Updated to match screenshot colors
  const background = Color(0xFF0A0E1A);      // Dark navy background
  const surface = Color(0xFF1A2332);         // Slot fill color
  const surfaceVariant = Color(0xFF1E2736);  // Slightly lighter surface
  const primary = Color(0xFF8B7BDD);         // Purple (highlight/Your move text)
  const secondary = Color(0xFF87CEEB);       // Light blue (Player A pieces)
  const tertiary = Color(0xFFFFA54F);        // Orange (Player B pieces)
  const accent = Color(0xFF00CEC9);          // Keep accent as is

  final baseText = const TextStyle(
    fontFamily: 'Inter',
    color: Color(0xFFF5F6FA),
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      tertiary: tertiary,
      surface: surface,
      surfaceVariant: surfaceVariant,
      surfaceContainerHighest: Color(0xFF2A3444), // For chips
      onSurface: Color(0xFFF5F6FA),
      onSurfaceVariant: Color(0xFFCED6E4),
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onTertiary: Colors.black,
      outline: Color(0xFF4A5568),
      outlineVariant: Color(0xFF2D3748),
      shadow: Colors.black,
      // Error colors for forbidden moves
      error: Color(0xFFFF6B6B),
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      headlineMedium: baseText.copyWith(
        fontFamily: 'SpaceGrotesk',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: const Color(0xFFF5F6FA),
      ),
      titleMedium: baseText.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: baseText.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      bodyLarge: baseText.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      bodySmall: baseText.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFCED6E4),
      ),
      labelLarge: baseText.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.0,
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: background,
      elevation: 0,
      centerTitle: true,
      foregroundColor: Color(0xFFF5F6FA),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    useMaterial3: true,
  );
}