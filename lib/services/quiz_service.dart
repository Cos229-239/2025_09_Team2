import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/quiz_session.dart';
import '../providers/pet_provider.dart';

/// Service for managing deck-based quiz sessions and scoring
class QuizService {
  static const String _quizSessionsKey = 'quiz_sessions';
  static const String _deckCooldownsKey = 'deck_cooldowns';
  static const Duration _deckCooldownPeriod =
      Duration(hours: 12); // Longer cooldown for deck quizzes

  // Cache for active quiz sessions
  final Map<String, QuizSession> _activeSessions = {};

  // Cache for deck cooldowns (deckId -> last attempt time)
  final Map<String, DateTime> _deckCooldowns = {};

  /// Initialize the service by loading cached data
  Future<void> initialize() async {
    await _loadDeckCooldowns();
  }

  /// Creates a new quiz session for a deck
  /// Only includes cards that have multiple choice options
  Future<QuizSession?> createQuizSession(Deck deck) async {
    // Check if deck can be quizzed (not on cooldown)
    if (!await canTakeDeckQuiz(deck.id)) {
      return null;
    }

    // Filter cards that have multiple choice options
    final quizCards = deck.cards
        .where((card) =>
            card.multipleChoiceOptions.isNotEmpty &&
            card.multipleChoiceOptions.length >= 2)
        .toList();

    if (quizCards.isEmpty) {
      return null; // No cards available for quiz
    }

    // Shuffle the cards for variety
    quizCards.shuffle();

    // Create new quiz session
    final sessionId = _generateSessionId();
    final session = QuizSession(
      id: sessionId,
      deckId: deck.id,
      deckTitle: deck.title,
      cardIds: quizCards.map((card) => card.id).toList(),
      startTime: DateTime.now(),
    );

    // Cache the active session
    _activeSessions[sessionId] = session;

    debugPrint(
        'Created quiz session for deck ${deck.title} with ${quizCards.length} questions');
    return session;
  }

  /// Checks if a deck can be quizzed (not on cooldown and has quiz cards)
  Future<bool> canTakeDeckQuiz(String deckId) async {
    await _loadDeckCooldowns();

    // Check if deck is on cooldown
    if (_deckCooldowns.containsKey(deckId)) {
      final lastAttempt = _deckCooldowns[deckId]!;
      final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
      return timeSinceLastAttempt >= _deckCooldownPeriod;
    }

    return true; // No previous attempt, can take quiz
  }

  /// Gets the remaining cooldown time for a deck quiz
  Future<Duration> getDeckQuizCooldown(String deckId) async {
    await _loadDeckCooldowns();

    if (!_deckCooldowns.containsKey(deckId)) {
      return Duration.zero; // No cooldown
    }

    final lastAttempt = _deckCooldowns[deckId]!;
    final timeSinceLastAttempt = DateTime.now().difference(lastAttempt);
    final cooldownRemaining = _deckCooldownPeriod - timeSinceLastAttempt;

    return cooldownRemaining.isNegative ? Duration.zero : cooldownRemaining;
  }

  /// Records an answer to a question in the current quiz session
  Future<QuizSession?> recordAnswer({
    required String sessionId,
    required String cardId,
    required int selectedOptionIndex,
    required int correctOptionIndex,
    required Deck deck,
    required PetProvider petProvider,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null || session.isCompleted) {
      return null;
    }

    // Create quiz answer
    final isCorrect = selectedOptionIndex == correctOptionIndex;
    final card = deck.cards.firstWhere((c) => c.id == cardId);
    final expEarned = isCorrect ? card.calculateExpReward() : 0;

    final answer = QuizAnswer(
      cardId: cardId,
      selectedOptionIndex: selectedOptionIndex,
      correctOptionIndex: correctOptionIndex,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      expEarned: expEarned,
    );

    // Update session with new answer
    final updatedAnswers = List<QuizAnswer>.from(session.answers)..add(answer);
    final updatedSession = session.copyWith(
      answers: updatedAnswers,
      currentQuestionIndex: session.currentQuestionIndex + 1,
    );

    // Check if quiz is completed
    if (updatedSession.currentQuestionIndex >= updatedSession.totalQuestions) {
      final completedSession =
          await _completeQuizSession(updatedSession, petProvider);
      _activeSessions[sessionId] = completedSession;
    } else {
      _activeSessions[sessionId] = updatedSession;
    }

    debugPrint(
        'Answer recorded: ${isCorrect ? "CORRECT" : "INCORRECT"} (+$expEarned EXP)');
    return _activeSessions[sessionId];
  }

