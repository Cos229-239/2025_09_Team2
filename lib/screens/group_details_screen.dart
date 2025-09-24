import 'package:flutter/material.dart';
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
  bool _hasRequestedToJoin = false;
  List<service.UserProfile> _members = [];
  List<service.UserProfile> _pendingRequests = [];
  service.SocialLearningService? _socialService;

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
    // Simulate loading group data
    await Future.delayed(const Duration(seconds: 1));
    
    // Mock data - in a real app, this would come from the service
    _members = [
      service.UserProfile(
        id: '1',
        username: 'alex_study',
        displayName: 'Alex Johnson',
        bio: 'Math enthusiast and study group leader',
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
        level: 5,
        totalXP: 1250,
        title: 'Study Group Leader',
        interests: ['Mathematics', 'Calculus'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.public,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: true,
        studyStats: {},
      ),
      service.UserProfile(
        id: '2',
        username: 'sarah_math',
        displayName: 'Sarah Chen',
        bio: 'Engineering student passionate about learning',
        joinDate: DateTime.now().subtract(const Duration(days: 15)),
        level: 3,
        totalXP: 750,
        title: 'Active Learner',
        interests: ['Engineering', 'Mathematics'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.friends,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: false,
        studyStats: {},
      ),
      service.UserProfile(
        id: '3',
        username: 'mike_tutor',
        displayName: 'Mike Rodriguez',
        bio: 'Tutor and study companion',
        joinDate: DateTime.now().subtract(const Duration(days: 45)),
        level: 7,
        totalXP: 2100,
        title: 'Tutor Master',
        interests: ['Mathematics', 'Teaching'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.public,
        friendsPrivacy: service.PrivacyLevel.public,
        isOnline: true,
        studyStats: {},
      ),
    ];

    _pendingRequests = [
      service.UserProfile(
        id: '4',
        username: 'jen_student',
        displayName: 'Jennifer Lee',
        bio: 'Aspiring mathematician',
        joinDate: DateTime.now().subtract(const Duration(days: 5)),
        level: 2,
        totalXP: 300,
        title: 'New Student',
        interests: ['Mathematics'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.friends,
        progressPrivacy: service.PrivacyLevel.private,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: false,
        studyStats: {},
      ),
    ];

    _isMember = widget.group.members.any((member) => member.userId == 'current_user_id');
    
    setState(() {
      _isLoading = false;
    });
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
                const PopupMenuItem(
                  value: 'leave',
                  child: ListTile(
                    leading: Icon(Icons.exit_to_app, color: Colors.red),
                    title: Text('Leave Group', style: TextStyle(color: Colors.red)),
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
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.group.subjects.isNotEmpty ? widget.group.subjects.first : 'General',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.people,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${_members.length}/${widget.group.maxMembers} members',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                                    color: widget.group.isPrivate ? Colors.orange[700] : Colors.green[700],
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
                      color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.9),
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
    final isAdmin = user.id == widget.group.ownerId;
    
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
              child: Text('Remove from Group', style: TextStyle(color: Colors.red)),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildActivityItem(
          icon: Icons.person_add,
          title: 'Sarah Chen joined the group',
          time: '2 hours ago',
          color: Colors.green,
        ),
        _buildActivityItem(
          icon: Icons.message,
          title: 'New message in group chat',
          time: '5 hours ago',
          color: Colors.blue,
        ),
        _buildActivityItem(
          icon: Icons.upload_file,
          title: 'Mike uploaded study materials',
          time: '1 day ago',
          color: Colors.orange,
        ),
        _buildActivityItem(
          icon: Icons.event,
          title: 'Study session scheduled',
          time: '2 days ago',
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String time,
    required Color color,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(time),
    );
  }

  Widget _buildResourcesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: Icon(Icons.picture_as_pdf, color: Colors.red),
          title: Text('Calculus Study Guide'),
          subtitle: Text('Uploaded by Alex Johnson • 2.3 MB'),
          trailing: IconButton(
            onPressed: () {},
            icon: Icon(Icons.download),
          ),
        ),
        ListTile(
          leading: Icon(Icons.video_library, color: Colors.blue),
          title: Text('Lecture Recording - Derivatives'),
          subtitle: Text('Shared by Sarah Chen • 45 min'),
          trailing: IconButton(
            onPressed: () {},
            icon: Icon(Icons.play_arrow),
          ),
        ),
        ListTile(
          leading: Icon(Icons.link, color: Colors.green),
          title: Text('Khan Academy - Calculus'),
          subtitle: Text('External resource • khanacademy.org'),
          trailing: IconButton(
            onPressed: () {},
            icon: Icon(Icons.open_in_new),
          ),
        ),
        const SizedBox(height: 16),
        if (_isMember)
          ElevatedButton.icon(
            onPressed: _uploadResource,
            icon: Icon(Icons.upload),
            label: Text('Upload Resource'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
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

  void _handlePendingRequest(service.UserProfile user, bool accept) {
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
  }

  void _joinGroup() async {
    // For simplicity, assume private groups require approval
    if (widget.group.isPrivate) {
      setState(() {
        _hasRequestedToJoin = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Join request sent! Waiting for approval.'),
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
    }
  }

  void _showInviteDialog() {
    // Implementation for inviting friends
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invite friends feature coming soon!')),
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
