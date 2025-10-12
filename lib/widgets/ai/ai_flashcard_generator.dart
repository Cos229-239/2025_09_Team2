import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/ai_provider.dart';
import '../../providers/deck_provider.dart';
import '../../providers/app_state.dart';
import '../../models/deck.dart';
import '../../models/user.dart';
import '../../mixins/loading_state_mixin.dart';
import 'ai_settings_widget.dart';

// TODO: AI Flashcard Generator - Major Implementation Gaps
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
  final String? initialText;
  final String? initialTopic;

  const AIFlashcardGenerator({
    super.key,
    this.initialText,
    this.initialTopic,
  });

  @override
  State<AIFlashcardGenerator> createState() => _AIFlashcardGeneratorState();
}

class _AIFlashcardGeneratorState extends State<AIFlashcardGenerator>
    with LoadingStateMixin {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  String _selectedSubject = 'General';
  String _selectedLearningStyle = 'visual';
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
  void initState() {
    super.initState();
    // Pre-fill text fields if initial values are provided
    if (widget.initialTopic != null) {
      _topicController.text = widget.initialTopic!;
    }
    if (widget.initialText != null) {
      _textController.text = widget.initialText!;
    }
  }

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

      // Get current user or create default user, then apply selected learning style
      final baseUser = appState.currentUser ??
          User(
            id: 'generator_user',
            email: 'user@studypals.com',
            name: 'User',
            preferences: UserPreferences(
              learningStyle: _selectedLearningStyle,
              difficultyPreference: 'moderate',
            ),
          );

      // Create a copy of the user with the selected learning style from the dropdown
      // This ensures the AI uses the user's chosen style for this generation
      final user = User(
        id: baseUser.id,
        email: baseUser.email,
        name: baseUser.name,
        username: baseUser.username,
        profilePictureUrl: baseUser.profilePictureUrl,
        phoneNumber: baseUser.phoneNumber,
        dateOfBirth: baseUser.dateOfBirth,
        bio: baseUser.bio,
        location: baseUser.location,
        school: baseUser.school,
        major: baseUser.major,
        graduationYear: baseUser.graduationYear,
        isEmailVerified: baseUser.isEmailVerified,
        isPhoneVerified: baseUser.isPhoneVerified,
        isProfileComplete: baseUser.isProfileComplete,
        isActive: baseUser.isActive,
        createdAt: baseUser.createdAt,
        lastActiveAt: baseUser.lastActiveAt,
        lastLoginAt: baseUser.lastLoginAt,
        privacySettings: baseUser.privacySettings,
        preferences: UserPreferences(
          learningStyle:
              _selectedLearningStyle, // Use selected style from dropdown
          difficultyPreference: baseUser.preferences.difficultyPreference,
          showHints: baseUser.preferences.showHints,
          studyStartHour: baseUser.preferences.studyStartHour,
          studyEndHour: baseUser.preferences.studyEndHour,
          studyDaysOfWeek: baseUser.preferences.studyDaysOfWeek,
          maxCardsPerDay: baseUser.preferences.maxCardsPerDay,
          maxMinutesPerDay: baseUser.preferences.maxMinutesPerDay,
          breakInterval: baseUser.preferences.breakInterval,
          breakDuration: baseUser.preferences.breakDuration,
          autoPlayAudio: baseUser.preferences.autoPlayAudio,
          cardReviewDelay: baseUser.preferences.cardReviewDelay,
          studyReminders: baseUser.preferences.studyReminders,
          achievementNotifications:
              baseUser.preferences.achievementNotifications,
          socialNotifications: baseUser.preferences.socialNotifications,
          petCareReminders: baseUser.preferences.petCareReminders,
          emailDigest: baseUser.preferences.emailDigest,
          reminderTime: baseUser.preferences.reminderTime,
          theme: baseUser.preferences.theme,
          primaryColor: baseUser.preferences.primaryColor,
          fontFamily: baseUser.preferences.fontFamily,
          fontSize: baseUser.preferences.fontSize,
          animations: baseUser.preferences.animations,
          soundEffects: baseUser.preferences.soundEffects,
          language: baseUser.preferences.language,
          timezone: baseUser.preferences.timezone,
          offline: baseUser.preferences.offline,
          autoSync: baseUser.preferences.autoSync,
          dataRetentionDays: baseUser.preferences.dataRetentionDays,
        ),
        loginCount: baseUser.loginCount,
        metadata: baseUser.metadata,
      );

      debugPrint('User learning style: ${user.preferences.learningStyle}');
      debugPrint(
          'Selected learning style from dropdown: $_selectedLearningStyle');

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
                _selectedLearningStyle = 'visual';
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
          return Container(
            decoration: BoxDecoration(
              color: const Color(0xFF242628), // Dashboard container color
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(
                    Icons.auto_awesome_outlined,
                    size: 48,
                    color: const Color(0xFF6FB8E9).withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Flashcard Generator',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color:
                              const Color(0xFFD9D9D9), // Dashboard text color
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'AI features are not available. Configure your AI settings to enable automatic flashcard generation.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: Color(0xFFB0B0B0)), // Dimmer text color
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF6FB8E9), // Dashboard accent color
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF242628), // Dashboard container color
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(2.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Topic input (removed duplicate header since dialog has one)
                  TextField(
                    controller: _topicController,
                    style: const TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontSize: 14), // Dashboard text color
                    decoration: InputDecoration(
                      labelText: 'Topic or Subject',
                      labelStyle: const TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 12),
                      hintText: 'e.g., Photosynthesis, World War II...',
                      hintStyle: const TextStyle(
                          color: Color(0xFF808080), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF6FB8E9), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.topic,
                          color: Color(0xFF6FB8E9), size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Text input for source material
                  TextField(
                    controller: _textController,
                    maxLines: 1,
                    style: const TextStyle(
                        color: Color(0xFFD9D9D9),
                        fontSize: 14), // Dashboard text color
                    decoration: InputDecoration(
                      labelText: 'Source Text (Optional)',
                      labelStyle: const TextStyle(
                          color: Color(0xFFB0B0B0), fontSize: 12),
                      hintText: 'Paste notes or material...',
                      hintStyle: const TextStyle(
                          color: Color(0xFF808080), fontSize: 12),
                      filled: true,
                      fillColor: const Color(0xFF1A1A1A),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Color(0xFF6FB8E9), width: 2),
                      ),
                      prefixIcon: const Icon(Icons.text_snippet,
                          color: Color(0xFF6FB8E9), size: 20),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Options row
                  Row(
                    children: [
                      // Subject dropdown
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedSubject,
                          style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 14), // Dashboard text color
                          dropdownColor: const Color(
                              0xFF242628), // Dashboard container color
                          decoration: InputDecoration(
                            labelText: 'Subject',
                            labelStyle: const TextStyle(
                                color: Color(0xFFB0B0B0), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: const Color(0xFF6FB8E9)
                                      .withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: const Color(0xFF6FB8E9)
                                      .withValues(alpha: 0.3)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF6FB8E9), width: 2),
                            ),
                          ),
                          items: _subjects.map((subject) {
                            return DropdownMenuItem(
                              value: subject,
                              child: Text(subject,
                                  style: const TextStyle(
                                      color: Color(0xFFD9D9D9), fontSize: 14)),
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
                      const SizedBox(width: 8),

                      // Learning style dropdown
                      Flexible(
                        flex: 1,
                        child: DropdownButtonFormField<String>(
                          initialValue: _selectedLearningStyle,
                          style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 14), // Dashboard text color
                          dropdownColor: const Color(
                              0xFF242628), // Dashboard container color
                          decoration: InputDecoration(
                            labelText: 'Learning Style',
                            labelStyle: const TextStyle(
                                color: Color(0xFFB0B0B0), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFF1A1A1A),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: const Color(0xFF6FB8E9)
                                      .withValues(alpha: 0.3)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: const Color(0xFF6FB8E9)
                                      .withValues(alpha: 0.3)),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Color(0xFF6FB8E9), width: 2),
                            ),
                          ),
                          items: _learningStyles.map((style) {
                            return DropdownMenuItem(
                              value: style,
                              child: Text(
                                style.substring(0, 1).toUpperCase() +
                                    style.substring(1),
                                style: const TextStyle(
                                    color: Color(0xFFD9D9D9), fontSize: 14),
                              ),
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
                  const SizedBox(height: 4),

                  // Card count slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cards to Generate: $_cardCount',
                        style: const TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontSize: 13,
                        ),
                      ),
                      Slider(
                        value: _cardCount.toDouble(),
                        min: 3,
                        max: 15,
                        divisions: 12,
                        activeColor:
                            const Color(0xFF6FB8E9), // Dashboard accent color
                        inactiveColor:
                            const Color(0xFF6FB8E9).withValues(alpha: 0.3),
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
                      padding: const EdgeInsets.all(4),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF5350)
                            .withValues(alpha: 0.1), // Red with transparency
                        border: Border.all(
                            color:
                                const Color(0xFFEF5350).withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Color(0xFFEF5350), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _generationError!,
                              style: const TextStyle(
                                  color: Color(0xFFEF5350), fontSize: 13),
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 16),
                      label: Text(
                        isLoading ? 'Generating...' : 'Generate Flashcards',
                        style: const TextStyle(fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFF6FB8E9), // Dashboard accent color
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),

                  // Tips
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6FB8E9).withValues(
                          alpha: 0.1), // Dashboard accent with transparency
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color:
                                  Color(0xFF6FB8E9), // Dashboard accent color
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tips:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color:
                                    Color(0xFF6FB8E9), // Dashboard accent color
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
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFD9D9D9), // Dashboard text color
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
