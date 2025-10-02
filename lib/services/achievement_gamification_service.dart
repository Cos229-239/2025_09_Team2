import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Represents different types of achievements
enum AchievementType {
  streak,
  milestone,
  mastery,
  social,
  special,
  daily,
  weekly,
  monthly,
}

/// Represents achievement rarities
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// Represents different types of rewards
enum RewardType {
  xp,
  badge,
  title,
  avatar,
  theme,
  feature,
}

/// Represents an achievement that can be unlocked
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final AchievementType type;
  final AchievementRarity rarity;
  final int xpReward;
  final Map<String, dynamic> requirements;
  final List<Reward> rewards;
  final bool isHidden;
  final DateTime? dateCreated;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.xpReward,
    required this.requirements,
    List<Reward>? rewards,
    this.isHidden = false,
    this.dateCreated,
  }) : rewards = rewards ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'icon': icon,
        'type': type.name,
        'rarity': rarity.name,
        'xpReward': xpReward,
        'requirements': requirements,
        'rewards': rewards.map((r) => r.toJson()).toList(),
        'isHidden': isHidden,
        'dateCreated': dateCreated?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        icon: json['icon'],
        type: AchievementType.values.firstWhere((e) => e.name == json['type']),
        rarity: AchievementRarity.values
            .firstWhere((e) => e.name == json['rarity']),
        xpReward: json['xpReward'],
        requirements: Map<String, dynamic>.from(json['requirements']),
        rewards: (json['rewards'] as List?)
                ?.map((r) => Reward.fromJson(r))
                .toList() ??
            [],
        isHidden: json['isHidden'] ?? false,
        dateCreated: json['dateCreated'] != null
            ? DateTime.parse(json['dateCreated'])
            : null,
      );
}

/// Represents a reward that can be earned
class Reward {
  final String id;
  final String name;
  final String description;
  final RewardType type;
  final String value;
  final Map<String, dynamic> metadata;

  Reward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'type': type.name,
        'value': value,
        'metadata': metadata,
      };

  factory Reward.fromJson(Map<String, dynamic> json) => Reward(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        type: RewardType.values.firstWhere((e) => e.name == json['type']),
        value: json['value'],
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}

/// Represents a user's achievement progress
class AchievementProgress {
  final String achievementId;
  final double progress;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final Map<String, dynamic> progressData;

  AchievementProgress({
    required this.achievementId,
    required this.progress,
    this.isUnlocked = false,
    this.unlockedAt,
    Map<String, dynamic>? progressData,
  }) : progressData = progressData ?? {};

  AchievementProgress copyWith({
    double? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
    Map<String, dynamic>? progressData,
  }) {
    return AchievementProgress(
      achievementId: achievementId,
      progress: progress ?? this.progress,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      progressData: progressData ?? this.progressData,
    );
  }

  Map<String, dynamic> toJson() => {
        'achievementId': achievementId,
        'progress': progress,
        'isUnlocked': isUnlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
        'progressData': progressData,
      };

  factory AchievementProgress.fromJson(Map<String, dynamic> json) =>
      AchievementProgress(
        achievementId: json['achievementId'],
        progress: json['progress'].toDouble(),
        isUnlocked: json['isUnlocked'] ?? false,
        unlockedAt: json['unlockedAt'] != null
            ? DateTime.parse(json['unlockedAt'])
            : null,
        progressData: Map<String, dynamic>.from(json['progressData'] ?? {}),
      );
}

/// Represents user experience and level information
class UserLevel {
  final int level;
  final int currentXP;
  final int xpForNextLevel;
  final int totalXP;
  final String title;
  final List<String> unlockedFeatures;

  UserLevel({
    required this.level,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.totalXP,
    required this.title,
    List<String>? unlockedFeatures,
  }) : unlockedFeatures = unlockedFeatures ?? [];

