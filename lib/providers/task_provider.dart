// Import Flutter's foundation library for ChangeNotifier (state management base class)
import 'package:flutter/foundation.dart';
// Import Dart's developer tools for proper logging instead of print statements
import 'dart:developer' as developer;
// Import the Task model representing individual to-do items
import 'package:studypals/models/task.dart';
// Import the repository for database operations on tasks
import 'package:studypals/services/task_repository.dart';

/// Task management provider handling all task-related state and operations
/// This class manages the list of tasks, loading states, and provides filtered views
/// Extends ChangeNotifier to automatically update UI when task data changes
class TaskProvider extends ChangeNotifier {
  // Private list storing all tasks loaded from the database
  // Starts empty and gets populated when loadTasks() is called
  List<Task> _tasks = [];

  // Private boolean tracking whether an async operation is in progress
  // Used to show loading indicators in the UI
  bool _isLoading = false;

  /// Public getter providing read-only access to all tasks
  /// UI widgets use this to display task lists
  /// @return Immutable list of all tasks
  List<Task> get tasks => _tasks;

  /// Public getter indicating if any async operation is currently running
  /// UI can show loading spinners or disable buttons when this is true
  /// @return true if loading, false if ready for user interaction
  bool get isLoading => _isLoading;

  /// Computed property returning tasks due today that aren't completed
  /// Filters tasks to show only those with today's date that need attention
  /// @return List of incomplete tasks due today
  List<Task> get todayTasks {
    final today = DateTime.now(); // Get current date and time
    return _tasks.where((task) {
      // Filter the task list
      if (task.dueAt == null) return false; // Skip tasks with no due date
      return task.dueAt!.day == today.day && // Same day
          task.dueAt!.month == today.month && // Same month
          task.dueAt!.year == today.year && // Same year
          task.status != TaskStatus.completed; // Not already completed
    }).toList(); // Convert filtered result to list
  }

  /// Computed property returning all tasks that haven't been started
  /// Used to show the backlog of work that needs attention
  /// @return List of tasks with pending status
  List<Task> get pendingTasks {
    return _tasks.where((task) => task.status == TaskStatus.pending).toList();
  }

  /// Loads all tasks from the database and updates the local task list
  /// This is typically called when the app starts or when refreshing data
  /// Shows loading state during the operation and handles errors gracefully
  Future<void> loadTasks() async {
    // Test SharedPreferences first
    await TaskRepository.testSharedPreferences();
    
    _isLoading = true; // Set loading flag to show UI indicators
    notifyListeners(); // Update UI to show loading state

    try {
      // Attempt to fetch all tasks from the database repository
      _tasks = await TaskRepository.getAllTasks();
      
      // Add sample tasks if list is empty (for demonstration)
      if (_tasks.isEmpty) {
        final sampleTasks = [
          Task(
            id: 'task_1',
            title: 'Complete JavaScript Assignment',
            estMinutes: 120,
            dueAt: DateTime.now().add(const Duration(days: 2)),
            priority: 3,
            tags: ['javascript', 'assignment', 'urgent'],
            status: TaskStatus.pending,
          ),
          Task(
            id: 'task_2',
            title: 'Review React Documentation',
            estMinutes: 60,
            dueAt: DateTime.now().add(const Duration(days: 1)),
            priority: 2,
            tags: ['react', 'study', 'documentation'],
            status: TaskStatus.inProgress,
          ),
          Task(
            id: 'task_3',
            title: 'Practice SQL Queries',
            estMinutes: 90,
            dueAt: DateTime.now().add(const Duration(hours: 8)),
            priority: 2,
            tags: ['sql', 'database', 'practice'],
            status: TaskStatus.pending,
          ),
          Task(
            id: 'task_4',
            title: 'Study Database Normalization',
            estMinutes: 45,
            dueAt: DateTime.now().subtract(const Duration(days: 1)),
            priority: 1,
            tags: ['database', 'theory'],
            status: TaskStatus.completed,
          ),
          Task(
            id: 'task_5',
            title: 'Set up Development Environment',
            estMinutes: 30,
            priority: 1,
            tags: ['setup', 'tools'],
            status: TaskStatus.completed,
          ),
        ];
        
        _tasks.addAll(sampleTasks);
      }
    } catch (e) {
      // Log any errors that occur during loading for debugging
      // Using developer.log instead of print for better debugging tools
      developer.log('Error loading tasks: $e', name: 'TaskProvider');
    } finally {
      // Always clear loading state, whether successful or not
      _isLoading = false; // Clear loading flag
      notifyListeners(); // Update UI to hide loading state
    }
  }

