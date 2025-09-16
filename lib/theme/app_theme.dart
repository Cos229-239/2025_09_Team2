// Import Flutter's material design theming system
import 'package:flutter/material.dart';

/// App theme configuration class containing light and dark theme definitions
/// Provides consistent styling across the entire StudyPals application
class AppTheme {
  /// Light theme configuration for daytime usage
  /// Uses bright colors and high contrast for better visibility in bright environments
  /// @return ThemeData configured for light mode
  static ThemeData get lightTheme {
    return ThemeData(
      // Enable Material Design 3 components and styling
      useMaterial3: true,

      // Generate a color scheme from a seed color (blue)
      // This creates a harmonious palette of colors that work well together
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue, // Primary color for the app
        brightness: Brightness.light, // Light mode configuration
      ),

      // Customize the bottom navigation bar appearance
      navigationBarTheme: NavigationBarThemeData(
        // Set indicator color with transparency for selected nav items
        indicatorColor: Colors.blue.withValues(alpha: 0.2),
      ),

      // Customize card widgets used throughout the app
      cardTheme: CardThemeData(
        elevation: 2, // Subtle shadow for depth
        shape: RoundedRectangleBorder(
          // Rounded corners for modern look
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Customize text input fields (forms, search bars, etc.)
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Enable background fill
        fillColor: Colors.grey.withValues(alpha: 0.1), // Light grey background

        // Default border style (no visible border)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide.none, // No border line
        ),

        // Border when field is enabled but not focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide.none, // No border line
        ),

        // Border when field is focused (user is typing)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: const BorderSide(
              color: Colors.blue, width: 2), // Blue border to show focus
        ),
      ),

      // Customize elevated buttons used for primary actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Set button padding for comfortable touch targets
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // Round the button corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// Dark theme configuration for nighttime usage
  /// Uses darker colors and reduced contrast to reduce eye strain in low-light environments
  /// @return ThemeData configured for dark mode
  static ThemeData get darkTheme {
    return ThemeData(
      // Enable Material Design 3 components and styling
      useMaterial3: true,

      // Generate a color scheme from a seed color (blue) for dark mode
      // This creates a harmonious palette adapted for dark backgrounds
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue, // Same primary color as light theme
        brightness: Brightness.dark, // Dark mode configuration
      ),

      // Customize the bottom navigation bar for dark theme
      navigationBarTheme: NavigationBarThemeData(
        // Slightly more visible indicator for dark backgrounds
        indicatorColor: Colors.blue.withValues(alpha: 0.3),
      ),

      // Customize card widgets for dark theme
      cardTheme: CardThemeData(
        elevation: 2, // Same shadow depth as light theme
        shape: RoundedRectangleBorder(
          // Consistent rounded corners
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Customize text input fields for dark theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true, // Enable background fill
        fillColor: Colors.grey
            .withValues(alpha: 0.1), // Subtle grey background for dark mode

        // Default border style (no visible border)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide.none, // No border line
        ),

        // Border when field is enabled but not focused
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: BorderSide.none, // No border line
        ),

        // Border when field is focused (user is typing)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8), // Rounded corners
          borderSide: const BorderSide(
              color: Colors.blue, width: 2), // Blue focus border
        ),
      ),

      // Customize elevated buttons for dark theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Same comfortable touch targets as light theme
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          // Consistent rounded corners
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
