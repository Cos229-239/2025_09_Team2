import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/quiz_session.dart';
import '../models/study_pal_persona.dart';
import '../providers/pet_provider.dart';
import '../providers/daily_quest_provider.dart';
import '../services/quiz_service.dart';
import '../services/predictive_scheduling_service.dart' as scheduling;
import '../widgets/schedule/schedule_prediction_widget.dart';
import 'deck_completion_screen.dart';

/// Flashcard study interface for reviewing cards in a deck
class FlashcardStudyScreen extends StatefulWidget {
  final Deck deck;
  final bool startInQuizMode;

  const FlashcardStudyScreen({
    super.key,
    required this.deck,
    this.startInQuizMode = false,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  // Individual quiz mode removed - only deck-based quizzes are supported
  final QuizService _quizService = QuizService();
  final scheduling.PredictiveSchedulingService _schedulingService = scheduling.PredictiveSchedulingService();
  bool _hasCompletedDeck = false; // Track if user has gone through all cards

  // Track which cards have been studied in this session (by card ID)
  final Set<String> _studiedCardIds = {};
  
  // Track which cards have been studied specifically in study mode (not quiz mode)
  final Set<String> _studyModeCardIds = {};

  // Deck-based quiz session state
  bool _isDeckQuizMode = false;
  QuizSession? _currentQuizSession;
  String? _quizSessionId;

  FlashCard get _currentCard {
    // In deck quiz mode, get the current question card from the quiz session
    if (_isDeckQuizMode && _currentQuizSession != null) {
      final currentQuizCard = _getCurrentQuizCard();
      if (currentQuizCard != null) {
        return currentQuizCard;
      }
    }
    
    // Normal study mode - use the current card index
    final card = widget.deck.cards[_currentCardIndex];
    return _quizService.getCardWithAttempts(card);
  }

  @override
  void initState() {
    super.initState();
    _loadCardState();
    
    // If starting in quiz mode, start a deck quiz
    if (widget.startInQuizMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startDeckQuiz();
      });
    }
  }

  @override
  void dispose() {
    // Mark current card as studied when leaving the screen
    _markCardAsStudied(_currentCard);
    super.dispose();
  }

