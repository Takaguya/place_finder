import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// The app's colours, following the D2D prototype.
abstract final class AppColors {
  static const ink = Color(0xFF17171E);
  static const blue = Color(0xFF2C4BFF);
  static const yellow = Color(0xFFFFDB00);
  static const white = Color(0xFFFFFFFF);

  /// Secondary text. Passes contrast on white, but not on [yellow].
  static const slate = Color(0xFF5F6675);
  static const line = Color(0xFFE7E9EF);
  static const mist = Color(0xFFF2F3F6);

  static const land = Color(0xFFE7EAE3);
  static const water = Color(0xFFBFDEE8);
  static const park = Color(0xFFCBE0C3);
  static const majorRoad = Color(0xFFF2DFA9);
  static const mapLabel = Color(0xFF5E6A5C);

  static const open = Color(0xFF0B7A52);
  static const closed = Color(0xFFC42F36);
}

abstract final class AppTheme {
  /// Space Grotesk carries names and numbers. Manrope carries everything else.
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.white,
      fontFamily: GoogleFonts.manrope().fontFamily,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.blue).copyWith(
        primary: AppColors.blue,
        onPrimary: AppColors.white,
        secondary: AppColors.yellow,
        onSecondary: AppColors.ink,
        surface: AppColors.white,
        onSurface: AppColors.ink,
      ),
      textTheme: TextTheme(
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          height: 1.2,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 14,
          height: 1.45,
          fontWeight: FontWeight.w500,
          color: AppColors.ink,
        ),
        bodySmall: GoogleFonts.manrope(
          fontSize: 13,
          height: 1.35,
          fontWeight: FontWeight.w500,
          color: AppColors.slate,
        ),
        labelLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        labelMedium: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.mapLabel,
        ),
      ),
    );
  }
}
