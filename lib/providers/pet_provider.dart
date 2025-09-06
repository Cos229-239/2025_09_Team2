// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Pet model to manage virtual pet data and behavior
import 'package:studypals/models/pet.dart';

/// Provider for managing virtual pet state and gamification features
/// Handles pet interactions, XP progression, leveling, and study streak tracking
/// Uses ChangeNotifier to notify UI widgets when pet state changes
class PetProvider extends ChangeNotifier {
  // Current pet instance with default values (cat species, level 1)
  Pet _currentPet = Pet(
    userId: 'user123',              // Default user ID (will be replaced with real auth)
    species: PetSpecies.cat,        // Default to cat species
  );
  
  // Current study streak count (consecutive days of study activity)
  int _currentStreak = 0;

  /// Getter for accessing the current pet instance (read-only)
  /// @return Current Pet object with all pet data
  Pet get currentPet => _currentPet;
  
  /// Getter for accessing the current study streak count (read-only)
  /// @return Integer representing consecutive study days
  int get currentStreak => _currentStreak;

  /// Adds experience points to the pet and handles level progression
  /// Triggers level-up celebrations and UI notifications when pet levels up
  /// @param amount - Amount of XP to add to the pet
  void addXP(int amount) {
    final oldLevel = _currentPet.level;           // Store current level for comparison
    _currentPet = _currentPet.addXP(amount);      // Add XP and get updated pet instance
    
    // Check if the pet leveled up during this XP addition
    if (_currentPet.level > oldLevel) {
      // Log level up event for debugging and analytics
      developer.log('Pet leveled up to level ${_currentPet.level}!', name: 'PetProvider');
      // Level up celebration will be implemented with animation system
      // Future: Show level up dialog with confetti animation and XP bonus
    }
    
    // Notify all listening widgets that pet state has changed
    notifyListeners();
  }

  /// Updates the current study streak and notifies listeners
  /// Called when user completes daily study goals or breaks streak
  /// @param streak - New streak count (0 if streak broken, incremented if continued)
  void updateStreak(int streak) {
    _currentStreak = streak;                      // Update the streak counter
    notifyListeners();                            // Notify UI of streak change
  }

  /// Simulates feeding the pet, adding XP as reward for this interaction
  /// Part of gamification to encourage regular app engagement
  void feedPet() {
    // Add modest XP reward for feeding interaction
    addXP(10);                                    // 10 XP for feeding the pet
  }

  /// Simulates playing with the pet, adding XP as reward for this interaction
  /// Part of gamification to encourage regular app engagement
  void playWithPet() {
    // Add slightly higher XP reward for playing interaction
    addXP(15);                                    // 15 XP for playing with pet
  }

  /// Changes the pet's species while preserving all other pet data
  /// Allows users to customize their virtual pet appearance
  /// @param newSpecies - The new species to change the pet to
  void changePetSpecies(PetSpecies newSpecies) {
    // Create new pet instance with updated species but preserve all other data
    _currentPet = Pet(
      userId: _currentPet.userId,                 // Keep same user association
      species: newSpecies,                        // Update to new species
      level: _currentPet.level,                   // Preserve current level
      xp: _currentPet.xp,                        // Preserve current XP
      gear: _currentPet.gear,                     // Preserve equipped gear
      mood: _currentPet.mood,                     // Preserve current mood
      createdAt: _currentPet.createdAt,          // Preserve creation timestamp
    );
    
    // Notify UI that pet appearance has changed
    notifyListeners();
  }

  /// Loads pet data from persistent storage (database)
  /// Called during app initialization to restore pet state
  Future<void> loadPet() async {
    // Database repository will be implemented in future version
    // For now, pet uses default constructor values
    // _currentPet = await PetRepository.getPet(userId);
    
    // Notify listeners that pet data has been loaded (even if placeholder)
    notifyListeners();
  }

  /// Saves current pet data to persistent storage (database)
  /// Called when pet state changes to ensure data persistence
  Future<void> savePet() async {
    // Database repository will be implemented in future version
    // For now, pet state is maintained in memory only
    // await PetRepository.savePet(_currentPet);
  }
}