  Map<String, dynamic> toJson() => {
        'level': level,
        'currentXP': currentXP,
        'xpForNextLevel': xpForNextLevel,
        'totalXP': totalXP,
        'title': title,
        'unlockedFeatures': unlockedFeatures,
      };

  factory UserLevel.fromJson(Map<String, dynamic> json) => UserLevel(
        level: json['level'],
        currentXP: json['currentXP'],
        xpForNextLevel: json['xpForNextLevel'],
        totalXP: json['totalXP'],
        title: json['title'],
        unlockedFeatures: List<String>.from(json['unlockedFeatures'] ?? []),
      );
}

/// Represents a streak counter
class Streak {
  final String type;
  final int current;
  final int longest;
  final DateTime? lastUpdate;
  final bool isActive;

  Streak({
    required this.type,
    required this.current,
    required this.longest,
    this.lastUpdate,
    this.isActive = true,
  });

  Streak copyWith({
    int? current,
    int? longest,
    DateTime? lastUpdate,
    bool? isActive,
  }) {
    return Streak(
      type: type,
      current: current ?? this.current,
      longest: longest ?? this.longest,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'current': current,
        'longest': longest,
        'lastUpdate': lastUpdate?.toIso8601String(),
        'isActive': isActive,
      };

  factory Streak.fromJson(Map<String, dynamic> json) => Streak(
        type: json['type'],
        current: json['current'],
        longest: json['longest'],
        lastUpdate: json['lastUpdate'] != null
            ? DateTime.parse(json['lastUpdate'])
            : null,
        isActive: json['isActive'] ?? true,
      );
}

/// Achievement and gamification service
/// TODO: CRITICAL ACHIEVEMENT GAMIFICATION SERVICE IMPLEMENTATION GAPS
/// - Current implementation uses only local SharedPreferences - NO CLOUD SYNC
/// - Need to implement full Firebase/Firestore integration for cross-device sync
/// - Missing real-time achievement tracking and progress updates
/// - Need to implement proper social achievement sharing and notifications
/// - Missing integration with actual study performance and learning analytics
/// - Need to implement dynamic achievement generation based on user behavior
/// - Missing proper reward redemption system and virtual economy
/// - Need to implement achievement leaderboards and social comparisons
/// - Missing integration with push notifications for achievement unlocks
/// - Need to implement seasonal and time-limited achievements
/// - Missing proper analytics tracking for gamification effectiveness
/// - Need to implement achievement difficulty balancing and A/B testing
/// - Missing integration with social features for achievement celebrations
/// - Need to implement proper fraud detection for achievement manipulation
/// - Missing accessibility features for achievement notifications and rewards
/// - Need to implement achievement import/export for account migration
/// - Missing integration with study streaks and habit formation psychology
/// - Need to implement proper achievement categorization and filtering
class AchievementGamificationService {
  static const String _progressKey = 'achievement_progress';
  static const String _levelKey = 'user_level';
  static const String _streaksKey = 'user_streaks';
  static const String _rewardsKey = 'earned_rewards';

  SharedPreferences? _prefs;
  Map<String, Achievement> _achievements = {};
  Map<String, AchievementProgress> _progress = {};
  UserLevel _userLevel = UserLevel(
      level: 1,
      currentXP: 0,
      xpForNextLevel: 100,
      totalXP: 0,
      title: 'Beginner');
  Map<String, Streak> _streaks = {};
  List<Reward> _earnedRewards = [];

  /// Initialize the service
  ///
  /// TODO: INITIALIZATION CRITICAL IMPROVEMENTS NEEDED
  /// - Current initialization only loads local data from SharedPreferences
  /// - Need to implement proper Firebase/Firestore initialization and data sync
  /// - Missing user authentication verification and data migration handling
  /// - Need to implement proper error handling for data corruption or conflicts
  /// - Missing integration with remote achievement definitions and updates
  /// - Need to implement proper offline/online state handling and data reconciliation
  /// - Missing initialization of real-time listeners for social achievement updates
  /// - Need to implement proper user onboarding flow for gamification features
  /// - Missing integration with analytics service for gamification tracking
  /// - Need to implement proper achievement definition versioning and updates
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadUserData();
    await _initializeDefaultAchievements();
  }

