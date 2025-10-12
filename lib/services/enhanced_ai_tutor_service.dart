// enhanced_ai_tutor_service.dart

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../models/tutor_session.dart';
import '../models/knowledge_node.dart';
import '../models/learning_profile.dart';
import '../models/quiz_question.dart';
import '../models/user.dart' as app_user;
import 'ai_service.dart';
import 'firestore_service.dart';

/// Enhanced AI Tutor Service with adaptive learning
class EnhancedAITutorService {
  final AIService _aiService;
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Knowledge Graph
  final Map<String, KnowledgeNode> _knowledgeGraph = {};
  final Map<String, List<QuizQuestion>> _conceptQuizzes = {};

  // User Learning Profiles
  final Map<String, LearningProfile> _learningProfiles = {};

  // Active Sessions
  final Map<String, TutorSession> _activeSessions = {};
  final Map<String, List<ChatMessage>> _sessionMessages = {};
  final Map<String, Map<String, dynamic>> _sessionContext = {};

  // Gamification
  final Map<String, int> _badgeThresholds = {
    'first_session': 1,
    'streak_3': 3,
    'streak_7': 7,
    'points_100': 100,
    'points_500': 500,
    'concepts_10': 10,
    'perfect_quiz': 1,
  };

  // Advanced Conversation Memory & Intelligence
  final Map<String, List<Map<String, dynamic>>> _conversationMemory = {};
  final Map<String, Map<String, dynamic>> _userPersonality = {};
  final Map<String, Map<String, dynamic>> _learningPatterns = {};
  final Map<String, DateTime> _lastInteractionTime = {};

  // Intelligent Response Cache
  final Map<String, String> _responseCache = {};
  final Map<String, List<String>> _topicFollowUps = {};

  // Advanced Analytics
  final Map<String, Map<String, dynamic>> _userBehaviorAnalytics = {};
  final Map<String, List<double>> _difficultyAdaptation = {};

  EnhancedAITutorService(this._aiService) {
    _initializeKnowledgeGraph();
    _loadUserProfiles();
  }

  /// Initialize the knowledge graph with sample concepts
  void _initializeKnowledgeGraph() {
    // Mathematics concepts
    _knowledgeGraph['math_algebra_basics'] = KnowledgeNode(
      id: 'math_algebra_basics',
      name: 'Algebra Basics',
      subject: 'Mathematics',
      difficulty: 3,
      prerequisites: [],
      relatedConcepts: ['math_linear_equations', 'math_quadratic_equations'],
    );

    _knowledgeGraph['math_linear_equations'] = KnowledgeNode(
      id: 'math_linear_equations',
      name: 'Linear Equations',
      subject: 'Mathematics',
      difficulty: 4,
      prerequisites: ['math_algebra_basics'],
      relatedConcepts: ['math_quadratic_equations', 'math_systems_equations'],
    );

    _knowledgeGraph['math_quadratic_equations'] = KnowledgeNode(
      id: 'math_quadratic_equations',
      name: 'Quadratic Equations',
      subject: 'Mathematics',
      difficulty: 5,
      prerequisites: ['math_algebra_basics', 'math_linear_equations'],
      relatedConcepts: ['math_polynomial_functions'],
    );

    // Science concepts
    _knowledgeGraph['sci_physics_motion'] = KnowledgeNode(
      id: 'sci_physics_motion',
      name: 'Motion and Forces',
      subject: 'Science',
      difficulty: 4,
      prerequisites: [],
      relatedConcepts: ['sci_physics_energy', 'sci_physics_momentum'],
    );

    _knowledgeGraph['sci_chemistry_atoms'] = KnowledgeNode(
      id: 'sci_chemistry_atoms',
      name: 'Atomic Structure',
      subject: 'Science',
      difficulty: 5,
      prerequisites: [],
      relatedConcepts: ['sci_chemistry_bonding', 'sci_chemistry_periodic'],
    );

    // Initialize quiz questions for each concept
    _initializeQuizzes();
  }

  /// Initialize quiz questions for concepts
  void _initializeQuizzes() {
    _conceptQuizzes['math_algebra_basics'] = [
      QuizQuestion(
        id: 'q1',
        question: 'What is the value of x in: 2x + 5 = 15?',
        options: ['x = 5', 'x = 10', 'x = 7.5', 'x = 20'],
        correctIndex: 0,
        explanation:
            'Subtract 5 from both sides: 2x = 10. Then divide by 2: x = 5',
        conceptId: 'math_algebra_basics',
        difficulty: 3,
      ),
      QuizQuestion(
        id: 'q2',
        question: 'Simplify: 3x + 2x - x',
        options: ['4x', '5x', '3x', '6x'],
        correctIndex: 0,
        explanation: '3x + 2x - x = 5x - x = 4x',
        conceptId: 'math_algebra_basics',
        difficulty: 2,
      ),
    ];

    _conceptQuizzes['math_quadratic_equations'] = [
      QuizQuestion(
        id: 'q3',
        question: 'What is the discriminant formula for ax² + bx + c = 0?',
        options: ['b² - 4ac', 'b² + 4ac', '2a', '-b/2a'],
        correctIndex: 0,
        explanation:
            'The discriminant is b² - 4ac, which determines the nature of roots',
        conceptId: 'math_quadratic_equations',
        difficulty: 5,
      ),
    ];
  }

  /// Load user learning profiles from Firestore
  Future<void> _loadUserProfiles() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc =
            await _firestore.collection('learningProfiles').doc(user.uid).get();

