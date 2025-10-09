// ai_tutor_chat.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../providers/enhanced_ai_tutor_provider.dart';
import '../../providers/app_state.dart';
import '../../models/chat_message.dart';
import 'ai_flashcard_generator.dart';

/// Main AI Tutor Chat Widget with full adaptive UI
class AITutorChat extends StatefulWidget {
  const AITutorChat({super.key});

  @override
  State<AITutorChat> createState() => _AITutorChatState();
}

class _AITutorChatState extends State<AITutorChat>
    with TickerProviderStateMixin {
  // Controllers
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  
  // State variables
  bool _showScrollToBottom = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  
  // Subject and difficulty options
  final List<String> _subjects = [
    'Mathematics',
    'Science',
    'History',
    'English',
    'Programming',
    'Chemistry',
    'Physics',
    'Biology',
  ];
  
  final List<String> _difficulties = [
    'Beginner',
    'Intermediate',
    'Advanced',
  ];
  
  final List<String> _learningGoalOptions = [
    'Homework help',
    'Exam preparation',
    'Concept understanding',
    'Problem solving',
    'Practice exercises',
    'Quick review',
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeProvider();
    _scrollController.addListener(_scrollListener);
    _messageFocusNode.addListener(_focusListener);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _initializeProvider() async {
    final provider = context.read<EnhancedAITutorProvider>();
    await provider.initialize();
  }

  void _scrollListener() {
    if (_scrollController.hasClients) {
      final showButton = _scrollController.offset > 200;
      if (showButton != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = showButton;
        });
      }
    }
  }

  void _focusListener() {
    if (_messageFocusNode.hasFocus) {
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom({bool animated = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        if (animated) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      }
    });
  }

  String _getLastAIResponse(EnhancedAITutorProvider provider) {
    // Get the last AI tutor response from messages
    for (int i = provider.messages.length - 1; i >= 0; i--) {
      final message = provider.messages[i];
      if (message.type == MessageType.assistant) {
        return message.content;
      }
    }
    return '';
  }

  void _generateFlashcardsFromAI(EnhancedAITutorProvider provider) {
    final lastAIResponse = _getLastAIResponse(provider);
    
    if (lastAIResponse.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No AI tutor response found. Please have a conversation first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navigate to AI flashcard generator with pre-filled text
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Generate Flashcards'),
            backgroundColor: const Color(0xFF242628),
            foregroundColor: const Color(0xFFD9D9D9),
          ),
          backgroundColor: const Color(0xFF1A1A1A),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: AIFlashcardGenerator(
                initialTopic: provider.currentSubject.isNotEmpty 
                    ? provider.currentSubject 
                    : 'AI Tutor Session',
                initialText: lastAIResponse,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EnhancedAITutorProvider, AppState>(
      builder: (context, tutorProvider, appState, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF16181A), // Dashboard background color
          appBar: _buildAppBar(tutorProvider),
          body: Stack(
            children: [
              Column(
                children: [
                  // Progress bar if active session
                  if (tutorProvider.hasActiveSession)
                    _buildSessionProgressBar(tutorProvider),
                  
                  // Session setup or chat area
                  Expanded(
                    child: tutorProvider.hasActiveSession
                        ? _buildChatView(tutorProvider)
                        : _buildSessionSetup(tutorProvider),
                  ),
                  
                  // Quick replies
                  if (tutorProvider.quickReplies.isNotEmpty &&
                      tutorProvider.hasActiveSession)
                    _buildQuickReplies(tutorProvider, appState),
                  
                  // Message input
                  if (tutorProvider.hasActiveSession)
                    _buildMessageInput(tutorProvider, appState),
                ],
              ),
              
              // Floating scroll to bottom button
              if (_showScrollToBottom)
                Positioned(
                  right: 16,
                  bottom: tutorProvider.hasActiveSession ? 100 : 20,
                  child: _buildScrollToBottomButton(),
                ),
              
              // Badges overlay
              if (tutorProvider.showBadges)
                _buildBadgesOverlay(tutorProvider),
              
              // Progress overlay
              if (tutorProvider.showProgress)
                _buildProgressOverlay(tutorProvider),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(EnhancedAITutorProvider provider) {
    return AppBar(
      backgroundColor: const Color(0xFF242628), // Dashboard header color
      foregroundColor: const Color(0xFFD9D9D9), // Light text
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology,
                size: 20,
                color: Color(0xFF6FB8E9), // Dashboard blue accent
              ),
              const SizedBox(width: 8),
              Text(
                provider.hasActiveSession
                    ? 'AI Tutor - ${provider.currentSubject}'
                    : 'AI Tutor',
                style: const TextStyle(
                  fontSize: 18,
                  color: Color(0xFFD9D9D9), // Light text
                ),
              ),
            ],
          ),
          if (provider.hasActiveSession)
            Text(
              '${provider.currentDifficulty} Level',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF888888), // Muted text
              ),
            ),
        ],
      ),
      actions: [
        // Streak indicator
        if (provider.currentStreak > 0)
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6FB8E9).withValues(alpha: 0.2), // Dashboard blue accent
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '${provider.currentStreak}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFFD9D9D9), // Light text
                  ),
                ),
              ],
            ),
          ),
        
        // Points indicator
        Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.1), // Dashboard blue accent
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Text('🏆', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 4),
              Text(
                '${provider.totalPoints}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFD9D9D9), // Light text
                ),
              ),
            ],
          ),
        ),
        
        // Menu button
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, provider),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'progress',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 20),
                  SizedBox(width: 8),
                  Text('View Progress'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'badges',
              child: Row(
                children: [
                  Icon(Icons.emoji_events, size: 20),
                  SizedBox(width: 8),
                  Text('My Badges'),
                ],
              ),
            ),
            if (provider.hasActiveSession)
              const PopupMenuItem(
                value: 'generate_flashcards',
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 20, color: Color(0xFF6FB8E9)),
                    SizedBox(width: 8),
                    Text('Generate Flashcards', style: TextStyle(color: Color(0xFF6FB8E9))),
                  ],
                ),
              ),
            if (provider.hasActiveSession)
              const PopupMenuItem(
                value: 'end_session',
                child: Row(
                  children: [
                     Icon(Icons.stop, size: 20, color: Color(0xFFE57373)), // Softer red for dark theme
                     SizedBox(width: 8),
                     Text('End Session', style: TextStyle(color: Color(0xFFE57373))), // Softer red for dark theme
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildSessionProgressBar(EnhancedAITutorProvider provider) {
    final mastery = provider.subjectMastery;
    
    return SizedBox(
      height: 4,
      child: LinearProgressIndicator(
        value: mastery,
        backgroundColor: const Color(0xFF242628), // Dashboard header color
        valueColor: AlwaysStoppedAnimation<Color>(
          mastery > 0.7
              ? const Color(0xFF4CAF50) // Green for high mastery
              : mastery > 0.4
                  ? const Color(0xFFFF9800) // Orange for medium mastery
                  : const Color(0xFF6FB8E9), // Dashboard blue for low mastery
        ),
      ),
    );
  }

  Widget _buildSessionSetup(EnhancedAITutorProvider provider) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Welcome card
              _buildWelcomeCard(provider),
              const SizedBox(height: 24),
              
              // Subject selection
              _buildSubjectSelection(provider),
              const SizedBox(height: 16),
              
              // Difficulty selection
              _buildDifficultySelection(provider),
              const SizedBox(height: 16),
              
              // Learning goals
              _buildLearningGoals(provider),
              const SizedBox(height: 24),
              
              // Start button
              _buildStartButton(provider),
              const SizedBox(height: 16),
              
              // Recent badges
              if (provider.unlockedBadges.isNotEmpty)
                _buildRecentBadges(provider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(EnhancedAITutorProvider provider) {
    return Card(
      elevation: 8,
      color: const Color(0xFF242628), // Dashboard header color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF16181A), // Match main background color
              Color(0xFF242628), // Dashboard header color
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB8E9), // Dashboard blue accent
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.psychology,
                  size: 50,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to AI Tutor!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9), // Light text for dark theme
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your personalized learning companion',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF888888), // Muted text for dark theme
              ),
              textAlign: TextAlign.center,
            ),
            if (provider.currentStreak > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.1), // Dashboard blue accent
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Text(
                      '${provider.currentStreak} day streak!',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFD9D9D9), // Light text for dark theme
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectSelection(EnhancedAITutorProvider provider) {
    return Card(
      color: const Color(0xFF242628), // Dashboard header color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.school,
                  color: Color(0xFF6FB8E9), // Dashboard blue accent
                ),
                SizedBox(width: 8),
                Text(
                  'Choose Subject',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9D9D9), // Light text for dark theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _subjects.map((subject) {
                final isSelected = provider.currentSubject == subject;
                final mastery = provider.userProfile?.subjectMastery[subject] ?? 0;
                
                return ChoiceChip(
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject,
                        style: TextStyle(
                          color: isSelected ? Colors.white : const Color(0xFFD9D9D9),
                        ),
                      ),
                      if (mastery > 0)
                        Text(
                          '${(mastery * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 10,
                            color: isSelected ? Colors.white : const Color(0xFF888888),
                          ),
                        ),
                    ],
                  ),
                  selected: isSelected,
                  onSelected: (_) => provider.updateSubject(subject),
                  selectedColor: const Color(0xFF6FB8E9), // Dashboard blue accent
                  backgroundColor: const Color(0xFF16181A), // Match main background color
                  avatar: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelection(EnhancedAITutorProvider provider) {
    return Card(
      color: const Color(0xFF242628), // Dashboard header color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.speed,
                  color: Color(0xFF6FB8E9), // Dashboard blue accent
                ),
                const SizedBox(width: 8),
                const Text(
                  'Difficulty Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9D9D9), // Light text for dark theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: _difficulties.map((difficulty) {
                final isSelected = provider.currentDifficulty == difficulty;
                final icon = difficulty == 'Beginner'
                    ? Icons.looks_one
                    : difficulty == 'Intermediate'
                        ? Icons.looks_two
                        : Icons.looks_3;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ElevatedButton.icon(
                      onPressed: () => provider.updateDifficulty(difficulty),
                      icon: Icon(icon, size: 20),
                      label: Text(difficulty),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSelected
                            ? const Color(0xFF6FB8E9) // Dashboard blue accent
                            : const Color(0xFF16181A), // Match main background color
                        foregroundColor: isSelected
                            ? Colors.white
                            : const Color(0xFFD9D9D9), // Light text for dark theme
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningGoals(EnhancedAITutorProvider provider) {
    return Card(
      color: const Color(0xFF242628), // Dashboard header color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.flag,
                  color: Color(0xFF6FB8E9), // Dashboard blue accent
                ),
                const SizedBox(width: 8),
                const Text(
                  'Learning Goals (Optional)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9D9D9), // Light text for dark theme
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _learningGoalOptions.map((goal) {
                final isSelected = provider.learningGoals.contains(goal);
                
                return ChoiceChip(
                  label: Text(
                    goal,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFD9D9D9),
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (_) {
                    if (isSelected) {
                      provider.removeLearningGoal(goal);
                    } else {
                      provider.addLearningGoal(goal);
                    }
                  },
                  selectedColor: const Color(0xFF6FB8E9), // Dashboard blue accent
                  backgroundColor: const Color(0xFF16181A), // Match main background color
                  avatar: isSelected
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartButton(EnhancedAITutorProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: provider.isStartingSession ? null : () async {
          HapticFeedback.lightImpact();
          await provider.startAdaptiveSession();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6FB8E9), // Dashboard blue accent
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 8,
          shadowColor: const Color(0xFF6FB8E9).withValues(alpha: 0.5), // Dashboard blue shadow
        ),
        child: provider.isStartingSession
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Starting Session...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rocket_launch, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Start Learning Session',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRecentBadges(EnhancedAITutorProvider provider) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('🎖️', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(
                  'Recent Achievements',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(5, provider.unlockedBadges.length),
                itemBuilder: (context, index) {
                  final badge = provider.unlockedBadges[
                      provider.unlockedBadges.length - 1 - index];
                  final details = provider.getBadgeDetails(badge);
                  
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withValues(alpha: 0.2),
                          Colors.orange.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          details['name'] ?? badge,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatView(EnhancedAITutorProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    
    if (provider.messages.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: provider.messages.length + (provider.isGenerating ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == provider.messages.length && provider.isGenerating) {
          return _buildTypingIndicator();
        }
        
        final message = provider.messages[index];
        return _buildMessageBubble(message, provider);
      },
    );
  }

  Widget _buildMessageBubble(
    ChatMessage message,
    EnhancedAITutorProvider provider,
  ) {
    final isUser = message.type == MessageType.user;
    final isError = message.type == MessageType.error;
    final isQuiz = message.metadata?['type'] == 'quiz';
    final isProgress = message.metadata?['type'] == 'progress';
    final isSessionSummary = message.metadata?['type'] == 'session_summary';
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(
        bottom: 12,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.psychology,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AI Tutor',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              padding: EdgeInsets.all(isProgress || isQuiz || isSessionSummary ? 16 : 14),
              decoration: BoxDecoration(
                color: isError
                    ? Colors.red.shade100
                    : isUser
                        ? Theme.of(context).primaryColor
                        : isProgress || isSessionSummary
                            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                            : isQuiz
                                ? Colors.purple.withValues(alpha: 0.1)
                                : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isUser
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: (isProgress || isQuiz || isSessionSummary) && !isUser
                    ? Border.all(
                        color: isQuiz
                            ? Colors.purple.withValues(alpha: 0.3)
                            : Theme.of(context).primaryColor.withValues(alpha: 0.3),
                        width: 1,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isQuiz)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '📝 Quiz',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      color: isError
                          ? Colors.red.shade800
                          : isUser
                              ? Colors.white
                              : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:'
                        '${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isError
                              ? Colors.red.shade600
                              : isUser
                                  ? Colors.white70
                                  : Colors.grey.shade600,
                        ),
                      ),
                      if (message.metadata?['hintLevel'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                size: 12,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                'Hint ${message.metadata!['hintLevel']}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (message.metadata?['pointsEarned'] != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '+${message.metadata!['pointsEarned']} pts',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12, bottom: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.psychology,
                size: 16,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                  bottomLeft: Radius.circular(4),
                  bottomRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI tutor is thinking...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
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

  Widget _buildQuickReplies(
    EnhancedAITutorProvider provider,
    AppState appState,
  ) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: provider.quickReplies.length,
        itemBuilder: (context, index) {
          final reply = provider.quickReplies[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  provider.sendMessage(reply, user: appState.currentUser);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15), // More visible!
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.5), // More visible border!
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      reply,
                      style: const TextStyle(
                        color: Colors.blue, // Bright blue text!
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput(
    EnhancedAITutorProvider provider,
    AppState appState,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(
                  Icons.attach_file,
                  color: Colors.blue, // Bright blue for visibility!
                  size: 26,
                ),
                onPressed: provider.isGenerating ? null : _handleAttachment,
                tooltip: 'Attach file',
              ),
              
              // Message field
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _messageFocusNode,
                    enabled: !provider.isGenerating,
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black, // Fix: Make text visible!
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (text) {
                      _typingTimer?.cancel();
                      if (text.isNotEmpty && !_isTyping) {
                        setState(() => _isTyping = true);
                      }
                      _typingTimer = Timer(const Duration(seconds: 1), () {
                        if (mounted && _isTyping) {
                          setState(() => _isTyping = false);
                        }
                      });
                    },
                    onSubmitted: (_) => _sendMessage(provider, appState),
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Voice input button
              IconButton(
                icon: const Icon(
                  Icons.mic,
                  color: Colors.blue, // Bright blue for visibility!
                  size: 26,
                ),
                onPressed: provider.isGenerating ? null : _handleVoiceInput,
                tooltip: 'Voice input',
              ),
              
              // Send button
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: provider.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                        ),
                  onPressed: provider.isGenerating
                      ? null
                      : () => _sendMessage(provider, appState),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedScale(
      scale: _showScrollToBottom ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _scrollToBottom,
            borderRadius: BorderRadius.circular(24),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadgesOverlay(EnhancedAITutorProvider provider) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: provider.showBadges ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🏆 Your Achievements',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.toggleBadgesDisplay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 1,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: provider.unlockedBadges.length,
                      itemBuilder: (context, index) {
                        final badge = provider.unlockedBadges[index];
                        final details = provider.getBadgeDetails(badge);
                        
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.amber.shade200,
                                Colors.orange.shade300,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                details['name']!.split(' ')[0],
                                style: const TextStyle(
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                details['name']!.substring(2),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressOverlay(EnhancedAITutorProvider provider) {
    final analytics = provider.getUserAnalytics();
    
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      top: provider.showProgress ? 0 : -MediaQuery.of(context).size.height,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '📊 Learning Progress',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: provider.toggleProgressDisplay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        '🔥',
                        analytics['currentStreak']?.toString() ?? '0',
                        'Day Streak',
                      ),
                      _buildStatCard(
                        '🏆',
                        analytics['totalPoints']?.toString() ?? '0',
                        'Total Points',
                      ),
                      _buildStatCard(
                        '🎖️',
                        analytics['badgesEarned']?.toString() ?? '0',
                        'Badges',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Subject mastery
                  Text(
                    'Subject Mastery',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  
                  if (analytics['subjectMastery'] != null)
                    ...Map<String, dynamic>.from(analytics['subjectMastery'])
                        .entries
                        .map((entry) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(entry.key),
                                      Text(
                                        '${(entry.value * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: entry.value,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      entry.value > 0.7
                                          ? Colors.green
                                          : entry.value > 0.4
                                              ? Colors.orange
                                              : Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(
    EnhancedAITutorProvider provider,
    AppState appState,
  ) async {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      HapticFeedback.selectionClick();
      _messageController.clear();
      await provider.sendMessage(message, user: appState.currentUser);
      _scrollToBottom();
    }
  }

  void _handleAttachment() {
    // Implement file attachment functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('File attachment coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleVoiceInput() {
    // Implement voice input functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice input coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _handleMenuAction(String action, EnhancedAITutorProvider provider) {
    switch (action) {
      case 'progress':
        provider.toggleProgressDisplay();
        break;
      case 'badges':
        provider.toggleBadgesDisplay();
        break;
      case 'generate_flashcards':
        _generateFlashcardsFromAI(provider);
        break;
      case 'end_session':
        _showEndSessionDialog(provider);
        break;
    }
  }

  void _showEndSessionDialog(EnhancedAITutorProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Learning Session?'),
        content: const Text(
          'Are you sure you want to end this session? '
          'Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.endSession();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('End Session'),
          ),
        ],
      ),
    );
  }
}
