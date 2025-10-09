import 'package:flutter/foundation.dart';
import 'dart:math';
import '../models/card.dart';
import '../models/deck.dart';
import '../models/quiz_session.dart';
import '../models/activity.dart';
import '../providers/pet_provider.dart';
import 'firestore_service.dart';
import 'activity_service.dart';

/// Service for managing deck-based quiz sessions and scoring
/// Integrates with Firestore for persistent storage and cross-device sync
class QuizService {
  final FirestoreService _firestoreService = FirestoreService();
  static const Duration _xpCooldownPeriod =
      Duration(hours: 24); // XP can only be earned once per day per deck

  // Cache for active quiz sessions
  final Map<String, QuizSession> _activeSessions = {};

  // Cache for deck XP cooldowns (deckId -> last XP earn time)
  final Map<String, DateTime> _deckXpCooldowns = {};

  /// Initialize the service by loading cached data
  Future<void> initialize() async {
    try {
      // Add timeout to prevent hanging during initialization
      await Future.wait([
        _loadDeckXpCooldowns(),
        loadQuizSessions(),
      ]).timeout(const Duration(seconds: 15));
    } catch (e) {
      debugPrint('Quiz service initialization completed with warnings: $e');
      // Continue with service available even if some data loading fails
    }
  }

  /// Creates a new quiz session for a deck
  /// Only includes cards that have multiple choice options
  /// NOTE: Quizzes can be taken at any time - XP earning has a separate cooldown
  Future<QuizSession?> createQuizSession(Deck deck) async {
    // No longer check cooldown for quiz availability - users can quiz anytime!
    
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

  /// Checks if XP can be earned from a deck (not on XP cooldown)
  /// Note: Users can take quizzes anytime, but XP is only earned once per cooldown period
  Future<bool> canEarnXPFromDeck(String deckId) async {
    try {
      // Add timeout to prevent hanging
      await _loadDeckXpCooldowns().timeout(const Duration(seconds: 10));

      // Check if deck is on XP earning cooldown
      if (_deckXpCooldowns.containsKey(deckId)) {
        final lastXpEarn = _deckXpCooldowns[deckId]!;
        final timeSinceLastXpEarn = DateTime.now().difference(lastXpEarn);
        return timeSinceLastXpEarn >= _xpCooldownPeriod;
      }

      return true; // No previous XP earned, can earn now
    } catch (e) {
      debugPrint('Error checking deck XP availability: $e');
      // If there's an error loading cooldowns, allow XP earning (fail-safe)
      return true;
    }
  }

  /// Gets the remaining XP cooldown time for a deck
  Future<Duration> getDeckXpCooldown(String deckId) async {
    await _loadDeckXpCooldowns();

    if (!_deckXpCooldowns.containsKey(deckId)) {
      return Duration.zero; // No cooldown
    }

    final lastXpEarn = _deckXpCooldowns[deckId]!;
    final timeSinceLastXpEarn = DateTime.now().difference(lastXpEarn);
    final cooldownRemaining = _xpCooldownPeriod - timeSinceLastXpEarn;

    return cooldownRemaining.isNegative ? Duration.zero : cooldownRemaining;
  }

  /// @deprecated - Quiz availability is no longer restricted by cooldown
  /// Use canEarnXPFromDeck() to check if XP can be earned
  Future<bool> canTakeDeckQuiz(String deckId) async {
    // Users can always take quizzes
    return true;
  }

  /// @deprecated - Returns XP cooldown instead of quiz cooldown
  /// Use getDeckXpCooldown() for the XP earning cooldown
  Future<Duration> getDeckQuizCooldown(String deckId) async {
    return getDeckXpCooldown(deckId);
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

    // Check if XP can be earned from this deck
    final canEarnXP = await canEarnXPFromDeck(session.deckId);
    final actualExpAwarded = canEarnXP ? totalExpEarned : 0;

    // Create completed session
    final completedSession = session.copyWith(
      isCompleted: true,
      endTime: DateTime.now(),
      finalScore: finalScore,
      totalExpEarned: actualExpAwarded, // Only award XP if not on cooldown
      lastAttemptTime: DateTime.now(),
      canRetake: finalScore < 0.8, // Can retake if score is below 80%
    );

    // Award total EXP to pet only if not on XP cooldown
    if (canEarnXP && totalExpEarned > 0) {
      debugPrint('Awarding $totalExpEarned EXP to pet from quiz session');
      petProvider.addXP(totalExpEarned, source: "quiz_session");
      
      // Set XP cooldown for this deck
      await _setDeckXpCooldown(session.deckId);
    } else if (!canEarnXP) {
      debugPrint('Deck is on XP cooldown - no XP awarded (can still take quiz for practice)');
    } else {
      debugPrint('No EXP to award - totalExpEarned: $totalExpEarned');
    }

    // Cache completed session
    _activeSessions[session.id] = completedSession;

    // Save completed session
    await _saveQuizSession(completedSession);

    // Log activity
    try {
      final activityService = ActivityService();
      await activityService.logActivity(
        type: ActivityType.quizCompleted,
        description: canEarnXP 
            ? 'Completed quiz with ${(finalScore * 100).round()}% score'
            : 'Completed quiz for practice (XP already earned today)',
        metadata: {
          'quizId': session.id,
          'score': finalScore,
          'expEarned': actualExpAwarded,
          'expOnCooldown': !canEarnXP,
          'cardsStudied': session.cardIds.length,
        },
      );
    } catch (e) {
      debugPrint('Failed to log quiz completion activity: $e');
    }

    final xpMessage = canEarnXP 
        ? '+$totalExpEarned total EXP' 
        : 'No XP (daily limit reached)';
    debugPrint(
        'Quiz completed: ${(finalScore * 100).round()}% score, $xpMessage');
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

  /// Gets a descriptive status for deck quiz XP earning availability
  Future<String> getDeckQuizStatusDescription(String deckId) async {
    if (await canEarnXPFromDeck(deckId)) {
      return "Quiz available - XP can be earned";
    }

    final cooldown = await getDeckXpCooldown(deckId);
    final timeLeft = formatCooldownTime(cooldown);
    return "XP available in: $timeLeft (Can still quiz for practice)";
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
    final updatedSession =
        session.recordParticipantAnswer(participantId, answer);
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
      final participantAnswers =
          session.participantAnswers[participantId] ?? [];
      final correctAnswers =
          participantAnswers.where((a) => a.isCorrect).length;
      final score = participantAnswers.isNotEmpty
          ? correctAnswers / participantAnswers.length
          : 0.0;
      final expEarned =
          participantAnswers.fold(0, (sum, answer) => sum + answer.expEarned);

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
        'winner':
            sortedParticipants.isNotEmpty ? sortedParticipants.first.key : null,
        'averageScore': participantScores.values.isNotEmpty
            ? participantScores.values.reduce((a, b) => a + b) /
                participantScores.length
            : 0.0,
      },
    );

    _activeSessions[sessionId] = completedSession;
    await _saveQuizSession(completedSession);

    debugPrint(
        'Multiplayer quiz completed with $totalExpAwarded total EXP awarded');
    return completedSession;
  }

