// Import the Task model to work with task data structures
import 'package:studypals/models/task.dart';
// Import database service to access SQLite database operations
import 'package:studypals/services/database_service.dart';

/// Repository class handling all database operations for Task entities
/// Provides an abstraction layer between the data layer (SQLite) and business logic
/// All methods are static since this is a stateless data access object
class TaskRepository {
  
  /// Retrieves all tasks from the database ordered by due date
  /// Tasks without due dates will appear last in the list
  /// @return List of Task objects representing all stored tasks
  static Future<List<Task>> getAllTasks() async {
    // Get database instance from the database service
    final db = await DatabaseService.database;
    
    // Query the tasks table, ordering by due date (null values last)
    final results = await db.query('tasks', orderBy: 'due_at ASC');
    
    // Transform database rows into Task objects
    return results.map((json) => Task(
      id: json['id'] as String,                           // Extract unique task identifier
      title: json['title'] as String,                     // Extract task title/description
      estMinutes: json['est_minutes'] as int,             // Extract estimated completion time
      
      // Handle nullable due date - parse if exists, otherwise null
      dueAt: json['due_at'] != null 
        ? DateTime.parse(json['due_at'] as String)        // Parse ISO string to DateTime
        : null,                                           // No due date set
      
      priority: json['priority'] as int,                  // Extract priority level (1-3)
      
      // Handle nullable tags - split comma-separated string or empty list
      tags: (json['tags'] as String?)?.split(',') ?? [],  // Convert "tag1,tag2" to ["tag1", "tag2"]
      
      // Parse status enum from string representation
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == 'TaskStatus.${json['status']}', // Match enum string format
        orElse: () => TaskStatus.pending,                 // Default to pending if invalid
      ),
      
      // Handle nullable linked note reference
      linkedNoteId: json['linked_note_id'] as String?,   // Extract note link or null
      
      // Handle nullable linked deck reference  
      linkedDeckId: json['linked_deck_id'] as String?,   // Extract deck link or null
    )).toList();                                         // Convert map result to list
  }

  /// Inserts a new task into the database
  /// Automatically sets creation and update timestamps
  /// @param task - Task object to be stored in database
  /// @throws Exception if database insertion fails
  static Future<void> insertTask(Task task) async {
    // Get database instance from the database service
    final db = await DatabaseService.database;
    
    // Insert task data into tasks table
    await db.insert('tasks', {
      'id': task.id,                                      // Unique task identifier
      'title': task.title,                                // Task title/description
      'est_minutes': task.estMinutes,                     // Estimated completion time in minutes
      'due_at': task.dueAt?.toIso8601String(),            // Due date as ISO string (null if no deadline)
      'priority': task.priority,                          // Priority level (1=low, 2=medium, 3=high)
      'tags': task.tags.join(','),                        // Convert tag list to comma-separated string
      'status': task.status.toString().split('.').last,   // Extract enum name (e.g., "pending" from "TaskStatus.pending")
      'linked_note_id': task.linkedNoteId,                // Reference to related note (can be null)
      'linked_deck_id': task.linkedDeckId,                // Reference to related deck (can be null)
      'created_at': DateTime.now().toIso8601String(),     // Set creation timestamp to now
      'updated_at': DateTime.now().toIso8601String(),     // Set update timestamp to now
    });
  }

  /// Updates an existing task in the database
  /// Automatically updates the modification timestamp
  /// @param task - Task object with updated data (must have existing ID)
  /// @throws Exception if database update fails or task doesn't exist
  static Future<void> updateTask(Task task) async {
    // Get database instance from the database service
    final db = await DatabaseService.database;
    
    // Update task record using WHERE clause to match by ID
    await db.update(
      'tasks',                                            // Table name to update
      {
        // Updated field values (ID is not updated as it's the primary key)
        'title': task.title,                              // New task title/description
        'est_minutes': task.estMinutes,                   // New estimated completion time
        'due_at': task.dueAt?.toIso8601String(),          // New due date as ISO string
        'priority': task.priority,                        // New priority level
        'tags': task.tags.join(','),                      // New tags as comma-separated string
        'status': task.status.toString().split('.').last, // New status enum name
        'linked_note_id': task.linkedNoteId,              // New note reference
        'linked_deck_id': task.linkedDeckId,              // New deck reference
        'updated_at': DateTime.now().toIso8601String(),   // Update modification timestamp
      },
      where: 'id = ?',                                    // WHERE clause to match specific task
      whereArgs: [task.id],                               // Arguments for WHERE clause (prevents SQL injection)
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
      'tasks',                                            // Table name to delete from
      where: 'id = ?',                                    // WHERE clause to match specific task
      whereArgs: [taskId],                                // Arguments for WHERE clause (prevents SQL injection)
    );
  }
}
