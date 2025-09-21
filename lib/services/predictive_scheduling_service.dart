import 'dart:math';
import '../models/study_pal_persona.dart';

/// Represents different times of day for scheduling
enum TimeOfDay {
  earlyMorning, // 5-8 AM
  morning,     // 8-11 AM
  midday,      // 11 AM-2 PM
  afternoon,   // 2-5 PM
  evening,     // 5-8 PM
  night,       // 8-11 PM
  lateNight,   // 11 PM-5 AM
}

/// Days of the week
enum DayOfWeek {
  monday,
  tuesday,
  wednesday,
  thursday,
  friday,
  saturday,
  sunday,
}

/// Study session difficulty levels
enum StudyDifficulty {
  easy,
  medium,
  hard,
  review,
}

/// Performance metrics for a study session
class StudySessionMetrics {
  final DateTime timestamp;
  final Duration sessionLength;
  final int totalQuestions;
  final int correctAnswers;
  final double averageResponseTime;
  final EmotionalState dominantEmotion;
  final TimeOfDay timeOfDay;
  final DayOfWeek dayOfWeek;
  final StudyDifficulty difficulty;
  final String subject;
  final double focusScore; // 0.0 - 1.0
  final double retentionScore; // 0.0 - 1.0
  final bool completedSession;

  StudySessionMetrics({
    required this.timestamp,
    required this.sessionLength,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.averageResponseTime,
    required this.dominantEmotion,
    required this.timeOfDay,
    required this.dayOfWeek,
    required this.difficulty,
    required this.subject,
    required this.focusScore,
    required this.retentionScore,
    required this.completedSession,
  });

  double get accuracyRate => totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;
  
  double get efficiencyScore {
    // Use service weights for calculation (would access via service instance in real implementation)
    final accuracyWeight = accuracyRate * 0.3;
    final focusWeight = focusScore * 0.25;
    final retentionWeight = retentionScore * 0.2;
    final completionWeight = completedSession ? 0.15 : 0.0;
    final moodWeight = dominantEmotion == EmotionalState.confident || 
                      dominantEmotion == EmotionalState.excited ? 0.1 : 0.0;
    return accuracyWeight + focusWeight + retentionWeight + completionWeight + moodWeight;
  }
}

/// Predicted optimal study schedule
class StudySchedulePrediction {
  final DateTime recommendedTime;
  final Duration estimatedDuration;
  final StudyDifficulty recommendedDifficulty;
  final List<String> recommendedSubjects;
  final double confidenceScore; // 0.0 - 1.0
  final String reasoning;
  final Map<String, dynamic> optimizationFactors;

  StudySchedulePrediction({
    required this.recommendedTime,
    required this.estimatedDuration,
    required this.recommendedDifficulty,
    required this.recommendedSubjects,
    required this.confidenceScore,
    required this.reasoning,
    required this.optimizationFactors,
  });
}

/// Performance pattern analysis for scheduling optimization
class PerformancePattern {
  final TimeOfDay bestTimeOfDay;
  final DayOfWeek bestDayOfWeek;
  final Duration optimalSessionLength;
  final Map<TimeOfDay, double> timePerformanceMap;
  final Map<DayOfWeek, double> dayPerformanceMap;
  final Map<StudyDifficulty, TimeOfDay> difficultyTimePreferences;
  final List<EmotionalState> optimalEmotionalStates;

  PerformancePattern({
    required this.bestTimeOfDay,
    required this.bestDayOfWeek,
    required this.optimalSessionLength,
    required this.timePerformanceMap,
    required this.dayPerformanceMap,
    required this.difficultyTimePreferences,
    required this.optimalEmotionalStates,
  });
}

/// Circadian rhythm analysis for study optimization
class CircadianAnalysis {
  final Map<int, double> hourlyAlertness; // Hour of day -> alertness score
  final Map<int, double> hourlyFocus; // Hour of day -> focus score
  final Map<int, double> hourlyRetention; // Hour of day -> retention score
  final int peakPerformanceHour;
  final int lowPerformanceHour;
  final List<int> optimalStudyHours;

