import 'package:flutter/material.dart';
import '../../services/competitive_learning_service.dart';

/// Widget for displaying leaderboard entries
class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String? currentUserId;
  final bool showRankIcons;
  final int maxEntries;

  const LeaderboardWidget({
    Key? key,
    required this.entries,
    this.currentUserId,
    this.showRankIcons = true,
    this.maxEntries = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayEntries = entries.take(maxEntries).toList();
    
    if (displayEntries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.leaderboard, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No rankings yet',
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
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Entries
          ...displayEntries.asMap().entries.map((entry) {
            final index = entry.key;
            final leaderboardEntry = entry.value;
            final isCurrentUser = leaderboardEntry.userId == currentUserId;
            
            return _buildLeaderboardEntry(
              context,
              leaderboardEntry,
              index,
              isCurrentUser,
            );
          }),
          
          // Show current user if not in top entries
          if (currentUserId != null && !displayEntries.any((e) => e.userId == currentUserId)) ...[
            const Divider(),
            _buildCurrentUserEntry(context),
          ],
        ],
      ),
    );
  }

  Widget _buildLeaderboardEntry(
    BuildContext context,
    LeaderboardEntry entry,
    int index,
    bool isCurrentUser,
  ) {
    final rank = entry.rank;
    final isTopThree = rank <= 3;
    
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
        border: isCurrentUser ? Border.all(
          color: Theme.of(context).primaryColor,
          width: 2,
        ) : null,
      ),
      child: ListTile(
        leading: _buildRankWidget(rank, isTopThree),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.displayName,
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'YOU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Text(
          '@${entry.username}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatScore(entry.score, entry.category),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isTopThree ? _getRankColor(rank) : null,
              ),
            ),
            if (entry.metadata.containsKey('level'))
              Text(
                'Lv.${entry.metadata['level']}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankWidget(int rank, bool isTopThree) {
    if (!showRankIcons || !isTopThree) {
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey[300],
        child: Text(
          '$rank',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Colors.black87,
          ),
        ),
      );
    }

    IconData icon;
    Color color;
    
    switch (rank) {
      case 1:
        icon = Icons.emoji_events;
        color = const Color(0xFFFFD700); // Gold
        break;
      case 2:
        icon = Icons.emoji_events;
        color = const Color(0xFFC0C0C0); // Silver
        break;
      case 3:
        icon = Icons.emoji_events;
        color = const Color(0xFFCD7F32); // Bronze
        break;
      default:
        icon = Icons.star;
        color = Colors.grey;
    }

    return CircleAvatar(
      radius: 16,
      backgroundColor: color,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }

  Widget _buildCurrentUserEntry(BuildContext context) {
    // Find current user in full entries list
    final userEntry = entries.firstWhere(
      (e) => e.userId == currentUserId,
      orElse: () => LeaderboardEntry(
        userId: currentUserId!,
        username: 'you',
        displayName: 'You',
        score: 0,
        rank: entries.length + 1,
        category: CompetitionCategory.xpGained,
        period: LeaderboardPeriod.weekly,
        lastUpdated: DateTime.now(),
      ),
    );

    return _buildLeaderboardEntry(context, userEntry, -1, true);
  }

  String _formatScore(double score, CompetitionCategory category) {
    switch (category) {
      case CompetitionCategory.studyTime:
        final hours = score ~/ 60;
        final minutes = (score % 60).toInt();
        return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      case CompetitionCategory.accuracy:
        return '${(score * 100).toInt()}%';
      case CompetitionCategory.streaks:
        return '${score.toInt()} days';
      case CompetitionCategory.xpGained:
        return '${score.toInt()} XP';
      case CompetitionCategory.sessionsCompleted:
        return '${score.toInt()} sessions';
      case CompetitionCategory.questionsAnswered:
        return '${score.toInt()} questions';
      case CompetitionCategory.subjectMastery:
        return '${score.toInt()} subjects';
      case CompetitionCategory.overallProgress:
        return '${score.toInt()}%';
    }
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.grey;
    }
  }
}

/// Widget for displaying competition cards
class CompetitionCard extends StatelessWidget {
  final Competition competition;
  final bool isParticipating;
  final VoidCallback? onJoin;
  final VoidCallback? onViewDetails;

