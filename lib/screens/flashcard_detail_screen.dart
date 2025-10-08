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
import '../providers/app_state.dart';
import '../widgets/visual_flashcard_widget.dart';
import '../widgets/common/themed_background_wrapper.dart';
import '../services/quiz_service.dart';
import '../services/predictive_scheduling_service.dart' as scheduling;
import '../widgets/schedule/schedule_prediction_widget.dart';
import 'deck_completion_screen.dart';

// TODO: Flashcard Study Screen - Missing Advanced Study Features
// - No spaced repetition algorithm integration (SM-2, etc.)
// - Missing adaptive difficulty adjustment based on performance
// - No integration with active recall techniques
// - Missing study analytics and performance tracking
// - No image/audio support for multimedia flashcards
// - Missing collaborative study sessions with real-time sync
// - No voice input/output for hands-free studying
// - Missing gamification elements (streaks, points, badges)
// - No integration with external content sources
// - Missing study break reminders and focus management
// - No advanced card types (cloze deletion, image occlusion)
// - Missing export/import functionality for study data

/// Flashcard detail interface for reviewing cards in a deck with dashboard colors
class FlashcardDetailScreen extends StatefulWidget {
  final Deck deck;
  final bool startInQuizMode;

  const FlashcardDetailScreen({
    super.key,
    required this.deck,
    this.startInQuizMode = false,
  });

  @override
  State<FlashcardDetailScreen> createState() => _FlashcardDetailScreenState();
}

