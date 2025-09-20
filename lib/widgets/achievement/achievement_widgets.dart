import 'package:flutter/material.dart';
import '../../services/achievement_gamification_service.dart';

/// Widget for displaying user's level and XP progress
class LevelProgressWidget extends StatelessWidget {
  final UserLevel userLevel;
  final bool showDetails;

  const LevelProgressWidget({
    super.key,
    required this.userLevel,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final progress = userLevel.currentXP / userLevel.xpForNextLevel;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getLevelColor(userLevel.level),
                  child: Text(
                    '${userLevel.level}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userLevel.title,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Level ${userLevel.level}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showDetails) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${userLevel.currentXP} / ${userLevel.xpForNextLevel} XP',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Total: ${userLevel.totalXP}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getLevelColor(userLevel.level)),
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Text(
                '${userLevel.xpForNextLevel - userLevel.currentXP} XP to next level',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(int level) {
    if (level >= 50) return Colors.purple;
    if (level >= 40) return Colors.red;
    if (level >= 30) return Colors.orange;
    if (level >= 20) return Colors.blue;
    if (level >= 10) return Colors.green;
    return Colors.grey;
  }
}

/// Widget for displaying achievements in a grid
class AchievementsGridWidget extends StatelessWidget {
  final List<Achievement> achievements;
  final Map<String, AchievementProgress> progress;
  final bool showOnlyUnlocked;

  const AchievementsGridWidget({
    super.key,
    required this.achievements,
    required this.progress,
    this.showOnlyUnlocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final filteredAchievements = showOnlyUnlocked
        ? achievements
            .where((a) => progress[a.id]?.isUnlocked ?? false)
            .toList()
        : achievements;

    if (filteredAchievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              showOnlyUnlocked
                  ? 'No achievements unlocked yet'
                  : 'No achievements available',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: filteredAchievements.length,
      itemBuilder: (context, index) {
        final achievement = filteredAchievements[index];
        final achievementProgress = progress[achievement.id];
        return AchievementCard(
          achievement: achievement,
          progress: achievementProgress,
        );
      },
    );
  }
}

/// Individual achievement card widget
class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress? progress;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress?.isUnlocked ?? false;
    final progressValue = progress?.progress ?? 0.0;

    return Card(
      elevation: isUnlocked ? 6 : 2,
      child: InkWell(
        onTap: () => _showAchievementDetails(context),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: isUnlocked
                ? Border.all(
                    color: _getRarityColor(achievement.rarity), width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Achievement icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isUnlocked
                        ? _getRarityColor(achievement.rarity)
                            .withValues(alpha: 0.2)
                        : Colors.grey[300],
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: 24,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Achievement name
                Text(
                  achievement.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Rarity indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRarityColor(achievement.rarity),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    achievement.rarity.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Progress bar (if not unlocked)
                if (!isUnlocked) ...[
                  LinearProgressIndicator(
                    value: progressValue,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getRarityColor(achievement.rarity)),
                    minHeight: 4,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(progressValue * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ] else ...[
                  Icon(
                    Icons.check_circle,
                    color: _getRarityColor(achievement.rarity),
                    size: 20,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAchievementDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AchievementDetailDialog(
        achievement: achievement,
        progress: progress,
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

/// Dialog for showing achievement details
class AchievementDetailDialog extends StatelessWidget {
  final Achievement achievement;
  final AchievementProgress? progress;

  const AchievementDetailDialog({
    super.key,
    required this.achievement,
    this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress?.isUnlocked ?? false;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Achievement icon and name
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    _getRarityColor(achievement.rarity).withValues(alpha: 0.2),
                border: Border.all(
                  color: _getRarityColor(achievement.rarity),
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  achievement.icon,
                  style: const TextStyle(fontSize: 36),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              achievement.name,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getRarityColor(achievement.rarity),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                achievement.rarity.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              achievement.description,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // XP Reward
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${achievement.xpReward} XP',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),

            // Progress or unlock status
            if (isUnlocked) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Unlocked on ${_formatDate(progress!.unlockedAt!)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (progress != null) ...[
              const SizedBox(height: 16),
              Text(
                'Progress: ${(progress!.progress * 100).toInt()}%',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress!.progress,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                    _getRarityColor(achievement.rarity)),
                minHeight: 8,
              ),
            ],

            // Rewards
            if (achievement.rewards.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Rewards:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...achievement.rewards.map((reward) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getRewardIcon(reward.type), size: 16),
                        const SizedBox(width: 4),
                        Text(reward.name),
                      ],
                    ),
                  )),
            ],

            const SizedBox(height: 24),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
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

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.xp:
        return Icons.star;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.title:
        return Icons.title;
      case RewardType.avatar:
        return Icons.account_circle;
      case RewardType.theme:
        return Icons.palette;
      case RewardType.feature:
        return Icons.extension;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Widget for displaying streaks
class StreakWidget extends StatelessWidget {
  final Map<String, Streak> streaks;

  const StreakWidget({
    super.key,
    required this.streaks,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Streaks',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...streaks.entries
                .map((entry) => _buildStreakItem(context, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(BuildContext context, Streak streak) {
    IconData icon;
    Color color;
    String title;

    switch (streak.type) {
      case 'daily':
        icon = Icons.calendar_today;
        color = Colors.orange;
        title = 'Daily Study';
        break;
      case 'study':
        icon = Icons.school;
        color = Colors.blue;
        title = 'Study Sessions';
        break;
      case 'accuracy':
        icon = Icons.gps_fixed;
        color = Colors.green;
        title = 'Accuracy';
        break;
      default:
        icon = Icons.trending_up;
        color = Colors.grey;
        title = streak.type;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Current: ${streak.current} | Best: ${streak.longest}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          if (streak.current > 0) ...[
            const Icon(Icons.local_fire_department, color: Colors.red),
            const SizedBox(width: 4),
            Text(
              '${streak.current}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget for displaying rewards earned
class RewardsWidget extends StatelessWidget {
  final List<Reward> rewards;

  const RewardsWidget({
    super.key,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    if (rewards.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.card_giftcard,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 8),
              Text(
                'No rewards earned yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rewards Earned',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return _buildRewardItem(context, reward);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardItem(BuildContext context, Reward reward) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getRewardIcon(reward.type), size: 24),
          const SizedBox(height: 4),
          Text(
            reward.name,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.xp:
        return Icons.star;
      case RewardType.badge:
        return Icons.military_tech;
      case RewardType.title:
        return Icons.title;
      case RewardType.avatar:
        return Icons.account_circle;
      case RewardType.theme:
        return Icons.palette;
      case RewardType.feature:
        return Icons.extension;
    }
  }
}