  /// Load user data from storage
  Future<void> _loadUserData() async {
    try {
      // Load achievement progress
      final progressData = _prefs?.getString(_progressKey);
      if (progressData != null) {
        final Map<String, dynamic> progressMap = jsonDecode(progressData);
        _progress = progressMap.map(
            (key, value) => MapEntry(key, AchievementProgress.fromJson(value)));
      }

      // Load user level
      final levelData = _prefs?.getString(_levelKey);
      if (levelData != null) {
        _userLevel = UserLevel.fromJson(jsonDecode(levelData));
      }

      // Load streaks
      final streaksData = _prefs?.getString(_streaksKey);
      if (streaksData != null) {
        final Map<String, dynamic> streaksMap = jsonDecode(streaksData);
        _streaks = streaksMap
            .map((key, value) => MapEntry(key, Streak.fromJson(value)));
      }

      // Load earned rewards
      final rewardsData = _prefs?.getString(_rewardsKey);
      if (rewardsData != null) {
        final List<dynamic> rewardsList = jsonDecode(rewardsData);
        _earnedRewards = rewardsList.map((r) => Reward.fromJson(r)).toList();
      }
    } catch (e) {
      debugPrint('Error loading achievement data: $e');
    }
  }

  /// Save user data to storage
  Future<void> _saveUserData() async {
    try {
      // Save achievement progress
      final progressMap =
          _progress.map((key, value) => MapEntry(key, value.toJson()));
      await _prefs?.setString(_progressKey, jsonEncode(progressMap));

      // Save user level
      await _prefs?.setString(_levelKey, jsonEncode(_userLevel.toJson()));

      // Save streaks
      final streaksMap =
          _streaks.map((key, value) => MapEntry(key, value.toJson()));
      await _prefs?.setString(_streaksKey, jsonEncode(streaksMap));

      // Save earned rewards
      final rewardsList = _earnedRewards.map((r) => r.toJson()).toList();
      await _prefs?.setString(_rewardsKey, jsonEncode(rewardsList));
    } catch (e) {
      debugPrint('Error saving achievement data: $e');
    }
  }

