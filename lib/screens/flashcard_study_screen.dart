import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/quiz_session.dart';
import '../providers/pet_provider.dart';
import '../providers/daily_quest_provider.dart';
import '../services/quiz_service.dart';

/// Flashcard study interface for reviewing cards in a deck
class FlashcardStudyScreen extends StatefulWidget {
  final Deck deck;

  const FlashcardStudyScreen({
    super.key,
    required this.deck,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  bool _showQuiz = false;
  int? _selectedAnswer;
  bool? _quizResult;
  int? _expEarned;
  final QuizService _quizService = QuizService();

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
  }

  void _loadCardState() {
    final card = _currentCard;
    
    // If card has quiz attempt data, restore the quiz state
    if (card.lastQuizAttempt != null) {
      setState(() {
        _selectedAnswer = card.lastQuizCorrect == true ? card.correctAnswerIndex : -1;
        _quizResult = card.lastQuizCorrect;
        if (card.lastQuizCorrect == true) {
          _expEarned = card.calculateExpReward();
        }
      });
    } else {
      // Reset state for cards without attempts
      setState(() {
        _selectedAnswer = null;
        _quizResult = null;
        _expEarned = null;
      });
    }
  }

  void _nextCard() {
    setState(() {
      if (_currentCardIndex < widget.deck.cards.length - 1) {
        _currentCardIndex++;
        _showAnswer = false;
        _showQuiz = false;
        _loadCardState(); // Load state for the new card
      } else {
        // Show completion dialog
        _showCompletionDialog();
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentCardIndex > 0) {
        _currentCardIndex--;
        _showAnswer = false;
        _showQuiz = false;
        _loadCardState(); // Load state for the previous card
      }
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
      _showQuiz = false;
    });
    
    // If showing answer for the first time, count as studying a card
    if (_showAnswer) {
      final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);
      questProvider.onCardStudied();
    }
  }

