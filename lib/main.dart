// StudyPals Flutter Application Entry Point
// TODO: CRITICAL STUDYPALS APPLICATION ARCHITECTURE GAPS
// 
// MAJOR MISSING SERVICES (NOT IMPLEMENTED):
// - StudyService: Core study session management and analytics
// - FileService: File upload, sharing, and management 
// - ImageService: Image processing, upload, and optimization
// - AudioService: Voice recording, audio processing, and playback
// - VideoService: Video recording, processing, and streaming
// - ExportService: Data export, backup, and migration
// - SearchService: Global search across all user content
// - AnalyticsService: User behavior tracking and insights
// - ReportingService: Progress reports and analytics dashboards
// - CalendarSyncService: External calendar integration (Google, Outlook)
// - WebRTCService: Real-time communication infrastructure
// - FCMService: Push notification management
// - UserService: Comprehensive user management and profiles
// - AdminService: Administrative functions and moderation
// - CacheService: Intelligent caching and offline support
// - SecurityService: Encryption, validation, and security monitoring
// - ConfigService: Dynamic configuration and feature flags
// - LoggingService: Comprehensive application logging and monitoring
// - BackupService: Automated data backup and recovery
// - MigrationService: Data migration and schema updates
// 
// MAJOR PLACEHOLDER/FAKE IMPLEMENTATIONS:
// - Spotify Service: 100% mock implementation, no real Spotify API integration
// - Live Session Features: Fake video calling and collaboration UI only
// - Chat System: Local UI only, no real messaging infrastructure
// - Social Features: Mock data only, no real user interactions
// - AI Features: Basic pattern matching, not true AI integration
// - Achievement System: Local storage only, no social gamification
// - Competition Features: Mock leaderboards, no real competitive systems
// - File Sharing: UI mockups only, no actual file handling
// - Notification System: Local notifications only, no push notifications
// - Real-time Features: No WebSocket or real-time synchronization
// 
// SECURITY AND COMPLIANCE GAPS:
// - Using Base64 instead of proper encryption
// - No data validation or sanitization
// - Missing user authentication for Google Sign-In
// - No privacy policy or terms of service integration
// - No GDPR compliance features
// - Missing user consent management
// - No data retention policies
// - Missing audit logging for security events
// 
// INFRASTRUCTURE AND SCALABILITY GAPS:
// - No load balancing or performance optimization
// - Missing error monitoring and crash reporting
// - No A/B testing framework
// - Missing automated testing and CI/CD
// - No database optimization or indexing strategy
// - Missing CDN integration for media files
// - No horizontal scaling preparation
// - Missing monitoring and alerting systems
// 
// CORE FEATURES NEEDING REAL IMPLEMENTATION:
// - Study effectiveness tracking and optimization
// - Personalized learning recommendations
// - Advanced spaced repetition algorithms
// - Real-time collaborative study features
// - Comprehensive social learning platform
// - Professional-grade video conferencing
// - Advanced AI tutoring and assistance
// - Cross-platform data synchronization
// - Offline-first architecture with smart sync
// - Advanced analytics and reporting dashboards

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
import 'providers/enhanced_ai_tutor_provider.dart';

// Import services
import 'services/social_learning_service.dart';
import 'services/enhanced_ai_tutor_service.dart';
import 'services/ai_service.dart';

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
        ChangeNotifierProxyProvider<StudyPalsAIProvider, EnhancedAITutorProvider>(
          create: (_) => EnhancedAITutorProvider(EnhancedAITutorService(AIService())),
          update: (_, aiProvider, tutorProvider) {
            // Always use the working AI provider
            if (tutorProvider == null) {
              final newProvider = EnhancedAITutorProvider(EnhancedAITutorService(aiProvider.aiService));
              newProvider.setAIProvider(aiProvider);
              return newProvider;
            }
            // Update existing provider with the working AI provider
            tutorProvider.setAIProvider(aiProvider);
            return tutorProvider;
          },
        ),
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
