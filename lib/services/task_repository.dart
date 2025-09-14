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
class TaskRepository {
  /// Retrieves all tasks from the database ordered by due date
  /// Tasks without due dates will appear last in the list
  /// @return List of Task objects representing all stored tasks
  static Future<List<Task>> getAllTasks() async {
    print('TaskRepository: getAllTasks() called');
    
    // On web, skip SQLite entirely and use SharedPreferences directly
    if (kIsWeb) {
      print('TaskRepository: Web platform detected, using SharedPreferences directly');
      return await _getTasksFromPrefs();
    }
    
    // Try SQLite first, fallback to SharedPreferences on mobile if SQLite fails
    try {
      // Get database instance from the database service
      final db = await DatabaseService.database;
      print('TaskRepository: Got SQLite database instance');

      // Query the tasks table, ordering by due date (null values last)
      final results = await db.query('tasks', orderBy: 'due_at ASC');
      print('TaskRepository: SQLite query returned ${results.length} rows');

      // Transform database rows into Task objects
      final tasks = results
          .map((json) => Task(
                id: json['id'] as String, // Extract unique task identifier
                title: json['title'] as String, // Extract task title/description
                estMinutes: json['est_minutes']
                    as int, // Extract estimated completion time

                // Handle nullable due date - parse if exists, otherwise null
                dueAt: json['due_at'] != null
                    ? DateTime.parse(
                        json['due_at'] as String) // Parse ISO string to DateTime
                    : null, // No due date set

                priority: json['priority'] as int, // Extract priority level (1-3)

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
      
      print('TaskRepository: Loaded ${tasks.length} tasks from SQLite');
      return tasks;
    } catch (e) {
      print('TaskRepository: SQLite failed: $e');
      print('TaskRepository: Using SharedPreferences fallback');
      // Fallback to SharedPreferences for web compatibility
      return await _getTasksFromPrefs();
    }
  }

  /// Fallback method to get tasks from SharedPreferences (web-compatible)
  static Future<List<Task>> _getTasksFromPrefs() async {
    print('TaskRepository: _getTasksFromPrefs() called');
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = prefs.getStringList('tasks') ?? [];
      print('TaskRepository: Found ${tasksJson.length} tasks in SharedPreferences');
      
      final tasks = <Task>[];
      for (int i = 0; i < tasksJson.length; i++) {
        try {
          final taskStr = tasksJson[i];
          print('TaskRepository: Parsing task $i: $taskStr');
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
          print('TaskRepository: Successfully parsed task "${task.title}"');
        } catch (e) {
          print('TaskRepository: Error parsing task $i: $e');
          // Skip this task and continue with others
        }
      }
      
      print('TaskRepository: Loaded ${tasks.length} tasks from SharedPreferences');
      for (var task in tasks) {
        print('  - TaskRepository (Prefs): "${task.title}" (ID: ${task.id}, Status: ${task.status})');
      }
      
      return tasks;
    } catch (e) {
      print('TaskRepository: Error in _getTasksFromPrefs: $e');
      return <Task>[]; // Return empty list on error
    }
  }

  /// Updates an existing task in SharedPreferences for web platform
  static Future<void> _updateTaskInPrefs(Task task) async {
    print('TaskRepository: _updateTaskInPrefs() called for "${task.title}" (ID: ${task.id})');
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTasks = prefs.getStringList('tasks') ?? [];
      print('TaskRepository: Found ${existingTasks.length} existing tasks in SharedPreferences');
      
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
            'updatedAt': DateTime.now().toIso8601String(), // Update modification time
          };
          taskFound = true;
          print('TaskRepository: Updated task "${task.title}" with status ${task.status}');
        }
        taskMaps.add(taskMap);
      }
      
      if (!taskFound) {
        print('TaskRepository: Warning - Task with ID ${task.id} not found for update');
        return;
      }
      
      // Convert back to string list and save
      final updatedTasks = taskMaps.map((taskMap) => jsonEncode(taskMap)).toList();
      final saveResult = await prefs.setStringList('tasks', updatedTasks);
      print('TaskRepository: SharedPreferences update result: $saveResult. Total tasks: ${updatedTasks.length}');
      
      // Verification
      final verification = prefs.getStringList('tasks') ?? [];
      print('TaskRepository: Verification - found ${verification.length} tasks after update');
      
    } catch (e) {
      print('TaskRepository: Error in _updateTaskInPrefs: $e');
      rethrow;
    }
  }

  /// Inserts a new task into the database
  /// Automatically sets creation and update timestamps
  /// @param task - Task object to be stored in database
  /// @throws Exception if database insertion fails
  static Future<void> insertTask(Task task) async {
    print('TaskRepository: insertTask() called for "${task.title}" (ID: ${task.id})');
    
    // On web, skip SQLite entirely and use SharedPreferences directly
    if (kIsWeb) {
      print('TaskRepository: Web platform detected, using SharedPreferences directly');
      await _saveTaskToPrefs(task);
      return;
    }
    
    // Try SQLite first, fallback to SharedPreferences on mobile if SQLite fails
    try {
      print('TaskRepository: Attempting to get SQLite database instance...');
      // Get database instance from the database service
      final db = await DatabaseService.database;
      print('TaskRepository: Got SQLite database instance');

      final taskData = {
        'id': task.id, // Unique task identifier
        'title': task.title, // Task title/description
        'est_minutes': task.estMinutes, // Estimated completion time in minutes
        'due_at': task.dueAt
            ?.toIso8601String(), // Due date as ISO string (null if no deadline)
        'priority': task.priority, // Priority level (1=low, 2=medium, 3=high)
        'tags': task.tags.join(','), // Convert tag list to comma-separated string
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

      print('TaskRepository: About to insert into SQLite...');
      // Insert task data into tasks table
      await db.insert('tasks', taskData);
      print('TaskRepository: Task inserted successfully into SQLite');
    } catch (e) {
      print('TaskRepository: SQLite insert failed: $e');
      print('TaskRepository: Using SharedPreferences fallback');
      // Fallback to SharedPreferences for web compatibility
      try {
        await _saveTaskToPrefs(task);
        print('TaskRepository: SharedPreferences fallback completed successfully');
      } catch (fallbackError) {
        print('TaskRepository: SharedPreferences fallback also failed: $fallbackError');
        rethrow;
      }
    }
  }

  /// Fallback method to save task to SharedPreferences (web-compatible)
  static Future<void> _saveTaskToPrefs(Task task) async {
    print('TaskRepository: _saveTaskToPrefs() called for "${task.title}"');
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingTasks = prefs.getStringList('tasks') ?? [];
      print('TaskRepository: Found ${existingTasks.length} existing tasks in SharedPreferences');
      
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
      
      print('TaskRepository: Task JSON: $taskJson');
      
      // Add new task to list
      existingTasks.add(taskJson);
      
      // Save back to SharedPreferences
      final success = await prefs.setStringList('tasks', existingTasks);
      print('TaskRepository: SharedPreferences save result: $success. Total tasks: ${existingTasks.length}');
      
      // Verify the save worked
      final verifyTasks = prefs.getStringList('tasks') ?? [];
      print('TaskRepository: Verification - found ${verifyTasks.length} tasks after save');
      
    } catch (e) {
      print('TaskRepository: Error in _saveTaskToPrefs: $e');
      rethrow;
    }
  }

  /// Test method to verify SharedPreferences is working
  static Future<void> testSharedPreferences() async {
    print('TaskRepository: testSharedPreferences() called');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('test_key', 'test_value');
      final result = prefs.getString('test_key');
      print('TaskRepository: SharedPreferences test - wrote "test_value", read "$result"');
    } catch (e) {
      print('TaskRepository: SharedPreferences test failed: $e');
    }
  }

  /// Updates an existing task in the database
  /// Automatically updates the modification timestamp
  /// @param task - Task object with updated data (must have existing ID)
  /// @throws Exception if database update fails or task doesn't exist
  static Future<void> updateTask(Task task) async {
    print('TaskRepository: updateTask() called for "${task.title}" (ID: ${task.id})');
    
    if (kIsWeb) {
      print('TaskRepository: Web platform detected, using SharedPreferences for update');
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
