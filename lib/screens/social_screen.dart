import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/social_learning_service.dart' as service;
import '../widgets/social/social_widgets.dart';
import '../widgets/sessions_tab.dart';
import '../providers/social_session_provider.dart';
import 'profile_settings_screen.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';
import 'group_details_screen.dart';

/// Main social learning screen with tabs for different social features
class SocialScreen extends StatefulWidget {
  const SocialScreen({super.key});

  @override
  State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  service.SocialLearningService? _socialService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSocialService();
  }

  Future<void> _initializeSocialService() async {
    _socialService = service.SocialLearningService();
    await _socialService!.initialize();

    // Initialize social session provider if available
    if (mounted) {
      final socialSessionProvider = Provider.of<SocialSessionProvider>(context, listen: false);
      await socialSessionProvider.initialize();
    }

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
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                    ...(_socialService!.pendingFriendRequests.take(3).map(
                          (request) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FriendRequestCard(
                              friendship: request,
                              onAccept: () => _acceptFriendRequest(request.id),
                              onDecline: () =>
                                  _declineFriendRequest(request.id),
                            ),
                          ),
                        )),
                    if (_socialService!.pendingFriendRequests.length > 3)
                      TextButton(
                        onPressed: () => _tabController.animateTo(1),
                        child: Text(
                            'View all ${_socialService!.pendingFriendRequests.length} requests'),
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
      {
        'type': 'group_created',
        'group': 'Mathematics Study Group',
        'time': '1 day ago'
      },
      {
        'type': 'session_completed',
        'session': 'Physics Review',
        'time': '2 days ago'
      },
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
        final mockProfile = service.UserProfile(
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
    final suggestedUsers = List.generate(
        10,
        (index) => service.UserProfile(
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
        final isJoined =
            _socialService!.myStudyGroups.any((g) => g.id == group.id);

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
    // Use our new comprehensive sessions tab with social session functionality
    return Consumer<SocialSessionProvider>(
      builder: (context, provider, child) {
        return const SessionsTab();
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
      case 3: // Sessions tab - handled by the SessionsTab widget itself
        return null; // The SessionsTab widget manages its own floating action button
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileSettingsScreen(),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => _SearchUsersDialog(socialService: _socialService!),
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Friend Request'),
        content: const Text(
          'Are you sure you want to decline this friend request? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _performDeclineFriendRequest(friendshipId);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeclineFriendRequest(String friendshipId) async {
    try {
      final success = await _socialService!.declineFriendRequest(friendshipId);
      
      if (mounted) {
        setState(() {}); // Refresh the UI
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Friend request declined'
                  : 'Failed to decline friend request',
            ),
            backgroundColor: success ? Colors.orange : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining friend request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddFriendDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddFriendDialog(socialService: _socialService!),
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

  void _showUserProfile(service.UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userProfile: profile,
          socialService: _socialService!,
        ),
      ),
    );
  }

  void _startChat(service.UserProfile profile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          otherUser: profile,
          socialService: _socialService!,
        ),
      ),
    );
  }

  // Group Methods
  void _createStudyGroup() {
    showDialog(
      context: context,
      builder: (context) => CreateStudyGroupDialog(),
    );
  }

  void _showGroupDetails(service.StudyGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailsScreen(group: group),
      ),
    );
  }

  Future<void> _joinGroup(service.StudyGroup group) async {
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

  // Session Methods - Now handled by SessionsTab widget
}

class _SearchUsersDialog extends StatefulWidget {
  final service.SocialLearningService socialService;

  const _SearchUsersDialog({
    required this.socialService,
  });

  @override
  State<_SearchUsersDialog> createState() => _SearchUsersDialogState();
}

class _SearchUsersDialogState extends State<_SearchUsersDialog> {
  final TextEditingController _searchController = TextEditingController();
  final List<service.UserProfile> _searchResults = [];
  bool _isSearching = false;
  String _searchFilter = 'all'; // all, friends, groups, interests

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Search Users',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username, display name, or interests...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
            
            const SizedBox(height: 16),
            
