/// Model representing a quiz session for an entire deck
/// Replaces individual card quiz attempts with comprehensive deck-based quizzes
class QuizSession {
  final String id; // Unique session identifier
  final String deckId; // ID of the deck being quizzed
  final String deckTitle; // Title of the deck for display purposes
  final List<String> cardIds; // IDs of cards included in this quiz session
  final DateTime startTime; // When the quiz session was started
  DateTime? endTime; // When the quiz session was completed (null if ongoing)

  // Progress tracking
  int currentQuestionIndex; // Index of current question (0-based)
  final List<QuizAnswer> answers; // User's answers for each question

  // Session state
  bool isCompleted; // Whether the quiz session is finished
  double? finalScore; // Final score as percentage (0.0 to 1.0)
  int? totalExpEarned; // Total EXP earned from this session

  // Cooldown and retry logic
  DateTime? lastAttemptTime; // When this quiz was last attempted
  bool canRetake; // Whether user can retake this quiz (based on cooldown/success)

  // Multiplayer support
  final bool isMultiplayer; // Whether this is a multiplayer session
  final String? socialSessionId; // Reference to social session if multiplayer
  final List<String> participantIds; // IDs of participants in multiplayer
  final Map<String, List<QuizAnswer>> participantAnswers; // Answers by participant
  final Map<String, dynamic>? sessionData; // Additional session data (results, etc.)

  QuizSession({
    required this.id,
    required this.deckId,
    required this.deckTitle,
    required this.cardIds,
    required this.startTime,
    this.endTime,
    this.currentQuestionIndex = 0,
    List<QuizAnswer>? answers,
    this.isCompleted = false,
    this.finalScore,
    this.totalExpEarned,
    this.lastAttemptTime,
    this.canRetake = true,
    this.isMultiplayer = false,
    this.socialSessionId,
    List<String>? participantIds,
    Map<String, List<QuizAnswer>>? participantAnswers,
    this.sessionData,
  }) : answers = answers ?? [],
       participantIds = participantIds ?? [],
       participantAnswers = participantAnswers ?? {};

  /// Creates a copy of this quiz session with updated fields
  QuizSession copyWith({
    String? id,
    String? deckId,
    String? deckTitle,
    List<String>? cardIds,
    DateTime? startTime,
    DateTime? endTime,
    int? currentQuestionIndex,
    List<QuizAnswer>? answers,
    bool? isCompleted,
    double? finalScore,
    int? totalExpEarned,
    DateTime? lastAttemptTime,
    bool? canRetake,
    bool? isMultiplayer,
    String? socialSessionId,
    List<String>? participantIds,
    Map<String, List<QuizAnswer>>? participantAnswers,
    Map<String, dynamic>? sessionData,
  }) {
    return QuizSession(
      id: id ?? this.id,
      deckId: deckId ?? this.deckId,
      deckTitle: deckTitle ?? this.deckTitle,
      cardIds: cardIds ?? this.cardIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      finalScore: finalScore ?? this.finalScore,
      totalExpEarned: totalExpEarned ?? this.totalExpEarned,
      lastAttemptTime: lastAttemptTime ?? this.lastAttemptTime,
      canRetake: canRetake ?? this.canRetake,
      isMultiplayer: isMultiplayer ?? this.isMultiplayer,
      socialSessionId: socialSessionId ?? this.socialSessionId,
      participantIds: participantIds ?? this.participantIds,
      participantAnswers: participantAnswers ?? this.participantAnswers,
      sessionData: sessionData ?? this.sessionData,
    );
  }

  /// Calculate current progress as percentage (0.0 to 1.0)
  double get progress {
    if (cardIds.isEmpty) return 0.0;
    return currentQuestionIndex / cardIds.length;
  }

  /// Get number of questions answered so far
  int get questionsAnswered => answers.length;

  /// Get total number of questions in this quiz
  int get totalQuestions => cardIds.length;

  /// Check if there are more questions to answer
  bool get hasMoreQuestions => currentQuestionIndex < cardIds.length;

