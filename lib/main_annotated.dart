/// StudyPals Application - Main Entry Point
///
/// This file initializes the Flutter application with all necessary providers
/// and sets up the database service for cross-platform compatibility.
///
/// Key Components:
/// - Database initialization for web/mobile platforms
/// - Provider setup for state management
/// - Theme configuration
/// - Authentication wrapper
///
/// @author StudyPals Development(s) plural Team
/// @version 1.0.0
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/app_state.dart';
import 'package:studypals/providers/task_provider.dart';
import 'package:studypals/providers/note_provider.dart';
import 'package:studypals/providers/deck_provider.dart';
import 'package:studypals/providers/pet_provider.dart';
import 'package:studypals/providers/srs_provider.dart';
import 'package:studypals/providers/ai_provider.dart';
import 'package:studypals/screens/auth/auth_wrapper.dart';
import 'package:studypals/theme/app_theme.dart';
import 'package:studypals/services/database_service.dart';

/// Application entry point
///
/// Initializes the Flutter framework and database service before
/// launching the main application widget.
void main() async {
  // Ensure Flutter framework is properly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database service for cross-platform compatibility
  await DatabaseService.initialize();

  // Launch the application
  runApp(const StudyPalsApp());
}

/// Main Application Widget
///
/// Sets up the provider hierarchy for state management and configures
/// the MaterialApp with theming and routing.
///
/// Provider Hierarchy:
/// - AppState: Global authentication and user session
/// - TaskProvider: Task management and CRUD operations
/// - NoteProvider: Note management and organization
/// - DeckProvider: Flashcard deck management
/// - PetProvider: Virtual pet progression and interactions
/// - SRSProvider: Spaced repetition system scheduling
class StudyPalsApp extends StatelessWidget {
  const StudyPalsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Authentication and global state
        ChangeNotifierProvider(create: (_) => AppState()),

        // Core feature providers
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),

        // Gamification providers
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => SRSProvider()),

        // AI-powered features
        ChangeNotifierProvider(create: (_) => StudyPalsAIProvider()),
      ],
      child: MaterialApp(
        title: 'StudyPals',

        // Theme configuration
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Follows system preference

        // Remove debug banner in release builds
        debugShowCheckedModeBanner: false,

        // Authentication-aware routing
        home: const AuthWrapper(),
      ),
    );
  }
}
