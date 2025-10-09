import 'package:flutter/material.dart';
import '../services/social_learning_service.dart';

class UserProfileScreen extends StatefulWidget {
  final UserProfile userProfile;
  final SocialLearningService socialService;

  const UserProfileScreen({
    super.key,
    required this.userProfile,
    required this.socialService,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoadingAction = false;
  int? _friendCount; // Store the actual friend count
  int? _mutualFriendsCount; // Store the mutual friends count
  
  @override
  void initState() {
    super.initState();
    _loadFriendCount();
    _loadMutualFriendsCount();
  }
  
  /// Load the friend count for this user
  Future<void> _loadFriendCount() async {
    final count = await widget.socialService.getFriendCountForUser(widget.userProfile.id);
    if (mounted) {
      setState(() {
        _friendCount = count;
      });
    }
  }
  
  /// Load the mutual friends count
  Future<void> _loadMutualFriendsCount() async {
    // Only load mutual friends if viewing someone else's profile
    if (!_isCurrentUser()) {
      final count = await widget.socialService.getMutualFriendsCount(widget.userProfile.id);
      if (mounted) {
        setState(() {
          _mutualFriendsCount = count;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userProfile.displayName),
        actions: [
          IconButton(
            onPressed: () => _showMoreOptions(),
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            _buildProfileHeader(),

            const SizedBox(height: 16),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Profile Information
            _buildProfileInfo(),

            const SizedBox(height: 24),

            // Study Stats
            if (widget.userProfile.progressPrivacy != PrivacyLevel.private ||
                _isFriend())
              _buildStudyStats(),

            const SizedBox(height: 24),

            // Interests
            if (widget.userProfile.interests.isNotEmpty) _buildInterests(),

            const SizedBox(height: 24),

            // Achievements
            if (widget.userProfile.achievements.isNotEmpty)
              _buildAchievements(),

            const SizedBox(height: 24),

            // Recent Activity
            if (_isFriend() ||
                widget.userProfile.progressPrivacy == PrivacyLevel.public)
              _buildRecentActivity(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final isOnline = widget.userProfile.isOnline;
    final lastActive = widget.userProfile.lastActive;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isOnline
                        ? Colors.green
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.1),
                  backgroundImage: widget.userProfile.avatar != null
                      ? NetworkImage(widget.userProfile.avatar!)
                      : null,
                  child: widget.userProfile.avatar == null
                      ? Text(
                          widget.userProfile.displayName.isNotEmpty
                              ? widget.userProfile.displayName[0].toUpperCase()
                              : widget.userProfile.username[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        )
                      : null,
                ),
              ),
              // Online indicator
              if (isOnline)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Display Name
          Text(
            widget.userProfile.displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 4),

          // Username
          Text(
            '@${widget.userProfile.username}',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                ),
          ),

          const SizedBox(height: 8),

          // Status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isOnline ? Icons.circle : Icons.schedule,
                size: 12,
                color: isOnline ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                isOnline
                    ? 'Online'
                    : lastActive != null
                        ? 'Last seen ${_formatLastActive(lastActive)}'
                        : 'Offline',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isOnline ? Colors.green : Colors.grey,
                    ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Level and Title
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Level ${widget.userProfile.level} • ${widget.userProfile.title}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isCurrentUser()) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit),
            label: const Text('Edit Profile'),
          ),
        ),
      );
    }