  /// Completes a quiz session and calculates final results
  Future<QuizSession> _completeQuizSession(
      QuizSession session, PetProvider petProvider) async {
    final correctAnswers = session.correctAnswers;
    final totalQuestions = session.totalQuestions;
    final finalScore = correctAnswers / totalQuestions;
    final totalExpEarned = session.answers
        .map((answer) => answer.expEarned)
        .fold(0, (sum, exp) => sum + exp);

    // Create completed session
    final completedSession = session.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
      finalScore: finalScore,
      totalExpEarned: totalExpEarned,
      lastAttemptTime: DateTime.now(),
      canRetake: finalScore < 0.8, // Can retake if score is below 80%
    );

    // Award total EXP to pet
    if (totalExpEarned > 0) {
      debugPrint('Awarding $totalExpEarned EXP to pet from quiz session');
      petProvider.addXP(totalExpEarned, source: "quiz_session");
    } else {
      debugPrint('No EXP to award - totalExpEarned: $totalExpEarned');
    }

    // Set deck cooldown
    await _setDeckCooldown(session.deckId);

    // Cache completed session
    _activeSessions[session.id] = completedSession;

    // Save completed session
    await _saveQuizSession(completedSession);

    debugPrint(
        'Quiz completed: ${(finalScore * 100).round()}% score, +$totalExpEarned total EXP');
    return completedSession;
  }

  /// Gets an active quiz session by ID
  QuizSession? getSession(String sessionId) {
    return _activeSessions[sessionId];
  }

  /// Gets the current question card for a quiz session
  FlashCard? getCurrentQuestionCard(QuizSession session, Deck deck) {
    if (session.currentQuestionIndex >= session.cardIds.length) {
      return null; // Quiz completed
    }

    final cardId = session.cardIds[session.currentQuestionIndex];
    return deck.cards.firstWhere((card) => card.id == cardId);
  }

  /// Abandons an active quiz session
  void abandonSession(String sessionId) {
    _activeSessions.remove(sessionId);
    debugPrint('Quiz session $sessionId abandoned');
  }

  /// Formats cooldown time as human-readable string
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

  /// Gets a descriptive status for deck quiz availability
  Future<String> getDeckQuizStatusDescription(String deckId) async {
    if (await canTakeDeckQuiz(deckId)) {
      return "Ready to take deck quiz";
    }

    final cooldown = await getDeckQuizCooldown(deckId);
    final timeLeft = formatCooldownTime(cooldown);
    return "Quiz available in: $timeLeft";
  }

  /// Gets quiz statistics for all completed sessions
  Future<Map<String, dynamic>> getQuizStats() async {
    // This would load from persistent storage in a real app
    final completedSessions =
        _activeSessions.values.where((session) => session.isCompleted).toList();

    if (completedSessions.isEmpty) {
      return {
        'totalSessions': 0,
        'averageScore': 0.0,
        'totalExpEarned': 0,
        'perfectScores': 0,
      };
    }

    final totalSessions = completedSessions.length;
    final averageScore = completedSessions
            .map((session) => session.finalScore ?? 0.0)
            .reduce((a, b) => a + b) /
        totalSessions;
    final totalExpEarned = completedSessions
        .map((session) => session.totalExpEarned ?? 0)
        .reduce((a, b) => a + b);
    final perfectScores =
        completedSessions.where((session) => session.isPerfectScore).length;

    return {
      'totalSessions': totalSessions,
      'averageScore': averageScore,
      'totalExpEarned': totalExpEarned,
      'perfectScores': perfectScores,
    };
  }

  /// Creates a multiplayer quiz session for a social study session
  Future<QuizSession?> createMultiplayerQuizSession({
    required List<Deck> decks,
    required String socialSessionId,
    required List<String> participantIds,
    int maxQuestions = 20,
  }) async {
    // Combine cards from all selected decks
    final allQuizCards = <FlashCard>[];
    for (final deck in decks) {
      final deckCards = deck.cards
          .where((card) =>
              card.multipleChoiceOptions.isNotEmpty &&
              card.multipleChoiceOptions.length >= 2)
          .toList();
      allQuizCards.addAll(deckCards);
    }

    if (allQuizCards.isEmpty) {
      debugPrint('No quiz cards available for multiplayer session');
      return null;
    }

    // Shuffle and limit questions for multiplayer
    allQuizCards.shuffle();
    final selectedCards = allQuizCards.take(maxQuestions).toList();

    final sessionId = _generateSessionId();
    final deckTitles = decks.map((d) => d.title).join(', ');
    
    final session = QuizSession(
      id: sessionId,
      deckId: socialSessionId, // Use social session ID as reference
      deckTitle: "Multiplayer Quiz: $deckTitles",
      cardIds: selectedCards.map((card) => card.id).toList(),
      startTime: DateTime.now(),
      isMultiplayer: true,
      socialSessionId: socialSessionId,
      participantIds: participantIds,
    );

    _activeSessions[sessionId] = session;

    debugPrint(
        'Created multiplayer quiz session with ${selectedCards.length} questions for ${participantIds.length} participants');
    return session;
  }

  /// Record an answer for a specific participant in a multiplayer quiz
  Future<QuizSession?> recordMultiplayerAnswer({
    required String sessionId,
    required String participantId,
    required String cardId,
    required int selectedOptionIndex,
    required int correctOptionIndex,
    required Deck deck,
    required PetProvider petProvider,
  }) async {
    final session = _activeSessions[sessionId];
    if (session == null || !session.isMultiplayer || session.isCompleted) {
      return null;
    }

    if (!session.participantIds.contains(participantId)) {
      debugPrint('Participant $participantId not found in session');
      return null;
    }

    // Create quiz answer
    final isCorrect = selectedOptionIndex == correctOptionIndex;
    final card = deck.cards.firstWhere((c) => c.id == cardId);
    final expEarned = isCorrect ? card.calculateExpReward() : 0;

    final answer = QuizAnswer(
      cardId: cardId,
      selectedOptionIndex: selectedOptionIndex,
      correctOptionIndex: correctOptionIndex,
      isCorrect: isCorrect,
      answeredAt: DateTime.now(),
      expEarned: expEarned,
    );

    // Update session with participant answer
    final updatedSession = session.recordParticipantAnswer(participantId, answer);
    _activeSessions[sessionId] = updatedSession;

    debugPrint(
        'Multiplayer answer recorded for $participantId: ${isCorrect ? "CORRECT" : "INCORRECT"} (+$expEarned EXP)');
    return updatedSession;
  }

  /// Complete a multiplayer quiz session and calculate results for all participants
  Future<QuizSession?> completeMultiplayerQuizSession(
      String sessionId, PetProvider petProvider) async {
    final session = _activeSessions[sessionId];
    if (session == null || !session.isMultiplayer || session.isCompleted) {
      return null;
    }

    final participantScores = session.participantScores;
    final participantResults = <String, Map<String, dynamic>>{};

    int totalExpAwarded = 0;

    // Calculate results for each participant
    for (final participantId in session.participantIds) {
      final participantAnswers = session.participantAnswers[participantId] ?? [];
      final correctAnswers = participantAnswers.where((a) => a.isCorrect).length;
      final score = participantAnswers.isNotEmpty ? correctAnswers / participantAnswers.length : 0.0;
      final expEarned = participantAnswers.fold(0, (sum, answer) => sum + answer.expEarned);

      participantResults[participantId] = {
        'score': score,
        'correctAnswers': correctAnswers,
        'totalAnswers': participantAnswers.length,
        'expEarned': expEarned,
        'rank': 0, // Will be calculated after all scores are known
      };

      totalExpAwarded += expEarned;
    }

    // Calculate rankings
    final sortedParticipants = participantResults.entries.toList()
      ..sort((a, b) => b.value['score'].compareTo(a.value['score']));

    for (int i = 0; i < sortedParticipants.length; i++) {
      participantResults[sortedParticipants[i].key]!['rank'] = i + 1;
    }

    // Create completed session
    final completedSession = session.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
      sessionData: {
        'participantResults': participantResults,
        'winner': sortedParticipants.isNotEmpty ? sortedParticipants.first.key : null,
        'averageScore': participantScores.values.isNotEmpty 
            ? participantScores.values.reduce((a, b) => a + b) / participantScores.length 
            : 0.0,
      },
    );

    _activeSessions[sessionId] = completedSession;
    await _saveQuizSession(completedSession);

    debugPrint('Multiplayer quiz completed with $totalExpAwarded total EXP awarded');
    return completedSession;
  }

  /// Get multiplayer quiz results for a specific participant
  Map<String, dynamic>? getMultiplayerResults(String sessionId, String participantId) {
    final session = _activeSessions[sessionId];
    if (session == null || !session.isMultiplayer || !session.isCompleted) {
      return null;
    }

    final sessionData = session.sessionData;
    if (sessionData == null) return null;

    final participantResults = sessionData['participantResults'] as Map<String, dynamic>?;
    if (participantResults == null) return null;

    final userResults = participantResults[participantId];
    if (userResults == null) return null;

    return {
      'score': userResults['score'],
      'correctAnswers': userResults['correctAnswers'],
      'totalAnswers': userResults['totalAnswers'],
      'expEarned': userResults['expEarned'],
      'rank': userResults['rank'],
      'totalParticipants': session.participantIds.length,
      'winner': sessionData['winner'],
      'averageScore': sessionData['averageScore'],
      'isWinner': sessionData['winner'] == participantId,
    };
  }

  /// Get leaderboard for a multiplayer session
  List<Map<String, dynamic>> getMultiplayerLeaderboard(String sessionId) {
    final session = _activeSessions[sessionId];
    if (session == null || !session.isMultiplayer) {
      return [];
    }

    final leaderboard = <Map<String, dynamic>>[];
    final participantScores = session.participantScores;

    for (final participantId in session.participantIds) {
      final participantAnswers = session.participantAnswers[participantId] ?? [];
      final score = participantScores[participantId] ?? 0.0;
      final correctAnswers = participantAnswers.where((a) => a.isCorrect).length;
      final expEarned = participantAnswers.fold(0, (sum, answer) => sum + answer.expEarned);

      leaderboard.add({
        'participantId': participantId,
        'score': score,
        'correctAnswers': correctAnswers,
        'totalAnswers': participantAnswers.length,
        'expEarned': expEarned,
        'percentage': (score * 100).round(),
      });
    }

    // Sort by score descending
    leaderboard.sort((a, b) => b['score'].compareTo(a['score']));

    // Add rank
    for (int i = 0; i < leaderboard.length; i++) {
      leaderboard[i]['rank'] = i + 1;
    }

    return leaderboard;
  }

  /// Clears all quiz data (for testing or reset functionality)
  Future<void> clearAllData() async {
    _activeSessions.clear();
    _deckCooldowns.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_quizSessionsKey);
    await prefs.remove(_deckCooldownsKey);

    debugPrint('All quiz data cleared');
  }

  // Private helper methods

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'quiz_${timestamp}_$random';
  }

  Future<void> _setDeckCooldown(String deckId) async {
    _deckCooldowns[deckId] = DateTime.now();
    await _saveDeckCooldowns();
  }

  Future<void> _saveDeckCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownsJson = _deckCooldowns.map(
      (deckId, timestamp) => MapEntry(deckId, timestamp.toIso8601String()),
    );
    await prefs.setString(_deckCooldownsKey, jsonEncode(cooldownsJson));
  }

  Future<void> _loadDeckCooldowns() async {
    final prefs = await SharedPreferences.getInstance();
    final cooldownsString = prefs.getString(_deckCooldownsKey);

    if (cooldownsString != null) {
      final cooldownsJson = jsonDecode(cooldownsString) as Map<String, dynamic>;
      _deckCooldowns.clear();
      cooldownsJson.forEach((deckId, timestampString) {
        _deckCooldowns[deckId] = DateTime.parse(timestampString);
      });
    }
  }

  Future<void> _saveQuizSession(QuizSession session) async {
    // In a real app, this would save to a database
    // For now, we just keep it in memory
    debugPrint('Quiz session ${session.id} saved (in-memory only)');
  }

  // Legacy methods for backward compatibility with individual card quizzes
  // These will be removed once the UI is fully updated

  /// @deprecated Use deck-based quizzes instead
  bool canTakeQuiz(FlashCard card) {
    return card.multipleChoiceOptions.isNotEmpty;
  }

  /// @deprecated Use deck-based quizzes instead
  FlashCard recordQuizAttempt({
    required FlashCard card,
    required bool correct,
    required PetProvider petProvider,
  }) {
    // Legacy compatibility - return card as-is
    debugPrint('Legacy quiz attempt recorded for card ${card.id}');
    return card;
  }

  /// @deprecated Use deck-based quizzes instead
  FlashCard getCardWithAttempts(FlashCard card) {
    return card;
  }

  /// @deprecated Use deck-based quizzes instead
  String getQuizStatusDescription(FlashCard card) {
    if (card.multipleChoiceOptions.isEmpty) {
      return "No quiz available for this card";
    }
    return "Use deck quiz for better experience";
  }
}
