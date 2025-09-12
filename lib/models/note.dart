/// Data model representing a study note with markdown content and tagging
/// Notes are used for storing study material, lecture notes, and reference content
/// Supports markdown formatting for rich text content and tag-based organization
class Note {
  // Unique identifier for the note (UUID format for cross-platform compatibility)
  final String id;

  // Display title of the note (shown in lists and search results)
  final String title;

  // Note content in markdown format for rich text support (headers, lists, links, etc.)
  final String contentMd;

  // List of tags for categorization and filtering (e.g., ["physics", "chapter1"])
  final List<String> tags;

  // Timestamp when the note was originally created (immutable once set)
  final DateTime createdAt;

  // Timestamp when the note was last modified (updated on each edit)
  final DateTime updatedAt;

  /// Constructor for creating a Note instance
  /// @param id - Unique identifier for the note
  /// @param title - Display title for the note
  /// @param contentMd - Markdown-formatted content
  /// @param tags - Optional list of tags (defaults to empty list)
  /// @param createdAt - Creation timestamp (defaults to current time)
  /// @param updatedAt - Last modified timestamp (defaults to current time)
  Note({
    required this.id, // Must provide unique identifier
    required this.title, // Must provide title for display
    required this.contentMd, // Must provide content (can be empty string)
    this.tags = const [], // Default to empty tag list (const for performance)
    DateTime? createdAt, // Optional, will use current time if null
    DateTime? updatedAt, // Optional, will use current time if null
  })  : createdAt = createdAt ??
            DateTime.now(), // Set creation time to now if not provided
        updatedAt = updatedAt ??
            DateTime.now(); // Set update time to now if not provided

  /// Converts the Note object to a JSON map for database storage or API transmission
  /// Returns [Map] containing all note data in JSON format
  Map<String, dynamic> toJson() => {
        'id': id, // Store unique identifier
        'title': title, // Store display title
        'contentMd': contentMd, // Store markdown content
        'tags': tags, // Store tag list as array
        'createdAt':
            createdAt.toIso8601String(), // Store creation time as ISO string
        'updatedAt':
            updatedAt.toIso8601String(), // Store update time as ISO string
      };

  /// Factory constructor to create a Note from JSON data (database or API)
  /// @param json - Map containing note data from JSON source
  /// @return Note instance populated with JSON data
  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'] as String, // Extract string ID from JSON
        title: json['title'] as String, // Extract string title from JSON
        contentMd:
            json['contentMd'] as String, // Extract markdown content from JSON
        // Convert tags array to List<String>, handle null case with empty list
        tags: List<String>.from((json['tags'] as List?) ?? []),
        // Parse ISO date string back to DateTime object for creation time
        createdAt: DateTime.parse(json['createdAt'] as String),
        // Parse ISO date string back to DateTime object for update time
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  /// Creates a copy of this Note with optionally updated fields
  /// Used for immutable updates - returns new instance instead of modifying existing
  /// @param id - New ID (optional, keeps current if not provided)
  /// @param title - New title (optional, keeps current if not provided)
  /// @param contentMd - New content (optional, keeps current if not provided)
  /// @param tags - New tags (optional, keeps current if not provided)
  /// @param createdAt - New creation time (optional, keeps current if not provided)
  /// @param updatedAt - New update time (optional, keeps current if not provided)
  /// @return New Note instance with updated fields
  Note copyWith({
    String? id, // Optional new ID
    String? title, // Optional new title
    String? contentMd, // Optional new content
    List<String>? tags, // Optional new tag list
    DateTime? createdAt, // Optional new creation time
    DateTime? updatedAt, // Optional new update time
  }) {
    return Note(
      id: id ?? this.id, // Use new ID or keep current
      title: title ?? this.title, // Use new title or keep current
      contentMd: contentMd ?? this.contentMd, // Use new content or keep current
      tags: tags ?? this.tags, // Use new tags or keep current
      createdAt:
          createdAt ?? this.createdAt, // Use new creation time or keep current
      updatedAt:
          updatedAt ?? this.updatedAt, // Use new update time or keep current
    );
  }
}
