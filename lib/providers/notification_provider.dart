import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

/// Provider for managing app notifications with LinkedIn-style functionality
/// Handles notification state, filtering, sorting, and user interactions
class NotificationProvider with ChangeNotifier {
  final NotificationService _notificationService = NotificationService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  
  // Filter settings
  NotificationType? _selectedFilter;
  bool _showUnreadOnly = false;
  
  /// Getters for accessing notification data
  List<AppNotification> get notifications => _getFilteredNotifications();
  List<AppNotification> get allNotifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  NotificationType? get selectedFilter => _selectedFilter;
  bool get showUnreadOnly => _showUnreadOnly;
  
  /// Computed properties for notification statistics
  int get unreadCount => _notifications.where((n) => !n.isRead && n.shouldDisplay).length;
  int get urgentCount => _notifications.where((n) => n.isUrgent && !n.isRead && n.shouldDisplay).length;
  int get totalCount => _notifications.where((n) => n.shouldDisplay).length;
  
  /// Get notifications grouped by type
  Map<NotificationType, List<AppNotification>> get notificationsByType {
    final Map<NotificationType, List<AppNotification>> grouped = {};
    
    for (final notification in _getFilteredNotifications()) {
      if (!grouped.containsKey(notification.type)) {
        grouped[notification.type] = [];
      }
      grouped[notification.type]!.add(notification);
    }
    
    return grouped;
  }
  
  /// Get recent notifications (last 24 hours)
  List<AppNotification> get recentNotifications {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return _getFilteredNotifications()
        .where((n) => n.createdAt.isAfter(yesterday))
        .toList();
  }
  
