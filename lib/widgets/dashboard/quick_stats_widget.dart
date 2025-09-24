// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing multiple state providers
import 'package:provider/provider.dart';
// Import TaskProvider for accessing task completion statistics
import 'package:studypals/providers/task_provider.dart';
// Import SRSProvider for accessing review statistics and progress
import 'package:studypals/providers/srs_provider.dart';
// Import PetProvider for accessing pet level and streak information
import 'package:studypals/providers/pet_provider.dart';
// Import DeckProvider for accessing deck count statistics
import 'package:studypals/providers/deck_provider.dart';

/// Widget displaying key study statistics and progress metrics
/// Shows task completion, deck count, review progress, pet level, and study streak
/// Provides at-a-glance overview of user's study progress and engagement
/// 
/// TODO: QUICK STATS WIDGET IMPLEMENTATION IMPROVEMENTS NEEDED
/// - Current implementation shows basic statistics but missing advanced analytics
/// - Need to implement real-time statistics updates with WebSocket connections
/// - Missing time-based statistics (daily, weekly, monthly progress)
/// - Need to implement interactive statistics with drill-down capabilities
/// - Missing personalized goal tracking and progress visualization
/// - Need to implement statistics export and sharing functionality
/// - Missing comparison statistics (vs. friends, vs. previous periods)
/// - Need to implement proper loading states and error handling for statistics
/// - Missing accessibility features for statistics display
/// - Need to implement statistics caching and offline display
/// - Missing visual graphs and charts for better data representation
/// - Need to implement statistics filtering and customization options
/// - Missing integration with achievement system for milestone notifications
/// - Need to implement proper statistics animations and transitions
class QuickStatsWidget extends StatelessWidget {
  // Constructor with optional key for widget identification
  const QuickStatsWidget({super.key});

  /// Builds the quick stats widget with multiple provider data and statistics
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the statistics overview interface
  @override
  Widget build(BuildContext context) {
    // Consumer4 listens to all four relevant providers for comprehensive stats
    return Consumer4<TaskProvider, SRSProvider, PetProvider, DeckProvider>(
      builder: (context, taskProvider, srsProvider, petProvider, deckProvider,
          child) {
        // Calculate task completion statistics
        final completedTasks = taskProvider.tasks
            .where((t) => t.status.toString().contains('completed'))
            .length;
        final totalTasks = taskProvider.tasks.length;

        // Get deck count from deck provider
        final totalDecks = deckProvider.decks.length;

        // Get current pet data for level display
        final pet = petProvider.currentPet;
        
        // Get review statistics (using local stats for immediate display)
        final dueReviews = srsProvider.dueCount;

        // Card container providing elevation and material design appearance
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16), // Internal spacing for content
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start, // Align content to left
              children: [
                // Widget title
                Text(
                  'Quick Stats',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16), // Spacing between title and stats

                // First row of statistics - Tasks and Decks
                Row(
                  children: [
                    // Task completion statistics
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.task_alt, // Checkmark icon for tasks
                        label: 'Tasks', // Label identifying statistic
                        value:
                            '$completedTasks/$totalTasks', // Completed/total format
                        color: Colors.green, // Green color for task completion
                      ),
                    ),
                    const SizedBox(width: 12), // Spacing between stat items
                    // Deck count statistics
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.style, // Deck icon for flashcards
                        label: 'Decks', // Label identifying statistic
                        value: '$totalDecks', // Total deck count
                        color: Colors.blue, // Blue color for deck stats
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between stat rows

                // Second row of statistics - Reviews and Pet Level
                Row(
                  children: [
                    // Daily review statistics
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.quiz, // Quiz icon for reviews
                        label: 'Reviews Today', // Label for daily review count
                        value:
                            '$dueReviews', // Reviews due today
                        color:
                            Colors.orange, // Orange color for review progress
                      ),
                    ),
                    const SizedBox(width: 12), // Spacing between stat items
                    // Pet level statistics
                    Expanded(
                      child: _buildStatItem(
                        context,
                        icon: Icons.pets, // Pet paw icon for gamification
                        label: 'Pet Level', // Label for pet progression
                        value: '${pet?.level ?? 0}', // Current pet level
                        color: Colors.purple, // Purple color for pet stats
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Spacing before streak section

                // Study streak highlight section
                Container(
                  padding: const EdgeInsets.all(
                      12), // Internal padding for streak container
                  decoration: BoxDecoration(
                    // Theme-aware background color with transparency
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                  ),
                  child: Row(
                    children: [
                      // Fire icon representing streak concept
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.orange, // Orange fire color
                        size: 20, // Smaller icon size for inline use
                      ),
                      const SizedBox(width: 8), // Spacing between icon and text
                      // Streak count and label
                      Text(
                        'Study Streak: ${petProvider.currentStreak} days',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight:
                                  FontWeight.w500, // Medium weight for emphasis
                            ),
                      ),
                      const Spacer(), // Push encouragement text to right
                      // Encouragement text
                      Text(
                        'Keep it up!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color:
                                  Colors.grey, // Muted color for encouragement
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds an individual statistic item with icon, value, and label
  /// @param context - Build context for theme access
  /// @param icon - IconData representing the statistic type
  /// @param label - String label describing the statistic
  /// @param value - String value to display (formatted number or text)
  /// @param color - Color theme for the statistic item
  /// @return Widget representing a single statistic with styling
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon, // Icon representing the statistic
    required String label, // Descriptive label for the statistic
    required String value, // Formatted value to display
    required Color color, // Theme color for consistency
  }) {
    return Container(
      padding: const EdgeInsets.all(12), // Internal padding for stat container
      decoration: BoxDecoration(
        color:
            color.withValues(alpha: 0.1), // Background color with transparency
        borderRadius:
            BorderRadius.circular(8), // Rounded corners for modern look
      ),
      child: Column(
        children: [
          // Statistic icon
          Icon(icon, color: color, size: 24), // Icon with theme color
          const SizedBox(height: 4), // Spacing between icon and value
          // Statistic value (main number/text)
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color, // Value color matching theme
                  fontWeight: FontWeight.bold, // Bold font for emphasis
                ),
          ),
          // Statistic label (description)
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey, // Muted color for label
                ),
          ),
        ],
      ),
    );
  }
}