    final isFriend = _isFriend();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _isLoadingAction
                ? const Center(child: CircularProgressIndicator())
                : FilledButton.icon(
                    onPressed: isFriend ? _startChat : _sendFriendRequest,
                    icon: Icon(isFriend ? Icons.chat : Icons.person_add),
                    label: Text(isFriend ? 'Message' : 'Add Friend'),
                  ),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _shareProfile,
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9D9D9),
                ),
          ),

          const SizedBox(height: 12),

            if (widget.userProfile.bio != null &&
              widget.userProfile.bio!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF242628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                widget.userProfile.bio!,
                style: const TextStyle(color: Color(0xFFD9D9D9)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                'This user hasn\'t added a bio yet.',
                style: TextStyle(
                  color: Color(0xFF888888),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),          const SizedBox(height: 16),

          // Join date and mutual friends
          Row(
            children: [
              Icon(
                Icons.calendar_month,
                size: 16,
                color: const Color(0xFF888888),
              ),
              const SizedBox(width: 4),
              Text(
                'Joined ${_formatJoinDate(widget.userProfile.joinDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF888888),
                    ),
              ),
              const Spacer(),
              if (!_isCurrentUser()) _buildMutualFriends(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMutualFriends() {
    // Only show mutual friends if data is loaded and count > 0
    if (_mutualFriendsCount == null) {
      // Still loading
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            size: 16,
            color: const Color(0xFF888888),
          ),
          const SizedBox(width: 4),
          Text(
            '...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF888888),
                ),
          ),
        ],
      );
    }
    
    if (_mutualFriendsCount == 0) {
      // No mutual friends, hide the widget
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.people,
          size: 16,
          color: const Color(0xFF888888),
        ),
        const SizedBox(width: 4),
        Text(
          '$_mutualFriendsCount mutual friend${_mutualFriendsCount == 1 ? '' : 's'}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF888888),
              ),
        ),
      ],
    );
  }

  Widget _buildStudyStats() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Study Stats',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9D9D9),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242628),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Total XP',
                    '${widget.userProfile.totalXP}',
                    Icons.star,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Level',
                    '${widget.userProfile.level}',
                    Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Friends',
                    _friendCount != null ? '$_friendCount' : '...',
                    Icons.people,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF6FB8E9),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFFD9D9D9),
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF888888),
              ),
        ),
      ],
    );
  }

  Widget _buildInterests() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Interests',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9D9D9),
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.userProfile.interests
                .map((interest) => Chip(
                      label: Text(interest),
                      backgroundColor: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                      labelStyle: const TextStyle(
                        color: Color(0xFF6FB8E9),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9D9D9),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242628),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Achievements will be displayed here when available.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFD9D9D9),
                ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF242628),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
              ),
            ),
            child: const Text(
              'Recent activity will be shown here when available.',
              style: TextStyle(
                color: Color(0xFF888888),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isCurrentUser() {
    final currentUser = widget.socialService.currentUserProfile;
    return currentUser?.id == widget.userProfile.id;
  }

  bool _isFriend() {
    final currentUserId = widget.socialService.currentUserProfile?.id;
    if (currentUserId == null) return false;
    
    // Check if there's an accepted friendship where:
    // - Current user sent request (userId == currentUserId) AND friend received it (friendId == viewedUserId)
    // - OR friend sent request (userId == viewedUserId) AND current user received it (friendId == currentUserId)
    return widget.socialService.friends.any((friendship) =>
      (friendship.userId == currentUserId && friendship.friendId == widget.userProfile.id) ||
      (friendship.userId == widget.userProfile.id && friendship.friendId == currentUserId)
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference < 30) {
      return '$difference days ago';
    } else if (difference < 365) {
      final months = (difference / 30).round();
      return '$months month${months == 1 ? '' : 's'} ago';
    } else {
      final years = (difference / 365).round();
      return '$years year${years == 1 ? '' : 's'} ago';
    }
  }

  String _formatLastActive(DateTime lastActive) {
    final now = DateTime.now();
    final difference = now.difference(lastActive);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!_isCurrentUser()) ...[
              ListTile(
                leading: const Icon(Icons.report),
                title: const Text('Report User'),
                onTap: () {
                  Navigator.pop(context);
                  _reportUser();
                },
              ),
              ListTile(
                leading: const Icon(Icons.block),
                title: const Text('Block User'),
                onTap: () {
                  Navigator.pop(context);
                  _blockUser();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Profile'),
              onTap: () {
                Navigator.pop(context);
                _shareProfile();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFriendRequest() async {
    setState(() {
      _isLoadingAction = true;
    });

    try {
      final success = await widget.socialService.sendFriendRequest(
        friendId: widget.userProfile.id,
        message: 'Hi! I\'d like to connect and study together.',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Friend request sent to ${widget.userProfile.displayName}!'
                  : 'Failed to send friend request',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAction = false;
        });
      }
    }
  }

  void _startChat() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Starting chat with ${widget.userProfile.displayName} - Coming soon!'),
      ),
    );
  }

  void _shareProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Sharing ${widget.userProfile.displayName}\'s profile - Coming soon!'),
      ),
    );
  }

  void _reportUser() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report user functionality - Coming soon!'),
      ),
    );
  }

  void _blockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${widget.userProfile.displayName}?'),
        content: const Text(
          'This user will no longer be able to send you messages or see your profile.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Block user functionality - Coming soon!'),
                ),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }
}