            // Search Filters
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Friends', 'friends'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Groups', 'groups'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Interests', 'interests'),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Search Results
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _searchFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _searchFilter = value;
        });
        _performSearch();
      },
    );
  }

  Widget _buildSearchResults() {
    if (_searchController.text.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Start typing to search for users',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchResults.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              child: Text(
                user.displayName.isNotEmpty 
                    ? user.displayName[0].toUpperCase()
                    : user.username[0].toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(user.displayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@${user.username}'),
                if (user.bio != null && user.bio!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      user.bio!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                if (user.interests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: user.interests.take(3).map((interest) => Chip(
                        label: Text(
                          interest,
                          style: const TextStyle(fontSize: 10),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      )).toList(),
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.person_add),
                  onPressed: () => _sendFriendRequest(user),
                  tooltip: 'Send Friend Request',
                ),
                IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => _viewProfile(user),
                  tooltip: 'View Profile',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _isSearching = true;
    });

    // Debounce the search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text == query) {
        _performSearch();
      }
    });
  }

  void _performSearch() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Mock search implementation
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        final query = _searchController.text.toLowerCase();
        final mockUsers = _generateMockSearchResults(query);
        
        setState(() {
          _searchResults.clear();
          _searchResults.addAll(mockUsers);
          _isSearching = false;
        });
      }
    });
  }

  List<service.UserProfile> _generateMockSearchResults(String query) {
    // Generate mock search results based on query
    final mockUsers = <service.UserProfile>[];
    
    if (query.contains('math') || query.contains('science') || query.contains('study')) {
      mockUsers.add(service.UserProfile(
        id: 'search_1',
        username: 'mathexpert2024',
        displayName: 'Alex Chen',
        bio: 'Mathematics enthusiast and tutor. Love helping others understand complex concepts!',
        joinDate: DateTime.now().subtract(const Duration(days: 180)),
        level: 15,
        totalXP: 2500,
        title: 'Math Wizard',
        interests: ['Mathematics', 'Physics', 'Teaching'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.friends,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: true,
        studyStats: {},
      ));
    }

    if (query.contains('prog') || query.contains('code') || query.contains('tech')) {
      mockUsers.add(service.UserProfile(
        id: 'search_2',
        username: 'codemaster',
        displayName: 'Sarah Johnson',
        bio: 'Full-stack developer and computer science student. Always learning new technologies.',
        joinDate: DateTime.now().subtract(const Duration(days: 90)),
        level: 12,
        totalXP: 1800,
        title: 'Code Ninja',
        interests: ['Programming', 'Web Development', 'AI'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.public,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 2)),
        studyStats: {},
      ));
    }

    if (query.contains('history') || query.contains('art') || query.contains('literature')) {
      mockUsers.add(service.UserProfile(
        id: 'search_3',
        username: 'historybuff',
        displayName: 'Michael Rodriguez',
        bio: 'History major with a passion for ancient civilizations and art history.',
        joinDate: DateTime.now().subtract(const Duration(days: 45)),
        level: 8,
        totalXP: 950,
        title: 'Time Traveler',
        interests: ['History', 'Art', 'Literature'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.friends,
        progressPrivacy: service.PrivacyLevel.friends,
        friendsPrivacy: service.PrivacyLevel.private,
        isOnline: true,
        studyStats: {},
      ));
    }

    // Always add a few general results
    if (mockUsers.length < 3) {
      mockUsers.add(service.UserProfile(
        id: 'search_general_1',
        username: 'studypal_${query.hashCode.abs()}',
        displayName: 'Study Buddy',
        bio: 'Looking for study partners and learning communities!',
        joinDate: DateTime.now().subtract(const Duration(days: 30)),
        level: 5,
        totalXP: 500,
        title: 'Beginner',
        interests: ['Learning', 'Growth', 'Collaboration'],
        achievements: {},
        profilePrivacy: service.PrivacyLevel.public,
        progressPrivacy: service.PrivacyLevel.friends,
        friendsPrivacy: service.PrivacyLevel.friends,
        isOnline: false,
        lastActive: DateTime.now().subtract(const Duration(hours: 8)),
        studyStats: {},
      ));
    }

    return mockUsers;
  }

  Future<void> _sendFriendRequest(service.UserProfile user) async {
    try {
      final success = await widget.socialService.sendFriendRequest(
        friendId: user.id,
        message: 'Hi! I found your profile through search. Would you like to be study partners?',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Friend request sent to ${user.displayName}!'
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
    }
  }

  void _viewProfile(service.UserProfile user) {
    Navigator.of(context).pop(); // Close search dialog
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(
          userProfile: user,
          socialService: widget.socialService,
        ),
      ),
    );
  }
}

class _AddFriendDialog extends StatefulWidget {
  final service.SocialLearningService socialService;

