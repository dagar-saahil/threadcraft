import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0B0B0F);
  static const Color surface = Color(0xFF13131A);
  static const Color card = Color(0xFF1A1A24);

  // Neon Primaries
  static const Color purple = Color(0xFF7C3AED);
  static const Color pink = Color(0xFFEC4899);
  static const Color orange = Color(0xFFF97316);
  static const Color blue = Color(0xFF3B82F6);
  static const Color cyan = Color(0xFF06B6D4);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color textMuted = Color(0xFF4B5563);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [purple, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [orange, pink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient coolGradient = LinearGradient(
    colors: [blue, cyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF1A1A24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glow colors (for BoxShadow)
  static Color purpleGlow = purple.withOpacity(0.4);
  static Color pinkGlow = pink.withOpacity(0.4);
  static Color orangeGlow = orange.withOpacity(0.35);
  static Color blueGlow = blue.withOpacity(0.4);
}