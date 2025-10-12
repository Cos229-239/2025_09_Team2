import 'package:flutter/material.dart';

/// Application color constants
class AppColors {
  // Primary colors
  static const primaryAccent =
      Color(0xFF6FB8E9); // New blue border color from Figma
  static const primaryBackground = Color(0xFF2A3050); // Dark background color

  // Text colors
  static const textPrimary = Color(0xFFD9D9D9);
  static const textSecondary =
      Color(0xFFD9D9D9); // Same as primary for consistency
  static const textMuted = Color(0xFFD9D9D9); // Same as primary for consistency

  // Status colors
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFA726);
  static const error = Color(0xFFEF5350);
  static const info = Color(0xFF42A5F5);

  // Container colors
  static const cardBackground = primaryBackground;
  static const surfaceBackground =
      Color(0xFF1A1F35); // Darker shade for surfaces
  static const divider = Color(0x1FFFFFFF); // 12% white

  // Gradient colors
  static const gradientStart = primaryBackground;
  static const gradientEnd = Color(0xFF3A4268); // Lighter shade of background

  // Shadow colors
  static const shadowLight = Color(0x40000000); // 25% black
  static const shadowDark = Color(0x80000000); // 50% black
}

/// Border radius constants
class AppRadius {
  static const small = 6.0;
  static const medium = 12.0;
  static const large = 16.0;
  static const extraLarge = 24.0;
}

/// Spacing constants
class AppSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
}

/// Border width constants
class AppBorders {
  static const thin = 1.0;
  static const normal = 2.0;
  static const thick = 3.0;
}