class _FlashcardDetailScreenState extends State<FlashcardDetailScreen>
    with SingleTickerProviderStateMixin {
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  // Individual quiz mode removed - only deck-based quizzes are supported
  final QuizService _quizService = QuizService();
  final scheduling.PredictiveSchedulingService _schedulingService =
      scheduling.PredictiveSchedulingService();
  bool _hasCompletedDeck = false; // Track if user has gone through all cards

  // Track which cards have been studied in this session (by card ID)
  final Set<String> _studiedCardIds = {};

  // Track which cards have been studied specifically in study mode (not quiz mode)
  final Set<String> _studyModeCardIds = {};

  // Deck-based quiz session state
  bool _isDeckQuizMode = false;
  QuizSession? _currentQuizSession;
  String? _quizSessionId;

  // Animation controller for flip effect
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;

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
    
    // Initialize flip animation
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    
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
    _flipController.dispose();
    // Mark current card as studied when leaving the screen, but only if widget is still mounted
    if (mounted) {
      _markCardAsStudied(_currentCard);
    }
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
        _flipController.reset(); // Reset flip animation for new card
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
        _flipController.reset(); // Reset flip animation for new card
        // Individual quiz mode removed
        _loadCardState(); // Load state for the previous card
      }
    });
  }

  void _toggleAnswer() {
    // Trigger flip animation
    if (_showAnswer) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    
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
    // Immediately set quiz mode to true to avoid showing flashcard interface
    if (mounted) {
      setState(() {
        _isDeckQuizMode = true;
      });
    }

    // Initialize quiz service
    await _quizService.initialize();

    // Create quiz session
    final session = await _quizService.createQuizSession(widget.deck);

    if (session == null) {
      // Show error message
      final statusMessage =
          await _quizService.getDeckQuizStatusDescription(widget.deck.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(statusMessage),
            backgroundColor: const Color(0xFF6FB8E9),
          ),
        );
      }
      return;
    }

    // Start quiz session - check if widget is still mounted
    if (mounted) {
      setState(() {
        _isDeckQuizMode = true;
        _currentQuizSession = session;
        _quizSessionId = session.id;
        _currentCardIndex = 0;
      });

      debugPrint('Started deck quiz with ${session.totalQuestions} questions');
    }
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

    if (mounted) {
      setState(() {
        _currentQuizSession = updatedSession;
      });
    }

    // Note: Quest progress is updated when the entire quiz session completes,
    // not for each individual question

    // Show immediate feedback
    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          String message;
          Color backgroundColor;

          if (isSkipped) {
            message =
                'Question skipped. Correct answer: ${currentCard.multipleChoiceOptions[correctIndex]}';
            backgroundColor = const Color(0xFF6FB8E9);
          } else if (isCorrect) {
            message = 'Correct! +$expEarned EXP';
            backgroundColor = Colors.green;
          } else {
            message =
                'Incorrect. The correct answer was ${currentCard.multipleChoiceOptions[correctIndex]}';
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
    return _quizService.getCurrentQuestionCard(
        _currentQuizSession!, widget.deck);
  }

  /// Shows the final results of the deck quiz
  void _showDeckQuizResults(QuizSession session) {
    final results = QuizResults.fromSession(session);

    // Update daily quest progress for completing a quiz (1 quiz = 1 deck completion)
    final questProvider =
        Provider.of<DailyQuestProvider>(context, listen: false);
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
        backgroundColor: const Color(0xFF242628),
        title: Row(
          children: [
            Icon(
              results.isPerfectScore ? Icons.star : Icons.quiz,
              color: results.isPerfectScore ? Colors.amber : const Color(0xFF6FB8E9),
            ),
            const SizedBox(width: 8),
            const Text(
              'Quiz Complete!',
              style: TextStyle(color: Color(0xFFD9D9D9)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              results.encouragementMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const SizedBox(height: 16),

            // Score breakdown
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withAlpha((0.3 * 255).round()),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Final Score:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD9D9D9),
                        ),
                      ),
                      Text(
                        '${(results.scorePercentage * 100).round()}% (${results.letterGrade})',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: results.scorePercentage >= 0.8
                              ? Colors.green
                              : const Color(0xFF6FB8E9),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Correct: ${results.correctAnswers}/${results.totalQuestions}',
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                  Text(
                    'Time: ${results.timeSpent.inMinutes}m ${results.timeSpent.inSeconds % 60}s',
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
                  Text(
                    'EXP Earned: +${results.totalExpEarned}',
                    style: const TextStyle(color: Color(0xFF888888)),
                  ),
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
            child: const Text(
              'Done',
              style: TextStyle(color: Color(0xFF888888)),
            ),
          ),
          if (results.scorePercentage <
              0.8) // Allow retry if score is below 80%
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A1A1A),
                foregroundColor: const Color(0xFFD9D9D9),
              ),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _exitDeckQuizMode();
              },
              child: const Text('Study More'),
            ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A1A1A),
              foregroundColor: const Color(0xFFD9D9D9),
            ),
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              _restartDeckQuiz();
            },
            child: const Text('Try Again'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FB8E9),
              foregroundColor: Colors.white,
            ),
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
        sessionLength:
            const Duration(minutes: 30), // Estimated session duration
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
      debugPrint('Error showing schedule prediction: $e');
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
    if (_isDeckQuizMode &&
        _currentQuizSession != null &&
        _currentQuizSession!.finalScore != null) {
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
      case 1:
        return scheduling.DayOfWeek.monday;
      case 2:
        return scheduling.DayOfWeek.tuesday;
      case 3:
        return scheduling.DayOfWeek.wednesday;
      case 4:
        return scheduling.DayOfWeek.thursday;
      case 5:
        return scheduling.DayOfWeek.friday;
      case 6:
        return scheduling.DayOfWeek.saturday;
      case 7:
        return scheduling.DayOfWeek.sunday;
      default:
        return scheduling.DayOfWeek.monday;
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
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
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
              ? const Color(0xFF4CAF50).withValues(alpha: 0.2) // Green for answer
              : const Color(0xFF6FB8E9).withValues(alpha: 0.2), // Dashboard accent for question
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showAnswer 
                ? const Color(0xFF4CAF50) 
                : const Color(0xFF6FB8E9),
              width: 1,
            ),
          ),
          child: Text(
            _showAnswer ? 'ANSWER' : 'QUESTION',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _showAnswer 
                ? const Color(0xFF4CAF50) 
                : const Color(0xFF6FB8E9),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Card content
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: _buildCardContent(),
            ),
          ),
        ),
      ],
    );
  }

  /// Build card content - uses visual widget for visual learners or cards with visual metadata
  Widget _buildCardContent() {
    final appState = Provider.of<AppState>(context, listen: false);
    final user = appState.currentUser;

    // Check if user is visual learner or card has visual metadata
    final bool isVisualLearner =
        user?.preferences.learningStyle.toLowerCase() == 'visual';
    final bool hasVisualMetadata = _currentCard.visualMetadata != null &&
        _currentCard.visualMetadata!.isNotEmpty;

    // Use visual widget for visual learners or cards with visual content
    if (isVisualLearner || hasVisualMetadata) {
      return VisualFlashcardWidget(
        flashcard: _currentCard,
        showBack: _showAnswer,
      );
    }

    // Default text display for non-visual content
    return Text(
      _showAnswer ? _currentCard.back : _currentCard.front,
      style: const TextStyle(
        fontSize: 20,
        height: 1.4,
        color: Color(0xFFD9D9D9), // Dashboard text color
      ),
      textAlign: TextAlign.center,
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
    final hasAnswered =
        _currentQuizSession!.answers.length > currentAnswerIndex;
    final currentAnswer =
        hasAnswered ? _currentQuizSession!.answers[currentAnswerIndex] : null;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quiz session header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6FB8E9),
              width: 1,
            ),
          ),
          child: Text(
            'DECK QUIZ - Question ${math.min(_currentQuizSession!.currentQuestionIndex + 1, _currentQuizSession!.totalQuestions)}/${_currentQuizSession!.totalQuestions}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFFD9D9D9),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Quiz session progress bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(
            value: _currentQuizSession!.progress,
            backgroundColor: const Color(0xFF242628),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6FB8E9)),
          ),
        ),

        const SizedBox(height: 16),

        // Current score display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Score: ',
              style: TextStyle(color: Color(0xFFD9D9D9)), // Dashboard text color
            ),
            Text(
              '${_currentQuizSession!.correctAnswers}/${_currentQuizSession!.questionsAnswered}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9), // Dashboard text color
              ),
            ),
            if (_currentQuizSession!.questionsAnswered > 0) ...[
              Text(
                ' (${(_currentQuizSession!.currentScore * 100).round()}%)',
                style: TextStyle(
                  color: _currentQuizSession!.currentScore >= 0.8
                      ? const Color(0xFF4CAF50) // Green for good score
                      : const Color(0xFF6FB8E9), // Blue for lower score
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
            color: Color(0xFFD9D9D9), // Dashboard text color
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
              final isSelected =
                  hasAnswered && currentAnswer!.selectedOptionIndex == index;
              final isCorrect = index == currentCard.correctAnswerIndex;
              final showResult = hasAnswered;

              Color? buttonColor;
              Color? textColor;
              if (showResult) {
                if (isSelected && isCorrect) {
                  buttonColor = const Color(0xFF4CAF50); // Green for correct
                  textColor = Colors.white;
                } else if (isSelected && !isCorrect) {
                  buttonColor = const Color(0xFFEF5350); // Red for incorrect
                  textColor = Colors.white;
                } else if (isCorrect) {
                  buttonColor = const Color(0xFF4CAF50); // Green for correct answer
                  textColor = Colors.white;
                } else {
                  buttonColor = const Color(0xFF242628); // Dashboard container color
                  textColor = const Color(0xFFD9D9D9); // Dashboard text color
                }
              } else {
                buttonColor = const Color(0xFF242628); // Dashboard container color
                textColor = const Color(0xFFD9D9D9); // Dashboard text color
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ElevatedButton(
                  onPressed: !hasAnswered
                      ? () => _answerDeckQuizQuestion(index)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: textColor,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: showResult && isCorrect 
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    '${String.fromCharCode(65 + index)}. $option',
                    style: TextStyle(
                      fontSize: 16,
                      color: textColor,
                    ),
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
              backgroundColor: const Color(0xFF6FB8E9), // Dashboard accent color
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
              color: currentAnswer!.isCorrect
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.2) // Green with transparency
                  : const Color(0xFFEF5350).withValues(alpha: 0.2), // Red with transparency
              border: Border.all(
                color: currentAnswer.isCorrect
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  currentAnswer.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: currentAnswer.isCorrect 
                    ? const Color(0xFF4CAF50) 
                    : const Color(0xFFEF5350),
                ),
                const SizedBox(width: 8),
                Text(
                  currentAnswer.isCorrect
                      ? 'Correct! +${currentAnswer.expEarned} EXP'
                      : 'Incorrect',
                  style: TextStyle(
                    color: currentAnswer.isCorrect
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFEF5350),
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

        // Update daily quest progress for studying a card (only if widget is still mounted)
        if (mounted) {
          final questProvider =
              Provider.of<DailyQuestProvider>(context, listen: false);
          questProvider.onCardStudied();
        }

        debugPrint(
            'Card studied in study mode: ${card.id} (Study quest progress: ${_studyModeCardIds.length})');
      }
    } else {
      debugPrint(
          'Card viewed in quiz mode: ${card.id} (not counted toward study quest)');
    }
  }

  void _showCompletionDialog() {
    // Show different completion dialog based on mode
    if (widget.startInQuizMode) {
      _showQuizCompletionDialog();
    } else {
      // Navigate to the dedicated completion screen for study mode
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DeckCompletionScreen(deck: widget.deck),
        ),
      );
    }
  }

  void _showQuizCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2A3050),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.green,
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Title
                Text(
                  'Quiz Complete!',
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Deck name
                Text(
                  widget.deck.title,
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 16,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Results summary
                Text(
                  'You completed all ${widget.deck.cards.length} cards',
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 14,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Try Again Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      // Reset the quiz
                      setState(() {
                        _currentCardIndex = 0;
                        _showAnswer = false;
                        _hasCompletedDeck = false;
                      });
                      // Restart quiz mode
                      _startDeckQuiz();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Back to Deck Selection Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close dialog
                      Navigator.of(context).pop(); // Go back to learning screen
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Deck Selection'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A3050),
                      foregroundColor: const Color(0xFF6FB8E9),
                      side: const BorderSide(
                        color: Color(0xFF6FB8E9),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Back to decks',
          ),
          title: Text(
            widget.deck.title,
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: const Color(0xFF6FB8E9),
          foregroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(
            color: Colors.white,
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                '${_currentCardIndex + 1} / ${widget.deck.cards.length}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
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
              backgroundColor: const Color(0xFF242628),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF6FB8E9),
              ),
            ),

            const SizedBox(height: 24),

            // Card display area
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * math.pi;
                    final isShowingBack = angle >= (math.pi / 2);
                    
                    // Apply additional 180-degree rotation to the back side to make text readable
                    final correctedAngle = isShowingBack ? angle + math.pi : angle;
                    
                    final transform = Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(correctedAngle);
                    
                    return Transform(
                      transform: transform,
                      alignment: Alignment.center,
                      child: GestureDetector(
                        onTap: _isDeckQuizMode ? null : _toggleAnswer,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF242628),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          child: _isDeckQuizMode
                              ? _buildQuizInterface()
                              : _buildCardInterface(),
                        ),
                      ),
                    );
                  },
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
                      backgroundColor: const Color(0xFF6C7B7F), // Neutral gray
                      foregroundColor: Colors.white,
                    ),
                  ),

                  // Quiz progress info
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                      border: Border.all(
                        color: const Color(0xFF6FB8E9),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Question ${math.min((_currentQuizSession?.currentQuestionIndex ?? 0) + 1, _currentQuizSession?.totalQuestions ?? 0)}/${_currentQuizSession?.totalQuestions ?? 0}',
                      style: const TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Skip question (for now, just mark as incorrect)
                  ElevatedButton.icon(
                    onPressed: (_isDeckQuizMode &&
                            _currentQuizSession != null &&
                            _currentQuizSession!.answers.length <=
                                _currentQuizSession!.currentQuestionIndex)
                        ? () => _answerDeckQuizQuestion(-1) // -1 indicates skip
                        : null,
                    icon: const Icon(Icons.skip_next),
                    label: const Text('Skip'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9), // Blue for skip
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
                      icon: Icon(_showAnswer
                          ? Icons.visibility_off
                          : Icons.visibility),
                      label: Text(_showAnswer ? 'Hide Answer' : 'Show Answer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FB8E9), // Dashboard accent
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
                      backgroundColor: const Color(0xFF6FB8E9), // Dashboard accent
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Deck quiz starter button - only show after completing deck study
              if (!_isDeckQuizMode &&
                  _hasCompletedDeck &&
                  widget.deck.cards
                          .where(
                              (card) => card.multipleChoiceOptions.isNotEmpty)
                          .length >=
                      2) ...[
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _startDeckQuiz,
                    icon: const Icon(Icons.quiz_outlined),
                    label: const Text('Start Deck Quiz'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9), // Dashboard accent
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
                  style: const TextStyle(
                    color: Color(0xFFB0B0B0), // Dashboard secondary text
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
                  // Quiz cooldown/status info
                  if (!_quizService.canTakeQuiz(_currentCard))
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _currentCard.lastQuizCorrect == true
                            ? const Color(0xFF38A169).withValues(alpha: 0.2) // Success green with transparency
                            : const Color(0xFF6FB8E9).withValues(alpha: 0.2), // Blue with transparency
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
                                ? const Color(0xFF38A169) // Success green
                                : const Color(0xFF6FB8E9), // Blue
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _quizService.getQuizStatusDescription(_currentCard),
                            style: TextStyle(
                              color: _currentCard.lastQuizCorrect == true
                                  ? const Color(0xFF38A169) // Success green
                                  : const Color(0xFF6FB8E9), // Blue
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
                color: const Color(0xFF242628),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6FB8E9)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, color: Color(0xFF6FB8E9)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _currentCard.multipleChoiceOptions.isNotEmpty
                          ? 'Tip: Take the quiz to earn EXP for your pet!'
                          : 'Tip: Try to answer before revealing the solution!',
                      style: const TextStyle(
                        color: Color(0xFFD9D9D9),
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
    ));
  }
}
