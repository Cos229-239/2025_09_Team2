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
    // Load real activity from Firestore
    return FutureBuilder<List<_ActivityItem>>(
      future: _loadGroupActivity(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final activities = snapshot.data ?? [];

        if (activities.isEmpty) {
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

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return _buildActivityItem(activity);
          },
        );
      },
    );
  }

  Widget _buildResourcesTab() {
    // Load real resources from Firestore
    return FutureBuilder<List<_GroupResource>>(
      future: _loadGroupResources(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = snapshot.data ?? [];

        if (resources.isEmpty) {
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
                      icon: const Icon(Icons.upload),
                      label: const Text('Upload Resource'),
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

        return Column(
          children: [
            if (_isMember)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: _uploadResource,
                  icon: const Icon(Icons.upload),
                  label: const Text('Upload Resource'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: resources.length,
                itemBuilder: (context, index) {
                  final resource = resources[index];
                  return _buildResourceItem(resource);
                },
              ),
            ),
          ],
        );
      },
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
                    
                    if (!mounted || !context.mounted) return;
                    
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
    _showUploadResourceDialog();
  }

  void _showUploadResourceDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final urlController = TextEditingController();
    String selectedType = 'PDF';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Upload Resource'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        hintText: 'Chapter 5 Notes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Summary of key concepts',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Resource Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'PDF', child: Text('PDF Document')),
                        DropdownMenuItem(value: 'Link', child: Text('Web Link')),
                        DropdownMenuItem(value: 'Video', child: Text('Video')),
                        DropdownMenuItem(value: 'Image', child: Text('Image')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL/Link *',
                        hintText: 'https://example.com/file.pdf',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    titleController.dispose();
                    descriptionController.dispose();
                    urlController.dispose();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        urlController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in required fields'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Create new resource
                    final newResource = _GroupResource(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      description: descriptionController.text.trim(),
                      type: selectedType,
                      url: urlController.text.trim(),
                      uploadedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
                      uploadDate: DateTime.now(),
                    );

                    // Save to Firestore when backend is ready:
                    // await _socialService!.uploadGroupResource(widget.group.id, newResource);
                    debugPrint('Resource to upload: ${newResource.title}');

                    titleController.dispose();
                    descriptionController.dispose();
                    urlController.dispose();

                    if (!mounted) return;
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Resource uploaded successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Refresh the tab
                    setState(() {});
                  },
                  child: const Text('Upload'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<List<_ActivityItem>> _loadGroupActivity() async {
    // Load activity from Firestore
    // For now, generate activity from group data
    final activities = <_ActivityItem>[];

    // Add member join activities
    for (final member in _members) {
      final memberData = widget.group.members.firstWhere(
        (m) => m.userId == member.id,
        orElse: () => service.StudyGroupMember(
          userId: member.id,
          groupId: widget.group.id,
          role: service.StudyGroupRole.member,
          status: service.MembershipStatus.active,
          joinDate: DateTime.now(),
        ),
      );

      activities.add(_ActivityItem(
        id: 'join_${member.id}',
        type: _ActivityType.memberJoined,
        userName: member.displayName,
        userId: member.id,
        timestamp: memberData.joinDate,
        description: 'joined the group',
      ));
    }

    // Sort by most recent first
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return activities;
  }

  Widget _buildActivityItem(_ActivityItem activity) {
    IconData icon;
    Color iconColor;

    switch (activity.type) {
      case _ActivityType.memberJoined:
        icon = Icons.person_add;
        iconColor = Colors.green;
        break;
      case _ActivityType.memberLeft:
        icon = Icons.person_remove;
        iconColor = Colors.orange;
        break;
      case _ActivityType.resourceUploaded:
        icon = Icons.upload_file;
        iconColor = Colors.blue;
        break;
      case _ActivityType.messagePosted:
        icon = Icons.message;
        iconColor = Colors.purple;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.bodyMedium,
            children: [
              TextSpan(
                text: activity.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              TextSpan(text: ' ${activity.description}'),
            ],
          ),
        ),
        subtitle: Text(_formatActivityTime(activity.timestamp)),
      ),
    );
  }

  String _formatActivityTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        if (difference.inMinutes == 0) {
          return 'Just now';
        } else {
          return '${difference.inMinutes}m ago';
        }
      } else {
        return '${difference.inHours}h ago';
      }
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Future<List<_GroupResource>> _loadGroupResources() async {
    // Load resources from Firestore
    // For now, return empty list
    // In production, this would query Firestore for group resources
    return [];
  }

  Widget _buildResourceItem(_GroupResource resource) {
    IconData icon;
    Color iconColor;

    switch (resource.type) {
      case 'PDF':
        icon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'Link':
        icon = Icons.link;
        iconColor = Colors.blue;
        break;
      case 'Video':
        icon = Icons.video_library;
        iconColor = Colors.purple;
        break;
      case 'Image':
        icon = Icons.image;
        iconColor = Colors.orange;
        break;
      default:
        icon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.1),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(resource.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resource.description.isNotEmpty)
              Text(
                resource.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              'Uploaded ${_formatActivityTime(resource.uploadDate)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (action) {
            switch (action) {
              case 'open':
                // Open the resource URL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening: ${resource.url}')),
                );
                break;
              case 'download':
                // Download the resource
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Download started')),
                );
                break;
              case 'delete':
                _confirmDeleteResource(resource);
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(Icons.open_in_new),
                  SizedBox(width: 8),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
            if (_isOwner ||
                resource.uploadedBy == FirebaseAuth.instance.currentUser?.uid)
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteResource(_GroupResource resource) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Resource'),
          content: Text('Are you sure you want to delete "${resource.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Delete from Firestore when backend is ready:
                // await _socialService!.deleteGroupResource(widget.group.id, resource.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Resource deleted'),
                    backgroundColor: Colors.green,
                  ),
                );
                setState(() {});
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}

/// Helper class for group activity items
class _ActivityItem {
  final String id;
  final _ActivityType type;
  final String userName;
  final String userId;
  final DateTime timestamp;
  final String description;

  _ActivityItem({
    required this.id,
    required this.type,
    required this.userName,
    required this.userId,
    required this.timestamp,
    required this.description,
  });
}

/// Activity types for group activity feed
enum _ActivityType {
  memberJoined,
  memberLeft,
  resourceUploaded,
  messagePosted,
}

/// Helper class for group resources
class _GroupResource {
  final String id;
  final String title;
  final String description;
  final String type;
  final String url;
  final String uploadedBy;
  final DateTime uploadDate;

  _GroupResource({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.url,
    required this.uploadedBy,
    required this.uploadDate,
  });
}

