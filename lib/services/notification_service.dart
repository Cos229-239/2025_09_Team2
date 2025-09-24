import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification.dart';
import '../models/daily_quest.dart';

/// Service for managing app notifications with quiz expiration and review scheduling
/// Integrates with quest system and SRS to generate timely notifications
/// 
/// TODO: CRITICAL NOTIFICATION SERVICE IMPLEMENTATION GAPS
/// - Current implementation is LOCAL ONLY - NO PUSH NOTIFICATIONS OR FCM INTEGRATION
/// - Need to implement Firebase Cloud Messaging (FCM) for real push notifications
/// - Missing proper notification scheduling with Android/iOS native schedulers
/// - Need to implement notification channels and categories for better organization
/// - Missing integration with device notification settings and permissions
/// - Need to implement proper background task scheduling for notification generation
/// - Missing notification analytics and delivery tracking
/// - Need to implement notification personalization based on user behavior
/// - Missing notification throttling and rate limiting to prevent spam
/// - Need to implement proper notification localization and time zone handling  
/// - Missing integration with user presence and do-not-disturb modes
/// - Need to implement notification grouping and bundling for better UX
/// - Missing notification action buttons and deep linking
/// - Need to implement proper notification sound and vibration patterns
/// - Missing notification delivery confirmation and retry mechanisms
/// - Need to implement notification A/B testing for effectiveness optimization
/// - Missing integration with cross-platform notification synchronization
/// - Need to implement notification template system for consistent messaging
class NotificationService {
  static const String _notificationsKey = 'app_notifications';
  static const String _lastNotificationCheckKey = 'last_notification_check';
  static const String _notificationSettingsKey = 'notification_settings';

  /// Get all stored notifications
  Future<List<AppNotification>> getAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList(_notificationsKey) ?? [];

      final notifications = notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .where((n) => !n.isExpired) // Filter out expired notifications
          .toList();

