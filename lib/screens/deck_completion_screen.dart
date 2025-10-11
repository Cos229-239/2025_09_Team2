import 'package:flutter/material.dart';
import '../models/deck.dart';
import '../services/quiz_service.dart';
import 'flashcard_detail_screen.dart';

/// Screen shown when a user completes studying a deck
/// Provides options to take a quiz or return to study
class DeckCompletionScreen extends StatefulWidget {
  final Deck deck;

  const DeckCompletionScreen({
    super.key,
    required this.deck,
  });

  @override
  State<DeckCompletionScreen> createState() => _DeckCompletionScreenState();
}

class _DeckCompletionScreenState extends State<DeckCompletionScreen> {
  final QuizService _quizService = QuizService();
  bool _isStartingQuiz = false;

  int get _quizEligibleCards => widget.deck.cards
      .where((card) => card.multipleChoiceOptions.isNotEmpty)
      .length;

  bool get _canTakeQuiz => _quizEligibleCards >= 2;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16181A),
      appBar: AppBar(
        title: Text('${widget.deck.title} Complete!'),
        centerTitle: true,
        backgroundColor: const Color(0xFF6FB8E9),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Celebration icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.check_circle,
                size: 80,
                color: Color(0xFF4CAF50),
              ),
            ),

            const SizedBox(height: 32),

            // Completion message
            Text(
              'Congratulations!',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4CAF50),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            Text(
              'You\'ve successfully studied all ${widget.deck.cards.length} flashcards in "${widget.deck.title}"',
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFFD9D9D9),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 48),

            // Stats card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF242628),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Cards Studied',
                        '${widget.deck.cards.length}',
                        Icons.style,
                        const Color(0xFF6FB8E9), // Use our standard blue
                      ),
                      _buildStatItem(
                        'Quiz Ready',
                        '$_quizEligibleCards',
                        Icons.quiz,
                        const Color(0xFF6FB8E9), // Use our standard blue
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Action buttons
            if (_canTakeQuiz) ...[
              // Quiz button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isStartingQuiz ? null : _startQuiz,
                  icon: _isStartingQuiz
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.quiz),
                  label: Text(
                      _isStartingQuiz ? 'Starting Quiz...' : 'Take Deck Quiz'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FB8E9),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                'Test your knowledge with $_quizEligibleCards multiple choice questions',
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
            ] else ...[
              // No quiz available message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF242628),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.orange.shade600.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange.shade600,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quiz Not Available',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'This deck needs at least 2 cards with multiple choice options for quiz mode.',
                      style: TextStyle(
                        color: const Color(0xFFD9D9D9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],

            // Secondary actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _studyAgain(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Study Again'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6FB8E9),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFF6FB8E9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Decks'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6FB8E9),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(
                        color: Color(0xFF6FB8E9),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFFD9D9D9),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _startQuiz() async {
    setState(() {
      _isStartingQuiz = true;
    });

    try {
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
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Navigate to flashcard detail screen in quiz mode
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FlashcardDetailScreen(
              deck: widget.deck,
              startInQuizMode: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isStartingQuiz = false;
        });
      }
    }
  }

  void _studyAgain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => FlashcardDetailScreen(deck: widget.deck),
      ),
    );
  }
}
