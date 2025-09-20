/// Notification model representing system notifications for quizzes, tasks, and app events
/// Inspired by LinkedIn's notification system with priority, timestamps, and read status
class AppNotification {
  // Unique identifier for the notification
  final String id;

  // Title of the notification (brief summary)
  final String title;

  // Detailed message body
  final String message;

  // Type of notification for categorization and styling
  final NotificationType type;

  // Priority level affecting display order and styling
  final NotificationPriority priority;

  // Whether the notification has been read by the user
  final bool isRead;

  // Whether the notification requires immediate attention
  final bool isUrgent;

  // Timestamp when notification was created
  final DateTime createdAt;

  // Optional timestamp for when notification becomes relevant
  final DateTime? scheduledFor;

  // Optional expiration time for temporary notifications
  final DateTime? expiresAt;

  // Optional action data (navigation routes, parameters)
  final NotificationAction? action;

  // Optional metadata for additional context
  final Map<String, dynamic>? metadata;

  /// Constructor for creating an AppNotification instance
  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.isUrgent = false,
    required this.createdAt,
    this.scheduledFor,
    this.expiresAt,
    this.action,
    this.metadata,
  });

  /// Create a copy of this notification with updated fields
  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    bool? isRead,
    bool? isUrgent,
    DateTime? createdAt,
    DateTime? scheduledFor,
    DateTime? expiresAt,
    NotificationAction? action,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      isRead: isRead ?? this.isRead,
      isUrgent: isUrgent ?? this.isUrgent,
      createdAt: createdAt ?? this.createdAt,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      expiresAt: expiresAt ?? this.expiresAt,
      action: action ?? this.action,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert notification to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'priority': priority.name,
      'isRead': isRead,
      'isUrgent': isUrgent,
      'createdAt': createdAt.toIso8601String(),
      'scheduledFor': scheduledFor?.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'action': action?.toJson(),
      'metadata': metadata,
    };
  }

  /// Create notification from JSON data
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      priority: NotificationPriority.values.firstWhere(
        (e) => e.name == json['priority'],
      ),
      isRead: json['isRead'] ?? false,
      isUrgent: json['isUrgent'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'])
          : null,
      expiresAt:
          json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
      action: json['action'] != null
          ? NotificationAction.fromJson(json['action'])
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Check if notification is currently expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if notification is scheduled for the future
  bool get isScheduled {
    if (scheduledFor == null) return false;
    return DateTime.now().isBefore(scheduledFor!);
  }

  /// Check if notification should be displayed now
  bool get shouldDisplay {
    if (isExpired) return false;
    if (isScheduled) return false;
    return true;
  }

  /// Get time ago string for display (LinkedIn-style)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 7) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  // Factory constructors for common notification types

  /// Create a quiz expiring soon notification
  factory AppNotification.quizExpiring({
    required String questId,
    required String questTitle,
    required Duration timeRemaining,
  }) {
    final hoursLeft = timeRemaining.inHours;
    final minutesLeft = timeRemaining.inMinutes % 60;

    String timeText;
    if (hoursLeft > 0) {
      timeText = '$hoursLeft hour${hoursLeft != 1 ? 's' : ''}';
      if (minutesLeft > 0) {
        timeText += ' and $minutesLeft minute${minutesLeft != 1 ? 's' : ''}';
      }
    } else {
      timeText = '$minutesLeft minute${minutesLeft != 1 ? 's' : ''}';
    }

    return AppNotification(
      id: 'quiz_expiring_$questId',
      title: 'Quiz Expiring Soon',
      message: '"$questTitle" expires in $timeText',
      type: NotificationType.quizExpiring,
      priority: NotificationPriority.high,
      isUrgent: timeRemaining.inHours < 2,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(timeRemaining),
      action: NotificationAction(
        type: ActionType.navigate,
        route: '/today-activities',
        parameters: {'questId': questId},
      ),
      metadata: {
        'questId': questId,
        'timeRemaining': timeRemaining.inMinutes,
      },
    );
  }

  /// Create a quiz available notification
  factory AppNotification.quizAvailable({
    required String questId,
    required String questTitle,
    required int expReward,
  }) {
    return AppNotification(
      id: 'quiz_available_$questId',
      title: 'New Quiz Available',
      message: '"$questTitle" is ready to complete (+$expReward EXP)',
      type: NotificationType.quizAvailable,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      action: NotificationAction(
        type: ActionType.navigate,
        route: '/today-activities',
        parameters: {'questId': questId},
      ),
      metadata: {
        'questId': questId,
        'expReward': expReward,
      },
    );
  }

  /// Create a spaced repetition review notification
  factory AppNotification.reviewDue({
    required int cardCount,
    required String deckName,
  }) {
    return AppNotification(
      id: 'review_due_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Cards Ready for Review',
      message:
          '$cardCount card${cardCount != 1 ? 's' : ''} from "$deckName" ${cardCount != 1 ? 'are' : 'is'} ready for review',
      type: NotificationType.reviewDue,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      action: NotificationAction(
        type: ActionType.navigate,
        route: '/flashcard-study',
        parameters: {'deckName': deckName},
      ),
      metadata: {
        'cardCount': cardCount,
        'deckName': deckName,
      },
    );
  }

  /// Create a streak reminder notification
  factory AppNotification.streakReminder({
    required int currentStreak,
  }) {
    return AppNotification(
      id: 'streak_reminder_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Don\'t Break Your Streak!',
      message: 'You have a $currentStreak-day study streak. Keep it going!',
      type: NotificationType.streakReminder,
      priority: NotificationPriority.normal,
      isUrgent: true,
      createdAt: DateTime.now(),
      action: NotificationAction(
        type: ActionType.navigate,
        route: '/today-activities',
      ),
      metadata: {
        'currentStreak': currentStreak,
      },
    );
  }

  /// Create a daily goal completion notification
  factory AppNotification.dailyGoalCompleted({
    required int questsCompleted,
    required int totalExp,
  }) {
    return AppNotification(
      id: 'daily_goal_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Daily Goal Achieved! 🎉',
      message:
          'You completed $questsCompleted quest${questsCompleted != 1 ? 's' : ''} and earned $totalExp EXP today!',
      type: NotificationType.achievement,
      priority: NotificationPriority.normal,
      createdAt: DateTime.now(),
      action: NotificationAction(
        type: ActionType.navigate,
        route: '/today-activities',
      ),
      metadata: {
        'questsCompleted': questsCompleted,
        'totalExp': totalExp,
      },
    );
  }
}

