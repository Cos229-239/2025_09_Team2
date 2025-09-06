// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing task state management
import 'package:provider/provider.dart';
// Import TaskProvider for managing task data and operations
import 'package:studypals/providers/task_provider.dart';
// Import Task model to access task data structures and enums
import 'package:studypals/models/task.dart';
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
    // Consumer listens to TaskProvider changes and rebuilds when task data updates
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final todayTasks = taskProvider.todayTasks;  // Get tasks due today from provider
        
        // Card container providing elevation and material design appearance
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),       // Internal spacing for content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,  // Align content to left
              children: [
                // Header row with title and add task button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Space between title and button
                  children: [
                    // Widget title
                    Text(
                      'Today\'s Tasks',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Add task button - opens task creation modal
                    IconButton(
                      onPressed: () => _showAddTaskSheet(context),  // Show add task modal
                      icon: const Icon(Icons.add),                  // Plus icon for adding
                    ),
                  ],
                ),
                const SizedBox(height: 12),         // Spacing between header and content
                
                // Conditional content based on task availability
                if (todayTasks.isEmpty)
                  // Empty state when no tasks exist for today
                  Container(
                    padding: const EdgeInsets.all(24),  // Generous padding for empty state
                    child: Column(
                      children: [
                        // Check circle icon indicating completion/empty state
                        const Icon(
                          Icons.check_circle_outline,
                          size: 48,                      // Large icon for visual impact
                          color: Colors.grey,            // Muted color for empty state
                        ),
                        const SizedBox(height: 8),      // Spacing between icon and text
                        // Primary empty state message
                        Text(
                          'No tasks for today!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,          // Muted color for secondary text
                          ),
                        ),
                        const SizedBox(height: 8),      // Spacing between messages
                        // Secondary message encouraging action
                        Text(
                          'Add a task to get started',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,          // Muted color for helper text
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Task list when tasks exist - show up to 3 tasks
                  ...todayTasks.take(3).map((task) => _buildTaskItem(context, task, taskProvider)),
                
                // "View more" button when there are more than 3 tasks
                if (todayTasks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),  // Top spacing for button
                    child: TextButton(
                      onPressed: () {
                        // Future implementation: Navigate to comprehensive task list screen
                        // Will show all tasks with filtering, sorting, and management options
                      },
                      // Show count of remaining tasks
                      child: Text('View ${todayTasks.length - 3} more tasks'),
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
  Widget _buildTaskItem(BuildContext context, Task task, TaskProvider taskProvider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),    // Bottom spacing between tasks
      child: Row(
        children: [
          // Completion checkbox
          Checkbox(
            value: task.status == TaskStatus.completed,  // Check state based on task status
            onChanged: (bool? value) {
              if (value == true) {                       // Only handle completion (not uncomplete)
                taskProvider.completeTask(task.id);      // Mark task as completed
              }
            },
          ),
          // Task details section
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,  // Left-align task details
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
                    '${task.estMinutes} min',             // Time estimate with unit
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,                 // Muted color for secondary info
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
              borderRadius: BorderRadius.circular(12),   // Rounded corners for pill shape
            ),
            child: Text(
              _getPriorityText(task.priority),           // Priority level text
              style: TextStyle(
                color: _getPriorityColor(task.priority), // Text color matching priority
                fontSize: 12,                            // Small font for badge
                fontWeight: FontWeight.w500,             // Medium weight for readability
              ),
            ),
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
        return Colors.red;                        // Red for high priority
      case 2:
        return Colors.orange;                     // Orange for medium priority
      default:
        return Colors.green;                      // Green for low priority (default)
    }
  }

  /// Converts priority level to display text
  /// @param priority - Priority level (1=low, 2=medium, 3=high)
  /// @return String representation of priority level
  String _getPriorityText(int priority) {
    switch (priority) {
      case 3:
        return 'High';                            // High priority text
      case 2:
        return 'Medium';                          // Medium priority text
      default:
        return 'Low';                             // Low priority text (default)
    }
  }

  /// Shows modal bottom sheet for adding new tasks
  /// @param context - Build context for navigation
  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,                   // Allow sheet to expand based on content
      builder: (context) => const AddTaskSheet(), // Show add task form widget
    );
  }
}