  const _AddFriendDialog({
    required this.socialService,
  });

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messageController.text = 'Hi! I\'d like to connect and study together. 📚';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.person_add),
          SizedBox(width: 8),
          Text('Add Friend'),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send a friend request to connect with other study partners.',
              style: TextStyle(color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username or Email',
                hintText: '@username or email@example.com',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a username or email';
                }
                
                final trimmed = value.trim();
                
                // Check for email format
                if (trimmed.contains('@')) {
                  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(trimmed)) {
                    return 'Please enter a valid email address';
                  }
                } else {
                  // Check username format
                  if (trimmed.startsWith('@')) {
                    final username = trimmed.substring(1);
                    if (username.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                  } else {
                    if (trimmed.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(trimmed)) {
                      return 'Username can only contain letters, numbers, and underscores';
                    }
                  }
                }
                
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Message (Optional)',
                hintText: 'Add a personal message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
              validator: (value) {
                if (value != null && value.length > 200) {
                  return 'Message cannot exceed 200 characters';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'The user will receive a notification about your friend request.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _sendFriendRequest,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Request'),
        ),
      ],
    );
  }

  Future<void> _sendFriendRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final input = _usernameController.text.trim();
      String friendId;
      
      // Convert username/email to user ID (in a real app, this would involve API calls)
      if (input.contains('@')) {
        // Email case - simulate finding user by email
        friendId = 'user_${input.hashCode.abs()}';
      } else {
        // Username case
        final username = input.startsWith('@') ? input.substring(1) : input;
        friendId = 'user_${username.hashCode.abs()}';
      }

      final success = await widget.socialService.sendFriendRequest(
        friendId: friendId,
        message: _messageController.text.trim().isEmpty
            ? 'Hi! I\'d like to connect and study together.'
            : _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Friend request sent successfully!'
                  : 'Failed to send friend request. User may not exist or request already sent.',
            ),
            backgroundColor: success ? Colors.green : Colors.orange,
            action: success
                ? null
                : SnackBarAction(
                    label: 'Search',
                    onPressed: () {
                      // Open search dialog to help find the user
                      showDialog(
                        context: context,
                        builder: (context) => _SearchUsersDialog(
                          socialService: widget.socialService,
                        ),
                      );
                    },
                  ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        
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
          _isLoading = false;
        });
      }
    }
  }
}

class CreateStudyGroupDialog extends StatefulWidget {
  const CreateStudyGroupDialog({super.key});

  @override
  State<CreateStudyGroupDialog> createState() => _CreateStudyGroupDialogState();
}

class _CreateStudyGroupDialogState extends State<CreateStudyGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedSubject = 'Mathematics';
  String _privacy = 'Public';
  int _maxMembers = 20;
  bool _allowInvites = true;
  bool _requireApproval = false;
  final List<String> _selectedTopics = [];

  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'History',
    'Literature',
    'Computer Science',
    'Languages',
    'Arts',
    'Business',
    'Medicine',
    'Engineering',
    'Psychology',
    'Philosophy',
    'Other'
  ];

  final List<String> _availableTopics = [
    'Exam Prep',
    'Homework Help',
    'Research Projects',
    'Discussion Groups',
    'Study Sessions',
    'Note Sharing',
    'Quiz Practice',
    'Peer Review',
    'Group Projects',
    'Tutoring'
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Create Study Group',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Group Name
                      Text(
                        'Group Name *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _groupNameController,
                        decoration: InputDecoration(
                          hintText: 'Enter group name...',
                          prefixIcon: Icon(Icons.group),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Group name is required';
                          }
                          if (value.trim().length < 3) {
                            return 'Group name must be at least 3 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Describe your study group...',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subject
                      Text(
                        'Subject *',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        decoration: InputDecoration(
                          prefixIcon: Icon(Icons.school),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSubject = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 20),

                      // Topics
                      Text(
                        'Study Topics',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableTopics.map((topic) {
                          final isSelected = _selectedTopics.contains(topic);
                          return FilterChip(
                            label: Text(topic),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedTopics.add(topic);
                                } else {
                                  _selectedTopics.remove(topic);
                                }
                              });
                            },
                            backgroundColor: isSelected 
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
                            selectedColor: Theme.of(context).colorScheme.primaryContainer,
                            checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Privacy Settings
                      Text(
                        'Privacy',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Public', label: Text('Public')),
                          ButtonSegment(value: 'Private', label: Text('Private')),
                        ],
                        selected: {_privacy},
                        onSelectionChanged: (selection) {
                          setState(() {
                            _privacy = selection.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Max Members
                      Text(
                        'Maximum Members: $_maxMembers',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Slider(
                        value: _maxMembers.toDouble(),
                        min: 2,
                        max: 100,
                        divisions: 98,
                        onChanged: (value) {
                          setState(() {
                            _maxMembers = value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Group Settings
                      SwitchListTile(
                        title: Text('Allow members to invite others'),
                        subtitle: Text('Members can send invitations to join the group'),
                        value: _allowInvites,
                        onChanged: (value) {
                          setState(() {
                            _allowInvites = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      SwitchListTile(
                        title: Text('Require approval to join'),
                        subtitle: Text('Admin approval needed for new members'),
                        value: _requireApproval,
                        onChanged: (value) {
                          setState(() {
                            _requireApproval = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _createGroup,
                  icon: Icon(Icons.add),
                  label: Text('Create Group'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show success and close dialog
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Study group "${_groupNameController.text}" created successfully!'),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
