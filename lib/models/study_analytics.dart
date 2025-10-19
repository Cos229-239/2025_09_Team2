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

  // Answer tracking for accurate incremental updates
  final int totalAnswersGiven;
  final int totalCorrectAnswers;

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
    required this.totalAnswersGiven,
    required this.totalCorrectAnswers,
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
        'totalAnswersGiven': totalAnswersGiven,
        'totalCorrectAnswers': totalCorrectAnswers,
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
        totalAnswersGiven: json['totalAnswersGiven'] ?? 0,
        totalCorrectAnswers: json['totalCorrectAnswers'] ?? 0,
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

    final totalAnswersGiven = allAnswers.length;
    final correctAnswers = allAnswers.where((a) => a.wasCorrect == true).length;
    final totalCorrectAnswers = correctAnswers;
    final overallAccuracy =
        totalAnswersGiven > 0 ? totalCorrectAnswers / totalAnswersGiven : 0.0;

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

      // Calculate total quizzes for this subject from quiz sessions
      final subjectQuizzes = quizSessions.where((quiz) {
        // Improved matching: try direct subject match first, fallback to deck matching
        try {
          final deckId = (quiz as dynamic).deckId;

          // First try: Direct subject match (if QuizSession has subject field)
          try {
            final quizSubject = (quiz as dynamic).subject;
            if (quizSubject != null && quizSubject == subject) {
              return true;
            }
          } catch (_) {
            // subject field doesn't exist, that's fine - continue to deck matching
          }

          // Fallback: Match by deckId if the deck was used in this subject's sessions
          if (deckId != null &&
              subjectSessionList.any((s) => s.deckId == deckId)) {
            return true;
          }

          return false;
        } catch (e) {
          return false;
        }
      }).toList();

      // Calculate recent scores (last 10 quiz sessions for this subject)
      final recentQuizScores = <double>[];
      final sortedQuizzes = List.from(subjectQuizzes)
        ..sort((a, b) {
          try {
            final aTime = (a as dynamic).startTime as DateTime;
            final bTime = (b as dynamic).startTime as DateTime;
            return bTime.compareTo(aTime); // Most recent first
          } catch (e) {
            return 0;
          }
        });

      for (final quiz in sortedQuizzes.take(10)) {
        try {
          final score = (quiz as dynamic).finalScore;
          if (score != null) {
            recentQuizScores.add((score as num).toDouble());
          }
        } catch (e) {
          // Skip if we can't extract score
        }
      }

      // Calculate difficulty breakdown from session activities
      final difficultyMap = <String, int>{
        'easy': 0,
        'moderate': 0,
        'hard': 0,
      };

      for (final session in subjectSessionList) {
        // Extract difficulty from metadata if available
        final metadata = session.metadata;
        if (metadata.containsKey('cardDifficulties')) {
          final difficulties = metadata['cardDifficulties'] as Map?;
          if (difficulties != null) {
            for (final diff in difficulties.values) {
              final diffValue = diff as int;
              if (diffValue <= 2) {
                difficultyMap['easy'] = (difficultyMap['easy'] ?? 0) + 1;
              } else if (diffValue <= 3) {
                difficultyMap['moderate'] =
                    (difficultyMap['moderate'] ?? 0) + 1;
              } else {
                difficultyMap['hard'] = (difficultyMap['hard'] ?? 0) + 1;
              }
            }
          }
        }
      }

      // Calculate average response time from session activities
      final responseTimes = subjectSessionList
          .expand((s) => s.activities)
          .where((a) => a.type == 'answer' && a.responseTimeMs != null)
          .map((a) => a.responseTimeMs!)
          .toList();

      final averageResponseTime = responseTimes.isNotEmpty
          ? responseTimes.reduce((a, b) => a + b) /
              responseTimes.length /
              1000.0 // Convert to seconds
          : 0.0;

      subjectPerformance[subject] = SubjectPerformance(
        subject: subject,
        accuracy: subjectAccuracy,
        totalCards: subjectCards,
        totalQuizzes: subjectQuizzes.length,
        studyTimeMinutes: subjectTime,
        lastStudied: lastStudied,
        recentScores: recentQuizScores,
        difficultyBreakdown: difficultyMap,
        averageResponseTime: averageResponseTime,
      );
    }

    // Calculate learning patterns
    final studyHours = <String, int>{};
    for (final session in sessions) {
      final hour = session.startTime.hour.toString();
      studyHours[hour] = (studyHours[hour] ?? 0) + 1;
    }

    // Calculate learning style effectiveness
    final learningStyleEffectiveness = <String, double>{};
    final learningStyleSessions = <String, List<StudySession>>{};

    for (final session in sessions) {
      final metadata = session.metadata;
      if (metadata.containsKey('learningStyle')) {
        final style = metadata['learningStyle'] as String;
        learningStyleSessions.putIfAbsent(style, () => []).add(session);
      }
    }

    for (final entry in learningStyleSessions.entries) {
      final style = entry.key;
      final styleSessions = entry.value;

      final styleAnswers = styleSessions
          .expand((s) => s.activities)
          .where((a) => a.type == 'answer' && a.wasCorrect != null);

      if (styleAnswers.isNotEmpty) {
        final correct = styleAnswers.where((a) => a.wasCorrect == true).length;
        learningStyleEffectiveness[style] = correct / styleAnswers.length;
      }
    }

    // If no learning styles are tracked, use default ones based on overall performance
    if (learningStyleEffectiveness.isEmpty) {
      learningStyleEffectiveness['visual'] = overallAccuracy;
      learningStyleEffectiveness['reading'] = overallAccuracy * 0.95;
      learningStyleEffectiveness['kinesthetic'] = overallAccuracy * 0.90;
    }

    // Calculate topic interest based on engagement metrics
    final topicInterest = <String, double>{};
    final topicSessions = <String, List<StudySession>>{};

    for (final session in sessions) {
      if (session.subject != null) {
        topicSessions.putIfAbsent(session.subject!, () => []).add(session);
      }
    }

    for (final entry in topicSessions.entries) {
      final topic = entry.key;
      final topicSessionList = entry.value;

      // Calculate engagement score based on:
      // 1. Session frequency (30%)
      // 2. Average session length (30%)
      // 3. Activity count per session (40%)
      final frequency = topicSessionList.length.toDouble();
      final avgLength = topicSessionList.isNotEmpty
          ? topicSessionList
                  .where((s) => s.endTime != null)
                  .map((s) => s.durationMinutes)
                  .fold(0, (sum, dur) => sum + dur) /
              topicSessionList.length
          : 0.0;
      final avgActivities = topicSessionList.isNotEmpty
          ? topicSessionList
                  .map((s) => s.activities.length)
                  .fold(0, (sum, count) => sum + count) /
              topicSessionList.length
          : 0.0;

      // Normalize to 0-1 scale
      final maxFrequency = sessions.length.toDouble();
      final normalizedFrequency = frequency / maxFrequency;
      final normalizedLength =
          avgLength > 0 ? (avgLength / 60.0).clamp(0.0, 1.0) : 0.0;
      final normalizedActivities =
          avgActivities > 0 ? (avgActivities / 50.0).clamp(0.0, 1.0) : 0.0;

      topicInterest[topic] = (normalizedFrequency * 0.3) +
          (normalizedLength * 0.3) +
          (normalizedActivities * 0.4);
    }

    // Analyze common mistake patterns
    final commonMistakePatterns = <String>[];
    final incorrectAnswers = sessions
        .expand((s) => s.activities)
        .where((a) => a.type == 'answer' && a.wasCorrect == false);

    if (incorrectAnswers.isNotEmpty) {
      // Group mistakes by card/topic
      final mistakesByCard = <String, int>{};
      for (final answer in incorrectAnswers) {
        if (answer.cardId != null) {
          mistakesByCard[answer.cardId!] =
              (mistakesByCard[answer.cardId!] ?? 0) + 1;
        }
      }

      // Find cards with multiple mistakes
      final frequentMistakes = mistakesByCard.entries
          .where((e) => e.value >= 2)
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Create pattern descriptions
      if (frequentMistakes.isNotEmpty) {
        commonMistakePatterns
            .add('Repeated errors on ${frequentMistakes.length} cards');
      }

      // Analyze mistake timing
      final recentMistakes = incorrectAnswers
          .where((a) => a.timestamp
              .isAfter(DateTime.now().subtract(const Duration(days: 7))))
          .length;
      final totalMistakes = incorrectAnswers.length;

      if (recentMistakes > totalMistakes * 0.5) {
        commonMistakePatterns.add('High error rate in recent sessions');
      }

      // Analyze response time correlation
      final slowIncorrect = incorrectAnswers
          .where((a) => a.responseTimeMs != null && a.responseTimeMs! > 10000)
          .length;

      if (slowIncorrect > totalMistakes * 0.3) {
        commonMistakePatterns.add('Slower response times on incorrect answers');
      }
    }

    final learningPatterns = LearningPatterns(
      preferredStudyHours: studyHours,
      learningStyleEffectiveness: learningStyleEffectiveness,
      averageSessionLength: sessions.isNotEmpty
          ? totalStudyTime / sessions.length.toDouble()
          : 0.0,
      preferredCardsPerSession: sessions.isNotEmpty
          ? (totalCardsStudied / sessions.length).round()
          : 0,
      topicInterest: topicInterest,
      commonMistakePatterns: commonMistakePatterns,
    );

    // Calculate performance trend
    final weeklyData = <WeeklyStats>[];
    final now = DateTime.now();
    final weeksToAnalyze = 4;

    // Group sessions by week
    for (int i = 0; i < weeksToAnalyze; i++) {
      final weekStart = now.subtract(Duration(days: 7 * (i + 1)));
      final weekEnd = now.subtract(Duration(days: 7 * i));

      final weekSessions = sessions.where((s) =>
          s.startTime.isAfter(weekStart) && s.startTime.isBefore(weekEnd));

      if (weekSessions.isEmpty) {
        // Include weeks with no activity
        weeklyData.add(WeeklyStats(
          weekStart: weekStart,
          averageAccuracy: 0.0,
          totalStudyTime: 0,
          cardsStudied: 0,
          quizzesCompleted: 0,
        ));
        continue;
      }

      // Calculate weekly metrics
      final weekAnswers = weekSessions
          .expand((s) => s.activities)
          .where((a) => a.type == 'answer' && a.wasCorrect != null);

      final weekAccuracy = weekAnswers.isNotEmpty
          ? weekAnswers.where((a) => a.wasCorrect == true).length /
              weekAnswers.length
          : 0.0;

      final weekStudyTime = weekSessions
          .where((s) => s.endTime != null)
          .map((s) => s.durationMinutes)
          .fold(0, (sum, dur) => sum + dur);

      final weekCards = weekSessions
          .expand((s) => s.activities)
          .where((a) => a.type == 'card_view')
          .length;

      final weekQuizzes = quizSessions.where((quiz) {
        try {
          final quizStart = (quiz as dynamic).startTime as DateTime;
          return quizStart.isAfter(weekStart) && quizStart.isBefore(weekEnd);
        } catch (e) {
          return false;
        }
      }).length;

      weeklyData.add(WeeklyStats(
        weekStart: weekStart,
        averageAccuracy: weekAccuracy,
        totalStudyTime: weekStudyTime,
        cardsStudied: weekCards,
        quizzesCompleted: weekQuizzes,
      ));
    }

    // Reverse to get chronological order (oldest to newest)
    final chronologicalWeeks = weeklyData.reversed.toList();

    // Calculate trend direction and change rate
    String trendDirection = 'stable';
    double changeRate = 0.0;

    if (chronologicalWeeks.length >= 2) {
      final weeksWithData = chronologicalWeeks
          .where((w) => w.averageAccuracy > 0 || w.cardsStudied > 0)
          .toList();

      if (weeksWithData.length >= 2) {
        // Calculate linear regression for accuracy trend
        final accuracies = weeksWithData.map((w) => w.averageAccuracy).toList();

        // Simple trend calculation: compare first half to second half
        final firstHalf = accuracies.take(accuracies.length ~/ 2).toList();
        final secondHalf = accuracies.skip(accuracies.length ~/ 2).toList();

        if (firstHalf.isNotEmpty && secondHalf.isNotEmpty) {
          final firstAvg = firstHalf.reduce((a, b) => a + b) / firstHalf.length;
          final secondAvg =
              secondHalf.reduce((a, b) => a + b) / secondHalf.length;

          final difference = secondAvg - firstAvg;

          // Calculate percentage change per week
          if (firstAvg > 0) {
            changeRate = (difference / firstAvg) * 100 / weeksToAnalyze;
          }

          // Determine direction
          if (difference > 0.05) {
            trendDirection = 'improving';
          } else if (difference < -0.05) {
            trendDirection = 'declining';
          } else {
            trendDirection = 'stable';
          }
        }
      }
    }

    final recentTrend = PerformanceTrend(
      direction: trendDirection,
      changeRate: changeRate,
      weeksAnalyzed: weeksToAnalyze,
      weeklyData: chronologicalWeeks,
    );

    // Calculate study streaks
    int currentStreak = 0;
    int longestStreak = 0;

    if (sessions.isNotEmpty) {
      // Get unique study dates (date only, no time)
      final studyDates = sessions
          .map((s) =>
              DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
          .toSet()
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Sort descending (newest first)

      if (studyDates.isNotEmpty) {
        // Calculate current streak
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(const Duration(days: 1));

        // Check if studied today or yesterday
        if (studyDates.first.isAtSameMomentAs(today) ||
            studyDates.first.isAtSameMomentAs(yesterday)) {
          currentStreak = 1;
          DateTime expectedDate =
              studyDates.first.subtract(const Duration(days: 1));

          for (int i = 1; i < studyDates.length; i++) {
            if (studyDates[i].isAtSameMomentAs(expectedDate)) {
              currentStreak++;
              expectedDate = expectedDate.subtract(const Duration(days: 1));
            } else {
              break;
            }
          }
        }

        // Calculate longest streak in history
        int tempStreak = 1;
        longestStreak = 1;

        for (int i = 1; i < studyDates.length; i++) {
          final daysDifference =
              studyDates[i - 1].difference(studyDates[i]).inDays;

          if (daysDifference == 1) {
            tempStreak++;
            if (tempStreak > longestStreak) {
              longestStreak = tempStreak;
            }
          } else {
            tempStreak = 1;
          }
        }
      }
    }

    return StudyAnalytics(
      userId: userId,
      lastUpdated: DateTime.now(),
      overallAccuracy: overallAccuracy,
      totalStudyTime: totalStudyTime,
      totalCardsStudied: totalCardsStudied,
      totalQuizzesTaken: totalQuizzes,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      totalAnswersGiven: totalAnswersGiven,
      totalCorrectAnswers: totalCorrectAnswers,
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
    // Update overall metrics
    final newTotalStudyTime = currentAnalytics.totalStudyTime +
        (newSession.endTime != null ? newSession.durationMinutes : 0);

    final newCardsStudied = currentAnalytics.totalCardsStudied +
        newSession.activities.where((a) => a.type == 'card_view').length;

    // Update overall accuracy using actual counts instead of estimates
    final newAnswers = newSession.activities
        .where((a) => a.type == 'answer' && a.wasCorrect != null);
    final newCorrect = newAnswers.where((a) => a.wasCorrect == true).length;
    final totalAnswers = newAnswers.length;

    // Use actual tracked counts for accurate calculation
    final newTotalAnswersGiven =
        currentAnalytics.totalAnswersGiven + totalAnswers;
    final newTotalCorrectAnswers =
        currentAnalytics.totalCorrectAnswers + newCorrect;

    final newOverallAccuracy = newTotalAnswersGiven > 0
        ? newTotalCorrectAnswers / newTotalAnswersGiven
        : currentAnalytics.overallAccuracy;

    // Update subject performance for the session's subject
    final updatedSubjectPerformance = Map<String, SubjectPerformance>.from(
        currentAnalytics.subjectPerformance);

    if (newSession.subject != null) {
      final subject = newSession.subject!;
      final currentSubject = updatedSubjectPerformance[subject];

      if (currentSubject != null) {
        // Update existing subject
        final subjectAnswers = newSession.activities
            .where((a) => a.type == 'answer' && a.wasCorrect != null);
        final subjectCorrect =
            subjectAnswers.where((a) => a.wasCorrect == true).length;

        // Calculate new subject accuracy
        final prevTotal = (currentSubject.totalCards * 0.8).round();
        final prevCorrect = (prevTotal * currentSubject.accuracy).round();
        final newTotal = prevTotal + subjectAnswers.length;
        final newSubjectAccuracy = newTotal > 0
            ? (prevCorrect + subjectCorrect) / newTotal
            : currentSubject.accuracy;

        final newSubjectCards = currentSubject.totalCards +
            newSession.activities.where((a) => a.type == 'card_view').length;

        final newSubjectTime = currentSubject.studyTimeMinutes +
            (newSession.endTime != null ? newSession.durationMinutes : 0);

        // Update response times
        final responseTimes = newSession.activities
            .where((a) => a.type == 'answer' && a.responseTimeMs != null)
            .map((a) => a.responseTimeMs!)
            .toList();

        final newResponseTime = responseTimes.isNotEmpty
            ? responseTimes.reduce((a, b) => a + b) /
                responseTimes.length /
                1000.0
            : currentSubject.averageResponseTime;

        // Weighted average of old and new response times
        final combinedResponseTime = currentSubject.totalCards > 0
            ? (currentSubject.averageResponseTime * currentSubject.totalCards +
                    newResponseTime * responseTimes.length) /
                (currentSubject.totalCards + responseTimes.length)
            : newResponseTime;

        updatedSubjectPerformance[subject] = SubjectPerformance(
          subject: subject,
          accuracy: newSubjectAccuracy,
          totalCards: newSubjectCards,
          totalQuizzes: currentSubject.totalQuizzes,
          studyTimeMinutes: newSubjectTime,
          lastStudied: newSession.startTime.isAfter(currentSubject.lastStudied)
              ? newSession.startTime
              : currentSubject.lastStudied,
          recentScores: currentSubject.recentScores,
          difficultyBreakdown: currentSubject.difficultyBreakdown,
          averageResponseTime: combinedResponseTime,
        );
      } else {
        // Create new subject entry
        final subjectAnswers = newSession.activities
            .where((a) => a.type == 'answer' && a.wasCorrect != null);
        final subjectCorrect =
            subjectAnswers.where((a) => a.wasCorrect == true).length;
        final subjectAccuracy = subjectAnswers.isNotEmpty
            ? subjectCorrect / subjectAnswers.length
            : 0.0;

        final subjectCards =
            newSession.activities.where((a) => a.type == 'card_view').length;

        final responseTimes = newSession.activities
            .where((a) => a.type == 'answer' && a.responseTimeMs != null)
            .map((a) => a.responseTimeMs!)
            .toList();

        final avgResponseTime = responseTimes.isNotEmpty
            ? responseTimes.reduce((a, b) => a + b) /
                responseTimes.length /
                1000.0
            : 0.0;

        updatedSubjectPerformance[subject] = SubjectPerformance(
          subject: subject,
          accuracy: subjectAccuracy,
          totalCards: subjectCards,
          totalQuizzes: 0,
          studyTimeMinutes:
              newSession.endTime != null ? newSession.durationMinutes : 0,
          lastStudied: newSession.startTime,
          recentScores: [],
          difficultyBreakdown: {'easy': 0, 'moderate': 0, 'hard': 0},
          averageResponseTime: avgResponseTime,
        );
      }
    }

    // Update streak if this is a new day
    final today =
        DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final sessionDate = DateTime(newSession.startTime.year,
        newSession.startTime.month, newSession.startTime.day);

    int newCurrentStreak = currentAnalytics.currentStreak;
    int newLongestStreak = currentAnalytics.longestStreak;

    if (sessionDate.isAtSameMomentAs(today)) {
      // Session is today, potentially extend streak
      // If we had a streak going, extend it
      if (currentAnalytics.currentStreak > 0) {
        // Streak continues
        newCurrentStreak = currentAnalytics.currentStreak;
      } else {
        // Starting a new streak
        newCurrentStreak = 1;
      }

      // Update longest streak if current exceeds it
      if (newCurrentStreak > newLongestStreak) {
        newLongestStreak = newCurrentStreak;
      }
    }

    return StudyAnalytics(
      userId: currentAnalytics.userId,
      lastUpdated: DateTime.now(),
      overallAccuracy: newOverallAccuracy,
      totalStudyTime: newTotalStudyTime,
      totalCardsStudied: newCardsStudied,
      totalQuizzesTaken: currentAnalytics.totalQuizzesTaken,
      currentStreak: newCurrentStreak,
      longestStreak: newLongestStreak,
      totalAnswersGiven: newTotalAnswersGiven,
      totalCorrectAnswers: newTotalCorrectAnswers,
      subjectPerformance: updatedSubjectPerformance,
      learningPatterns: currentAnalytics.learningPatterns,
      recentTrend: currentAnalytics.recentTrend,
    );
  }
}
