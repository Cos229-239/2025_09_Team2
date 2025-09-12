// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing state management
import 'package:provider/provider.dart';
// Import TaskProvider for managing regular task data and operations
import 'package:studypals/providers/task_provider.dart';
// Import DailyQuestProvider for managing daily quest data
import 'package:studypals/providers/daily_quest_provider.dart';
// Import Task model to access task data structures and enums
import 'package:studypals/models/task.dart';
// Import DailyQuest model for quest data structures
import 'package:studypals/models/daily_quest.dart';
// Import AddTaskSheet widget for creating new tasks
import 'package:studypals/widgets/common/add_task_sheet.dart';

/// Widget displaying today's tasks with quick completion actions
/// Shows up to 3 tasks due today with add task functionality
/// Part of the dashboard providing immediate task visibility and management
class TodayTasksWidget extends StatelessWidget {
  // Constructor with optional key for widget identification
  const TodayTasksWidget({super.key});

  /// Builds the today's tasks widget with task list and add functionality
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing today's task interface
  @override
  Widget build(BuildContext context) {
    // Multiple consumers to listen to both regular tasks and daily quests
    return Consumer2<TaskProvider, DailyQuestProvider>(
      builder: (context, taskProvider, questProvider, child) {
        final todayTasks = taskProvider.todayTasks; // Get regular tasks due today
        final dailyQuests = questProvider.quests; // Get daily quests

        // Card container providing elevation and material design appearance
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16), // Internal spacing for content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Align content to left
              children: [
                // Header row with title and add task button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between title and button
                  children: [
                    // Widget title
                    Text(
                      'Today\'s Tasks & Quests',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Add task button - opens task creation modal
                    IconButton(
                      onPressed: () => _showAddTaskSheet(context), // Show add task modal
                      icon: const Icon(Icons.add), // Plus icon for adding
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between header and content

                // Daily Quests Section
                if (dailyQuests.isNotEmpty) ...[
                  Text(
                    'Daily Quests',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.purple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...dailyQuests.take(3).map((quest) => _buildQuestItem(context, quest, questProvider)),
                  if (dailyQuests.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () {
                          // Future: Navigate to quest details screen
                        },
                        child: Text('View ${dailyQuests.length - 3} more quests'),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],

                // Regular Tasks Section
                if (todayTasks.isNotEmpty) ...[
                  Text(
                    'Regular Tasks',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.blue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...todayTasks.take(3).map((task) => _buildTaskItem(context, task, taskProvider)),
                  if (todayTasks.length > 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: TextButton(
                        onPressed: () {
                          // Future: Navigate to comprehensive task list screen
                        },
                        child: Text('View ${todayTasks.length - 3} more tasks'),
                      ),
                    ),
                ],

                // Empty state when no tasks or quests exist
                if (todayTasks.isEmpty && dailyQuests.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24), // Generous padding for empty state
                    child: Column(
                      children: [
                        // Check circle icon indicating completion/empty state
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48, // Large icon for visual impact
                          color: Colors.grey, // Muted color for empty state
                        ),
                        const SizedBox(height: 8), // Spacing between icon and text
                        // Primary empty state message
                        Text(
                          'All tasks completed!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.grey, // Muted color for secondary text
                              ),
                        ),
                        const SizedBox(height: 8), // Spacing between messages
                        // Secondary message encouraging action
                        Text(
                          'New daily quests will appear tomorrow',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey, // Muted color for helper text
                              ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds an individual task item with checkbox, details, and priority indicator
  /// @param context - Build context for theme access
  /// @param task - Task data to display
  /// @param taskProvider - Provider for task operations (completion, etc.)
  /// @return Widget representing a single task item
  Widget _buildTaskItem(
      BuildContext context, Task task, TaskProvider taskProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Bottom spacing between tasks
      child: Row(
        children: [
          // Completion checkbox
          Checkbox(
            value: task.status ==
                TaskStatus.completed, // Check state based on task status
            onChanged: (bool? value) {
              if (value == true) {
                // Only handle completion (not uncomplete)
                taskProvider.completeTask(task.id); // Mark task as completed
              }
            },
          ),
          // Task details section
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Left-align task details
              children: [
                // Task title with conditional strikethrough for completed tasks
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        // Apply strikethrough decoration if task is completed
                        decoration: task.status == TaskStatus.completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                ),
                // Estimated time display (only if time is specified)
                if (task.estMinutes > 0)
                  Text(
                    '${task.estMinutes} min', // Time estimate with unit
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey, // Muted color for secondary info
                        ),
                  ),
              ],
            ),
          ),
          // Priority indicator badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              // Background color based on priority level with transparency
              color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
              borderRadius:
                  BorderRadius.circular(12), // Rounded corners for pill shape
            ),
            child: Text(
              _getPriorityText(task.priority), // Priority level text
              style: TextStyle(
                color: _getPriorityColor(
                    task.priority), // Text color matching priority
                fontSize: 12, // Small font for badge
                fontWeight: FontWeight.w500, // Medium weight for readability
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds an individual daily quest item with progress bar and EXP reward
  /// @param context - Build context for theme access
  /// @param quest - Daily quest data to display
  /// @param questProvider - Provider for quest operations
  /// @return Widget representing a single quest item
  Widget _buildQuestItem(
      BuildContext context, DailyQuest quest, DailyQuestProvider questProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // Bottom spacing between quests
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: quest.isCompleted ? Colors.green : Colors.purple.shade200,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: quest.isCompleted ? Colors.green.shade50 : Colors.purple.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quest header with icon, title, and EXP
          Row(
            children: [
              // Quest type icon
              Text(
                quest.type.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              // Quest title
              Expanded(
                child: Text(
                  quest.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    decoration: quest.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              // EXP reward
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '+${quest.expReward} EXP',
                  style: TextStyle(
                    color: Colors.amber.shade700,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Quest description
          Text(
            quest.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          
          // Progress bar and text
          Row(
            children: [
              // Progress indicator
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
              // Progress text
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
    );
  }

  /// Returns color associated with task priority level
  /// @param priority - Priority level (1=low, 2=medium, 3=high)
  /// @return Color representing the priority level
  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 3:
        return Colors.red; // Red for high priority
      case 2:
        return Colors.orange; // Orange for medium priority
      default:
        return Colors.green; // Green for low priority (default)
    }
  }

  /// Converts priority level to display text
  /// @param priority - Priority level (1=low, 2=medium, 3=high)
  /// @return String representation of priority level
  String _getPriorityText(int priority) {
    switch (priority) {
      case 3:
        return 'High'; // High priority text
      case 2:
        return 'Medium'; // Medium priority text
      default:
        return 'Low'; // Low priority text (default)
    }
  }

  /// Shows modal bottom sheet for adding new tasks
  /// @param context - Build context for navigation
  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true, // Allow sheet to expand based on content
      builder: (context) => const AddTaskSheet(), // Show add task form widget
    );
  }
}