      // Sort by creation time (newest first)
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return notifications;
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      return [];
    }
  }

  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    try {
      final notifications = await getAllNotifications();

      // Check for duplicate notifications
      final exists = notifications.any((n) => n.id == notification.id);
      if (exists) {
        debugPrint('Notification already exists: ${notification.id}');
        return;
      }

      notifications.insert(0, notification);
      await saveNotifications(notifications);

      debugPrint('Added notification: ${notification.title}');
    } catch (e) {
      debugPrint('Error adding notification: $e');
      rethrow;
    }
  }

  /// Save notifications to storage
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson =
          notifications.map((n) => jsonEncode(n.toJson())).toList();

      await prefs.setStringList(_notificationsKey, notificationsJson);
    } catch (e) {
      debugPrint('Error saving notifications: $e');
      rethrow;
    }
  }

  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      final index = notifications.indexWhere((n) => n.id == notificationId);

      if (index != -1) {
        notifications[index] = notifications[index].copyWith(isRead: true);
        await saveNotifications(notifications);
        debugPrint('Marked notification as read: $notificationId');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final notifications = await getAllNotifications();
      final updatedNotifications =
          notifications.map((n) => n.copyWith(isRead: true)).toList();

      await saveNotifications(updatedNotifications);
      debugPrint('Marked all notifications as read');
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final notifications = await getAllNotifications();
      notifications.removeWhere((n) => n.id == notificationId);
      await saveNotifications(notifications);
      debugPrint('Deleted notification: $notificationId');
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      rethrow;
    }
  }

  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
      debugPrint('Cleared all notifications');
    } catch (e) {
      debugPrint('Error clearing notifications: $e');
      rethrow;
    }
  }

  /// Generate quiz and review notifications based on current state
  Future<List<AppNotification>> generateQuizNotifications({
    required List<dynamic> quests,
    required List<dynamic> dueCards,
  }) async {
    final List<AppNotification> newNotifications = [];
    final now = DateTime.now();

    try {
      // Check for expiring quests
      for (final quest in quests) {
        if (quest is DailyQuest && !quest.isCompleted && !quest.isExpired) {
          final timeUntilExpiration = quest.expiresAt.difference(now);

          // Generate notifications for quests expiring in 2 hours or 30 minutes
          if (_shouldNotifyForExpiring(timeUntilExpiration)) {
            final notification = AppNotification.quizExpiring(
              questId: quest.id,
              questTitle: quest.title,
              timeRemaining: timeUntilExpiration,
            );
            newNotifications.add(notification);
          }
        }
      }

      // Check for new available quests
      for (final quest in quests) {
        if (quest is DailyQuest && !quest.isCompleted && !quest.isExpired) {
          final isNewToday = quest.createdAt.isAfter(
            DateTime(now.year, now.month, now.day),
          );

          if (isNewToday &&
              !(await _hasNotificationForQuest(quest.id, 'quiz_available'))) {
            final notification = AppNotification.quizAvailable(
              questId: quest.id,
              questTitle: quest.title,
              expReward: quest.expReward,
            );
            newNotifications.add(notification);
          }
        }
      }

      // Check for SRS review cards
      if (dueCards.isNotEmpty) {
        // Group cards by deck if possible
        final cardsByDeck = <String, int>{};
        for (final card in dueCards) {
          final deckName = card.deckName ?? 'Study Deck';
          cardsByDeck[deckName] = (cardsByDeck[deckName] ?? 0) + 1;
        }

        // Generate notifications for each deck with due cards
        for (final entry in cardsByDeck.entries) {
          if (!(await _hasNotificationForReview(entry.key))) {
            final notification = AppNotification.reviewDue(
              cardCount: entry.value,
              deckName: entry.key,
            );
            newNotifications.add(notification);
          }
        }
      }

      // Save generated notifications
      for (final notification in newNotifications) {
        await addNotification(notification);
      }

      return newNotifications;
    } catch (e) {
      debugPrint('Error generating quiz notifications: $e');
      return [];
    }
  }

  /// Check if we should notify for expiring quest
  bool _shouldNotifyForExpiring(Duration timeRemaining) {
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes;

    // Notify at 2 hours, 1 hour, and 30 minutes before expiration
    return (hours == 2 && minutes <= 120) ||
        (hours == 1 && minutes <= 60) ||
        (minutes == 30) ||
        (minutes == 15) ||
        (minutes == 5);
  }

  /// Check if we already have a notification for a specific quest
  Future<bool> _hasNotificationForQuest(String questId, String type) async {
    final notifications = await getAllNotifications();
    return notifications.any((n) =>
        n.id.startsWith('${type}_$questId') &&
        n.createdAt
            .isAfter(DateTime.now().subtract(const Duration(hours: 24))));
  }

  /// Check if we already have a review notification for a deck
  Future<bool> _hasNotificationForReview(String deckName) async {
    final notifications = await getAllNotifications();
    return notifications.any((n) =>
        n.type == NotificationType.reviewDue &&
        n.metadata?['deckName'] == deckName &&
        n.createdAt.isAfter(DateTime.now().subtract(const Duration(hours: 6))));
  }

  /// Generate streak-related notifications
  Future<void> generateStreakNotifications({
    required int currentStreak,
    required bool hasStudiedToday,
  }) async {
    try {
      final now = DateTime.now();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 0);
      final timeUntilEndOfDay = endOfDay.difference(now);

      // If user hasn't studied today and it's getting late, remind them
      if (!hasStudiedToday &&
          timeUntilEndOfDay.inHours <= 3 &&
          currentStreak > 0) {
        final notificationId =
            'streak_reminder_${now.year}_${now.month}_${now.day}';

        if (!(await _hasNotificationById(notificationId))) {
          final notification = AppNotification.streakReminder(
            currentStreak: currentStreak,
          );
          await addNotification(notification.copyWith(id: notificationId));
        }
      }
    } catch (e) {
      debugPrint('Error generating streak notifications: $e');
    }
  }

  /// Generate achievement notifications
  Future<void> generateAchievementNotifications({
    required int questsCompleted,
    required int totalExp,
    required bool isAllQuestsComplete,
  }) async {
    try {
      if (isAllQuestsComplete && questsCompleted > 0) {
        final now = DateTime.now();
        final notificationId = 'daily_goal_${now.year}_${now.month}_${now.day}';

        if (!(await _hasNotificationById(notificationId))) {
          final notification = AppNotification.dailyGoalCompleted(
            questsCompleted: questsCompleted,
            totalExp: totalExp,
          );
          await addNotification(notification.copyWith(id: notificationId));
        }
      }
    } catch (e) {
      debugPrint('Error generating achievement notifications: $e');
    }
  }

  /// Check if notification with specific ID exists
  Future<bool> _hasNotificationById(String notificationId) async {
    final notifications = await getAllNotifications();
    return notifications.any((n) => n.id == notificationId);
  }

  /// Schedule recurring notification checks (placeholder for background tasks)
  /// 
  /// TODO: BACKGROUND TASK SCHEDULING CRITICAL IMPROVEMENTS NEEDED
  /// - Current implementation is PLACEHOLDER ONLY - no actual background scheduling
  /// - Need to implement proper iOS/Android background task registration
  /// - Missing integration with WorkManager (Android) and Background App Refresh (iOS)
  /// - Need to implement proper notification scheduling with platform native APIs
  /// - Missing battery optimization handling and background execution limits
  /// - Need to implement proper background sync for notification data
  /// - Missing integration with system notification scheduling services
  /// - Need to implement proper wake-up alarms for critical notifications
  /// - Missing notification timing optimization based on user activity patterns
  /// - Need to implement proper error handling for background task failures
  Future<void> scheduleRecurringChecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _lastNotificationCheckKey, DateTime.now().toIso8601String());

      // In a real implementation, this would set up background tasks
      // For now, we'll rely on app lifecycle checks
      debugPrint('Scheduled recurring notification checks');
    } catch (e) {
      debugPrint('Error scheduling notification checks: $e');
      rethrow;
    }
  }

  /// Perform routine maintenance on notifications
  Future<void> performMaintenance() async {
    try {
      final notifications = await getAllNotifications();
      final now = DateTime.now();

      // Remove expired notifications
      final activeNotifications =
          notifications.where((n) => !n.isExpired).toList();

      // Remove old read notifications (older than 7 days)
      final recentNotifications = activeNotifications
          .where((n) =>
              !n.isRead ||
              n.createdAt.isAfter(now.subtract(const Duration(days: 7))))
          .toList();

      // Limit total notifications (keep latest 100)
      final limitedNotifications = recentNotifications.take(100).toList();

      if (limitedNotifications.length != notifications.length) {
        await saveNotifications(limitedNotifications);
        debugPrint(
            'Cleaned up ${notifications.length - limitedNotifications.length} old notifications');
      }
    } catch (e) {
      debugPrint('Error performing notification maintenance: $e');
    }
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_notificationSettingsKey);

      if (settingsJson == null) {
        // Default settings
        return {
          'quizExpiring': true,
          'quizAvailable': true,
          'reviewDue': true,
          'streakReminder': true,
          'achievements': true,
          'system': true,
        };
      }

      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      return settings.cast<String, bool>();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      return {
        'quizExpiring': true,
        'quizAvailable': true,
        'reviewDue': true,
        'streakReminder': true,
        'achievements': true,
        'system': true,
      };
    }
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationSettingsKey, jsonEncode(settings));
      debugPrint('Updated notification settings');
    } catch (e) {
      debugPrint('Error updating notification settings: $e');
      rethrow;
    }
  }

  /// Generate summary notification for end of day
  Future<void> generateDailySummary({
    required int questsCompleted,
    required int totalQuests,
    required int expEarned,
    required int cardsStudied,
  }) async {
    try {
      final now = DateTime.now();
      final notificationId =
          'daily_summary_${now.year}_${now.month}_${now.day}';

      if (!(await _hasNotificationById(notificationId)) &&
          questsCompleted > 0) {
        final completionRate = (questsCompleted / totalQuests * 100).round();

        final notification = AppNotification(
          id: notificationId,
          title: 'Daily Summary 📊',
          message:
              'Today: $questsCompleted/$totalQuests quests ($completionRate%), $expEarned EXP, $cardsStudied cards studied',
          type: NotificationType.achievement,
          priority: NotificationPriority.normal,
          createdAt: now,
          metadata: {
            'questsCompleted': questsCompleted,
            'totalQuests': totalQuests,
            'expEarned': expEarned,
            'cardsStudied': cardsStudied,
            'completionRate': completionRate,
          },
        );

        await addNotification(notification);
      }
    } catch (e) {
      debugPrint('Error generating daily summary: $e');
    }
  }
}
