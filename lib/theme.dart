// lib/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

ThemeData buildPlanBTheme() {
  const background = Color(0xFF050814);
  const surface = Color(0xFF0B1020);
  const primary = Color(0xFF6C5CE7);
  const accent = Color(0xFF00CEC9);

  final baseText = GoogleFonts.inter(
    color: const Color(0xFFF5F6FA),
  );

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: accent,
      surface: surface,
    ),
    textTheme: TextTheme(
      headlineMedium: GoogleFonts.spaceGrotesk(
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
    ),
    useMaterial3: true,
  );
}
