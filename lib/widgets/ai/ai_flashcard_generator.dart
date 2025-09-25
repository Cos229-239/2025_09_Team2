import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/app_state.dart';
import '../../models/deck.dart';
import '../../models/user.dart';
import '../../mixins/loading_state_mixin.dart';
import '../../widgets/visual_flashcard_widget.dart';
import 'ai_settings_widget.dart';

// TODO: AI Flashcard Generator - Major Implementation Gaps
// - AI Provider currently uses pattern matching, not real AI
// - No integration with actual AI services (OpenAI, Gemini, Claude)
// - Need proper AI configuration management
// - Missing error handling for AI service failures
// - No rate limiting or usage tracking
// - Quality validation of generated flashcards needed
// - Batch processing for large text inputs missing
// - No customization of flashcard difficulty levels
// - Missing support for different flashcard types (image, audio)
// - No user feedback collection on generated content quality
// - Template system for different subjects not implemented

/// AI-Powered Flashcard Generator
class AIFlashcardGenerator extends StatefulWidget {
  const AIFlashcardGenerator({super.key});

  @override
  State<AIFlashcardGenerator> createState() => _AIFlashcardGeneratorState();
}

class _AIFlashcardGeneratorState extends State<AIFlashcardGenerator>
    with LoadingStateMixin {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  String _selectedSubject = 'General';
  String _selectedLearningStyle = 'adaptive';
  int _cardCount = 5;
  String? _generationError;

  final List<String> _subjects = [
    'General',
    'Mathematics',
    'Science',
    'History',
    'Language Arts',
    'Computer Science',
    'Biology',
    'Chemistry',
    'Physics',
    'Geography',
    'Literature',
    'Philosophy',
  ];

  final List<String> _learningStyles = [
    'adaptive',
    'visual',
    'auditory',
    'kinesthetic',
    'reading',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _generateFlashcards() async {
    if (_topicController.text.trim().isEmpty) {
      setState(() {
        _generationError = 'Please enter a topic or paste some text';
      });
      return;
    }

    setState(() {
      setLoading(true);
      _generationError = null;
    });
    try {
      final aiProvider =
          Provider.of<StudyPalsAIProvider>(context, listen: false);
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      final appState = Provider.of<AppState>(context, listen: false);

      // Generate flashcards using AI
      debugPrint('=== AI Flashcard Generator Widget Debug ===');
      debugPrint('Topic: ${_topicController.text}');
      debugPrint('Text: ${_textController.text}');
      debugPrint('Subject: $_selectedSubject');
      debugPrint('Card Count: $_cardCount');

      // Get current user or create default user with selected learning style
      final user = appState.currentUser ?? User(
        id: 'generator_user',
        email: 'user@studypals.com',
        name: 'User',
        preferences: UserPreferences(
          learningStyle: _selectedLearningStyle,
          difficultyPreference: 'moderate',
        ),
      );

      debugPrint('User learning style: ${user.preferences.learningStyle}');

      final flashcards = await aiProvider.generateFlashcardsFromText(
        _textController.text.isNotEmpty
            ? _textController.text
            : _topicController.text,
        user,
        count: _cardCount,
        subject: _selectedSubject,
      );

      debugPrint(
          'Generated ${flashcards.length} flashcards (expected $_cardCount)');

      if (flashcards.isNotEmpty) {
        // Create a new deck for the generated cards
        final newDeck = Deck(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: 'AI Generated: ${_topicController.text}',
          tags: [_selectedSubject.toLowerCase(), 'ai-generated'],
          cards: flashcards,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Add the deck to the deck provider
        await deckProvider.addDeck(newDeck);

        // Show success dialog
        if (mounted) {
          _showSuccessDialog(flashcards.length);
        }
      } else {
        setState(() {
          _generationError =
              'No flashcards were generated. Please try a different topic.';
        });
      }
    } catch (e) {
      setState(() {
        _generationError = 'Failed to generate flashcards: $e';
      });
    } finally {
      // Don't wrap setLoading in setState - it already handles state updates
      setLoading(false);
    }
  }

  Future<void> _debugAI() async {
    if (_topicController.text.trim().isEmpty) {
      setState(() {
        _generationError = 'Please enter a topic first.';
      });
      return;
    }

    setState(() {
      setLoading(true);
      _generationError = null;
    });

    try {
      final aiProvider =
          Provider.of<StudyPalsAIProvider>(context, listen: false);
      
      // Create a sample user for debugging (in production, get from user provider)
      final sampleUser = User(
        id: 'debug_user',
        email: 'debug@studypals.com',
        name: 'Debug User',
        preferences: UserPreferences(
          learningStyle: 'visual',
          difficultyPreference: 'moderate',
        ),
      );
      
      final response = await aiProvider.aiService.debugFlashcardGeneration(
        _topicController.text.trim(),
        _selectedSubject,
        sampleUser,
      );

      // Show the raw response in a dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Raw AI Response'),
            content: SingleChildScrollView(
              child: Text(response),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _generationError = 'Debug failed: $e';
      });
    } finally {
      setState(() {
        setLoading(false);
      });
    }
  }

  void _showSuccessDialog(int cardCount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Generated $cardCount flashcards successfully!'),
            const SizedBox(height: 12),
            const Text(
              'Your new deck has been created and can be found in:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            const Text('📚 Dashboard → "Decks" Tab (4th tab at bottom)'),
            const SizedBox(height: 8),
            Text(
              'Deck Name: "AI Generated: ${_topicController.text}"',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Clear the form
              _topicController.clear();
              _textController.clear();
              setState(() {
                _selectedSubject = 'General';
                _selectedLearningStyle = 'adaptive';
                _cardCount = 5;
              });
            },
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate back to dashboard to see the deck
              Navigator.of(context).pop(); // Close the flashcard generator
            },
            child: const Text('View Deck'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyPalsAIProvider>(
      builder: (context, aiProvider, child) {
        if (!aiProvider.isAIEnabled) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Flashcard Generator',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI features are not available. Configure your AI settings to enable automatic flashcard generation.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to AI settings
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('AI Settings'),
                            ),
                            body: const AISettingsWidget(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('Configure AI'),
                  ),
                ],
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Flashcard Generator',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Topic input
                TextField(
                  controller: _topicController,
                  decoration: const InputDecoration(
                    labelText: 'Topic or Subject',
                    hintText: 'e.g., Photosynthesis, World War II, Calculus...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.topic),
                  ),
                ),
                const SizedBox(height: 16),

                // Text input for source material
                TextField(
                  controller: _textController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Source Text (Optional)',
                    hintText:
                        'Paste notes, textbook excerpts, or any material to generate flashcards from...',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_snippet),
                  ),
                ),
                const SizedBox(height: 16),

                // Options row
                Row(
                  children: [
                    // Subject dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSubject,
                        decoration: const InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(),
                        ),
                        items: _subjects.map((subject) {
                          return DropdownMenuItem(
                            value: subject,
                            child: Text(subject),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSubject = value;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Learning style dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedLearningStyle,
                        decoration: const InputDecoration(
                          labelText: 'Learning Style',
                          border: OutlineInputBorder(),
                        ),
                        items: _learningStyles.map((style) {
                          return DropdownMenuItem(
                            value: style,
                            child: Text(style.substring(0, 1).toUpperCase() + style.substring(1)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedLearningStyle = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Card count slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cards to Generate: $_cardCount',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Slider(
                      value: _cardCount.toDouble(),
                      min: 3,
                      max: 15,
                      divisions: 12,
                      onChanged: (value) {
                        setState(() {
                          _cardCount = value.round();
                        });
                      },
                    ),
                  ],
                ),

                // Error message
                if (_generationError != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _generationError!,
                            style: TextStyle(color: Colors.red.shade600),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Generate button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _generateFlashcards,
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                        isLoading ? 'Generating...' : 'Generate Flashcards'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),

                // Debug button
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isLoading ? null : _debugAI,
                    icon: const Icon(Icons.bug_report),
                    label: const Text('Debug AI Response'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),

                // Tips
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tips:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '• Be specific with your topic for better results\n'
                        '• Paste text from notes or textbooks for targeted cards\n'
                        '• Choose the right subject to get relevant content\n'
                        '• Start with fewer cards and generate more if needed',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
