// Analytics Provider for StudyPals
// Manages user performance analytics and provides data to the UI
// Integrates with AI service for personalized learning recommendations

import 'package:flutter/foundation.dart';
import '../models/study_analytics.dart';
import '../models/review.dart';
import '../services/analytics_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsService _analyticsService = AnalyticsService();

  StudyAnalytics? _currentAnalytics;
  bool _isLoading = false;
  String? _error;
  StudySession? _activeSession;

  // Getters
  StudyAnalytics? get currentAnalytics => _currentAnalytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  StudySession? get activeSession => _activeSession;

  bool get hasAnalytics => _currentAnalytics != null;
  String get performanceLevel =>
      _currentAnalytics?.performanceLevel ?? 'Beginner';
  double get overallAccuracy => _currentAnalytics?.overallAccuracy ?? 0.0;
  int get currentStreak => _currentAnalytics?.currentStreak ?? 0;

  /// Load user analytics from the service
  Future<void> loadUserAnalytics(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      _currentAnalytics = await _analyticsService.getUserAnalytics(userId);

      // If no analytics exist, calculate them
      _currentAnalytics ??=
          await _analyticsService.calculateAndUpdateAnalytics(userId);
    } catch (e) {
      _error = 'Failed to load analytics: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh analytics by recalculating from recent data
  Future<void> refreshAnalytics(String userId) async {
    _setLoading(true);
    _error = null;

    try {
      _currentAnalytics =
          await _analyticsService.calculateAndUpdateAnalytics(userId);
    } catch (e) {
      _error = 'Failed to refresh analytics: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
    } finally {
      _setLoading(false);
    }
  }

  /// Start a new study session
  Future<void> startStudySession({
    required String userId,
    String? deckId,
    String? subject,
  }) async {
    try {
      _activeSession = await _analyticsService.startStudySession(
        userId: userId,
        deckId: deckId,
        subject: subject,
      );
      notifyListeners();
    } catch (e) {
      _error = 'Failed to start study session: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
      notifyListeners();
    }
  }

  /// Add activity to the current study session
  Future<void> addSessionActivity(SessionActivity activity) async {
    if (_activeSession == null) return;

    try {
      await _analyticsService.addSessionActivity(_activeSession!.id, activity);
      // Update local session
      _activeSession!.addActivity(activity);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to record activity: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
    }
  }

  /// End the current study session
  Future<void> endStudySession(String userId) async {
    if (_activeSession == null) return;

    try {
      await _analyticsService.endStudySession(_activeSession!.id, userId);
      _activeSession!.endSession();

      // Refresh analytics after session ends
      await refreshAnalytics(userId);

      _activeSession = null;
    } catch (e) {
      _error = 'Failed to end study session: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
    }

    notifyListeners();
  }

  /// Record a card being viewed
  void recordCardView(String cardId, String? subject) {
    if (_activeSession == null) return;

    final activity = SessionActivity(
      type: 'card_view',
      timestamp: DateTime.now(),
      cardId: cardId,
      data: {'subject': subject ?? 'unknown'},
    );

    addSessionActivity(activity);
  }

  /// Record an answer being given
  void recordAnswer(
      String cardId, bool wasCorrect, int responseTimeMs, String? subject) {
    if (_activeSession == null) return;

    final activity = SessionActivity(
      type: 'answer',
      timestamp: DateTime.now(),
      cardId: cardId,
      wasCorrect: wasCorrect,
      responseTimeMs: responseTimeMs,
      data: {'subject': subject ?? 'unknown'},
    );

    addSessionActivity(activity);
  }

  /// Record a hint being used
  void recordHintUsed(String cardId, String? subject) {
    if (_activeSession == null) return;

    final activity = SessionActivity(
      type: 'hint_used',
      timestamp: DateTime.now(),
      cardId: cardId,
      data: {'subject': subject ?? 'unknown'},
    );

    addSessionActivity(activity);
  }

  /// Record a card being skipped
  void recordCardSkip(String cardId, String? subject) {
    if (_activeSession == null) return;

    final activity = SessionActivity(
      type: 'skip',
      timestamp: DateTime.now(),
      cardId: cardId,
      data: {'subject': subject ?? 'unknown'},
    );

    addSessionActivity(activity);
  }

  /// Get performance insights for a specific subject
  Future<Map<String, dynamic>> getSubjectInsights(
      String userId, String subject) async {
    try {
      return await _analyticsService.getSubjectInsights(userId, subject);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsProvider: Failed to get subject insights: $e');
      }
      return {};
    }
  }

  /// Get overall performance summary
  Future<Map<String, dynamic>> getPerformanceSummary(String userId) async {
    try {
      return await _analyticsService.getUserPerformanceSummary(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AnalyticsProvider: Failed to get performance summary: $e');
      }
      return {};
    }
  }

  /// Record completion of a quiz
  Future<void> recordQuizCompletion({
    required String userId,
    required String subject,
    required double accuracy,
    required int timeSpentMinutes,
    required int cardsCount,
  }) async {
    try {
      await _analyticsService.recordQuizCompletion(
        userId: userId,
        subject: subject,
        accuracy: accuracy,
        timeSpentMinutes: timeSpentMinutes,
        cardsCount: cardsCount,
      );

      // Refresh analytics after quiz completion
      await refreshAnalytics(userId);
    } catch (e) {
      _error = 'Failed to record quiz completion: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
      notifyListeners();
    }
  }

  /// Record completion of a review session
  Future<void> recordReviewSession({
    required String userId,
    required String subject,
    required List<ReviewGrade> grades,
    required int timeSpentMinutes,
  }) async {
    try {
      await _analyticsService.recordReviewSession(
        userId: userId,
        subject: subject,
        grades: grades,
        timeSpentMinutes: timeSpentMinutes,
      );

      // Refresh analytics after review session
      await refreshAnalytics(userId);
    } catch (e) {
      _error = 'Failed to record review session: $e';
      if (kDebugMode) debugPrint('AnalyticsProvider: $_error');
      notifyListeners();
    }
  }

  /// Get recommended difficulty for a subject
  String getRecommendedDifficulty(String subject) {
    return _currentAnalytics?.getRecommendedDifficulty(subject) ?? 'moderate';
  }

  /// Check if user is struggling with a subject
  bool isStruggling(String subject) {
    return _currentAnalytics?.strugglingSubjects.contains(subject) ?? false;
  }

  /// Check if user excels at a subject
  bool excelsAt(String subject) {
    return _currentAnalytics?.strongSubjects.contains(subject) ?? false;
  }

  /// Get learning patterns for AI personalization
  LearningPatterns? get learningPatterns => _currentAnalytics?.learningPatterns;

  /// Get performance level description
  String get performanceLevelDescription {
    switch (performanceLevel) {
      case 'Expert':
        return 'You\'re mastering your studies! 🌟';
      case 'Advanced':
        return 'Great progress! Keep it up! 📈';
      case 'Intermediate':
        return 'You\'re improving steadily 👍';
      case 'Developing':
        return 'Keep practicing - you\'re getting there! 💪';
      case 'Beginner':
      default:
        return 'Every expert was once a beginner 🌱';
    }
  }

  /// Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Clear all analytics data (for logout)
  void clear() {
    _currentAnalytics = null;
    _activeSession = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
