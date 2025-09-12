// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing pet state management
import 'package:provider/provider.dart';
// Import PetProvider for managing virtual pet state and interactions
import 'package:studypals/providers/pet_provider.dart';
// Import Pet model to access pet data structures and enums
import 'package:studypals/models/pet.dart';

/// Widget displaying the virtual pet with interactive gamification features
/// Shows pet avatar, level progress, mood, study streak, and interaction buttons
/// Core component of the gamification system to motivate study engagement
class PetWidget extends StatelessWidget {
  // Constructor with optional key for widget identification
  const PetWidget({super.key});

  /// Builds the pet widget with avatar, progress, mood, and interaction controls
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the virtual pet interface
  @override
  Widget build(BuildContext context) {
    // Consumer listens to PetProvider changes and rebuilds when pet state updates
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        final pet =
            petProvider.currentPet; // Get current pet data from provider

        // Card container providing elevation and material design appearance
        return Card(
          elevation: 4, // Shadow depth for visual hierarchy
          child: Padding(
            padding: const EdgeInsets.all(16), // Internal spacing for content
            child: Column(
              children: [
                // Main pet information row with avatar and level details
                Row(
                  children: [
                    // Pet Avatar - circular container with species icon
                    Container(
                      width: 80, // Fixed avatar width
                      height: 80, // Fixed avatar height
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, // Circular avatar shape
                        // Background color with theme-aware primary color and transparency
                        color: Theme.of(context)
                            .primaryColor
                            .withValues(alpha: 0.1),
                      ),
                      child: Center(
                        // Display species-specific icon in center of avatar
                        child: _getPetIcon(pet.species),
                      ),
                    ),
                    const SizedBox(
                        width: 16), // Spacing between avatar and details
                    Expanded(
                      // Pet level and XP progress details
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start, // Align content to left
                        children: [
                          // Pet level and species name display
                          Text(
                            'Level ${pet.level} ${_getSpeciesName(pet.species)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(
                              height: 8), // Spacing before progress bar
                          // XP progress bar showing advancement toward next level
                          LinearProgressIndicator(
                            value:
                                pet.xpProgress, // Progress value (0.0 to 1.0)
                            backgroundColor: Colors.grey[300], // Track color
                            // Bar color based on pet mood for visual variety
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _getMoodColor(pet.mood),
                            ),
                          ),
                          const SizedBox(
                              height: 4), // Spacing after progress bar
                          // XP text showing current/required XP for next level
                          Text(
                            '${pet.xp} / ${pet.xpForNextLevel} XP',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12), // Spacing between sections
                // Row displaying pet mood and study streak information
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceAround, // Even spacing
                  children: [
                    _buildMoodChip(context, pet.mood), // Pet mood indicator
                    _buildStreakChip(context,
                        petProvider.currentStreak), // Study streak counter
                  ],
                ),
                const SizedBox(height: 12), // Spacing before action buttons
                // Action buttons for pet interactions
                Row(
                  children: [
                    // Feed pet button - adds XP and shows care interaction
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            petProvider.feedPet(), // Trigger feeding action
                        icon:
                            const Icon(Icons.food_bank, size: 16), // Food icon
                        label: const Text('Feed'), // Button label
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8), // Button height
                        ),
                      ),
                    ),
                    const SizedBox(width: 8), // Spacing between buttons
                    // Play with pet button - adds XP and shows play interaction
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            petProvider.playWithPet(), // Trigger play action
                        icon: const Icon(Icons.sports_esports,
                            size: 16), // Game controller icon
                        label: const Text('Play'), // Button label
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8), // Button height
                        ),
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

  /// Returns the appropriate icon for each pet species
  /// @param species - The PetSpecies enum value
  /// @return Icon widget representing the species
  Widget _getPetIcon(PetSpecies species) {
    IconData icon; // Icon data to be determined by species
    switch (species) {
      case PetSpecies.cat:
        icon = Icons.pets; // Paw icon for cats
        break;
      case PetSpecies.dog:
        icon = Icons.pets; // Paw icon for dogs
        break;
      case PetSpecies.dragon:
        icon = Icons.whatshot; // Fire icon for dragons
        break;
      case PetSpecies.owl:
        icon = Icons.nights_stay; // Moon icon for owls
        break;
      case PetSpecies.fox:
        icon = Icons.nature; // Nature icon for foxes
        break;
    }
    return Icon(icon, size: 40); // Return icon with standard size
  }

  /// Converts pet species enum to display string
  /// @param species - The PetSpecies enum value
  /// @return Formatted species name in uppercase
  String _getSpeciesName(PetSpecies species) {
    // Extract species name from enum and convert to uppercase
    return species.toString().split('.').last.toUpperCase();
  }

  /// Returns color associated with pet mood for UI theming
  /// @param mood - The PetMood enum value
  /// @return Color representing the mood state
  Color _getMoodColor(PetMood mood) {
    switch (mood) {
      case PetMood.excited:
        return Colors.green; // Bright green for excitement
      case PetMood.happy:
        return Colors.lightGreen; // Light green for happiness
      case PetMood.content:
        return Colors.orange; // Orange for content state
      case PetMood.sleepy:
        return Colors.grey; // Grey for sleepy state
    }
  }

  /// Builds a chip widget displaying the pet's current mood
  /// @param context - Build context for theme access
  /// @param mood - Current pet mood to display
  /// @return Chip widget with mood icon and text
  Widget _buildMoodChip(BuildContext context, PetMood mood) {
    return Chip(
      avatar: const Icon(Icons.emoji_emotions, size: 16), // Emoji icon for mood
      label: Text(_getMoodName(mood)), // Mood name as label
      // Background color with mood-specific color and transparency
      backgroundColor: _getMoodColor(mood).withValues(alpha: 0.2),
    );
  }

  /// Converts pet mood enum to display string
  /// @param mood - The PetMood enum value
  /// @return Formatted mood name in uppercase
  String _getMoodName(PetMood mood) {
    // Extract mood name from enum and convert to uppercase
    return mood.toString().split('.').last.toUpperCase();
  }

  /// Builds a chip widget displaying the current study streak
  /// @param context - Build context for theme access
  /// @param streak - Number of consecutive study days
  /// @return Chip widget with fire icon and streak count
  Widget _buildStreakChip(BuildContext context, int streak) {
    return Chip(
      // Fire icon representing streak "fire" concept
      avatar: const Icon(Icons.local_fire_department,
          size: 16, color: Colors.orange),
      label: Text('$streak day streak'), // Streak count with descriptive text
      // Orange background to match fire theme with transparency
      backgroundColor: Colors.orange.withValues(alpha: 0.2),
    );
  }
}
