// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing multiple state providers
import 'package:provider/provider.dart';
// Import SRSProvider for accessing spaced repetition system data
import 'package:studypals/providers/srs_provider.dart';
// Import DeckProvider for accessing flashcard deck data
import 'package:studypals/providers/deck_provider.dart';

/// Widget displaying flashcard review status and due cards count
/// Shows review progress, due card count, and provides quick access to review session
/// Part of the dashboard providing immediate visibility into spaced repetition progress
class DueCardsWidget extends StatelessWidget {
  // Constructor with optional key for widget identification
  const DueCardsWidget({super.key});

  /// Builds the due cards widget with review status and start review functionality
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the flashcard review interface
  @override
  Widget build(BuildContext context) {
    // Consumer2 listens to both SRS and Deck providers for comprehensive card data
    return Consumer2<SRSProvider, DeckProvider>(
      builder: (context, srsProvider, deckProvider, child) {
        final dueCount = srsProvider.dueCount;                    // Get count of cards due for review
        final totalCards = deckProvider.getAllCards().length;     // Get total number of cards across all decks
        
        // Card container providing elevation and material design appearance
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),     // Internal spacing for content
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,  // Align content to left
              children: [
                // Header row with title and due count badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Space between title and badge
                  children: [
                    // Widget title
                    Text(
                      'Flashcard Review',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    // Due count badge (only shown when cards are due)
                    if (dueCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,                     // Red background for urgency
                          borderRadius: BorderRadius.circular(12),  // Rounded corners for pill shape
                        ),
                        child: Text(
                          '$dueCount',                           // Display due count
                          style: const TextStyle(
                            color: Colors.white,                // White text on red background
                            fontWeight: FontWeight.bold,        // Bold text for emphasis
                            fontSize: 12,                       // Small font for badge
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),         // Spacing between header and content
                
                // Conditional content based on card availability and due status
                if (dueCount == 0 && totalCards == 0)
                  // Empty state when no cards exist at all
                  Container(
                    padding: const EdgeInsets.all(24),  // Generous padding for empty state
                    child: Column(
                      children: [
                        // Deck icon indicating flashcard functionality
                        const Icon(
                          Icons.style,
                          size: 48,                      // Large icon for visual impact
                          color: Colors.grey,            // Muted color for empty state
                        ),
                        const SizedBox(height: 8),      // Spacing between icon and text
                        // Primary empty state message
                        Text(
                          'No flashcards yet',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.grey,          // Muted color for secondary text
                          ),
                        ),
                        const SizedBox(height: 8),      // Spacing between messages
                        // Secondary message encouraging deck creation
                        Text(
                          'Create a deck and add some cards',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,          // Muted color for helper text
                          ),
                        ),
                      ],
                    ),
                  )
                else if (dueCount == 0)
                  // All caught up state when cards exist but none are due
                  Container(
                    padding: const EdgeInsets.all(24),  // Generous padding for success state
                    child: Column(
                      children: [
                        // Check circle icon indicating completion
                        const Icon(
                          Icons.check_circle,
                          size: 48,                      // Large icon for visual impact
                          color: Colors.green,           // Green color for success state
                        ),
                        const SizedBox(height: 8),      // Spacing between icon and text
                        // Primary success message
                        Text(
                          'All caught up!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.green,         // Green color matching icon
                          ),
                        ),
                        const SizedBox(height: 8),      // Spacing between messages
                        // Secondary message explaining no reviews needed
                        Text(
                          'No cards due for review',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,          // Muted color for helper text
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  // Active review state when cards are due for review
                  Column(
                    children: [
                      // Due cards information row
                      Row(
                        children: [
                          // Schedule icon indicating time-based review
                          const Icon(Icons.schedule, color: Colors.orange),
                          const SizedBox(width: 8),     // Spacing between icon and text
                          // Due cards count message
                          Text(
                            '$dueCount cards due for review',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),       // Spacing before action button
                      // Start review button
                      SizedBox(
                        width: double.infinity,          // Full width button
                        child: ElevatedButton(
                          onPressed: () {
                            // Future implementation: Navigate to spaced repetition review screen
                            _startReview(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,    // Blue background for action button
                            foregroundColor: Colors.white,   // White text on blue background
                          ),
                          child: const Text('Start Review'),
                        ),
                      ),
                      const SizedBox(height: 8),        // Spacing after button
                      // Estimated time display for review session planning
                      Text(
                        'Estimated time: ${(dueCount * 2)} minutes',  // 2 minutes per card estimate
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,            // Muted color for secondary info
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Handles starting a review session
  /// Currently shows placeholder message, will navigate to review screen in future
  /// @param context - Build context for navigation and snackbar display
  void _startReview(BuildContext context) {
    // Future implementation: Navigate to spaced repetition review screen
    // Will start interactive review session with SM-2 algorithm
    // For now, show coming soon message to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Review screen coming soon!')),
    );
  }
}