  CircadianAnalysis({
    required this.hourlyAlertness,
    required this.hourlyFocus,
    required this.hourlyRetention,
    required this.peakPerformanceHour,
    required this.lowPerformanceHour,
    required this.optimalStudyHours,
  });
}

/// Comprehensive predictive scheduling service
class PredictiveSchedulingService {
  static final PredictiveSchedulingService _instance = PredictiveSchedulingService._internal();
  factory PredictiveSchedulingService() => _instance;
  PredictiveSchedulingService._internal();

  final List<StudySessionMetrics> _sessionHistory = [];

  /// Record a completed study session for learning
  void recordStudySession(StudySessionMetrics metrics) {
    _sessionHistory.add(metrics);
    
    // Keep only recent history (last 100 sessions for performance)
    if (_sessionHistory.length > 100) {
      _sessionHistory.removeAt(0);
    }
    
    // Trigger pattern analysis update
    _updateLearningPatterns();
  }

  /// Get optimal study schedule prediction for the next period
  StudySchedulePrediction predictOptimalSchedule({
    required DateTime targetDate,
    required List<String> availableSubjects,
    required Map<String, int> subjectPriorities,
    StudyPalPersona? persona,
    Duration? availableTime,
  }) {
    final patterns = _analyzePerformancePatterns();
    final circadian = _analyzeCircadianRhythm();
    
    // Find optimal time slot
    final optimalTime = _findOptimalTimeSlot(
      targetDate: targetDate,
      patterns: patterns,
      circadian: circadian,
      availableTime: availableTime,
    );
    
    // Determine optimal difficulty
    final optimalDifficulty = _predictOptimalDifficulty(
      timeOfDay: _getTimeOfDay(optimalTime.hour),
      patterns: patterns,
      persona: persona,
    );
    
    // Recommend subjects
    final recommendedSubjects = _recommendSubjects(
      availableSubjects: availableSubjects,
      priorities: subjectPriorities,
      timeOfDay: _getTimeOfDay(optimalTime.hour),
      difficulty: optimalDifficulty,
    );
    
    // Estimate optimal duration
    final estimatedDuration = _estimateOptimalDuration(
      timeOfDay: _getTimeOfDay(optimalTime.hour),
      difficulty: optimalDifficulty,
      patterns: patterns,
      persona: persona,
    );
    
    // Calculate confidence score
    final confidence = _calculateConfidenceScore(patterns, circadian);
    
    // Generate reasoning
    final reasoning = _generateSchedulingReasoning(
      optimalTime: optimalTime,
      difficulty: optimalDifficulty,
      subjects: recommendedSubjects,
      patterns: patterns,
      persona: persona,
    );
    
    return StudySchedulePrediction(
      recommendedTime: optimalTime,
      estimatedDuration: estimatedDuration,
      recommendedDifficulty: optimalDifficulty,
      recommendedSubjects: recommendedSubjects,
      confidenceScore: confidence,
      reasoning: reasoning,
      optimizationFactors: {
        'timeOptimization': patterns.timePerformanceMap[_getTimeOfDay(optimalTime.hour)] ?? 0.5,
        'dayOptimization': patterns.dayPerformanceMap[_getDayOfWeek(optimalTime.weekday)] ?? 0.5,
        'circadianAlignment': circadian.hourlyAlertness[optimalTime.hour] ?? 0.5,
        'difficultyMatch': 0.8, // Simplified calculation
        'subjectRelevance': 0.7, // Simplified calculation
      },
    );
  }

