import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/notification.dart';
import '../../providers/notification_provider.dart';
import '../../screens/dashboard_screen.dart'; // Import for SettingsGearPainter

// TODO: Notification Panel - Missing Core Notification Features
// - No actual push notifications integration (Firebase Cloud Messaging)
// - Settings save functionality shows success message but doesn't persist
// - Missing real-time notification delivery system
// - No notification scheduling and delivery management
// - Missing notification sound and vibration customization
// - No notification categories and custom channels
// - Missing notification templates and personalization
// - No bulk notification management (select multiple, batch actions)
// - Missing notification analytics and engagement tracking
// - No notification history and archival system
// - Missing deep link handling for notification navigation
// - No notification preview and test functionality

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
          height:
              isBottomSheet ? MediaQuery.of(context).size.height * 0.8 : null,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: isBottomSheet
                ? const BorderRadius.vertical(top: Radius.circular(20))
                : null,
            boxShadow: isBottomSheet
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ]
                : null,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // If height is very small during animation, show minimal content
              if (constraints.maxHeight < 100) {
                return SizedBox(
                  height: constraints.maxHeight,
                  width: double.infinity,
                );
              }

              return ClipRect(
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  height: constraints.maxHeight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with title and controls
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildHeader(context, notificationProvider),
                      ),

                      // Filter bar
                      Flexible(
                        fit: FlexFit.loose,
                        child: _buildFilterBar(context, notificationProvider),
                      ),

                      // Notification list - takes remaining space
                      Expanded(
                        child: _buildNotificationList(
                            context, notificationProvider),
                      ),
                    ],
                  ),
                ),
              );
            },
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              // Mark all as read text button - always visible
              GestureDetector(
                onTap: provider.unreadCount > 0
                    ? () => provider.markAllAsRead()
                    : null,
                child: Text(
                  'Mark all as read',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: provider.unreadCount > 0
                            ? const Color(0xFF6FB8E9)
                            : const Color(0xFF6FB8E9).withValues(
                                alpha: 0.5), // Dimmed when no unread
                        fontWeight: FontWeight.w600,
                      ),
                ),
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
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
            selectedColor:
                Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  /// Build the main notification list
  Widget _buildNotificationList(
      BuildContext context, NotificationProvider provider) {
    if (provider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final notifications = provider.notifications;

    if (notifications.isEmpty) {
      return LayoutBuilder(
        builder: (context, constraints) {
          // Scale down the illustration if space is limited during animation
          final availableHeight = constraints.maxHeight;
          final shouldShowIllustration = availableHeight > 200;
          final illustrationSize = availableHeight > 300
              ? 160.0
              : (availableHeight * 0.4).clamp(80.0, 160.0);

          return Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: availableHeight > 0 ? availableHeight : 0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (shouldShowIllustration) ...[
                      // Static detective cat image (ONLY this image, no fallbacks)
                      Container(
                        width: illustrationSize,
                        height: illustrationSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.transparent,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.asset(
                            'assets/detective_cat_final.png',
                            width: illustrationSize,
                            height: illustrationSize,
                            fit: BoxFit.contain,
                            // NO ERROR BUILDER - only show the detective cat image
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    if (availableHeight >
                        100) // Only show text if there's enough space
                      Text(
                        'Looks like nothing\'s here...',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: const Color(
                                      0xFFD9D9D9), // Matching app text color
                                  fontWeight: FontWeight.w500,
                                ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
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
                      fontWeight: notification.isRead
                          ? FontWeight.normal
                          : FontWeight.w600,
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
                    color: notification.isRead
                        ? Colors.grey.shade600
                        : Colors.grey.shade800,
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
            context,
            notification,
            provider,
            action,
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
}

/// Settings dialog for notification preferences
class NotificationSettingsDialog extends StatefulWidget {
  const NotificationSettingsDialog({super.key});

  @override
  State<NotificationSettingsDialog> createState() =>
      _NotificationSettingsDialogState();
}

class _NotificationSettingsDialogState
    extends State<NotificationSettingsDialog> {
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

/// Notification bell icon with unread count badge and custom SVG states
class NotificationBellIcon extends StatefulWidget {
  final VoidCallback? onTap;
  final bool isSelected;

  const NotificationBellIcon({
    super.key,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon>
    with TickerProviderStateMixin {
  late AnimationController _ringAnimationController;
  late Animation<double> _ringAnimation;
  late AnimationController _dotAnimationController;
  late Animation<double> _dotScaleAnimation;
  late Animation<double> _dotOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // Bell ringing animation controller
    _ringAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1700), // Total animation duration
      vsync: this,
    );

    // Bell ringing animation with keyframes matching the Lottie animation
    _ringAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: 18)
            .chain(CurveTween(curve: const Cubic(0.455, 1, 0.7, 0))),
        weight: 23, // 0 to 7 frames (7/30 * 100 ≈ 23%)
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: -18)
            .chain(CurveTween(curve: const Cubic(0.279, 1, 0.7, 0))),
        weight: 23, // 7 to 14 frames
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -18, end: 18)
            .chain(CurveTween(curve: const Cubic(0.334, 0.997, 0.7, 0))),
        weight: 30, // 14 to 23 frames
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18, end: -9)
            .chain(CurveTween(curve: const Cubic(0.335, 1, 0.7, 0))),
        weight: 27, // 23 to 31 frames
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -9, end: 5)
            .chain(CurveTween(curve: const Cubic(0.7, 1, 0.3, 0))),
        weight: 23, // 31 to 38 frames
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 5, end: 0)
            .chain(CurveTween(curve: const Cubic(0.194, 1.949, 0.3, 0))),
        weight: 40, // 38 to 50 frames
      ),
    ]).animate(_ringAnimationController);

    // Red dot animation controller (appears during ringing)
    _dotAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300), // Quick appear animation
      vsync: this,
    );

    // Scale animation for the red dot (starts at 0, grows to 1.0)
    _dotScaleAnimation = Tween<double>(
      begin: 0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotAnimationController,
      curve: const Cubic(0.7, 1, 0.7, 0), // Matching Lottie easing
    ));

    // Opacity animation for the red dot (0 to 1)
    _dotOpacityAnimation = Tween<double>(
      begin: 0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _dotAnimationController,
      curve: const Cubic(0.833, 0.833, 0.167, 0.167), // Matching Lottie easing
    ));
  }

  @override
  void dispose() {
    _ringAnimationController.dispose();
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        // Determine notification state
        bool hasUnread = provider.unreadCount > 0;
        bool isSelected = widget.isSelected;

        // Start/stop animations based on unread status
        if (hasUnread && !_ringAnimationController.isAnimating) {
          _ringAnimationController.repeat(reverse: false);
          _dotAnimationController.forward();
        } else if (!hasUnread) {
          _ringAnimationController.stop();
          _ringAnimationController.reset();
          _dotAnimationController.reverse();
        }

        return AnimatedBuilder(
          animation: Listenable.merge(
              [_ringAnimation, _dotScaleAnimation, _dotOpacityAnimation]),
          builder: (context, child) {
            return Stack(
              children: [
                Transform.rotate(
                  angle: hasUnread
                      ? _ringAnimation.value * (3.14159 / 180)
                      : 0, // Only animate rotation when there are unread notifications
                  child: GestureDetector(
                    onTap:
                        widget.onTap ?? () => _showNotificationPanel(context),
                    child: CustomPaint(
                      size: const Size(28, 28),
                      painter: _getNotificationPainter(
                        hasUnread: hasUnread,
                        isSelected: isSelected,
                        waveProgress:
                            0, // Always 0 to keep consistent visual style
                      ),
                    ),
                  ),
                ),
                // Red notification dot (matching Lottie animation)
                if (hasUnread)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Transform.scale(
                      scale: _dotScaleAnimation.value,
                      child: Opacity(
                        opacity: _dotOpacityAnimation.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(
                                0xFFEF3737), // Red color matching Lottie: [0.937254961799,0.215686289469,0.215686289469,1]
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  CustomPainter _getNotificationPainter({
    required bool hasUnread,
    required bool isSelected,
    required double waveProgress,
  }) {
    final iconColor = Theme.of(context).iconTheme.color;

    // If the notification panel is open (selected), show X icon with blue color
    if (isSelected) {
      return NotificationCloseIconPainter(iconColor: const Color(0xFF6FB8E9));
    }

    // Always use the same visual style regardless of unread status
    // Only the ringing animation changes, not the icon appearance
    if (hasUnread) {
      return NotificationBellOutlinedPainter(iconColor: iconColor);
    } else {
      return NotificationBellOutlinedPainter(iconColor: iconColor);
    }
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

/// Custom painter for outlined notification bell (normal state)
class NotificationBellOutlinedPainter extends CustomPainter {
  final Color? iconColor;

  NotificationBellOutlinedPainter({this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = iconColor ?? Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Convert SVG path to Flutter coordinates
    // SVG viewBox is 0 0 24 24, so we scale to our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Main bell shape: M14.857 17.082a23.848 23.848 0 0 0 5.454-1.31A8.967 8.967 0 0 1 18 9.75V9A6 6 0 0 0 6 9v.75a8.967 8.967 0 0 1-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31
    path.moveTo(14.857 * scaleX, 17.082 * scaleY);

    // Curve for right side of bell
    path.cubicTo(
      17.571 * scaleX,
      16.562 * scaleY,
      19.595 * scaleX,
      15.982 * scaleY,
      20.311 * scaleX,
      15.772 * scaleY,
    );

    // Right bell curve to top
    path.cubicTo(
      19.033 * scaleX,
      12.75 * scaleY,
      18 * scaleX,
      11.358 * scaleY,
      18 * scaleX,
      9.75 * scaleY,
    );

    // Top of bell
    path.lineTo(18 * scaleX, 9 * scaleY);
    path.cubicTo(
      18 * scaleX,
      5.686 * scaleY,
      15.314 * scaleX,
      3 * scaleY,
      12 * scaleX,
      3 * scaleY,
    );
    path.cubicTo(
      8.686 * scaleX,
      3 * scaleY,
      6 * scaleX,
      5.686 * scaleY,
      6 * scaleX,
      9 * scaleY,
    );

    // Left side of bell
    path.lineTo(6 * scaleX, 9.75 * scaleY);
    path.cubicTo(
      6 * scaleX,
      11.358 * scaleY,
      4.967 * scaleX,
      12.75 * scaleY,
      3.688 * scaleX,
      15.772 * scaleY,
    );

    // Left bell curve
    path.cubicTo(
      5.421 * scaleX,
      16.412 * scaleY,
      7.248 * scaleX,
      16.857 * scaleY,
      9.143 * scaleX,
      17.082 * scaleY,
    );

    canvas.drawPath(path, paint);

    // Draw the bell clapper/bottom part: m5.714 0a24.255 24.255 0 0 1-5.714 0m5.714 0a3 3 0 1 1-5.714 0
    final clapperPath = Path();

    // Bottom line of bell
    clapperPath.moveTo(9.143 * scaleX, 17.082 * scaleY);
    clapperPath.lineTo(14.857 * scaleX, 17.082 * scaleY);

    // Clapper semicircle
    clapperPath.moveTo(14.857 * scaleX, 17.082 * scaleY);
    clapperPath.cubicTo(
      14.857 * scaleX,
      18.74 * scaleY,
      13.657 * scaleX,
      20.082 * scaleY,
      12 * scaleX,
      20.082 * scaleY,
    );
    clapperPath.cubicTo(
      10.343 * scaleX,
      20.082 * scaleY,
      9.143 * scaleX,
      18.74 * scaleY,
      9.143 * scaleX,
      17.082 * scaleY,
    );

    canvas.drawPath(clapperPath, paint);

    // Draw the top sound lines: M3.124 7.5A8.969 8.969 0 0 1 5.292 3m13.416 0a8.969 8.969 0 0 1 2.168 4.5
    final soundPath = Path();

    // Left sound line
    soundPath.moveTo(3.124 * scaleX, 7.5 * scaleY);
    soundPath.cubicTo(
      3.847 * scaleX,
      5.813 * scaleY,
      4.569 * scaleX,
      4.407 * scaleY,
      5.292 * scaleX,
      3 * scaleY,
    );

    // Right sound line
    soundPath.moveTo(18.708 * scaleX, 3 * scaleY);
    soundPath.cubicTo(
      19.431 * scaleX,
      4.407 * scaleY,
      20.153 * scaleX,
      5.813 * scaleY,
      20.876 * scaleX,
      7.5 * scaleY,
    );

    canvas.drawPath(soundPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom painter for filled notification bell (selected state)
class NotificationBellFilledPainter extends CustomPainter {
  final Color? fillColor;

  NotificationBellFilledPainter({this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = fillColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    final path = Path();

    // Bell body - filled
    path.moveTo(size.width * 0.2, size.height * 0.75);
    path.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.15,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.75,
    );

    // Bell bottom
    path.lineTo(size.width * 0.2, size.height * 0.75);

    // Bell clapper
    final clapperRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.85),
      width: size.width * 0.15,
      height: size.height * 0.1,
    );
    path.addRRect(
        RRect.fromRectAndRadius(clapperRect, const Radius.circular(2)));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom painter for outlined notification bell with animated wave lines (unread state)
class NotificationBellOutlinedWithWavesPainter extends CustomPainter {
  final double waveProgress;

  NotificationBellOutlinedWithWavesPainter({required this.waveProgress});

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the outlined bell
    final bellPaint = Paint()
      ..color = Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bellPath = Path();

    // Bell body - outlined
    bellPath.moveTo(size.width * 0.2, size.height * 0.75);
    bellPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.15,
    );
    bellPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.75,
    );

    // Bell bottom
    bellPath.lineTo(size.width * 0.2, size.height * 0.75);

    // Bell clapper
    final clapperRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.85),
      width: size.width * 0.15,
      height: size.height * 0.1,
    );
    bellPath.addRRect(
        RRect.fromRectAndRadius(clapperRect, const Radius.circular(2)));

    canvas.drawPath(bellPath, bellPaint);

    // Draw animated wave lines
    final wavePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.6 + (0.4 * waveProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left wave
    final leftWaveRadius =
        (size.width * 0.3) + (size.width * 0.2 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.5),
      leftWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 0.8 - (0.6 * waveProgress)),
    );

    // Right wave
    final rightWaveRadius =
        (size.width * 0.3) + (size.width * 0.2 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.5),
      rightWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 0.8 - (0.6 * waveProgress)),
    );

    // Center wave (smaller)
    final centerWaveRadius =
        (size.width * 0.2) + (size.width * 0.15 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      centerWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 0.9 - (0.7 * waveProgress)),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is NotificationBellOutlinedWithWavesPainter &&
        oldDelegate.waveProgress != waveProgress;
  }
}

/// Custom painter for filled notification bell with animated wave lines (unread + selected state)
class NotificationBellFilledWithWavesPainter extends CustomPainter {
  final double waveProgress;
  final Color? fillColor;

  NotificationBellFilledWithWavesPainter({
    required this.waveProgress,
    this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the filled bell
    final bellPaint = Paint()
      ..color = fillColor ?? Colors.blue
      ..style = PaintingStyle.fill;

    final bellPath = Path();

    // Bell body - filled
    bellPath.moveTo(size.width * 0.2, size.height * 0.75);
    bellPath.quadraticBezierTo(
      size.width * 0.2,
      size.height * 0.4,
      size.width * 0.5,
      size.height * 0.15,
    );
    bellPath.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.4,
      size.width * 0.8,
      size.height * 0.75,
    );

    // Bell bottom
    bellPath.lineTo(size.width * 0.2, size.height * 0.75);

    // Bell clapper
    final clapperRect = Rect.fromCenter(
      center: Offset(size.width * 0.5, size.height * 0.85),
      width: size.width * 0.15,
      height: size.height * 0.1,
    );
    bellPath.addRRect(
        RRect.fromRectAndRadius(clapperRect, const Radius.circular(2)));

    canvas.drawPath(bellPath, bellPaint);

    // Draw animated wave lines
    final wavePaint = Paint()
      ..color = Colors.orange.withValues(alpha: 0.7 + (0.3 * waveProgress))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Left wave
    final leftWaveRadius =
        (size.width * 0.3) + (size.width * 0.2 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.5),
      leftWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 0.9 - (0.7 * waveProgress)),
    );

    // Right wave
    final rightWaveRadius =
        (size.width * 0.3) + (size.width * 0.2 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.5),
      rightWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 0.9 - (0.7 * waveProgress)),
    );

    // Center wave (smaller)
    final centerWaveRadius =
        (size.width * 0.2) + (size.width * 0.15 * waveProgress);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.4),
      centerWaveRadius,
      wavePaint
        ..color = wavePaint.color.withValues(alpha: 1.0 - (0.8 * waveProgress)),
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is NotificationBellFilledWithWavesPainter &&
        oldDelegate.waveProgress != waveProgress;
  }
}