  const CompetitionCard({
    Key? key,
    required this.competition,
    this.isParticipating = false,
    this.onJoin,
    this.onViewDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isActive = competition.isActive && 
                    competition.startDate.isBefore(now) && 
                    competition.endDate.isAfter(now);
    final isUpcoming = competition.startDate.isAfter(now);
    final timeRemaining = isActive 
        ? competition.endDate.difference(now)
        : competition.startDate.difference(now);

    return Card(
      elevation: 3,
      child: InkWell(
        onTap: onViewDetails,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and Type
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(isActive, isUpcoming).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getStatusColor(isActive, isUpcoming)),
                    ),
                    child: Text(
                      _getStatusText(isActive, isUpcoming),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(isActive, isUpcoming),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(competition.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      competition.type.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _getTypeColor(competition.type),
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isParticipating)
                    Icon(Icons.check_circle, color: Colors.green),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Title and Description
              Text(
                competition.name,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                competition.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Competition Category
              Row(
                children: [
                  Icon(
                    _getCategoryIcon(competition.category),
                    size: 16,
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getCategoryName(competition.category),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Participants and Time
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${competition.participants.length}/${competition.maxParticipants}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeRemaining(timeRemaining, isActive, isUpcoming),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Rewards
              if (competition.rewards.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Rewards:',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: competition.rewards.take(3).map((reward) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reward.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.amber[800],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
              
              // Action Buttons
              if (!isParticipating && isActive) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.sports_score),
                    label: const Text('Join Competition'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(bool isActive, bool isUpcoming) {
    if (isActive) return Colors.green;
    if (isUpcoming) return Colors.blue;
    return Colors.grey;
  }

  String _getStatusText(bool isActive, bool isUpcoming) {
    if (isActive) return 'ACTIVE';
    if (isUpcoming) return 'UPCOMING';
    return 'ENDED';
  }

  Color _getTypeColor(CompetitionType type) {
    switch (type) {
      case CompetitionType.daily:
        return Colors.orange;
      case CompetitionType.weekly:
        return Colors.blue;
      case CompetitionType.monthly:
        return Colors.purple;
      case CompetitionType.challenge:
        return Colors.red;
      case CompetitionType.tournament:
        return Colors.green;
    }
  }

  IconData _getCategoryIcon(CompetitionCategory category) {
    switch (category) {
      case CompetitionCategory.studyTime:
        return Icons.access_time;
      case CompetitionCategory.accuracy:
        return Icons.gps_fixed;
      case CompetitionCategory.streaks:
        return Icons.local_fire_department;
      case CompetitionCategory.xpGained:
        return Icons.star;
      case CompetitionCategory.sessionsCompleted:
        return Icons.task_alt;
      case CompetitionCategory.questionsAnswered:
        return Icons.quiz;
      case CompetitionCategory.subjectMastery:
        return Icons.school;
      case CompetitionCategory.overallProgress:
        return Icons.trending_up;
    }
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

  String _formatTimeRemaining(Duration timeRemaining, bool isActive, bool isUpcoming) {
    if (timeRemaining.isNegative) return 'Ended';
    
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours % 24;
    final minutes = timeRemaining.inMinutes % 60;
    
    if (days > 0) {
      return '${days}d ${hours}h';
    } else if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Widget for displaying peer comparisons
class PeerComparisonWidget extends StatelessWidget {
  final List<PeerComparison> comparisons;
  final Map<String, String> friendNames;

  const PeerComparisonWidget({
    Key? key,
    required this.comparisons,
    this.friendNames = const {},
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (comparisons.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.people, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No friend comparisons yet',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add friends to see how you compare!',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Friend Comparisons',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...comparisons.map((comparison) => _buildComparisonTile(context, comparison)),
        ],
      ),
    );
  }

  Widget _buildComparisonTile(BuildContext context, PeerComparison comparison) {
    final friendName = friendNames[comparison.friendId] ?? 'Friend';
    final category = comparison.category;
    final userScore = comparison.userScore;
    final friendScore = comparison.friendScore;
    final userIsAhead = comparison.userIsAhead;
    final difference = comparison.difference;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: userIsAhead ? Colors.green : Colors.orange,
        child: Icon(
          userIsAhead ? Icons.trending_up : Icons.trending_down,
          color: Colors.white,
        ),
      ),
      title: Text(
        _getCategoryName(category),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('vs $friendName'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            userIsAhead ? '+${_formatScore(difference, category)}' : '-${_formatScore(difference, category)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: userIsAhead ? Colors.green : Colors.orange,
            ),
          ),
          Text(
            '${_formatScore(userScore, category)} vs ${_formatScore(friendScore, category)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
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

  String _formatScore(double score, CompetitionCategory category) {
    switch (category) {
      case CompetitionCategory.studyTime:
        final hours = score ~/ 60;
        final minutes = (score % 60).toInt();
        return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
      case CompetitionCategory.accuracy:
        return '${(score * 100).toInt()}%';
      case CompetitionCategory.streaks:
        return '${score.toInt()} days';
      case CompetitionCategory.xpGained:
        return '${score.toInt()} XP';
      case CompetitionCategory.sessionsCompleted:
        return '${score.toInt()}';
      case CompetitionCategory.questionsAnswered:
        return '${score.toInt()}';
      case CompetitionCategory.subjectMastery:
        return '${score.toInt()}';
      case CompetitionCategory.overallProgress:
        return '${score.toInt()}%';
    }
  }
}

/// Widget for displaying competitive stats overview
class CompetitiveStatsWidget extends StatelessWidget {
  final Map<String, dynamic> stats;

  const CompetitiveStatsWidget({
    Key? key,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Competitive Stats',
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
                    'Competitions Won',
                    '${stats['competitionsWon'] ?? 0}',
                    Icons.emoji_events,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Win Rate',
                    '${((stats['winRate'] ?? 0.0) * 100).toInt()}%',
                    Icons.trending_up,
                    Colors.green,
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
                    'Active Competitions',
                    '${stats['activeCompetitions'] ?? 0}',
                    Icons.sports_score,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Participated',
                    '${stats['competitionsParticipated'] ?? 0}',
                    Icons.groups,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
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
}