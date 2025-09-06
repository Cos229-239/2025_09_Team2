/// Task model representing a to-do item or assignment in the StudyPals app
/// Can be linked to notes or flashcard decks for integrated studying
class Task {
  // Unique identifier for the task
  final String id;
  // Title/description of what needs to be done
  final String title;
  // Estimated time to complete the task in minutes
  final int estMinutes;
  // Optional deadline for when the task should be completed
  final DateTime? dueAt;
  // Priority level (1 = low, 2 = medium, 3 = high)
  final int priority;
  // List of tags for categorizing and filtering tasks
  final List<String> tags;
  // Current status of the task (pending, in progress, completed, cancelled)
  final TaskStatus status;
  // Optional ID linking this task to a specific note
  final String? linkedNoteId;
  // Optional ID linking this task to a specific flashcard deck
  final String? linkedDeckId;

  /// Constructor for creating a Task instance
  /// @param id - Required unique identifier
  /// @param title - Required task description
  /// @param estMinutes - Required time estimate in minutes
  /// @param dueAt - Optional deadline
  /// @param priority - Priority level (defaults to 1)
  /// @param tags - List of tags (defaults to empty list)
  /// @param status - Task status (defaults to pending)
  /// @param linkedNoteId - Optional note ID for linking
  /// @param linkedDeckId - Optional deck ID for linking
  Task({
    required this.id,                           // Must provide unique ID
    required this.title,                        // Must provide task title
    required this.estMinutes,                   // Must provide time estimate
    this.dueAt,                                 // Optional deadline
    this.priority = 1,                          // Default to low priority
    this.tags = const [],                       // Default to no tags
    this.status = TaskStatus.pending,           // Default to pending status
    this.linkedNoteId,                          // Optional note link
    this.linkedDeckId,                          // Optional deck link
  });

  /// Converts Task object to JSON map for database storage
  /// @return Map containing all task data in JSON-serializable format
  Map<String, dynamic> toJson() => {
    'id': id,                                   // Store ID as string
    'title': title,                             // Store title as string
    'estMinutes': estMinutes,                   // Store time estimate as integer
    'dueAt': dueAt?.toIso8601String(),          // Convert DateTime to ISO string (null if no deadline)
    'priority': priority,                       // Store priority as integer
    'tags': tags,                               // Store tags as list of strings
    'status': status.toString(),                // Convert enum to string representation
    'linkedNoteId': linkedNoteId,               // Store linked note ID (null if not linked)
    'linkedDeckId': linkedDeckId,               // Store linked deck ID (null if not linked)
  };

  /// Creates Task object from JSON map (from database or API)
  /// @param json - Map containing task data
  /// @return New Task instance populated with data from JSON
  factory Task.fromJson(Map<String, dynamic> json) => Task(
    id: json['id'] as String,                   // Extract ID as string
    title: json['title'] as String,             // Extract title as string
    estMinutes: json['estMinutes'] as int,      // Extract time estimate as integer
    dueAt: json['dueAt'] != null                // Check if deadline exists
        ? DateTime.parse(json['dueAt'] as String) // Parse ISO string to DateTime if present
        : null,                                 // Set to null if no deadline
    priority: (json['priority'] as int?) ?? 1,  // Extract priority, default to 1 if missing
    tags: List<String>.from(json['tags'] ?? []), // Convert tags to List<String>, default to empty if missing
    status: TaskStatus.values.firstWhere(       // Find matching enum value
      (e) => e.toString() == json['status'],     // Compare string representations
      orElse: () => TaskStatus.pending,          // Default to pending if no match found
    ),
    linkedNoteId: json['linkedNoteId'] as String?, // Extract note ID (can be null)
    linkedDeckId: json['linkedDeckId'] as String?, // Extract deck ID (can be null)
  );

  /// Creates a copy of this Task with optionally modified fields
  /// Used for updating tasks without mutating the original object
  /// @param id - New ID (optional, keeps current if not provided)
  /// @param title - New title (optional)
  /// @param estMinutes - New time estimate (optional)
  /// @param dueAt - New deadline (optional)
  /// @param priority - New priority (optional)
  /// @param tags - New tags (optional)
  /// @param status - New status (optional)
  /// @param linkedNoteId - New note link (optional)
  /// @param linkedDeckId - New deck link (optional)
  /// @return New Task instance with updated fields
  Task copyWith({
    String? id,             // Optional new ID
    String? title,          // Optional new title
    int? estMinutes,        // Optional new time estimate
    DateTime? dueAt,        // Optional new deadline
    int? priority,          // Optional new priority
    List<String>? tags,     // Optional new tags
    TaskStatus? status,     // Optional new status
    String? linkedNoteId,   // Optional new note link
    String? linkedDeckId,   // Optional new deck link
  }) {
    return Task(
      id: id ?? this.id,                               // Use new ID or keep current
      title: title ?? this.title,                     // Use new title or keep current
      estMinutes: estMinutes ?? this.estMinutes,       // Use new estimate or keep current
      dueAt: dueAt ?? this.dueAt,                     // Use new deadline or keep current
      priority: priority ?? this.priority,             // Use new priority or keep current
      tags: tags ?? this.tags,                         // Use new tags or keep current
      status: status ?? this.status,                   // Use new status or keep current
      linkedNoteId: linkedNoteId ?? this.linkedNoteId, // Use new note link or keep current
      linkedDeckId: linkedDeckId ?? this.linkedDeckId, // Use new deck link or keep current
    );
  }
}

/// Enumeration of possible task statuses
/// Represents the lifecycle of a task from creation to completion
enum TaskStatus { 
  pending,      // Task has been created but not started
  inProgress,   // Task is currently being worked on
  completed,    // Task has been finished successfully
  cancelled     // Task has been abandoned or is no longer needed
}
