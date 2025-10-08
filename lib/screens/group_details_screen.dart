import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/social_learning_service.dart' as service;

class GroupDetailsScreen extends StatefulWidget {
  final service.StudyGroup group;

  const GroupDetailsScreen({
    super.key,
    required this.group,
  });

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  bool _isMember = false;
  bool _isOwner = false;
  bool _hasRequestedToJoin = false;
  List<service.UserProfile> _members = [];
  List<service.UserProfile> _pendingRequests = [];
  service.SocialLearningService? _socialService;
  service.StudyGroup? _currentGroup; // Store the fresh group data

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeService();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeService() async {
    _socialService = service.SocialLearningService();
    await _socialService!.initialize();
    await _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    try {
      debugPrint('🔍 Loading group data for: ${widget.group.id}');
      
      // Get current user ID
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        debugPrint('❌ No current user ID');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      // Fetch fresh group data from Firestore
      final freshGroup = await _socialService!.getStudyGroupById(widget.group.id);
      
      if (freshGroup == null) {
        debugPrint('❌ Could not load group data');
        setState(() {
          _isLoading = false;
        });
        return;
      }
      
      _currentGroup = freshGroup;
      
      // Check if current user is the owner
      _isOwner = freshGroup.ownerId == currentUserId;
      debugPrint('👑 Is owner: $_isOwner (Owner: ${freshGroup.ownerId}, Current: $currentUserId)');
      
      // Check if current user is a member (owner is always a member)
      _isMember = _isOwner || freshGroup.members.any((member) => 
        member.userId == currentUserId && member.status == service.MembershipStatus.active
      );
      debugPrint('👥 Is member: $_isMember');
      
      // Load member profiles
      _members = await _socialService!.getGroupMembers(freshGroup);
      debugPrint('✅ Loaded ${_members.length} member profiles');
      
      // Load pending join requests (only for owner/moderator)
      if (_isOwner || freshGroup.members.any((m) => 
          m.userId == currentUserId && m.role == service.StudyGroupRole.moderator)) {
        final pendingMembers = _socialService!.getPendingMembers(freshGroup.id);
        
        // Load user profiles for pending members
        _pendingRequests = [];
        for (final pendingMember in pendingMembers) {
          final profile = await _socialService!.getUserProfile(pendingMember.userId);
          if (profile != null) {
            _pendingRequests.add(profile);
          }
        }
        debugPrint('📋 Loaded ${_pendingRequests.length} pending requests');
      } else {
        _pendingRequests = [];
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading group data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Loading...'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        actions: [
          if (_isMember)
            PopupMenuButton<String>(
              onSelected: _handleMenuAction,
              itemBuilder: (context) => [
                if (_isOwner) ...[
                  const PopupMenuItem(
                    value: 'invite',
                    child: ListTile(
                      leading: Icon(Icons.person_add),
                      title: Text('Invite Friends'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'settings',
                    child: ListTile(
                      leading: Icon(Icons.settings),
                      title: Text('Group Settings'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
                if (!_isOwner)
                  const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.red),
                      title: Text('Leave Group',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          // Group Header
          Container(
            padding: const EdgeInsets.all(20),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Text(
                        widget.group.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.group.name,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.group.subjects.isNotEmpty
                                ? widget.group.subjects.first
                                : 'General',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer
                                    .withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_members.length}/${widget.group.maxMembers} members',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: widget.group.isPrivate
                                      ? Colors.orange.withValues(alpha: 0.2)
                                      : Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  widget.group.isPrivate ? 'Private' : 'Public',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: widget.group.isPrivate
                                        ? Colors.orange[700]
                                        : Colors.green[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (widget.group.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    widget.group.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onPrimaryContainer
                              .withValues(alpha: 0.9),
                        ),
                  ),
                ],
                const SizedBox(height: 16),
                if (!_isMember) _buildJoinSection(),
              ],
            ),
          ),
          // Tab Bar
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Members', icon: Icon(Icons.people)),
              Tab(text: 'Activity', icon: Icon(Icons.timeline)),
              Tab(text: 'Resources', icon: Icon(Icons.folder)),
            ],
          ),
          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMembersTab(),
                _buildActivityTab(),
                _buildResourcesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinSection() {
    if (_hasRequestedToJoin) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.hourglass_empty, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Request pending approval'),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _joinGroup,
      icon: Icon(Icons.add),
      label: Text('Join Group'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildMembersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_isMember && _pendingRequests.isNotEmpty) ...[
          Text(
            'Pending Requests',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          ..._pendingRequests.map((user) => _buildPendingRequestTile(user)),
          const SizedBox(height: 16),
        ],
        Text(
          'Members (${_members.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ..._members.map((user) => _buildMemberTile(user)),
      ],
    );
  }

  Widget _buildMemberTile(service.UserProfile user) {
    // Use the fresh group data if available, otherwise fall back to widget.group
    final groupOwnerId = _currentGroup?.ownerId ?? widget.group.ownerId;
    final isAdmin = user.id == groupOwnerId;

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            child: Text(user.displayName.substring(0, 1).toUpperCase()),
          ),
          if (user.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
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
      title: Row(
        children: [
          Text(user.displayName),
          if (isAdmin) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Admin',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(user.bio ?? 'No bio available'),
      trailing: PopupMenuButton<String>(
        onSelected: (action) => _handleMemberAction(action, user),
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'profile',
            child: Text('View Profile'),
          ),
          const PopupMenuItem(
            value: 'message',
            child: Text('Send Message'),
          ),
          if (_isMember && !isAdmin)
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove from Group',
                  style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestTile(service.UserProfile user) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(user.displayName.substring(0, 1).toUpperCase()),
      ),
      title: Text(user.displayName),
      subtitle: Text(user.bio ?? 'No bio available'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => _handlePendingRequest(user, true),
            icon: Icon(Icons.check, color: Colors.green),
            tooltip: 'Accept',
          ),
          IconButton(
            onPressed: () => _handlePendingRequest(user, false),
            icon: Icon(Icons.close, color: Colors.red),
            tooltip: 'Decline',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    // TODO: Load real activity from Firestore
    // For now, show empty state
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.timeline,
              size: 64,
              color: Color(0xFF888888),
            ),
            const SizedBox(height: 16),
            Text(
              'No Activity Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFD9D9D9),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Group activity will appear here when members interact',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF888888),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourcesTab() {
    // TODO: Load real resources from Firestore
    // For now, show empty state with upload option
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open,
              size: 64,
              color: Color(0xFF888888),
            ),
            const SizedBox(height: 16),
            Text(
              'No Resources Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: const Color(0xFFD9D9D9),
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Upload study materials to share with your group',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF888888),
                  ),
            ),
            if (_isMember) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _uploadResource,
                icon: Icon(Icons.upload),
                label: Text('Upload Resource'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'invite':
        _showInviteDialog();
        break;
      case 'settings':
        _showGroupSettings();
        break;
      case 'leave':
        _showLeaveGroupDialog();
        break;
    }
  }

  void _handleMemberAction(String action, service.UserProfile user) {
    switch (action) {
      case 'profile':
        // Navigate to user profile
        break;
      case 'message':
        // Open chat with user
        break;
      case 'remove':
        _showRemoveMemberDialog(user);
        break;
    }
  }

  void _handlePendingRequest(service.UserProfile user, bool accept) async {
    if (_socialService == null) return;

    bool success;
    if (accept) {
      success = await _socialService!.approveMember(
        groupId: widget.group.id,
        userId: user.id,
      );
    } else {
      success = await _socialService!.denyMember(
        groupId: widget.group.id,
        userId: user.id,
      );
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _pendingRequests.remove(user);
        if (accept) {
          _members.add(user);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(accept
              ? '${user.displayName} has been added to the group'
              : '${user.displayName}\'s request has been declined'),
          backgroundColor: accept ? Colors.green : Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to process request'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _joinGroup() async {
    if (_socialService == null) return;

    String? password;
    
    // If group is private and has a password, show password dialog
    if (widget.group.isPrivate && widget.group.password != null) {
      password = await _showPasswordDialog();
      if (password == null) return; // User cancelled
    }

    final success = await _socialService!.joinStudyGroup(
      groupId: widget.group.id,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      if (widget.group.isPrivate) {
        setState(() {
          _hasRequestedToJoin = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application sent! Status: Pending approval'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        setState(() {
          _isMember = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the group!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadGroupData(); // Reload group data
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to join group. Check your password or group availability.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<String?> _showPasswordDialog() async {
    final TextEditingController passwordController = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Group Password'),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, passwordController.text),
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _showInviteDialog() async {
    if (_socialService == null) return;
    
    // Get all friends
    final friends = _socialService!.friends;
    
    // Get current group members to filter them out
    final memberIds = widget.group.members.map((m) => m.userId).toSet();
    
    // Filter friends who are not already members
    final availableFriends = <service.UserProfile>[];
    for (final friendship in friends) {
      final friendId = friendship.userId == _socialService!.currentUserProfile?.id 
          ? friendship.friendId 
          : friendship.userId;
      
      if (!memberIds.contains(friendId)) {
        final friendProfile = await _socialService!.getUserProfile(friendId);
        if (friendProfile != null) {
          availableFriends.add(friendProfile);
        }
      }
    }

    if (!mounted) return;

    if (availableFriends.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No friends available to invite')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Invite Friends'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableFriends.length,
            itemBuilder: (context, index) {
              final friend = availableFriends[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: friend.avatar != null
                      ? NetworkImage(friend.avatar!)
                      : null,
                  child: friend.avatar == null
                      ? Text(friend.displayName[0].toUpperCase())
                      : null,
                ),
                title: Text(friend.displayName),
                subtitle: Text('@${friend.username}'),
                trailing: ElevatedButton(
                  onPressed: () async {
                    final success = await _socialService!.inviteFriendToGroup(
                      groupId: widget.group.id,
                      friendId: friend.id,
                    );
                    
                    if (!mounted) return;
                    
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Invited ${friend.displayName} to the group!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                      setState(() {}); // Refresh the members list
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to invite friend'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Invite'),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showGroupSettings() {
    // Implementation for group settings
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Group settings feature coming soon!')),
    );
  }

  void _showLeaveGroupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Group'),
        content: Text('Are you sure you want to leave "${widget.group.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Left "${widget.group.name}" successfully'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Leave', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRemoveMemberDialog(service.UserProfile user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Member'),
        content: Text('Remove ${user.displayName} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _members.remove(user);
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.displayName} removed from group'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _uploadResource() {
    // Implementation for uploading resources
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload resource feature coming soon!')),
    );
  }
}
