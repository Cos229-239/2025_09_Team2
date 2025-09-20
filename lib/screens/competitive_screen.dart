import 'package:flutter/material.dart';
import '../services/competitive_learning_service.dart';
import '../widgets/competitive/competitive_widgets.dart';

/// Main competitive learning screen
class CompetitiveScreen extends StatefulWidget {
  const CompetitiveScreen({super.key});

  @override
  State<CompetitiveScreen> createState() => _CompetitiveScreenState();
}

class _CompetitiveScreenState extends State<CompetitiveScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  CompetitiveLearningService? _competitiveService;
  bool _isLoading = true;
  final String _currentUserId = 'current_user';

  CompetitionCategory _selectedCategory = CompetitionCategory.xpGained;
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.weekly;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeCompetitiveService();
  }

  Future<void> _initializeCompetitiveService() async {
    _competitiveService = CompetitiveLearningService();
    await _competitiveService!.initialize(_currentUserId);
    
    // Update user performance with mock data
    await _updateUserPerformance();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateUserPerformance() async {
    // Mock user performance data
    final userScores = {
      CompetitionCategory.studyTime: 180.0, // 3 hours
      CompetitionCategory.accuracy: 0.85, // 85%
      CompetitionCategory.streaks: 7.0, // 7 days
      CompetitionCategory.xpGained: 1250.0,
      CompetitionCategory.sessionsCompleted: 12.0,
      CompetitionCategory.questionsAnswered: 150.0,
      CompetitionCategory.subjectMastery: 3.0,
      CompetitionCategory.overallProgress: 75.0,
    };

    await _competitiveService!.updateUserPerformance(
      userId: _currentUserId,
      username: 'you',
      displayName: 'You',
      categoryScores: userScores,
    );

    // Generate peer comparisons with mock friends
    await _competitiveService!.generatePeerComparisons(
      userId: _currentUserId,
      friendIds: ['friend1', 'friend2', 'friend3'],
      userScores: userScores,
    );
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
        title: const Text('Competitive Learning'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboards'),
            Tab(icon: Icon(Icons.sports_score), text: 'Competitions'),
            Tab(icon: Icon(Icons.compare), text: 'Compare'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildLeaderboardsTab(),
          _buildCompetitionsTab(),
          _buildCompareTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _competitiveService!.getCompetitiveOverview(_currentUserId);
    final leaderboardSummary = _competitiveService!.getLeaderboardSummary(_currentUserId);

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
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rankings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
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
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => _tabController.animateTo(2),
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildActiveCompetitionsPreview(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickRankings(Map<String, dynamic> leaderboardSummary) {
    final weeklyRankings = leaderboardSummary['weekly'] as Map<String, dynamic>? ?? {};
    
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.5,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: [
        _buildRankCard('XP Gained', weeklyRankings['xpGained'] ?? 'N/A', Icons.star, Colors.amber),
        _buildRankCard('Study Time', weeklyRankings['studyTime'] ?? 'N/A', Icons.access_time, Colors.blue),
        _buildRankCard('Accuracy', weeklyRankings['accuracy'] ?? 'N/A', Icons.gps_fixed, Colors.green),
        _buildRankCard('Streaks', weeklyRankings['streaks'] ?? 'N/A', Icons.local_fire_department, Colors.red),
      ],
    );
  }

  Widget _buildRankCard(String title, dynamic rank, IconData icon, Color color) {
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
                  style: const TextStyle(fontSize: 10),
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
    final activeCompetitions = _competitiveService!.getActiveCompetitions();
    
    if (activeCompetitions.isEmpty) {
      return SizedBox(
        height: 100,
        child: const Center(
          child: Text('No active competitions'),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: activeCompetitions.length,
        itemBuilder: (context, index) {
          final competition = activeCompetitions[index];
          final isParticipating = competition.participants.contains(_currentUserId);
          
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 12),
            child: CompetitionCard(
              competition: competition,
              isParticipating: isParticipating,
              onJoin: () => _joinCompetition(competition.id),
              onViewDetails: () => _showCompetitionDetails(competition),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardsTab() {
    return Column(
      children: [
        // Category and Period Selectors
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<CompetitionCategory>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: CompetitionCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_getCategoryName(category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<LeaderboardPeriod>(
                  initialValue: _selectedPeriod,
                  decoration: const InputDecoration(
                    labelText: 'Period',
                    border: OutlineInputBorder(),
                  ),
                  items: LeaderboardPeriod.values.map((period) {
                    return DropdownMenuItem(
                      value: period,
                      child: Text(_getPeriodName(period)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPeriod = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        // Leaderboard
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LeaderboardWidget(
              entries: _competitiveService!.getLeaderboard(
                category: _selectedCategory,
                period: _selectedPeriod,
              ),
              currentUserId: _currentUserId,
              maxEntries: 50,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompetitionsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Active'),
              Tab(text: 'Upcoming'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildActiveCompetitions(),
                _buildUpcomingCompetitions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCompetitions() {
    final activeCompetitions = _competitiveService!.getActiveCompetitions();
    
    if (activeCompetitions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_score, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No active competitions'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeCompetitions.length,
      itemBuilder: (context, index) {
        final competition = activeCompetitions[index];
        final isParticipating = competition.participants.contains(_currentUserId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CompetitionCard(
            competition: competition,
            isParticipating: isParticipating,
            onJoin: () => _joinCompetition(competition.id),
            onViewDetails: () => _showCompetitionDetails(competition),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingCompetitions() {
    final upcomingCompetitions = _competitiveService!.getUpcomingCompetitions();
    
    if (upcomingCompetitions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.schedule, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No upcoming competitions'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: upcomingCompetitions.length,
      itemBuilder: (context, index) {
        final competition = upcomingCompetitions[index];
        final isParticipating = competition.participants.contains(_currentUserId);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CompetitionCard(
            competition: competition,
            isParticipating: isParticipating,
            onJoin: () => _joinCompetition(competition.id),
            onViewDetails: () => _showCompetitionDetails(competition),
          ),
        );
      },
    );
  }

  Widget _buildCompareTab() {
    final peerComparisons = _competitiveService!.getPeerComparisons(_currentUserId);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Peer Comparisons
          PeerComparisonWidget(
            comparisons: peerComparisons,
            friendNames: const {
              'friend1': 'Alex Chen',
              'friend2': 'Sarah Johnson',
              'friend3': 'Mike Rodriguez',
            },
          ),
          const SizedBox(height: 16),
          
          // Personal Best Rankings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Best Rankings',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildBestRankings(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBestRankings() {
    final stats = _competitiveService!.getCompetitiveOverview(_currentUserId);
    final bestRanks = stats['bestRanks'] as Map<String, int>? ?? {};
    
    if (bestRanks.isEmpty) {
      return const Text('No rankings yet');
    }
    
    return Column(
      children: bestRanks.entries.map((entry) {
        final categoryName = _getCategoryName(
          CompetitionCategory.values.firstWhere((e) => e.name == entry.key)
        );
        final rank = entry.value;
        
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: _getRankColor(rank),
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(categoryName),
          subtitle: const Text('Best rank achieved'),
          trailing: _getRankBadge(rank),
        );
      }).toList(),
    );
  }

  Widget _getRankBadge(int rank) {
    if (rank <= 3) {
      IconData icon;
      Color color;
      
      switch (rank) {
        case 1:
          icon = Icons.emoji_events;
          color = const Color(0xFFFFD700);
          break;
        case 2:
          icon = Icons.emoji_events;
          color = const Color(0xFFC0C0C0);
          break;
        case 3:
          icon = Icons.emoji_events;
          color = const Color(0xFFCD7F32);
          break;
        default:
          icon = Icons.star;
          color = Colors.grey;
      }
      
      return Icon(icon, color: color);
    }
    
    return const SizedBox();
  }

  Color _getRankColor(int rank) {
    if (rank <= 3) return Colors.amber;
    if (rank <= 10) return Colors.blue;
    if (rank <= 50) return Colors.green;
    return Colors.grey;
  }

  String _getCategoryName(CompetitionCategory category) {
    switch (category) {
      case CompetitionCategory.studyTime:
        return 'Study Time';
      case CompetitionCategory.accuracy:
        return 'Accuracy';
      case CompetitionCategory.streaks:
        return 'Streaks';
      case CompetitionCategory.xpGained:
        return 'XP Gained';
      case CompetitionCategory.sessionsCompleted:
        return 'Sessions';
      case CompetitionCategory.questionsAnswered:
        return 'Questions';
      case CompetitionCategory.subjectMastery:
        return 'Subject Mastery';
      case CompetitionCategory.overallProgress:
        return 'Progress';
    }
  }

  String _getPeriodName(LeaderboardPeriod period) {
    switch (period) {
      case LeaderboardPeriod.daily:
        return 'Daily';
      case LeaderboardPeriod.weekly:
        return 'Weekly';
      case LeaderboardPeriod.monthly:
        return 'Monthly';
      case LeaderboardPeriod.allTime:
        return 'All Time';
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    
    await _updateUserPerformance();
    
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _joinCompetition(String competitionId) async {
    final success = await _competitiveService!.joinCompetition(competitionId, _currentUserId);
    
    if (success) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined competition successfully!')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to join competition')),
      );
    }
  }

  void _showCompetitionDetails(Competition competition) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                competition.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(competition.description),
              const SizedBox(height: 16),
              Text(
                'Participants: ${competition.participants.length}/${competition.maxParticipants}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Start: ${_formatDateTime(competition.startDate)}',
              ),
              Text(
                'End: ${_formatDateTime(competition.endDate)}',
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}