// Study Analytics and Performance Tracking Models
// Provides comprehensive user performance data for AI personalization
// Tracks learning patterns, subject performance, and adaptive difficulty metrics

/// Comprehensive study analytics for a user
/// Aggregates performance data across all subjects and study activities
class StudyAnalytics {
  final String userId;
  final DateTime lastUpdated;

  // Overall Performance Metrics
  final double overallAccuracy; // 0.0 to 1.0
  final int totalStudyTime; // in minutes
  final int totalCardsStudied;
  final int totalQuizzesTaken;
  final int currentStreak; // days
  final int longestStreak; // days

  // Subject-specific performance
  final Map<String, SubjectPerformance> subjectPerformance;

  // Learning pattern insights
  final LearningPatterns learningPatterns;

  // Recent performance trend
  final PerformanceTrend recentTrend;

  StudyAnalytics({
    required this.userId,
    required this.lastUpdated,
    required this.overallAccuracy,
    required this.totalStudyTime,
    required this.totalCardsStudied,
    required this.totalQuizzesTaken,
    required this.currentStreak,
    required this.longestStreak,
    required this.subjectPerformance,
    required this.learningPatterns,
    required this.recentTrend,
  });

  /// Get performance level as string for AI context
  String get performanceLevel {
    if (overallAccuracy >= 0.9) return 'Expert';
    if (overallAccuracy >= 0.8) return 'Advanced';
    if (overallAccuracy >= 0.7) return 'Intermediate';
    if (overallAccuracy >= 0.6) return 'Developing';
    return 'Beginner';
  }

  /// Get subjects where user struggles (accuracy < 70%)
  List<String> get strugglingSubjects {
    return subjectPerformance.entries
        .where((entry) => entry.value.accuracy < 0.7)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get subjects where user excels (accuracy >= 85%)
  List<String> get strongSubjects {
    return subjectPerformance.entries
        .where((entry) => entry.value.accuracy >= 0.85)
        .map((entry) => entry.key)
        .toList();
  }

  /// Get recommended difficulty for a subject
  String getRecommendedDifficulty(String subject) {
    final performance = subjectPerformance[subject];
    if (performance == null) return 'moderate';

    if (performance.accuracy >= 0.9) return 'challenging';
    if (performance.accuracy >= 0.8) return 'moderate';
    if (performance.accuracy >= 0.7) return 'easy';
    return 'easy';
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'lastUpdated': lastUpdated.toIso8601String(),
        'overallAccuracy': overallAccuracy,
        'totalStudyTime': totalStudyTime,
        'totalCardsStudied': totalCardsStudied,
        'totalQuizzesTaken': totalQuizzesTaken,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'subjectPerformance': subjectPerformance
            .map((key, value) => MapEntry(key, value.toJson())),
        'learningPatterns': learningPatterns.toJson(),
        'recentTrend': recentTrend.toJson(),
      };

  factory StudyAnalytics.fromJson(Map<String, dynamic> json) => StudyAnalytics(
        userId: json['userId'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
        overallAccuracy: json['overallAccuracy'].toDouble(),
        totalStudyTime: json['totalStudyTime'],
        totalCardsStudied: json['totalCardsStudied'],
        totalQuizzesTaken: json['totalQuizzesTaken'],
        currentStreak: json['currentStreak'],
        longestStreak: json['longestStreak'],
        subjectPerformance: (json['subjectPerformance'] as Map<String, dynamic>)
            .map((key, value) =>
                MapEntry(key, SubjectPerformance.fromJson(value))),
        learningPatterns: LearningPatterns.fromJson(json['learningPatterns']),
        recentTrend: PerformanceTrend.fromJson(json['recentTrend']),
      );
}

/// Performance data for a specific subject/topic
class SubjectPerformance {
  final String subject;
  final double accuracy; // 0.0 to 1.0
  final int totalCards;
  final int totalQuizzes;
  final int studyTimeMinutes;
  final DateTime lastStudied;
  final List<double> recentScores; // Last 10 quiz scores
  final Map<String, int> difficultyBreakdown; // easy/moderate/hard counts
  final double averageResponseTime; // in seconds

  SubjectPerformance({
    required this.subject,
    required this.accuracy,
    required this.totalCards,
    required this.totalQuizzes,
    required this.studyTimeMinutes,
    required this.lastStudied,
    required this.recentScores,
    required this.difficultyBreakdown,
    required this.averageResponseTime,
  });

  /// Check if performance is improving based on recent scores
  bool get isImproving {
    if (recentScores.length < 3) return false;
    final recent = recentScores.take(3).toList();
    final older = recentScores.skip(3).take(3).toList();
    if (older.isEmpty) return false;

    final recentAvg = recent.reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.reduce((a, b) => a + b) / older.length;
    return recentAvg > olderAvg;
  }

  /// Get performance trend description
  String get trendDescription {
    if (isImproving) return 'Improving';
    if (recentScores.isNotEmpty && recentScores.first >= 0.8) {
      return 'Consistent';
    }
    return 'Needs Focus';
  }

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'accuracy': accuracy,
        'totalCards': totalCards,
        'totalQuizzes': totalQuizzes,
        'studyTimeMinutes': studyTimeMinutes,
        'lastStudied': lastStudied.toIso8601String(),
        'recentScores': recentScores,
        'difficultyBreakdown': difficultyBreakdown,
        'averageResponseTime': averageResponseTime,
      };

  factory SubjectPerformance.fromJson(Map<String, dynamic> json) =>
      SubjectPerformance(
        subject: json['subject'],
        accuracy: json['accuracy'].toDouble(),
        totalCards: json['totalCards'],
        totalQuizzes: json['totalQuizzes'],
        studyTimeMinutes: json['studyTimeMinutes'],
        lastStudied: DateTime.parse(json['lastStudied']),
        recentScores: List<double>.from(json['recentScores']),
        difficultyBreakdown: Map<String, int>.from(json['difficultyBreakdown']),
        averageResponseTime: json['averageResponseTime'].toDouble(),
      );
}

/// Analysis of user's learning patterns and preferences
class LearningPatterns {
  final Map<String, int> preferredStudyHours; // hour -> frequency
  final Map<String, double> learningStyleEffectiveness; // style -> accuracy
  final double averageSessionLength; // in minutes
  final int preferredCardsPerSession;
  final Map<String, double> topicInterest; // topic -> engagement score
  final List<String> commonMistakePatterns;

