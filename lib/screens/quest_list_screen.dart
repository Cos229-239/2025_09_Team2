// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing state management
import 'package:provider/provider.dart';
// Import DailyQuest model and provider for quest data
import 'package:studypals/models/daily_quest.dart';
import 'package:studypals/providers/daily_quest_provider.dart';

/// Screen displaying all daily quests with detailed view and progress tracking
/// Provides comprehensive quest management beyond the dashboard preview
class QuestListScreen extends StatefulWidget {
  const QuestListScreen({super.key});

  @override
  State<QuestListScreen> createState() => _QuestListScreenState();
}

class _QuestListScreenState extends State<QuestListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh quests when screen loads to ensure latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DailyQuestProvider>(context, listen: false).refreshQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Quests'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button to reload quests
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              Provider.of<DailyQuestProvider>(context, listen: false).refreshQuests();
            },
          ),
        ],
      ),
      body: Consumer<DailyQuestProvider>(
        builder: (context, questProvider, child) {
          if (questProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.purple,
              ),
            );
          }

          if (questProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading quests',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    questProvider.error!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => questProvider.refreshQuests(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final quests = questProvider.quests;
          final completedQuests = questProvider.completedQuests;
          final pendingQuests = questProvider.pendingQuests;

          if (quests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No quests available',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'New daily quests will be generated tomorrow',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Quest summary header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.purple.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Today\'s Progress',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Completed',
                            '${completedQuests.length}',
                            Colors.green,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Pending',
                            '${pendingQuests.length}',
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Total EXP',
                            '${questProvider.totalExpToday}',
                            Colors.amber,
                          ),
                        ),
                      ],
                    ),
                    if (quests.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: questProvider.completionRate,
                          backgroundColor: Colors.purple.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.purple),
                        ),
                      ),
                  ],
                ),
              ),

              // Quest list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: quests.length,
                  itemBuilder: (context, index) {
                    final quest = quests[index];
                    return _buildDetailedQuestItem(context, quest, questProvider);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
      ],
    );
  }

  Widget _buildDetailedQuestItem(
    BuildContext context,
    DailyQuest quest,
    DailyQuestProvider questProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: quest.isCompleted ? Colors.green : Colors.purple.shade200,
            width: 2,
          ),
          color: quest.isCompleted ? Colors.green.shade50 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest header with icon, title, and status
            Row(
              children: [
                // Quest type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: quest.isCompleted ? Colors.green.shade100 : Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    quest.type.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                // Quest title and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                            ),
                      ),
                      Text(
                        quest.type.displayName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                // EXP reward and priority
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${quest.expReward} EXP',
                        style: TextStyle(
                          color: Colors.amber.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Priority indicator
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(quest.priority).withAlpha(50),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Priority ${quest.priority}',
                        style: TextStyle(
                          color: _getPriorityColor(quest.priority),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Quest description
            Text(
              quest.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 12),
            
            // Progress section
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progress',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                          Text(
                            quest.progressText,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: quest.progressPercentage,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          quest.isCompleted ? Colors.green : Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Expiry information
            if (!quest.isCompleted && !quest.isExpired)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Expires at ${_formatTime(quest.expiresAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                  ],
                ),
              ),

            // Completion status
            if (quest.isCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Completed!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}