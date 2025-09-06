/// Data model representing an individual flashcard within a deck
/// Supports different card types for various study methods (basic, cloze deletion, reverse)
/// Cards contain question/answer content and link to their parent deck
class FlashCard {
  // Unique identifier for the card (UUID format for cross-platform compatibility)
  final String id;
  
  // ID of the deck this card belongs to (foreign key relationship)
  final String deckId;
  
  // Type of flashcard determining the study behavior (basic, cloze, reverse)
  final CardType type;
  
  // Front side content (question, prompt, or cloze text)
  final String front;
  
  // Back side content (answer, explanation, or solution)
  final String back;
  
  // Optional cloze deletion pattern for cloze cards (e.g., "{{c1::answer}}")
  final String? clozeMask;

  /// Constructor for creating a FlashCard instance
  /// @param id - Unique identifier for the card
  /// @param deckId - ID of the parent deck containing this card
  /// @param type - Card type determining study behavior
  /// @param front - Front side content (question/prompt)
  /// @param back - Back side content (answer/explanation)
  /// @param clozeMask - Optional cloze deletion pattern (only for cloze cards)
  FlashCard({
    required this.id,              // Must provide unique identifier
    required this.deckId,          // Must link to parent deck
    required this.type,            // Must specify card type for proper display
    required this.front,           // Must provide front content
    required this.back,            // Must provide back content
    this.clozeMask,                // Optional cloze pattern (null for non-cloze cards)
  });

  /// Converts the FlashCard object to a JSON map for database storage or API transmission
  /// @return Map<String, dynamic> containing all card data in JSON format
  Map<String, dynamic> toJson() => {
    'id': id,                                      // Store unique identifier
    'deckId': deckId,                              // Store parent deck reference
    'type': type.toString(),                       // Store card type as string enum
    'front': front,                                // Store front side content
    'back': back,                                  // Store back side content
    'clozeMask': clozeMask,                        // Store cloze pattern (can be null)
  };

  /// Factory constructor to create a FlashCard from JSON data (database or API)
  /// @param json - Map containing card data from JSON source
  /// @return FlashCard instance populated with JSON data
  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
    id: json['id'] as String,                      // Extract string ID from JSON
    deckId: json['deckId'] as String,              // Extract parent deck ID from JSON
    // Parse card type from string back to enum, default to basic if invalid
    type: CardType.values.firstWhere(
      (e) => e.toString() == json['type'],         // Find matching enum value
      orElse: () => CardType.basic,                // Default to basic type if not found
    ),
    front: json['front'] as String,                // Extract front content from JSON
    back: json['back'] as String,                  // Extract back content from JSON
    clozeMask: json['clozeMask'] as String?,       // Extract optional cloze pattern
  );
}

/// Enumeration defining the different types of flashcards supported
/// Each type has different behavior during study sessions
enum CardType { 
  basic,    // Traditional front/back cards (question → answer)
  cloze,    // Cloze deletion cards with fill-in-the-blank sections
  reverse   // Bidirectional cards that can be studied both ways
}