  LearningPatterns({
    required this.preferredStudyHours,
    required this.learningStyleEffectiveness,
    required this.averageSessionLength,
    required this.preferredCardsPerSession,
    required this.topicInterest,
    required this.commonMistakePatterns,
  });

  /// Get most effective learning style
  String get mostEffectiveLearningStyle {
    return learningStyleEffectiveness.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Get preferred study time
  String get preferredStudyTime {
    if (preferredStudyHours.isEmpty) return 'flexible';
    final mostFrequent =
        preferredStudyHours.entries.reduce((a, b) => a.value > b.value ? a : b);

    final hour = int.parse(mostFrequent.key);
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  Map<String, dynamic> toJson() => {
        'preferredStudyHours': preferredStudyHours,
        'learningStyleEffectiveness': learningStyleEffectiveness,
        'averageSessionLength': averageSessionLength,
        'preferredCardsPerSession': preferredCardsPerSession,
        'topicInterest': topicInterest,
        'commonMistakePatterns': commonMistakePatterns,
      };

  factory LearningPatterns.fromJson(Map<String, dynamic> json) =>
      LearningPatterns(
        preferredStudyHours: Map<String, int>.from(json['preferredStudyHours']),
        learningStyleEffectiveness:
            Map<String, double>.from(json['learningStyleEffectiveness']),
        averageSessionLength: json['averageSessionLength'].toDouble(),
        preferredCardsPerSession: json['preferredCardsPerSession'],
        topicInterest: Map<String, double>.from(json['topicInterest']),
        commonMistakePatterns: List<String>.from(json['commonMistakePatterns']),
      );
}

/// Recent performance trend analysis
class PerformanceTrend {
  final String direction; // 'improving', 'declining', 'stable'
  final double changeRate; // percentage change per week
  final int weeksAnalyzed;
  final List<WeeklyStats> weeklyData;

  PerformanceTrend({
    required this.direction,
    required this.changeRate,
    required this.weeksAnalyzed,
    required this.weeklyData,
  });

  /// Get trend description for AI context
  String get description {
    switch (direction) {
      case 'improving':
        return 'User shows consistent improvement with ${changeRate.toStringAsFixed(1)}% weekly growth';
      case 'declining':
        return 'User performance declining by ${changeRate.abs().toStringAsFixed(1)}% weekly - needs support';
      case 'stable':
        return 'User performance is stable with consistent results';
      default:
        return 'Performance trend unclear - need more data';
    }
  }

  Map<String, dynamic> toJson() => {
        'direction': direction,
        'changeRate': changeRate,
        'weeksAnalyzed': weeksAnalyzed,
        'weeklyData': weeklyData.map((w) => w.toJson()).toList(),
      };

  factory PerformanceTrend.fromJson(Map<String, dynamic> json) =>
      PerformanceTrend(
        direction: json['direction'],
        changeRate: json['changeRate'].toDouble(),
        weeksAnalyzed: json['weeksAnalyzed'],
        weeklyData: (json['weeklyData'] as List)
            .map((w) => WeeklyStats.fromJson(w))
            .toList(),
      );
}

/// Weekly performance statistics
class WeeklyStats {
  final DateTime weekStart;
  final double averageAccuracy;
  final int totalStudyTime; // minutes
  final int cardsStudied;
  final int quizzesCompleted;

  WeeklyStats({
    required this.weekStart,
    required this.averageAccuracy,
    required this.totalStudyTime,
    required this.cardsStudied,
    required this.quizzesCompleted,
  });

  Map<String, dynamic> toJson() => {
        'weekStart': weekStart.toIso8601String(),
        'averageAccuracy': averageAccuracy,
        'totalStudyTime': totalStudyTime,
        'cardsStudied': cardsStudied,
        'quizzesCompleted': quizzesCompleted,
      };

  factory WeeklyStats.fromJson(Map<String, dynamic> json) => WeeklyStats(
        weekStart: DateTime.parse(json['weekStart']),
        averageAccuracy: json['averageAccuracy'].toDouble(),
        totalStudyTime: json['totalStudyTime'],
        cardsStudied: json['cardsStudied'],
        quizzesCompleted: json['quizzesCompleted'],
      );
}

/// Real-time study session tracking
class StudySession {
  final String id;
  final String userId;
  final String? deckId;
  final String? subject;
  final DateTime startTime;
  DateTime? endTime;
  final List<SessionActivity> activities;
  final Map<String, dynamic> metadata;

  StudySession({
    required this.id,
    required this.userId,
    this.deckId,
    this.subject,
    required this.startTime,
    this.endTime,
    required this.activities,
    required this.metadata,
  });

  /// Get session duration in minutes
  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  /// Get overall session accuracy
  double get sessionAccuracy {
    final correctAnswers = activities
        .where((a) => a.type == 'answer' && a.wasCorrect == true)
        .length;
    final totalAnswers = activities.where((a) => a.type == 'answer').length;

    return totalAnswers > 0 ? correctAnswers / totalAnswers : 0.0;
  }

  /// Add activity to session
  void addActivity(SessionActivity activity) {
    activities.add(activity);
  }

  /// End the study session
  void endSession() {
    endTime = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'deckId': deckId,
        'subject': subject,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'activities': activities.map((a) => a.toJson()).toList(),
        'metadata': metadata,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'],
        userId: json['userId'],
        deckId: json['deckId'],
        subject: json['subject'],
        startTime: DateTime.parse(json['startTime']),
        endTime:
            json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
        activities: (json['activities'] as List)
            .map((a) => SessionActivity.fromJson(a))
            .toList(),
        metadata: Map<String, dynamic>.from(json['metadata']),
      );
}

/// Individual activity within a study session
class SessionActivity {
  final String type; // 'card_view', 'answer', 'hint_used', 'skip'
  final DateTime timestamp;
  final String? cardId;
  final bool? wasCorrect;
  final int? responseTimeMs;
  final Map<String, dynamic> data;

  SessionActivity({
    required this.type,
    required this.timestamp,
    this.cardId,
    this.wasCorrect,
    this.responseTimeMs,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'timestamp': timestamp.toIso8601String(),
        'cardId': cardId,
        'wasCorrect': wasCorrect,
        'responseTimeMs': responseTimeMs,
        'data': data,
      };

  factory SessionActivity.fromJson(Map<String, dynamic> json) =>
      SessionActivity(
        type: json['type'],
        timestamp: DateTime.parse(json['timestamp']),
        cardId: json['cardId'],
        wasCorrect: json['wasCorrect'],
        responseTimeMs: json['responseTimeMs'],
        data: Map<String, dynamic>.from(json['data']),
      );
}

/// Analytics service for calculating and updating user performance
class AnalyticsCalculator {
  /// Calculate comprehensive analytics from user's study data
  static StudyAnalytics calculateUserAnalytics({
    required String userId,
    required List<StudySession> sessions,
    required List<dynamic> quizSessions, // QuizSession instances
    required List<dynamic> reviews, // Review instances
  }) {
    // Calculate overall metrics
    final totalStudyTime = sessions
        .where((s) => s.endTime != null)
        .map((s) => s.durationMinutes)
        .fold(0, (sum, duration) => sum + duration);

    final totalCardsStudied = sessions
        .expand((s) => s.activities)
        .where((a) => a.type == 'card_view')
        .length;

    final totalQuizzes = quizSessions.length;

    // Calculate accuracy from all answer activities
    final allAnswers = sessions
        .expand((s) => s.activities)
        .where((a) => a.type == 'answer' && a.wasCorrect != null);

    final correctAnswers = allAnswers.where((a) => a.wasCorrect == true).length;
    final overallAccuracy =
        allAnswers.isNotEmpty ? correctAnswers / allAnswers.length : 0.0;

    // Calculate subject performance
    final subjectPerformance = <String, SubjectPerformance>{};
    final subjectSessions = <String, List<StudySession>>{};

    for (final session in sessions) {
      if (session.subject != null) {
        subjectSessions.putIfAbsent(session.subject!, () => []).add(session);
      }
    }

    for (final entry in subjectSessions.entries) {
      final subject = entry.key;
      final subjectSessionList = entry.value;

      final subjectAnswers = subjectSessionList
          .expand((s) => s.activities)
          .where((a) => a.type == 'answer' && a.wasCorrect != null);

      final subjectCorrect =
          subjectAnswers.where((a) => a.wasCorrect == true).length;
      final subjectAccuracy = subjectAnswers.isNotEmpty
          ? subjectCorrect / subjectAnswers.length
          : 0.0;

      final subjectCards = subjectSessionList
          .expand((s) => s.activities)
          .where((a) => a.type == 'card_view')
          .length;

      final subjectTime = subjectSessionList
          .where((s) => s.endTime != null)
          .map((s) => s.durationMinutes)
          .fold(0, (sum, duration) => sum + duration);

      final lastStudied = subjectSessionList
          .map((s) => s.startTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);

      subjectPerformance[subject] = SubjectPerformance(
        subject: subject,
        accuracy: subjectAccuracy,
        totalCards: subjectCards,
        totalQuizzes: 0, // TODO: Calculate from quiz sessions
        studyTimeMinutes: subjectTime,
        lastStudied: lastStudied,
        recentScores: [], // TODO: Calculate from recent quizzes
        difficultyBreakdown: {}, // TODO: Calculate from difficulty data
        averageResponseTime: 0.0, // TODO: Calculate from response times
      );
    }

    // Calculate learning patterns
    final studyHours = <String, int>{};
    for (final session in sessions) {
      final hour = session.startTime.hour.toString();
      studyHours[hour] = (studyHours[hour] ?? 0) + 1;
    }

    final learningPatterns = LearningPatterns(
      preferredStudyHours: studyHours,
      learningStyleEffectiveness: {}, // TODO: Calculate from performance data
      averageSessionLength: sessions.isNotEmpty
          ? totalStudyTime / sessions.length.toDouble()
          : 0.0,
      preferredCardsPerSession: sessions.isNotEmpty
          ? (totalCardsStudied / sessions.length).round()
          : 0,
      topicInterest: {}, // TODO: Calculate from engagement metrics
      commonMistakePatterns: [], // TODO: Analyze common mistakes
    );

    // Calculate performance trend
    final recentTrend = PerformanceTrend(
      direction: 'stable', // TODO: Calculate actual trend
      changeRate: 0.0, // TODO: Calculate change rate
      weeksAnalyzed: 4,
      weeklyData: [], // TODO: Calculate weekly stats
    );

    return StudyAnalytics(
      userId: userId,
      lastUpdated: DateTime.now(),
      overallAccuracy: overallAccuracy,
      totalStudyTime: totalStudyTime,
      totalCardsStudied: totalCardsStudied,
      totalQuizzesTaken: totalQuizzes,
      currentStreak: 0, // TODO: Calculate streak
      longestStreak: 0, // TODO: Calculate longest streak
      subjectPerformance: subjectPerformance,
      learningPatterns: learningPatterns,
      recentTrend: recentTrend,
    );
  }

  /// Update analytics based on a new study session
  static StudyAnalytics updateAnalyticsWithSession(
    StudyAnalytics currentAnalytics,
    StudySession newSession,
  ) {
    // TODO: Implement incremental analytics update
    // This would be more efficient than recalculating everything
    return currentAnalytics;
  }
}
