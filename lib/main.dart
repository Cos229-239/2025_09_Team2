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

// Import screens
import 'screens/dashboard_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core app state - should be first as other providers may depend on it
        ChangeNotifierProvider(create: (_) => AppState()),
        
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
      child: MaterialApp(
        title: 'StudyPals',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}