  /// Calculate current score based on answers so far
  double get currentScore {
    if (answers.isEmpty) return 0.0;
    final correctAnswers = answers.where((answer) => answer.isCorrect).length;
    return correctAnswers / answers.length;
  }

  /// Get number of correct answers
  int get correctAnswers => answers.where((answer) => answer.isCorrect).length;

  /// Get number of incorrect answers
  int get incorrectAnswers =>
      answers.where((answer) => !answer.isCorrect).length;

  /// Check if this is a perfect score (all answers correct)
  bool get isPerfectScore => isCompleted && finalScore == 1.0;

  /// Get quiz session status as human-readable string
  String get statusDescription {
    if (!isCompleted) {
      return 'In Progress ($questionsAnswered/$totalQuestions)';
    }

    if (finalScore == null) return 'Completed';

    final percentage = (finalScore! * 100).round();
    if (percentage >= 90) return 'Excellent ($percentage%)';
    if (percentage >= 80) return 'Great ($percentage%)';
    if (percentage >= 70) return 'Good ($percentage%)';
    if (percentage >= 60) return 'Fair ($percentage%)';
    return 'Needs Improvement ($percentage%)';
  }

  /// Get participant scores for multiplayer sessions
  Map<String, double> get participantScores {
    if (!isMultiplayer) return {};
    
    final scores = <String, double>{};
    for (final participantId in participantIds) {
      final participantAnswers = this.participantAnswers[participantId] ?? [];
      if (participantAnswers.isNotEmpty) {
        final correct = participantAnswers.where((a) => a.isCorrect).length;
        scores[participantId] = correct / participantAnswers.length;
      } else {
        scores[participantId] = 0.0;
      }
    }
    return scores;
  }

  /// Record an answer for a specific participant in multiplayer
  QuizSession recordParticipantAnswer(String participantId, QuizAnswer answer) {
    if (!isMultiplayer) return this;
    
    final updatedParticipantAnswers = Map<String, List<QuizAnswer>>.from(participantAnswers);
    final currentAnswers = updatedParticipantAnswers[participantId] ?? <QuizAnswer>[];
    updatedParticipantAnswers[participantId] = [...currentAnswers, answer];
    
    return copyWith(participantAnswers: updatedParticipantAnswers);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deckId': deckId,
      'deckTitle': deckTitle,
      'cardIds': cardIds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'answers': answers.map((answer) => answer.toJson()).toList(),
      'isCompleted': isCompleted,
      'finalScore': finalScore,
      'totalExpEarned': totalExpEarned,
      'lastAttemptTime': lastAttemptTime?.toIso8601String(),
      'canRetake': canRetake,
      'isMultiplayer': isMultiplayer,
      'socialSessionId': socialSessionId,
      'participantIds': participantIds,
      'participantAnswers': participantAnswers.map((key, value) => 
          MapEntry(key, value.map((answer) => answer.toJson()).toList())),
      'sessionData': sessionData,
    };
  }

  /// Create from JSON for loading from storage
  factory QuizSession.fromJson(Map<String, dynamic> json) {
    // Parse participant answers
    final participantAnswersJson = json['participantAnswers'] as Map<String, dynamic>? ?? {};
    final participantAnswers = <String, List<QuizAnswer>>{};
    
    for (final entry in participantAnswersJson.entries) {
      final answersList = entry.value as List<dynamic>? ?? [];
      participantAnswers[entry.key] = answersList
          .map((answerJson) => QuizAnswer.fromJson(answerJson as Map<String, dynamic>))
          .toList();
    }

    return QuizSession(
      id: json['id'],
      deckId: json['deckId'],
      deckTitle: json['deckTitle'],
      cardIds: List<String>.from(json['cardIds']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      answers: (json['answers'] as List<dynamic>?)
              ?.map((answerJson) => QuizAnswer.fromJson(answerJson))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] ?? false,
      finalScore: json['finalScore']?.toDouble(),
      totalExpEarned: json['totalExpEarned'],
      lastAttemptTime: json['lastAttemptTime'] != null
          ? DateTime.parse(json['lastAttemptTime'])
          : null,
      canRetake: json['canRetake'] ?? true,
      isMultiplayer: json['isMultiplayer'] ?? false,
      socialSessionId: json['socialSessionId'],
      participantIds: List<String>.from(json['participantIds'] ?? []),
      participantAnswers: participantAnswers,
      sessionData: json['sessionData'] as Map<String, dynamic>?,
    );
  }
}

