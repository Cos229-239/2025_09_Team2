import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/social_learning_service.dart' as service;
import '../services/activity_service.dart';
import '../services/competitive_learning_service.dart';
import '../services/analytics_service.dart';
import '../models/activity.dart';
import '../widgets/social/social_widgets.dart';
import '../widgets/sessions_tab.dart';
import '../widgets/competitive/competitive_widgets.dart';
import '../providers/social_session_provider.dart';
import 'profile_settings_screen.dart';
import 'user_profile_screen.dart';
import 'chat_screen.dart';
import 'group_details_screen.dart';
import 'competitive_screen.dart';
import '../widgets/common/themed_background_wrapper.dart';

// TODO: Social Screen - Major Social Feature Implementation Gaps
// - Social learning service is completely placeholder-based
// - No real user authentication or profile management
// - Missing real-time friend status and presence indicators
// - No actual social matching algorithms or friend suggestions
// - Missing integration with study progress sharing
// - No real-time collaborative features
// - Missing social gamification and leaderboards
// - No content sharing or study resource exchange
// - Missing social notification system
// - No privacy controls or social settings
// - Missing social analytics and engagement tracking
// - No integration with external social platforms

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
  CompetitiveLearningService? _competitiveService;
  final ActivityService _activityService = ActivityService();
  final AnalyticsService _analyticsService = AnalyticsService();
  bool _isLoading = true;
  String _currentUserId = '';
  String _currentUsername = 'User';
  String _currentDisplayName = 'User';
  int _profileRefreshKey = 0; // Counter to force FutureBuilder refresh

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSocialService();
  }

  Future<void> _initializeSocialService() async {
    try {
      _socialService = service.SocialLearningService();
      await _socialService!.initialize();

      // Initialize social session provider if available
      if (mounted) {
        final socialSessionProvider =
            Provider.of<SocialSessionProvider>(context, listen: false);
        await socialSessionProvider.initialize();
      }

      // Create default profile if none exists AND user is authenticated
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _socialService!.currentUserProfile == null) {
        await _showProfileSetup();
      }

      // Initialize competitive service only if user is authenticated
      if (user != null) {
        await _initializeCompetitiveService();
      }
    } catch (e) {
      debugPrint('Error initializing social service: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _initializeCompetitiveService() async {
    try {
      // Get current user from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUserId = user.uid;
        _currentUsername = user.email?.split('@').first ?? 'user';
        _currentDisplayName = user.displayName ?? 'User';

        // Initialize competitive service
        _competitiveService = CompetitiveLearningService();
        await _competitiveService!.initialize(_currentUserId);

        // Load and update user performance from analytics
        await _updateUserPerformanceFromAnalytics();

        // Load friend comparisons
        await _loadFriendComparisons();
      }
    } catch (e) {
      debugPrint('Error initializing competitive service: $e');
    }
  }

  Future<void> _updateUserPerformanceFromAnalytics() async {
    try {
      // Get user analytics from Firebase
      final analytics = await _analyticsService.getUserAnalytics(_currentUserId);
      
      if (analytics != null && _competitiveService != null) {
        // Convert analytics data to competitive scores
        final analyticsData = {
          'totalStudyTimeMinutes': analytics.totalStudyTime.toDouble(),
          'averageAccuracy': analytics.overallAccuracy,
          'currentStreak': analytics.currentStreak.toDouble(),
          'totalXp': (analytics.totalCardsStudied * 10).toDouble(), // Estimate XP
          'sessionsCompleted': analytics.totalQuizzesTaken.toDouble(),
          'questionsAnswered': analytics.totalCardsStudied.toDouble(),
          'subjectsMastered': analytics.subjectPerformance.length.toDouble(),
          'overallProgress': (analytics.overallAccuracy * 100),
        };

        await _competitiveService!.updateScoresFromAnalytics(
          userId: _currentUserId,
          username: _currentUsername,
          displayName: _currentDisplayName,
          analyticsData: analyticsData,
        );
      }
    } catch (e) {
      debugPrint('Error updating user performance: $e');
    }
  }

  Future<void> _loadFriendComparisons() async {
    try {
      if (_competitiveService == null) return;
      
      // Get friend IDs from Firebase
      final friendIds = await _competitiveService!.getFriendIds(_currentUserId);

      if (friendIds.isNotEmpty) {
        // Get current user stats
        final userStats = _competitiveService!.userCompetitiveStats;
        if (userStats != null) {
          await _competitiveService!.generatePeerComparisons(
            userId: _currentUserId,
            friendIds: friendIds,
            userScores: userStats.categoryScores,
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading friend comparisons: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _competitiveService?.dispose();
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

    // Check if user is authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Social Learning'),
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 100,
                  color: Color(0xFF6FB8E9),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Login Required',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please log in to access social learning features and connect with other students.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Social Learning'),
          elevation: 0,
          backgroundColor: Colors.transparent,
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
              const Tab(icon: Icon(Icons.emoji_events), text: 'compete'),
              Tab(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.people),
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
                text: 'Friends',
              ),
              const Tab(icon: Icon(Icons.groups), text: 'Groups'),
              const Tab(icon: Icon(Icons.video_call), text: 'Sessions'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCompeteTab(),
            _buildFriendsTab(),
            _buildGroupsTab(),
            _buildSessionsTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildCompeteTab() {
    // Show loading or error state if competitive service is not ready
    if (_competitiveService == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading competitive features...'),
          ],
        ),
      );
    }

    final stats = _competitiveService!.getCompetitiveOverview(_currentUserId);
    final leaderboardSummary =
        _competitiveService!.getLeaderboardSummary(_currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Competitive Stats
          CompetitiveStatsWidget(stats: stats),
          const SizedBox(height: 16),

          // Quick Rankings
          Card(
            color: const Color(0xFF21262D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rankings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickRankings(leaderboardSummary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Active Competitions
          Card(
            color: const Color(0xFF21262D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Active Competitions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          // Navigate to full competitive screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CompetitiveScreen(),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(color: Color(0xFF58A6FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActiveCompetitionsPreview(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Recent Activity Section
          Card(
            color: const Color(0xFF21262D),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recent Activity',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.history,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
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

  Widget _buildQuickRankings(Map<String, dynamic> leaderboardSummary) {
    final weeklyRankings =
        leaderboardSummary['weekly'] as Map<String, dynamic>? ?? {};

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildRankCard('XP Gained', weeklyRankings['xpGained'] ?? 'N/A',
            Icons.star, Colors.amber),
        _buildRankCard('Study Time', weeklyRankings['studyTime'] ?? 'N/A',
            Icons.access_time, Colors.blue),
        _buildRankCard('Accuracy', weeklyRankings['accuracy'] ?? 'N/A',
            Icons.gps_fixed, Colors.green),
        _buildRankCard('Streaks', weeklyRankings['streaks'] ?? 'N/A',
            Icons.local_fire_department, Colors.red),
      ],
    );
  }

  Widget _buildRankCard(
      String title, dynamic rank, IconData icon, Color color) {
    final rankText = rank is int ? '#$rank' : rank.toString();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  rankText,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCompetitionsPreview() {
    if (_competitiveService == null) {
      return const Center(child: Text('Loading competitions...'));
    }

    final competitions = _competitiveService!.getActiveCompetitions();

    if (competitions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.emoji_events, size: 48, color: Colors.grey[600]),
              const SizedBox(height: 12),
              Text(
                'No active competitions',
                style: TextStyle(color: Colors.grey[400]),
              ),
              const SizedBox(height: 8),
              Text(
                'Check back later for new challenges!',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: competitions.take(3).map((competition) {
        return CompetitionCard(
          competition: competition,
          isParticipating: competition.participants.contains(_currentUserId),
          onViewDetails: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CompetitiveScreen(),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivity() {
    return StreamBuilder<List<Activity>>(
      stream: _activityService.watchRecentActivities(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF58A6FF)),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 32,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No recent activity',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final activities = snapshot.data!;

        return Column(
          children: activities.map((activity) {
            IconData icon;
            Color color;

            switch (activity.type) {
              case ActivityType.friendAdded:
                icon = Icons.person_add;
                color = Colors.green;
                break;
              case ActivityType.groupCreated:
              case ActivityType.groupJoined:
                icon = Icons.group_add;
                color = Colors.blue;
                break;
              case ActivityType.studySessionCompleted:
                icon = Icons.check_circle;
                color = Colors.purple;
                break;
              case ActivityType.quizCompleted:
                icon = Icons.quiz;
                color = Colors.orange;
                break;
              case ActivityType.achievementUnlocked:
                icon = Icons.emoji_events;
                color = Colors.amber;
                break;
              case ActivityType.levelUp:
                icon = Icons.trending_up;
                color = Colors.teal;
                break;
              case ActivityType.taskCompleted:
                icon = Icons.task_alt;
                color = Colors.indigo;
                break;
              default:
                icon = Icons.info;
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
                        Text(
                          activity.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.getTimeAgo(),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
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
      },
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

    return Column(
      children: [
        // Refresh button to clear cache and reload profiles
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () {
              // Clear all profile caches to force fresh data
              _socialService!.clearAllProfileCaches();
              setState(() {
                _profileRefreshKey++; // Increment to force new FutureBuilder instances
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Friend Profiles'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: friends.length,
            itemBuilder: (context, index) {
              final friendship = friends[index];
              
              // Determine the friend's ID (not the current user's ID)
              final currentUserId = _socialService!.currentUserProfile?.id;
              final friendId = friendship.userId == currentUserId 
                  ? friendship.friendId 
                  : friendship.userId;
              
              // Fetch the friend's actual profile
              // Using refresh key ensures FutureBuilder rebuilds when cache is cleared
              return FutureBuilder<service.UserProfile?>(
                key: ValueKey('friend_${friendId}_$_profileRefreshKey'),
                future: _socialService!.getUserProfile(friendId, forceRefresh: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    );
                  }
                  
                  final friendProfile = snapshot.data;
                  if (friendProfile == null) {
                    return const SizedBox.shrink();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: UserProfileCard(
                      profile: friendProfile,
                      onTap: () => _showUserProfile(friendProfile),
                      onMessageTap: () => _startChat(friendProfile),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFriendRequests() {
    final requests = _socialService!.pendingFriendRequests;

    return Column(
      children: [
        // Refresh button at the top
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              await _socialService!.refreshFriendships();
              setState(() {}); // Rebuild UI after refresh
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Friend Requests'),
          ),
        ),
        Expanded(
          child: requests.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No friend requests'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    // Fetch the requester's profile
                    return FutureBuilder<service.UserProfile?>(
                      future: _socialService!.getUserProfile(request.userId),
                      builder: (context, snapshot) {
                        // Show loading indicator while fetching
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FriendRequestCard(
                              friendship: request,
                              requesterProfile: null, // Will show "Unknown User" while loading
                              onAccept: () => _acceptFriendRequest(request.id),
                              onDecline: () => _declineFriendRequest(request.id),
                            ),
                          );
                        }
                        
                        // Show error state if fetch failed
                        if (snapshot.hasError) {
                          debugPrint('Error loading profile for ${request.userId}: ${snapshot.error}');
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: FriendRequestCard(
                            friendship: request,
                            requesterProfile: snapshot.data,
                            onAccept: () => _acceptFriendRequest(request.id),
                            onDecline: () => _declineFriendRequest(request.id),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFindPeople() {
    return FutureBuilder<List<service.UserProfile>>(
      future:
          _socialService?.getUsersForDiscovery(limit: 20) ?? Future.value([]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Finding StudyPal users...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load users',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger a rebuild to retry
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Be the first to invite friends to StudyPals!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
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
    return FutureBuilder<List<service.StudyGroup>>(
      future: _socialService!.getPublicStudyGroupsForDiscovery(limit: 50),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading groups: ${snapshot.error}'),
              ],
            ),
          );
        }
        
        final groups = snapshot.data ?? [];
        
        if (groups.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.groups, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No public groups available'),
                Text('Be the first to create one!'),
              ],
            ),
          );
        }

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
  void _createStudyGroup() async {
    await showDialog(
      context: context,
      builder: (context) => CreateStudyGroupDialog(socialService: _socialService!),
    );
    
    // Refresh the UI after the dialog closes to show the new group
    setState(() {});
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
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                if (user.interests.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Wrap(
                      spacing: 4,
                      children: user.interests
                          .take(3)
                          .map((interest) => Chip(
                                label: Text(
                                  interest,
                                  style: const TextStyle(fontSize: 10),
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ))
                          .toList(),
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

    if (query.contains('math') ||
        query.contains('science') ||
        query.contains('study')) {
      mockUsers.add(service.UserProfile(
        id: 'search_1',
        username: 'mathexpert2024',
        displayName: 'Alex Chen',
        bio:
            'Mathematics enthusiast and tutor. Love helping others understand complex concepts!',
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

    if (query.contains('prog') ||
        query.contains('code') ||
        query.contains('tech')) {
      mockUsers.add(service.UserProfile(
        id: 'search_2',
        username: 'codemaster',
        displayName: 'Sarah Johnson',
        bio:
            'Full-stack developer and computer science student. Always learning new technologies.',
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

    if (query.contains('history') ||
        query.contains('art') ||
        query.contains('literature')) {
      mockUsers.add(service.UserProfile(
        id: 'search_3',
        username: 'historybuff',
        displayName: 'Michael Rodriguez',
        bio:
            'History major with a passion for ancient civilizations and art history.',
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
        message:
            'Hi! I found your profile through search. Would you like to be study partners?',
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
  final service.SocialLearningService socialService;
  
  const CreateStudyGroupDialog({
    super.key,
    required this.socialService,
  });

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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            checkmarkColor: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 20),

                      // Privacy Settings
                      Text(
                        'Privacy',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'Public', label: Text('Public')),
                          ButtonSegment(
                              value: 'Private', label: Text('Private')),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                        subtitle: Text(
                            'Members can send invitations to join the group'),
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

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Create the study group using the provided social service
      final group = await widget.socialService.createStudyGroup(
        name: _groupNameController.text,
        description: _descriptionController.text,
        subjects: [_selectedSubject, ..._selectedTopics],
        maxMembers: _maxMembers,
        isPrivate: _privacy == 'Private',
      );

      if (!mounted) return;

      if (group != null) {
        // Show success and close dialog
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                      'Study group "${_groupNameController.text}" created successfully!'),
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
      } else {
        // Failed to create group
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create study group'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error creating study group in UI: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating study group: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
