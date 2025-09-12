// Import the FlashCard model to define the cards contained in this deck
import 'package:studypals/models/card.dart';

/// Data model representing a collection of flashcards organized into a study deck
/// Decks group related flashcards together for organized study sessions
/// Can be linked to notes for auto-generated cards from study material
class Deck {
  // Unique identifier for the deck (UUID format for cross-platform compatibility)
  final String id;
  
  // Display title of the deck (shown in deck lists and study sessions)
  final String title;
  
  // List of tags for categorization and filtering (e.g., ["math", "algebra"])
  final List<String> tags;
  
  // Optional link to a note that this deck was generated from (null if manually created)
  final String? noteId;
  
  // List of flashcards contained in this deck for study sessions
  final List<FlashCard> cards;
  
  // Timestamp when the deck was originally created (immutable once set)
  final DateTime createdAt;
  
  // Timestamp when the deck was last modified (updated when cards added/removed)
  final DateTime updatedAt;

  /// Constructor for creating a Deck instance
  /// @param id - Unique identifier for the deck
  /// @param title - Display title for the deck
  /// @param tags - Optional list of tags (defaults to empty list)
  /// @param noteId - Optional link to source note (null for manual decks)
  /// @param cards - Optional list of cards (defaults to empty list)
  /// @param createdAt - Creation timestamp (defaults to current time)
  /// @param updatedAt - Last modified timestamp (defaults to current time)
  Deck({
    required this.id,              // Must provide unique identifier
    required this.title,           // Must provide title for display
    this.tags = const [],          // Default to empty tag list (const for performance)
    this.noteId,                   // Optional note link (null for standalone decks)
    this.cards = const [],         // Default to empty card list (const for performance)
    DateTime? createdAt,           // Optional, will use current time if null
    DateTime? updatedAt,           // Optional, will use current time if null
  }) : createdAt = createdAt ?? DateTime.now(),  // Set creation time to now if not provided
        updatedAt = updatedAt ?? DateTime.now(); // Set update time to now if not provided

  /// Converts the Deck object to a JSON map for database storage or API transmission
  /// Returns [Map] containing all deck data in JSON format
  Map<String, dynamic> toJson() => {
    'id': id,                                      // Store unique identifier
    'title': title,                                // Store display title
    'tags': tags,                                  // Store tag list as array
    'noteId': noteId,                              // Store note link (can be null)
    // Convert each card to JSON and store as array of card objects
    'cards': cards.map((c) => c.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),      // Store creation time as ISO string
    'updatedAt': updatedAt.toIso8601String(),      // Store update time as ISO string
  };

  /// Factory constructor to create a Deck from JSON data (database or API)
  /// @param json - Map containing deck data from JSON source
  /// @return Deck instance populated with JSON data
  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
    id: json['id'] as String,                      // Extract string ID from JSON
    title: json['title'] as String,                // Extract string title from JSON
    // Convert tags array to List<String>, handle null case with empty list
    tags: List<String>.from((json['tags'] as List?) ?? []),
    noteId: json['noteId'] as String?,             // Extract optional note ID (can be null)
    // Convert cards array to List<FlashCard>, handle null case with empty list
    cards: (json['cards'] as List?)
        ?.map((c) => FlashCard.fromJson(c as Map<String, dynamic>))  // Parse each card from JSON
        .toList() ?? [],                           // Default to empty list if null
    // Parse ISO date string back to DateTime object for creation time
    createdAt: DateTime.parse(json['createdAt'] as String),
    // Parse ISO date string back to DateTime object for update time
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  /// Creates a copy of this Deck with optionally updated fields
  /// Used for immutable updates - returns new instance instead of modifying existing
  /// @param id - New ID (optional, keeps current if not provided)
  /// @param title - New title (optional, keeps current if not provided)
  /// @param tags - New tags (optional, keeps current if not provided)
  /// @param noteId - New note link (optional, keeps current if not provided)
  /// @param cards - New card list (optional, keeps current if not provided)
  /// @param createdAt - New creation time (optional, keeps current if not provided)
  /// @param updatedAt - New update time (optional, keeps current if not provided)
  /// @return New Deck instance with updated fields
  Deck copyWith({
    String? id,                    // Optional new ID
    String? title,                 // Optional new title
    List<String>? tags,            // Optional new tag list
    String? noteId,                // Optional new note link
    List<FlashCard>? cards,        // Optional new card list
    DateTime? createdAt,           // Optional new creation time
    DateTime? updatedAt,           // Optional new update time
  }) {
    return Deck(
      id: id ?? this.id,                          // Use new ID or keep current
      title: title ?? this.title,                // Use new title or keep current
      tags: tags ?? this.tags,                   // Use new tags or keep current
      noteId: noteId ?? this.noteId,             // Use new note link or keep current
      cards: cards ?? this.cards,               // Use new cards or keep current
      createdAt: createdAt ?? this.createdAt,    // Use new creation time or keep current
      updatedAt: updatedAt ?? this.updatedAt,    // Use new update time or keep current
    );
  }
}
