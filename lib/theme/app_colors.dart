import 'package:flutter/material.dart';

class AppColors {
  // Base dark backgrounds
  static const Color background = Color(0xFF1C2229);
  static const Color backgroundBlack = Color(0xFF000000);

  // Surface containers (Solid matte, no slop blur)
  static const Color surface = Color(0xFF0E1622);
  static const Color surfaceLight = Color(0xFF151F2D);
  static const Color surfaceCard = Color(0xFF101A27);
  static const Color surfaceElevated = Color(0xFF1B2A3B);

  // Typography
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF91A3B8);
  static const Color textMuted = Color(0xFF65788F);

  // High contrast accents
  static const Color accentWhite = Color(0xFFFFFFFF);
  static const Color accentDark = Color(0xFF0F172A);
  static const Color accentPrimary = Color(0xFF55C7FF);
  static const Color primaryButton = Color(0xFF02539A); // Universal Sapphire Primary Button
  static const Color backgroundDark = background;
  static const Color highlightLavender = Color(0xFFA5B4FC);
  static const Color highlightPeriwinkle = Color(0xFF939CFE);

  // Semantic indicators
  static const Color positiveGreen = Color(0xFF10B981);
  static const Color negativeRed = Color(0xFFF43F5E);
  static const Color incomeGreen = positiveGreen;
  static const Color expenseRed = negativeRed;

  static const Color borderSubtle = Color(0x14FFFFFF);

  // Fluid Mesh Gradient for the Card Hero ONLY
  static const List<Color> meshCardGradient = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF38BDF8),
    Color(0xFF34D399),
    Color(0xFFFB923C),
  ];
  static const List<Color> meshGradientColors = meshCardGradient;
}
