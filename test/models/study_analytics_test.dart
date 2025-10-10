import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/models/study_analytics.dart';
import 'package:studypals/models/quiz_session.dart';

void main() {
  group('StudyAnalytics Calculation Tests', () {
    late List<StudySession> testSessions;
    late List<QuizSession> testQuizSessions;

    setUp(() {
      // Create test data
      final now = DateTime.now();

      // Create study sessions with various activities
      testSessions = [
        // Session 1: Math, 3 days ago
        StudySession(
          id: 'session1',
          userId: 'user123',
          deckId: 'deck1',
          subject: 'Mathematics',
          startTime: now.subtract(const Duration(days: 3)),
          endTime: now.subtract(const Duration(days: 3, hours: -1)),
          activities: [
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(days: 3)),
              cardId: 'card1',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(days: 3)),
              cardId: 'card1',
              wasCorrect: true,
              responseTimeMs: 5000,
              data: {},
            ),
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(days: 3)),
              cardId: 'card2',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(days: 3)),
              cardId: 'card2',
              wasCorrect: false,
              responseTimeMs: 8000,
              data: {},
            ),
          ],
          metadata: {
            'learningStyle': 'visual',
            'cardDifficulties': {'card1': 2, 'card2': 4},
          },
        ),
        // Session 2: Science, 2 days ago
        StudySession(
          id: 'session2',
          userId: 'user123',
          deckId: 'deck2',
          subject: 'Science',
          startTime: now.subtract(const Duration(days: 2)),
          endTime: now.subtract(const Duration(days: 2, hours: -2)),
          activities: [
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(days: 2)),
              cardId: 'card3',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(days: 2)),
              cardId: 'card3',
              wasCorrect: true,
              responseTimeMs: 4000,
              data: {},
            ),
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(days: 2)),
              cardId: 'card4',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(days: 2)),
              cardId: 'card4',
              wasCorrect: true,
              responseTimeMs: 6000,
              data: {},
            ),
          ],
          metadata: {
            'learningStyle': 'visual',
            'cardDifficulties': {'card3': 1, 'card4': 3},
          },
        ),
        // Session 3: Math, yesterday
        StudySession(
          id: 'session3',
          userId: 'user123',
          deckId: 'deck1',
          subject: 'Mathematics',
          startTime: now.subtract(const Duration(days: 1)),
          endTime: now.subtract(const Duration(days: 1, hours: -1, minutes: -30)),
          activities: [
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(days: 1)),
              cardId: 'card5',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(days: 1)),
              cardId: 'card5',
              wasCorrect: true,
              responseTimeMs: 3000,
              data: {},
            ),
          ],
          metadata: {
            'learningStyle': 'reading',
            'cardDifficulties': {'card5': 3},
          },
        ),
        // Session 4: Math, today
        StudySession(
          id: 'session4',
          userId: 'user123',
          deckId: 'deck1',
          subject: 'Mathematics',
          startTime: now.subtract(const Duration(hours: 2)),
          endTime: now.subtract(const Duration(hours: 1)),
          activities: [
            SessionActivity(
              type: 'card_view',
              timestamp: now.subtract(const Duration(hours: 2)),
              cardId: 'card6',
              data: {},
            ),
            SessionActivity(
              type: 'answer',
              timestamp: now.subtract(const Duration(hours: 2)),
              cardId: 'card6',
              wasCorrect: true,
              responseTimeMs: 7000,
              data: {},
            ),
          ],
          metadata: {
            'learningStyle': 'visual',
            'cardDifficulties': {'card6': 5},
          },
        ),
      ];

      // Create quiz sessions
      testQuizSessions = [
        QuizSession(
          id: 'quiz1',
          deckId: 'deck1',
          deckTitle: 'Math Deck',
          cardIds: ['card1', 'card2', 'card5'],
          startTime: now.subtract(const Duration(days: 3)),
          endTime: now.subtract(const Duration(days: 3, hours: -1)),
          isCompleted: true,
          finalScore: 0.67, // 2 out of 3 correct
          answers: [
            QuizAnswer(
              cardId: 'card1',
              selectedOptionIndex: 0,
              correctOptionIndex: 0,
              isCorrect: true,
              answeredAt: now.subtract(const Duration(days: 3)),
            ),
            QuizAnswer(
              cardId: 'card2',
              selectedOptionIndex: 1,
              correctOptionIndex: 0,
              isCorrect: false,
              answeredAt: now.subtract(const Duration(days: 3)),
            ),
            QuizAnswer(
              cardId: 'card5',
              selectedOptionIndex: 2,
              correctOptionIndex: 2,
              isCorrect: true,
              answeredAt: now.subtract(const Duration(days: 3)),
            ),
          ],
        ),
        QuizSession(
          id: 'quiz2',
          deckId: 'deck2',
          deckTitle: 'Science Deck',
          cardIds: ['card3', 'card4'],
          startTime: now.subtract(const Duration(days: 2)),
          endTime: now.subtract(const Duration(days: 2, hours: -1)),
          isCompleted: true,
          finalScore: 1.0, // Perfect score
          answers: [
            QuizAnswer(
              cardId: 'card3',
              selectedOptionIndex: 0,
              correctOptionIndex: 0,
              isCorrect: true,
              answeredAt: now.subtract(const Duration(days: 2)),
            ),
            QuizAnswer(
              cardId: 'card4',
              selectedOptionIndex: 1,
              correctOptionIndex: 1,
              isCorrect: true,
              answeredAt: now.subtract(const Duration(days: 2)),
            ),
          ],
        ),
      ];
    });

    test('Calculate overall metrics correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Test overall accuracy: 5 correct out of 6 total = 0.833...
      expect(analytics.overallAccuracy, greaterThan(0.8));
      expect(analytics.overallAccuracy, lessThan(0.9));

      // Test total study time: 1 + 2 + 1.5 + 1 = 5.5 hours = 330 minutes
      expect(analytics.totalStudyTime, equals(330));

      // Test total cards studied: 6 card_view activities total (not 4)
      expect(analytics.totalCardsStudied, equals(6));

      // Test total quizzes taken
      expect(analytics.totalQuizzesTaken, equals(2));
    });

    test('Calculate subject performance correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Check Mathematics performance
      expect(analytics.subjectPerformance.containsKey('Mathematics'), isTrue);
      final mathPerf = analytics.subjectPerformance['Mathematics']!;
      
      expect(mathPerf.totalCards, equals(4)); // 4 math cards viewed (card1, card2, card5, card6)
      expect(mathPerf.accuracy, greaterThan(0.6)); // 3 out of 4 correct = 0.75
      expect(mathPerf.studyTimeMinutes, equals(210)); // 1 + 1.5 + 1 hours
      expect(mathPerf.totalQuizzes, equals(1)); // 1 math quiz
      expect(mathPerf.recentScores.length, equals(1)); // 1 recent quiz score
      expect(mathPerf.recentScores.first, equals(0.67));

      // Check Science performance
      expect(analytics.subjectPerformance.containsKey('Science'), isTrue);
      final sciencePerf = analytics.subjectPerformance['Science']!;
      
      expect(sciencePerf.totalCards, equals(2)); // 2 science cards viewed
      expect(sciencePerf.accuracy, equals(1.0)); // Perfect accuracy
      expect(sciencePerf.studyTimeMinutes, equals(120)); // 2 hours
      expect(sciencePerf.totalQuizzes, equals(1)); // 1 science quiz
    });

    test('Calculate difficulty breakdown correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final mathPerf = analytics.subjectPerformance['Mathematics']!;
      
      // Math has cards with difficulty: 2 (easy), 4 (hard), 3 (moderate), 5 (hard)
      expect(mathPerf.difficultyBreakdown.containsKey('easy'), isTrue);
      expect(mathPerf.difficultyBreakdown.containsKey('moderate'), isTrue);
      expect(mathPerf.difficultyBreakdown.containsKey('hard'), isTrue);
    });

    test('Calculate average response time correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final mathPerf = analytics.subjectPerformance['Mathematics']!;
      
      // Math response times: 5000, 8000, 3000, 7000 ms = average 5750 ms = 5.75 seconds
      expect(mathPerf.averageResponseTime, greaterThan(5.0));
      expect(mathPerf.averageResponseTime, lessThan(6.5));
    });

    test('Calculate learning patterns correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final patterns = analytics.learningPatterns;

      // Test preferred study hours
      expect(patterns.preferredStudyHours.isNotEmpty, isTrue);

      // Test learning style effectiveness
      expect(patterns.learningStyleEffectiveness.containsKey('visual'), isTrue);
      expect(patterns.learningStyleEffectiveness.containsKey('reading'), isTrue);

      // Visual style: 4 correct out of 5 attempts = 0.8
      expect(patterns.learningStyleEffectiveness['visual'], greaterThan(0.7));

      // Test average session length
      expect(patterns.averageSessionLength, greaterThan(60.0)); // Over 1 hour average

      // Test preferred cards per session (6 cards / 4 sessions = 1.5, rounds to 2)
      expect(patterns.preferredCardsPerSession, isIn([1, 2]));
    });

    test('Calculate topic interest correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final patterns = analytics.learningPatterns;

      // Check topic interest calculation
      expect(patterns.topicInterest.containsKey('Mathematics'), isTrue);
      expect(patterns.topicInterest.containsKey('Science'), isTrue);

      // Mathematics should have higher interest (3 sessions vs 1)
      expect(
        patterns.topicInterest['Mathematics']! > patterns.topicInterest['Science']!,
        isTrue,
      );
    });

    test('Analyze common mistake patterns correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final patterns = analytics.learningPatterns;

      // Should identify mistake patterns
      // Only 1 incorrect answer in our test data, so might not trigger all patterns
      expect(patterns.commonMistakePatterns, isNotNull);
    });

    test('Calculate performance trend correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final trend = analytics.recentTrend;

      // Test trend properties
      expect(trend.weeksAnalyzed, equals(4));
      expect(trend.weeklyData.length, equals(4));
      expect(trend.direction, isIn(['improving', 'declining', 'stable']));
      expect(trend.changeRate, isA<double>());
    });

    test('Calculate weekly stats correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final trend = analytics.recentTrend;
      final currentWeek = trend.weeklyData.last;

      // Current week should have data from our sessions
      expect(currentWeek.cardsStudied, greaterThan(0));
      expect(currentWeek.averageAccuracy, greaterThan(0.0));
    });

    test('Calculate current streak correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Should have a streak since we studied today, yesterday, 2 days ago, and 3 days ago
      expect(analytics.currentStreak, equals(4));
    });

    test('Calculate longest streak correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Longest streak should be at least the current streak
      expect(analytics.longestStreak, greaterThanOrEqualTo(analytics.currentStreak));
      expect(analytics.longestStreak, equals(4));
    });

    test('Incremental update works correctly', () {
      final initialAnalytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions.take(3).toList(),
        quizSessions: testQuizSessions,
        reviews: [],
      );

      final newSession = testSessions.last;
      final updatedAnalytics = AnalyticsCalculator.updateAnalyticsWithSession(
        initialAnalytics,
        newSession,
      );

      // Check that totals increased
      expect(
        updatedAnalytics.totalCardsStudied,
        greaterThan(initialAnalytics.totalCardsStudied),
      );
      expect(
        updatedAnalytics.totalStudyTime,
        greaterThan(initialAnalytics.totalStudyTime),
      );

      // Check that subject performance was updated
      expect(
        updatedAnalytics.subjectPerformance['Mathematics']!.totalCards,
        greaterThan(initialAnalytics.subjectPerformance['Mathematics']!.totalCards),
      );
    });

    test('Performance level classification works correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // With 5/6 correct answers, should be Intermediate or Advanced
      expect(analytics.performanceLevel, isIn(['Intermediate', 'Advanced']));
    });

    test('Struggling and strong subjects identified correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Science has 100% accuracy, should be strong
      expect(analytics.strongSubjects.contains('Science'), isTrue);

      // No subjects should be struggling (all above 70%)
      expect(analytics.strugglingSubjects.isEmpty, isTrue);
    });

    test('Recommended difficulty calculated correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Science with 100% accuracy should recommend challenging
      expect(
        analytics.getRecommendedDifficulty('Science'),
        equals('challenging'),
      );

      // Math with ~75% accuracy should recommend moderate
      expect(
        analytics.getRecommendedDifficulty('Mathematics'),
        isIn(['easy', 'moderate']),
      );
    });

    test('Empty sessions return valid analytics', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: [],
        quizSessions: [],
        reviews: [],
      );

      expect(analytics.overallAccuracy, equals(0.0));
      expect(analytics.totalStudyTime, equals(0));
      expect(analytics.totalCardsStudied, equals(0));
      expect(analytics.totalQuizzesTaken, equals(0));
      expect(analytics.currentStreak, equals(0));
      expect(analytics.longestStreak, equals(0));
      expect(analytics.subjectPerformance.isEmpty, isTrue);
    });

    test('JSON serialization and deserialization works correctly', () {
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: 'user123',
        sessions: testSessions,
        quizSessions: testQuizSessions,
        reviews: [],
      );

      // Convert to JSON and back
      final json = analytics.toJson();
      final deserialized = StudyAnalytics.fromJson(json);

      // Check that key fields match
      expect(deserialized.userId, equals(analytics.userId));
      expect(deserialized.overallAccuracy, equals(analytics.overallAccuracy));
      expect(deserialized.totalStudyTime, equals(analytics.totalStudyTime));
      expect(deserialized.currentStreak, equals(analytics.currentStreak));
      expect(deserialized.longestStreak, equals(analytics.longestStreak));
      expect(
        deserialized.subjectPerformance.keys.toSet(),
        equals(analytics.subjectPerformance.keys.toSet()),
      );
    });
  });
}
