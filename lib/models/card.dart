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

  // Multiple choice options for quiz mode (4 options including correct answer)
  final List<String> multipleChoiceOptions;

  // Index of the correct answer in multipleChoiceOptions (0-3)
  final int correctAnswerIndex;

  // Difficulty rating from 1-5 (affects EXP rewards)
  final int difficulty;

  // Timestamp of last quiz attempt for cooldown enforcement
  final DateTime? lastQuizAttempt;

  // Whether the last quiz attempt was correct
  final bool? lastQuizCorrect;

  // Multi-modal content fields for enhanced learning experiences
  final String? imageUrl; // URL to generated visual representation
  final String? audioUrl; // URL to generated audio content
  final String? diagramData; // JSON data for interactive diagrams
  final Map<String, String>? visualMetadata; // Additional visual content info

  /// Constructor for creating a FlashCard instance
  /// @param id - Unique identifier for the card
  /// @param deckId - ID of the parent deck containing this card
  /// @param type - Card type determining study behavior
  /// @param front - Front side content (question/prompt)
  /// @param back - Back side content (answer/explanation)
  /// @param clozeMask - Optional cloze deletion pattern (only for cloze cards)
  /// @param multipleChoiceOptions - List of 4 quiz options
  /// @param correctAnswerIndex - Index (0-3) of correct answer in options
  /// @param difficulty - Difficulty rating 1-5 for EXP calculation
  /// @param lastQuizAttempt - When user last attempted quiz for this card
  /// @param lastQuizCorrect - Whether last quiz attempt was correct
  FlashCard({
    required this.id, // Must provide unique identifier
    required this.deckId, // Must link to parent deck
    required this.type, // Must specify card type for proper display
    required this.front, // Must provide front content
    required this.back, // Must provide back content
    this.clozeMask, // Optional cloze pattern (null for non-cloze cards)
    this.multipleChoiceOptions =
        const [], // Default to empty list for existing cards
    this.correctAnswerIndex = 0, // Default to first option
    this.difficulty = 3, // Default to medium difficulty
    this.lastQuizAttempt, // No quiz attempt initially
    this.lastQuizCorrect, // No quiz result initially
    this.imageUrl, // Optional visual content URL
    this.audioUrl, // Optional audio content URL
    this.diagramData, // Optional diagram JSON data
    this.visualMetadata, // Optional visual metadata
  });

  /// Checks if quiz is available (not in cooldown period)
  /// @return true if user can take quiz, false if in cooldown
  bool get canTakeQuiz {
    if (lastQuizAttempt == null) return true; // Never attempted

    // For both correct and incorrect answers, enforce a cooldown
    final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
    final sixHoursAgo = DateTime.now().subtract(const Duration(hours: 6));

    if (lastQuizCorrect == true) {
      // Correct answers have a 1-hour cooldown to prevent spam
      return lastQuizAttempt!.isBefore(oneHourAgo);
    } else {
      // Incorrect answers have a 6-hour cooldown
      return lastQuizAttempt!.isBefore(sixHoursAgo);
    }
  }

  /// Gets time remaining until quiz becomes available again
  /// @return Duration until quiz cooldown expires, or Duration.zero if available
  Duration get quizCooldownRemaining {
    if (lastQuizAttempt == null) return Duration.zero;

    if (lastQuizCorrect == true) {
      // 1-hour cooldown for correct answers
      final oneHourAfterAttempt =
          lastQuizAttempt!.add(const Duration(hours: 1));
      final remaining = oneHourAfterAttempt.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    } else {
      // 6-hour cooldown for incorrect answers
      final sixHoursAfterAttempt =
          lastQuizAttempt!.add(const Duration(hours: 6));
      final remaining = sixHoursAfterAttempt.difference(DateTime.now());
      return remaining.isNegative ? Duration.zero : remaining;
    }
  }

  /// Gets the quiz status for UI display
  /// @return String describing the quiz state
  String get quizStatus {
    if (lastQuizAttempt == null) return 'Not attempted';
    if (canTakeQuiz) return 'Available';
    if (lastQuizCorrect == true) return 'Completed (1h cooldown)';
    return 'Failed (6h cooldown)';
  }

  /// Calculates EXP reward for correct quiz answer based on difficulty
  /// @return Random EXP amount (difficulty * 10-20 points)
  int calculateExpReward() {
    final baseExp = difficulty * 10; // Base: 10, 20, 30, 40, or 50
    final randomBonus = (DateTime.now().millisecond % 11); // 0-10 random bonus
    return baseExp + randomBonus;
  }

  /// Creates a copy of this card with updated quiz attempt data
  /// @param attempted - Timestamp of quiz attempt
  /// @param correct - Whether the answer was correct
  /// @return New FlashCard instance with updated quiz data
  FlashCard withQuizAttempt({
    required DateTime attempted,
    required bool correct,
  }) {
    return FlashCard(
      id: id,
      deckId: deckId,
      type: type,
      front: front,
      back: back,
      clozeMask: clozeMask,
      multipleChoiceOptions: multipleChoiceOptions,
      correctAnswerIndex: correctAnswerIndex,
      difficulty: difficulty,
      lastQuizAttempt: attempted,
      lastQuizCorrect: correct,
      imageUrl: imageUrl,
      audioUrl: audioUrl,
      diagramData: diagramData,
      visualMetadata: visualMetadata,
    );
  }

  /// Converts the FlashCard object to a JSON map for database storage or API transmission
  /// @return Map containing all card data in JSON format
  Map<String, dynamic> toJson() => {
        'id': id, // Store unique identifier
        'deckId': deckId, // Store parent deck reference
        'type': type.toString(), // Store card type as string enum
        'front': front, // Store front side content
        'back': back, // Store back side content
        'clozeMask': clozeMask, // Store cloze pattern (can be null)
        'multipleChoiceOptions': multipleChoiceOptions, // Store quiz options
        'correctAnswerIndex': correctAnswerIndex, // Store correct answer index
        'difficulty': difficulty, // Store difficulty rating
        'lastQuizAttempt':
            lastQuizAttempt?.toIso8601String(), // Store quiz attempt time
        'lastQuizCorrect': lastQuizCorrect, // Store quiz result
        'imageUrl': imageUrl, // Store visual content URL
        'audioUrl': audioUrl, // Store audio content URL
        'diagramData': diagramData, // Store diagram JSON data
        'visualMetadata': visualMetadata, // Store visual metadata
      };

  /// Factory constructor to create a FlashCard from JSON data (database or API)
  /// @param json - Map containing card data from JSON source
  /// @return FlashCard instance populated with JSON data
  factory FlashCard.fromJson(Map<String, dynamic> json) => FlashCard(
        id: json['id'] as String, // Extract string ID from JSON
        deckId: json['deckId'] as String, // Extract parent deck ID from JSON
        // Parse card type from string back to enum, default to basic if invalid
        type: CardType.values.firstWhere(
          (e) => e.toString() == json['type'], // Find matching enum value
          orElse: () => CardType.basic, // Default to basic type if not found
        ),
        front: json['front'] as String, // Extract front content from JSON
        back: json['back'] as String, // Extract back content from JSON
        clozeMask:
            json['clozeMask'] as String?, // Extract optional cloze pattern
        multipleChoiceOptions: List<String>.from(
          (json['multipleChoiceOptions'] as List?) ??
              [], // Extract quiz options
        ),
        correctAnswerIndex: json['correctAnswerIndex'] as int? ??
            0, // Extract correct answer index
        difficulty:
            json['difficulty'] as int? ?? 3, // Extract difficulty with default
        lastQuizAttempt: json['lastQuizAttempt'] != null
            ? DateTime.parse(
                json['lastQuizAttempt'] as String) // Parse quiz attempt time
            : null,
        lastQuizCorrect:
            json['lastQuizCorrect'] as bool?, // Extract quiz result
        imageUrl: json['imageUrl'] as String?, // Extract visual content URL
        audioUrl: json['audioUrl'] as String?, // Extract audio content URL
        diagramData: json['diagramData'] as String?, // Extract diagram JSON data
        visualMetadata: json['visualMetadata'] != null
            ? Map<String, String>.from(json['visualMetadata'] as Map)
            : null, // Extract visual metadata
      );
}

/// Enumeration defining the different types of flashcards supported
/// Each type has different behavior during study sessions
enum CardType {
  basic, // Traditional front/back cards (question → answer)
  cloze, // Cloze deletion cards with fill-in-the-blank sections
  reverse, // Bidirectional cards that can be studied both ways
  multipleChoice, // Multiple choice questions with 4 options
  trueFalse, // True/false questions with explanations
  comparison, // Compare and contrast questions
  scenario, // Real-world application scenarios
  causeEffect, // Cause and effect relationships
  sequence, // Ordering or process questions
  definitionExample, // Match definitions to examples
  // Advanced question formats
  caseStudy, // Multi-paragraph case studies with analysis
  problemSolving, // Multi-step problem-solving chains
  hypothesisTesting, // Evidence-based conclusion questions
  decisionAnalysis, // Best approach evaluation questions
  systemAnalysis, // Component interaction questions
  prediction, // Pattern-based prediction questions
  evaluation, // Effectiveness assessment questions
  synthesis // Concept combination questions
}
