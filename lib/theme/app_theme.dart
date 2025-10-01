// Import Flutter's material design theming system
import 'package:flutter/material.dart';

/// App theme configuration class with advanced Material 3 styling
/// Provides ultra-fun themes with sophisticated design elements
class AppTheme {
  /// Available theme options
  static const List<String> availableThemes = [
    'Dark',
  ];

  /// Get theme by name
  static ThemeData getThemeByName(String themeName) {
    switch (themeName) {
      case 'Dark':
        return darkParadiseTheme;
      default:
        return darkParadiseTheme;
    }
  }

  /// StudyPals Dark Theme - Based on Dashboard Design
  static ThemeData get darkParadiseTheme {
    const primaryColor = Color(0xFFF8B67F); // Flash Cards border color
    const secondaryColor = Color(0xFFF8B67F); // Same as primary for consistency
    const tertiaryColor = Color(0xFFF8B67F); // Same as primary for consistency
    const errorColor = Color(0xFFEF5350); // Error red
    const surfaceColor = Color(0xFF2A3050); // Dark background color

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: const Color(0xFFF9FAFB),
      ),

      // Card theme matching dashboard design
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: primaryColor,
            width: 2.0,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.transparent),
          ),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: primaryColor.withValues(alpha: 0.7)),
      ),

      // App bar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryColor),
      ),

      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withValues(alpha: 0.3),
        backgroundColor: surfaceColor,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(WidgetState.selected)
                ? primaryColor
                : Colors.white70,
            fontSize: 12,
          );
        }),
      ),

      // Dialog theme
      dialogTheme: const DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
          side: BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // Bottom sheet theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        modalBackgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          side: BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // Progress indicator theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
        circularTrackColor: surfaceColor,
      ),

      // Icon theme
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),

      // Divider theme
      dividerTheme: DividerThemeData(
        color: primaryColor.withValues(alpha: 0.1),
        thickness: 1,
      ),
    );
  }
}
