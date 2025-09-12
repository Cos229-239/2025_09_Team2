import 'package:flutter/foundation.dart';
import '../models/card.dart';
import '../models/deck.dart';
import '../providers/pet_provider.dart';

/// Service for managing quiz attempts, cooldowns, and progress tracking
class QuizService {
  // In-memory storage for quiz attempts (in real app, this would be in database)
  final Map<String, FlashCard> _cardAttempts = {};
  
  /// Records a quiz attempt for a flashcard
  /// @param card - The flashcard that was attempted
  /// @param correct - Whether the answer was correct
  /// @param petProvider - Pet provider to award XP if correct
  /// @return Updated FlashCard with attempt data
  FlashCard recordQuizAttempt({
    required FlashCard card,
    required bool correct,
    required PetProvider petProvider,
  }) {
    final updatedCard = card.withQuizAttempt(
      attempted: DateTime.now(),
      correct: correct,
    );
    
    // Store the updated card
    _cardAttempts[card.id] = updatedCard;
    
    // Award XP if answer was correct
    if (correct) {
      petProvider.awardQuizXP(updatedCard);
    }
    
    debugPrint('Quiz attempt recorded for card ${card.id}: ${correct ? "CORRECT" : "INCORRECT"}');
    
    return updatedCard;
  }
  
  /// Gets the current state of a flashcard including quiz attempt data
  /// @param card - Original flashcard
  /// @return FlashCard with latest attempt data if available
  FlashCard getCardWithAttempts(FlashCard card) {
    return _cardAttempts[card.id] ?? card;
  }
  
  /// Updates a deck with the latest quiz attempt data for all cards
  /// @param deck - Original deck
  /// @return Deck with updated card attempt data
  Deck getDeckWithAttempts(Deck deck) {
    final updatedCards = deck.cards.map((card) => getCardWithAttempts(card)).toList();
    
    return deck.copyWith(cards: updatedCards);
  }
  
  /// Checks if a quiz can be taken for a specific card
  /// @param card - The flashcard to check
  /// @return true if quiz is available, false if in cooldown
  bool canTakeQuiz(FlashCard card) {
    final cardWithAttempts = getCardWithAttempts(card);
    return cardWithAttempts.canTakeQuiz;
  }
  
  /// Gets the remaining cooldown time for a quiz
  /// @param card - The flashcard to check
  /// @return Duration until quiz becomes available
  Duration getQuizCooldown(FlashCard card) {
    final cardWithAttempts = getCardWithAttempts(card);
    return cardWithAttempts.quizCooldownRemaining;
  }
  
  /// Formats cooldown time as human-readable string
  /// @param duration - Cooldown duration
  /// @return Formatted string like "2h 30m" or "45m"
  String formatCooldownTime(Duration duration) {
    if (duration.inMinutes <= 0) return "Available now";
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return "${hours}h ${minutes}m";
    } else {
      return "${minutes}m";
    }
  }
  
  /// Clears all quiz attempt data (for testing or reset functionality)
  void clearAllAttempts() {
    _cardAttempts.clear();
    debugPrint('All quiz attempts cleared');
  }
  
  /// Gets statistics about quiz performance
  /// @return Map with quiz statistics
  Map<String, dynamic> getQuizStats() {
    if (_cardAttempts.isEmpty) {
      return {
        'totalAttempts': 0,
        'correctAttempts': 0,
        'successRate': 0.0,
        'averageDifficulty': 0.0,
      };
    }
    
    final attempts = _cardAttempts.values.toList();
    final totalAttempts = attempts.length;
    final correctAttempts = attempts.where((card) => card.lastQuizCorrect == true).length;
    final successRate = correctAttempts / totalAttempts;
    final averageDifficulty = attempts.map((card) => card.difficulty).reduce((a, b) => a + b) / totalAttempts;
    
    return {
      'totalAttempts': totalAttempts,
      'correctAttempts': correctAttempts,
      'successRate': successRate,
      'averageDifficulty': averageDifficulty,
    };
  }
}