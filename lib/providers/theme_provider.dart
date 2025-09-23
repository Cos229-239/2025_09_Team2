import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';

/// Provider for managing app theme state
/// Handles switching between multiple custom themes with persistence
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'selected_theme';
  
  String _currentThemeName = 'Dark';
  
  /// Current theme name
  String get currentThemeName => _currentThemeName;
  
  /// Get current theme data
  ThemeData get currentTheme => AppTheme.getThemeByName(_currentThemeName);
  
  /// Whether the current theme is dark
  bool get isDarkMode => _currentThemeName == 'Dark' || _currentThemeName == 'Cosmic';
  
  /// Get all available themes
  List<String> get availableThemes => AppTheme.availableThemes;
  
  /// Initialize theme from stored preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString(_themeKey) ?? 'Cosmic';
    
    // Validate theme name exists
    if (AppTheme.availableThemes.contains(themeName)) {
      _currentThemeName = themeName;
    } else {
      _currentThemeName = 'Dark';
    }
    
    notifyListeners();
  }
  
  /// Set theme by name and persist to storage
  Future<void> setTheme(String themeName) async {
    if (_currentThemeName == themeName) return;
    
    if (!AppTheme.availableThemes.contains(themeName)) {
      throw ArgumentError('Theme "$themeName" not found');
    }
    
    _currentThemeName = themeName;
    notifyListeners();
    
    // Persist theme preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, themeName);
  }
  
  /// Toggle between light and dark theme (for backwards compatibility)
  Future<void> toggleTheme() async {
    final newTheme = _currentThemeName == 'Cosmic' ? 'Light' : 'Cosmic';
    await setTheme(newTheme);
  }
  
  /// Set theme mode (for backwards compatibility with existing code)
  Future<void> setThemeMode(ThemeMode mode) async {
    String themeName;
    switch (mode) {
      case ThemeMode.light:
        themeName = 'Light';
        break;
      case ThemeMode.dark:
        themeName = 'Dark';
        break;
      case ThemeMode.system:
        // For system mode, we'll default to cosmic theme
        // In a full implementation, you'd check the system theme
        themeName = 'Cosmic';
        break;
    }
    await setTheme(themeName);
  }
  
  /// Get ThemeMode for backwards compatibility
  ThemeMode get themeMode {
    switch (_currentThemeName) {
      case 'Light':
        return ThemeMode.light;
      case 'Dark':
      case 'Cosmic':
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }
}
