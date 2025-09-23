// Import Flutter's material design theming system
import 'package:flutter/material.dart';

/// App theme configuration class with advanced Material 3 styling
/// Provides ultra-fun themes with sophisticated design elements
class AppTheme {
  
  /// Available theme options
  static const List<String> availableThemes = [
    'Light',
    'Dark', 
    'Professional',
    'Nature',
    'Sunset',
    'Cosmic',
  ];
  
  /// Get theme by name
  static ThemeData getThemeByName(String themeName) {
    switch (themeName) {
      case 'Light':
        return rainbowParadiseTheme;
      case 'Dark':
        return darkParadiseTheme;
      case 'Professional':
        return modernTechTheme;
      case 'Nature':
        return tropicalParadiseTheme;
      case 'Sunset':
        return volcanoVibesTheme;
      case 'Cosmic':
        return intergalacticRaveTheme;
      default:
        return rainbowParadiseTheme;
    }
  }

  /// Rainbow Paradise Theme - Ultra Fun Light Mode! 🌈✨
  static ThemeData get rainbowParadiseTheme {
    const primaryColor = Color(0xFF6366F1); // Vibrant indigo
    const secondaryColor = Color(0xFFEC4899); // Hot pink
    const tertiaryColor = Color(0xFF10B981); // Emerald green
    const errorColor = Color(0xFFEF4444); // Bright red
    const surfaceColor = Color(0xFFFEFBFF); // Soft lavender white
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: const Color(0xFF1C1B1F),
      ),
      
