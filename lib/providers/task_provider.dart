// Import Flutter's foundation library for ChangeNotifier (state management base class)
import 'package:flutter/foundation.dart';
// Import Dart's developer tools for proper logging instead of print statements
import 'dart:developer' as developer;
// Import the Task model representing individual to-do items
import 'package:studypals/models/task.dart';
// Import Firebase Auth for user authentication
import 'package:firebase_auth/firebase_auth.dart';
// Import Firestore service for database operations
import 'package:studypals/services/firestore_service.dart';
// Import Activity service for tracking user activities
import 'package:studypals/services/activity_service.dart';
import 'package:studypals/models/activity.dart';

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

  // Firestore service instance for database operations
  final FirestoreService _firestoreService = FirestoreService();

  // Firebase Auth instance for user authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    _isLoading = true; // Set loading flag to show UI indicators
    notifyListeners(); // Update UI to show loading state

    try {
      // Get current user
      final user = _auth.currentUser;

      if (user != null) {
        // Fetch tasks from Firestore for the current user
        final taskMaps = await _firestoreService.getUserFullTasks(user.uid);
        _tasks = taskMaps
            .map((taskMap) => _convertFirestoreToTask(taskMap))
            .toList();
      } else {
        // No user logged in, use empty list
        _tasks = [];
      }

      // Sample tasks removed - now only shows tasks from Firestore
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

  /// Helper method to convert Firestore document data to Task object
  Task _convertFirestoreToTask(Map<String, dynamic> data) {
    return Task(
      id: data['id'] as String,
      title: data['title'] as String,
      estMinutes: data['estMinutes'] as int,
      dueAt: data['dueAt'] != null
          ? (data['dueAt'] as dynamic).toDate() as DateTime
          : null,
      priority: data['priority'] as int? ?? 1,
      tags: List<String>.from(data['tags'] ?? []),
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TaskStatus.pending,
      ),
      linkedNoteId: data['linkedNoteId'] as String?,
      linkedDeckId: data['linkedDeckId'] as String?,
    );
  }

  /// Adds a new task to both the database and local task list
  /// Immediately updates the UI optimistically after database insertion
  /// @param task - New task object to add
  /// @throws Exception if database insertion fails
  Future<void> addTask(Task task) async {
    try {
      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // Convert Task to Firestore-compatible data
      final taskData = task.toJson();
      taskData.remove('id'); // Remove ID as Firestore will generate it

      // Save to Firestore
      final docId = await _firestoreService.createFullTask(user.uid, taskData);
      if (docId == null) {
        throw Exception('Failed to create task in Firestore');
      }

      // Create task with Firestore-generated ID and add to local list
      final taskWithId = task.copyWith(id: docId);
      _tasks.add(taskWithId); // Add to local task list
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
      // Convert Task to Firestore-compatible data
      final taskData = task.toJson();
      taskData.remove('id'); // Remove ID as it shouldn't be updated

      // Update in Firestore
      final success = await _firestoreService.updateFullTask(task.id, taskData);
      if (!success) {
        throw Exception('Failed to update task in Firestore');
      }

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
      // Delete from Firestore (soft delete - archives the task)
      final success = await _firestoreService.deleteFullTask(taskId);
      if (!success) {
        throw Exception('Failed to delete task in Firestore');
      }

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
    
    // Log activity
    try {
      final activityService = ActivityService();
      await activityService.logActivity(
        type: ActivityType.taskCompleted,
        description: 'Completed task: ${task.title}',
        metadata: {'taskId': taskId, 'taskTitle': task.title},
      );
    } catch (e) {
      debugPrint('Failed to log task completion activity: $e');
    }
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
