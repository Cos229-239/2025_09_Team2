import 'package:flutter/material.dart';
import '../services/achievement_gamification_service.dart';
import '../widgets/achievement/achievement_widgets.dart';
import '../widgets/common/themed_background_wrapper.dart';

// TODO: Achievement Screen - Missing Real Gamification Features
// - Achievement service is completely placeholder implementation
// - No actual achievement tracking with real user data
// - Missing integration with study progress for achievement unlocking
// - No real reward system or redeemable benefits
// - Missing social achievement sharing and comparisons
// - No dynamic achievement generation based on user behavior
// - Missing achievement categories and difficulty levels
// - No integration with external badge systems
// - Missing achievement notification system
// - No progress analytics for achievement completion
// - Missing seasonal or time-limited achievements
// - No integration with learning analytics for meaningful achievements

/// Screen for displaying user achievements and progress
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeGamificationService();
  }

  Future<void> _initializeGamificationService() async {
    _gamificationService = AchievementGamificationService();
    await _gamificationService!.initialize();
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

    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Achievements'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Achievements'),
            Tab(icon: Icon(Icons.trending_up), text: 'Streaks'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Rewards'),
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
        ],
      ),
    ),
  );
  }

  Widget _buildOverviewTab() {
    final stats = _gamificationService!.getGamificationStats();
    final userLevel = _gamificationService!.userLevel;

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
                  Text(
                    'Quick Stats',
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
    return Column(
      children: [
        // Filter buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showFilteredAchievements(false),
                  icon: const Icon(Icons.list),
                  label: const Text('All'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showFilteredAchievements(true),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Unlocked'),
                ),
              ),
            ],
          ),
        ),
        // Achievements grid
        Expanded(
          child: AchievementsGridWidget(
            achievements: _gamificationService!.allAchievements,
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
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: RewardsWidget(
          rewards: _gamificationService!.earnedRewards,
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
              Text(
                showOnlyUnlocked ? 'Unlocked Achievements' : 'All Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: AchievementsGridWidget(
                  achievements: _gamificationService!.allAchievements,
                  progress: _getProgressMap(),
                  showOnlyUnlocked: showOnlyUnlocked,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
