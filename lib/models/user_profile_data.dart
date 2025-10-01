// user_profile_data.dart
// Model for persistent user profile storage (opt-in)

import 'package:cloud_firestore/cloud_firestore.dart';

/// Learning style preferences detected from user interactions
class LearningStylePreferences {
  final double visual;        // 0.0 to 1.0
  final double auditory;      // 0.0 to 1.0
  final double kinesthetic;   // 0.0 to 1.0
  final double reading;       // 0.0 to 1.0
  final String preferredDepth; // 'brief' or 'detailed'
  
  LearningStylePreferences({
    this.visual = 0.5,
    this.auditory = 0.5,
    this.kinesthetic = 0.5,
    this.reading = 0.5,
    this.preferredDepth = 'medium',
  });

  Map<String, dynamic> toJson() => {
    'visual': visual,
    'auditory': auditory,
    'kinesthetic': kinesthetic,
    'reading': reading,
    'preferredDepth': preferredDepth,
  };

  factory LearningStylePreferences.fromJson(Map<String, dynamic> json) {
    return LearningStylePreferences(
      visual: (json['visual'] as num?)?.toDouble() ?? 0.5,
      auditory: (json['auditory'] as num?)?.toDouble() ?? 0.5,
      kinesthetic: (json['kinesthetic'] as num?)?.toDouble() ?? 0.5,
      reading: (json['reading'] as num?)?.toDouble() ?? 0.5,
      preferredDepth: json['preferredDepth'] as String? ?? 'medium',
    );
  }

  /// Get dominant learning style
  String getDominantStyle() {
    final styles = {
      'visual': visual,
      'auditory': auditory,
      'kinesthetic': kinesthetic,
      'reading': reading,
    };
    return styles.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

/// Skill mastery scores by subject
class SkillScores {
  final Map<String, double> subjectMastery; // subject -> 0.0 to 1.0
  final Map<String, int> topicAttempts;     // topic -> count
  final Map<String, double> conceptConfidence; // concept -> 0.0 to 1.0
  
  SkillScores({
    Map<String, double>? subjectMastery,
    Map<String, int>? topicAttempts,
    Map<String, double>? conceptConfidence,
  })  : subjectMastery = subjectMastery ?? {},
        topicAttempts = topicAttempts ?? {},
        conceptConfidence = conceptConfidence ?? {};

  Map<String, dynamic> toJson() => {
    'subjectMastery': subjectMastery,
    'topicAttempts': topicAttempts,
    'conceptConfidence': conceptConfidence,
  };

  factory SkillScores.fromJson(Map<String, dynamic> json) {
    return SkillScores(
      subjectMastery: (json['subjectMastery'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
      topicAttempts: (json['topicAttempts'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, v as int)),
      conceptConfidence: (json['conceptConfidence'] as Map<String, dynamic>?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}

/// Privacy and feature opt-in flags
class OptInFlags {
  final bool profileStorage;      // Allow persistent profile
  final bool learningAnalytics;   // Track learning patterns
  final bool personalization;     // Use data for personalization
  final bool semanticMemory;      // Store conversation embeddings
  
  OptInFlags({
    this.profileStorage = false,
    this.learningAnalytics = false,
    this.personalization = false,
    this.semanticMemory = false,
  });

  Map<String, dynamic> toJson() => {
    'profileStorage': profileStorage,
    'learningAnalytics': learningAnalytics,
    'personalization': personalization,
    'semanticMemory': semanticMemory,
  };

  factory OptInFlags.fromJson(Map<String, dynamic> json) {
    return OptInFlags(
      profileStorage: json['profileStorage'] as bool? ?? false,
      learningAnalytics: json['learningAnalytics'] as bool? ?? false,
      personalization: json['personalization'] as bool? ?? false,
      semanticMemory: json['semanticMemory'] as bool? ?? false,
    );
  }

  bool get anyEnabled => 
      profileStorage || learningAnalytics || personalization || semanticMemory;
}

/// Complete user profile for AI tutor personalization
class UserProfileData {
  final String userId;
  final String? displayName;
  final LearningStylePreferences learningPreferences;
  final SkillScores skillScores;
  final DateTime lastSeen;
  final OptInFlags optInFlags;
  final Map<String, dynamic> metadata; // Extensible for future features
  
  UserProfileData({
    required this.userId,
    this.displayName,
    LearningStylePreferences? learningPreferences,
    SkillScores? skillScores,
    DateTime? lastSeen,
    OptInFlags? optInFlags,
    Map<String, dynamic>? metadata,
  })  : learningPreferences = learningPreferences ?? LearningStylePreferences(),
        skillScores = skillScores ?? SkillScores(),
        lastSeen = lastSeen ?? DateTime.now(),
        optInFlags = optInFlags ?? OptInFlags(),
        metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'displayName': displayName,
    'learningPreferences': learningPreferences.toJson(),
    'skillScores': skillScores.toJson(),
    'lastSeen': Timestamp.fromDate(lastSeen),
    'optInFlags': optInFlags.toJson(),
    'metadata': metadata,
  };

  factory UserProfileData.fromJson(Map<String, dynamic> json) {
    return UserProfileData(
      userId: json['userId'] as String,
      displayName: json['displayName'] as String?,
      learningPreferences: json['learningPreferences'] != null
          ? LearningStylePreferences.fromJson(
              json['learningPreferences'] as Map<String, dynamic>)
          : null,
      skillScores: json['skillScores'] != null
          ? SkillScores.fromJson(json['skillScores'] as Map<String, dynamic>)
          : null,
      lastSeen: (json['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      optInFlags: json['optInFlags'] != null
          ? OptInFlags.fromJson(json['optInFlags'] as Map<String, dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Create a copy with updated fields
  UserProfileData copyWith({
    String? displayName,
    LearningStylePreferences? learningPreferences,
    SkillScores? skillScores,
    DateTime? lastSeen,
    OptInFlags? optInFlags,
    Map<String, dynamic>? metadata,
  }) {
    return UserProfileData(
      userId: userId,
      displayName: displayName ?? this.displayName,
      learningPreferences: learningPreferences ?? this.learningPreferences,
      skillScores: skillScores ?? this.skillScores,
      lastSeen: lastSeen ?? this.lastSeen,
      optInFlags: optInFlags ?? this.optInFlags,
      metadata: metadata ?? this.metadata,
    );
  }
}