  /// Get weekly schedule optimization
  List<StudySchedulePrediction> generateWeeklySchedule({
    required DateTime weekStart,
    required Map<String, int> subjectHours,
    required List<String> availableTimeSlots,
    StudyPalPersona? persona,
  }) {
    final predictions = <StudySchedulePrediction>[];
    final patterns = _analyzePerformancePatterns();
    final circadian = _analyzeCircadianRhythm();
    
    for (int day = 0; day < 7; day++) {
      final currentDate = weekStart.add(Duration(days: day));
      
      // Get subjects that need study time
      final subjectsForDay = _distributeSubjectsAcrossDays(subjectHours, day);
      
      if (subjectsForDay.isNotEmpty) {
        final prediction = _generateDaySchedule(
          date: currentDate,
          subjects: subjectsForDay,
          patterns: patterns,
          circadian: circadian,
          persona: persona,
        );
        
        if (prediction != null) {
          predictions.add(prediction);
        }
      }
    }
    
    return predictions;
  }

  /// Analyze when user learns most effectively
  PerformancePattern _analyzePerformancePatterns() {
    if (_sessionHistory.length < 5) {
      // Return default patterns for new users
      return _getDefaultPerformancePattern();
    }
    
    // Calculate performance by time of day
    final timePerformanceMap = <TimeOfDay, double>{};
    final dayPerformanceMap = <DayOfWeek, double>{};
    final difficultyTimePreferences = <StudyDifficulty, TimeOfDay>{};
    
    for (final timeOfDay in TimeOfDay.values) {
      final sessionsAtTime = _sessionHistory.where((s) => s.timeOfDay == timeOfDay).toList();
      if (sessionsAtTime.isNotEmpty) {
        final avgPerformance = sessionsAtTime
            .map((s) => s.efficiencyScore)
            .reduce((a, b) => a + b) / sessionsAtTime.length;
        timePerformanceMap[timeOfDay] = avgPerformance;
      } else {
        timePerformanceMap[timeOfDay] = 0.5; // Default neutral performance
      }
    }
    
    // Calculate performance by day of week
    for (final dayOfWeek in DayOfWeek.values) {
      final sessionsOnDay = _sessionHistory.where((s) => s.dayOfWeek == dayOfWeek).toList();
      if (sessionsOnDay.isNotEmpty) {
        final avgPerformance = sessionsOnDay
            .map((s) => s.efficiencyScore)
            .reduce((a, b) => a + b) / sessionsOnDay.length;
        dayPerformanceMap[dayOfWeek] = avgPerformance;
      } else {
        dayPerformanceMap[dayOfWeek] = 0.5;
      }
    }
    
    // Find best times for each difficulty level
    for (final difficulty in StudyDifficulty.values) {
      final sessionsByDifficulty = _sessionHistory.where((s) => s.difficulty == difficulty).toList();
      if (sessionsByDifficulty.isNotEmpty) {
        final timePerformanceForDifficulty = <TimeOfDay, double>{};
        
        for (final timeOfDay in TimeOfDay.values) {
          final sessionsAtTimeAndDifficulty = sessionsByDifficulty
              .where((s) => s.timeOfDay == timeOfDay)
              .toList();
          if (sessionsAtTimeAndDifficulty.isNotEmpty) {
            final avgPerformance = sessionsAtTimeAndDifficulty
                .map((s) => s.efficiencyScore)
                .reduce((a, b) => a + b) / sessionsAtTimeAndDifficulty.length;
            timePerformanceForDifficulty[timeOfDay] = avgPerformance;
          }
        }
        
        if (timePerformanceForDifficulty.isNotEmpty) {
          final bestTime = timePerformanceForDifficulty.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
          difficultyTimePreferences[difficulty] = bestTime;
        }
      }
    }
    
    // Find overall best time and day
    final bestTime = timePerformanceMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final bestDay = dayPerformanceMap.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Calculate optimal session length
    final completedSessions = _sessionHistory.where((s) => s.completedSession).toList();
    final optimalLength = completedSessions.isNotEmpty
        ? Duration(
            minutes: (completedSessions
                    .map((s) => s.sessionLength.inMinutes)
                    .reduce((a, b) => a + b) /
                completedSessions.length).round(),
          )
        : const Duration(minutes: 25); // Default Pomodoro length
    
    // Find optimal emotional states
    final emotionPerformanceMap = <EmotionalState, double>{};
    for (final emotion in EmotionalState.values) {
      final sessionsWithEmotion = _sessionHistory.where((s) => s.dominantEmotion == emotion).toList();
      if (sessionsWithEmotion.isNotEmpty) {
        final avgPerformance = sessionsWithEmotion
            .map((s) => s.efficiencyScore)
            .reduce((a, b) => a + b) / sessionsWithEmotion.length;
        emotionPerformanceMap[emotion] = avgPerformance;
      }
    }
    
    final optimalEmotions = emotionPerformanceMap.entries
        .where((e) => e.value > 0.6) // Good performance threshold
        .map((e) => e.key)
        .toList();
    
    return PerformancePattern(
      bestTimeOfDay: bestTime,
      bestDayOfWeek: bestDay,
      optimalSessionLength: optimalLength,
      timePerformanceMap: timePerformanceMap,
      dayPerformanceMap: dayPerformanceMap,
      difficultyTimePreferences: difficultyTimePreferences,
      optimalEmotionalStates: optimalEmotions,
    );
  }

