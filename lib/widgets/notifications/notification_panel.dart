import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';

/// LinkedIn-style notification panel widget with filtering and interaction features
/// Displays notifications in a modern, professional layout with read/unread states
class NotificationPanel extends StatelessWidget {
  final VoidCallback? onClose;
  final bool isBottomSheet;

  const NotificationPanel({
    super.key,
    this.onClose,
    this.isBottomSheet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Container(
          height: isBottomSheet ? MediaQuery.of(context).size.height * 0.8 : null,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: isBottomSheet 
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : null,
            boxShadow: isBottomSheet ? [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ] : null,
          ),
          child: Column(
            children: [
              // Header with title and controls
              _buildHeader(context, notificationProvider),
              
              // Filter bar
              _buildFilterBar(context, notificationProvider),
              
              // Notification list
              Expanded(
                child: _buildNotificationList(context, notificationProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build the header section with title and action buttons
  Widget _buildHeader(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Title with unread count
          Expanded(
            child: Row(
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (provider.unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Action buttons
          Row(
            children: [
              // Mark all as read button
              if (provider.unreadCount > 0)
                IconButton(
                  icon: const Icon(Icons.done_all),
                  onPressed: () => provider.markAllAsRead(),
                  tooltip: 'Mark all as read',
                ),
              
              // Settings button
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => _showNotificationSettings(context),
                tooltip: 'Notification settings',
              ),
              
              // Close button (for bottom sheet)
              if (onClose != null)
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build the filter bar for notification types and read status
  Widget _buildFilterBar(BuildContext context, NotificationProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Type filter dropdown
          Expanded(
            child: DropdownButtonFormField<NotificationType?>(
              initialValue: provider.selectedFilter,
              decoration: const InputDecoration(
                labelText: 'Filter by type',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<NotificationType?>(
                  value: null,
                  child: Text('All notifications'),
                ),
                ...NotificationType.values.map((type) => DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Text(type.icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Text(type.displayName),
                    ],
                  ),
                )),
              ],
              onChanged: (value) => provider.setFilter(value),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Unread only toggle
          FilterChip(
            label: const Text('Unread only'),
            selected: provider.showUnreadOnly,
            onSelected: (_) => provider.toggleUnreadFilter(),
            selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// Build the main notification list
  Widget _buildNotificationList(BuildContext context, NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final notifications = provider.notifications;

    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              provider.showUnreadOnly ? 'No unread notifications' : 'No notifications',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'We\'ll notify you about quiz deadlines and study reminders',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
        return _buildNotificationItem(context, notification, provider);
      },
    );
  }

  /// Build individual notification item with LinkedIn-style design
  Widget _buildNotificationItem(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: notification.isRead 
            ? Colors.transparent 
            : Theme.of(context).primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: notification.isUrgent
            ? Border.all(color: Colors.orange, width: 1)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _buildNotificationIcon(notification),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.w600,
                ),
              ),
            ),
            Text(
              notification.timeAgo,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              notification.message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: notification.isRead ? Colors.grey.shade600 : Colors.grey.shade800,
              ),
            ),
            if (notification.isUrgent) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'URGENT',
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 20),
          onSelected: (action) => _handleNotificationAction(
            context, notification, provider, action,
          ),
          itemBuilder: (context) => [
            if (!notification.isRead)
              const PopupMenuItem(
                value: 'mark_read',
                child: Row(
                  children: [
                    Icon(Icons.done, size: 16),
                    SizedBox(width: 8),
                    Text('Mark as read'),
                  ],
                ),
              ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        onTap: () => _handleNotificationTap(context, notification, provider),
      ),
    );
  }

  /// Build notification icon based on type and priority
  Widget _buildNotificationIcon(AppNotification notification) {
    Color backgroundColor;

    switch (notification.priority) {
      case NotificationPriority.critical:
        backgroundColor = Colors.red.shade100;
        break;
      case NotificationPriority.high:
        backgroundColor = Colors.orange.shade100;
        break;
      case NotificationPriority.normal:
        backgroundColor = Colors.blue.shade100;
        break;
      case NotificationPriority.low:
        backgroundColor = Colors.grey.shade200;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          notification.type.icon,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  /// Handle notification item tap
  void _handleNotificationTap(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    // Mark as read if not already read
    if (!notification.isRead) {
      provider.markAsRead(notification.id);
    }

    // Handle navigation if action is specified
    if (notification.action != null) {
      final action = notification.action!;
      
      if (action.type == ActionType.navigate && action.route != null) {
        Navigator.of(context).pushNamed(
          action.route!,
          arguments: action.parameters,
        );
      }
    }
  }

  /// Handle notification action menu
  void _handleNotificationAction(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
    String action,
  ) {
    switch (action) {
      case 'mark_read':
        provider.markAsRead(notification.id);
        break;
      case 'delete':
        provider.deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification deleted'),
            duration: Duration(seconds: 2),
          ),
        );
        break;
    }
  }

  /// Show notification settings dialog
  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const NotificationSettingsDialog(),
    );
  }
}

/// Settings dialog for notification preferences
class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() => _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState extends State<NotificationSettingsDialog> {
  Map<String, bool> _settings = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load settings from notification service
    // For now, use default settings
    setState(() {
      _settings = {
        'Quiz Expiring': true,
        'Quiz Available': true,
        'Review Due': true,
        'Streak Reminder': true,
        'Achievements': true,
        'System Updates': true,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Notification Settings'),
      content: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: _settings.entries.map((entry) {
                return SwitchListTile(
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) {
                    setState(() {
                      _settings[entry.key] = value;
                    });
                  },
                );
              }).toList(),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Save settings
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Settings saved'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Notification bell icon with unread count badge
class NotificationBellIcon extends StatelessWidget {
  final VoidCallback? onTap;

  const NotificationBellIcon({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: onTap ?? () => _showNotificationPanel(context),
            ),
            if (provider.unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    provider.unreadCount > 99 ? '99+' : '${provider.unreadCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showNotificationPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => NotificationPanel(
        isBottomSheet: true,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }
}