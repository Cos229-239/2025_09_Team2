import 'package:flutter/material.dart';
import '../../services/social_learning_service.dart';

// TODO: Social Widgets - Missing Real Social Features
// - All social functionality depends on placeholder service implementations
// - No real user authentication or profile management
// - Missing real-time messaging and video call integration
// - No push notifications for social activities
// - Missing content moderation and safety features
// - No privacy controls and data protection
// - Missing friend suggestions and discovery algorithms
// - No integration with external social platforms
// - Missing reporting and blocking functionality
// - No social analytics and engagement tracking
// - Missing social gamification features
// - No advanced group management and permissions

/// Widget for displaying user profile card
class UserProfileCard extends StatelessWidget {
  final UserProfile profile;
  final bool isCurrentUser;
  final VoidCallback? onTap;
  final VoidCallback? onMessageTap;
  final VoidCallback? onAddFriendTap;

  const UserProfileCard({
    super.key,
    required this.profile,
    this.isCurrentUser = false,
    this.onTap,
    this.onMessageTap,
    this.onAddFriendTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Profile Avatar
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getLevelColor(profile.level),
                    backgroundImage: profile.avatar != null
                        ? NetworkImage(profile.avatar!)
                        : null,
                    child: profile.avatar == null
                        ? Text(
                            profile.displayName.isNotEmpty
                                ? profile.displayName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),

                  // Profile Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.displayName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (profile.isOnline) ...[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Online',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          '@${profile.username}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getLevelColor(profile.level),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Lv.${profile.level} ${profile.title}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            Text(
                              '${profile.totalXP}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bio
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  profile.bio!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              // Interests
              if (profile.interests.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: profile.interests.take(3).map((interest) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        interest,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              // Action buttons
              if (!isCurrentUser) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (onAddFriendTap != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onAddFriendTap,
                          icon: const Icon(Icons.person_add, size: 16),
                          label: const Text('Add Friend'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    if (onAddFriendTap != null && onMessageTap != null)
                      const SizedBox(width: 8),
                    if (onMessageTap != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onMessageTap,
                          icon: const Icon(Icons.message, size: 16),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 50) return Colors.purple;
    if (level >= 40) return Colors.red;
    if (level >= 30) return Colors.orange;
    if (level >= 20) return Colors.blue;
    if (level >= 10) return Colors.green;
    return Colors.grey;
  }
}

/// Widget for displaying friend request card
class FriendRequestCard extends StatelessWidget {
  final Friendship friendship;
  final UserProfile? requesterProfile;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;

  const FriendRequestCard({
    super.key,
    required this.friendship,
    this.requesterProfile,
    this.onAccept,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  backgroundImage: requesterProfile?.avatar != null
                      ? NetworkImage(requesterProfile!.avatar!)
                      : null,
                  child: requesterProfile?.avatar == null
                      ? Text(
                          requesterProfile?.displayName.isNotEmpty == true
                              ? requesterProfile!.displayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        requesterProfile?.displayName ?? 'Unknown User',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Text(
                        '@${requesterProfile?.username ?? 'unknown'}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (friendship.requestMessage != null &&
                friendship.requestMessage!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  friendship.requestMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Sent ${_formatTimeAgo(friendship.requestDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }
}

/// Widget for displaying study group card
class StudyGroupCard extends StatelessWidget {
  final StudyGroup group;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool isJoined;
  final bool showJoinButton;

  const StudyGroupCard({
    super.key,
    required this.group,
    this.onTap,
    this.onJoin,
    this.isJoined = false,
    this.showJoinButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Group Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue,
                    backgroundImage: group.avatar != null
                        ? NetworkImage(group.avatar!)
                        : null,
                    child: group.avatar == null
                        ? const Icon(
                            Icons.groups,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                group.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (group.isPrivate)
                              Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                          ],
                        ),
                        Text(
                          '${group.currentMembers}/${group.maxMembers} members',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Description
              Text(
                group.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // Subjects
              if (group.subjects.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: group.subjects.take(3).map((subject) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        subject,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.info, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                  if (showJoinButton && !isJoined) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onJoin,
                        icon: const Icon(Icons.group_add, size: 16),
                        label: const Text('Join'),
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 8),
              Text(
                'Created ${_formatDate(group.createdDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 30) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else {
      return 'Today';
    }
  }
}

/// Widget for displaying collaborative session card
class CollaborativeSessionCard extends StatelessWidget {
  final CollaborativeSession session;
  final VoidCallback? onTap;
  final VoidCallback? onJoin;
  final bool canJoin;

  const CollaborativeSessionCard({
    super.key,
    required this.session,
    this.onTap,
    this.onJoin,
    this.canJoin = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUpcoming = session.scheduledTime.isAfter(DateTime.now());
    final isActive = session.isActive;

    Color statusColor = Colors.grey;
    String statusText = 'Ended';
    IconData statusIcon = Icons.history;

    if (isActive) {
      statusColor = Colors.green;
      statusText = 'Live';
      statusIcon = Icons.play_circle_filled;
    } else if (isUpcoming) {
      statusColor = Colors.blue;
      statusText = 'Upcoming';
      statusIcon = Icons.schedule;
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${session.participants.length} participant${session.participants.length != 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                session.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  session.subject,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.purple[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (session.description != null &&
                  session.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  session.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(session.scheduledTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              if (session.startTime != null && session.endTime != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Duration: ${_formatDuration(session.endTime!.difference(session.startTime!))}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
              if (canJoin && (isUpcoming || isActive)) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: Icon(isActive ? Icons.join_inner : Icons.schedule),
                    label: Text(isActive ? 'Join Session' : 'Join When Ready'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (sessionDate == today) {
      dateStr = 'Today';
    } else if (sessionDate == today.add(const Duration(days: 1))) {
      dateStr = 'Tomorrow';
    } else if (sessionDate == today.subtract(const Duration(days: 1))) {
      dateStr = 'Yesterday';
    } else {
      dateStr = '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    return '$dateStr at $timeStr';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Widget for displaying social stats
class SocialStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const SocialStatsWidget({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Friends',
                    '${stats['totalFriends'] ?? 0}',
                    Icons.people,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Study Groups',
                    '${stats['studyGroupsJoined'] ?? 0}',
                    Icons.groups,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Sessions',
                    '${stats['collaborativeSessions'] ?? 0}',
                    Icons.video_call,
                    Colors.purple,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Profile',
                    '${((stats['profileCompleteness'] ?? 0.0) * 100).toInt()}%',
                    Icons.account_circle,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
