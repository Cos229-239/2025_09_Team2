import 'package:flutter/material.dart';
import '../services/social_learning_service.dart';
import '../widgets/social/social_widgets.dart';

/// Main social learning screen with tabs for different social features
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SocialLearningService? _socialService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSocialService();
  }

  Future<void> _initializeSocialService() async {
    _socialService = SocialLearningService();
    await _socialService!.initialize();
    
    // Create default profile if none exists
    if (_socialService!.currentUserProfile == null) {
      await _showProfileSetup();
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Learning'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showProfileSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.dashboard),
                  if (_socialService!.pendingFriendRequests.isNotEmpty)
                    Positioned(
                      right: -6,
                      top: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_socialService!.pendingFriendRequests.length}',
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
              ),
              text: 'Overview',
            ),
            const Tab(icon: Icon(Icons.people), text: 'Friends'),
            const Tab(icon: Icon(Icons.groups), text: 'Groups'),
            const Tab(icon: Icon(Icons.video_call), text: 'Sessions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildFriendsTab(),
          _buildGroupsTab(),
          _buildSessionsTab(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildOverviewTab() {
    final profile = _socialService!.currentUserProfile!;
    final stats = _socialService!.getSocialStats();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Profile Card
          UserProfileCard(
            profile: profile,
            isCurrentUser: true,
            onTap: _showProfileSettings,
          ),
          const SizedBox(height: 16),

          // Social Stats
          SocialStatsWidget(stats: stats),
          const SizedBox(height: 16),

          // Friend Requests Section
          if (_socialService!.pendingFriendRequests.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Friend Requests',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_socialService!.pendingFriendRequests.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(_socialService!.pendingFriendRequests.take(3).map((request) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FriendRequestCard(
                          friendship: request,
                          onAccept: () => _acceptFriendRequest(request.id),
                          onDecline: () => _declineFriendRequest(request.id),
                        ),
                      ),
                    )),
                    if (_socialService!.pendingFriendRequests.length > 3)
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: Text('View all ${_socialService!.pendingFriendRequests.length} requests'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recent Activity
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivity(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    // Mock recent activity - in a real app, this would come from a service
    final activities = [
      {'type': 'friend_joined', 'user': 'Alex Chen', 'time': '2 hours ago'},
      {'type': 'group_created', 'group': 'Mathematics Study Group', 'time': '1 day ago'},
      {'type': 'session_completed', 'session': 'Physics Review', 'time': '2 days ago'},
    ];

    if (activities.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No recent activity'),
        ),
      );
    }

    return Column(
      children: activities.map((activity) {
        IconData icon;
        String description;
        Color color;
        
        switch (activity['type']) {
          case 'friend_joined':
            icon = Icons.person_add;
            description = '${activity['user']} joined your friends';
            color = Colors.green;
            break;
          case 'group_created':
            icon = Icons.group_add;
            description = 'You created "${activity['group']}"';
            color = Colors.blue;
            break;
          case 'session_completed':
            icon = Icons.check_circle;
            description = 'Completed study session "${activity['session']}"';
            color = Colors.purple;
            break;
          default:
            icon = Icons.info;
            description = 'Unknown activity';
            color = Colors.grey;
        }
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: color.withValues(alpha: 0.2),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(description),
                    Text(
                      activity['time']!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFriendsTab() {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Friends'),
              Tab(text: 'Requests'),
              Tab(text: 'Find People'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFriendsList(),
                _buildFriendRequests(),
                _buildFindPeople(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsList() {
    final friends = _socialService!.friends;
    
    if (friends.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No friends yet'),
            Text('Start by sending friend requests!'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friendship = friends[index];
        // In a real app, you'd fetch the friend's profile
        final mockProfile = UserProfile(
          id: friendship.friendId,
          username: 'user${friendship.friendId}',
          displayName: 'Friend ${friendship.friendId}',
          joinDate: DateTime.now().subtract(const Duration(days: 30)),
          level: 15,
          totalXP: 2500,
          title: 'Intermediate',
          interests: ['Math', 'Science'],
          isOnline: index % 3 == 0,
        );
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UserProfileCard(
            profile: mockProfile,
            onTap: () => _showUserProfile(mockProfile),
            onMessageTap: () => _startChat(mockProfile),
          ),
        );
      },
    );
  }

  Widget _buildFriendRequests() {
    final requests = _socialService!.pendingFriendRequests;
    
    if (requests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No friend requests'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FriendRequestCard(
            friendship: request,
            onAccept: () => _acceptFriendRequest(request.id),
            onDecline: () => _declineFriendRequest(request.id),
          ),
        );
      },
    );
  }

  Widget _buildFindPeople() {
    // Mock suggested users
    final suggestedUsers = List.generate(10, (index) => UserProfile(
      id: 'suggested_$index',
      username: 'user_$index',
      displayName: 'User ${index + 1}',
      bio: 'Love studying and learning new things!',
      joinDate: DateTime.now().subtract(Duration(days: index * 10)),
      level: 10 + index,
      totalXP: 1000 + (index * 200),
      title: index > 5 ? 'Advanced' : 'Intermediate',
      interests: ['Math', 'Science', 'History'][index % 3] == 'Math' 
          ? ['Math', 'Physics'] 
          : ['Science', 'Biology'],
    ));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: suggestedUsers.length,
      itemBuilder: (context, index) {
        final user = suggestedUsers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: UserProfileCard(
            profile: user,
            onTap: () => _showUserProfile(user),
            onAddFriendTap: () => _sendFriendRequest(user.id),
          ),
        );
      },
    );
  }

  Widget _buildGroupsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'My Groups'),
              Tab(text: 'Discover'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMyGroups(),
                _buildDiscoverGroups(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyGroups() {
    final groups = _socialService!.myStudyGroups;
    
    if (groups.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.groups, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No study groups yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _createStudyGroup,
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudyGroupCard(
            group: group,
            isJoined: true,
            showJoinButton: false,
            onTap: () => _showGroupDetails(group),
          ),
        );
      },
    );
  }

  Widget _buildDiscoverGroups() {
    final groups = _socialService!.publicStudyGroups;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        final isJoined = _socialService!.myStudyGroups.any((g) => g.id == group.id);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: StudyGroupCard(
            group: group,
            isJoined: isJoined,
            onTap: () => _showGroupDetails(group),
            onJoin: () => _joinGroup(group),
          ),
        );
      },
    );
  }

  Widget _buildSessionsTab() {
    final sessions = _socialService!.myCollaborativeSessions;
    
    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.video_call, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No study sessions yet'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _scheduleSession,
              icon: const Icon(Icons.add),
              label: const Text('Schedule Session'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: CollaborativeSessionCard(
            session: session,
            canJoin: true,
            onTap: () => _showSessionDetails(session),
            onJoin: () => _joinSession(session),
          ),
        );
      },
    );
  }

  Widget? _buildFloatingActionButton() {
    switch (_tabController.index) {
      case 1: // Friends tab
        return FloatingActionButton(
          onPressed: _showAddFriendDialog,
          child: const Icon(Icons.person_add),
        );
      case 2: // Groups tab
        return FloatingActionButton(
          onPressed: _createStudyGroup,
          child: const Icon(Icons.group_add),
        );
      case 3: // Sessions tab
        return FloatingActionButton(
          onPressed: _scheduleSession,
          child: const Icon(Icons.video_call),
        );
      default:
        return null;
    }
  }

  // Profile and Settings Methods
  Future<void> _showProfileSetup() async {
    // In a real app, this would show a proper profile setup dialog
    await _socialService!.createUserProfile(
      username: 'user_${DateTime.now().millisecondsSinceEpoch}',
      displayName: 'Study Pal',
      bio: 'Ready to learn and grow!',
      interests: ['Learning', 'Growth'],
    );
  }

  void _showProfileSettings() {
    // TODO: Implement profile settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile settings - Coming soon!')),
    );
  }

  void _showSearchDialog() {
    // TODO: Implement search functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Search - Coming soon!')),
    );
  }

  // Friend Methods
  Future<void> _acceptFriendRequest(String friendshipId) async {
    final success = await _socialService!.acceptFriendRequest(friendshipId);
    if (success) {
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request accepted!')),
        );
      }
    }
  }

  void _declineFriendRequest(String friendshipId) {
    // TODO: Implement decline functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Friend request declined')),
    );
  }

  void _showAddFriendDialog() {
    // TODO: Implement add friend dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add friend - Coming soon!')),
    );
  }

  Future<void> _sendFriendRequest(String userId) async {
    final success = await _socialService!.sendFriendRequest(
      friendId: userId,
      message: 'Let\'s study together!',
    );
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request sent!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send friend request')),
        );
      }
    }
  }

  void _showUserProfile(UserProfile profile) {
    // TODO: Implement user profile view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${profile.displayName}\'s profile')),
    );
  }

  void _startChat(UserProfile profile) {
    // TODO: Implement chat functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Starting chat with ${profile.displayName}')),
    );
  }

  // Group Methods
  void _createStudyGroup() {
    // TODO: Implement create study group dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create study group - Coming soon!')),
    );
  }

  void _showGroupDetails(StudyGroup group) {
    // TODO: Implement group details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${group.name} details')),
    );
  }

  Future<void> _joinGroup(StudyGroup group) async {
    final success = await _socialService!.joinStudyGroup(groupId: group.id);
    if (success) {
      setState(() {});
    }
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined ${group.name}!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join group')),
        );
      }
    }
  }

  // Session Methods
  void _scheduleSession() {
    // TODO: Implement schedule session dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Schedule session - Coming soon!')),
    );
  }

  void _showSessionDetails(CollaborativeSession session) {
    // TODO: Implement session details view
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing ${session.name} details')),
    );
  }

  void _joinSession(CollaborativeSession session) {
    // TODO: Implement join session functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining ${session.name}')),
    );
  }
}