  void _startQuiz() {
    if (!_quizService.canTakeQuiz(_currentCard)) {
      // Show status message based on quiz state
      final statusMessage = _quizService.getQuizStatusDescription(_currentCard);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage),
          backgroundColor: _currentCard.lastQuizCorrect == true ? Colors.green : Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _showQuiz = true;
      _showAnswer = false;
      _selectedAnswer = null;
      _quizResult = null;
      _expEarned = null;
    });
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
      _selectedAnswer = null;
      _quizResult = null;
      _expEarned = null;
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
    final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);

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
      _selectedAnswer = isSkipped ? null : selectedIndex; // Don't show selection for skipped
      _quizResult = isSkipped ? null : isCorrect; // Don't show result for skipped
      _expEarned = expEarned;
    });

    // Update daily quest progress
    questProvider.onQuizTaken();
    if (isCorrect) {
      questProvider.onPerfectScore(); // Each correct answer contributes to perfect score
    }

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
        _selectedAnswer = null;
        _quizResult = null;
        _expEarned = null;
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
      _selectedAnswer = null;
      _quizResult = null;
      _expEarned = null;
    });
  }

  /// Restarts the deck quiz
  void _restartDeckQuiz() {
    _exitDeckQuizMode();
    _startDeckQuiz();
  }

  void _selectAnswer(int index) {
    if (_selectedAnswer != null) return; // Already answered
    
    setState(() {
      _selectedAnswer = index;
      _quizResult = index == _currentCard.correctAnswerIndex;
    });

    // Record the quiz attempt
    final petProvider = Provider.of<PetProvider>(context, listen: false);
    final questProvider = Provider.of<DailyQuestProvider>(context, listen: false);
    
    _quizService.recordQuizAttempt(
      card: _currentCard,
      correct: _quizResult!,
      petProvider: petProvider,
    );

    // Update daily quest progress
    questProvider.onQuizTaken();
    
    if (_quizResult!) {
      _expEarned = _currentCard.calculateExpReward();
      
      // Check if this was a perfect score (getting all quiz questions right)
      // For now, we'll consider any correct answer as contributing to perfect score quest
      questProvider.onPerfectScore();
      
      // Show success message
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Correct! +$_expEarned EXP earned!'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } else {
      // Show incorrect message with cooldown info
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Incorrect! You can retry this quiz in 6 hours.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    }
  }

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
    // Use deck quiz mode if active
    if (_isDeckQuizMode && _currentQuizSession != null) {
      return _buildDeckQuizInterface();
    }
    
    // Legacy individual card quiz mode
    final hasMultipleChoice = _currentCard.multipleChoiceOptions.isNotEmpty;
    
    if (!hasMultipleChoice) {
      return _buildCardInterface(); // Fallback to regular card interface
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Quiz label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: Colors.purple.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            'QUIZ MODE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Difficulty indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Difficulty: '),
            ...List.generate(5, (index) => Icon(
              Icons.star,
              size: 16,
              color: index < _currentCard.difficulty 
                  ? Colors.amber 
                  : Colors.grey.shade300,
            )),
          ],
        ),

        const SizedBox(height: 24),

        // Question
        Text(
          _currentCard.front,
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
            itemCount: _currentCard.multipleChoiceOptions.length,
            itemBuilder: (context, index) {
              final option = _currentCard.multipleChoiceOptions[index];
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == _currentCard.correctAnswerIndex;
              final showResult = _selectedAnswer != null;
              
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
                  onPressed: _selectedAnswer == null ? () => _selectAnswer(index) : null,
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

        // Result message
        if (_quizResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _quizResult! ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _quizResult! ? Icons.check_circle : Icons.cancel,
                  color: _quizResult! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _quizResult! 
                      ? 'Correct! +${_expEarned ?? 0} EXP'
                      : 'Incorrect. Quiz locked for 6 hours.',
                  style: TextStyle(
                    color: _quizResult! ? Colors.green.shade700 : Colors.red.shade700,
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

  /// Builds the interface for deck-based quiz sessions
  Widget _buildDeckQuizInterface() {
    if (_currentQuizSession == null) {
      return const Center(child: Text('Error: No quiz session'));
    }

    final currentCard = _getCurrentQuizCard();
    if (currentCard == null) {
      return const Center(child: Text('Quiz completed!'));
    }

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
            'DECK QUIZ - Question ${_currentQuizSession!.currentQuestionIndex + 1}/${_currentQuizSession!.totalQuestions}',
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
              final isSelected = _selectedAnswer == index;
              final isCorrect = index == currentCard.correctAnswerIndex;
              final showResult = _selectedAnswer != null;
              
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
                  onPressed: _selectedAnswer == null 
                      ? () => _answerDeckQuizQuestion(index) 
                      : null,
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
        if (_selectedAnswer != null && _currentQuizSession!.hasMoreQuestions) ...[
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
        if (_quizResult != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _quizResult! ? Colors.green.shade100 : Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _quizResult! ? Icons.check_circle : Icons.cancel,
                  color: _quizResult! ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _quizResult! 
                      ? 'Correct! +${_expEarned ?? 0} EXP'
                      : 'Incorrect',
                  style: TextStyle(
                    color: _quizResult! ? Colors.green.shade700 : Colors.red.shade700,
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

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deck Complete!'),
        content: Text(
            'You\'ve finished studying "${widget.deck.title}". Great job!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to deck list
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              setState(() {
                _currentCardIndex = 0;
                _showAnswer = false;
                _showQuiz = false;
                _selectedAnswer = null;
                _quizResult = null;
                _expEarned = null;
              });
            },
            child: const Text('Study Again'),
          ),
        ],
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
                    child: _showQuiz ? _buildQuizInterface() : _buildCardInterface(),
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
                      'Question ${(_currentQuizSession?.currentQuestionIndex ?? 0) + 1}/${_currentQuizSession?.totalQuestions ?? 0}',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  // Skip question (for now, just mark as incorrect)
                  ElevatedButton.icon(
                    onPressed: _selectedAnswer == null 
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

                  // Quiz/Show answer button
                  if (_currentCard.multipleChoiceOptions.isNotEmpty && !_showAnswer)
                    ElevatedButton.icon(
                      onPressed: _startQuiz,
                      icon: Icon(_showQuiz ? Icons.quiz : Icons.play_arrow),
                      label: Text(_showQuiz ? 'Quiz Mode' : 'Take Quiz'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _quizService.canTakeQuiz(_currentCard) 
                            ? Colors.purple.shade600 
                            : Colors.grey.shade400,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    )
                  else
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

              // Deck quiz starter button
              if (!_showQuiz && widget.deck.cards.where((card) => 
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
                  if (!_showQuiz)
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