  /// Analyze user's circadian rhythm patterns
  CircadianAnalysis _analyzeCircadianRhythm() {
    final hourlyAlertness = <int, double>{};
    final hourlyFocus = <int, double>{};
    final hourlyRetention = <int, double>{};
    
    // Initialize all hours
    for (int hour = 0; hour < 24; hour++) {
      hourlyAlertness[hour] = 0.5;
      hourlyFocus[hour] = 0.5;
      hourlyRetention[hour] = 0.5;
    }
    
    // Analyze historical data
    if (_sessionHistory.isNotEmpty) {
      final hourlySessionData = <int, List<StudySessionMetrics>>{};
      
      // Group sessions by hour
      for (final session in _sessionHistory) {
        final hour = session.timestamp.hour;
        hourlySessionData.putIfAbsent(hour, () => []);
        hourlySessionData[hour]!.add(session);
      }
      
      // Calculate metrics for each hour
      for (final entry in hourlySessionData.entries) {
        final hour = entry.key;
        final sessions = entry.value;
        
        if (sessions.isNotEmpty) {
          hourlyAlertness[hour] = sessions
              .map((s) => s.accuracyRate)
              .reduce((a, b) => a + b) / sessions.length;
          
          hourlyFocus[hour] = sessions
              .map((s) => s.focusScore)
              .reduce((a, b) => a + b) / sessions.length;
          
          hourlyRetention[hour] = sessions
              .map((s) => s.retentionScore)
              .reduce((a, b) => a + b) / sessions.length;
        }
      }
    }
    
    // Find peak and low performance hours
    final peakHour = hourlyAlertness.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    final lowHour = hourlyAlertness.entries
        .reduce((a, b) => a.value < b.value ? a : b)
        .key;
    
    // Find optimal study hours (top 6 hours)
    final sortedHours = hourlyAlertness.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final optimalHours = sortedHours.take(6).map((e) => e.key).toList();
    
    return CircadianAnalysis(
      hourlyAlertness: hourlyAlertness,
      hourlyFocus: hourlyFocus,
      hourlyRetention: hourlyRetention,
      peakPerformanceHour: peakHour,
      lowPerformanceHour: lowHour,
      optimalStudyHours: optimalHours,
    );
  }

  DateTime _findOptimalTimeSlot({
    required DateTime targetDate,
    required PerformancePattern patterns,
    required CircadianAnalysis circadian,
    Duration? availableTime,
  }) {
    final dayOfWeek = _getDayOfWeek(targetDate.weekday);
    
    // Find the best hour on this day
    int bestHour = circadian.peakPerformanceHour;
    
    // Adjust for weekends vs weekdays
    if (dayOfWeek == DayOfWeek.saturday || dayOfWeek == DayOfWeek.sunday) {
      // Weekends - prefer later start times
      bestHour = max(9, bestHour);
    } else {
      // Weekdays - consider work/school schedules
      if (bestHour < 7) bestHour = 7;
      if (bestHour > 22) bestHour = 22;
    }
    
    return DateTime(
      targetDate.year,
      targetDate.month,
      targetDate.day,
      bestHour,
      0,
    );
  }

