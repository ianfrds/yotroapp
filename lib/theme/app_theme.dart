import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = ThemeData.dark().textTheme.apply(fontFamily: GoogleFonts.manrope().fontFamily);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.accentWhite,
        onPrimary: AppColors.backgroundBlack,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        background: AppColors.background,
        onBackground: AppColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.interTight(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.interTight(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.interTight(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.interTight(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.interTight(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.interTight(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        titleMedium: GoogleFonts.interTight(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.textSecondary,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF131A26),
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A3545), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }

  static ThemeData get lightTheme {
    final baseTextTheme = ThemeData.light().textTheme.apply(fontFamily: GoogleFonts.manrope().fontFamily);
    const lightTextPrimary = Color(0xFF0F172A);
    const lightTextSecondary = Color(0xFF475569);
    const lightTextMuted = Color(0xFF64748B);
    const lightBg = Color(0xFFF4F5F7);
    const lightSurface = Color(0xFFFFFFFF);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: lightTextPrimary,
        onPrimary: Colors.white,
        surface: lightSurface,
        onSurface: lightTextPrimary,
        background: lightBg,
        onBackground: lightTextPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: GoogleFonts.interTight(
          color: lightTextPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.interTight(
          fontSize: 34,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.6,
        ),
        displayMedium: GoogleFonts.interTight(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
          letterSpacing: -0.5,
        ),
        headlineLarge: GoogleFonts.interTight(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        headlineMedium: GoogleFonts.interTight(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleLarge: GoogleFonts.interTight(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        titleMedium: GoogleFonts.interTight(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: lightTextPrimary,
        ),
        bodyLarge: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: lightTextPrimary,
        ),
        bodyMedium: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: lightTextSecondary,
        ),
        labelSmall: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF131A26),
        contentTextStyle: GoogleFonts.manrope(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF2A3545), width: 1),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),
    );
  }
}
