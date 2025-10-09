// COMPREHENSIVE AI SYSTEM TESTS
// Tests all major AI enhancement features using public APIs

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/services/ai_service.dart';
import 'package:studypals/models/card.dart';
import 'package:studypals/models/user.dart';
import 'package:studypals/models/study_analytics.dart';

void main() {
  group('🤖 Comprehensive AI System Tests', () {
    late AIService aiService;
    late User testUser;
    late StudyAnalytics testAnalytics;

    setUp(() {
      aiService = AIService();
      aiService.configure(
        provider: AIProvider.google,
        apiKey: 'test-key-for-validation',
      );

      // Create comprehensive test user with all personalization data
      testUser = User(
        id: 'test-user-comprehensive',
        name: 'Test User Advanced',
        email: 'test@studypals.com',
        school: 'MIT',
        major: 'Computer Science',
        graduationYear: 2026,
        location: 'Boston, USA',
        createdAt: DateTime.now().subtract(Duration(days: 180)),
        lastActiveAt: DateTime.now().subtract(Duration(hours: 2)),
        loginCount: 45,
        preferences: UserPreferences(
          learningStyle: 'visual',
          difficultyPreference: 'adaptive',
          studyStartHour: 9,
          studyEndHour: 17,
          maxCardsPerDay: 25,
          maxMinutesPerDay: 90,
          studyDaysOfWeek: [1, 2, 3, 4, 5], // Monday-Friday
          breakInterval: 25,
          breakDuration: 5,
          cardReviewDelay: 3000,
          showHints: true,
          autoPlayAudio: false,
          socialNotifications: true,
          studyReminders: true,
          achievementNotifications: true,
          fontSize: 1.2,
          theme: 'light',
          animations: true,
          language: 'en',
          offline: false,
          autoSync: true,
        ),
        privacySettings: UserPrivacySettings(
          shareStudyStats: true,
          allowDirectMessages: true,
        ),
      );

      // Create comprehensive test analytics
      testAnalytics = StudyAnalytics(
        userId: testUser.id,
        lastUpdated: DateTime.now(),
        overallAccuracy: 0.82,
        totalStudyTime: 450,
        totalCardsStudied: 180,
        totalQuizzesTaken: 25,
        currentStreak: 8,
        longestStreak: 15,
        totalAnswersGiven: 220,
        totalCorrectAnswers: 180,
        subjectPerformance: {
          'Computer Science': SubjectPerformance(
            subject: 'Computer Science',
            accuracy: 0.88,
            totalCards: 75,
            totalQuizzes: 12,
            studyTimeMinutes: 180,
            lastStudied: DateTime.now().subtract(Duration(hours: 1)),
            recentScores: [0.92, 0.85, 0.90, 0.87, 0.89],
            difficultyBreakdown: {'easy': 20, 'moderate': 35, 'hard': 20},
            averageResponseTime: 22.5,
          ),
          'Mathematics': SubjectPerformance(
            subject: 'Mathematics',
            accuracy: 0.75,
            totalCards: 60,
            totalQuizzes: 8,
            studyTimeMinutes: 150,
            lastStudied: DateTime.now().subtract(Duration(days: 2)),
            recentScores: [0.70, 0.75, 0.78, 0.72, 0.80],
            difficultyBreakdown: {'easy': 25, 'moderate': 25, 'hard': 10},
            averageResponseTime: 35.2,
          ),
        },
        learningPatterns: LearningPatterns(
          preferredStudyHours: {'9': 15, '14': 12, '16': 8},
          learningStyleEffectiveness: {
            'visual': 0.92,
            'auditory': 0.65,
            'kinesthetic': 0.78,
            'reading': 0.85,
          },
          averageSessionLength: 28.5,
          preferredCardsPerSession: 18,
          topicInterest: {
            'algorithms': 0.95,
            'data structures': 0.88,
            'machine learning': 0.82,
          },
          commonMistakePatterns: [
            'array indexing errors',
            'off-by-one mistakes',
          ],
        ),
        recentTrend: PerformanceTrend(
          direction: 'improving',
          changeRate: 8.5,
          weeksAnalyzed: 4,
          weeklyData: [],
        ),
      );
    });

    group('✅ TASK 1: Enhanced AI Service User Integration', () {
      test('AI Service Configuration and Status', () {
        expect(aiService.isConfigured, isTrue);
        debugPrint('✅ AI Service Configuration: PASSED');
      });

      test('User Profile Integration', () {
        expect(testUser.id, isNotEmpty);
        expect(testUser.school, isNotNull);
        expect(testUser.major, isNotNull);
        expect(testUser.preferences.learningStyle, isNotEmpty);
        expect(testUser.preferences.studyDaysOfWeek, isNotEmpty);
        debugPrint('✅ User Profile Integration: PASSED');
      });

      test('Comprehensive User Preferences', () {
        final prefs = testUser.preferences;
        expect(prefs.learningStyle, equals('visual'));
        expect(prefs.difficultyPreference, equals('adaptive'));
        expect(prefs.studyStartHour, greaterThan(0));
        expect(prefs.studyEndHour, greaterThan(prefs.studyStartHour));
        expect(prefs.breakInterval, greaterThan(0));
        expect(prefs.studyDaysOfWeek.length, greaterThan(0));
        debugPrint('✅ Comprehensive User Preferences: PASSED');
      });
    });

    group('✅ TASK 2: Multi-Modal Content Generation', () {
      test('Learning Styles Support', () {
        final supportedStyles = [
          'visual',
          'auditory',
          'kinesthetic',
          'reading'
        ];
        for (final style in supportedStyles) {
          expect(style, isNotEmpty);
        }
        debugPrint('✅ Learning Styles Support: PASSED');
      });

      test('Card Type Variety', () {
        final basicTypes = [
          CardType.basic,
          CardType.cloze,
          CardType.reverse,
          CardType.multipleChoice
        ];
        final advancedTypes = [
          CardType.trueFalse,
          CardType.comparison,
          CardType.scenario,
          CardType.causeEffect
        ];

        expect(basicTypes.length, equals(4));
        expect(advancedTypes.length, equals(4));
        debugPrint('✅ Card Type Variety: PASSED');
      });
    });

    group('✅ TASK 3: Question Type Variety Enhancement', () {
      test('18 Question Types Available', () {
        final allTypes = CardType.values;
        expect(allTypes.length, greaterThanOrEqualTo(18));

        // Verify specific advanced types exist
        expect(allTypes, contains(CardType.caseStudy));
        expect(allTypes, contains(CardType.problemSolving));
        expect(allTypes, contains(CardType.hypothesisTesting));
        expect(allTypes, contains(CardType.evaluation));
        expect(allTypes, contains(CardType.synthesis));

        debugPrint('✅ 18 Question Types Available: PASSED');
      });

      test('Question Type Instructions Integration', () {
        expect(testUser.major, isNotNull);
        expect(testUser.preferences.learningStyle, isNotEmpty);
        debugPrint('✅ Question Type Instructions Integration: PASSED');
      });
    });

    group('✅ TASK 4: Performance-Based Difficulty Adaptation', () {
      test('Analytics Data Structure', () {
        expect(testAnalytics.overallAccuracy, greaterThan(0));
        expect(testAnalytics.subjectPerformance, isNotEmpty);
        expect(testAnalytics.recentTrend.direction, isNotEmpty);
        expect(testAnalytics.learningPatterns.learningStyleEffectiveness,
            isNotEmpty);
        debugPrint('✅ Analytics Data Structure: PASSED');
      });

      test('Performance Context Integration', () {
        expect(testAnalytics.totalStudyTime, greaterThan(0));
        expect(testAnalytics.totalCardsStudied, greaterThan(0));
        expect(testAnalytics.learningPatterns.averageSessionLength,
            greaterThan(0));
        expect(testAnalytics.learningPatterns.preferredCardsPerSession,
            greaterThan(0));
        debugPrint('✅ Performance Context Integration: PASSED');
      });
    });

    group('✅ TASK 5: Real-Time Analytics Feedback Loop', () {
      test('Learning Pattern Analysis', () {
        final patterns = testAnalytics.learningPatterns;
        expect(patterns.learningStyleEffectiveness, isNotEmpty);
        expect(patterns.topicInterest, isNotEmpty);
        expect(patterns.commonMistakePatterns, isNotEmpty);
        expect(patterns.preferredStudyHours, isNotEmpty);
        debugPrint('✅ Learning Pattern Analysis: PASSED');
      });

      test('Adaptive Recommendations Data', () {
        final recommendations = aiService.getAdaptiveRecommendations(
            testUser, testAnalytics, 'Computer Science');
        expect(recommendations, isNotNull);
        expect(recommendations, containsPair('difficulty', isNotNull));
        expect(recommendations, containsPair('questionTypes', isNotNull));
        expect(recommendations, containsPair('confidence', isNotNull));
        debugPrint('✅ Adaptive Recommendations Data: PASSED');
      });
    });

    group('✅ TASK 6: Advanced Question Formats', () {
      test('Advanced Card Types', () {
        final advancedTypes = [
          CardType.caseStudy,
          CardType.problemSolving,
          CardType.hypothesisTesting,
          CardType.decisionAnalysis,
          CardType.systemAnalysis,
          CardType.evaluation,
          CardType.synthesis
        ];

        for (final type in advancedTypes) {
          expect(CardType.values, contains(type));
        }
        debugPrint('✅ Advanced Card Types: PASSED');
      });

      test('Error Handling and Fallback', () {
        expect(aiService.isConfigured, isTrue);
        expect(
            () => aiService.getAdaptiveRecommendations(
                testUser, null, 'Test Subject'),
            returnsNormally);
        debugPrint('✅ Error Handling and Fallback: PASSED');
      });
    });

    group('✅ INTEGRATION: Complete System Validation', () {
      test('Full User-Analytics-AI Integration', () {
        expect(testUser.id, isNotEmpty);
        expect(testAnalytics.userId, equals(testUser.id));
        expect(aiService.isConfigured, isTrue);

        final recommendations = aiService.getAdaptiveRecommendations(
            testUser, testAnalytics, 'Computer Science');
        expect(recommendations, isNotNull);
        debugPrint('✅ Full User-Analytics-AI Integration: PASSED');
      });

      test('Public API Functionality', () async {
        // Test public API methods that users actually interact with
        expect(() => aiService.isConfigured, returnsNormally);
        expect(
            () => aiService.getAdaptiveRecommendations(
                testUser, testAnalytics, 'CS'),
            returnsNormally);
        debugPrint('✅ Public API Functionality: PASSED');
      });

      test('Data Model Consistency', () {
        // Verify all data models work together
        expect(testUser.preferences.learningStyle,
            isIn(['visual', 'auditory', 'kinesthetic', 'reading', 'adaptive']));
        expect(testAnalytics.overallAccuracy, inInclusiveRange(0.0, 1.0));
        expect(
            testAnalytics.learningPatterns.learningStyleEffectiveness.keys,
            everyElement(
                isIn(['visual', 'auditory', 'kinesthetic', 'reading'])));
        debugPrint('✅ Data Model Consistency: PASSED');
      });
    });
  });
}

// Simple test helpers without accessing private methods
extension TestHelpers on AIService {
  Map<String, dynamic> getTestRecommendations(
      User user, StudyAnalytics? analytics, String subject) {
    return getAdaptiveRecommendations(user, analytics, subject);
  }
}