  /// Adds a new task to both the database and local task list
  /// Immediately updates the UI optimistically after database insertion
  /// @param task - New task object to add
  /// @throws Exception if database insertion fails
  Future<void> addTask(Task task) async {
    try {
      // First save to database to ensure persistence
      await TaskRepository.insertTask(task);

      // Add to local list only after successful database insertion
      _tasks.add(task); // Add to local task list
      notifyListeners(); // Update UI to show new task
    } catch (e) {
      // Log the error for debugging purposes
      developer.log('Error adding task: $e', name: 'TaskProvider');

      // Rethrow the exception so calling code can handle the error
      // This allows UI to show error messages to the user
      rethrow;
    }
  }

  /// Updates an existing task in both database and local list
  /// Finds the task by ID and replaces it with the updated version
  /// @param task - Updated task object with same ID as existing task
  /// @throws Exception if database update fails
  Future<void> updateTask(Task task) async {
    try {
      // First update in database to ensure persistence
      await TaskRepository.updateTask(task);

      // Find the task in local list by matching ID
      final index = _tasks.indexWhere((t) => t.id == task.id);

      // Update local list only if task was found
      if (index != -1) {
        // Check if task was found
        _tasks[index] = task; // Replace with updated task
        notifyListeners(); // Update UI to show changes
      }
    } catch (e) {
      // Log the error for debugging purposes
      developer.log('Error updating task: $e', name: 'TaskProvider');

      // Rethrow the exception so calling code can handle the error
      rethrow;
    }
  }

  /// Removes a task from both database and local list
  /// Permanently deletes the task - this action cannot be undone
  /// @param taskId - Unique identifier of the task to delete
  /// @throws Exception if database deletion fails
  Future<void> deleteTask(String taskId) async {
    try {
      // First delete from database to ensure permanent removal
      await TaskRepository.deleteTask(taskId);

      // Remove from local list only after successful database deletion
      _tasks.removeWhere(
          (task) => task.id == taskId); // Filter out the deleted task
      notifyListeners(); // Update UI to hide deleted task
    } catch (e) {
      // Log the error for debugging purposes
      developer.log('Error deleting task: $e', name: 'TaskProvider');

      // Rethrow the exception so calling code can handle the error
      rethrow;
    }
  }

  /// Marks a specific task as completed
  /// This is a convenience method that finds the task and updates its status
  /// @param taskId - Unique identifier of the task to complete
  Future<void> completeTask(String taskId) async {
    // Find the task in the local list by ID
    final task = _tasks.firstWhere((t) => t.id == taskId);

    // Create a new task object with completed status (immutable update pattern)
    final completedTask = task.copyWith(status: TaskStatus.completed);

    // Use the existing updateTask method to save the status change
    await updateTask(completedTask);
  }

  /// Searches tasks by title, tags, or linked content using case-insensitive matching
  /// Returns all tasks if query is empty, filtered tasks otherwise
  /// @param query - Search string to match against task data
  /// @return List of Task objects matching the search criteria
  List<Task> searchTasks(String query) {
    // Return all tasks if no search query provided
    if (query.isEmpty) return _tasks;

    // Filter tasks based on title or tag matches
    return _tasks.where((task) {
      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      // Check if title contains the search query
      final titleMatch = task.title.toLowerCase().contains(lowerQuery);

      // Check if any tag contains the search query
      final tagMatch =
          task.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));

      // Return true if any field matches the search query
      return titleMatch || tagMatch;
    }).toList();
  }
}
