import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/deck.dart';
import '../models/card.dart';
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

  FlashCard get _currentCard {
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
      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correct! +$_expEarned EXP earned!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } else {
      // Show incorrect message with cooldown info
      Future.delayed(const Duration(milliseconds: 500), () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect! You can retry this quiz in 6 hours.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      });
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
