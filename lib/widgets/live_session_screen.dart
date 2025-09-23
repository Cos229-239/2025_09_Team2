import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/social_session.dart';
import '../models/deck.dart';
import '../models/card.dart';
import '../models/quiz_session.dart';
import '../providers/social_session_provider.dart';
import '../services/quiz_service.dart';
import '../providers/deck_provider.dart';
import '../providers/pet_provider.dart';

class LiveSessionScreen extends StatefulWidget {
  final SocialSession session;

  const LiveSessionScreen({super.key, required this.session});

  @override
  State<LiveSessionScreen> createState() => _LiveSessionScreenState();
}

class _LiveSessionScreenState extends State<LiveSessionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  QuizSession? _quizSession;
  FlashCard? _currentCard;
  int _selectedOptionIndex = -1;
  bool _isAnswerSubmitted = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeSession() async {
    if (widget.session.type == SessionType.quiz) {
      await _startQuizSession();
    }
  }

  Future<void> _startQuizSession() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      final quizService = Provider.of<QuizService>(context, listen: false);
      
      // Get decks for this session
      final sessionDecks = widget.session.deckIds
          .map((deckId) => deckProvider.decks.firstWhere(
                (deck) => deck.id == deckId,
                orElse: () => Deck(id: deckId, title: 'Unknown Deck', cards: []),
              ))
          .where((deck) => deck.cards.isNotEmpty)
          .toList();

      if (sessionDecks.isEmpty) {
        throw Exception('No valid decks found for this session');
      }

      // Create multiplayer quiz session
      final quizSession = await quizService.createMultiplayerQuizSession(
        decks: sessionDecks,
        socialSessionId: widget.session.id,
        participantIds: widget.session.participantIds,
      );

      if (quizSession != null) {
        setState(() {
          _quizSession = quizSession;
          _loadCurrentCard();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadCurrentCard() {
    if (_quizSession == null || _quizSession!.currentQuestionIndex >= _quizSession!.cardIds.length) {
      return;
    }

    final deckProvider = Provider.of<DeckProvider>(context, listen: false);
    final cardId = _quizSession!.cardIds[_quizSession!.currentQuestionIndex];
    
    // Find the card in any of the session decks
    for (final deckId in widget.session.deckIds) {
      final deck = deckProvider.decks.firstWhere(
        (d) => d.id == deckId,
        orElse: () => Deck(id: deckId, title: 'Unknown', cards: []),
      );
      
      for (final card in deck.cards) {
        if (card.id == cardId) {
          setState(() {
            _currentCard = card;
            _selectedOptionIndex = -1;
            _isAnswerSubmitted = false;
          });
          return;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final socialProvider = Provider.of<SocialSessionProvider>(context);
    final isHost = widget.session.hostId == socialProvider.currentUserId;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.session.title,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            Row(
              children: [
                const Icon(Icons.circle, color: Colors.white, size: 8),
                const SizedBox(width: 4),
                const Text(
                  'LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                const SizedBox(width: 12),
                Text(
                  '${widget.session.participantCount} participants',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _showLeaveConfirmation,
        ),
        actions: [
          if (isHost)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onSelected: (value) {
                switch (value) {
                  case 'end':
                    _showEndSessionConfirmation();
                    break;
                  case 'participants':
                    _showParticipantsList();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'participants',
                  child: Text('View Participants'),
                ),
                const PopupMenuItem(
                  value: 'end',
                  child: Text('End Session'),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Study'),
            Tab(text: 'Chat'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStudyTab(),
          _buildChatTab(),
        ],
      ),
    );
  }

  Widget _buildStudyTab() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading study session...'),
          ],
        ),
      );
    }

    if (widget.session.type == SessionType.quiz) {
      return _buildQuizInterface();
    } else {
      return _buildStudyInterface();
    }
  }

  Widget _buildQuizInterface() {
    if (_quizSession == null || _currentCard == null) {
      return const Center(
        child: Text('No quiz available'),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    final progress = (_quizSession!.currentQuestionIndex + 1) / _quizSession!.totalQuestions;

    return Column(
      children: [
        // Progress bar
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_quizSession!.currentQuestionIndex + 1} of ${_quizSession!.totalQuestions}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    '${(_quizSession!.currentScore * 100).round()}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ],
          ),
        ),

        // Question card
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question
                    Text(
                      _currentCard!.front,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Multiple choice options
                    ..._currentCard!.multipleChoiceOptions.asMap().entries.map((entry) {
                      final index = entry.key;
                      final option = entry.value;
                      final isSelected = _selectedOptionIndex == index;
                      final isCorrect = index == _currentCard!.correctAnswerIndex;

                      Color? backgroundColor;
                      Color? borderColor;
                      
                      if (_isAnswerSubmitted) {
                        if (isCorrect) {
                          backgroundColor = Colors.green.withValues(alpha: 0.2);
                          borderColor = Colors.green;
                        } else if (isSelected && !isCorrect) {
                          backgroundColor = Colors.red.withValues(alpha: 0.2);
                          borderColor = Colors.red;
                        }
                      } else if (isSelected) {
                        backgroundColor = colorScheme.primary.withValues(alpha: 0.2);
                        borderColor = colorScheme.primary;
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: _isAnswerSubmitted ? null : () {
                            setState(() {
                              _selectedOptionIndex = index;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: backgroundColor,
                              border: Border.all(
                                color: borderColor ?? colorScheme.outline,
                                width: borderColor != null ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: borderColor ?? colorScheme.outline,
                                      width: 2,
                                    ),
                                    color: isSelected ? (borderColor ?? colorScheme.primary) : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                if (_isAnswerSubmitted && isCorrect)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (_isAnswerSubmitted && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Submit/Next button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selectedOptionIndex == -1 
                            ? null 
                            : _isAnswerSubmitted 
                                ? _nextQuestion
                                : _submitAnswer,
                        child: Text(
                          _isAnswerSubmitted ? 'Next Question' : 'Submit Answer',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudyInterface() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.library_books, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Study Session',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Study session interface coming soon!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Session Chat',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Chat feature coming soon!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  void _submitAnswer() async {
    if (_selectedOptionIndex == -1 || _quizSession == null || _currentCard == null) return;

    setState(() {
      _isAnswerSubmitted = true;
    });

    try {
      final quizService = Provider.of<QuizService>(context, listen: false);
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      final socialProvider = Provider.of<SocialSessionProvider>(context, listen: false);
      
      // Find the deck containing this card
      final deckProvider = Provider.of<DeckProvider>(context, listen: false);
      Deck? cardDeck;
      
      for (final deckId in widget.session.deckIds) {
        final deck = deckProvider.decks.firstWhere(
          (d) => d.id == deckId,
          orElse: () => Deck(id: deckId, title: 'Unknown', cards: []),
        );
        
        if (deck.cards.any((c) => c.id == _currentCard!.id)) {
          cardDeck = deck;
          break;
        }
      }

      if (cardDeck != null) {
        await quizService.recordMultiplayerAnswer(
          sessionId: _quizSession!.id,
          participantId: socialProvider.currentUserId,
          cardId: _currentCard!.id,
          selectedOptionIndex: _selectedOptionIndex,
          correctOptionIndex: _currentCard!.correctAnswerIndex,
          deck: cardDeck,
          petProvider: petProvider,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting answer: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _nextQuestion() {
    if (_quizSession == null) return;

    setState(() {
      _quizSession = _quizSession!.copyWith(
        currentQuestionIndex: _quizSession!.currentQuestionIndex + 1,
      );
    });

    if (_quizSession!.hasMoreQuestions) {
      _loadCurrentCard();
    } else {
      _completeQuiz();
    }
  }

  void _completeQuiz() async {
    if (_quizSession == null) return;

    try {
      final quizService = Provider.of<QuizService>(context, listen: false);
      final petProvider = Provider.of<PetProvider>(context, listen: false);
      
      final completedSession = await quizService.completeMultiplayerQuizSession(
        _quizSession!.id,
        petProvider,
      );

      if (completedSession != null && mounted) {
        _showQuizResults(completedSession);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showQuizResults(QuizSession completedSession) {
    final socialProvider = Provider.of<SocialSessionProvider>(context, listen: false);
    final results = Provider.of<QuizService>(context, listen: false)
        .getMultiplayerResults(completedSession.id, socialProvider.currentUserId);

    if (results != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Quiz Complete!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Score: ${(results['score'] * 100).round()}%'),
              Text('Correct Answers: ${results['correctAnswers']}/${results['totalAnswers']}'),
              Text('Rank: ${results['rank']} of ${results['totalParticipants']}'),
              Text('EXP Earned: ${results['expEarned']}'),
              if (results['isWinner']) 
                const Text('🎉 Congratulations! You won!'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Exit live session
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Session'),
        content: const Text('Are you sure you want to leave this session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Exit live session
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _showEndSessionConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Session'),
        content: const Text('Are you sure you want to end this session for all participants?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final socialProvider = Provider.of<SocialSessionProvider>(context, listen: false);
              
              navigator.pop(); // Close dialog
              
              try {
                await socialProvider.endSession(widget.session.id);
                if (mounted) {
                  navigator.pop(); // Exit live session
                }
              } catch (e) {
                if (mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Error ending session: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }

  void _showParticipantsList() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Participants'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: widget.session.participantIds.length,
            itemBuilder: (context, index) {
              final participantId = widget.session.participantIds[index];
              final participantName = widget.session.participantNames[participantId] ?? 'Unknown';
              final isHost = participantId == widget.session.hostId;
              
              return ListTile(
                leading: CircleAvatar(
                  child: Text(participantName[0].toUpperCase()),
                ),
                title: Text(participantName),
                trailing: isHost ? const Icon(Icons.star, color: Colors.amber) : null,
              );
            },
          ),
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
}