  StudyDifficulty _predictOptimalDifficulty({
    required TimeOfDay timeOfDay,
    required PerformancePattern patterns,
    StudyPalPersona? persona,
  }) {
    // Check if we have specific difficulty preferences for this time
    final difficultyPreferences = patterns.difficultyTimePreferences;
    
    for (final entry in difficultyPreferences.entries) {
      if (entry.value == timeOfDay) {
        return entry.key;
      }
    }
    
    // Default logic based on time of day and persona
    switch (timeOfDay) {
      case TimeOfDay.earlyMorning:
      case TimeOfDay.morning:
        return StudyDifficulty.hard; // Peak cognitive performance
      case TimeOfDay.midday:
        return StudyDifficulty.medium;
      case TimeOfDay.afternoon:
        return StudyDifficulty.medium;
      case TimeOfDay.evening:
        return StudyDifficulty.review; // Good for consolidation
      case TimeOfDay.night:
        return StudyDifficulty.easy;
      case TimeOfDay.lateNight:
        return StudyDifficulty.review;
    }
  }

  List<String> _recommendSubjects({
    required List<String> availableSubjects,
    required Map<String, int> priorities,
    required TimeOfDay timeOfDay,
    required StudyDifficulty difficulty,
  }) {
    // Sort subjects by priority
    final sortedSubjects = availableSubjects.toList()
      ..sort((a, b) => (priorities[b] ?? 0).compareTo(priorities[a] ?? 0));
    
    // Return top subjects based on difficulty
    switch (difficulty) {
      case StudyDifficulty.hard:
        return sortedSubjects.take(1).toList(); // Focus on one challenging subject
      case StudyDifficulty.medium:
        return sortedSubjects.take(2).toList();
      case StudyDifficulty.easy:
      case StudyDifficulty.review:
        return sortedSubjects.take(3).toList(); // Can handle more subjects
    }
  }

  Duration _estimateOptimalDuration({
    required TimeOfDay timeOfDay,
    required StudyDifficulty difficulty,
    required PerformancePattern patterns,
    StudyPalPersona? persona,
  }) {
    Duration baseDuration = patterns.optimalSessionLength;
    
    // Adjust based on difficulty
    switch (difficulty) {
      case StudyDifficulty.hard:
        baseDuration = Duration(minutes: (baseDuration.inMinutes * 0.8).round()); // Shorter for intense focus
        break;
      case StudyDifficulty.medium:
        // Keep base duration
        break;
      case StudyDifficulty.easy:
      case StudyDifficulty.review:
        baseDuration = Duration(minutes: (baseDuration.inMinutes * 1.2).round()); // Longer for easier content
        break;
    }
    
    // Adjust based on time of day
    switch (timeOfDay) {
      case TimeOfDay.earlyMorning:
      case TimeOfDay.morning:
        // Peak hours - can handle longer sessions
        baseDuration = Duration(minutes: (baseDuration.inMinutes * 1.1).round());
        break;
      case TimeOfDay.lateNight:
        // Reduce for late hours
        baseDuration = Duration(minutes: (baseDuration.inMinutes * 0.7).round());
        break;
      default:
        // Keep adjusted duration
        break;
    }
    
    // Persona adjustments
    if (persona != null) {
      switch (persona.type) {
        case PersonaType.scholar:
          baseDuration = Duration(minutes: (baseDuration.inMinutes * 1.3).round()); // Longer sessions
          break;
        case PersonaType.buddy:
          baseDuration = Duration(minutes: (baseDuration.inMinutes * 0.9).round()); // Shorter, more frequent
          break;
        default:
          // Keep duration
          break;
      }
    }
    
    // Ensure reasonable bounds
    final minutes = baseDuration.inMinutes.clamp(15, 120);
    return Duration(minutes: minutes);
  }