        if (doc.exists) {
          _learningProfiles[user.uid] = LearningProfile.fromJson(doc.data()!);
        } else {
          _learningProfiles[user.uid] = LearningProfile(userId: user.uid);
        }
      }
    } catch (e) {
      debugPrint('Error loading learning profiles: $e');
    }
  }

  // ==================== PUBLIC INTERFACE METHODS ====================

  /// Public getter for Firebase Auth instance
  FirebaseAuth get auth => _auth;

  /// Public method to load user profiles
  Future<void> loadUserProfiles() => _loadUserProfiles();

  /// Calculate session metrics for a given session
  Map<String, dynamic> calculateSessionMetrics(String sessionId) {
    final messages = _sessionMessages[sessionId] ?? [];
    final userMessages =
        messages.where((m) => m.type == MessageType.user).length;
    final assistantMessages =
        messages.where((m) => m.type == MessageType.assistant).length;

    return {
      'totalMessages': messages.length,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'duration': messages.isNotEmpty
          ? messages.last.timestamp
              .difference(messages.first.timestamp)
              .inMinutes
          : 0,
    };
  }

  /// Get or create learning profile for user
  LearningProfile _getUserProfile(String userId) {
    if (!_learningProfiles.containsKey(userId)) {
      _learningProfiles[userId] = LearningProfile(userId: userId);
    }
    return _learningProfiles[userId]!;
  }

  /// Generate adaptive AI tutor response with full context
  Future<ChatMessage> generateAdaptiveTutorResponse({
    required String userMessage,
    required String sessionId,
    String? subject,
    String? difficulty,
    String? currentConceptId,
    List<ChatMessage>? conversationHistory,
    app_user.User? user,
  }) async {
    try {
      final userId = user?.id ?? _auth.currentUser?.uid ?? 'anonymous';
      final profile = _getUserProfile(userId);
      final context = _sessionContext[sessionId] ?? {};

      // Analyze user message with advanced intelligence
      final analysis =
          await _analyzeAdvancedMessageIntent(userMessage, context, userId);
      final intent = analysis['intent'] as String;

      // Generate appropriate response based on intent
      String response;
      Map<String, dynamic> metadata = {
        'sessionId': sessionId,
        'subject': subject,
        'difficulty': difficulty,
        'intent': intent,
        'emotion': analysis['emotion'],
        'complexity': analysis['complexity'],
        'learningStyle': analysis['learningStyle'],
      };

      switch (intent) {
        case 'question':
        case 'deep_explanation':
        case 'quick_clarification':
        case 'problem_solving':
        case 'conceptual_understanding':
        case 'application_request':
        case 'validation_seeking':
          response = await _handleAdvancedQuestion(
            userMessage,
            subject ?? 'General',
            profile,
            conversationHistory ?? [],
            userId,
          );
          // Update context with new topic discussed
          _updateSessionContext(
            sessionId,
            newTopic: subject ?? 'General',
            progressIncrement: 5.0,
          );
          break;

        case 'confusion':
          response = await _handleConfusion(
            userMessage,
            currentConceptId,
            profile,
            conversationHistory ?? [],
          );
          metadata['helpType'] = 'clarification';
          // Update context with adaptive adjustment
          _updateSessionContext(sessionId, adaptiveAdjustment: true);
          break;

        case 'quiz_request':
          final quiz = await _generateQuiz(
            subject ?? 'General',
            profile,
            difficulty ?? 'Intermediate',
          );
          response = quiz;
          metadata['type'] = 'quiz';
          // Update context with concept exploration
          _updateSessionContext(
            sessionId,
            newConcept: subject ?? 'General',
            progressIncrement: 10.0,
          );
          break;

        case 'hint_request':
          response = await _generateHint(
            context['lastQuestion'] ?? userMessage,
            context['hintLevel'] ?? 0,
          );
          context['hintLevel'] = (context['hintLevel'] ?? 0) + 1;
          metadata['hintLevel'] = context['hintLevel'];
          // Update context for adaptive adjustment
          _updateSessionContext(sessionId, adaptiveAdjustment: true);
          break;

        case 'progress_check':
          response = _generateProgressReport(profile, subject ?? 'General');
          metadata['type'] = 'progress';
          break;

        default:
          response = await _generateGeneralResponse(
            userMessage,
            subject ?? 'General',
            profile,
            conversationHistory ?? [],
          );
      }

      // Award points for engagement
      await _awardPoints(userId, 5, 'message_sent');

      // Update session context
      _sessionContext[sessionId] = {
        ...context,
        'lastMessage': userMessage,
        'lastResponse': response,
        'lastIntent': intent,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Create and save message
      final chatMessage = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        content: response,
        type: MessageType.assistant,
        format: MessageFormat.structured,
        userId: userId,
        metadata: metadata,
      );

      _sessionMessages[sessionId] ??= [];
      _sessionMessages[sessionId]!.add(chatMessage);

      // 🔥 ADD: Track message ID in session
      final session = _activeSessions[sessionId];
      if (session != null) {
        session.messageIds.add(chatMessage.id);
        // 🔥 FIX: Update session in Firestore with new messageIds
        unawaited(_saveTutorSession(session));
      }

      // Save to Firestore
      _saveChatMessage(chatMessage);
      _saveUserProfile(profile);

      return chatMessage;
    } catch (e) {
      debugPrint('Error generating adaptive response: $e');
      return _createErrorMessage();
    }
  }

  /// Advanced message intent analysis with emotion detection and learning style recognition
  Future<Map<String, dynamic>> _analyzeAdvancedMessageIntent(
      String message, Map<String, dynamic> context, String userId) async {
    final analysis = {
      'intent': 'general',
      'confidence': 0.0,
      'emotion': 'neutral',
      'complexity': 'medium',
      'urgency': 'normal',
      'learningStyle': 'mixed',
      'subTopics': <String>[],
      'followUpSuggestions': <String>[],
    };

    final lowerMessage = message.toLowerCase().trim();

    // Advanced Intent Classification
    final intentPatterns = {
      'deep_explanation': {
        'patterns': [
          r'explain (in detail|thoroughly|completely)',
          r'how does .* work exactly',
          r'break down',
          r'walk me through'
        ],
        'confidence': 0.9,
      },
      'quick_clarification': {
        'patterns': [
          r'what (is|does|means?)',
          r'define',
          r'meaning of',
          r'quickly explain'
        ],
        'confidence': 0.85,
      },
      'problem_solving': {
        'patterns': [
          r'how (do|can) i (solve|fix|calculate)',
          r'step by step',
          r'show me how'
        ],
        'confidence': 0.9,
      },
      'conceptual_understanding': {
        'patterns': [
          r'why (is|does|do)',
          r'what causes',
          r'relationship between',
          r'difference between'
        ],
        'confidence': 0.8,
      },
      'application_request': {
        'patterns': [
          r'example of',
          r'real world',
          r'practical use',
          r'applied to'
        ],
        'confidence': 0.85,
      },
      'confusion_signal': {
        'patterns': [
          r"don't understand",
          r'confused',
          r'lost',
          r'unclear',
          r'what do you mean'
        ],
        'confidence': 0.95,
      },
      'confusion': {
        'patterns': [
          r"don't understand",
          r'confused',
          r'explain',
          r'what do you mean'
        ],
        'confidence': 0.9,
      },
      'validation_seeking': {
        'patterns': [
          r'is this (right|correct)',
          r'am i (right|correct)',
          r'does this make sense',
          r'true or false'
        ],
        'confidence': 0.9,
      },
      'progress_inquiry': {
        'patterns': [
          r'how am i doing',
          r'my progress',
          r'performance',
          r'improvement'
        ],
        'confidence': 0.9,
      },
      'progress_check': {
        'patterns': [r'progress', r'score', r'how am i doing'],
        'confidence': 0.85,
      },
      'quiz_request': {
        'patterns': [r'quiz', r'test', r'question'],
        'confidence': 0.8,
      },
      'hint_request': {
        'patterns': [r'hint', r'help', r'stuck'],
        'confidence': 0.8,
      },
    };

    // Determine primary intent
    double maxConfidence = 0.0;
    String primaryIntent = 'general';

    for (final intentType in intentPatterns.keys) {
      final patterns = intentPatterns[intentType]!['patterns'] as List<String>;
      final confidence = intentPatterns[intentType]!['confidence'] as double;

      for (final pattern in patterns) {
        if (RegExp(pattern, caseSensitive: false).hasMatch(lowerMessage)) {
          if (confidence > maxConfidence) {
            maxConfidence = confidence;
            primaryIntent = intentType;
          }
        }
      }
    }

    analysis['intent'] = primaryIntent;
    analysis['confidence'] = maxConfidence;

    // Emotion Detection
    final emotionKeywords = {
      'frustrated': [
        'frustrated',
        'stuck',
        'hard',
        'difficult',
        "can't",
        'impossible',
        'hate'
      ],
      'excited': [
        'excited',
        'awesome',
        'amazing',
        'love',
        'great',
        'fantastic',
        'cool'
      ],
      'curious': [
        'interesting',
        'wonder',
        'curious',
        'want to learn',
        'tell me more'
      ],
      'confident': ['easy', 'got it', 'understand', 'makes sense', 'clear'],
      'uncertain': ['maybe', 'think', 'guess', 'not sure', 'probably'],
    };

    for (final emotion in emotionKeywords.keys) {
      if (emotionKeywords[emotion]!
          .any((keyword) => lowerMessage.contains(keyword))) {
        analysis['emotion'] = emotion;
        break;
      }
    }

    // Complexity Assessment
    final complexityIndicators = {
      'simple': message.length < 20 && !message.contains('?'),
      'medium': message.length < 100 && message.split(' ').length < 15,
      'complex': message.length > 100 || message.split('?').length > 2,
    };

    for (final complexity in complexityIndicators.keys) {
      if (complexityIndicators[complexity]!) {
        analysis['complexity'] = complexity;
        break;
      }
    }

    // Learning Style Detection
    final learningStyleCues = {
      'visual': ['show', 'see', 'picture', 'diagram', 'chart', 'graph'],
      'auditory': ['explain', 'tell', 'describe', 'sound', 'hear'],
      'kinesthetic': ['practice', 'try', 'do', 'hands-on', 'example'],
      'analytical': ['why', 'how', 'because', 'reason', 'logic', 'proof'],
    };

    final detectedStyles = <String>[];
    for (final style in learningStyleCues.keys) {
      if (learningStyleCues[style]!.any((cue) => lowerMessage.contains(cue))) {
        detectedStyles.add(style);
      }
    }
    analysis['learningStyle'] =
        detectedStyles.isNotEmpty ? detectedStyles.first : 'mixed';

    // Store conversation memory
    _conversationMemory[userId] ??= [];
    _conversationMemory[userId]!.add({
      'message': message,
      'analysis': analysis,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Keep only last 20 interactions
    if (_conversationMemory[userId]!.length > 20) {
      _conversationMemory[userId]!.removeAt(0);
    }

    // Track interaction timing for engagement analysis
    _lastInteractionTime[userId] = DateTime.now();

    return analysis;
  }

  /// Build personalized response configuration based on user patterns
  Map<String, dynamic> _buildPersonalizedResponse(
      String message, String userId, Map<String, dynamic> analysis) {
    // Get user's learning patterns
    final patterns = _learningPatterns[userId] ?? {};
    final personality = _userPersonality[userId] ?? {};
    final memory = _conversationMemory[userId] ?? [];

    // Analyze user's preferred response style from history
    final recentInteractions = memory.take(5).toList();
    final preferredComplexity =
        _determinePreferredComplexity(recentInteractions);
    final emotionalState = analysis['emotion'] as String;
    final learningStyle = analysis['learningStyle'] as String;

    // Dynamic response configuration
    final responseConfig = {
      'tone': _determineTone(emotionalState, personality),
      'complexity': preferredComplexity,
      'examples': _shouldIncludeExamples(learningStyle, analysis),
      'analogies': _shouldUseAnalogies(patterns),
      'encouragement': _getEncouragementLevel(emotionalState),
      'structure': _determineResponseStructure(analysis),
      'followUps': _generateSmartFollowUps(message, analysis, userId: userId),
    };

    // Apply difficulty adaptation based on user performance history
    return _applyDifficultyAdaptation(userId, responseConfig);
  }

  String _determineTone(String emotion, Map<String, dynamic> personality) {
    switch (emotion) {
      case 'frustrated':
        return 'patient and encouraging';
      case 'excited':
        return 'enthusiastic and supportive';
      case 'uncertain':
        return 'reassuring and clear';
      case 'confident':
        return 'collaborative and challenging';
      default:
        return 'warm and professional';
    }
  }

  String _determinePreferredComplexity(
      List<Map<String, dynamic>> interactions) {
    if (interactions.isEmpty) return 'medium';

    // Analyze user's engagement with different complexity levels
    final complexityEngagement = <String, int>{};
    for (final interaction in interactions) {
      final analysis = interaction['analysis'] as Map<String, dynamic>;
      final complexity = analysis['complexity'] as String;
      complexityEngagement[complexity] =
          (complexityEngagement[complexity] ?? 0) + 1;
    }

    return complexityEngagement.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  bool _shouldIncludeExamples(
      String learningStyle, Map<String, dynamic> analysis) {
    return learningStyle == 'kinesthetic' ||
        learningStyle == 'visual' ||
        analysis['intent'] == 'application_request';
  }

  bool _shouldUseAnalogies(Map<String, dynamic> patterns) {
    return patterns['responds_well_to_analogies'] == true ||
        patterns['conceptual_learner'] == true;
  }

  String _getEncouragementLevel(String emotion) {
    switch (emotion) {
      case 'frustrated':
        return 'high';
      case 'uncertain':
        return 'medium';
      case 'confident':
        return 'low';
      default:
        return 'medium';
    }
  }

  String _determineResponseStructure(Map<String, dynamic> analysis) {
    final intent = analysis['intent'] as String;
    switch (intent) {
      case 'deep_explanation':
        return 'structured_detailed';
      case 'quick_clarification':
        return 'concise_direct';
      case 'problem_solving':
        return 'step_by_step';
      case 'confusion_signal':
        return 'simplified_breakdown';
      default:
        return 'balanced';
    }
  }

  List<String> _generateSmartFollowUps(
      String message, Map<String, dynamic> analysis,
      {String? userId}) {
    final intent = analysis['intent'] as String;
    final followUps = <String>[];

    // Get topic-based follow-ups if userId is provided
    if (userId != null) {
      final topicFollowUps = _generateTopicBasedFollowUps(message, userId);
      followUps.addAll(topicFollowUps);
    }

    // Add intent-based follow-ups
    switch (intent) {
      case 'quick_clarification':
        followUps.addAll([
          'Would you like a deeper explanation?',
          'Want to see how this applies in practice?',
          'Should we try a related example?'
        ]);
        break;
      case 'deep_explanation':
        followUps.addAll([
          'Would you like to test your understanding with a quiz?',
          'Want to see how this connects to other concepts?',
          'Ready to try a practice problem?'
        ]);
        break;
      case 'problem_solving':
        followUps.addAll([
          'Want to try a similar problem?',
          'Should we explore a harder variation?',
          'Would you like to see alternative methods?'
        ]);
        break;
      case 'confusion_signal':
        followUps.addAll([
          'Would a different explanation help?',
          'Should we try a simpler example?',
          'Want me to break this down further?'
        ]);
        break;
    }

    return followUps.take(3).toList();
  }

  /// Generate topic-based follow-up questions
  List<String> _generateTopicBasedFollowUps(String message, String userId) {
    final followUps = <String>[];

    // Extract key topics from current message
    final currentTopics = _extractTopicsFromMessage(message);

    // Get stored follow-ups for these topics
    for (final topic in currentTopics) {
      final topicFollowUps = _topicFollowUps[topic] ?? [];
      followUps.addAll(topicFollowUps.take(2));
    }

    // Update topic follow-ups based on conversation patterns
    _updateTopicFollowUps(currentTopics, userId);

    return followUps.take(2).toList();
  }

  /// Extract key topics from a message
  List<String> _extractTopicsFromMessage(String message) {
    final topics = <String>[];
    final lowerMessage = message.toLowerCase();

    // Common academic topics
    final topicKeywords = {
      'mathematics': [
        'math',
        'algebra',
        'geometry',
        'calculus',
        'equation',
        'formula'
      ],
      'science': [
        'biology',
        'chemistry',
        'physics',
        'experiment',
        'hypothesis'
      ],
      'history': ['history', 'historical', 'war', 'civilization', 'empire'],
      'literature': ['literature', 'poetry', 'novel', 'author', 'character'],
      'programming': [
        'code',
        'programming',
        'algorithm',
        'function',
        'variable'
      ],
    };

    for (final topic in topicKeywords.keys) {
      if (topicKeywords[topic]!
          .any((keyword) => lowerMessage.contains(keyword))) {
        topics.add(topic);
      }
    }

    return topics;
  }

  /// Update topic follow-ups based on user patterns
  void _updateTopicFollowUps(List<String> topics, String userId) {
    final userPatterns = _learningPatterns[userId] ?? {};
    final preferredIntents =
        userPatterns['preferred_intents'] as Map<String, int>? ?? {};

    for (final topic in topics) {
      _topicFollowUps[topic] ??= [];

      // Add follow-ups based on user's preferred learning style
      if (preferredIntents['deep_explanation'] != null &&
          preferredIntents['deep_explanation']! > 2) {
        _topicFollowUps[topic]!.addAll([
          'Want to explore the deeper principles behind $topic?',
          'Should we examine the theoretical foundations of $topic?'
        ]);
      }

      if (preferredIntents['application_request'] != null &&
          preferredIntents['application_request']! > 2) {
        _topicFollowUps[topic]!.addAll([
          'How might you apply $topic in real-world scenarios?',
          'Want to see practical examples of $topic?'
        ]);
      }

      if (preferredIntents['problem_solving'] != null &&
          preferredIntents['problem_solving']! > 2) {
        _topicFollowUps[topic]!.addAll([
          'Ready for some $topic practice problems?',
          'Should we work through a challenging $topic example?'
        ]);
      }

      // Limit follow-ups per topic to prevent bloat
      if (_topicFollowUps[topic]!.length > 10) {
        _topicFollowUps[topic] = _topicFollowUps[topic]!.take(10).toList();
      }
    }
  }

  /// Generate sophisticated Socratic response using Bloom's taxonomy
  Future<String> _generateSocraticResponse(String message, String subject,
      Map<String, dynamic> analysis, String userId) async {
    final userLevel = _determineBloomLevel(message, analysis);
    final targetLevel = _getNextBloomLevel(userLevel);

    final socraticPrompts = {
      'knowledge': [
        'What do you already know about this topic?',
        'Can you recall any similar concepts?',
        'What facts can you tell me about this?'
      ],
      'comprehension': [
        'Can you explain this in your own words?',
        'What does this mean to you?',
        'How would you summarize this?'
      ],
      'application': [
        'Where might you use this in real life?',
        'Can you think of an example?',
        'How would you apply this concept?'
      ],
      'analysis': [
        'What patterns do you notice?',
        'How do these parts relate to each other?',
        'What are the key components here?'
      ],
      'synthesis': [
        'How could you combine this with other ideas?',
        'What would happen if we changed this?',
        'Can you create a new example?'
      ],
      'evaluation': [
        'What do you think about this approach?',
        'How would you judge the effectiveness?',
        'What criteria would you use to evaluate this?'
      ]
    };

    final questions =
        socraticPrompts[targetLevel] ?? socraticPrompts['comprehension']!;
    final selectedQuestion = questions[math.Random().nextInt(questions.length)];

    return selectedQuestion;
  }

  String _determineBloomLevel(String message, Map<String, dynamic> analysis) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains(RegExp(r'what is|define|list|name'))) {
      return 'knowledge';
    }
    if (lowerMessage.contains(RegExp(r'explain|describe|summarize'))) {
      return 'comprehension';
    }
    if (lowerMessage.contains(RegExp(r'apply|use|solve|calculate'))) {
      return 'application';
    }
    if (lowerMessage.contains(RegExp(r'analyze|compare|contrast|why'))) {
      return 'analysis';
    }
    if (lowerMessage.contains(RegExp(r'create|design|combine|develop'))) {
      return 'synthesis';
    }
    if (lowerMessage.contains(RegExp(r'evaluate|judge|critique|assess'))) {
      return 'evaluation';
    }

    return 'comprehension';
  }

  String _getNextBloomLevel(String currentLevel) {
    final levels = [
      'knowledge',
      'comprehension',
      'application',
      'analysis',
      'synthesis',
      'evaluation'
    ];
    final currentIndex = levels.indexOf(currentLevel);
    return currentIndex < levels.length - 1
        ? levels[currentIndex + 1]
        : currentLevel;
  }

  bool _shouldUseSocraticMethod(
      Map<String, dynamic> analysis, LearningProfile profile) {
    final intent = analysis['intent'] as String;
    final complexity = analysis['complexity'] as String;

    // Use Socratic method for deeper learning
    return intent == 'conceptual_understanding' ||
        intent == 'deep_explanation' ||
        (complexity == 'complex' &&
            profile.preferences['teaching_style'] != 'direct');
  }

  Future<String> _handleAdvancedQuestion(
    String question,
    String subject,
    LearningProfile profile,
    List<ChatMessage> history,
    String userId,
  ) async {
    // Analyze the question comprehensively
    final analysis = await _analyzeAdvancedMessageIntent(question, {}, userId);
    final responseConfig =
        _buildPersonalizedResponse(question, userId, analysis);

    // Determine if we should use Socratic method
    final useSocratic = _shouldUseSocraticMethod(analysis, profile);

    if (useSocratic && analysis['intent'] != 'quick_clarification') {
      final socraticQuestion =
          await _generateSocraticResponse(question, subject, analysis, userId);
      return socraticQuestion;
    }

    // Build sophisticated prompt
    final prompt = _buildAdvancedPrompt(
      question: question,
      subject: subject,
      profile: profile,
      analysis: analysis,
      responseConfig: responseConfig,
      history: history,
    );

    // Check response cache first
    final cacheKey = _generateCacheKey(question, subject, analysis);
    final cachedResponse = _responseCache[cacheKey];

    String response;
    if (cachedResponse != null && _shouldUseCachedResponse(analysis, profile)) {
      response = cachedResponse;
    } else {
      response = await _aiService.callGoogleAIWithRetry(prompt, 0);

      // Cache response for frequently asked questions
      if (_shouldCacheResponse(analysis, response)) {
        _responseCache[cacheKey] = response;
        _pruneResponseCache();
      }
    }

    // Learn from this interaction
    _updateLearningPatterns(userId, analysis, response);

    return response;
  }

  String _buildAdvancedPrompt({
    required String question,
    required String subject,
    required LearningProfile profile,
    required Map<String, dynamic> analysis,
    required Map<String, dynamic> responseConfig,
    required List<ChatMessage> history,
  }) {
    final intent = analysis['intent'] as String;
    final emotion = analysis['emotion'] as String;
    final tone = responseConfig['tone'] as String;
    final complexity = responseConfig['complexity'] as String;
    final includeExamples = responseConfig['examples'] as bool;

    final basePrompt = '''
You are an expert AI tutor specializing in $subject with a $tone approach.

STUDENT CONTEXT:
- Current emotional state: $emotion
- Preferred complexity: $complexity
- Learning style: ${analysis['learningStyle']}
- Subject mastery: ${(profile.subjectMastery[subject] ?? 0.5 * 100).toStringAsFixed(0)}%
- Query intent: $intent

CONVERSATION HISTORY:
${history.take(3).map((m) => '${m.type == MessageType.user ? "Student" : "AI"}: ${m.content.trim()}').join('\n')}

CURRENT QUESTION: "$question"

RESPONSE REQUIREMENTS:
''';

    switch (intent) {
      case 'quick_clarification':
        return '''$basePrompt
- Provide a direct, concise answer (1-2 sentences max)
- Use simple, clear language
- End with a brief follow-up question if appropriate
''';

      case 'deep_explanation':
        return '''$basePrompt
- Provide comprehensive explanation with clear structure
- Use headings, bullet points, or numbered steps
- Include practical applications and connections
- ${includeExamples ? 'Provide 2-3 concrete examples' : 'Focus on conceptual understanding'}
- End with thought-provoking follow-up questions
''';

      case 'confusion_signal':
        return '''$basePrompt
- Acknowledge their confusion with empathy
- Provide alternative explanation using different approach
- Break down complex concepts into digestible parts
- Use simple analogies and relatable examples
- Check understanding before moving forward
''';

      case 'problem_solving':
        return '''$basePrompt
- Provide step-by-step solution methodology
- Explain the reasoning behind each step
- Highlight common pitfalls to avoid
- Suggest variations or alternative approaches
- Encourage practice with similar problems
''';

      default:
        return '''$basePrompt
- Provide helpful, educational response matching student's needs
- Adapt tone and complexity to student's current state
- Include encouraging elements appropriate to their emotion
- End with engaging follow-up to continue learning
''';
    }
  }

  void _updateLearningPatterns(
      String userId, Map<String, dynamic> analysis, String response) {
    _learningPatterns[userId] ??= {};
    final patterns = _learningPatterns[userId]!;

    // Track what types of responses the user engages well with
    final intent = analysis['intent'] as String;
    patterns['preferred_intents'] ??= <String, int>{};
    patterns['preferred_intents'][intent] =
        (patterns['preferred_intents'][intent] ?? 0) + 1;

    // Track response characteristics
    if (response.length < 100) {
      patterns['prefers_concise'] = (patterns['prefers_concise'] ?? 0) + 1;
    } else {
      patterns['prefers_detailed'] = (patterns['prefers_detailed'] ?? 0) + 1;
    }

    // Update user personality profile
    _userPersonality[userId] ??= {};
    final personality = _userPersonality[userId]!;

    final emotion = analysis['emotion'] as String;
    personality['dominant_emotions'] ??= <String, int>{};
    personality['dominant_emotions'][emotion] =
        (personality['dominant_emotions'][emotion] ?? 0) + 1;

    // Update behavior analytics
    _updateBehaviorAnalytics(userId, analysis, response);

    // Update difficulty adaptation based on successful response generation
    final wasSuccessful = response.isNotEmpty &&
        !response.contains('error') &&
        !response.contains('sorry');
    _updateDifficultyAdaptation(userId, analysis, wasSuccessful);
  }

  /// Handle confusion with progressive clarification
  Future<String> _handleConfusion(
    String message,
    String? conceptId,
    LearningProfile profile,
    List<ChatMessage> history,
  ) async {
    final lastTutorMessage = history
        .lastWhere(
          (m) => m.type == MessageType.assistant,
          orElse: () => ChatMessage(
            id: '',
            content: '',
            type: MessageType.assistant,
            format: MessageFormat.text,
          ),
        )
        .content;

    final prompt = '''
The student is confused about your previous explanation.
Previous explanation: "$lastTutorMessage"
Student says: "$message"

Provide a DIFFERENT, SIMPLER explanation that:
1. Uses more basic language
2. Breaks down the concept into smaller steps
3. Uses a relatable real-world example
4. Avoids jargon and technical terms
5. Includes visual descriptions if helpful

Keep it under 150 words and very encouraging.''';

    final response = await _aiService.callGoogleAIWithRetry(prompt, 0);

    // Track struggling concept
    if (conceptId != null && !profile.strugglingConcepts.contains(conceptId)) {
      profile.strugglingConcepts.add(conceptId);
    }

    return response;
  }

  /// Generate quiz questions based on user profile
  Future<String> _generateQuiz(
    String subject,
    LearningProfile profile,
    String difficulty,
  ) async {
    // Find appropriate concept for quiz
    final concepts = _knowledgeGraph.values
        .where((n) => n.subject == subject)
        .toList()
      ..sort((a, b) => (profile.conceptMastery[a.id] ?? 0)
          .compareTo(profile.conceptMastery[b.id] ?? 0));

    if (concepts.isEmpty) {
      return _generateDynamicQuiz(subject, difficulty);
    }

    final targetConcept = concepts.first;
    final questions = _conceptQuizzes[targetConcept.id] ?? [];

    if (questions.isEmpty) {
      return _generateDynamicQuiz(subject, difficulty);
    }

    final question = questions[math.Random().nextInt(questions.length)];

    return '''
📝 **Quick Quiz Time!**

**Question:** ${question.question}

A) ${question.options[0]}
B) ${question.options[1]}
C) ${question.options[2]}
D) ${question.options[3]}

Reply with your answer (A, B, C, or D) and I'll let you know how you did!

💡 *This question tests: ${targetConcept.name}*
''';
  }

  /// Generate dynamic quiz when predefined questions aren't available
  Future<String> _generateDynamicQuiz(String subject, String difficulty) async {
    final prompt = '''
Create a multiple-choice quiz question for $subject at $difficulty level.
Format the response EXACTLY like this:

📝 **Quick Quiz Time!**

**Question:** [Your question here]

A) [Option A]
B) [Option B]
C) [Option C]
D) [Option D]

Reply with your answer (A, B, C, or D) and I'll let you know how you did!

Make it educational and age-appropriate for students.''';

    return await _aiService.callGoogleAIWithRetry(prompt, 0);
  }

  /// Generate progressive hints
  Future<String> _generateHint(String question, int hintLevel) async {
    final hintTypes = [
      'Give a subtle hint without revealing the answer',
      'Provide a more direct hint that guides toward the solution',
      'Break down the problem into clear steps',
      'Show the solution method with a similar example',
    ];

    final hintInstruction =
        hintLevel < hintTypes.length ? hintTypes[hintLevel] : hintTypes.last;

    final prompt = '''
The student needs help with: "$question"
Hint level: ${hintLevel + 1}

$hintInstruction

Keep the hint brief (under 100 words) and encouraging.
Don't give the complete answer unless it's hint level 4+.''';

    final response = await _aiService.callGoogleAIWithRetry(prompt, 0);

    return '💡 **Hint ${hintLevel + 1}:**\n\n$response';
  }

  /// Generate progress report
  String _generateProgressReport(LearningProfile profile, String subject) {
    final mastery = profile.subjectMastery[subject] ?? 0;
    final totalConcepts =
        _knowledgeGraph.values.where((n) => n.subject == subject).length;
    final completedConcepts = profile.completedConcepts
        .where((id) => _knowledgeGraph[id]?.subject == subject)
        .length;

    final emoji = mastery > 0.8
        ? '🌟'
        : mastery > 0.6
            ? '💪'
            : mastery > 0.4
                ? '📈'
                : '🌱';

    return '''
$emoji **Your Progress in $subject**

📊 **Overall Mastery:** ${(mastery * 100).toStringAsFixed(0)}%
✅ **Concepts Completed:** $completedConcepts/$totalConcepts
🏆 **Total Points:** ${profile.totalPoints}
🔥 **Current Streak:** ${profile.currentStreak} days
🎖️ **Badges Earned:** ${profile.unlockedBadges.length}

${_getMotivationalMessage(mastery)}

**Areas to Focus On:**
${profile.strugglingConcepts.take(3).map((id) => '• ${_knowledgeGraph[id]?.name ?? id}').join('\n')}

Keep up the great work! What would you like to practice next?
''';
  }

  /// Get motivational message based on performance
  String _getMotivationalMessage(double mastery) {
    if (mastery >= 0.9) {
      return "🎉 Outstanding! You're mastering this subject!";
    } else if (mastery >= 0.7) {
      return "Great progress! You're getting really good at this!";
    } else if (mastery >= 0.5) {
      return "You're doing well! Keep practicing to improve further!";
    } else if (mastery >= 0.3) {
      return "Good start! Every step forward counts!";
    } else {
      return "You're just beginning your journey - that's exciting!";
    }
  }

  /// Generate general educational response
  Future<String> _generateGeneralResponse(
    String message,
    String subject,
    LearningProfile profile,
    List<ChatMessage> history,
  ) async {
    final mastery = profile.subjectMastery[subject] ?? 0.5;

    final prompt = '''
You are a friendly, encouraging AI tutor for $subject.
Student mastery: ${(mastery * 100).toStringAsFixed(0)}%
Total points earned: ${profile.totalPoints}

Recent conversation:
${history.take(3).map((m) => '${m.type == MessageType.user ? "Student" : "Tutor"}: ${m.content}').join('\n')}

Student says: "$message"

Respond in a helpful, educational way that:
1. Addresses their message appropriately
2. Maintains an encouraging, supportive tone
3. Uses age-appropriate language
4. Includes emojis sparingly for friendliness
5. Suggests a learning activity if appropriate

Keep response under 150 words.''';

    return await _aiService.callGoogleAIWithRetry(prompt, 0);
  }

  /// Update concept mastery based on performance
  void _updateConceptMastery(
    LearningProfile profile,
    String subject,
    double change,
  ) {
    profile.subjectMastery[subject] =
        (profile.subjectMastery[subject] ?? 0.3) + change;
    profile.subjectMastery[subject] =
        profile.subjectMastery[subject]!.clamp(0.0, 1.0);
  }

  /// Award points and check for badge unlocks
  Future<void> _awardPoints(String userId, int points, String reason) async {
    final profile = _getUserProfile(userId);
    final oldPoints = profile.totalPoints;
    final newPoints = oldPoints + points;

    // Update points
    _learningProfiles[userId] = LearningProfile(
      userId: userId,
      subjectMastery: profile.subjectMastery,
      conceptAttempts: profile.conceptAttempts,
      conceptMastery: profile.conceptMastery,
      completedConcepts: profile.completedConcepts,
      strugglingConcepts: profile.strugglingConcepts,
      totalPoints: newPoints,
      currentStreak: profile.currentStreak,
      lastActivity: DateTime.now(),
      unlockedBadges: profile.unlockedBadges,
      preferences: profile.preferences,
    );

    // Check for badge unlocks
    await _checkBadgeUnlocks(userId);

    debugPrint('Awarded $points points to $userId for $reason');
  }

  /// Check and unlock badges based on achievements
  Future<void> _checkBadgeUnlocks(String userId) async {
    final profile = _getUserProfile(userId);

    // Check each badge threshold
    _badgeThresholds.forEach((badgeId, threshold) {
      if (!profile.unlockedBadges.contains(badgeId)) {
        bool shouldUnlock = false;
        String badgeName = '';
        String badgeIcon = '';

        switch (badgeId) {
          case 'first_session':
            shouldUnlock = _sessionMessages.containsKey(userId) &&
                _sessionMessages[userId]!.isNotEmpty;
            badgeName = 'First Session';
            badgeIcon = '🌱';
            break;
          case 'streak_3':
            shouldUnlock = profile.currentStreak >= threshold;
            badgeName = '3 Day Streak';
            badgeIcon = '🔥';
            break;
          case 'streak_7':
            shouldUnlock = profile.currentStreak >= threshold;
            badgeName = '7 Day Streak';
            badgeIcon = '💎';
            break;
          case 'points_100':
            shouldUnlock = profile.totalPoints >= threshold;
            badgeName = '100 Points';
            badgeIcon = '🎖️';
            break;
          case 'points_500':
            shouldUnlock = profile.totalPoints >= threshold;
            badgeName = '500 Points';
            badgeIcon = '🏆';
            break;
          case 'concepts_10':
            shouldUnlock = profile.completedConcepts.length >= threshold;
            badgeName = '10 Concepts Mastered';
            badgeIcon = '🌟';
            break;
          case 'perfect_quiz':
            // Check if user has completed a perfect quiz (this can be set elsewhere)
            shouldUnlock = profile.unlockedBadges.contains('temp_perfect_quiz');
            badgeName = 'Perfect Quiz';
            badgeIcon = '⭐';
            break;
        }

        if (shouldUnlock) {
          profile.unlockedBadges.add(badgeId);
          debugPrint('$badgeIcon Badge Unlocked: $badgeName!');
        }
      }
    });
  }

  /// Update daily streak
  Future<void> updateStreak(String userId) async {
    final profile = _getUserProfile(userId);
    final lastActivity = profile.lastActivity;
    final now = DateTime.now();

    // Check if it's a new day
    final daysSinceLastActivity = now.difference(lastActivity).inDays;

    if (daysSinceLastActivity == 1) {
      // Consecutive day - increase streak
      _learningProfiles[userId] = LearningProfile(
        userId: userId,
        subjectMastery: profile.subjectMastery,
        conceptAttempts: profile.conceptAttempts,
        conceptMastery: profile.conceptMastery,
        completedConcepts: profile.completedConcepts,
        strugglingConcepts: profile.strugglingConcepts,
        totalPoints: profile.totalPoints,
        currentStreak: profile.currentStreak + 1,
        lastActivity: now,
        unlockedBadges: profile.unlockedBadges,
        preferences: profile.preferences,
      );
      await _checkBadgeUnlocks(userId);
    } else if (daysSinceLastActivity > 1) {
      // Streak broken - reset to 1
      _learningProfiles[userId] = LearningProfile(
        userId: userId,
        subjectMastery: profile.subjectMastery,
        conceptAttempts: profile.conceptAttempts,
        conceptMastery: profile.conceptMastery,
        completedConcepts: profile.completedConcepts,
        strugglingConcepts: profile.strugglingConcepts,
        totalPoints: profile.totalPoints,
        currentStreak: 1,
        lastActivity: now,
        unlockedBadges: profile.unlockedBadges,
        preferences: profile.preferences,
      );
    }
  }

  /// Process quiz answer and update mastery
  Future<ChatMessage> processQuizAnswer({
    required String answer,
    required String sessionId,
    required String conceptId,
    required int correctIndex,
    String? explanation,
  }) async {
    final userAnswer = answer.toUpperCase().trim();
    final answerIndex = ['A', 'B', 'C', 'D'].indexOf(userAnswer);
    final isCorrect = answerIndex == correctIndex;
    final userId = _auth.currentUser?.uid ?? 'anonymous';
    final profile = _getUserProfile(userId);

    String response;
    if (isCorrect) {
      response = '''
✅ **Correct!** Excellent work!

${explanation ?? 'Great job understanding this concept!'}

${_getRandomPraise()}

You earned **15 points**! 🎉
''';
      await _awardPoints(userId, 15, 'quiz_correct');
      _updateConceptMastery(profile, conceptId, 0.1);
    } else {
      response = '''
❌ Not quite right, but that's okay!

The correct answer was **${['A', 'B', 'C', 'D'][correctIndex]}**

${explanation ?? 'Let me explain this concept differently...'}

Remember: Making mistakes is part of learning! You still earned **5 points** for trying! 💪
''';
      await _awardPoints(userId, 5, 'quiz_attempt');
      _updateConceptMastery(profile, conceptId, -0.05);
    }

    // Track attempt
    profile.conceptAttempts[conceptId] =
        (profile.conceptAttempts[conceptId] ?? 0) + 1;

    final chatMessage = ChatMessage(
      id: 'quiz_result_${DateTime.now().millisecondsSinceEpoch}',
      content: response,
      type: MessageType.assistant,
      format: MessageFormat.structured,
      metadata: {
        'type': 'quiz_result',
        'isCorrect': isCorrect,
        'conceptId': conceptId,
      },
    );

    _sessionMessages[sessionId]?.add(chatMessage);

    // 🔥 ADD: Track message ID in session
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.messageIds.add(chatMessage.id);
      // 🔥 FIX: Update session in Firestore with new messageIds
      unawaited(_saveTutorSession(session));
    }

    // Save operations are non-blocking to avoid delays
    unawaited(_saveChatMessage(chatMessage));
    unawaited(_saveUserProfile(profile));

    return chatMessage;
  }

  /// Get random praise message
  String _getRandomPraise() {
    final praises = [
      "You're getting better every day!",
      "Your hard work is paying off!",
      "I'm impressed with your progress!",
      "You're a natural at this!",
      "Keep up the fantastic work!",
      "You're on fire today!",
      "That was brilliant thinking!",
      "You're becoming an expert!",
    ];
    return praises[math.Random().nextInt(praises.length)];
  }

  /// Start an adaptive tutoring session
  Future<TutorSession> startAdaptiveSession({
    required String subject,
    required String difficulty,
    List<String>? learningGoals,
  }) async {
    debugPrint('🔧 Service: Starting session...');
    final user = _auth.currentUser;
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final userId =
        user?.uid ?? 'anonymous_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('🔧 Service: User ID: $userId, Session ID: $sessionId');

    // 🔥 NEW: Load recent session history for cross-session memory
    debugPrint('🔧 Service: Loading recent session history...');
    final recentSessions = await _loadRecentSessions(userId, days: 7);
    debugPrint('🔧 Service: Loaded ${recentSessions.length} recent sessions');

    // Update streak
    debugPrint('🔧 Service: Updating streak...');
    await updateStreak(userId);
    debugPrint('🔧 Service: Streak updated');

    // Create session
    debugPrint('🔧 Service: Creating session...');
    final session = TutorSession(
      id: sessionId,
      userId: userId,
      subject: subject,
      difficulty: difficulty,
      sessionMetrics: {
        'learningGoals': learningGoals ?? [],
        'startMastery': _getUserProfile(userId).subjectMastery[subject] ?? 0,
        'recentSessionsCount': recentSessions.length, // Track loaded history
      },
    );
    debugPrint('🔧 Service: Session object created');
    debugPrint(
        '📍 Session will be saved with userId: "$userId"'); // 🔥 ADD: Log userId being saved

    _activeSessions[sessionId] = session;
    _sessionMessages[sessionId] = [];

    // 🔥 NEW: Add recent session history to context
    _sessionContext[sessionId] = {
      'subject': subject,
      'difficulty': difficulty,
      'startTime': DateTime.now().toIso8601String(),
      'userId': userId,
      'topics_discussed': <String>[],
      'concepts_explored': <String>[],
      'difficulty_progression': <String>[difficulty],
      'learning_path_progress': 0.0,
      'adaptive_adjustments': 0,
      'recent_sessions': recentSessions, // Store for cross-session recall
    };

    // Generate welcome message based on profile
    debugPrint('🔧 Service: Generating welcome message...');
    final profile = _getUserProfile(userId);
    final welcomeMessage =
        _generatePersonalizedWelcome(profile, subject, recentSessions);
    debugPrint('🔧 Service: Welcome message generated');

    final welcomeMsg = ChatMessage(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      content: welcomeMessage,
      type: MessageType.assistant,
      format: MessageFormat.structured,
    );

    _sessionMessages[sessionId]!.add(welcomeMsg);

    // 🔥 ADD: Track message ID in session
    session.messageIds.add(welcomeMsg.id);

    debugPrint('🔧 Service: Welcome message added to session');

    // Save to Firestore (non-blocking - runs in background)
    debugPrint('🔧 Service: Saving to Firestore...');
    unawaited(_saveTutorSession(session));
    debugPrint('🔧 Service: Session save initiated (background)');

    // Award points for starting session (non-blocking)
    unawaited(_awardPoints(userId, 10, 'session_started'));

    // Check if first session badge should be awarded
    if (!profile.unlockedBadges.contains('first_session')) {
      profile.unlockedBadges.add('first_session');
      debugPrint('🔧 Service: Saving user profile with first session badge...');
      unawaited(_saveUserProfile(profile));
      debugPrint('🔧 Service: User profile save initiated (background)');
    }

    debugPrint('🎉 Service: Session creation completed successfully!');
    return session;
  }

  /// Generate personalized welcome message
  String _generatePersonalizedWelcome(LearningProfile profile, String subject,
      [List<Map<String, dynamic>>? recentSessions]) {
    final mastery = profile.subjectMastery[subject] ?? 0;
    final hasReturned =
        profile.lastActivity.difference(DateTime.now()).abs().inDays < 1;

    String greeting = hasReturned
        ? "Welcome back! Great to see you again!"
        : "Hello! I'm your AI tutor, ready to help you learn!";

    // 🔥 NEW: Add session history context
    String historyContext = '';
    if (recentSessions != null && recentSessions.isNotEmpty) {
      final lastSession = recentSessions.first;
      final daysSinceLastSession = DateTime.now()
          .difference(lastSession['startTime'] as DateTime)
          .inDays;

      if (daysSinceLastSession == 0) {
        historyContext = "\n\n📚 Continuing from earlier today...";
      } else if (daysSinceLastSession == 1) {
        historyContext =
            "\n\n📚 Welcome back! I remember our ${lastSession['subject']} discussion from yesterday.";
      } else if (daysSinceLastSession < 7) {
        historyContext =
            "\n\n📚 Welcome back! We last discussed ${lastSession['subject']} $daysSinceLastSession days ago.";
      }
    }

    String streakMessage = profile.currentStreak > 1
        ? "\n\n🔥 You're on a ${profile.currentStreak} day streak! Amazing!"
        : "";

    String masteryMessage = mastery > 0
        ? "\n\n📊 Your current $subject mastery: ${(mastery * 100).toStringAsFixed(0)}%"
        : "\n\n🌟 Let's start your $subject journey!";

    String badges = profile.unlockedBadges.isNotEmpty
        ? "\n\n🎖️ Badges earned: ${profile.unlockedBadges.length}"
        : "";

    return '''
$greeting$historyContext$streakMessage$masteryMessage$badges

What would you like to learn about today? You can:
• Ask me any $subject question
• Request a practice quiz
• Ask for hints on problems
• Check your progress
• Just chat about what you're learning!

How can I help you today?
''';
  }

  /// Get recommended next concept based on knowledge graph
  KnowledgeNode? getNextRecommendedConcept(String userId, String subject) {
    final profile = _getUserProfile(userId);
    final subjectConcepts = _knowledgeGraph.values
        .where((node) => node.subject == subject)
        .toList();

    // Find concepts with all prerequisites completed
    final availableConcepts = subjectConcepts.where((node) {
      return node.prerequisites.every(
        (prereq) => profile.completedConcepts.contains(prereq),
      );
    }).toList();

    // Sort by difficulty and mastery
    availableConcepts.sort((a, b) {
      final aMastery = profile.conceptMastery[a.id] ?? 0;
      final bMastery = profile.conceptMastery[b.id] ?? 0;

      // Prioritize concepts with lower mastery but appropriate difficulty
      final aScore = a.difficulty * (1 - aMastery);
      final bScore = b.difficulty * (1 - bMastery);

      return aScore.compareTo(bScore);
    });

    return availableConcepts.isNotEmpty ? availableConcepts.first : null;
  }

  /// End session and calculate final metrics
  Future<void> endAdaptiveSession(String sessionId) async {
    final session = _activeSessions[sessionId];
    if (session == null) return;

    final userId = session.userId;
    final profile = _getUserProfile(userId);
    final startMastery = session.sessionMetrics['startMastery'] ?? 0;
    final endMastery = profile.subjectMastery[session.subject] ?? 0;
    final improvement = endMastery - startMastery;

    final metrics = _calculateSessionMetrics(sessionId);
    metrics['masteryGain'] = improvement;
    metrics['finalMastery'] = endMastery;
    metrics['pointsEarned'] = profile.totalPoints;

    final endedSession = TutorSession(
      id: session.id,
      userId: session.userId,
      subject: session.subject,
      difficulty: session.difficulty,
      messageIds: session.messageIds,
      startTime: session.startTime,
      endTime: DateTime.now(),
      sessionMetrics: metrics,
      isActive: false,
    );

    // Save session and profile updates (non-blocking)
    unawaited(_saveTutorSession(endedSession));
    unawaited(_saveUserProfile(profile));

    _activeSessions.remove(sessionId);
    _sessionContext.remove(sessionId);
  }

  /// Calculate comprehensive session metrics
  Map<String, dynamic> _calculateSessionMetrics(String sessionId) {
    final messages = _sessionMessages[sessionId] ?? [];
    final context = _sessionContext[sessionId] ?? {};

    final userMessages =
        messages.where((m) => m.type == MessageType.user).length;
    final assistantMessages =
        messages.where((m) => m.type == MessageType.assistant).length;
    final quizMessages =
        messages.where((m) => m.metadata?['type'] == 'quiz').length;
    final hintMessages =
        messages.where((m) => m.metadata?['hintLevel'] != null).length;
    final correctAnswers =
        messages.where((m) => m.metadata?['isCorrect'] == true).length;

    // Calculate context-aware metrics using session context
    final topicsDiscussed = context['topics_discussed'] as List<String>? ?? [];
    final conceptsExplored =
        context['concepts_explored'] as List<String>? ?? [];
    final difficultyProgression =
        context['difficulty_progression'] as List<String>? ?? [];
    final learningPathProgress =
        context['learning_path_progress'] as double? ?? 0.0;
    final adaptiveAdjustments = context['adaptive_adjustments'] as int? ?? 0;

    return {
      'totalMessages': messages.length,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'quizzesTaken': quizMessages,
      'hintsRequested': hintMessages,
      'correctAnswers': correctAnswers,
      'duration': messages.isNotEmpty
          ? messages.last.timestamp
              .difference(messages.first.timestamp)
              .inMinutes
          : 0,
      'engagementScore': _calculateEngagementScore(messages),
      // Context-aware metrics
      'topicsDiscussed': topicsDiscussed.length,
      'conceptsExplored': conceptsExplored.length,
      'difficultyProgression': difficultyProgression,
      'learningPathProgress': learningPathProgress,
      'adaptiveAdjustments': adaptiveAdjustments,
      'contextComplexity': _calculateContextComplexity(context),
    };
  }

  /// Update session context with new information
  void _updateSessionContext(
    String sessionId, {
    String? newTopic,
    String? newConcept,
    String? difficultyChange,
    double? progressIncrement,
    bool? adaptiveAdjustment,
  }) {
    final context = _sessionContext[sessionId];
    if (context == null) return;

    if (newTopic != null) {
      final topics = context['topics_discussed'] as List<String>;
      if (!topics.contains(newTopic)) {
        topics.add(newTopic);
      }
    }

    if (newConcept != null) {
      final concepts = context['concepts_explored'] as List<String>;
      if (!concepts.contains(newConcept)) {
        concepts.add(newConcept);
      }
    }

    if (difficultyChange != null) {
      final progression = context['difficulty_progression'] as List<String>;
      if (progression.isEmpty || progression.last != difficultyChange) {
        progression.add(difficultyChange);
      }
    }

    if (progressIncrement != null) {
      final currentProgress = context['learning_path_progress'] as double;
      context['learning_path_progress'] =
          (currentProgress + progressIncrement).clamp(0.0, 100.0);
    }

    if (adaptiveAdjustment == true) {
      final adjustments = context['adaptive_adjustments'] as int;
      context['adaptive_adjustments'] = adjustments + 1;
    }
  }

  /// Calculate context complexity based on session data
  double _calculateContextComplexity(Map<String, dynamic> context) {
    double complexity = 0.0;

    // Base complexity from topics and concepts
    final topicsCount =
        (context['topics_discussed'] as List<String>? ?? []).length;
    final conceptsCount =
        (context['concepts_explored'] as List<String>? ?? []).length;
    complexity += topicsCount * 0.5 + conceptsCount * 0.3;

    // Difficulty progression complexity
    final difficultyProgression =
        context['difficulty_progression'] as List<String>? ?? [];
    complexity += difficultyProgression.length * 0.2;

    // Adaptive adjustments indicate complexity
    final adaptiveAdjustments = context['adaptive_adjustments'] as int? ?? 0;
    complexity += adaptiveAdjustments * 0.1;

    return complexity.clamp(0.0, 10.0); // Keep complexity score between 0-10
  }

  /// Calculate engagement score based on interaction patterns
  double _calculateEngagementScore(List<ChatMessage> messages) {
    if (messages.isEmpty) return 0.0;

    double score = 0.0;

    // Points for message frequency
    score += math.min(messages.length * 0.05, 0.3);

    // Points for asking questions
    score += messages
            .where((m) => m.type == MessageType.user && m.content.contains('?'))
            .length *
        0.1;

    // Points for quiz participation
    score += messages.where((m) => m.metadata?['type'] == 'quiz').length * 0.15;

    // Points for correct answers
    score +=
        messages.where((m) => m.metadata?['isCorrect'] == true).length * 0.2;

    return math.min(score, 1.0);
  }

  /// Save user profile to Firestore
  Future<void> _saveUserProfile(LearningProfile profile) async {
    try {
      await _firestore
          .collection('learningProfiles')
          .doc(profile.userId)
          .set(profile.toJson())
          .timeout(const Duration(seconds: 5));
      debugPrint('✅ User profile saved to Firestore successfully');
    } catch (e) {
      debugPrint('⚠️ Warning: Could not save user profile to Firestore: $e');
    }
  }

  /// Save chat message to Firestore
  Future<void> _saveChatMessage(ChatMessage message) async {
    try {
      await _firestoreService.createChatMessage(message.toJson());
    } catch (e) {
      debugPrint('Error saving chat message: $e');
    }
  }

  /// Save tutor session to Firestore
  Future<void> _saveTutorSession(TutorSession session) async {
    try {
      // Add timeout to prevent hanging
      await _firestoreService
          .createTutorSession(session.toJson())
          .timeout(const Duration(seconds: 5));
      debugPrint('✅ Session saved to Firestore successfully');
    } catch (e) {
      debugPrint(
          '⚠️ Warning: Could not save to Firestore (session will continue locally): $e');
      // Continue even if Firestore fails - this allows offline usage
    }
  }

  /// 🔥 NEW: Load recent tutor sessions from Firestore for cross-session memory
  Future<List<Map<String, dynamic>>> _loadRecentSessions(String userId,
      {int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      debugPrint(
          '🔍 Querying tutorSessions: userId="$userId", startTime>=${cutoffDate.toIso8601String()}');

      // Query recent sessions from Firestore
      final sessionsSnapshot = await _firestore
          .collection('tutorSessions')
          .where('userId', isEqualTo: userId)
          .where('startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate))
          .orderBy('startTime', descending: true)
          .limit(10) // Load last 10 sessions max
          .get()
          .timeout(const Duration(seconds: 5));

      final sessions = <Map<String, dynamic>>[];

      for (final doc in sessionsSnapshot.docs) {
        final data = doc.data();
        final sessionData = {
          'id': doc.id,
          'subject': data['subject'] ?? 'Unknown',
          'startTime':
              (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'endTime': (data['endTime'] as Timestamp?)?.toDate(),
          'messageCount': (data['messageIds'] as List?)?.length ?? 0,
          'messageIds': data['messageIds'] ?? [],
        };

        // Log each session found
        debugPrint(
            '   📍 Found session: ${doc.id}, subject=${sessionData['subject']}, messageCount=${sessionData['messageCount']}, endTime=${sessionData['endTime']}');

        sessions.add(sessionData);
      }

      debugPrint(
          '✅ Loaded ${sessions.length} recent sessions from Firestore (including current session if active)');
      if (sessions.isEmpty) {
        debugPrint(
            '   ℹ️ No sessions found. This is expected for first-time users or if all sessions are older than $days days.');
      }
      return sessions;
    } catch (e) {
      // Check if it's an index-building error
      final errorStr = e.toString();
      if (errorStr.contains('failed-precondition') ||
          errorStr.contains('index')) {
        debugPrint(
            '⏳ FIRESTORE INDEX STILL BUILDING - Cross-session memory will work once index is ready!');
        debugPrint(
            '   Check status: https://console.firebase.google.com/project/studypals-9f7e1/firestore/indexes');
      } else {
        debugPrint('⚠️ Could not load recent sessions: $e');
      }
      return []; // Return empty list on error
    }
  }

  /// 🔥 NEW: Load chat messages from past sessions for cross-session memory
  Future<List<ChatMessage>> _loadPastSessionMessages(
      List<Map<String, dynamic>> sessions,
      {int maxMessages = 20}) async {
    try {
      final allMessages = <ChatMessage>[];

      // Process sessions in chronological order (oldest first)
      final sortedSessions = List<Map<String, dynamic>>.from(sessions)
        ..sort((a, b) =>
            (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime));

      for (final session in sortedSessions) {
        final messageIds = session['messageIds'] as List<dynamic>?;
        debugPrint(
            '   🔍 Session ${session['id']}: messageIds = $messageIds (length: ${messageIds?.length ?? 0})');

        if (messageIds == null || messageIds.isEmpty) {
          debugPrint(
              '   ⚠️ Skipping session ${session['id']} - no message IDs');
          continue;
        }

        // Load messages for this session
        debugPrint(
            '   📥 Loading ${messageIds.length} messages from session ${session['id']}...');
        for (final messageId in messageIds) {
          try {
            final messageDoc = await _firestore
                .collection('chatMessages')
                .doc(messageId.toString())
                .get()
                .timeout(const Duration(seconds: 2));

            if (messageDoc.exists) {
              final data = messageDoc.data();
              if (data != null) {
                allMessages.add(ChatMessage.fromJson(data));
                debugPrint('      ✅ Loaded message: $messageId');
              }
            } else {
              debugPrint('      ⚠️ Message $messageId not found in Firestore');
            }
          } catch (e) {
            debugPrint('⚠️ Could not load message $messageId: $e');
            // Continue loading other messages
          }
        }

        // Stop if we've collected enough messages
        if (allMessages.length >= maxMessages) break;
      }

      // Return most recent messages, limited to maxMessages
      final messagesToReturn = allMessages.length > maxMessages
          ? allMessages.sublist(allMessages.length - maxMessages)
          : allMessages;

      debugPrint(
          '✅ Loaded ${messagesToReturn.length} messages from ${sessions.length} past sessions');
      return messagesToReturn;
    } catch (e) {
      debugPrint('⚠️ Could not load past session messages: $e');
      return []; // Return empty list on error
    }
  }

  /// Create error message
  ChatMessage _createErrorMessage() {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: 'I apologize, but I encountered an error. Please try again!',
      type: MessageType.error,
      format: MessageFormat.text,
      userId: _auth.currentUser?.uid,
    );
  }

  /// Get learning analytics for a user
  Map<String, dynamic> getUserAnalytics(String userId) {
    final profile = _getUserProfile(userId);

    return {
      'totalPoints': profile.totalPoints,
      'currentStreak': profile.currentStreak,
      'badgesEarned': profile.unlockedBadges.length,
      'completedConcepts': profile.completedConcepts.length,
      'subjectMastery': profile.subjectMastery,
      'strugglingAreas': profile.strugglingConcepts,
      'lastActivity': profile.lastActivity.toIso8601String(),
    };
  }

  /// Get session messages
  List<ChatMessage> getSessionMessages(String sessionId) {
    return _sessionMessages[sessionId] ?? [];
  }

  /// 🔥 NEW: Add user message to session and track its ID
  void addUserMessage(String sessionId, ChatMessage message) {
    _sessionMessages[sessionId] ??= [];
    _sessionMessages[sessionId]!.add(message);

    // Track message ID in session
    final session = _activeSessions[sessionId];
    if (session != null) {
      session.messageIds.add(message.id);
      // 🔥 FIX: Update session in Firestore with new messageIds
      unawaited(_saveTutorSession(session));
    }

    // Save to Firestore (non-blocking)
    unawaited(_saveChatMessage(message));
  }

  /// Get recent sessions data for cross-session memory
  List<Map<String, dynamic>>? getRecentSessionsData(String sessionId) {
    final context = _sessionContext[sessionId];
    if (context == null) return null;

    final recentSessions =
        context['recent_sessions'] as List<Map<String, dynamic>>?;
    return recentSessions;
  }

  /// 🔥 NEW: Get past session messages for cross-session memory
  Future<List<ChatMessage>> getPastSessionMessages(String sessionId) async {
    final recentSessions = getRecentSessionsData(sessionId);
    if (recentSessions == null || recentSessions.isEmpty) {
      return [];
    }

    return await _loadPastSessionMessages(recentSessions, maxMessages: 15);
  }

  /// Get user's learning profile
  LearningProfile? getUserProfile(String userId) {
    return _learningProfiles[userId];
  }

  /// Generate detailed progress analysis with advanced tracking
  Map<String, dynamic> _generateDetailedProgressAnalysis(
      String userId, String subject) {
    final profile = _getUserProfile(userId);
    final patterns = _learningPatterns[userId] ?? {};
    final memory = _conversationMemory[userId] ?? [];

    // Analyze learning trajectory
    final recentSessions = memory.take(10).toList();
    final progressTrend = _calculateProgressTrend(recentSessions);
    final knowledgeGaps = _identifyKnowledgeGaps(profile, subject);
    final strengths = _identifyStrengths(profile, subject);

    return {
      'overall_mastery': profile.subjectMastery[subject] ?? 0,
      'progress_trend': progressTrend,
      'knowledge_gaps': knowledgeGaps,
      'strengths': strengths,
      'recommended_topics': _getRecommendedTopics(profile, subject),
      'learning_velocity': _calculateLearningVelocity(memory),
      'engagement_level': _calculateCurrentEngagement(patterns),
      'next_milestone': _getNextMilestone(profile, subject),
    };
  }

  String _calculateProgressTrend(List<Map<String, dynamic>> recentSessions) {
    if (recentSessions.length < 3) return 'insufficient_data';

    // Analyze complexity of questions over time
    final complexityScores = recentSessions.map((session) {
      final analysis = session['analysis'] as Map<String, dynamic>;
      switch (analysis['complexity']) {
        case 'simple':
          return 1.0;
        case 'medium':
          return 2.0;
        case 'complex':
          return 3.0;
        default:
          return 2.0;
      }
    }).toList();

    // Calculate trend
    final early = complexityScores
        .take(complexityScores.length ~/ 2)
        .fold(0.0, (a, b) => a + b);
    final late = complexityScores
        .skip(complexityScores.length ~/ 2)
        .fold(0.0, (a, b) => a + b);

    if (late > early * 1.2) return 'improving';
    if (late < early * 0.8) return 'declining';
    return 'stable';
  }

  List<String> _identifyKnowledgeGaps(LearningProfile profile, String subject) {
    final gaps = <String>[];

    // Check prerequisite concepts
    for (final conceptId in profile.strugglingConcepts) {
      final concept = _knowledgeGraph[conceptId];
      if (concept?.subject == subject) {
        gaps.add(concept!.name);
      }
    }

    return gaps;
  }

  List<String> _identifyStrengths(LearningProfile profile, String subject) {
    final strengths = <String>[];

    for (final entry in profile.conceptMastery.entries) {
      final concept = _knowledgeGraph[entry.key];
      if (concept?.subject == subject && entry.value > 0.8) {
        strengths.add(concept!.name);
      }
    }

    return strengths;
  }

  List<String> _getRecommendedTopics(LearningProfile profile, String subject) {
    final recommendations = <String>[];

    // Find concepts ready to be learned based on prerequisites
    for (final concept in _knowledgeGraph.values) {
      if (concept.subject == subject &&
          !profile.completedConcepts.contains(concept.id) &&
          _arePrerequisitesMet(concept, profile)) {
        recommendations.add(concept.name);
      }
    }

    return recommendations.take(5).toList();
  }

  bool _arePrerequisitesMet(KnowledgeNode concept, LearningProfile profile) {
    for (final prereqId in concept.prerequisites) {
      if (!profile.completedConcepts.contains(prereqId)) {
        return false;
      }
    }
    return true;
  }

  double _calculateLearningVelocity(List<Map<String, dynamic>> memory) {
    if (memory.length < 2) return 0.0;

    // Calculate concepts learned per session
    final recentSessions = memory.take(5).toList();
    int conceptsEngaged = 0;

    for (final session in recentSessions) {
      final analysis = session['analysis'] as Map<String, dynamic>;
      if (analysis['intent'] == 'deep_explanation' ||
          analysis['intent'] == 'conceptual_understanding') {
        conceptsEngaged++;
      }
    }

    return conceptsEngaged / recentSessions.length;
  }

  double _calculateCurrentEngagement(Map<String, dynamic> patterns,
      {String? userId}) {
    // Base engagement on interaction frequency and depth
    final preferredIntents =
        patterns['preferred_intents'] as Map<String, int>? ?? {};
    final deepLearningIntents = [
      'deep_explanation',
      'conceptual_understanding',
      'problem_solving'
    ];

    int deepEngagement = 0;
    int totalInteractions = 0;

    for (final entry in preferredIntents.entries) {
      totalInteractions += entry.value;
      if (deepLearningIntents.contains(entry.key)) {
        deepEngagement += entry.value;
      }
    }

    double baseEngagement =
        totalInteractions > 0 ? deepEngagement / totalInteractions : 0.5;

    // Factor in timing engagement if userId is provided
    if (userId != null) {
      final timingEngagement = _calculateTimingEngagement(userId);
      baseEngagement = (baseEngagement + timingEngagement) / 2;
    }

    return baseEngagement;
  }

  /// Calculate user engagement based on interaction timing patterns
  double _calculateTimingEngagement(String userId) {
    final lastInteraction = _lastInteractionTime[userId];
    if (lastInteraction == null) return 0.0;

    final timeSinceLastInteraction = DateTime.now().difference(lastInteraction);
    final memory = _conversationMemory[userId] ?? [];

    if (memory.length < 2) return 0.5;

    // Penalize long gaps in interaction (indicates lower engagement)
    double recentEngagementMultiplier = 1.0;
    if (timeSinceLastInteraction.inHours > 24) {
      recentEngagementMultiplier = 0.3; // Very old interaction
    } else if (timeSinceLastInteraction.inHours > 6) {
      recentEngagementMultiplier = 0.6; // Somewhat old interaction
    } else if (timeSinceLastInteraction.inMinutes > 30) {
      recentEngagementMultiplier = 0.8; // Recent but not immediate
    }

    // Calculate average time between interactions
    double totalInterval = 0.0;
    int intervals = 0;

    for (int i = 1; i < memory.length; i++) {
      final prevTimestamp =
          DateTime.parse(memory[i - 1]['timestamp'] as String);
      final currTimestamp = DateTime.parse(memory[i]['timestamp'] as String);
      totalInterval +=
          currTimestamp.difference(prevTimestamp).inMinutes.toDouble();
      intervals++;
    }

    if (intervals == 0) return 0.5 * recentEngagementMultiplier;

    final avgInterval = totalInterval / intervals;

    // High engagement: short intervals (< 2 minutes), consistent interaction
    // Medium engagement: moderate intervals (2-10 minutes)
    // Low engagement: long intervals (> 10 minutes)
    double baseEngagement;
    if (avgInterval < 2) {
      baseEngagement = 0.9;
    } else if (avgInterval < 10) {
      baseEngagement = 0.6;
    } else {
      baseEngagement = 0.3;
    }

    return baseEngagement * recentEngagementMultiplier;
  }

  /// Update comprehensive user behavior analytics
  void _updateBehaviorAnalytics(
      String userId, Map<String, dynamic> analysis, String response) {
    _userBehaviorAnalytics[userId] ??= {
      'session_count': 0,
      'total_interactions': 0,
      'question_types': <String, int>{},
      'learning_patterns': <String, dynamic>{},
      'performance_metrics': <String, double>{},
      'time_spent_minutes': 0.0,
      'preferred_topics': <String, int>{},
      'confusion_instances': 0,
      'successful_completions': 0,
      'average_response_length': 0.0,
      'engagement_history': <double>[],
    };

    final analytics = _userBehaviorAnalytics[userId]!;
    final intent = analysis['intent'] as String;
    final complexity = analysis['complexity'] as String;
    final emotion = analysis['emotion'] as String;

    // Update interaction counts
    analytics['total_interactions'] =
        (analytics['total_interactions'] as int) + 1;

    // Track question types
    final questionTypes = analytics['question_types'] as Map<String, int>;
    questionTypes[intent] = (questionTypes[intent] ?? 0) + 1;

    // Track learning patterns
    final learningPatterns =
        analytics['learning_patterns'] as Map<String, dynamic>;
    learningPatterns['complexity_preference'] ??= <String, int>{};
    final complexityPref =
        learningPatterns['complexity_preference'] as Map<String, int>;
    complexityPref[complexity] = (complexityPref[complexity] ?? 0) + 1;

    learningPatterns['emotional_states'] ??= <String, int>{};
    final emotionalStates =
        learningPatterns['emotional_states'] as Map<String, int>;
    emotionalStates[emotion] = (emotionalStates[emotion] ?? 0) + 1;

    // Track confusion and success patterns
    if (intent == 'confusion_signal') {
      analytics['confusion_instances'] =
          (analytics['confusion_instances'] as int) + 1;
    }

    if (intent == 'validation_seeking' || emotion == 'confident') {
      analytics['successful_completions'] =
          (analytics['successful_completions'] as int) + 1;
    }

    // Update average response length for personalization
    final currentAvg = analytics['average_response_length'] as double;
    final totalInteractions = analytics['total_interactions'] as int;
    analytics['average_response_length'] =
        (currentAvg * (totalInteractions - 1) + response.length) /
            totalInteractions;

    // Track preferred topics from message content
    final preferredTopics = analytics['preferred_topics'] as Map<String, int>;
    final message = analysis['message'] as String? ?? '';
    final topics = _extractTopicsFromMessage(message);
    for (final topic in topics) {
      preferredTopics[topic] = (preferredTopics[topic] ?? 0) + 1;
    }

    // Calculate and store current engagement score
    final engagementHistory = analytics['engagement_history'] as List<double>;
    final currentEngagement = _calculateCurrentEngagement(
        _learningPatterns[userId] ?? {},
        userId: userId);
    engagementHistory.add(currentEngagement);

    // Keep only last 20 engagement scores
    if (engagementHistory.length > 20) {
      engagementHistory.removeAt(0);
    }

    // Update performance metrics
    final performanceMetrics =
        analytics['performance_metrics'] as Map<String, double>;
    performanceMetrics['current_engagement'] = currentEngagement;
    performanceMetrics['confusion_rate'] =
        (analytics['confusion_instances'] as int) /
            (analytics['total_interactions'] as int);
    performanceMetrics['success_rate'] =
        (analytics['successful_completions'] as int) /
            (analytics['total_interactions'] as int);
  }

  /// Get behavior analytics for a user
  Map<String, dynamic> getBehaviorAnalytics(String userId) {
    return _userBehaviorAnalytics[userId] ?? {};
  }

  /// Get detailed progress analysis for a user in a specific subject
  Map<String, dynamic> getProgressAnalysis(String userId, String subject) {
    return _generateDetailedProgressAnalysis(userId, subject);
  }

  // Test helper methods for comprehensive verification
  @visibleForTesting
  bool hasConversationMemory(String userId) {
    return _conversationMemory.containsKey(userId);
  }

  @visibleForTesting
  void initializeUserMemory(String userId) {
    _conversationMemory[userId] ??= [];
    _userPersonality[userId] ??= {};
    _learningPatterns[userId] ??= {};
    _lastInteractionTime[userId] = DateTime.now();
  }

  @visibleForTesting
  Map<String, dynamic> getUserPersonality(String userId) {
    return _userPersonality[userId] ?? {};
  }

  @visibleForTesting
  Map<String, dynamic> getLearningPatterns(String userId) {
    return _learningPatterns[userId] ?? {};
  }

  @visibleForTesting
  DateTime? getLastInteractionTime(String userId) {
    return _lastInteractionTime[userId];
  }

  @visibleForTesting
  void updateUserPersonality(
      String userId, String emotion, String learningStyle) {
    _userPersonality[userId] ??= {};
    _userPersonality[userId]!['dominant_emotions'] ??= <String, int>{};
    _userPersonality[userId]!['dominant_emotions'][emotion] =
        (_userPersonality[userId]!['dominant_emotions'][emotion] ?? 0) + 1;
    _userPersonality[userId]!['learning_style'] = learningStyle;
  }

  @visibleForTesting
  void updateLearningPatterns(String userId, String pattern, bool value) {
    _learningPatterns[userId] ??= {};
    _learningPatterns[userId]![pattern] = value;
  }

  @visibleForTesting
  void updateLastInteractionTime(String userId) {
    _lastInteractionTime[userId] = DateTime.now();
  }

  @visibleForTesting
  String testGenerateCacheKey(String message, Map<String, dynamic> context) {
    return '$message-${context.hashCode}';
  }

  @visibleForTesting
  void testAddToCache(String key, String response) {
    _responseCache[key] = response;
    _pruneResponseCache();
  }

  @visibleForTesting
  bool testShouldUseCachedResponse(String key) {
    return _responseCache.containsKey(key);
  }

  @visibleForTesting
  int testGetCacheSize() {
    return _responseCache.length;
  }

  @visibleForTesting
  List<String> testExtractTopicsFromMessage(String message) {
    return _extractTopicsFromMessage(message);
  }

  @visibleForTesting
  List<String> testGenerateTopicBasedFollowUps(
      String message, Map<String, dynamic> analysis, String userId) {
    return _generateTopicBasedFollowUps(message, userId);
  }

  @visibleForTesting
  void testUpdateTopicFollowUps(
      String userId, String topic, List<String> followUps) {
    _topicFollowUps[userId] ??= [];
    // Add topic to list (simplified for testing)
    if (!_topicFollowUps[userId]!.contains(topic)) {
      _topicFollowUps[userId]!.add(topic);
    }

    // Limit to 20 topics per user
    if (_topicFollowUps[userId]!.length > 20) {
      _topicFollowUps[userId]!.removeAt(0);
    }
  }

  @visibleForTesting
  Map<String, List<String>> getTopicFollowUps(String userId) {
    final topics = _topicFollowUps[userId] ?? [];
    final result = <String, List<String>>{};
    for (final topic in topics) {
      result[topic] = ['Follow-up for $topic'];
    }
    return result;
  }

  @visibleForTesting
  void testUpdateBehaviorAnalytics(
      String userId, Map<String, dynamic> analysis, String response) {
    _updateBehaviorAnalytics(userId, analysis, response);
  }

  @visibleForTesting
  double testCalculateTimingEngagement(String userId) {
    return _calculateTimingEngagement(userId);
  }

  @visibleForTesting
  void testUpdateDifficultyAdaptation(
      String userId, Map<String, dynamic> analysis, bool wasSuccessful) {
    _updateDifficultyAdaptation(userId, analysis, wasSuccessful);
  }

  @visibleForTesting
  List<double> testGetDifficultyAdaptationHistory(String userId) {
    return _difficultyAdaptation[userId] ?? [];
  }

  @visibleForTesting
  Map<String, dynamic> testApplyDifficultyAdaptation(
      String userId, Map<String, dynamic> responseConfig) {
    return _applyDifficultyAdaptation(userId, responseConfig);
  }

  /// Update difficulty adaptation based on user performance
  void _updateDifficultyAdaptation(
      String userId, Map<String, dynamic> analysis, bool wasSuccessful) {
    _difficultyAdaptation[userId] ??= [];
    final adaptationHistory = _difficultyAdaptation[userId]!;

    final complexity = analysis['complexity'] as String;
    final intent = analysis['intent'] as String;

    // Convert complexity and success to numerical score
    double complexityScore = 0.0;
    switch (complexity) {
      case 'simple':
        complexityScore = 1.0;
        break;
      case 'medium':
        complexityScore = 2.0;
        break;
      case 'complex':
        complexityScore = 3.0;
        break;
    }

    // Adjust score based on success/failure
    double performanceScore =
        wasSuccessful ? complexityScore : complexityScore * 0.5;

    // Factor in intent difficulty
    if (intent == 'deep_explanation' || intent == 'problem_solving') {
      performanceScore *= 1.2;
    } else if (intent == 'quick_clarification') {
      performanceScore *= 0.8;
    }

    adaptationHistory.add(performanceScore);

    // Keep only last 10 performance scores for adaptation
    if (adaptationHistory.length > 10) {
      adaptationHistory.removeAt(0);
    }
  }

  /// Get recommended difficulty level for user
  String getRecommendedDifficulty(String userId) {
    final adaptationHistory = _difficultyAdaptation[userId];
    if (adaptationHistory == null || adaptationHistory.isEmpty) {
      return 'medium'; // Default difficulty
    }

    // Calculate average performance score
    final avgScore =
        adaptationHistory.reduce((a, b) => a + b) / adaptationHistory.length;

    // Recent performance trend (last 3 vs previous scores)
    double recentTrend = 0.0;
    if (adaptationHistory.length >= 6) {
      final recent = adaptationHistory
              .skip(adaptationHistory.length - 3)
              .fold(0.0, (a, b) => a + b) /
          3;
      final previous = adaptationHistory
              .take(adaptationHistory.length - 3)
              .fold(0.0, (a, b) => a + b) /
          (adaptationHistory.length - 3);
      recentTrend = recent - previous;
    }

    // Adjust difficulty based on performance and trend
    if (avgScore >= 2.5 && recentTrend >= 0) {
      return 'hard'; // User is performing well, increase difficulty
    } else if (avgScore >= 1.8) {
      return 'medium';
    } else if (avgScore >= 1.0) {
      return 'easy';
    } else {
      return 'beginner'; // User struggling, provide more support
    }
  }

  /// Apply difficulty adaptation to response configuration
  Map<String, dynamic> _applyDifficultyAdaptation(
      String userId, Map<String, dynamic> responseConfig) {
    final recommendedDifficulty = getRecommendedDifficulty(userId);
    final adaptedConfig = Map<String, dynamic>.from(responseConfig);

    switch (recommendedDifficulty) {
      case 'beginner':
        adaptedConfig['complexity'] = 'simple';
        adaptedConfig['examples'] = true;
        adaptedConfig['encouragement'] = 'high';
        adaptedConfig['structure'] = 'simplified_breakdown';
        break;
      case 'easy':
        adaptedConfig['complexity'] = 'simple';
        adaptedConfig['examples'] = true;
        break;
      case 'medium':
        // Keep original configuration
        break;
      case 'hard':
        adaptedConfig['complexity'] = 'complex';
        adaptedConfig['examples'] = false;
        adaptedConfig['structure'] = 'structured_detailed';
        break;
    }

    return adaptedConfig;
  }

  /// Generate cache key for response caching
  String _generateCacheKey(
      String question, String subject, Map<String, dynamic> analysis) {
    final intent = analysis['intent'] as String;
    final complexity = analysis['complexity'] as String;

    // Create a normalized key based on question essence and context
    final normalizedQuestion =
        question.toLowerCase().trim().replaceAll(RegExp(r'\s+'), ' ');
    return '${subject}_${intent}_${complexity}_${normalizedQuestion.hashCode}';
  }

  /// Determine if cached response should be used
  bool _shouldUseCachedResponse(
      Map<String, dynamic> analysis, LearningProfile profile) {
    final intent = analysis['intent'] as String;

    // Use cache for factual questions and quick clarifications
    // Avoid cache for personalized or complex queries
    return intent == 'quick_clarification' ||
        intent == 'validation_seeking' ||
        (intent == 'question' && analysis['complexity'] == 'simple');
  }

  /// Determine if response should be cached
  bool _shouldCacheResponse(Map<String, dynamic> analysis, String response) {
    final intent = analysis['intent'] as String;

    // Cache short, factual responses that are likely to be reused
    return (intent == 'quick_clarification' ||
            intent == 'validation_seeking') &&
        response.length < 200 &&
        !response.contains('you') && // Avoid personalized responses
        !response.contains('your');
  }

  /// Prune response cache to prevent memory bloat
  void _pruneResponseCache() {
    // Keep only the 100 most recent responses
    if (_responseCache.length > 100) {
      final entries = _responseCache.entries.toList();
      _responseCache.clear();

      // Keep the last 100 entries (simple LRU-like approach)
      for (int i = entries.length - 100; i < entries.length; i++) {
        _responseCache[entries[i].key] = entries[i].value;
      }
    }
  }

  String _getNextMilestone(LearningProfile profile, String subject) {
    final mastery = profile.subjectMastery[subject] ?? 0.0;

    if (mastery < 0.25) return 'Complete 5 basic concepts';
    if (mastery < 0.5) return 'Achieve 50% subject mastery';
    if (mastery < 0.75) return 'Master intermediate topics';
    if (mastery < 0.9) return 'Complete advanced concepts';
    return 'Achieve expert level (95%+)';
  }
}