/// Action data for notification interactions
class NotificationAction {
  final ActionType type;
  final String? route;
  final Map<String, dynamic>? parameters;
  final String? url;

  NotificationAction({
    required this.type,
    this.route,
    this.parameters,
    this.url,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'route': route,
      'parameters': parameters,
      'url': url,
    };
  }

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      type: ActionType.values.firstWhere((e) => e.name == json['type']),
      route: json['route'],
      parameters: json['parameters'] as Map<String, dynamic>?,
      url: json['url'],
    );
  }
}

/// Types of notifications in the system
enum NotificationType {
  quizExpiring, // Quiz is about to expire
  quizAvailable, // New quiz is available
  reviewDue, // SRS cards need review
  streakReminder, // Daily streak maintenance reminder
  achievement, // Goal completed, milestone reached
  system, // System updates, announcements
  social, // Study group, sharing features
}

/// Priority levels for notification ordering and styling
enum NotificationPriority {
  low, // Gray styling, bottom of list
  normal, // Standard blue styling
  high, // Orange/yellow styling, higher in list
  critical, // Red styling, top of list
}

/// Types of actions notifications can trigger
enum ActionType {
  navigate, // Navigate to app screen
  url, // Open external URL
  dismiss, // Just dismiss notification
}

/// Extension to provide display properties for notification types
extension NotificationTypeExtension on NotificationType {
  String get displayName {
    switch (this) {
      case NotificationType.quizExpiring:
        return 'Quiz Expiring';
      case NotificationType.quizAvailable:
        return 'Quiz Available';
      case NotificationType.reviewDue:
        return 'Review Due';
      case NotificationType.streakReminder:
        return 'Streak Reminder';
      case NotificationType.achievement:
        return 'Achievement';
      case NotificationType.system:
        return 'System';
      case NotificationType.social:
        return 'Social';
    }
  }

  String get icon {
    switch (this) {
      case NotificationType.quizExpiring:
        return '⏰';
      case NotificationType.quizAvailable:
        return '🧠';
      case NotificationType.reviewDue:
        return '🔄';
      case NotificationType.streakReminder:
        return '🔥';
      case NotificationType.achievement:
        return '🎉';
      case NotificationType.system:
        return 'ℹ️';
      case NotificationType.social:
        return '👥';
    }
  }
}

/// Extension to provide display properties for notification priorities
extension NotificationPriorityExtension on NotificationPriority {
  String get displayName {
    switch (this) {
      case NotificationPriority.low:
        return 'Low';
      case NotificationPriority.normal:
        return 'Normal';
      case NotificationPriority.high:
        return 'High';
      case NotificationPriority.critical:
        return 'Critical';
    }
  }
}
