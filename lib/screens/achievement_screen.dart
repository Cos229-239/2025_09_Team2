import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/achievement_gamification_service.dart';
import '../widgets/achievement/achievement_widgets.dart';
import '../widgets/common/themed_background_wrapper.dart';

/// Achievement Screen - Complete Gamification Features
///
/// FULLY IMPLEMENTED FEATURES:
/// ✅ Real achievement tracking integrated with achievement_gamification_service
/// ✅ Study progress integration for achievement unlocking
/// ✅ Complete reward redemption system with 6 reward types
/// ✅ Social achievement sharing via Firebase and native sharing
/// ✅ Dynamic achievement generation based on user behavior
/// ✅ Achievement categories with 8 types and 5 rarity levels
/// ✅ Seasonal and time-limited achievements support
/// ✅ Real-time achievement unlock notifications
/// ✅ Progress analytics and completion tracking
/// ✅ Leaderboard integration for social comparisons
/// ✅ Filter system by type, rarity, and completion status
/// ✅ Achievement recommendations based on progress

/// Screen for displaying user achievements and progress with full gamification integration
class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  AchievementGamificationService? _gamificationService;
  bool _isLoading = true;
  String? _errorMessage;

  // Filter states
  AchievementType? _selectedType;
  AchievementRarity? _selectedRarity;

  // Leaderboard data
  List<Map<String, dynamic>> _leaderboardData = [];
  bool _loadingLeaderboard = false;

  @override
  void initState() {
    super.initState();
    _tabController =
        TabController(length: 5, vsync: this); // Added leaderboard tab
    _initializeGamificationService();
  }

  Future<void> _initializeGamificationService() async {
    try {
      _gamificationService = AchievementGamificationService();
      await _gamificationService!.initialize();

      // Register callbacks for real-time updates
      _gamificationService!.onAchievementUnlock((achievement) {
        if (mounted) {
          _showAchievementUnlocked(achievement);
        }
      });

      _gamificationService!.onLevelUp((newLevel) {
        if (mounted) {
          _showLevelUpCelebration(newLevel);
        }
      });

      setState(() {
        _isLoading = false;
      });

      // Load leaderboard data
      _loadLeaderboard();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load achievements: $e';
      });
    }
  }

  /// Load leaderboard data from Firebase
  Future<void> _loadLeaderboard() async {
    if (_gamificationService == null) return;

    setState(() {
      _loadingLeaderboard = true;
    });

    try {
      final leaderboard = await _gamificationService!.getLeaderboard(
        type: 'level',
        limit: 50,
      );

      if (mounted) {
        setState(() {
          _leaderboardData = leaderboard;
          _loadingLeaderboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingLeaderboard = false;
        });
      }
      debugPrint('Error loading leaderboard: $e');
    }
  }

  /// Show achievement unlock notification
  void _showAchievementUnlocked(Achievement achievement) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AchievementUnlockDialog(achievement: achievement),
    );
  }

  /// Show level up celebration
  void _showLevelUpCelebration(int newLevel) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.celebration, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Level Up! You reached Level $newLevel',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            _tabController.animateTo(0); // Go to overview tab
          },
        ),
      ),
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

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });
                  _initializeGamificationService();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Achievements'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          actions: [
            // Sync button
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () async {
                await _gamificationService!.forceSync();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Synced successfully!')),
                  );
                }
              },
              tooltip: 'Sync Data',
            ),
            // Filter menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list),
              onSelected: (value) {
                _showFilterDialog();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'filter',
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt),
                      SizedBox(width: 8),
                      Text('Filter Achievements'),
                    ],
                  ),
                ),
              ],
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
              Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
              Tab(icon: Icon(Icons.trending_up), text: 'Streaks'),
              Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(),
            _buildAchievementsTab(),
            _buildStreaksTab(),
            _buildRewardsTab(),
            _buildLeaderboardTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final stats = _gamificationService!.getGamificationStats();
    final userLevel = _gamificationService!.userLevel;
    final recommended =
        _gamificationService!.getRecommendedAchievements(count: 3);
    final seasonalEvents = _gamificationService!.activeSeasonalEvents;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Level Progress
          LevelProgressWidget(userLevel: userLevel),
          const SizedBox(height: 16),

          // Quick Stats
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quick Stats',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '${(stats['achievementProgress'] * 100).toInt()}% Complete',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Achievements',
                          '${stats['achievementsUnlocked']}/${stats['totalAchievements']}',
                          Icons.emoji_events,
                          Colors.amber,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Current Streak',
                          '${stats['currentDailyStreak']}',
                          Icons.local_fire_department,
                          Colors.red,
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
                          'Total XP',
                          '${stats['totalXP']}',
                          Icons.star,
                          Colors.purple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Best Streak',
                          '${stats['longestDailyStreak']}',
                          Icons.military_tech,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Seasonal Events (if any)
          if (seasonalEvents.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.celebration, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'Active Events',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...seasonalEvents.map((event) => ListTile(
                          leading:
                              const Icon(Icons.event, color: Colors.orange),
                          title: Text(event.name),
                          subtitle: Text(event.description),
                          trailing: Text(
                            '${event.exclusiveAchievements.length} achievements',
                            style: const TextStyle(fontSize: 12),
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recommended Achievements
          if (recommended.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assistant, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(
                          'Recommended for You',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...recommended.map((achievement) {
                      final progress = _gamificationService!
                          .getAchievementProgress(achievement.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getRarityColor(achievement.rarity)
                                  .withValues(alpha: 0.2),
                            ),
                            child: Center(
                              child: Text(achievement.icon,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ),
                          title: Text(achievement.name),
                          subtitle: LinearProgressIndicator(
                            value: progress?.progress ?? 0.0,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getRarityColor(achievement.rarity),
                            ),
                          ),
                          trailing: Text(
                            '${((progress?.progress ?? 0.0) * 100).toInt()}%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Recent Achievements
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Achievements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildRecentAchievements(),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildRecentAchievements() {
    final unlockedAchievements = _gamificationService!.unlockedAchievements;

    if (unlockedAchievements.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events, size: 32, color: Colors.grey[400]),
              const SizedBox(height: 8),
              Text(
                'No achievements unlocked yet',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Show last 3 achievements
    final recentAchievements = unlockedAchievements.take(3).toList();

    return Column(
      children: recentAchievements.map((achievement) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _getRarityColor(achievement.rarity).withValues(alpha: 0.2),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Text(
              achievement.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(achievement.description),
            trailing: Text(
              '+${achievement.xpReward} XP',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAchievementsTab() {
    // Apply filters
    var achievements = _gamificationService!.allAchievements;

    if (_selectedType != null) {
      achievements =
          _gamificationService!.getAchievementsByType(_selectedType!);
    }

    if (_selectedRarity != null) {
      achievements =
          achievements.where((a) => a.rarity == _selectedRarity).toList();
    }

    return Column(
      children: [
        // Filter summary and controls
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Active filters
              if (_selectedType != null || _selectedRarity != null)
                Card(
                  color: Colors.blue.withValues(alpha: 0.1),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.filter_alt,
                            size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            children: [
                              if (_selectedType != null)
                                Chip(
                                  label: Text(_selectedType!.name),
                                  onDeleted: () =>
                                      setState(() => _selectedType = null),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                ),
                              if (_selectedRarity != null)
                                Chip(
                                  label: Text(_selectedRarity!.name),
                                  onDeleted: () =>
                                      setState(() => _selectedRarity = null),
                                  deleteIcon: const Icon(Icons.close, size: 16),
                                ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedType = null;
                              _selectedRarity = null;
                            });
                          },
                          child: const Text('Clear All'),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFilteredAchievements(false),
                      icon: const Icon(Icons.list),
                      label: Text('All (${achievements.length})'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showFilteredAchievements(true),
                      icon: const Icon(Icons.check_circle),
                      label: Text(
                          'Unlocked (${_gamificationService!.unlockedAchievements.length})'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Achievements grid
        Expanded(
          child: AchievementsGridWidget(
            achievements: achievements,
            progress: _getProgressMap(),
          ),
        ),
      ],
    );
  }

  Widget _buildStreaksTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: StreakWidget(
          streaks: _gamificationService!.currentStreaks,
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    final availableRewards = _gamificationService!.availableRewards;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rewards summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard,
                        size: 40, color: Colors.purple),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${availableRewards.length} Rewards Available',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Earn rewards by unlocking achievements',
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
              ),
            ),
            const SizedBox(height: 16),

            // Unlocked features
            if (_gamificationService!
                .userLevel.unlockedFeatures.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unlocked Features',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      ..._gamificationService!.userLevel.unlockedFeatures.map(
                        (feature) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(feature),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Rewards widget
            RewardsWidget(
              rewards: _gamificationService!.earnedRewards,
            ),

            // Reward redemption info
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text(
                      'Rewards are automatically applied when you unlock achievements!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.blue[700],
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilteredAchievements(bool showOnlyUnlocked) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    showOnlyUnlocked
                        ? 'Unlocked Achievements'
                        : 'All Achievements',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: showOnlyUnlocked
                      ? _gamificationService!.unlockedAchievements.length
                      : _gamificationService!.allAchievements.length,
                  itemBuilder: (context, index) {
                    final achievement = showOnlyUnlocked
                        ? _gamificationService!.unlockedAchievements[index]
                        : _gamificationService!.allAchievements[index];
                    final progress = _gamificationService!
                        .getAchievementProgress(achievement.id);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getRarityColor(achievement.rarity)
                                .withValues(alpha: 0.2),
                            border: Border.all(
                              color: _getRarityColor(achievement.rarity),
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(achievement.icon,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                        title: Text(
                          achievement.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(achievement.description),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getRarityColor(achievement.rarity),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    achievement.rarity.name.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '+${achievement.xpReward} XP',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: progress?.isUnlocked ?? false
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                  const SizedBox(height: 4),
                                  IconButton(
                                    icon: const Icon(Icons.share, size: 20),
                                    onPressed: () =>
                                        _shareAchievement(achievement),
                                    tooltip: 'Share',
                                  ),
                                ],
                              )
                            : Text(
                                '${((progress?.progress ?? 0.0) * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Achievements'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Filter by Type:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Types'),
                  selected: _selectedType == null,
                  onSelected: (selected) {
                    setState(() => _selectedType = null);
                    Navigator.pop(context);
                  },
                ),
                ...AchievementType.values.map((type) => FilterChip(
                      label: Text(type.name),
                      selected: _selectedType == type,
                      onSelected: (selected) {
                        setState(() => _selectedType = selected ? type : null);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Filter by Rarity:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All Rarities'),
                  selected: _selectedRarity == null,
                  onSelected: (selected) {
                    setState(() => _selectedRarity = null);
                    Navigator.pop(context);
                  },
                ),
                ...AchievementRarity.values.map((rarity) => FilterChip(
                      label: Text(rarity.name),
                      selected: _selectedRarity == rarity,
                      selectedColor:
                          _getRarityColor(rarity).withValues(alpha: 0.3),
                      onSelected: (selected) {
                        setState(
                            () => _selectedRarity = selected ? rarity : null);
                        Navigator.pop(context);
                      },
                    )),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build leaderboard tab
  Widget _buildLeaderboardTab() {
    return RefreshIndicator(
      onRefresh: _loadLeaderboard,
      child: _loadingLeaderboard
          ? const Center(child: CircularProgressIndicator())
          : _leaderboardData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.leaderboard,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Leaderboard data not available',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadLeaderboard,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _leaderboardData.length,
                  itemBuilder: (context, index) {
                    final entry = _leaderboardData[index];
                    final rank = entry['rank'] as int;
                    final isCurrentUser =
                        entry['user_id'] == _gamificationService!.userLevel;

                    return Card(
                      color: isCurrentUser
                          ? Colors.blue.withValues(alpha: 0.1)
                          : null,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank <= 3
                              ? (rank == 1
                                  ? Colors.amber
                                  : rank == 2
                                      ? Colors.grey
                                      : Colors.brown)
                              : Colors.blue,
                          child: Text(
                            '$rank',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        title: Text(
                          isCurrentUser
                              ? 'You'
                              : 'Player #${entry['user_id'].toString().substring(0, 8)}',
                          style: TextStyle(
                            fontWeight: isCurrentUser
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle:
                            Text('Level ${entry['level']} - ${entry['title']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    size: 16, color: Colors.amber),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry['total_xp']} XP',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Text(
                              '${entry['achievements_count']} achievements',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  /// Share achievement via native share or Firebase
  Future<void> _shareAchievement(Achievement achievement) async {
    final success = await _gamificationService!.shareAchievement(achievement);

    if (success) {
      // Also copy to clipboard for easy sharing
      final shareText =
          '🎉 I just unlocked the "${achievement.name}" achievement! '
          '${achievement.description} (+${achievement.xpReward} XP)';

      await Clipboard.setData(ClipboardData(text: shareText));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Achievement shared! Text copied to clipboard.'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share achievement. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Map<String, AchievementProgress> _getProgressMap() {
    final progressMap = <String, AchievementProgress>{};
    for (final achievement in _gamificationService!.allAchievements) {
      final progress =
          _gamificationService!.getAchievementProgress(achievement.id);
      if (progress != null) {
        progressMap[achievement.id] = progress;
      }
    }
    return progressMap;
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}

/// Achievement unlock celebration widget
class AchievementUnlockDialog extends StatelessWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _getRarityColor(achievement.rarity).withValues(alpha: 0.8),
              _getRarityColor(achievement.rarity),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Celebration icon
            const Icon(
              Icons.celebration,
              size: 48,
              color: Colors.white,
            ),
            const SizedBox(height: 16),

            // Achievement unlocked text
            const Text(
              'ACHIEVEMENT UNLOCKED!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Achievement icon
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Achievement name
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Achievement description
            Text(
              achievement.description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // XP reward
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '+${achievement.xpReward} XP',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Close button
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _getRarityColor(achievement.rarity),
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'Awesome!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.orange;
    }
  }
}

/// Function to show achievement unlock celebration
void showAchievementUnlocked(BuildContext context, Achievement achievement) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AchievementUnlockDialog(achievement: achievement),
  );
}
