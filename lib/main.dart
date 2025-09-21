import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import all providers
import 'providers/app_state.dart';
import 'providers/pet_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/spotify_provider.dart';
import 'providers/task_provider.dart';
import 'providers/note_provider.dart';
import 'providers/deck_provider.dart';
import 'providers/srs_provider.dart';
import 'providers/daily_quest_provider.dart';
import 'providers/ai_provider.dart';
import 'providers/theme_provider.dart';

// Import auth wrapper for authentication flow
import 'screens/auth/auth_wrapper.dart';
// Import app wrapper for global functionality
import 'widgets/common/app_wrapper.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize theme provider
  final themeProvider = ThemeProvider();
  await themeProvider.initialize();
  
  runApp(MyApp(themeProvider: themeProvider));
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider;
  
  const MyApp({super.key, required this.themeProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core app state - should be first as other providers may depend on it
        ChangeNotifierProvider(create: (_) => AppState()),
        
        // Theme provider
        ChangeNotifierProvider.value(value: themeProvider),
        
        // Feature providers
        ChangeNotifierProvider(create: (_) => PetProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SpotifyProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => DeckProvider()),
        ChangeNotifierProvider(create: (_) => SRSProvider()),
        ChangeNotifierProvider(create: (_) => DailyQuestProvider()),
        ChangeNotifierProvider(create: (_) => StudyPalsAIProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'StudyPals',
            theme: themeProvider.currentTheme,
            home: const AppWrapper(
              child: AuthWrapper(),
            ),
          );
        },
      ),
    );
  }
}