/// Represents a user's answer to a quiz question
class QuizAnswer {
  final String cardId; // ID of the card this answer is for
  final int selectedOptionIndex; // Index of selected multiple choice option
  final int correctOptionIndex; // Index of the correct option
  final bool isCorrect; // Whether the answer was correct
  final DateTime answeredAt; // When this question was answered
  final int expEarned; // EXP earned for this answer (usually 0 for incorrect)

  QuizAnswer({
    required this.cardId,
    required this.selectedOptionIndex,
    required this.correctOptionIndex,
    required this.isCorrect,
    required this.answeredAt,
    this.expEarned = 0,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'selectedOptionIndex': selectedOptionIndex,
      'correctOptionIndex': correctOptionIndex,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt.toIso8601String(),
      'expEarned': expEarned,
    };
  }

  /// Create from JSON for loading from storage
  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      cardId: json['cardId'],
      selectedOptionIndex: json['selectedOptionIndex'],
      correctOptionIndex: json['correctOptionIndex'],
      isCorrect: json['isCorrect'],
      answeredAt: DateTime.parse(json['answeredAt']),
      expEarned: json['expEarned'] ?? 0,
    );
  }
}

/// Represents the final results of a completed quiz session
class QuizResults {
  final QuizSession session;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double scorePercentage;
  final int totalExpEarned;
  final Duration timeSpent;
  final bool isPerfectScore;

  QuizResults({
    required this.session,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.scorePercentage,
    required this.totalExpEarned,
    required this.timeSpent,
    required this.isPerfectScore,
  });

  /// Create quiz results from a completed session
  factory QuizResults.fromSession(QuizSession session) {
    if (!session.isCompleted) {
      throw ArgumentError('Cannot create results from incomplete session');
    }

    final totalQuestions = session.totalQuestions;
    final correctAnswers = session.correctAnswers;
    final incorrectAnswers = session.incorrectAnswers;
    final scorePercentage = session.finalScore ?? 0.0;
    final totalExpEarned = session.totalExpEarned ?? 0;
    final timeSpent = session.endTime != null
        ? session.endTime!.difference(session.startTime)
        : Duration.zero;
    final isPerfectScore = session.isPerfectScore;

    return QuizResults(
      session: session,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      scorePercentage: scorePercentage,
      totalExpEarned: totalExpEarned,
      timeSpent: timeSpent,
      isPerfectScore: isPerfectScore,
    );
  }

  /// Get letter grade based on score percentage
  String get letterGrade {
    final percentage = scorePercentage * 100;
    if (percentage >= 97) return 'A+';
    if (percentage >= 93) return 'A';
    if (percentage >= 90) return 'A-';
    if (percentage >= 87) return 'B+';
    if (percentage >= 83) return 'B';
    if (percentage >= 80) return 'B-';
    if (percentage >= 77) return 'C+';
    if (percentage >= 73) return 'C';
    if (percentage >= 70) return 'C-';
    if (percentage >= 67) return 'D+';
    if (percentage >= 63) return 'D';
    if (percentage >= 60) return 'D-';
    return 'F';
  }

  /// Get encouraging message based on performance
  String get encouragementMessage {
    if (isPerfectScore) {
      return '🎉 Perfect score! You\'ve mastered this deck!';
    } else if (scorePercentage >= 0.9) {
      return '🌟 Excellent work! You\'re almost there!';
    } else if (scorePercentage >= 0.8) {
      return '👏 Great job! Keep up the good work!';
    } else if (scorePercentage >= 0.7) {
      return '👍 Good effort! A bit more practice will help!';
    } else if (scorePercentage >= 0.6) {
      return '📚 You\'re making progress! Review the material and try again!';
    } else {
      return '💪 Don\'t give up! Study the cards and you\'ll improve!';
    }
  }
}
