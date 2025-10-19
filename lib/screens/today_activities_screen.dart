import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../providers/daily_quest_provider.dart';
import '../models/task.dart';
import '../models/daily_quest.dart';
import '../widgets/common/add_task_sheet.dart';

/// Today's Activities screen showing all tasks and quests for today
/// Provides a comprehensive view of daily activities, tasks, and quests
/// Accessible from the notification bell in the dashboard
class TodayActivitiesScreen extends StatelessWidget {
  const TodayActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Activities'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Add task button in app bar
          IconButton(
            onPressed: () => _showAddTaskSheet(context),
            icon: const Icon(Icons.add),
            tooltip: 'Add New Task',
          ),
        ],
      ),
      body: Consumer2<TaskProvider, DailyQuestProvider>(
        builder: (context, taskProvider, questProvider, child) {
          final todayTasks = taskProvider.todayTasks;
          final dailyQuests = questProvider.quests;
          final completedTasks = todayTasks
              .where((task) => task.status == TaskStatus.completed)
              .toList();
          final pendingTasks = todayTasks
              .where((task) => task.status != TaskStatus.completed)
              .toList();
          final completedQuests =
              dailyQuests.where((quest) => quest.isCompleted).toList();
          final pendingQuests =
              dailyQuests.where((quest) => !quest.isCompleted).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                _buildSummaryCard(context, todayTasks, dailyQuests),

                const SizedBox(height: 24),

                // Daily Quests Section
                if (dailyQuests.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Daily Quests',
                    '${completedQuests.length}/${dailyQuests.length} completed',
                    Icons.star,
                    Colors.purple,
                  ),
                  const SizedBox(height: 12),

                  // Pending Quests
                  if (pendingQuests.isNotEmpty) ...[
                    Text(
                      'Pending Quests',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...pendingQuests.map((quest) =>
                        _buildQuestCard(context, quest, questProvider)),
                    const SizedBox(height: 16),
                  ],

                  // Completed Quests
                  if (completedQuests.isNotEmpty) ...[
                    Text(
                      'Completed Quests',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...completedQuests.map((quest) =>
                        _buildQuestCard(context, quest, questProvider)),
                    const SizedBox(height: 24),
                  ],
                ],

                // Regular Tasks Section
                if (todayTasks.isNotEmpty) ...[
                  _buildSectionHeader(
                    context,
                    'Regular Tasks',
                    '${completedTasks.length}/${todayTasks.length} completed',
                    Icons.task_alt,
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),

                  // Pending Tasks
                  if (pendingTasks.isNotEmpty) ...[
                    Text(
                      'Pending Tasks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...pendingTasks.map(
                        (task) => _buildTaskCard(context, task, taskProvider)),
                    const SizedBox(height: 16),
                  ],

                  // Completed Tasks
                  if (completedTasks.isNotEmpty) ...[
                    Text(
                      'Completed Tasks',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...completedTasks.map(
                        (task) => _buildTaskCard(context, task, taskProvider)),
                  ],
                ],

                // Empty state
                if (todayTasks.isEmpty && dailyQuests.isEmpty)
                  _buildEmptyState(context),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        tooltip: 'Add New Task',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, List<Task> tasks, List<DailyQuest> quests) {
    final completedTasks =
        tasks.where((task) => task.status == TaskStatus.completed).length;
    final completedQuests = quests.where((quest) => quest.isCompleted).length;
    final totalTasks = tasks.length;
    final totalQuests = quests.length;
    final totalItems = totalTasks + totalQuests;
    final completedItems = completedTasks + completedQuests;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main progress indicator
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Progress',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 8),
                      if (totalItems > 0) ...[
                        LinearProgressIndicator(
                          value: completedItems / totalItems,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            completedItems == totalItems
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$completedItems of $totalItems items completed',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ] else ...[
                        Text(
                          'No activities for today',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey.shade600,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (totalItems > 0)
                  CircularProgressIndicator(
                    value: completedItems / totalItems,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      completedItems == totalItems ? Colors.green : Colors.blue,
                    ),
                  ),
              ],
            ),

            if (totalItems > 0) ...[
              const SizedBox(height: 16),
              // Breakdown
              Row(
                children: [
                  Expanded(
                    child: _buildProgressItem(
                      context,
                      'Tasks',
                      completedTasks,
                      totalTasks,
                      Colors.blue,
                      Icons.task_alt,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildProgressItem(
                      context,
                      'Quests',
                      completedQuests,
                      totalQuests,
                      Colors.purple,
                      Icons.star,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressItem(BuildContext context, String label, int completed,
      int total, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            '$completed/$total',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title,
      String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Checkbox(
          value: task.status == TaskStatus.completed,
          onChanged: (bool? value) {
            if (value == true) {
              taskProvider.completeTask(task.id);
            }
          },
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
            color: task.status == TaskStatus.completed ? Colors.grey : null,
          ),
        ),
        subtitle:
            task.estMinutes > 0 ? Text('${task.estMinutes} minutes') : null,
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _getPriorityText(task.priority),
            style: TextStyle(
              color: _getPriorityColor(task.priority),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestCard(BuildContext context, DailyQuest quest,
      DailyQuestProvider questProvider) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quest header
            Row(
              children: [
                Text(
                  quest.type.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: quest.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: quest.isCompleted ? Colors.grey : null,
                                ),
                      ),
                      Text(
                        quest.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '+${quest.expReward} EXP',
                    style: TextStyle(
                      color: Colors.amber.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: quest.progressPercentage,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      quest.isCompleted ? Colors.green : Colors.purple,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  quest.progressText,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'All caught up!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'No tasks or quests for today.\nNew daily quests will appear tomorrow.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddTaskSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add a Task'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red;
      case 2:
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 3:
        return 'High';
      case 2:
        return 'Medium';
      default:
        return 'Low';
    }
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTaskSheet(),
    );
  }
}