  /// Initialize and load notifications
  Future<void> loadNotifications() async {
    _setLoading(true);
    _clearError();
    
    try {
      _notifications = await _notificationService.getAllNotifications();
      await _removeExpiredNotifications();
      debugPrint('Loaded ${_notifications.length} notifications');
    } catch (e) {
      _setError('Failed to load notifications: $e');
      debugPrint('Error loading notifications: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Add a new notification
  Future<void> addNotification(AppNotification notification) async {
    try {
      await _notificationService.addNotification(notification);
      _notifications.insert(0, notification); // Add to beginning for recency
      notifyListeners();
      debugPrint('Added notification: ${notification.title}');
    } catch (e) {
      _setError('Failed to add notification: $e');
      debugPrint('Error adding notification: $e');
    }
  }
  
  /// Mark a notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        notifyListeners();
        debugPrint('Marked notification as read: $notificationId');
      }
    } catch (e) {
      _setError('Failed to mark notification as read: $e');
      debugPrint('Error marking notification as read: $e');
    }
  }
  
  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      notifyListeners();
      debugPrint('Marked all notifications as read');
    } catch (e) {
      _setError('Failed to mark all notifications as read: $e');
      debugPrint('Error marking all notifications as read: $e');
    }
  }
  
  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationService.deleteNotification(notificationId);
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      debugPrint('Deleted notification: $notificationId');
    } catch (e) {
      _setError('Failed to delete notification: $e');
      debugPrint('Error deleting notification: $e');
    }
  }
  
  /// Clear all notifications
  Future<void> clearAllNotifications() async {
    try {
      await _notificationService.clearAllNotifications();
      _notifications.clear();
      notifyListeners();
      debugPrint('Cleared all notifications');
    } catch (e) {
      _setError('Failed to clear notifications: $e');
      debugPrint('Error clearing notifications: $e');
    }
  }
  
  /// Set notification filter by type
  void setFilter(NotificationType? filter) {
    _selectedFilter = filter;
    notifyListeners();
  }
  
  /// Toggle showing only unread notifications
  void toggleUnreadFilter() {
    _showUnreadOnly = !_showUnreadOnly;
    notifyListeners();
  }
  
  /// Clear all filters
  void clearFilters() {
    _selectedFilter = null;
    _showUnreadOnly = false;
    notifyListeners();
  }
  
  /// Check for and generate quiz-related notifications
  Future<void> checkQuizNotifications({
    required List<dynamic> quests, // Daily quests
    required List<dynamic> dueCards, // SRS cards due for review
  }) async {
    try {
      final newNotifications = await _notificationService.generateQuizNotifications(
        quests: quests,
        dueCards: dueCards,
      );
      
      for (final notification in newNotifications) {
        // Check if we already have this notification
        final exists = _notifications.any((n) => n.id == notification.id);
        if (!exists) {
          _notifications.insert(0, notification);
        }
      }
      
      if (newNotifications.isNotEmpty) {
        notifyListeners();
        debugPrint('Generated ${newNotifications.length} quiz notifications');
      }
    } catch (e) {
      debugPrint('Error checking quiz notifications: $e');
    }
  }
  
  /// Generate notification for quest completion
  Future<void> notifyQuestCompleted(dynamic quest) async {
    try {
      final notification = AppNotification.dailyGoalCompleted(
        questsCompleted: 1,
        totalExp: quest.expReward ?? 0,
      );
      
      await addNotification(notification);
    } catch (e) {
      debugPrint('Error generating quest completion notification: $e');
    }
  }
  
  /// Generate notification for streak milestone
  Future<void> notifyStreakMilestone(int streakDays) async {
    try {
      final notification = AppNotification.streakReminder(
        currentStreak: streakDays,
      );
      
      await addNotification(notification);
    } catch (e) {
      debugPrint('Error generating streak notification: $e');
    }
  }
  
  /// Schedule recurring notification checks
  Future<void> scheduleNotificationChecks() async {
    try {
      await _notificationService.scheduleRecurringChecks();
      debugPrint('Scheduled recurring notification checks');
    } catch (e) {
      debugPrint('Error scheduling notification checks: $e');
    }
  }
  
  /// Get filtered and sorted notifications based on current settings
  List<AppNotification> _getFilteredNotifications() {
    List<AppNotification> filtered = _notifications
        .where((n) => n.shouldDisplay) // Only show non-expired, non-scheduled
        .toList();
    
    // Apply type filter
    if (_selectedFilter != null) {
      filtered = filtered.where((n) => n.type == _selectedFilter).toList();
    }
    
    // Apply unread filter
    if (_showUnreadOnly) {
      filtered = filtered.where((n) => !n.isRead).toList();
    }
    
    // Sort by priority, then by urgency, then by creation time
    filtered.sort((a, b) {
      // First by priority (critical first)
      final priorityComparison = b.priority.index.compareTo(a.priority.index);
      if (priorityComparison != 0) return priorityComparison;
      
      // Then by urgency
      if (a.isUrgent != b.isUrgent) {
        return a.isUrgent ? -1 : 1;
      }
      
      // Finally by creation time (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });
    
    return filtered;
  }
  
  /// Remove expired notifications from the list
  Future<void> _removeExpiredNotifications() async {
    final originalCount = _notifications.length;
    _notifications.removeWhere((n) => n.isExpired);
    
    if (_notifications.length < originalCount) {
      await _notificationService.saveNotifications(_notifications);
      debugPrint('Removed ${originalCount - _notifications.length} expired notifications');
    }
  }
  
  /// Refresh notifications (useful for manual refresh)
  Future<void> refreshNotifications() async {
    await loadNotifications();
  }
  
  /// Get notification statistics for display
  Map<String, int> getNotificationStats() {
    final stats = <String, int>{};
    
    for (final type in NotificationType.values) {
      final count = _notifications
          .where((n) => n.type == type && n.shouldDisplay)
          .length;
      stats[type.displayName] = count;
    }
    
    return stats;
  }
  
  /// Search notifications by title or message
  List<AppNotification> searchNotifications(String query) {
    if (query.isEmpty) return _getFilteredNotifications();
    
    final lowerQuery = query.toLowerCase();
    return _getFilteredNotifications()
        .where((n) => 
            n.title.toLowerCase().contains(lowerQuery) ||
            n.message.toLowerCase().contains(lowerQuery))
        .toList();
  }
  
  // Private helper methods
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
  
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }
  
  void _clearError() {
    _error = null;
  }
}