// Analytics Service for StudyPals
// Calculates and manages user performance analytics and study insights
// Integrates with AI service for personalized learning experiences

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/study_analytics.dart';
import '../models/review.dart';
import '../models/quiz_session.dart';

class AnalyticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _analyticsCollection = 'study_analytics';
  static const String _sessionsCollection = 'study_sessions';

  /// Get user's study analytics from Firestore
  Future<StudyAnalytics?> getUserAnalytics(String userId) async {
    try {
      final doc =
          await _firestore.collection(_analyticsCollection).doc(userId).get();

      if (doc.exists) {
        return StudyAnalytics.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error fetching user analytics: $e');
      }
      return null;
    }
  }

  /// Calculate and update user analytics based on recent activity
  Future<StudyAnalytics> calculateAndUpdateAnalytics(String userId) async {
    try {
      // Fetch all user's study data
      final sessions = await _getUserStudySessions(userId);
      final quizSessions = await _getUserQuizSessions(userId);
      final reviews = await _getUserReviews(userId);

      // Calculate comprehensive analytics
      final analytics = AnalyticsCalculator.calculateUserAnalytics(
        userId: userId,
        sessions: sessions,
        quizSessions: quizSessions,
        reviews: reviews,
      );

      // Save to Firestore
      await _firestore
          .collection(_analyticsCollection)
          .doc(userId)
          .set(analytics.toJson());

      return analytics;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error calculating analytics: $e');
      }
      // Return basic analytics as fallback
      return StudyAnalytics(
        userId: userId,
        lastUpdated: DateTime.now(),
        overallAccuracy: 0.0,
        totalStudyTime: 0,
        totalCardsStudied: 0,
        totalQuizzesTaken: 0,
        currentStreak: 0,
        longestStreak: 0,
        totalAnswersGiven: 0,
        totalCorrectAnswers: 0,
        subjectPerformance: {},
        learningPatterns: LearningPatterns(
          preferredStudyHours: {},
          learningStyleEffectiveness: {},
          averageSessionLength: 0.0,
          preferredCardsPerSession: 0,
          topicInterest: {},
          commonMistakePatterns: [],
        ),
        recentTrend: PerformanceTrend(
          direction: 'stable',
          changeRate: 0.0,
          weeksAnalyzed: 0,
          weeklyData: [],
        ),
      );
    }
  }

  /// Start a new study session
  Future<StudySession> startStudySession({
    required String userId,
    String? deckId,
    String? subject,
  }) async {
    final session = StudySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      deckId: deckId,
      subject: subject,
      startTime: DateTime.now(),
      activities: [],
      metadata: {},
    );

    // Save to Firestore
    await _firestore
        .collection(_sessionsCollection)
        .doc(session.id)
        .set(session.toJson());

    return session;
  }

  /// Add activity to a study session
  Future<void> addSessionActivity(
    String sessionId,
    SessionActivity activity,
  ) async {
    try {
      // Add activity to session document
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'activities': FieldValue.arrayUnion([activity.toJson()]),
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error adding session activity: $e');
      }
    }
  }

  /// End a study session and trigger analytics update
  Future<void> endStudySession(String sessionId, String userId) async {
    try {
      // Mark session as ended
      await _firestore.collection(_sessionsCollection).doc(sessionId).update({
        'endTime': DateTime.now().toIso8601String(),
      });

      // Trigger analytics recalculation
      await calculateAndUpdateAnalytics(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error ending study session: $e');
      }
    }
  }

  /// Get user's study history for analytics
  Future<List<StudySession>> _getUserStudySessions(String userId) async {
    try {
      final query = await _firestore
          .collection(_sessionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(100) // Get recent 100 sessions
          .get();

      return query.docs
          .map((doc) => StudySession.fromJson(doc.data()))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error fetching study sessions: $e');
      }
      return [];
    }
  }

  /// Get user's quiz sessions for analytics
  Future<List<QuizSession>> _getUserQuizSessions(String userId) async {
    try {
      // TODO: Implement actual quiz session query
      // This would need to be implemented based on your quiz session storage
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error fetching quiz sessions: $e');
      }
      return [];
    }
  }

  /// Get user's reviews for analytics
  Future<List<Review>> _getUserReviews(String userId) async {
    try {
      // TODO: Implement actual review query
      // This would need to be implemented based on your review storage
      return [];
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error fetching reviews: $e');
      }
      return [];
    }
  }

  /// Get performance insights for a specific subject
  Future<Map<String, dynamic>> getSubjectInsights(
    String userId,
    String subject,
  ) async {
    final analytics = await getUserAnalytics(userId);
    if (analytics == null) return {};

    final subjectPerf = analytics.subjectPerformance[subject];
    if (subjectPerf == null) return {};

    return {
      'accuracy': subjectPerf.accuracy,
      'trend': subjectPerf.trendDescription,
      'recommendedDifficulty': analytics.getRecommendedDifficulty(subject),
      'totalCards': subjectPerf.totalCards,
      'studyTime': subjectPerf.studyTimeMinutes,
      'lastStudied': subjectPerf.lastStudied.toIso8601String(),
      'isImproving': subjectPerf.isImproving,
    };
  }

  /// Get overall user performance summary
  Future<Map<String, dynamic>> getUserPerformanceSummary(String userId) async {
    final analytics = await getUserAnalytics(userId);
    if (analytics == null) return {};

    return {
      'performanceLevel': analytics.performanceLevel,
      'overallAccuracy': analytics.overallAccuracy,
      'currentStreak': analytics.currentStreak,
      'totalStudyTime': analytics.totalStudyTime,
      'strugglingSubjects': analytics.strugglingSubjects,
      'strongSubjects': analytics.strongSubjects,
      'preferredStudyTime': analytics.learningPatterns.preferredStudyTime,
      'mostEffectiveLearningStyle':
          analytics.learningPatterns.mostEffectiveLearningStyle,
      'recentTrend': analytics.recentTrend.description,
    };
  }

  /// Update analytics when user completes a quiz
  Future<void> recordQuizCompletion({
    required String userId,
    required String subject,
    required double accuracy,
    required int timeSpentMinutes,
    required int cardsCount,
  }) async {
    try {
      // Create a synthetic study session for the quiz
      final session = StudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        subject: subject,
        startTime: DateTime.now().subtract(Duration(minutes: timeSpentMinutes)),
        endTime: DateTime.now(),
        activities: [
          // Add activities based on quiz results
          for (int i = 0; i < cardsCount; i++)
            SessionActivity(
              type: 'answer',
              timestamp: DateTime.now().subtract(Duration(
                  minutes: timeSpentMinutes -
                      (i * (timeSpentMinutes ~/ cardsCount)))),
              cardId: 'quiz_card_$i',
              wasCorrect: i < (cardsCount * accuracy).round(),
              responseTimeMs: (timeSpentMinutes * 60 * 1000) ~/ cardsCount,
              data: {'subject': subject},
            ),
        ],
        metadata: {'source': 'quiz_completion'},
      );

      // Save session
      await _firestore
          .collection(_sessionsCollection)
          .doc(session.id)
          .set(session.toJson());

      // Update analytics
      await calculateAndUpdateAnalytics(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error recording quiz completion: $e');
      }
    }
  }

  /// Update analytics when user completes a review session
  Future<void> recordReviewSession({
    required String userId,
    required String subject,
    required List<ReviewGrade> grades,
    required int timeSpentMinutes,
  }) async {
    try {
      final activities = <SessionActivity>[];

      for (int i = 0; i < grades.length; i++) {
        final grade = grades[i];
        final wasCorrect =
            grade == ReviewGrade.good || grade == ReviewGrade.easy;

        activities.add(SessionActivity(
          type: 'answer',
          timestamp: DateTime.now().subtract(Duration(
              minutes: timeSpentMinutes -
                  (i * (timeSpentMinutes ~/ grades.length)))),
          cardId: 'review_card_$i',
          wasCorrect: wasCorrect,
          responseTimeMs: (timeSpentMinutes * 60 * 1000) ~/ grades.length,
          data: {'subject': subject, 'grade': grade.toString()},
        ));
      }

      final session = StudySession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        subject: subject,
        startTime: DateTime.now().subtract(Duration(minutes: timeSpentMinutes)),
        endTime: DateTime.now(),
        activities: activities,
        metadata: {'source': 'review_session'},
      );

      // Save session
      await _firestore
          .collection(_sessionsCollection)
          .doc(session.id)
          .set(session.toJson());

      // Update analytics
      await calculateAndUpdateAnalytics(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsService: Error recording review session: $e');
      }
    }
  }
}
