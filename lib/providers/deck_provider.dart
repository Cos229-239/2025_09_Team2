// Import Flutter's foundation for ChangeNotifier (state management pattern)
import 'package:flutter/foundation.dart';
// Import developer tools for logging and debugging
import 'dart:developer' as developer;
// Import Firebase Auth for user authentication
import 'package:firebase_auth/firebase_auth.dart';
// Import Deck model to manage flashcard deck collections
import 'package:studypals/models/deck.dart';
// Import FlashCard model for individual card operations within decks
import 'package:studypals/models/card.dart';
// Import Firestore service for persistence
import 'package:studypals/services/firestore_service.dart';

/// Provider for managing flashcard deck collections and card operations
/// Handles deck CRUD operations, card management within decks, and loading states
/// Uses ChangeNotifier to notify UI widgets when deck data changes
class DeckProvider extends ChangeNotifier {
  // List of all flashcard decks loaded from database
  List<Deck> _decks = [];

  // Loading state flag to show/hide loading indicators in UI
  bool _isLoading = false;

  // Firebase services for persistence
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Getter for accessing the list of all decks (read-only)
  /// @return List of Deck objects containing all flashcard collections
  List<Deck> get decks => _decks;

  /// Getter for accessing the current loading state (read-only)
  /// @return Boolean indicating if deck data is currently being loaded
  bool get isLoading => _isLoading;

  /// Loads all flashcard decks from persistent storage (database)
  /// Sets loading state and handles errors gracefully with logging
  Future<void> loadDecks() async {
    _isLoading = true; // Set loading state to true
    notifyListeners(); // Notify UI to show loading indicators

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        debugPrint('No user logged in, cannot load decks');
        _decks = [];
        return;
      }

      // Load decks from Firestore
      final deckData = await _firestoreService.getUserDecks(currentUser.uid);
      _decks = deckData.map((data) => _convertFirestoreToDeck(data)).toList();
      
      debugPrint('✅ Loaded ${_decks.length} decks from Firestore');