  /// Get multiplayer quiz results for a specific participant
  Map<String, dynamic>? getMultiplayerResults(
      String sessionId, String participantId) {
    final session = _activeSessions[sessionId];
    if (session == null || !session.isMultiplayer || !session.isCompleted) {
      return null;
    }

    final sessionData = session.sessionData;
    if (sessionData == null) return null;

    final participantResults =
        sessionData['participantResults'] as Map<String, dynamic>?;
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
      final participantAnswers =
          session.participantAnswers[participantId] ?? [];
      final score = participantScores[participantId] ?? 0.0;
      final correctAnswers =
          participantAnswers.where((a) => a.isCorrect).length;
      final expEarned =
          participantAnswers.fold(0, (sum, answer) => sum + answer.expEarned);

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
    _deckXpCooldowns.clear();

    await _firestoreService.clearAllQuizData();

    debugPrint('All quiz data cleared');
  }

  // Private helper methods

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'quiz_${timestamp}_$random';
  }

  Future<void> _setDeckXpCooldown(String deckId) async {
    final cooldownEnd = DateTime.now().add(_xpCooldownPeriod);
    _deckXpCooldowns[deckId] = DateTime.now();
    await _firestoreService.saveDeckCooldown(deckId, cooldownEnd);
  }

  Future<void> _loadDeckXpCooldowns() async {
    try {
      // Add timeout to prevent hanging on Firestore calls
      final cooldowns = await _firestoreService
          .getAllDeckCooldowns()
          .timeout(const Duration(seconds: 8));
      _deckXpCooldowns.clear();
      cooldowns.forEach((deckId, cooldownEnd) {
        // Store the start time (now - cooldown period) for compatibility
        final startTime = cooldownEnd.subtract(_xpCooldownPeriod);
        _deckXpCooldowns[deckId] = startTime;
      });
    } catch (e) {
      debugPrint('Error loading deck XP cooldowns: $e');
      // Continue with empty cooldowns if loading fails
    }
  }

  Future<void> _saveQuizSession(QuizSession session) async {
    try {
      await _firestoreService.saveQuizSession(session);
      debugPrint('Quiz session ${session.id} saved to Firestore');
    } catch (e) {
      debugPrint('Error saving quiz session: $e');
    }
  }

  /// Load quiz sessions from Firestore for initialization
  Future<void> loadQuizSessions() async {
    try {
      final sessions = await _firestoreService.getQuizSessions();
      _activeSessions.clear();
      for (final session in sessions) {
        if (!session.isCompleted) {
          _activeSessions[session.id] = session;
        }
      }
      debugPrint(
          'Loaded ${_activeSessions.length} active quiz sessions from Firestore');
    } catch (e) {
      debugPrint('Error loading quiz sessions: $e');
    }
  }

  /// Get quiz sessions for a specific deck from Firestore
  Future<List<QuizSession>> getQuizSessionsForDeck(String deckId) async {
    try {
      return await _firestoreService.getQuizSessionsForDeck(deckId);
    } catch (e) {
      debugPrint('Error getting quiz sessions for deck: $e');
      return [];
    }
  }

  /// Get all quiz sessions (completed and active) from Firestore
  Future<List<QuizSession>> getAllQuizSessions() async {
    try {
      return await _firestoreService.getQuizSessions();
    } catch (e) {
      debugPrint('Error getting all quiz sessions: $e');
      return [];
    }
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
