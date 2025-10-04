// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Pet model to manage virtual pet data and behavior
import 'package:studypals/models/pet.dart';
// Import Card model for quiz tracking
import 'package:studypals/models/card.dart';
// Import Firestore service for pet data persistence
import 'package:studypals/services/firestore_service.dart';

/// Provider for managing virtual pet state and gamification features
/// Handles pet interactions, XP progression, leveling, and study streak tracking
/// Uses ChangeNotifier to notify UI widgets when pet state changes
/// Integrates with Firebase/Firestore for real-time pet data persistence
class PetProvider extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  // Current pet instance with default values (will be loaded from Firestore)
  Pet? _currentPet;

  // Current study streak count (consecutive days of study activity)
  int _currentStreak = 0;

  // Loading state for UI feedback
  bool _isLoading = false;

  /// Getter for accessing the current pet instance (read-only)
  /// @return Current Pet object with all pet data or null if none exists
  Pet? get currentPet => _currentPet;

  /// Getter for accessing the current study streak count (read-only)
  /// @return Integer representing consecutive study days
  int get currentStreak => _currentStreak;

  /// Getter for loading state
  /// @return Boolean indicating if pet operations are in progress
  bool get isLoading => _isLoading;

  /// Initialize the PetProvider and load pet data from Firestore
  /// Call this when the provider is first created
  Future<void> initialize() async {
    await loadPet();
  }

  /// Adds experience points to the pet and handles level progression
  /// Triggers level-up celebrations and UI notifications when pet levels up
  /// Automatically saves changes to Firestore
  /// @param amount - Amount of XP to add to the pet
  /// @param source - Source of XP for logging (e.g., "quiz", "study", "feeding")
  Future<void> addXP(int amount, {String source = "general"}) async {
    if (_currentPet == null) {
      // Create default pet if none exists
      await createDefaultPet();
      if (_currentPet == null) return;
    }

    final oldLevel = _currentPet!.level; // Store current level for comparison
    final updatedPet = await _firestoreService.addPetXP(amount);

    if (updatedPet != null) {
      _currentPet = updatedPet;

      // Log XP gain event for debugging and analytics
      developer.log(
          'Pet gained $amount XP from $source (Total: ${_currentPet!.xp})',
          name: 'PetProvider');

      // Check if the pet leveled up during this XP addition
      if (_currentPet!.level > oldLevel) {
        // Log level up event for debugging and analytics
        developer.log('Pet leveled up to level ${_currentPet!.level}!',
            name: 'PetProvider');
        // Level up celebration will be implemented with animation system
        // Future: Show level up dialog with confetti animation and XP bonus
      }

      // Notify all listening widgets that pet state has changed
      notifyListeners();
    } else {
      developer.log('Failed to add XP to pet', name: 'PetProvider');
    }
  }

  /// Awards XP for correct quiz answers based on flashcard difficulty
  /// Implements the gamification system for quiz success
  /// @param card - The flashcard that was answered correctly
  /// @return Amount of XP awarded
  Future<int> awardQuizXP(FlashCard card) async {
    final expReward = card.calculateExpReward();
    await addXP(expReward, source: "quiz");

    developer.log(
        'Quiz correct! Awarded $expReward XP for difficulty ${card.difficulty}',
        name: 'PetProvider');

    return expReward;
  }

  /// Updates the current study streak and notifies listeners
  /// Called when user completes daily study goals or breaks streak
  /// @param streak - New streak count (0 if streak broken, incremented if continued)
  void updateStreak(int streak) {
    _currentStreak = streak; // Update the streak counter
    notifyListeners(); // Notify UI of streak change
  }

  /// Simulates feeding the pet, adding XP as reward for this interaction
  /// Part of gamification to encourage regular app engagement
  Future<void> feedPet() async {
    // Add modest XP reward for feeding interaction
    await addXP(10, source: "feeding"); // 10 XP for feeding the pet
  }

  /// Simulates playing with the pet, adding XP as reward for this interaction
  /// Part of gamification to encourage regular app engagement
  Future<void> playWithPet() async {
    // Add slightly higher XP reward for playing interaction
    await addXP(15, source: "playing"); // 15 XP for playing with pet
  }

  /// Changes the pet's species while preserving all other pet data
  /// Allows users to customize their virtual pet appearance
  /// @param newSpecies - The new species to change the pet to
  Future<void> changePetSpecies(PetSpecies newSpecies) async {
    if (_currentPet == null) return;

    // Create new pet instance with updated species but preserve all other data
    final updatedPet = Pet(
      userId: _currentPet!.userId, // Keep same user association
      species: newSpecies, // Update to new species
      level: _currentPet!.level, // Preserve current level
      xp: _currentPet!.xp, // Preserve current XP
      gear: _currentPet!.gear, // Preserve equipped gear
      mood: _currentPet!.mood, // Preserve current mood
      createdAt: _currentPet!.createdAt, // Preserve creation timestamp
    );

    final success = await _firestoreService.savePet(updatedPet);
    if (success) {
      _currentPet = updatedPet;
      // Notify UI that pet appearance has changed
      notifyListeners();
    }
  }

  /// Loads pet data from Firestore
  /// Called during app initialization to restore pet state
  /// If no pet exists, creates a default one automatically
  Future<void> loadPet() async {
    _isLoading = true;
    notifyListeners();

    try {
      final pet = await _firestoreService.getUserPet();
      
      if (pet != null) {
        _currentPet = pet;
        developer.log(
            'Pet loaded successfully: Level ${pet.level}, XP ${pet.xp}',
            name: 'PetProvider');
      } else {
        developer.log('No pet found for user, user can create one from UI', 
            name: 'PetProvider');
        // Don't auto-create here - let the UI handle it
        // This gives users the choice of which pet species to start with
        _currentPet = null;
      }
    } catch (e) {
      developer.log('Error loading pet: $e', name: 'PetProvider');
      _currentPet = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a default pet for new users
  /// @param species - Pet species to create (defaults to cat)
  Future<void> createDefaultPet([PetSpecies species = PetSpecies.cat]) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newPet = await _firestoreService.createPet(species);
      if (newPet != null) {
        _currentPet = newPet;
        developer.log('Default pet created: $species', name: 'PetProvider');
      } else {
        developer.log('Failed to create default pet', name: 'PetProvider');
      }
    } catch (e) {
      developer.log('Error creating default pet: $e', name: 'PetProvider');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Gets a real-time stream of pet data from Firestore
  /// Use this for widgets that need live updates
  /// @return Stream of Pet objects
  Stream<Pet?> getPetStream() {
    return _firestoreService.getPetStream();
  }

  /// Deletes the current pet (use with caution)
  /// Typically used for account reset or pet replacement
  Future<void> deletePet() async {
    final success = await _firestoreService.deletePet();
    if (success) {
      _currentPet = null;
      notifyListeners();
      developer.log('Pet deleted successfully', name: 'PetProvider');
    }
  }

  @override
  void dispose() {
    // Clean up any streams or listeners if needed
    super.dispose();
  }
}
