// Import Flutter's material design components for UI
import 'package:flutter/material.dart';
// Import Provider for accessing app state across widgets
import 'package:provider/provider.dart';
// Import the global app state that tracks authentication status
import 'package:studypals/providers/app_state.dart';
// Import the main dashboard screen shown to authenticated users
import 'package:studypals/screens/dashboard_screen.dart';
// Import the login screen shown to unauthenticated users
import 'package:studypals/screens/auth/login_screen.dart';

/// Authentication wrapper that decides which screen to show based on login status
/// This widget acts as a router - it shows login screen for guests and dashboard for logged-in users
class AuthWrapper extends StatelessWidget {
  // Constructor with optional key for widget identification
  const AuthWrapper({super.key});

  /// Builds the appropriate screen based on authentication state
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree showing either login screen or dashboard
  @override
  Widget build(BuildContext context) {
    // Consumer listens to AppState changes and rebuilds when authentication status changes
    return Consumer<AppState>(
      // Builder function called whenever AppState notifies of changes
      // @param context - Build context passed from Consumer
      // @param appState - Current instance of AppState with authentication data
      // @param child - Unused child widget (could be used for optimization)
      builder: (context, appState, child) {
        // Check if user is currently logged in
        if (appState.isAuthenticated) {
          // User is logged in - show the main dashboard with all app features
          return const DashboardScreen();
        } else {
          // User is not logged in - show login screen to collect credentials
          return const LoginScreen();
        }
      },
    );
  }
}
