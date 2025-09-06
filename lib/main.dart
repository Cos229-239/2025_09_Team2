// Import Flutter's core material design library for UI components
import 'package:flutter/material.dart';
// Import Provider package for state management across the app
import 'package:provider/provider.dart';
// Import all the state providers that manage different parts of app data
import 'package:studypals/providers/app_state.dart';      // Global app state (auth, user session)
import 'package:studypals/providers/task_provider.dart';  // Task management state
import 'package:studypals/providers/note_provider.dart';  // Notes management state
import 'package:studypals/providers/deck_provider.dart';  // Flashcard decks state
import 'package:studypals/providers/pet_provider.dart';   // Virtual pet state
import 'package:studypals/providers/srs_provider.dart';   // Spaced repetition system state
// Import authentication wrapper to handle login/logout flow
import 'package:studypals/screens/auth/auth_wrapper.dart';
// Import app theme configuration for consistent styling
import 'package:studypals/theme/app_theme.dart';
// Import database service for data persistence
import 'package:studypals/services/database_service.dart';

/// Main entry point of the StudyPals application
/// This function runs when the app starts up
void main() async {
  // Ensure Flutter framework is initialized before running async operations
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize database service for storing user data locally
  // This must complete before the app starts to ensure data is available
  await DatabaseService.initialize();
  
  // Launch the main app widget
  runApp(const MyApp());
}

/// Root widget of the StudyPals application
/// This is a StatelessWidget because the root doesn't need to change
class MyApp extends StatelessWidget {
  // Constructor with optional key parameter for widget identification
  const MyApp({super.key});

  /// Builds the widget tree for the entire application
  /// @param context - Build context containing theme, media info, etc.
  /// @return Widget tree representing the entire app
  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state management to all child widgets
    return MultiProvider(
      // List of all state providers that will be available throughout the app
      providers: [
        // Global app state provider for authentication and user session management
        ChangeNotifierProvider(create: (_) => AppState()),
        // Task provider for managing to-do items and assignments
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        // Note provider for managing study notes and documents
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        // Deck provider for managing flashcard collections
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        // Pet provider for managing virtual pet progression and interactions
        ChangeNotifierProvider(create: (_) => PetProvider()),
        // SRS provider for spaced repetition scheduling algorithm
        ChangeNotifierProvider(create: (_) => SRSProvider()),
      ],
      // MaterialApp is the main app container with theme and routing
      child: MaterialApp(
        // App title shown in app switcher and browser tab
        title: 'StudyPals',
        // Light theme configuration for daytime usage
        theme: AppTheme.lightTheme,
        // Dark theme configuration for nighttime usage
        darkTheme: AppTheme.darkTheme,
        // Starting screen - authentication wrapper determines if user sees login or dashboard
        home: const AuthWrapper(),
      ),
    );
  }
}

/// Root widget of the StudyPals application
/// This is a StatelessWidget because the root doesn't need to change
class StudyPalsApp extends StatelessWidget {
  // Constructor with optional key parameter for widget identification
  const StudyPalsApp({super.key});

  /// Builds the widget tree for the entire application
  /// @param context - Build context containing theme, media info, etc.
  /// @return Widget tree representing the entire app
  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state management to all child widgets
    return MultiProvider(
      // List of all state providers that will be available throughout the app
      providers: [
        // Global app state provider for authentication and user session management
        ChangeNotifierProvider(create: (_) => AppState()),
        // Task provider for managing to-do items and assignments
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        // Note provider for managing study notes and documents
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        // Deck provider for managing flashcard collections
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        // Pet provider for managing virtual pet progression and interactions
        ChangeNotifierProvider(create: (_) => PetProvider()),
        // SRS provider for spaced repetition scheduling algorithm
        ChangeNotifierProvider(create: (_) => SRSProvider()),
      ],
      // MaterialApp is the main app container with theme and routing
      child: MaterialApp(
        // App title shown in app switcher and browser tab
        title: 'StudyPals',
        // Light theme configuration for daytime usage
        theme: AppTheme.lightTheme,
        // Dark theme configuration for nighttime usage
        darkTheme: AppTheme.darkTheme,
        // Starting screen - authentication wrapper determines if user sees login or dashboard
        home: const AuthWrapper(),
      ),
    );
  }
}