/// Animated settings button widget with gear rotation matching Lottie animation
class AnimatedSettingsButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedSettingsButton({
    super.key,
    required this.onPressed,
  });

  @override
  State<AnimatedSettingsButton> createState() => _AnimatedSettingsButtonState();
}

class _AnimatedSettingsButtonState extends State<AnimatedSettingsButton>
    with TickerProviderStateMixin {
  late AnimationController _settingsController;
  late Animation<double> _settingsRotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize Settings icon animation controller matching dashboard
    _settingsController = AnimationController(
      duration:
          const Duration(milliseconds: 1000), // 1 second (60 frames at 60fps)
      vsync: this,
    );
    // Create complex rotation animation matching Lottie keyframes
    _settingsRotationAnimation = TweenSequence<double>([
      // 0-16 frames: 0° to 64°
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 64 / 360)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 27, // 16/60 * 100 ≈ 27%
      ),
      // 16-25 frames: 64° to 60° (slight back)
      TweenSequenceItem(
        tween: Tween<double>(begin: 64 / 360, end: 60 / 360)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15, // 9/60 * 100 = 15%
      ),
      // 25-32 frames: hold at 60°
      TweenSequenceItem(
        tween: Tween<double>(begin: 60 / 360, end: 60 / 360),
        weight: 12, // 7/60 * 100 ≈ 12%
      ),
      // 32-48 frames: 60° to 124°
      TweenSequenceItem(
        tween: Tween<double>(begin: 60 / 360, end: 124 / 360)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 27, // 16/60 * 100 ≈ 27%
      ),
      // 48-57 frames: 124° to 120° (settle)
      TweenSequenceItem(
        tween: Tween<double>(begin: 124 / 360, end: 120 / 360)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 19, // 9/60 * 100 ≈ 15%, remaining 4% for balance
      ),
    ]).animate(_settingsController);
  }

  @override
  void dispose() {
    _settingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _settingsRotationAnimation,
      builder: (context, child) {
        return IconButton(
          icon: Transform.rotate(
            angle: _settingsRotationAnimation.value *
                2 *
                3.14159, // Convert to radians
            child: CustomPaint(
              size: const Size(24, 24),
              painter: SettingsGearPainter(
                color: Theme.of(context).iconTheme.color,
              ),
            ),
          ),
          onPressed: () {
            // Trigger gear rotation animation
            _settingsController.forward().then((_) {
              // Reset animation after completion
              _settingsController.reset();
            });

            // Call the provided callback
            widget.onPressed();
          },
          tooltip: 'Notification settings',
        );
      },
    );
  }
}

/// Custom painter for close (X) icon when notification panel is open
class NotificationCloseIconPainter extends CustomPainter {
  final Color? iconColor;

  NotificationCloseIconPainter({this.iconColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = iconColor ?? Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double length = size.width * 0.35; // X size relative to icon size

    // Draw X lines
    canvas.drawLine(
      Offset(centerX - length, centerY - length),
      Offset(centerX + length, centerY + length),
      paint,
    );
    canvas.drawLine(
      Offset(centerX + length, centerY - length),
      Offset(centerX - length, centerY + length),
      paint,
    );
  }

  @override
  bool shouldRepaint(NotificationCloseIconPainter oldDelegate) {
    return iconColor != oldDelegate.iconColor;
  }
}
