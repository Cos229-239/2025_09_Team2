/// Daily Quest model representing gamified daily tasks for users
/// These are automatically generated tasks that reset daily and provide rewards
class DailyQuest {
  // Unique identifier for the quest
  final String id;
  // Title/description of the quest
  final String title;
  // Detailed description of what needs to be done
  final String description;
  // Type of quest (study, quiz, streak, etc.)
  final QuestType type;
  // Target amount to complete (e.g., 5 cards, 3 quizzes)
  final int targetCount;
  // Current progress towards the target
  final int currentProgress;
  // EXP reward for completing the quest
  final int expReward;
  // Date this quest was created/assigned
  final DateTime createdAt;
  // Date this quest expires (typically end of day)
  final DateTime expiresAt;
  // Whether the quest has been completed
  final bool isCompleted;
  // Priority level for display order (1 = low, 3 = high)
  final int priority;

  /// Constructor for creating a DailyQuest instance
  DailyQuest({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    this.currentProgress = 0,
    required this.expReward,
    required this.createdAt,
    required this.expiresAt,
    this.isCompleted = false,
    this.priority = 2,
  });

  /// Calculated property: progress as percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (currentProgress / targetCount).clamp(0.0, 1.0);
  }

  /// Calculated property: whether the quest is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Calculated property: whether the quest can be completed
  bool get canComplete {
    return currentProgress >= targetCount && !isCompleted && !isExpired;
  }

  /// Calculated property: progress display text
  String get progressText {
    return '$currentProgress/$targetCount';
  }

  /// Converts DailyQuest object to JSON map for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.toString(),
        'targetCount': targetCount,
        'currentProgress': currentProgress,
        'expReward': expReward,
        'createdAt': createdAt.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
        'isCompleted': isCompleted,
        'priority': priority,
      };

  /// Creates DailyQuest object from JSON map
  factory DailyQuest.fromJson(Map<String, dynamic> json) => DailyQuest(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        type: QuestType.values.firstWhere(
          (e) => e.toString() == json['type'],
          orElse: () => QuestType.study,
        ),
        targetCount: json['targetCount'] as int,
        currentProgress: (json['currentProgress'] as int?) ?? 0,
        expReward: json['expReward'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        isCompleted: (json['isCompleted'] as bool?) ?? false,
        priority: (json['priority'] as int?) ?? 2,
      );

  /// Creates a copy of this DailyQuest with optionally modified fields
  DailyQuest copyWith({
    String? id,
    String? title,
    String? description,
    QuestType? type,
    int? targetCount,
    int? currentProgress,
    int? expReward,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? isCompleted,
    int? priority,
  }) {
    return DailyQuest(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentProgress: currentProgress ?? this.currentProgress,
      expReward: expReward ?? this.expReward,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }

  /// Factory method to create common quest types
  factory DailyQuest.studyCards({
    required String id,
    int targetCards = 10,
    int expReward = 50,
  }) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return DailyQuest(
      id: id,
      title: 'Study Master',
      description: 'Study $targetCards flashcards to improve your knowledge',
      type: QuestType.study,
      targetCount: targetCards,
      expReward: expReward,
      createdAt: now,
      expiresAt: endOfDay,
      priority: 2,
    );
  }

  factory DailyQuest.takeQuizzes({
    required String id,
    int targetQuizzes = 3,
    int expReward = 75,
  }) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return DailyQuest(
      id: id,
      title: 'Quiz Champion',
      description: 'Take $targetQuizzes quizzes to test your knowledge',
      type: QuestType.quiz,
      targetCount: targetQuizzes,
      expReward: expReward,
      createdAt: now,
      expiresAt: endOfDay,
      priority: 3,
    );
  }

  factory DailyQuest.maintainStreak({
    required String id,
    int expReward = 100,
  }) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return DailyQuest(
      id: id,
      title: 'Streak Keeper',
      description: 'Study today to maintain your learning streak',
      type: QuestType.streak,
      targetCount: 1,
      expReward: expReward,
      createdAt: now,
      expiresAt: endOfDay,
      priority: 1,
    );
  }

  factory DailyQuest.perfectScore({
    required String id,
    int expReward = 150,
  }) {
    final now = DateTime.now();
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    
    return DailyQuest(
      id: id,
      title: 'Perfect Scholar',
      description: 'Get a perfect score on any quiz today',
      type: QuestType.perfectScore,
      targetCount: 1,
      expReward: expReward,
      createdAt: now,
      expiresAt: endOfDay,
      priority: 3,
    );
  }
}

/// Enumeration of daily quest types
enum QuestType {
  study, // Study a certain number of cards
  quiz, // Take a certain number of quizzes
  streak, // Maintain study streak
  perfectScore, // Get perfect score on quiz
  timeSpent, // Spend certain amount of time studying
  newCards, // Study new cards
  review, // Review old cards
}

/// Extension to provide display properties for quest types
extension QuestTypeExtension on QuestType {
  String get displayName {
    switch (this) {
      case QuestType.study:
        return 'Study';
      case QuestType.quiz:
        return 'Quiz';
      case QuestType.streak:
        return 'Streak';
      case QuestType.perfectScore:
        return 'Perfect Score';
      case QuestType.timeSpent:
        return 'Time Spent';
      case QuestType.newCards:
        return 'New Cards';
      case QuestType.review:
        return 'Review';
    }
  }

  String get icon {
    switch (this) {
      case QuestType.study:
        return '📚';
      case QuestType.quiz:
        return '🧠';
      case QuestType.streak:
        return '🔥';
      case QuestType.perfectScore:
        return '⭐';
      case QuestType.timeSpent:
        return '⏰';
      case QuestType.newCards:
        return '✨';
      case QuestType.review:
        return '🔄';
    }
  }
}