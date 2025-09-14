// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing state management
import 'package:provider/provider.dart';
// Import Task model and provider for task data
import 'package:studypals/models/task.dart';
import 'package:studypals/providers/task_provider.dart';
// Import AddTaskSheet widget for creating new tasks
import 'package:studypals/widgets/common/add_task_sheet.dart';

/// Screen displaying all tasks with filtering, sorting, and management capabilities
/// Provides comprehensive task management beyond the dashboard preview
class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  TaskStatus? _filterStatus;
  int? _filterPriority; // Priority is an int (1=low, 2=medium, 3=high)
  String _searchQuery = '';
  bool _showingCompletedTasks = false; // Track if we're viewing completed tasks
  
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
        title: Text(_showingCompletedTasks ? 'Completed Tasks' : 'All Tasks'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => _showSearchDialog(context),
          ),
          // Filter button
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
          ),
          // Add task button
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddTaskSheet(context),
          ),
        ],
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }

          final allTasks = taskProvider.tasks;
          print('TaskListScreen: Rendering with ${allTasks.length} total tasks');
          for (var task in allTasks) {
            print('  - TaskListScreen task: "${task.title}" (Status: ${task.status})');
          }
          
          final filteredTasks = _filterTasks(allTasks);
          print('TaskListScreen: After filtering, ${filteredTasks.length} tasks remain');
          
          final completedTasks = allTasks.where((task) => task.status == TaskStatus.completed).toList();
          final pendingTasks = allTasks.where((task) => task.status != TaskStatus.completed).toList();

          if (allTasks.isEmpty) {
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
                    'No tasks yet',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first task to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showAddTaskSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Task summary header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Task Overview',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        if (_filterStatus != null || _filterPriority != null || _searchQuery.isNotEmpty || _showingCompletedTasks)
                          TextButton(
                            onPressed: _clearFilters,
                            child: Text(_showingCompletedTasks ? 'Back to Active Tasks' : 'Clear Filters'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Total',
                            '${allTasks.length}',
                            Colors.blue,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Pending',
                            '${pendingTasks.length}',
                            Colors.orange,
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Completed',
                            '${completedTasks.length}',
                            _showingCompletedTasks ? Colors.green.shade700 : Colors.green,
                            onTap: () {
                              setState(() {
                                _showingCompletedTasks = !_showingCompletedTasks;
                                // Clear other filters when switching between views
                                if (_showingCompletedTasks) {
                                  _filterStatus = null;
                                  _filterPriority = null;
                                  _searchQuery = '';
                                }
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: _buildSummaryItem(
                            context,
                            'Filtered',
                            '${filteredTasks.length}',
                            Colors.purple,
                          ),
                        ),
                      ],
                    ),
                    if (allTasks.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: LinearProgressIndicator(
                          value: completedTasks.length / allTasks.length,
                          backgroundColor: Colors.blue.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                      ),
                  ],
                ),
              ),

              // Active filters display
              if (_filterStatus != null || _filterPriority != null || _searchQuery.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.grey.shade100,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      if (_searchQuery.isNotEmpty)
                        Chip(
                          label: Text('Search: "$_searchQuery"'),
                          onDeleted: () => setState(() => _searchQuery = ''),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      if (_filterStatus != null)
                        Chip(
                          label: Text('Status: ${_getStatusText(_filterStatus!)}'),
                          onDeleted: () => setState(() => _filterStatus = null),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                      if (_filterPriority != null)
                        Chip(
                          label: Text('Priority: ${_getPriorityText(_filterPriority!)}'),
                          onDeleted: () => setState(() => _filterPriority = null),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        ),
                    ],
                  ),
                ),

              // Task list
              Expanded(
                child: filteredTasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks match your filters',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredTasks.length,
                        itemBuilder: (context, index) {
                          print('ListView.builder: Rendering item $index of ${filteredTasks.length}');
                          final task = filteredTasks[index];
                          print('  Task to render: "${task.title}"');
                          return _buildDetailedTaskItem(context, task, taskProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskSheet(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  List<Task> _filterTasks(List<Task> tasks) {
    print('_filterTasks: Starting with ${tasks.length} tasks');
    print('  Search query: "$_searchQuery"');
    print('  Filter status: $_filterStatus');
    print('  Filter priority: $_filterPriority');
    
    var filtered = tasks;

    // Apply search filter (search in title since Task doesn't have description)
    if (_searchQuery.isNotEmpty) {
      var beforeSearch = filtered.length;
      filtered = filtered.where((task) =>
          task.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
      print('  After search filter: ${filtered.length} tasks (was $beforeSearch)');
    }

    // Apply status filter
    if (_filterStatus != null) {
      var beforeStatus = filtered.length;
      filtered = filtered.where((task) => task.status == _filterStatus).toList();
      print('  After status filter: ${filtered.length} tasks (was $beforeStatus)');
    }

    // Apply priority filter
    if (_filterPriority != null) {
      var beforePriority = filtered.length;
      filtered = filtered.where((task) => task.priority == _filterPriority).toList();
      print('  After priority filter: ${filtered.length} tasks (was $beforePriority)');
    }

    // Apply completed/active task filter based on current view mode
    if (_showingCompletedTasks) {
      // Show only completed tasks
      var beforeCompletedFilter = filtered.length;
      filtered = filtered.where((task) => task.status == TaskStatus.completed).toList();
      print('  After completed filter (showing completed): ${filtered.length} tasks (was $beforeCompletedFilter)');
    } else {
      // Hide completed tasks (show only active tasks)
      var beforeActiveFilter = filtered.length;
      filtered = filtered.where((task) => task.status != TaskStatus.completed).toList();
      print('  After active filter (hiding completed): ${filtered.length} tasks (was $beforeActiveFilter)');
    }

    // Sort by priority (high to low) then by due date
    filtered.sort((a, b) {
      // First sort by completion status (incomplete first)
      if (a.status != b.status) {
        return a.status == TaskStatus.completed ? 1 : -1;
      }
      // Then by priority (high to low)
      final priorityComparison = b.priority.compareTo(a.priority);
      if (priorityComparison != 0) return priorityComparison;
      
      // Finally by due date (earlier first)
      if (a.dueAt != null && b.dueAt != null) {
        return a.dueAt!.compareTo(b.dueAt!);
      } else if (a.dueAt != null) {
        return -1;
      } else if (b.dueAt != null) {
        return 1;
      }
      return 0;
    });

    print('_filterTasks: Returning ${filtered.length} tasks after all filters and sorting');
    for (var task in filtered) {
      print('  - Final task: "${task.title}" (Status: ${task.status}, Priority: ${task.priority})');
    }
    
    return filtered;
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _filterPriority = null;
      _searchQuery = '';
      _showingCompletedTasks = false; // Reset to active tasks view
    });
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Tasks'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter search terms...',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _searchQuery = value,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {});
              Navigator.of(context).pop();
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    TaskStatus? tempStatus = _filterStatus;
    int? tempPriority = _filterPriority;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Tasks'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Status:'),
              DropdownButton<TaskStatus?>(
                value: tempStatus,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...TaskStatus.values.map((status) => DropdownMenuItem(
                        value: status,
                        child: Text(_getStatusText(status)),
                      )),
                ],
                onChanged: (value) => setDialogState(() => tempStatus = value),
              ),
              const SizedBox(height: 16),
              const Text('Priority:'),
              DropdownButton<int?>(
                value: tempPriority,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  const DropdownMenuItem(value: 1, child: Text('Low')),
                  const DropdownMenuItem(value: 2, child: Text('Medium')),
                  const DropdownMenuItem(value: 3, child: Text('High')),
                ],
                onChanged: (value) => setDialogState(() => tempPriority = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterStatus = tempStatus;
                  _filterPriority = tempPriority;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddTaskSheet(),
    );
  }

  Widget _buildSummaryItem(
    BuildContext context,
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    Widget content = Column(
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

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: (label == 'Completed' && _showingCompletedTasks) 
                ? color.withAlpha(40)  // Highlight when active
                : Colors.transparent,
            border: (label == 'Completed' && _showingCompletedTasks)
                ? Border.all(color: color.withAlpha(100), width: 1)
                : null,
          ),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildDetailedTaskItem(
    BuildContext context,
    Task task,
    TaskProvider taskProvider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: task.status == TaskStatus.completed ? Colors.green : _getPriorityColor(task.priority),
            width: 2,
          ),
          color: task.status == TaskStatus.completed ? Colors.green.shade50 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Task header with checkbox, title, and priority
            Row(
              children: [
                // Completion checkbox
                Checkbox(
                  value: task.status == TaskStatus.completed,
                  onChanged: (value) async {
                    if (value == true) {
                      await taskProvider.completeTask(task.id);
                    } else {
                      // Update task status back to pending
                      final updatedTask = task.copyWith(status: TaskStatus.pending);
                      await taskProvider.updateTask(updatedTask);
                    }
                  },
                  activeColor: Colors.green,
                ),
                // Task title
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed ? TextDecoration.lineThrough : null,
                        ),
                  ),
                ),
                // Priority indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withAlpha(50),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getPriorityText(task.priority),
                    style: TextStyle(
                      color: _getPriorityColor(task.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            // Task details row
            if (task.dueAt != null || task.estMinutes > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 48),
                child: Row(
                  children: [
                    if (task.dueAt != null) ...[
                      Icon(
                        Icons.schedule,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${_formatDate(task.dueAt!)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                      if (task.estMinutes > 0) const SizedBox(width: 16),
                    ],
                    if (task.estMinutes > 0) ...[
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${task.estMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),

            // Task status
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: Row(
                children: [
                  Icon(
                    _getStatusIcon(task.status),
                    size: 16,
                    color: _getStatusColor(task.status),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getStatusText(task.status),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _getStatusColor(task.status),
                          fontWeight: FontWeight.w500,
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

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Icons.schedule;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusText(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Today';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}