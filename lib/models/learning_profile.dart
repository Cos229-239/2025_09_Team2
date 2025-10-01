/// User learning profile with adaptive metrics
class LearningProfile {
  final String userId;
  final Map<String, double> subjectMastery; // Subject -> Mastery level (0-1)
  final Map<String, int> conceptAttempts; // Concept ID -> Number of attempts
  final Map<String, double> conceptMastery; // Concept ID -> Mastery level
  final List<String> completedConcepts;
  final List<String> strugglingConcepts;
  final int totalPoints;
  final int currentStreak;
  final DateTime lastActivity;
  final List<String> unlockedBadges;
  final Map<String, dynamic> preferences;

  LearningProfile({
    required this.userId,
    Map<String, double>? subjectMastery,
    Map<String, int>? conceptAttempts,
    Map<String, double>? conceptMastery,
    List<String>? completedConcepts,
    List<String>? strugglingConcepts,
    this.totalPoints = 0,
    this.currentStreak = 0,
    DateTime? lastActivity,
    List<String>? unlockedBadges,
    Map<String, dynamic>? preferences,
  })  : subjectMastery = subjectMastery ?? {},
        conceptAttempts = conceptAttempts ?? {},
        conceptMastery = conceptMastery ?? {},
        completedConcepts = completedConcepts ?? [],
        strugglingConcepts = strugglingConcepts ?? [],
        lastActivity = lastActivity ?? DateTime.now(),
        unlockedBadges = unlockedBadges ?? [],
        preferences = preferences ?? {};

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'userId': userId,
    'subjectMastery': subjectMastery,
    'conceptAttempts': conceptAttempts,
    'conceptMastery': conceptMastery,
    'completedConcepts': completedConcepts,
    'strugglingConcepts': strugglingConcepts,
    'totalPoints': totalPoints,
    'currentStreak': currentStreak,
    'lastActivity': lastActivity.toIso8601String(),
    'unlockedBadges': unlockedBadges,
    'preferences': preferences,
  };

  /// Create from JSON
  factory LearningProfile.fromJson(Map<String, dynamic> json) {
    return LearningProfile(
      userId: json['userId'] as String,
      subjectMastery: (json['subjectMastery'] as Map<String, dynamic>?)?.cast<String, double>(),
      conceptAttempts: (json['conceptAttempts'] as Map<String, dynamic>?)?.cast<String, int>(),
      conceptMastery: (json['conceptMastery'] as Map<String, dynamic>?)?.cast<String, double>(),
      completedConcepts: (json['completedConcepts'] as List?)?.cast<String>(),
      strugglingConcepts: (json['strugglingConcepts'] as List?)?.cast<String>(),
      totalPoints: json['totalPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      lastActivity: json['lastActivity'] != null 
        ? DateTime.parse(json['lastActivity'] as String)
        : DateTime.now(),
      unlockedBadges: (json['unlockedBadges'] as List?)?.cast<String>(),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
}