      // If no decks found, add sample data for development
      if (_decks.isEmpty) {
        debugPrint('No decks found, adding sample deck');
        _decks = [
        Deck(
          id: '1', // Sample deck ID
          title: 'Sample Deck', // Sample deck title
          tags: ['sample'], // Sample tags for categorization
          cards: [
            // Add some sample flashcards for testing
            FlashCard(
              id: '1',
              deckId: '1',
              type: CardType.basic,
              front: 'What is the capital of France?',
              back: 'Paris',
              multipleChoiceOptions: ['London', 'Paris', 'Berlin', 'Madrid'],
              correctAnswerIndex: 1,
              difficulty: 2,
            ),
            FlashCard(
              id: '2',
              deckId: '1',
              type: CardType.basic,
              front: 'What is 2 + 2?',
              back: '4',
              multipleChoiceOptions: ['3', '4', '5', '6'],
              correctAnswerIndex: 1,
              difficulty: 1,
            ),
            FlashCard(
              id: '3',
              deckId: '1',
              type: CardType.basic,
              front: 'What is the largest planet in our solar system?',
              back: 'Jupiter',
              multipleChoiceOptions: ['Earth', 'Saturn', 'Jupiter', 'Neptune'],
              correctAnswerIndex: 2,
              difficulty: 3,
            ),
            FlashCard(
              id: '4',
              deckId: '1',
              type: CardType.basic,
              front: 'Who wrote "Romeo and Juliet"?',
              back: 'William Shakespeare',
              multipleChoiceOptions: [
                'Charles Dickens',
                'William Shakespeare',
                'Mark Twain',
                'Jane Austen'
              ],
              correctAnswerIndex: 1,
              difficulty: 2,
            ),
            FlashCard(
              id: '5',
              deckId: '1',
              type: CardType.basic,
              front: 'What is the chemical symbol for gold?',
              back: 'Au',
              multipleChoiceOptions: ['Go', 'Gd', 'Au', 'Ag'],
              correctAnswerIndex: 2,
              difficulty: 4,
            ),
          ], // Sample cards for testing
        ),
        ];
      }
    } catch (e) {
      // Log any errors that occur during deck loading for debugging
      developer.log('Error loading decks: $e', name: 'DeckProvider');
      _decks = []; // Set empty list on error
    } finally {
      _isLoading = false; // Always clear loading state
      notifyListeners(); // Notify UI that loading is complete
    }
  }

  /// Convert Firestore document data to Deck object
  Deck _convertFirestoreToDeck(Map<String, dynamic> data) {
    final cardsData = data['cards'] as List<dynamic>? ?? [];
    final cards = cardsData.map((cardData) => _convertFirestoreToCard(cardData)).toList();
    
    return Deck(
      id: data['id'] ?? '',
      title: data['title'] ?? 'Untitled Deck',
      tags: List<String>.from(data['tags'] ?? []),
      cards: cards,
      createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert Firestore card data to FlashCard object
  FlashCard _convertFirestoreToCard(Map<String, dynamic> cardData) {
    return FlashCard(
      id: cardData['id'] ?? '',
      deckId: cardData['deckId'] ?? '',
      type: _parseCardType(cardData['type']),
      front: cardData['front'] ?? '',
      back: cardData['back'] ?? '',
      multipleChoiceOptions: List<String>.from(cardData['multipleChoiceOptions'] ?? []),
      correctAnswerIndex: cardData['correctAnswerIndex'] ?? 0,
      difficulty: cardData['difficulty'] ?? 1,
    );
  }

  /// Parse card type from string
  CardType _parseCardType(String? typeString) {
    switch (typeString) {
      case 'basic':
        return CardType.basic;
      case 'cloze':
        return CardType.cloze;
      case 'reverse':
        return CardType.reverse;
      default:
        return CardType.basic;
    }
  }

  /// Adds a new deck to the collection and notifies listeners
  /// @param deck - The Deck object to add to the collection
  Future<void> addDeck(Deck deck) async {
    _decks.add(deck); // Add deck to the list locally first
    notifyListeners(); // Notify UI of the addition immediately
    
    // Save to Firestore in the background
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      try {
        final cardsData = deck.cards.map((card) => _convertCardToFirestore(card)).toList();
        final deckId = await _firestoreService.createDeckWithCards(
          uid: currentUser.uid,
          title: deck.title,
          description: '', // Deck model doesn't have description
          cards: cardsData,
          category: deck.tags.isEmpty ? 'General' : deck.tags.first,
          tags: deck.tags,
        );
        
        if (deckId != null) {
          debugPrint('✅ Saved deck to Firestore with ID: $deckId');
          
          // Update the local deck with the Firestore ID
          final deckIndex = _decks.indexWhere((d) => d.id == deck.id);
          if (deckIndex != -1) {
            _decks[deckIndex] = deck.copyWith(id: deckId);
            notifyListeners();
          }
        } else {
          debugPrint('❌ Failed to save deck to Firestore');
        }
      } catch (e) {
        debugPrint('❌ Error saving deck to Firestore: $e');
      }
    }
  }

  /// Convert FlashCard to Firestore format
  Map<String, dynamic> _convertCardToFirestore(FlashCard card) {
    return {
      'id': card.id,
      'deckId': card.deckId,
      'type': card.type.name,
      'front': card.front,
      'back': card.back,
      'multipleChoiceOptions': card.multipleChoiceOptions,
      'correctAnswerIndex': card.correctAnswerIndex,
      'difficulty': card.difficulty,
    };
  }

  /// Updates an existing deck in the collection by ID
  /// Finds deck by ID and replaces it with updated version
  /// @param deck - The updated Deck object with same ID
  void updateDeck(Deck deck) {
    // Find the index of the deck to update by matching ID
    final index = _decks.indexWhere((d) => d.id == deck.id);

    if (index != -1) {
      // If deck found
      _decks[index] = deck; // Replace with updated deck
      notifyListeners(); // Notify UI of the change
    }
  }

  /// Removes a deck from the collection by ID
  /// @param deckId - The ID of the deck to remove
  void deleteDeck(String deckId) {
    // Remove all decks with matching ID (should be only one)
    _decks.removeWhere((deck) => deck.id == deckId);
    notifyListeners(); // Notify UI of the removal
  }

  /// Adds a new flashcard to a specific deck
  /// Creates an updated deck with the new card and replaces the old one
  /// @param deckId - ID of the deck to add the card to
  /// @param card - The FlashCard object to add
  void addCardToDeck(String deckId, FlashCard card) {
    // Find the index of the target deck by ID
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);

    if (deckIndex != -1) {
      // If deck found
      final deck = _decks[deckIndex]; // Get the current deck
      // Create new card list with the added card (immutable update)
      final updatedCards = List<FlashCard>.from(deck.cards)..add(card);
      // Replace deck with updated version containing new card
      _decks[deckIndex] = deck.copyWith(cards: updatedCards);
      notifyListeners(); // Notify UI of the change
    }
  }

  /// Removes a flashcard from a specific deck
  /// Creates an updated deck without the specified card
  /// @param deckId - ID of the deck containing the card
  /// @param cardId - ID of the card to remove
  void removeCardFromDeck(String deckId, String cardId) {
    // Find the index of the target deck by ID
    final deckIndex = _decks.indexWhere((d) => d.id == deckId);

    if (deckIndex != -1) {
      // If deck found
      final deck = _decks[deckIndex]; // Get the current deck
      // Create new card list without the specified card (immutable update)
      final updatedCards = deck.cards.where((c) => c.id != cardId).toList();
      // Replace deck with updated version without the removed card
      _decks[deckIndex] = deck.copyWith(cards: updatedCards);
      notifyListeners(); // Notify UI of the change
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
