// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Review model for spaced repetition system data
import 'package:studypals/models/review.dart';
// Import FlashCard model for card-review relationships
import 'package:studypals/models/card.dart';
// Import Firestore service for review data persistence
import 'package:studypals/services/firestore_service.dart';

/// Provider for managing spaced repetition system (SRS) and review scheduling
/// Implements SM-2 algorithm for optimal learning intervals and review timing
/// Uses ChangeNotifier to notify UI widgets when review data changes
/// Integrates with Firebase/Firestore for real-time review data persistence
class SRSProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // List of all card reviews with scheduling information (cached from Firestore)
  List<Review> _reviews = [];

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
    // Filter reviews where due date has passed (is before now or equal)
    return _reviews.where((r) => r.dueAt.isBefore(now) || r.dueAt.isAtSameMomentAs(now)).toList();
  }

  /// Getter for count of reviews currently due for study
  /// Used for displaying review counts in UI badges and notifications
  /// @return Integer count of reviews ready for study
  int get dueCount => dueReviews.length;

  /// Initialize the SRSProvider and load review data from Firestore
  /// Call this when the provider is first created
  Future<void> initialize() async {
    await loadReviews();
  }

  /// Loads all review data from Firestore
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadReviews() async {
    _isLoading = true; // Set loading state to true
    notifyListeners(); // Notify UI to show loading indicators

    try {
      _reviews = await _firestoreService.getUserReviews();
      developer.log('Loaded ${_reviews.length} reviews from Firestore', name: 'SRSProvider');
    } catch (e) {
      // Log any errors that occur during review loading for debugging
      developer.log('Error loading reviews: $e', name: 'SRSProvider');
      _reviews = []; // Reset to empty list on error
    } finally {
      _isLoading = false; // Always clear loading state
      notifyListeners(); // Notify UI that loading is complete
    }
  }

  /// Records a review session result and updates spaced repetition scheduling
  /// Uses SM-2 algorithm to calculate next review date based on performance
  /// Automatically saves changes to Firestore
  /// @param card - The FlashCard that was reviewed
  /// @param grade - User's performance grade (again, hard, good, easy)
  Future<void> recordReview(FlashCard card, ReviewGrade grade) async {
    try {
      // Update review with grade using Firestore service (handles SM-2 algorithm)
      final updatedReview = await _firestoreService.updateReviewWithGrade(card.id, grade);
      
      if (updatedReview != null) {
        // Update local cache
        final existingIndex = _reviews.indexWhere((r) => r.cardId == card.id);
        if (existingIndex != -1) {
          _reviews[existingIndex] = updatedReview;
        } else {
          _reviews.add(updatedReview);
        }

        developer.log(
          'Review recorded for card ${card.id}: Grade=$grade, Next due=${updatedReview.dueAt}',
          name: 'SRSProvider'
        );

        // Notify UI that review data has changed
        notifyListeners();
      } else {
        developer.log('Failed to record review for card ${card.id}', name: 'SRSProvider');
      }
    } catch (e) {
      developer.log('Error recording review: $e', name: 'SRSProvider');
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
  Future<void> resetReview(String cardId) async {
    try {
      final success = await _firestoreService.deleteReview(cardId);
      if (success) {
        // Remove from local cache
        _reviews.removeWhere((r) => r.cardId == cardId);
        notifyListeners(); // Notify UI of the change
        developer.log('Review reset for card: $cardId', name: 'SRSProvider');
      } else {
        developer.log('Failed to reset review for card: $cardId', name: 'SRSProvider');
      }
    } catch (e) {
      developer.log('Error resetting review: $e', name: 'SRSProvider');
    }
  }

  /// Generates statistics about review activity and card progress
  /// Used for displaying progress analytics and study insights
  /// @return Map containing various review statistics  
  Future<Map<String, int>> getReviewStats() async {
    try {
      // Calculate local stats for current state
      final today = DateTime.now();
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
    } catch (e) {
      developer.log('Error getting review stats: $e', name: 'SRSProvider');
      return {
        'total': 0,
        'due': 0,
        'reviewedToday': 0,
        'learning': 0,
        'mature': 0,
      };
    }
  }

  /// Gets a real-time stream of due reviews from Firestore
  /// Use this for widgets that need live updates of due reviews
  /// @return Stream of due Review objects
  Stream<List<Review>> getDueReviewsStream() {
    return _firestoreService.getDueReviewsStream();
  }

  /// Create a new review for a card (first time studying)
  /// @param cardId - ID of the card to create review for
  /// @return Created Review object or null if failed
  Future<Review?> createReview(String cardId) async {
    try {
      final newReview = await _firestoreService.createReview(cardId);
      if (newReview != null) {
        _reviews.add(newReview);
        notifyListeners();
        developer.log('New review created for card: $cardId', name: 'SRSProvider');
      }
      return newReview;
    } catch (e) {
      developer.log('Error creating review: $e', name: 'SRSProvider');
      return null;
    }
  }

  /// Get review for a specific card
  /// @param cardId - Card ID to get review for
  /// @return Review object or null if not found
  Future<Review?> getCardReview(String cardId) async {
    try {
      // First check local cache
      final localReview = _reviews.where((r) => r.cardId == cardId).firstOrNull;
      if (localReview != null) {
        return localReview;
      }

      // If not in cache, fetch from Firestore
      final review = await _firestoreService.getCardReview(cardId);
      if (review != null) {
        _reviews.add(review);
        notifyListeners();
      }
      return review;
    } catch (e) {
      developer.log('Error getting card review: $e', name: 'SRSProvider');
      return null;
    }
  }

  @override
  void dispose() {
    // Clean up any streams or listeners if needed
    super.dispose();
  }
}