  double _calculateConfidenceScore(PerformancePattern patterns, CircadianAnalysis circadian) {
    double confidence = 0.5; // Base confidence
    
    // Increase confidence based on data availability
    final dataPoints = _sessionHistory.length;
    if (dataPoints >= 20) {
      confidence += 0.3;
    } else if (dataPoints >= 10) {
      confidence += 0.2;
    } else if (dataPoints >= 5) {
      confidence += 0.1;
    }
    
    // Increase confidence based on pattern consistency
    final timeVariance = _calculateVariance(patterns.timePerformanceMap.values.toList());
    if (timeVariance < 0.1) {
      confidence += 0.2; // Consistent patterns
    }
    
    return confidence.clamp(0.0, 1.0);
  }

  String _generateSchedulingReasoning({
    required DateTime optimalTime,
    required StudyDifficulty difficulty,
    required List<String> subjects,
    required PerformancePattern patterns,
    StudyPalPersona? persona,
  }) {
    final timeOfDay = _getTimeOfDay(optimalTime.hour);
    final dayOfWeek = _getDayOfWeek(optimalTime.weekday);
    
    final reasons = <String>[];
    
    // Time-based reasoning
    final timePerformance = patterns.timePerformanceMap[timeOfDay] ?? 0.5;
    if (timePerformance > 0.7) {
      reasons.add('You typically perform ${(timePerformance * 100).round()}% better during ${_timeOfDayToString(timeOfDay)}');
    }
    
    // Day-based reasoning
    final dayPerformance = patterns.dayPerformanceMap[dayOfWeek] ?? 0.5;
    if (dayPerformance > 0.6) {
      reasons.add('${_dayOfWeekToString(dayOfWeek)}s are historically good study days for you');
    }
    
    // Difficulty reasoning
    switch (difficulty) {
      case StudyDifficulty.hard:
        reasons.add('This time is optimal for challenging material when your cognitive resources are at their peak');
        break;
      case StudyDifficulty.review:
        reasons.add('Perfect timing for review and consolidation of previously learned material');
        break;
      default:
        reasons.add('This timing balances cognitive load with your natural alertness patterns');
        break;
    }
    
    // Persona-specific reasoning
    if (persona != null) {
      switch (persona.type) {
        case PersonaType.scholar:
          reasons.add('Your scholarly approach benefits from extended, focused study periods');
          break;
        case PersonaType.coach:
          reasons.add('This schedule maximizes your goal-oriented learning style');
          break;
        default:
          break;
      }
    }
    
    return reasons.isNotEmpty 
        ? '${reasons.join('. ')}.'
        : 'This schedule is optimized based on your personal learning patterns.';
  }

  // Helper methods

  PerformancePattern _getDefaultPerformancePattern() {
    // Return research-based default patterns for new users
    return PerformancePattern(
      bestTimeOfDay: TimeOfDay.morning,
      bestDayOfWeek: DayOfWeek.tuesday,
      optimalSessionLength: const Duration(minutes: 25),
      timePerformanceMap: {
        TimeOfDay.earlyMorning: 0.7,
        TimeOfDay.morning: 0.8,
        TimeOfDay.midday: 0.6,
        TimeOfDay.afternoon: 0.5,
        TimeOfDay.evening: 0.6,
        TimeOfDay.night: 0.4,
        TimeOfDay.lateNight: 0.3,
      },
      dayPerformanceMap: {
        DayOfWeek.monday: 0.6,
        DayOfWeek.tuesday: 0.8,
        DayOfWeek.wednesday: 0.7,
        DayOfWeek.thursday: 0.7,
        DayOfWeek.friday: 0.5,
        DayOfWeek.saturday: 0.6,
        DayOfWeek.sunday: 0.5,
      },
      difficultyTimePreferences: {
        StudyDifficulty.hard: TimeOfDay.morning,
        StudyDifficulty.medium: TimeOfDay.afternoon,
        StudyDifficulty.easy: TimeOfDay.evening,
        StudyDifficulty.review: TimeOfDay.evening,
      },
      optimalEmotionalStates: [
        EmotionalState.confident,
        EmotionalState.excited,
        EmotionalState.neutral,
      ],
    );
  }

