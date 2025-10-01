import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Provider for managing app theme state
/// Always uses dark theme
class ThemeProvider extends ChangeNotifier {

  String _currentThemeName = 'Dark';

  /// Current theme name
  String get currentThemeName => _currentThemeName;

  /// Get current theme data
  ThemeData get currentTheme => AppTheme.getThemeByName(_currentThemeName);

  /// Whether the current theme is dark
  bool get isDarkMode => true; // Always dark theme

  /// Get all available themes
  List<String> get availableThemes => AppTheme.availableThemes;

  /// Initialize theme from stored preferences
  Future<void> initialize() async {
    // Always use Dark theme
    _currentThemeName = 'Dark';
    notifyListeners();
  }

  /// Set theme by name and persist to storage
  Future<void> setTheme(String themeName) async {
    // Always use Dark theme, ignore input
    _currentThemeName = 'Dark';
    notifyListeners();
  }

  /// Toggle between light and dark theme (for backwards compatibility)
  Future<void> toggleTheme() async {
    // Always stay on Dark theme, do nothing
    return;
  }

  /// Set theme mode (for backwards compatibility with existing code)
  Future<void> setThemeMode(ThemeMode mode) async {
    // Always use Dark theme regardless of input
    await setTheme('Dark');
  }

  /// Get ThemeMode for backwards compatibility
  ThemeMode get themeMode {
    // Always return dark mode
    return ThemeMode.dark;
  }
}
