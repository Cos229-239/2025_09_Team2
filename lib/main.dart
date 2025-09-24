import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
import 'providers/social_session_provider.dart';
import 'providers/calendar_provider.dart';
import 'providers/planner_provider.dart';

// Import services
import 'services/social_learning_service.dart';

// Import auth wrapper for authentication flow
import 'screens/auth/auth_wrapper.dart';
// Import app wrapper for global functionality
import 'widgets/common/app_wrapper.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('✅ Firebase initialized successfully');
    }
    
    // Enable Firestore offline persistence for better connectivity
    try {
      // Note: This is only needed for mobile platforms, web handles it differently
      if (!kIsWeb) {
        // Import Firestore and enable persistence
        // This will be handled by the FirestoreService when it's first used
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore offline persistence setup issue: $e');
      }
    }
  } catch (e) {
    if (kDebugMode) {
      print('❌ Firebase initialization error: $e');
    }
    rethrow;
  }

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
        ChangeNotifierProvider(create: (_) => SocialSessionProvider()),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => PlannerProvider()),

        // Services
        Provider(create: (_) => SocialLearningService()),
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