  void _loadCardState() {
    // Individual quiz mode removed - only deck-based quizzes are supported
    // Card state loading simplified for study mode only
    final card = _currentCard;
    _quizService.getCardWithAttempts(card);
    
    // Mark the card as studied after a short delay (gives user time to read it)
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _markCardAsStudied(card);
      }
    });
  }

  void _nextCard() {
    // Mark current card as studied before moving to next
    _markCardAsStudied(_currentCard);
    
    setState(() {
      if (_currentCardIndex < widget.deck.cards.length - 1) {
        _currentCardIndex++;
        _showAnswer = false;
        // Individual quiz mode removed
        _loadCardState(); // Load state for the new card
      } else {
        // Mark deck as completed
        _hasCompletedDeck = true;
        // Show completion dialog
        _showCompletionDialog();
      }
    });
  }

  void _previousCard() {
    // Mark current card as studied before moving to previous
    _markCardAsStudied(_currentCard);
    
    setState(() {
      if (_currentCardIndex > 0) {
        _currentCardIndex--;
        _showAnswer = false;
        // Individual quiz mode removed
        _loadCardState(); // Load state for the previous card
      }
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
      // Individual quiz mode removed
    });
    
    // If showing answer for the first time, count as studying a card
    if (_showAnswer) {
      _markCardAsStudied(_currentCard);
    }
  }

  /// Starts a deck-based quiz session with all quiz cards
  Future<void> _startDeckQuiz() async {
    // Initialize quiz service
    await _quizService.initialize();
    
    // Create quiz session
    final session = await _quizService.createQuizSession(widget.deck);
    
    if (session == null) {
      // Show error message
      final statusMessage = await _quizService.getDeckQuizStatusDescription(widget.deck.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMessage),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Start quiz session
    setState(() {
      _isDeckQuizMode = true;
      _currentQuizSession = session;
      _quizSessionId = session.id;
      _currentCardIndex = 0;
    });

    debugPrint('Started deck quiz with ${session.totalQuestions} questions');
  }

  /// Handles answering a question in deck quiz mode
  Future<void> _answerDeckQuizQuestion(int selectedIndex) async {
    if (_currentQuizSession == null || _quizSessionId == null) return;
    
    final currentCard = _getCurrentQuizCard();
    if (currentCard == null) return;

    // Handle skipped questions (selectedIndex = -1)
    final isSkipped = selectedIndex == -1;
    final actualSelectedIndex = isSkipped ? -1 : selectedIndex;
    final correctIndex = currentCard.correctAnswerIndex;

    final petProvider = Provider.of<PetProvider>(context, listen: false);

    // Record answer in quiz session
    final updatedSession = await _quizService.recordAnswer(
      sessionId: _quizSessionId!,
      cardId: currentCard.id,
      selectedOptionIndex: actualSelectedIndex,
      correctOptionIndex: correctIndex,
      deck: widget.deck,
      petProvider: petProvider,
    );

    if (updatedSession == null) return;

    final isCorrect = !isSkipped && selectedIndex == correctIndex;
    final expEarned = isCorrect ? currentCard.calculateExpReward() : 0;

    setState(() {
      _currentQuizSession = updatedSession;
    });

    // Note: Quest progress is updated when the entire quiz session completes,
    // not for each individual question
    
    // Show immediate feedback
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          String message;
          Color backgroundColor;
          
          if (isSkipped) {
            message = 'Question skipped. Correct answer: ${currentCard.multipleChoiceOptions[correctIndex]}';
            backgroundColor = Colors.orange;
          } else if (isCorrect) {
            message = 'Correct! +$expEarned EXP';
            backgroundColor = Colors.green;
          } else {
            message = 'Incorrect. The correct answer was ${currentCard.multipleChoiceOptions[correctIndex]}';
            backgroundColor = Colors.red;
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      });
    }

    // Auto-advance to next question after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && updatedSession.hasMoreQuestions) {
        _nextDeckQuizQuestion();
      } else if (mounted && updatedSession.isCompleted) {
        _showDeckQuizResults(updatedSession);
      }
    });
  }

  /// Moves to the next question in deck quiz mode
  void _nextDeckQuizQuestion() {
    if (_currentQuizSession == null) return;

    if (_currentQuizSession!.hasMoreQuestions) {
      setState(() {
        _currentCardIndex++;
      });
    }
  }

  /// Gets the current card for deck quiz mode
  FlashCard? _getCurrentQuizCard() {
    if (_currentQuizSession == null) return null;
    return _quizService.getCurrentQuestionCard(_currentQuizSession!, widget.deck);
  }

  /// Shows the final results of the deck quiz
  void _showDeckQuizResults(QuizSession session) {
    final results = QuizResults.fromSession(session);
    
    // Update daily quest progress for completing a quiz (1 quiz = 1 deck completion)
    final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);
    questProvider.onQuizTaken(); // One quiz completed (deck-based)
    
    // Check if perfect score achieved
    if (results.isPerfectScore) {
      questProvider.onPerfectScore(); // Perfect score quest
    }
    
    // Note: EXP is already awarded in QuizService._completeQuizSession()
    // No need to award it again here to avoid duplicate EXP
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              results.isPerfectScore ? Icons.star : Icons.quiz,
              color: results.isPerfectScore ? Colors.amber : Colors.blue,
            ),
            const SizedBox(width: 8),
            const Text('Quiz Complete!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              results.encouragementMessage,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            
            // Score breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Score:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${(results.scorePercentage * 100).round()}% (${results.letterGrade})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: results.scorePercentage >= 0.8 ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Correct: ${results.correctAnswers}/${results.totalQuestions}'),
                  Text('Time: ${results.timeSpent.inMinutes}m ${results.timeSpent.inSeconds % 60}s'),
                  Text('EXP Earned: +${results.totalExpEarned}'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to deck list
            },
            child: const Text('Done'),
          ),
          if (results.scorePercentage < 0.8) // Allow retry if score is below 80%
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _exitDeckQuizMode();
              },
              child: const Text('Study More'),
            ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _restartDeckQuiz();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _triggerSchedulePrediction();
            },
            child: const Text('Schedule Next'),
          ),
        ],
      ),
    );
  }

  /// Exits deck quiz mode and returns to normal study mode
  void _exitDeckQuizMode() {
    setState(() {
      _isDeckQuizMode = false;
      _currentQuizSession = null;
      _quizSessionId = null;
      _currentCardIndex = 0;
    });
  }

  /// Shows next study session prediction after completion
  void _triggerSchedulePrediction() async {
    try {
      // Get subject from deck tags or title
      final subject = widget.deck.tags.isNotEmpty 
          ? widget.deck.tags.first 
          : widget.deck.title.split(' ').first;

      // Record the current study session
      final now = DateTime.now();
      final sessionMetrics = scheduling.StudySessionMetrics(
        timestamp: now,
        sessionLength: const Duration(minutes: 30), // Estimated session duration
        totalQuestions: widget.deck.cards.length,
        correctAnswers: _getEstimatedCorrectAnswers(),
        averageResponseTime: 5.0, // Estimated 5 seconds per question
        dominantEmotion: EmotionalState.confident,
        timeOfDay: _getSchedulingTimeOfDay(now.hour),
        dayOfWeek: _getDayOfWeek(now.weekday),
        difficulty: scheduling.StudyDifficulty.medium,
        subject: subject,
        focusScore: _hasCompletedDeck ? 0.8 : 0.6,
        retentionScore: _getEstimatedRetentionScore(),
        completedSession: _hasCompletedDeck,
      );

      _schedulingService.recordStudySession(sessionMetrics);

      // Get prediction for next session
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final prediction = _schedulingService.predictOptimalSchedule(
        targetDate: tomorrow,
        availableSubjects: [subject],
        subjectPriorities: {subject: 1},
      );

      if (mounted) {
        _showPredictionDialog(prediction);
      }
    } catch (e) {
      print('Error showing schedule prediction: $e');
    }
  }

  /// Gets estimated correct answers based on session type
  int _getEstimatedCorrectAnswers() {
    if (_isDeckQuizMode && _currentQuizSession != null) {
      final session = _currentQuizSession!;
      return session.answers.where((answer) => answer.isCorrect).length;
    }
    return (widget.deck.cards.length * (_hasCompletedDeck ? 0.7 : 0.5)).round();
  }

  /// Gets estimated retention score
  double _getEstimatedRetentionScore() {
    if (_isDeckQuizMode && _currentQuizSession != null && _currentQuizSession!.finalScore != null) {
      return _currentQuizSession!.finalScore!;
    }
    return _hasCompletedDeck ? 0.75 : 0.6;
  }

  /// Maps hour to TimeOfDay enum from scheduling service
  scheduling.TimeOfDay _getSchedulingTimeOfDay(int hour) {
    if (hour >= 5 && hour < 8) return scheduling.TimeOfDay.earlyMorning;
    if (hour >= 8 && hour < 11) return scheduling.TimeOfDay.morning;
    if (hour >= 11 && hour < 14) return scheduling.TimeOfDay.midday;
    if (hour >= 14 && hour < 17) return scheduling.TimeOfDay.afternoon;
    if (hour >= 17 && hour < 20) return scheduling.TimeOfDay.evening;
    if (hour >= 20 && hour < 23) return scheduling.TimeOfDay.night;
    return scheduling.TimeOfDay.lateNight;
  }

  /// Maps weekday int to DayOfWeek enum
  scheduling.DayOfWeek _getDayOfWeek(int weekday) {
    switch (weekday) {
      case 1: return scheduling.DayOfWeek.monday;
      case 2: return scheduling.DayOfWeek.tuesday;
      case 3: return scheduling.DayOfWeek.wednesday;
      case 4: return scheduling.DayOfWeek.thursday;
      case 5: return scheduling.DayOfWeek.friday;
      case 6: return scheduling.DayOfWeek.saturday;
      case 7: return scheduling.DayOfWeek.sunday;
      default: return scheduling.DayOfWeek.monday;
    }
  }

  /// Shows the prediction dialog
  void _showPredictionDialog(scheduling.StudySchedulePrediction prediction) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text('Next Study Session'),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: SchedulePredictionWidget(
                    prediction: prediction,
                    onSchedule: () {
                      Navigator.of(context).pop();
                      _scheduleStudySession(prediction);
                    },
                    onCustomize: () {
                      Navigator.of(context).pop();
                      _showCustomizeSchedule(prediction);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Schedules a study session based on prediction
  void _scheduleStudySession(scheduling.StudySchedulePrediction prediction) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Study session scheduled for ${_formatDateTime(prediction.recommendedTime)}',
        ),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            // Would navigate to calendar/schedule view
          },
        ),
      ),
    );
  }

  /// Shows schedule customization options
  void _showCustomizeSchedule(scheduling.StudySchedulePrediction prediction) {
    // Would show a more detailed scheduling interface
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Schedule customization coming soon!'),
      ),
    );
  }

  /// Formats DateTime for display
  String _formatDateTime(DateTime dateTime) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    
    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    final hour = dateTime.hour == 0 ? 12 : dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    
    return '$dayName, $monthName ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  /// Restarts the deck quiz
  void _restartDeckQuiz() {
    _exitDeckQuizMode();
    _startDeckQuiz();
  }

  // Individual quiz mode removed - _selectAnswer method deleted

  Widget _buildCardInterface() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Question/Answer label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _showAnswer
                ? Colors.green.shade100
                : Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _showAnswer ? 'ANSWER' : 'QUESTION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _showAnswer
                  ? Colors.green.shade700
                  : Colors.blue.shade700,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Card content
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Text(
                _showAnswer
                    ? _currentCard.back
                    : _currentCard.front,
                style: const TextStyle(
                  fontSize: 20,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuizInterface() {
    // Only deck quiz mode is supported now
    if (_isDeckQuizMode && _currentQuizSession != null) {
      return _buildDeckQuizInterface();
    }
    
    // For non-deck mode, just show the regular card interface
    return _buildCardInterface();
  }

  /// Builds the interface for deck-based quiz sessions
  Widget _buildDeckQuizInterface() {
    if (_currentQuizSession == null) {
      return const Center(child: Text('Error: No quiz session'));
    }

    final currentCard = _getCurrentQuizCard();
    if (currentCard == null) {
      return const Center(child: Text('Quiz completed!'));
    }

    // Check if current question has been answered
    final currentAnswerIndex = _currentQuizSession!.currentQuestionIndex;
    final hasAnswered = _currentQuizSession!.answers.length > currentAnswerIndex;
    final currentAnswer = hasAnswered ? _currentQuizSession!.answers[currentAnswerIndex] : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quiz session header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'DECK QUIZ - Question ${math.min(_currentQuizSession!.currentQuestionIndex + 1, _currentQuizSession!.totalQuestions)}/${_currentQuizSession!.totalQuestions}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quiz session progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: _currentQuizSession!.progress,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
          ),
        ),

        const SizedBox(height: 16),

        // Current score display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Score: '),
            Text(
              '${_currentQuizSession!.correctAnswers}/${_currentQuizSession!.questionsAnswered}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (_currentQuizSession!.questionsAnswered > 0) ...[
              Text(
                ' (${(_currentQuizSession!.currentScore * 100).round()}%)',
                style: TextStyle(
                  color: _currentQuizSession!.currentScore >= 0.8 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 24),

        // Question
        Text(
          currentCard.front,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 32),

        // Multiple choice options
        Expanded(
          child: ListView.builder(
            itemCount: currentCard.multipleChoiceOptions.length,
            itemBuilder: (context, index) {
              final option = currentCard.multipleChoiceOptions[index];
              final isSelected = hasAnswered && currentAnswer!.selectedOptionIndex == index;
              final isCorrect = index == currentCard.correctAnswerIndex;
              final showResult = hasAnswered;
              
              Color? buttonColor;
              if (showResult) {
                if (isSelected && isCorrect) {
                  buttonColor = Colors.green;
                } else if (isSelected && !isCorrect) {
                  buttonColor = Colors.red;
                } else if (isCorrect) {
                  buttonColor = Colors.green;
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: !hasAnswered ? () => _answerDeckQuizQuestion(index) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonColor != null ? Colors.white : null,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '${String.fromCharCode(65 + index)}. $option',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.left,
                  ),
                ),
              );
            },
          ),
        ),

        // Next question button for deck quiz
        if (hasAnswered && _currentQuizSession!.hasMoreQuestions) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _nextDeckQuizQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Next Question'),
          ),
        ],

        // Result feedback
        if (hasAnswered) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: currentAnswer!.isCorrect ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  currentAnswer.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: currentAnswer.isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  currentAnswer.isCorrect 
                      ? 'Correct! +${currentAnswer.expEarned} EXP'
                      : 'Incorrect',
                  style: TextStyle(
                    color: currentAnswer.isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Mark a card as studied and update quest progress if it's the first time
  void _markCardAsStudied(FlashCard card) {
    // Track overall card viewing (for internal tracking)
    _studiedCardIds.add(card.id);
    
    // Only count towards "study flashcards" quest when NOT in quiz mode
    // Quiz mode has its own separate quest tracking
    if (!_isDeckQuizMode) {
      // Only count each card once for study mode quest progress
      if (!_studyModeCardIds.contains(card.id)) {
        _studyModeCardIds.add(card.id);
        
        // Update daily quest progress for studying a card
        final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);
        questProvider.onCardStudied();
        
        debugPrint('Card studied in study mode: ${card.id} (Study quest progress: ${_studyModeCardIds.length})');
      }
    } else {
      debugPrint('Card viewed in quiz mode: ${card.id} (not counted toward study quest)');
    }
  }

  void _showCompletionDialog() {
    // Navigate to the dedicated completion screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DeckCompletionScreen(deck: widget.deck),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Check if deck has cards
    if (widget.deck.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.deck.title)),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text('This deck has no cards to study.'),
              Text('Please generate some flashcards first.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deck.title),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '${_currentCardIndex + 1} / ${widget.deck.cards.length}',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentCardIndex + 1) / widget.deck.cards.length,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),

            const SizedBox(height: 24),

            // Card display area
            Expanded(
              child: Center(
                child: Card(
                  elevation: 8,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: _isDeckQuizMode ? _buildQuizInterface() : _buildCardInterface(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Control buttons
            if (_isDeckQuizMode) ...[
              // Deck quiz mode controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Exit quiz button
                  ElevatedButton.icon(
                    onPressed: _exitDeckQuizMode,
                    icon: const Icon(Icons.exit_to_app),
                    label: const Text('Exit Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Quiz progress info
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Question ${math.min((_currentQuizSession?.currentQuestionIndex ?? 0) + 1, _currentQuizSession?.totalQuestions ?? 0)}/${_currentQuizSession?.totalQuestions ?? 0}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Skip question (for now, just mark as incorrect)
                  ElevatedButton.icon(
                    onPressed: (_isDeckQuizMode && _currentQuizSession != null && 
                               _currentQuizSession!.answers.length <= _currentQuizSession!.currentQuestionIndex)
                        ? () => _answerDeckQuizQuestion(-1) // -1 indicates skip
                        : null,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Normal study mode controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Previous button
                  ElevatedButton.icon(
                    onPressed: _currentCardIndex > 0 ? _previousCard : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Show answer button (only in study mode, not quiz mode)
                  if (!_isDeckQuizMode)
                    ElevatedButton.icon(
                      onPressed: _toggleAnswer,
                      icon: Icon(
                          _showAnswer ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),

                  // Next button
                  ElevatedButton.icon(
                    onPressed: _nextCard,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(_currentCardIndex < widget.deck.cards.length - 1
                        ? 'Next'
                        : 'Finish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Deck quiz starter button - only show after completing deck study
              if (!_isDeckQuizMode && _hasCompletedDeck && widget.deck.cards.where((card) => 
                  card.multipleChoiceOptions.isNotEmpty).length >= 2) ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _startDeckQuiz,
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Start Deck Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Quiz all ${widget.deck.cards.where((card) => card.multipleChoiceOptions.isNotEmpty).length} cards at once!',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],

            const SizedBox(height: 16),

            // Additional controls row for quiz cards
            if (_currentCard.multipleChoiceOptions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Show answer button for quiz cards
                  if (!_isDeckQuizMode)
                    TextButton.icon(
                      onPressed: _toggleAnswer,
                      icon: Icon(_showAnswer ? Icons.visibility_off : Icons.visibility),
                      label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                    ),
                  
                  const SizedBox(width: 16),
                  
                  // Quiz cooldown/status info
                  if (!_quizService.canTakeQuiz(_currentCard))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentCard.lastQuizCorrect == true 
                            ? Colors.green.shade100 
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentCard.lastQuizCorrect == true 
                                ? Icons.check_circle_outline 
                                : Icons.schedule,
                            size: 16,
                            color: _currentCard.lastQuizCorrect == true 
                                ? Colors.green.shade700 
                                : Colors.orange.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _quizService.getQuizStatusDescription(_currentCard),
                            style: TextStyle(
                              color: _currentCard.lastQuizCorrect == true 
                                  ? Colors.green.shade700 
                                  : Colors.orange.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Study tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentCard.multipleChoiceOptions.isNotEmpty 
                          ? 'Tip: Take the quiz to earn EXP for your pet!'
                          : 'Tip: Try to answer before revealing the solution!',
                      style: TextStyle(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}