  /// Initialize default achievements
  Future<void> _initializeDefaultAchievements() async {
    _achievements = {
      // Streak Achievements
      'first_day': Achievement(
        id: 'first_day',
        name: 'Getting Started',
        description: 'Complete your first study session',
        icon: '🌟',
        type: AchievementType.milestone,
        rarity: AchievementRarity.common,
        xpReward: 50,
        requirements: {'sessions_completed': 1},
        rewards: [
          Reward(
              id: 'starter_badge',
              name: 'Starter Badge',
              description: 'First session completed',
              type: RewardType.badge,
              value: 'starter'),
        ],
      ),

      'week_warrior': Achievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Study for 7 consecutive days',
        icon: '🔥',
        type: AchievementType.streak,
        rarity: AchievementRarity.uncommon,
        xpReward: 200,
        requirements: {'daily_streak': 7},
        rewards: [
          Reward(
              id: 'fire_badge',
              name: 'Fire Badge',
              description: '7-day streak achieved',
              type: RewardType.badge,
              value: 'fire'),
        ],
      ),

      'month_master': Achievement(
        id: 'month_master',
        name: 'Month Master',
        description: 'Study for 30 consecutive days',
        icon: '👑',
        type: AchievementType.streak,
        rarity: AchievementRarity.epic,
        xpReward: 1000,
        requirements: {'daily_streak': 30},
        rewards: [
          Reward(
              id: 'crown_badge',
              name: 'Crown Badge',
              description: '30-day streak achieved',
              type: RewardType.badge,
              value: 'crown'),
          Reward(
              id: 'dedication_title',
              name: 'Dedication Title',
              description: 'The Dedicated',
              type: RewardType.title,
              value: 'The Dedicated'),
        ],
      ),

      // Mastery Achievements
      'quick_learner': Achievement(
        id: 'quick_learner',
        name: 'Quick Learner',
        description: 'Answer 10 questions correctly in under 5 seconds each',
        icon: '⚡',
        type: AchievementType.mastery,
        rarity: AchievementRarity.rare,
        xpReward: 300,
        requirements: {'quick_answers': 10, 'max_time': 5000},
      ),

      'perfectionist': Achievement(
        id: 'perfectionist',
        name: 'Perfectionist',
        description: 'Complete a study session with 100% accuracy',
        icon: '💎',
        type: AchievementType.mastery,
        rarity: AchievementRarity.rare,
        xpReward: 400,
        requirements: {'session_accuracy': 1.0},
        rewards: [
          Reward(
              id: 'diamond_badge',
              name: 'Diamond Badge',
              description: 'Perfect session completed',
              type: RewardType.badge,
              value: 'diamond'),
        ],
      ),

      'knowledge_master': Achievement(
        id: 'knowledge_master',
        name: 'Knowledge Master',
        description: 'Achieve 90% mastery in 5 different subjects',
        icon: '🧠',
        type: AchievementType.mastery,
        rarity: AchievementRarity.legendary,
        xpReward: 2000,
        requirements: {'subjects_mastered': 5, 'mastery_threshold': 0.9},
        rewards: [
          Reward(
              id: 'brain_badge',
              name: 'Brain Badge',
              description: 'Master of knowledge',
              type: RewardType.badge,
              value: 'brain'),
          Reward(
              id: 'scholar_title',
              name: 'Scholar Title',
              description: 'The Scholar',
              type: RewardType.title,
              value: 'The Scholar'),
        ],
      ),

      // Milestone Achievements
      'century_club': Achievement(
        id: 'century_club',
        name: 'Century Club',
        description: 'Complete 100 study sessions',
        icon: '💯',
        type: AchievementType.milestone,
        rarity: AchievementRarity.uncommon,
        xpReward: 500,
        requirements: {'total_sessions': 100},
      ),

      'thousand_strong': Achievement(
        id: 'thousand_strong',
        name: 'Thousand Strong',
        description: 'Answer 1000 questions correctly',
        icon: '🎯',
        type: AchievementType.milestone,
        rarity: AchievementRarity.rare,
        xpReward: 800,
        requirements: {'correct_answers': 1000},
      ),

      // Special Achievements
      'early_bird': Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Study before 8 AM for 5 consecutive days',
        icon: '🐦',
        type: AchievementType.special,
        rarity: AchievementRarity.uncommon,
        xpReward: 250,
        requirements: {'early_sessions': 5, 'before_hour': 8},
      ),

      'night_owl': Achievement(
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Study after 10 PM for 5 consecutive days',
        icon: '🦉',
        type: AchievementType.special,
        rarity: AchievementRarity.uncommon,
        xpReward: 250,
        requirements: {'late_sessions': 5, 'after_hour': 22},
      ),

      'social_butterfly': Achievement(
        id: 'social_butterfly',
        name: 'Social Butterfly',
        description: 'Study with friends 10 times',
        icon: '🦋',
        type: AchievementType.social,
        rarity: AchievementRarity.rare,
        xpReward: 600,
        requirements: {'social_sessions': 10},
      ),

      // Daily/Weekly Achievements
      'daily_dose': Achievement(
        id: 'daily_dose',
        name: 'Daily Dose',
        description: 'Study for at least 30 minutes today',
        icon: '📚',
        type: AchievementType.daily,
        rarity: AchievementRarity.common,
        xpReward: 25,
        requirements: {'daily_minutes': 30},
      ),