  void _updateLearningPatterns() {
    // This would trigger ML model updates in a real implementation
    // For now, it's a placeholder for pattern learning
  }

  StudySchedulePrediction? _generateDaySchedule({
    required DateTime date,
    required List<String> subjects,
    required PerformancePattern patterns,
    required CircadianAnalysis circadian,
    StudyPalPersona? persona,
  }) {
    if (subjects.isEmpty) return null;
    
    final optimalTime = _findOptimalTimeSlot(
      targetDate: date,
      patterns: patterns,
      circadian: circadian,
    );
    
    return StudySchedulePrediction(
      recommendedTime: optimalTime,
      estimatedDuration: _estimateOptimalDuration(
        timeOfDay: _getTimeOfDay(optimalTime.hour),
        difficulty: StudyDifficulty.medium,
        patterns: patterns,
        persona: persona,
      ),
      recommendedDifficulty: StudyDifficulty.medium,
      recommendedSubjects: subjects,
      confidenceScore: 0.7,
      reasoning: 'Optimized for your weekly learning schedule',
      optimizationFactors: {},
    );
  }

  List<String> _distributeSubjectsAcrossDays(Map<String, int> subjectHours, int dayIndex) {
    // Simplified distribution - would be more sophisticated in real implementation
    final subjects = subjectHours.keys.toList();
    final subjectsPerDay = (subjects.length / 7).ceil();
    final startIndex = dayIndex * subjectsPerDay;
    final endIndex = min(startIndex + subjectsPerDay, subjects.length);
    
    return subjects.sublist(startIndex, min(endIndex, subjects.length));
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final squaredDiffs = values.map((v) => pow(v - mean, 2));
    return squaredDiffs.reduce((a, b) => a + b) / values.length;
  }

  TimeOfDay _getTimeOfDay(int hour) {
    if (hour >= 5 && hour < 8) return TimeOfDay.earlyMorning;
    if (hour >= 8 && hour < 11) return TimeOfDay.morning;
    if (hour >= 11 && hour < 14) return TimeOfDay.midday;
    if (hour >= 14 && hour < 17) return TimeOfDay.afternoon;
    if (hour >= 17 && hour < 20) return TimeOfDay.evening;
    if (hour >= 20 && hour < 23) return TimeOfDay.night;
    return TimeOfDay.lateNight;
  }

  DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case DateTime.monday: return DayOfWeek.monday;
      case DateTime.tuesday: return DayOfWeek.tuesday;
      case DateTime.wednesday: return DayOfWeek.wednesday;
      case DateTime.thursday: return DayOfWeek.thursday;
      case DateTime.friday: return DayOfWeek.friday;
      case DateTime.saturday: return DayOfWeek.saturday;
      case DateTime.sunday: return DayOfWeek.sunday;
      default: return DayOfWeek.monday;
    }
  }

  String _timeOfDayToString(TimeOfDay timeOfDay) {
    switch (timeOfDay) {
      case TimeOfDay.earlyMorning: return 'early morning';
      case TimeOfDay.morning: return 'morning';
      case TimeOfDay.midday: return 'midday';
      case TimeOfDay.afternoon: return 'afternoon';
      case TimeOfDay.evening: return 'evening';
      case TimeOfDay.night: return 'night';
      case TimeOfDay.lateNight: return 'late night';
    }
  }

  String _dayOfWeekToString(DayOfWeek dayOfWeek) {
    switch (dayOfWeek) {
      case DayOfWeek.monday: return 'Monday';
      case DayOfWeek.tuesday: return 'Tuesday';
      case DayOfWeek.wednesday: return 'Wednesday';
      case DayOfWeek.thursday: return 'Thursday';
      case DayOfWeek.friday: return 'Friday';
      case DayOfWeek.saturday: return 'Saturday';
      case DayOfWeek.sunday: return 'Sunday';
    }
  }
}