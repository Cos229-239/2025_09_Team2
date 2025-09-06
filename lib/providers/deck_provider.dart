// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Deck model to manage flashcard deck collections
import 'package:studypals/models/deck.dart';
// Import FlashCard model for individual card operations within decks
import 'package:studypals/models/card.dart';

/// Provider for managing flashcard deck collections and card operations
/// Handles deck CRUD operations, card management within decks, and loading states
/// Uses ChangeNotifier to notify UI widgets when deck data changes
class DeckProvider extends ChangeNotifier {
  // List of all flashcard decks loaded from database
  List<Deck> _decks = [];
  
  // Loading state flag to show/hide loading indicators in UI
  bool _isLoading = false;

  /// Getter for accessing the list of all decks (read-only)
  /// @return List of Deck objects containing all flashcard collections
  List<Deck> get decks => _decks;
  
  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if deck data is currently being loaded
  bool get isLoading => _isLoading;

  /// Loads all flashcard decks from persistent storage (database)
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadDecks() async {
    _isLoading = true;                            // Set loading state to true
    notifyListeners();                            // Notify UI to show loading indicators
    
    try {
      // Database loading will be implemented when repository layer is added
      // For now, create sample data for development and testing purposes
      // _decks = await DeckRepository.getAllDecks();
      
      // For now, add sample data for development and testing
      _decks = [
        Deck(
          id: '1',                                // Sample deck ID
          title: 'Sample Deck',                  // Sample deck title
          tags: ['sample'],                       // Sample tags for categorization
          cards: [],                              // Empty card list initially
        ),
      ];
    } catch (e) {
      // Log any errors that occur during deck loading for debugging
      developer.log('Error loading decks: $e', name: 'DeckProvider');
    } finally {
      _isLoading = false;                         // Always clear loading state
      notifyListeners();                          // Notify UI that loading is complete
    }
  }

  /// Adds a new deck to the collection and notifies listeners
  /// @param deck - The Deck object to add to the collection
  void addDeck(Deck deck) {
    _decks.add(deck);                             // Add deck to the list
    notifyListeners();                            // Notify UI of the addition
  }

  /// Updates an existing deck in the collection by ID
  /// Finds deck by ID and replaces it with updated version
  /// @param deck - The updated Deck object with same ID
  void updateDeck(Deck deck) {
    // Find the index of the deck to update by matching ID
    final index = _decks.indexWhere((d) => d.id == deck.id);
    
    if (index != -1) {                            // If deck found
      _decks[index] = deck;                       // Replace with updated deck
      notifyListeners();                          // Notify UI of the change
    }
  }

  /// Removes a deck from the collection by ID
  /// @param deckId - The ID of the deck to remove
  void deleteDeck(String deckId) {
    // Remove all decks with matching ID (should be only one)
    _decks.removeWhere((deck) => deck.id == deckId);
    notifyListeners();                            // Notify UI of the removal
  }

  /// Adds a new flashcard to a specific deck
  /// Creates an updated deck with the new card and replaces the old one
  /// @param deckId - ID of the deck to add the card to
  /// @param card - The FlashCard object to add
  void addCardToDeck(String deckId, FlashCard card) {
    // Find the index of the target deck by ID
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    
    if (deckIndex != -1) {                        // If deck found
      final deck = _decks[deckIndex];             // Get the current deck
      // Create new card list with the added card (immutable update)
      final updatedCards = List<FlashCard>.from(deck.cards)..add(card);
      // Replace deck with updated version containing new card
      _decks[deckIndex] = deck.copyWith(cards: updatedCards);
      notifyListeners();                          // Notify UI of the change
    }
  }

  /// Removes a flashcard from a specific deck
  /// Creates an updated deck without the specified card
  /// @param deckId - ID of the deck containing the card
  /// @param cardId - ID of the card to remove
  void removeCardFromDeck(String deckId, String cardId) {
    // Find the index of the target deck by ID
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);
    
    if (deckIndex != -1) {                        // If deck found
      final deck = _decks[deckIndex];             // Get the current deck
      // Create new card list without the specified card (immutable update)
      final updatedCards = deck.cards.where((c) => c.id != cardId).toList();
      // Replace deck with updated version without the removed card
      _decks[deckIndex] = deck.copyWith(cards: updatedCards);
      notifyListeners();                          // Notify UI of the change
    }
  }

  /// Returns a flat list of all cards from all decks
  /// Useful for global operations like search or spaced repetition
  /// @return List of all FlashCard objects across all decks
  List<FlashCard> getAllCards() {
    // Expand all deck cards into a single flat list
    return _decks.expand((deck) => deck.cards).toList();
  }
}