      'weekend_warrior': Achievement(
        id: 'weekend_warrior',
        name: 'Weekend Warrior',
        description: 'Study on both Saturday and Sunday',
        icon: '🛡️',
        type: AchievementType.weekly,
        rarity: AchievementRarity.uncommon,
        xpReward: 150,
        requirements: {'weekend_sessions': 2},
      ),
    };

    // Initialize progress for all achievements
    for (final achievement in _achievements.values) {
      if (!_progress.containsKey(achievement.id)) {
        _progress[achievement.id] = AchievementProgress(
          achievementId: achievement.id,
          progress: 0.0,
        );
      }
    }

    // Initialize default streaks
    if (_streaks.isEmpty) {
      _streaks = {
        'daily': Streak(type: 'daily', current: 0, longest: 0),
        'study': Streak(type: 'study', current: 0, longest: 0),
        'accuracy': Streak(type: 'accuracy', current: 0, longest: 0),
      };
    }

    await _saveUserData();
  }

  /// Record a study session and update achievements
  Future<List<Achievement>> recordStudySession({
    required int duration,
    required double accuracy,
    required int questionsAnswered,
    required int correctAnswers,
    required String subject,
    required DateTime sessionTime,
    List<int>? responseTimes,
    bool isSocialSession = false,
  }) async {
    final unlockedAchievements = <Achievement>[];

    // Update daily streak
    await _updateDailyStreak(sessionTime);

    // Award XP for the session
    final sessionXP =
        _calculateSessionXP(duration, accuracy, questionsAnswered);
    await _awardXP(sessionXP);

    // Check achievements
    final sessionData = {
      'duration': duration,
      'accuracy': accuracy,
      'questions_answered': questionsAnswered,
      'correct_answers': correctAnswers,
      'subject': subject,
      'session_time': sessionTime,
      'response_times': responseTimes ?? [],
      'is_social': isSocialSession,
    };

    unlockedAchievements.addAll(await _checkAchievements(sessionData));

    await _saveUserData();
    return unlockedAchievements;
  }

  /// Update daily streak
  Future<void> _updateDailyStreak(DateTime sessionTime) async {
    final today =
        DateTime(sessionTime.year, sessionTime.month, sessionTime.day);
    final dailyStreak = _streaks['daily']!;

    if (dailyStreak.lastUpdate == null) {
      // First session ever
      _streaks['daily'] = dailyStreak.copyWith(
        current: 1,
        longest: 1,
        lastUpdate: today,
        isActive: true,
      );
    } else {
      final lastUpdate = DateTime(
        dailyStreak.lastUpdate!.year,
        dailyStreak.lastUpdate!.month,
        dailyStreak.lastUpdate!.day,
      );

      final daysDiff = today.difference(lastUpdate).inDays;

      if (daysDiff == 0) {
        // Same day, no change needed
        return;
      } else if (daysDiff == 1) {
        // Consecutive day
        final newCurrent = dailyStreak.current + 1;
        _streaks['daily'] = dailyStreak.copyWith(
          current: newCurrent,
          longest: max(dailyStreak.longest, newCurrent),
          lastUpdate: today,
          isActive: true,
        );
      } else {
        // Streak broken
        _streaks['daily'] = dailyStreak.copyWith(
          current: 1,
          lastUpdate: today,
          isActive: true,
        );
      }
    }
  }

  /// Calculate XP for a study session
  int _calculateSessionXP(
      int duration, double accuracy, int questionsAnswered) {
    // Base XP from duration (1 XP per minute)
    int xp = duration;

    // Accuracy bonus (up to 50% bonus for perfect accuracy)
    xp += (xp * accuracy * 0.5).round();

    // Question completion bonus (2 XP per question)
    xp += questionsAnswered * 2;

    // Minimum XP
    return max(10, xp);
  }

  /// Award XP and check for level ups
  Future<bool> _awardXP(int xp) async {
    final newTotalXP = _userLevel.totalXP + xp;
    final newCurrentXP = _userLevel.currentXP + xp;

    // Check for level up
    if (newCurrentXP >= _userLevel.xpForNextLevel) {
      final newLevel = _userLevel.level + 1;
      final newXPForNext = _calculateXPForLevel(newLevel + 1);
      final remainingXP = newCurrentXP - _userLevel.xpForNextLevel;

      _userLevel = UserLevel(
        level: newLevel,
        currentXP: remainingXP,
        xpForNextLevel: newXPForNext,
        totalXP: newTotalXP,
        title: _getTitleForLevel(newLevel),
        unlockedFeatures: _getFeaturesForLevel(newLevel),
      );

      return true; // Leveled up
    } else {
      _userLevel = UserLevel(
        level: _userLevel.level,
        currentXP: newCurrentXP,
        xpForNextLevel: _userLevel.xpForNextLevel,
        totalXP: newTotalXP,
        title: _userLevel.title,
        unlockedFeatures: _userLevel.unlockedFeatures,
      );

      return false; // No level up
    }
  }

  /// Calculate XP required for a level
  int _calculateXPForLevel(int level) {
    return (100 * pow(1.5, level - 1)).round();
  }

  /// Get title for level
  String _getTitleForLevel(int level) {
    if (level >= 50) return 'Grandmaster';
    if (level >= 40) return 'Master';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Advanced';
    if (level >= 10) return 'Intermediate';
    if (level >= 5) return 'Novice';
    return 'Beginner';
  }

  /// Get unlocked features for level
  List<String> _getFeaturesForLevel(int level) {
    final features = <String>[];
    if (level >= 5) features.add('Custom Themes');
    if (level >= 10) features.add('Advanced Analytics');
    if (level >= 15) features.add('Study Groups');
    if (level >= 20) features.add('AI Tutor Premium');
    if (level >= 25) features.add('Custom Achievements');
    if (level >= 30) features.add('Leaderboards');
    return features;
  }

  /// Check achievements based on session data
  Future<List<Achievement>> _checkAchievements(
      Map<String, dynamic> sessionData) async {
    final unlockedAchievements = <Achievement>[];

    for (final achievement in _achievements.values) {
      final progress = _progress[achievement.id]!;

      if (progress.isUnlocked) continue;

      final newProgress =
          _calculateAchievementProgress(achievement, sessionData);
      final updatedProgress = progress.copyWith(progress: newProgress);

      if (newProgress >= 1.0 && !progress.isUnlocked) {
        // Achievement unlocked!
        _progress[achievement.id] = updatedProgress.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );

        // Award achievement rewards
        await _awardXP(achievement.xpReward);
        _earnedRewards.addAll(achievement.rewards);

        unlockedAchievements.add(achievement);
      } else {
        _progress[achievement.id] = updatedProgress;
      }
    }

    return unlockedAchievements;
  }

  /// Calculate progress for an achievement
  double _calculateAchievementProgress(
      Achievement achievement, Map<String, dynamic> sessionData) {
    switch (achievement.id) {
      case 'first_day':
        return 1.0; // Always unlocked on first session

      case 'week_warrior':
        return (_streaks['daily']?.current ?? 0) / 7.0;

      case 'month_master':
        return (_streaks['daily']?.current ?? 0) / 30.0;

      case 'quick_learner':
        final responseTimes = sessionData['response_times'] as List<int>? ?? [];
        final quickAnswers = responseTimes.where((time) => time <= 5000).length;
        final currentProgress =
            _progress[achievement.id]?.progressData['quick_answers'] ?? 0;
        final newQuickAnswers = currentProgress + quickAnswers;
        _progress[achievement.id]?.progressData['quick_answers'] =
            newQuickAnswers;
        return newQuickAnswers / 10.0;

      case 'perfectionist':
        return sessionData['accuracy'] as double;

      case 'daily_dose':
        final duration = sessionData['duration'] as int;
        return duration / 30.0; // 30 minutes required

      case 'century_club':
        final currentSessions =
            _progress[achievement.id]?.progressData['sessions'] ?? 0;
        final newSessions = currentSessions + 1;
        _progress[achievement.id]?.progressData['sessions'] = newSessions;
        return newSessions / 100.0;

      case 'early_bird':
        final sessionTime = sessionData['session_time'] as DateTime;
        if (sessionTime.hour < 8) {
          final currentEarly =
              _progress[achievement.id]?.progressData['early_sessions'] ?? 0;
          final newEarly = currentEarly + 1;
          _progress[achievement.id]?.progressData['early_sessions'] = newEarly;
          return newEarly / 5.0;
        }
        return _progress[achievement.id]?.progress ?? 0.0;

      case 'social_butterfly':
        if (sessionData['is_social'] as bool) {
          final currentSocial =
              _progress[achievement.id]?.progressData['social_sessions'] ?? 0;
          final newSocial = currentSocial + 1;
          _progress[achievement.id]?.progressData['social_sessions'] =
              newSocial;
          return newSocial / 10.0;
        }
        return _progress[achievement.id]?.progress ?? 0.0;

      default:
        return _progress[achievement.id]?.progress ?? 0.0;
    }
  }

  /// Get user's current level information
  UserLevel get userLevel => _userLevel;

  /// Get all achievements
  List<Achievement> get allAchievements => _achievements.values.toList();

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return _achievements.values
        .where((achievement) => _progress[achievement.id]?.isUnlocked ?? false)
        .toList();
  }

  /// Get achievement progress
  AchievementProgress? getAchievementProgress(String achievementId) {
    return _progress[achievementId];
  }

  /// Get current streaks
  Map<String, Streak> get currentStreaks => Map.from(_streaks);

  /// Get earned rewards
  List<Reward> get earnedRewards => List.from(_earnedRewards);

  /// Get gamification statistics
  Map<String, dynamic> getGamificationStats() {
    final totalAchievements = _achievements.length;
    final unlockedCount = unlockedAchievements.length;
    final totalXPFromAchievements = unlockedAchievements
        .map((a) => a.xpReward)
        .fold(0, (sum, xp) => sum + xp);

    return {
      'level': _userLevel.level,
      'totalXP': _userLevel.totalXP,
      'currentXP': _userLevel.currentXP,
      'xpForNextLevel': _userLevel.xpForNextLevel,
      'title': _userLevel.title,
      'achievementsUnlocked': unlockedCount,
      'totalAchievements': totalAchievements,
      'achievementProgress': unlockedCount / totalAchievements,
      'longestDailyStreak': _streaks['daily']?.longest ?? 0,
      'currentDailyStreak': _streaks['daily']?.current ?? 0,
      'totalRewards': _earnedRewards.length,
      'xpFromAchievements': totalXPFromAchievements,
    };
  }

  /// Get leaderboard data (for user's own progress)
  Map<String, dynamic> getLeaderboardData() {
    return {
      'level': _userLevel.level,
      'totalXP': _userLevel.totalXP,
      'achievements': unlockedAchievements.length,
      'longestStreak': _streaks['daily']?.longest ?? 0,
      'title': _userLevel.title,
    };
  }

  /// Reset daily achievements (should be called daily)
  Future<void> resetDailyAchievements() async {
    for (final achievement in _achievements.values) {
      if (achievement.type == AchievementType.daily) {
        _progress[achievement.id] = AchievementProgress(
          achievementId: achievement.id,
          progress: 0.0,
        );
      }
    }
    await _saveUserData();
  }

  /// Reset weekly achievements (should be called weekly)
  Future<void> resetWeeklyAchievements() async {
    for (final achievement in _achievements.values) {
      if (achievement.type == AchievementType.weekly) {
        _progress[achievement.id] = AchievementProgress(
          achievementId: achievement.id,
          progress: 0.0,
        );
      }
    }
    await _saveUserData();
  }
}
