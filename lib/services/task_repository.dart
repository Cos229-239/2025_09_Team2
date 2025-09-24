// Import the Task model to work with task data structures
import 'package:studypals/models/task.dart';
// Import database service to access SQLite database operations
import 'package:studypals/services/database_service.dart';
// Import Flutter foundation to check if running on web platform
import 'package:flutter/foundation.dart';
// Import SharedPreferences for web-compatible storage
import 'package:shared_preferences/shared_preferences.dart';
// Import JSON encoding/decoding for data serialization
import 'dart:convert';

/// Repository class handling all database operations for Task entities
/// Provides an abstraction layer between the data layer (SQLite) and business logic
/// All methods are static since this is a stateless data access object
/// 
/// TODO: CRITICAL TASK REPOSITORY LEGACY CODE - SHOULD BE REMOVED  
/// - This entire repository is LEGACY and should be deleted - replaced by TaskProvider with Firestore
/// - Current implementation uses deprecated SQLite/SharedPreferences approach
/// - TaskProvider now handles all task operations through FirestoreService with cloud sync
/// - This file is no longer used anywhere in the application
/// - Need to verify no remaining references to TaskRepository exist in codebase
/// - Delete this file and remove all imports/dependencies once verification complete
/// - Any remaining SQLite task data should be migrated to Firestore if needed
/// - SharedPreferences fallback is also deprecated in favor of Firestore integration
class TaskRepository {
  /// Retrieves all tasks from the database ordered by due date
  /// Tasks without due dates will appear last in the list
  /// @return List of Task objects representing all stored tasks
  static Future<List<Task>> getAllTasks() async {
    // On web, skip SQLite entirely and use SharedPreferences directly
    if (kIsWeb) {
      return await _getTasksFromPrefs();
    }

    // Try SQLite first, fallback to SharedPreferences on mobile if SQLite fails
    try {
      // Get database instance from the database service
      final db = await DatabaseService.database;

      // Query the tasks table, ordering by due date (null values last)
      final results = await db.query('tasks', orderBy: 'due_at ASC');

      // Transform database rows into Task objects
      final tasks = results
          .map((json) => Task(
                id: json['id'] as String, // Extract unique task identifier
                title:
                    json['title'] as String, // Extract task title/description
                estMinutes: json['est_minutes']
                    as int, // Extract estimated completion time

                // Handle nullable due date - parse if exists, otherwise null
                dueAt: json['due_at'] != null
                    ? DateTime.parse(json['due_at']
                        as String) // Parse ISO string to DateTime
                    : null, // No due date set

                priority:
                    json['priority'] as int, // Extract priority level (1-3)

                // Handle nullable tags - split comma-separated string or empty list
                tags: (json['tags'] as String?)?.split(',') ??
                    [], // Convert "tag1,tag2" to ["tag1", "tag2"]

                // Parse status enum from string representation
                status: TaskStatus.values.firstWhere(
                  (e) =>
                      e.toString() ==
                      'TaskStatus.${json['status']}', // Match enum string format
                  orElse: () =>
                      TaskStatus.pending, // Default to pending if invalid
                ),

                // Handle nullable linked note reference
                linkedNoteId: json['linked_note_id']
                    as String?, // Extract note link or null

                // Handle nullable linked deck reference
                linkedDeckId: json['linked_deck_id']
                    as String?, // Extract deck link or null
              ))
          .toList(); // Convert map result to list

      return tasks;
    } catch (e) {
      // Fallback to SharedPreferences for web compatibility
      return await _getTasksFromPrefs();
    }
  }