      // Card theme with fun rounded corners
      cardTheme: CardThemeData(
        elevation: 8.0,
        color: Colors.white,
        shadowColor: primaryColor.withValues(alpha: 0.2),
        surfaceTintColor: tertiaryColor.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: secondaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 6.0,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondaryColor, width: 2),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      
      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: secondaryColor.withValues(alpha: 0.3),
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: primaryColor.withValues(alpha: 0.1),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 24,
        shadowColor: primaryColor.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        elevation: 16,
        shadowColor: primaryColor.withValues(alpha: 0.2),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
      ),
    );
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
          side: BorderSide(
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: TextStyle(color: primaryColor.withValues(alpha: 0.7)),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
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
        labelTextStyle: MaterialStateProperty.resolveWith((states) {
          return TextStyle(
            color: states.contains(MaterialState.selected) ? primaryColor : Colors.white70,
            fontSize: 12,
          );
        }),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      
      // Bottom sheet theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceColor,
        elevation: 0,
        modalBackgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(20),
          ),
          side: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      
      // Progress indicator theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceColor,
        circularTrackColor: surfaceColor,
      ),
      
      // Icon theme
      iconTheme: IconThemeData(
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

  /// Modern Tech Theme - Sleek Professional! 💻⚡
  static ThemeData get modernTechTheme {
    const primaryColor = Color(0xFF0F172A); // Slate dark
    const secondaryColor = Color(0xFF06B6D4); // Bright cyan
    const tertiaryColor = Color(0xFF8B5CF6); // Electric violet
    const errorColor = Color(0xFFEF4444); // Bright red
    const surfaceColor = Color(0xFFF8FAFC); // Cool white
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: const Color(0xFF1E293B),
      ),
      
      // Card theme with modern tech styling
      cardTheme: CardThemeData(
        elevation: 8.0,
        color: Colors.white,
        shadowColor: secondaryColor.withValues(alpha: 0.2),
        surfaceTintColor: tertiaryColor.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: secondaryColor.withValues(alpha: 0.2),
            width: 1.5,
          ),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 6.0,
          shadowColor: primaryColor.withValues(alpha: 0.3),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFCBD5E1).withValues(alpha: 0.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFCBD5E1).withValues(alpha: 0.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: secondaryColor, width: 2.5),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shadowColor: primaryColor.withValues(alpha: 0.2),
      ),
      
      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: secondaryColor.withValues(alpha: 0.2),
        backgroundColor: Colors.white.withValues(alpha: 0.98),
        elevation: 12,
        shadowColor: secondaryColor.withValues(alpha: 0.15),
      ),
    );
  }

  /// Tropical Paradise Theme - Jungle Adventure! 🌺🌴
  static ThemeData get tropicalParadiseTheme {
    const primaryColor = Color(0xFF10B981); // Bright emerald
    const secondaryColor = Color(0xFFFF6B35); // Sunset orange
    const tertiaryColor = Color(0xFF06B6D4); // Tropical ocean
    const errorColor = Color(0xFFFF69B4); // Hot pink flowers
    const surfaceColor = Color(0xFFECFDF5); // Sage whisper
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: const Color(0xFF064E3B),
      ),
      
      // Card theme with organic styling
      cardTheme: CardThemeData(
        elevation: 10.0,
        color: Colors.white,
        shadowColor: secondaryColor.withValues(alpha: 0.3),
        surfaceTintColor: primaryColor.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: errorColor.withValues(alpha: 0.2),
            width: 2,
          ),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 8.0,
          shadowColor: primaryColor.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: secondaryColor, width: 3),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shadowColor: primaryColor.withValues(alpha: 0.3),
      ),
    );
  }

  /// Volcano Vibes Theme - Explosive Energy! 🌋🔥
  static ThemeData get volcanoVibesTheme {
    const primaryColor = Color(0xFFFF4500); // Lava red
    const secondaryColor = Color(0xFFFF1493); // Deep pink
    const tertiaryColor = Color(0xFFFF8C00); // Blazing orange
    const errorColor = Color(0xFFFFD700); // Golden flame
    const surfaceColor = Color(0xFFFFE4E1); // Misty rose
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color scheme
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        error: errorColor,
        surface: surfaceColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.black,
        onSurface: const Color(0xFF8B4513),
      ),
      
      // Card theme with fiery styling
      cardTheme: CardThemeData(
        elevation: 12.0,
        color: const Color(0xFFFFFAF0),
        shadowColor: primaryColor.withValues(alpha: 0.4),
        surfaceTintColor: tertiaryColor.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: errorColor.withValues(alpha: 0.4),
            width: 2,
          ),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 10.0,
          shadowColor: primaryColor.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: tertiaryColor.withValues(alpha: 0.5), width: 2.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: tertiaryColor.withValues(alpha: 0.5), width: 2.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: secondaryColor, width: 3.5),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shadowColor: primaryColor.withValues(alpha: 0.4),
      ),
    );
  }

  /// Intergalactic Rave Theme - Cosmic Party! 🚀🌌✨ (Same as old Dark theme)
  static ThemeData get intergalacticRaveTheme {
    const primaryColor = Color(0xFF8B5CF6); // Electric purple
    const secondaryColor = Color(0xFFFF10F0); // Hot neon pink
    const tertiaryColor = Color(0xFF00FFFF); // Bright cyan
    const errorColor = Color(0xFFFF3366); // Bright neon red
    const surfaceColor = Color(0xFF0F0F23); // Deep dark blue
    
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
        onTertiary: Colors.black,
        onError: Colors.white,
        onSurface: const Color(0xFFE0E0FF),
      ),
      
      // Card theme with neon glow
      cardTheme: CardThemeData(
        elevation: 16.0,
        color: surfaceColor,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        surfaceTintColor: primaryColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: primaryColor.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 12.0,
          shadowColor: primaryColor.withValues(alpha: 0.6),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1A1A2E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: tertiaryColor, width: 3),
        ),
      ),
      
      // App bar theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: const Color(0xFFE0E0FF),
        elevation: 0,
        centerTitle: true,
        shadowColor: primaryColor.withValues(alpha: 0.5),
      ),
      
      // Navigation bar theme
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: primaryColor.withValues(alpha: 0.4),
        backgroundColor: surfaceColor.withValues(alpha: 0.8),
        elevation: 20,
        shadowColor: primaryColor.withValues(alpha: 0.3),
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceColor,
        elevation: 32,
        shadowColor: primaryColor.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
      ),
    );
  }
}