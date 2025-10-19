/// Data model representing a spaced repetition review session for a flashcard
/// Implements the SM-2 algorithm for optimal learning intervals
/// Tracks review history, ease factor, and next due date for each card
class Review {
  // ID of the flashcard this review applies to (foreign key relationship)
  final String cardId;

  // ID of the user who performed this review (for multi-user support)
  final String userId;

  // Next scheduled review date based on spaced repetition algorithm
  final DateTime dueAt;

  // Ease factor determining how quickly intervals increase (SM-2 algorithm)
  // Higher values = longer intervals between reviews (easier cards)
  final double ease;

  // Current review interval in days (time between current and next review)
  final int interval;

  // Number of times this card has been reviewed successfully
  final int reps;

  // Grade from the most recent review session (again, hard, good, easy)
  final ReviewGrade? lastGrade;

  // Timestamp of the most recent review session
  final DateTime? lastReviewed;

  /// Constructor for creating a Review instance
  /// @param cardId - ID of the flashcard being reviewed
  /// @param userId - ID of the user performing the review
  /// @param dueAt - Next scheduled review date
  /// @param ease - Ease factor for SM-2 algorithm (default 2.5)
  /// @param interval - Current interval in days (default 1)
  /// @param reps - Number of successful repetitions (default 0)
  /// @param lastGrade - Grade from last review (null for new cards)
  /// @param lastReviewed - Timestamp of last review (null for new cards)
  Review({
    required this.cardId, // Must link to specific card
    required this.userId, // Must link to specific user
    required this.dueAt, // Must specify when next review is due
    this.ease = 2.5, // Default ease factor from SM-2 algorithm
    this.interval = 1, // Default to 1-day interval for new cards
    this.reps = 0, // Default to 0 repetitions for new cards
    this.lastGrade, // Optional last grade (null for new cards)
    this.lastReviewed, // Optional last review time (null for new cards)
  });

  /// Updates the review data based on user's performance grade using SM-2 algorithm
  /// Calculates new ease factor, interval, and due date based on how well user remembered
  /// @param grade - User's performance rating (again, hard, good, easy)
  /// @return New Review instance with updated spaced repetition parameters
  Review updateWithGrade(ReviewGrade grade) {
    // SM-2 algorithm implementation for spaced repetition learning
    double newEase = ease; // Start with current ease factor
    int newInterval = interval; // Start with current interval
    int newReps = reps + 1; // Increment repetition count

    // Calculate new parameters based on user's performance grade
    switch (grade) {
      case ReviewGrade.again: // User forgot the card completely
        newReps = 0; // Reset repetition count (back to learning phase)
        newInterval = 1; // Reset to 1-day interval
        newEase =
            ease - 0.2; // Decrease ease factor (make future intervals shorter)
        break;

      case ReviewGrade.hard: // User struggled but remembered
        newInterval = (interval * 1.2).round(); // Slight interval increase
        newEase = ease - 0.15; // Decrease ease factor slightly
        break;

      case ReviewGrade.good: // User remembered correctly
        if (reps == 0) {
          // First time reviewing this card
          newInterval = 1; // Keep at 1 day for first review
        } else if (reps == 1) {
          // Second time reviewing
          newInterval = 6; // Jump to 6 days for second review
        } else {
          // Subsequent reviews
          newInterval =
              (interval * ease).round(); // Use ease factor for interval
        }
        break;

      case ReviewGrade.easy: // User remembered very easily
        newInterval =
            (interval * ease * 1.3).round(); // Longer interval increase
        newEase =
            ease + 0.15; // Increase ease factor (make future intervals longer)
        break;
    }

    // Clamp ease factor to reasonable bounds (SM-2 algorithm constraints)
    newEase = newEase.clamp(1.3, 2.5); // Min 1.3, Max 2.5 for optimal learning

    // Return new Review instance with updated parameters
    return Review(
      cardId: cardId, // Keep same card reference
      userId: userId, // Keep same user reference
      dueAt: DateTime.now()
          .add(Duration(days: newInterval)), // Calculate new due date
      ease: newEase, // Updated ease factor
      interval: newInterval, // Updated interval
      reps: newReps, // Updated repetition count
      lastGrade: grade, // Store this grade as last grade
      lastReviewed: DateTime.now(), // Mark current time as last reviewed
    );
  }

  /// Converts the Review object to a JSON map for database storage or API transmission
  /// @return Map containing all review data in JSON format
  Map<String, dynamic> toJson() => {
        'cardId': cardId, // Store card reference
        'userId': userId, // Store user reference
        'dueAt': dueAt.toIso8601String(), // Store due date as ISO string
        'ease': ease, // Store ease factor as number
        'interval': interval, // Store interval as integer
        'reps': reps, // Store repetition count as integer
        'lastGrade': lastGrade?.toString(), // Store grade as string (null safe)
        'lastReviewed': lastReviewed
            ?.toIso8601String(), // Store review time as ISO string (null safe)
      };

  /// Factory constructor to create a Review from JSON data (database or API)
  /// @param json - Map containing review data from JSON source
  /// @return Review instance populated with JSON data
  factory Review.fromJson(Map<String, dynamic> json) => Review(
        cardId: json['cardId'] as String, // Extract card ID from JSON
        userId: json['userId'] as String, // Extract user ID from JSON
        dueAt: DateTime.parse(
            json['dueAt'] as String), // Parse due date from ISO string
        ease: (json['ease'] as num).toDouble(), // Convert ease to double
        interval: json['interval'] as int, // Extract interval as integer
        reps: json['reps'] as int, // Extract repetitions as integer
        // Parse grade from string back to enum, handle null case
        lastGrade: json['lastGrade'] != null
            ? ReviewGrade.values.firstWhere(
                (e) =>
                    e.toString() ==
                    json['lastGrade'], // Find matching enum value
                orElse: () => ReviewGrade.good, // Default to good if invalid
              )
            : null, // Keep null if no grade stored
        // Parse review time from ISO string, handle null case
        lastReviewed: json['lastReviewed'] != null
            ? DateTime.parse(
                json['lastReviewed'] as String) // Parse ISO string to DateTime
            : null, // Keep null if no time stored
      );
}

/// Enumeration defining the possible grades for review performance
/// Used in SM-2 algorithm to adjust future review intervals
enum ReviewGrade {
  again, // Complete failure - user forgot the card (interval resets)
  hard, // Difficult recall - user struggled but remembered (slight penalty)
  good, // Normal recall - user remembered correctly (standard progression)
  easy // Easy recall - user remembered very easily (bonus progression)
}
