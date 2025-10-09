// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing state management
import 'package:provider/provider.dart';
// Import Task model and provider for task data
import 'package:studypals/models/task.dart';
import 'package:studypals/providers/task_provider.dart';
// Import AddTaskSheet widget for creating new tasks
import 'package:studypals/widgets/common/add_task_sheet.dart';

/// Screen displaying tasks organized by time periods (Today, This Week, This Month)
/// Follows the same styling pattern as the notes page
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh tasks when screen loads to ensure latest data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        backgroundColor: const Color(0xFF6FB8E9),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskSection(
                        title: "Today's Tasks",
                        tasks: _getTodayTasks(taskProvider.tasks),
                        icon: Icons.today,
                        emptyMessage: "No tasks due today",
                      ),
                      const SizedBox(height: 24),
                      _buildTaskSection(
                        title: "This Week's Tasks",
                        tasks: _getThisWeekTasks(taskProvider.tasks),
                        icon: Icons.view_week,
                        emptyMessage: "No tasks due this week",
                      ),
                      const SizedBox(height: 24),
                      _buildTaskSection(
                        title: "This Month's Tasks",
                        tasks: _getThisMonthTasks(taskProvider.tasks),
                        icon: Icons.calendar_month,
                        emptyMessage: "No tasks due this month",
                      ),
                      const SizedBox(height: 80), // Space for floating button
                    ],
                  ),
                ),
              ),
              
              // Create button at bottom matching notes page style
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showCreateTaskModal(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Task'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6FB8E9),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Get tasks due today
  List<Task> _getTodayTasks(List<Task> allTasks) {
    final today = DateTime.now();
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      return task.dueAt!.year == today.year &&
          task.dueAt!.month == today.month &&
          task.dueAt!.day == today.day;
    }).toList();
  }

  /// Get tasks due this week
  List<Task> _getThisWeekTasks(List<Task> allTasks) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      // Exclude today's tasks as they're shown in the today section
      final isToday = task.dueAt!.year == today.year &&
          task.dueAt!.month == today.month &&
          task.dueAt!.day == today.day;
      if (isToday) return false;
      
      return task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get tasks due this month
  List<Task> _getThisMonthTasks(List<Task> allTasks) {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      
      // Exclude tasks already shown in today and this week sections
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final isInCurrentWeek = task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
      if (isInCurrentWeek) return false;
      
      return task.dueAt!.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  /// Build a task section with header and task list
  Widget _buildTaskSection({
    required String title,
    required List<Task> tasks,
    required IconData icon,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6FB8E9),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FB8E9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Task list or empty message
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.map((task) => _buildTaskCard(task)),
      ],
    );
  }

  /// Build individual task card matching notes page style
  Widget _buildTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTaskDetails(task),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Task status checkbox
                GestureDetector(
                  onTap: () => _toggleTaskStatus(task),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.status == TaskStatus.completed
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF6FB8E9),
                        width: 2,
                      ),
                      color: task.status == TaskStatus.completed
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                    ),
                    child: task.status == TaskStatus.completed
                        ? const Icon(
                            Icons.check,
                            size: 16,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == TaskStatus.completed
                              ? Colors.grey[500]
                              : const Color(0xFF333333),
                        ),
                      ),
                      if (task.tags.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: task.tags.take(3).map((tag) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6FB8E9),
                              ),
                            ),
                          )).toList(),
                        ),
                      ],
                      if (task.dueAt != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDate(task.dueAt!),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                
                // More options menu
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editTask(task);
                    } else if (value == 'delete') {
                      _deleteTask(task);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 12),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Format due date for display
  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Due today';
    } else if (taskDate == tomorrow) {
      return 'Due tomorrow';
    } else if (taskDate.isBefore(today)) {
      final diff = today.difference(taskDate).inDays;
      return 'Overdue by $diff day${diff > 1 ? 's' : ''}';
    } else {
      final diff = taskDate.difference(today).inDays;
      return 'Due in $diff day${diff > 1 ? 's' : ''}';
    }
  }

  /// Show create task modal
  void _showCreateTaskModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTaskSheet(),
    );
  }

  /// Toggle task completion status
  void _toggleTaskStatus(Task task) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    
    // Create updated task
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      estMinutes: task.estMinutes,
      dueAt: task.dueAt,
      priority: task.priority,
      tags: task.tags,
      status: newStatus,
      linkedNoteId: task.linkedNoteId,
      linkedDeckId: task.linkedDeckId,
    );
    
    provider.updateTask(updatedTask);
  }

  /// Show task details
  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated time: ${task.estMinutes} minutes'),
            if (task.dueAt != null)
              Text('Due: ${_formatDueDate(task.dueAt!)}'),
            Text('Priority: ${_getPriorityText(task.priority)}'),
            if (task.tags.isNotEmpty)
              Text('Tags: ${task.tags.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get priority text
  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
  }

  /// Edit task
  void _editTask(Task task) {
    // TODO: Implement task editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Task editing coming soon!')),
    );
  }

  /// Delete task
  void _deleteTask(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Provider.of<TaskProvider>(context, listen: false).deleteTask(task.id);
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Task deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}