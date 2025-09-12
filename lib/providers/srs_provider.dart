// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Review model for spaced repetition system data
import 'package:studypals/models/review.dart';
// Import FlashCard model for card-review relationships
import 'package:studypals/models/card.dart';

/// Provider for managing spaced repetition system (SRS) and review scheduling
/// Implements SM-2 algorithm for optimal learning intervals and review timing
/// Uses ChangeNotifier to notify UI widgets when review data changes
class SRSProvider extends ChangeNotifier {
  // List of all card reviews with scheduling information
  final List<Review> _reviews = [];

  // Loading state flag to show/hide loading indicators in UI
  bool _isLoading = false;

  /// Getter for accessing the list of all reviews (read-only)
  /// @return List of Review objects containing all spaced repetition data
  List<Review> get reviews => _reviews;

  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if review data is currently being loaded
  bool get isLoading => _isLoading;

  /// Getter for reviews that are currently due for study
  /// Compares review due dates with current time to determine readiness
  /// @return List of Review objects that are ready for study
  List<Review> get dueReviews {
    final now = DateTime.now(); // Get current timestamp
    // Filter reviews where due date has passed (is before now)
    return _reviews.where((r) => r.dueAt.isBefore(now)).toList();
  }

  /// Getter for count of reviews currently due for study
  /// Used for displaying review counts in UI badges and notifications
  /// @return Integer count of reviews ready for study
  int get dueCount => dueReviews.length;

  /// Loads all review data from persistent storage (database)
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadReviews() async {
    _isLoading = true; // Set loading state to true
    notifyListeners(); // Notify UI to show loading indicators

    try {
      // Database loading will be implemented when repository layer is added
      // For now, reviews list remains empty until user starts reviewing cards
      // _reviews = await ReviewRepository.getAllReviews();
    } catch (e) {
      // Log any errors that occur during review loading for debugging
      developer.log('Error loading reviews: $e', name: 'SRSProvider');
    } finally {
      _isLoading = false; // Always clear loading state
      notifyListeners(); // Notify UI that loading is complete
    }
  }

  /// Records a review session result and updates spaced repetition scheduling
  /// Uses SM-2 algorithm to calculate next review date based on performance
  /// @param card - The FlashCard that was reviewed
  /// @param grade - User's performance grade (again, hard, good, easy)
  void recordReview(FlashCard card, ReviewGrade grade) {
    // Find existing review for this card
    final existingReviewIndex = _reviews.indexWhere(
      (r) => r.cardId == card.id, // Match by card ID
    );

    Review updatedReview;

    if (existingReviewIndex != -1) {
      // If review already exists
      // Update existing review with new grade using SM-2 algorithm
      final existingReview = _reviews[existingReviewIndex];
      updatedReview =
          existingReview.updateWithGrade(grade); // Calculate new intervals
      _reviews[existingReviewIndex] =
          updatedReview; // Replace with updated review
    } else {
      // If this is a new card
      // Create new review with initial SM-2 parameters
      updatedReview = Review(
        cardId: card.id, // Link to the reviewed card
        userId:
            'user123', // Placeholder user ID (will be replaced with auth system)
        dueAt: _getInitialDueDate(grade), // Calculate first review date
        ease: 2.5, // Default ease factor from SM-2
        interval: 1, // Start with 1-day interval
        reps: 1, // First repetition
        lastGrade: grade, // Store the performance grade
        lastReviewed: DateTime.now(), // Mark current time as review time
      );
      _reviews.add(updatedReview); // Add new review to collection
    }

    // Notify UI that review data has changed
    notifyListeners();
  }

  /// Calculates initial due date for new cards based on first review performance
  /// Different grades result in different initial intervals
  /// @param grade - User's performance grade on first review
  /// @return DateTime when card should next be reviewed
  DateTime _getInitialDueDate(ReviewGrade grade) {
    switch (grade) {
      case ReviewGrade.again: // Complete failure
        return DateTime.now()
            .add(const Duration(minutes: 10)); // Review again in 10 minutes
      case ReviewGrade.hard: // Difficult recall
        return DateTime.now()
            .add(const Duration(days: 1)); // Review again tomorrow
      case ReviewGrade.good: // Normal recall
        return DateTime.now()
            .add(const Duration(days: 1)); // Review again tomorrow
      case ReviewGrade.easy: // Very easy recall
        return DateTime.now().add(const Duration(days: 3)); // Review in 3 days
    }
  }

  /// Returns flashcards that are due for review from a given card collection
  /// Cross-references due reviews with available cards
  /// @param allCards - List of all available FlashCard objects
  /// @return List of FlashCard objects that need review
  List<FlashCard> getDueCards(List<FlashCard> allCards) {
    // Get set of card IDs that are due for review
    final dueCardIds = dueReviews.map((r) => r.cardId).toSet();

    // Filter cards to only include those with due reviews
    return allCards.where((card) => dueCardIds.contains(card.id)).toList();
  }

  /// Resets review progress for a specific card (removes from SRS)
  /// Used when user wants to restart learning a card from the beginning
  /// @param cardId - ID of the card to reset
  void resetReview(String cardId) {
    // Remove all reviews for the specified card
    _reviews.removeWhere((r) => r.cardId == cardId);
    notifyListeners(); // Notify UI of the change
  }

  /// Generates statistics about review activity and card progress
  /// Used for displaying progress analytics and study insights
  /// @return Map containing various review statistics
  Map<String, int> getReviewStats() {
    final today = DateTime.now(); // Get current date

    // Filter reviews that were completed today
    final todayReviews = _reviews
        .where((r) =>
                r.lastReviewed != null && // Has been reviewed
                r.lastReviewed!.day == today.day && // Same day
                r.lastReviewed!.month == today.month && // Same month
                r.lastReviewed!.year == today.year // Same year
            )
        .toList();

    // Return comprehensive statistics about review progress
    return {
      'total': _reviews.length, // Total cards in SRS system
      'due': dueCount, // Cards due for review now
      'reviewedToday': todayReviews.length, // Cards reviewed today
      'learning': _reviews
          .where((r) => r.interval < 7)
          .length, // Cards in learning phase (< 1 week)
      'mature': _reviews
          .where((r) => r.interval >= 21)
          .length, // Mature cards (≥ 3 weeks)
    };
  }
}