  /// Fallback method to get tasks from SharedPreferences (web-compatible)
  static Future<List<Task>> _getTasksFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];

      final tasks = <Task>[];
      for (int i = 0; i < tasksJson.length; i++) {
        try {
          final taskStr = tasksJson[i];
          final taskMap = jsonDecode(taskStr) as Map<String, dynamic>;
          final task = Task(
            id: taskMap['id'] as String,
            title: taskMap['title'] as String,
            estMinutes: taskMap['estMinutes'] as int,
            dueAt: taskMap['dueAt'] != null
                ? DateTime.parse(taskMap['dueAt'] as String)
                : null,
            priority: taskMap['priority'] as int,
            tags: List<String>.from(taskMap['tags'] ?? []),
            status: TaskStatus.values.firstWhere(
              (e) => e.toString() == taskMap['status'],
              orElse: () => TaskStatus.pending,
            ),
            linkedNoteId: taskMap['linkedNoteId'] as String?,
            linkedDeckId: taskMap['linkedDeckId'] as String?,
          );
          tasks.add(task);
        } catch (e) {
          // Skip this task and continue with others
        }
      }

      return tasks;
    } catch (e) {
      return <Task>[]; // Return empty list on error
    }
  }

  /// Updates an existing task in SharedPreferences for web platform
  static Future<void> _updateTaskInPrefs(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTasks = prefs.getStringList('tasks') ?? [];

      // Parse existing tasks and find the one to update
      List<Map<String, dynamic>> taskMaps = [];
      bool taskFound = false;

      for (String taskString in existingTasks) {
        Map<String, dynamic> taskMap = jsonDecode(taskString);
        if (taskMap['id'] == task.id) {
          // Update this task
          taskMap = {
            'id': task.id,
            'title': task.title,
            'estMinutes': task.estMinutes,
            'dueAt': task.dueAt?.toIso8601String(),
            'priority': task.priority,
            'tags': task.tags,
            'status': task.status.toString(),
            'linkedNoteId': task.linkedNoteId,
            'linkedDeckId': task.linkedDeckId,
            'createdAt': taskMap['createdAt'], // Keep original creation time
            'updatedAt':
                DateTime.now().toIso8601String(), // Update modification time
          };
          taskFound = true;
        }
        taskMaps.add(taskMap);
      }

      if (!taskFound) {
        return;
      }

      // Convert back to string list and save
      final updatedTasks =
          taskMaps.map((taskMap) => jsonEncode(taskMap)).toList();
      await prefs.setStringList('tasks', updatedTasks);
    } catch (e) {
      rethrow;
    }
  }

  /// Inserts a new task into the database
  /// Automatically sets creation and update timestamps
  /// @param task - Task object to be stored in database
  /// @throws Exception if database insertion fails
  static Future<void> insertTask(Task task) async {
    // On web, skip SQLite entirely and use SharedPreferences directly
    if (kIsWeb) {
      await _saveTaskToPrefs(task);
      return;
    }

    // Try SQLite first, fallback to SharedPreferences on mobile if SQLite fails
    try {
      // Get database instance from the database service
      final db = await DatabaseService.database;

      final taskData = {
        'id': task.id, // Unique task identifier
        'title': task.title, // Task title/description
        'est_minutes': task.estMinutes, // Estimated completion time in minutes
        'due_at': task.dueAt
            ?.toIso8601String(), // Due date as ISO string (null if no deadline)
        'priority': task.priority, // Priority level (1=low, 2=medium, 3=high)
        'tags':
            task.tags.join(','), // Convert tag list to comma-separated string
        'status': task.status
            .toString()
            .split('.')
            .last, // Extract enum name (e.g., "pending" from "TaskStatus.pending")
        'linked_note_id':
            task.linkedNoteId, // Reference to related note (can be null)
        'linked_deck_id':
            task.linkedDeckId, // Reference to related deck (can be null)
        'created_at':
            DateTime.now().toIso8601String(), // Set creation timestamp to now
        'updated_at':
            DateTime.now().toIso8601String(), // Set update timestamp to now
      };

      // Insert task data into tasks table
      await db.insert('tasks', taskData);
    } catch (e) {
      // Fallback to SharedPreferences for web compatibility
      try {
        await _saveTaskToPrefs(task);
      } catch (fallbackError) {
        rethrow;
      }
    }
  }

  /// Fallback method to save task to SharedPreferences (web-compatible)
  static Future<void> _saveTaskToPrefs(Task task) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTasks = prefs.getStringList('tasks') ?? [];

      // Convert task to JSON
      final taskJson = jsonEncode({
        'id': task.id,
        'title': task.title,
        'estMinutes': task.estMinutes,
        'dueAt': task.dueAt?.toIso8601String(),
        'priority': task.priority,
        'tags': task.tags,
        'status': task.status.toString(),
        'linkedNoteId': task.linkedNoteId,
        'linkedDeckId': task.linkedDeckId,
        'createdAt': DateTime.now().toIso8601String(),
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Add new task to list
      existingTasks.add(taskJson);

      // Save back to SharedPreferences
      await prefs.setStringList('tasks', existingTasks);
    } catch (e) {
      rethrow;
    }
  }

  /// Test method to verify SharedPreferences is working
  static Future<void> testSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');
      prefs.getString('test_key');
    } catch (e) {
      // Ignore SharedPreferences test errors
    }
  }

  /// Updates an existing task in the database
  /// Automatically updates the modification timestamp
  /// @param task - Task object with updated data (must have existing ID)
  /// @throws Exception if database update fails or task doesn't exist
  static Future<void> updateTask(Task task) async {
    if (kIsWeb) {
      await _updateTaskInPrefs(task);
      return;
    }

    // Get database instance from the database service
    final db = await DatabaseService.database;

    // Update task record using WHERE clause to match by ID
    await db.update(
      'tasks', // Table name to update
      {
        // Updated field values (ID is not updated as it's the primary key)
        'title': task.title, // New task title/description
        'est_minutes': task.estMinutes, // New estimated completion time
        'due_at': task.dueAt?.toIso8601String(), // New due date as ISO string
        'priority': task.priority, // New priority level
        'tags': task.tags.join(','), // New tags as comma-separated string
        'status':
            task.status.toString().split('.').last, // New status enum name
        'linked_note_id': task.linkedNoteId, // New note reference
        'linked_deck_id': task.linkedDeckId, // New deck reference
        'updated_at':
            DateTime.now().toIso8601String(), // Update modification timestamp
      },
      where: 'id = ?', // WHERE clause to match specific task
      whereArgs: [
        task.id
      ], // Arguments for WHERE clause (prevents SQL injection)
    );
  }

  /// Permanently deletes a task from the database
  /// This operation cannot be undone - task data will be lost forever
  /// @param taskId - Unique identifier of the task to delete
  /// @throws Exception if database deletion fails
  static Future<void> deleteTask(String taskId) async {
    // Get database instance from the database service
    final db = await DatabaseService.database;

    // Delete task record using WHERE clause to match by ID
    await db.delete(
      'tasks', // Table name to delete from
      where: 'id = ?', // WHERE clause to match specific task
      whereArgs: [
        taskId
      ], // Arguments for WHERE clause (prevents SQL injection)
    );
  }
}
