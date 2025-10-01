// enhanced_ai_tutor_provider.dart

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/tutor_session.dart';
import '../models/knowledge_node.dart';
import '../models/learning_profile.dart';
import '../models/quiz_question.dart';
import '../models/user.dart' as app_user;
import '../services/enhanced_ai_tutor_service.dart';
import 'ai_provider.dart';

/// Log level enum for development logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Response length types based on AI Assistant Response Length Framework
enum ResponseType {
  simple,  // 1-2 sentences
  medium,  // 3-5 sentences / short paragraph
  longer,  // Detailed, structured response
}

/// Subject categories for specialized handling
enum SubjectType {
  mathematics,
  science,
  history,
  literature,
  language,
  philosophy,
  arts,
  technology,
  socialStudies,
  general,
}

/// Query complexity levels
enum QueryComplexity {
  basic,      // Simple facts, definitions
  intermediate, // Explanations, comparisons
  advanced,   // Analysis, synthesis, evaluation
}

/// User intent classification
enum UserIntent {
  factual,      // Want facts/definitions
  conceptual,   // Want understanding
  procedural,   // Want step-by-step process
  analytical,   // Want analysis/evaluation
  creative,     // Want exploration/brainstorming
  confirmatory, // Seeking validation
}

/// Learning approach preferences
enum LearningApproach {
  direct,       // Straightforward explanation
  socratic,     // Guided questioning
  exampleBased, // Learn through examples
  analogical,   // Learn through analogies
  scaffolded,   // Step-by-step building
}

/// Comprehensive query analysis result
class QueryAnalysis {
  final SubjectType subject;
  final QueryComplexity complexity;
  final UserIntent intent;
  final ResponseType responseType;
  final LearningApproach learningApproach;
  final List<String> keywords;
  final String questionType;
  final bool requiresExamples;
  final bool requiresSteps;

  QueryAnalysis({
    required this.subject,
    required this.complexity,
    required this.intent,
    required this.responseType,
    required this.learningApproach,
    required this.keywords,
    required this.questionType,
    required this.requiresExamples,
    required this.requiresSteps,
  });

  @override
  String toString() {
    return 'QueryAnalysis(subject: $subject, complexity: $complexity, intent: $intent, responseType: $responseType, approach: $learningApproach, examples: $requiresExamples, steps: $requiresSteps)';
  }
}

/// State management for enhanced AI tutor with adaptive learning
class EnhancedAITutorProvider extends ChangeNotifier {
  final EnhancedAITutorService _tutorService;
  StudyPalsAIProvider? _aiProvider; // Reference to the working AI provider
  static int _instanceCount = 0;

  // State variables
  List<ChatMessage> _messages = [];
  TutorSession? _currentSession;
  bool _isGenerating = false;
  String? _lastMessageContent;
  DateTime? _lastMessageTime;
  bool _isStartingSession = false;
  String? _error;
  String _currentSubject = 'Mathematics';
  String _currentDifficulty = 'Intermediate';
  List<String> _learningGoals = [];
  
  // Enhanced context tracking
  final List<String> _conversationTopics = [];
  final Map<String, int> _topicFrequency = {};
  final List<QueryAnalysis> _queryHistory = [];
  String? _lastLearningApproach;
  SubjectType? _dominantSubject;
  QueryComplexity? _userComplexityLevel;
  
  // Learning profile state
  LearningProfile? _userProfile;
  KnowledgeNode? _currentConcept;
  QuizQuestion? _activeQuiz;
  
  // UI state
  bool _showProgress = false;
  bool _showBadges = false;
  Map<String, dynamic> _sessionMetrics = {};
  
  // Quick reply suggestions
  List<String> _quickReplies = [];

  EnhancedAITutorProvider(this._tutorService) {
    _instanceCount++;
    _log('EnhancedAITutorProvider instance #$_instanceCount created', level: LogLevel.debug);
  }

  /// Logging utility for production-safe debug output
  void _log(String message, {LogLevel level = LogLevel.info, String? context}) {
    if (kDebugMode) {
      final prefix = switch (level) {
        LogLevel.debug => '🐛',
        LogLevel.info => 'ℹ️',
        LogLevel.warning => '⚠️',
        LogLevel.error => '❌',
      };
      final contextStr = context != null ? '[$context] ' : '';
      developer.log('$prefix $contextStr$message', name: 'EnhancedAITutor');
    }
  }

  /// Set the working AI provider reference
  void setAIProvider(StudyPalsAIProvider aiProvider) {
    _aiProvider = aiProvider;
    _log('AI Provider configured for Enhanced AI Tutor', level: LogLevel.debug);
  }

  // Getters
  List<ChatMessage> get messages => _messages;
  TutorSession? get currentSession => _currentSession;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  String get currentSubject => _currentSubject;
  String get currentDifficulty => _currentDifficulty;
  List<String> get learningGoals => _learningGoals;
  LearningProfile? get userProfile => _userProfile;
  KnowledgeNode? get currentConcept => _currentConcept;
  QuizQuestion? get activeQuiz => _activeQuiz;
  bool get showProgress => _showProgress;
  bool get showBadges => _showBadges;
  Map<String, dynamic> get sessionMetrics => _sessionMetrics;
  List<String> get quickReplies => _quickReplies;
  bool get hasActiveSession => _currentSession?.isActive == true;
  bool get isStartingSession => _isStartingSession;

  // Statistics getters
  int get totalPoints => _userProfile?.totalPoints ?? 0;
  int get currentStreak => _userProfile?.currentStreak ?? 0;
  List<String> get unlockedBadges => _userProfile?.unlockedBadges ?? [];
  double get subjectMastery => 
      _userProfile?.subjectMastery[_currentSubject] ?? 0.0;
  
  /// Initialize provider
  Future<void> initialize() async {
    try {
      _error = null;
      await _tutorService.loadUserProfiles();
      
      final userId = _tutorService.auth.currentUser?.uid;
      if (userId != null) {
        _userProfile = _tutorService.getUserProfile(userId);
        await _tutorService.updateStreak(userId);
      }
      
      _updateQuickReplies();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      notifyListeners();
    }
  }

  /// Start a new adaptive tutoring session
  Future<void> startAdaptiveSession({
    String? subject,
    String? difficulty,
    List<String>? goals,
  }) async {
    // Prevent multiple simultaneous session starts
    if (_isStartingSession) {
      _log('Session start already in progress, ignoring duplicate request', level: LogLevel.warning, context: 'startAdaptiveSession');
      return;
    }

    try {
      _log('Starting adaptive session...', level: LogLevel.info, context: 'startAdaptiveSession');
      _isStartingSession = true;
      _error = null;
      notifyListeners(); // Update UI to show loading state
      
      _currentSubject = subject ?? _currentSubject;
      _currentDifficulty = difficulty ?? _currentDifficulty;
      _learningGoals = goals ?? [];
      
      _log('Subject: $_currentSubject, Difficulty: $_currentDifficulty', level: LogLevel.info, context: 'startAdaptiveSession');
      
      _currentSession = await _tutorService.startAdaptiveSession(
        subject: _currentSubject,
        difficulty: _currentDifficulty,
        learningGoals: _learningGoals,
      );
      
      _log('Session created: ${_currentSession!.id}', level: LogLevel.info, context: 'startAdaptiveSession');
      
      _messages = _tutorService.getSessionMessages(_currentSession!.id);
      _log('Messages loaded: ${_messages.length}', level: LogLevel.info, context: 'startAdaptiveSession');
      
      if (_messages.isEmpty) {
        _log('Warning: No messages found in session', level: LogLevel.warning, context: 'startAdaptiveSession');
      }
      
      // Get recommended concept
      final userId = _tutorService.auth.currentUser?.uid ?? 'anonymous';
      _log('User ID: $userId', level: LogLevel.info, context: 'startAdaptiveSession');
      
      _currentConcept = _tutorService.getNextRecommendedConcept(
        userId,
        _currentSubject,
      );
      _userProfile = _tutorService.getUserProfile(userId);
      
      _log('Current concept: ${_currentConcept?.name}', level: LogLevel.info, context: 'startAdaptiveSession');
      
      _updateQuickReplies();
      _log('Session started successfully!', level: LogLevel.info, context: 'startAdaptiveSession');
    } catch (e) {
      _error = 'Failed to start session: $e';
      _log('Error starting session: $e', level: LogLevel.error, context: 'startAdaptiveSession');
    } finally {
      _isStartingSession = false;
      notifyListeners();
    }
  }

  /// Send a message and get AI response
  Future<void> sendMessage(String content, {app_user.User? user}) async {
    if (_currentSession == null || content.trim().isEmpty || _isGenerating) return;

    // Simple duplicate prevention: ignore identical messages sent within 2 seconds
    final now = DateTime.now();
    if (_lastMessageContent == content.trim() && 
        _lastMessageTime != null && 
        now.difference(_lastMessageTime!).inSeconds < 2) {
      _log('Duplicate message ignored: "$content"', level: LogLevel.warning, context: 'sendMessage');
      return;
    }

    _lastMessageContent = content.trim();
    _lastMessageTime = now;

    _log('sendMessage called with: "$content", _isGenerating: $_isGenerating, _activeQuiz: ${_activeQuiz != null}', level: LogLevel.debug, context: 'sendMessage');

    try {
      _error = null;
      
      // Check if this is a quiz answer BEFORE clearing _activeQuiz
      if (_isQuizAnswer(content)) {
        _log('Processing as quiz answer', level: LogLevel.debug, context: 'sendMessage');
        await _processQuizAnswer(content);
        return;
      }
      
      // Clear active quiz only if this is not a quiz answer
      _activeQuiz = null;
      _log('Processing as regular message', level: LogLevel.debug, context: 'sendMessage');
      
      // Add user message
      final userMessage = ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        content: content.trim(),
        type: MessageType.user,
        format: MessageFormat.text,
        userId: user?.id ?? _tutorService.auth.currentUser?.uid,
      );
      
      _messages.add(userMessage);
      _log('Added user message to list. Total messages: ${_messages.length}', level: LogLevel.debug, context: 'sendMessage');
      _isGenerating = true;
      _quickReplies.clear();
      notifyListeners();

      // Generate AI response using the working AI provider
      String responseContent;
      if (_aiProvider != null && _aiProvider!.isAIEnabled) {
        // Use the working AI service that handles flashcards
        final prompt = _buildPromptForContent(content.trim());
        
        responseContent = await _aiProvider!.aiService.callGoogleAIWithRetry(prompt, 0);
        
        // PRODUCTION QUALITY CONTROL - Validate response meets standards
        final analysis = _performQueryAnalysis(content.trim());
        responseContent = _validateAndOptimizeResponse(responseContent, analysis, content.trim());
      } else {
        responseContent = 'I apologize, but I encountered an error. Please try again!';
      }
      
      final aiResponse = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: responseContent,
        type: MessageType.assistant,
        format: MessageFormat.text,
      );

      _messages.add(aiResponse);
      _log('Added AI response to list. Total messages: ${_messages.length}', level: LogLevel.debug, context: 'sendMessage');
      
      // Check if response contains a quiz (either by metadata or content)
      if (aiResponse.metadata?['type'] == 'quiz' || 
          _containsQuizPattern(aiResponse.content)) {
        _parseQuizFromResponse(aiResponse.content);
      }
      
      // Update user profile
      final userId = _tutorService.auth.currentUser?.uid;
      if (userId != null) {
        _userProfile = _tutorService.getUserProfile(userId);
      }
      
      // Update session metrics
      _sessionMetrics = _tutorService.calculateSessionMetrics(_currentSession!.id);
      
      _updateQuickReplies();
    } catch (e) {
      _error = 'Failed to generate response: $e';
      
      // Add error message
      final errorMessage = ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Sorry, I encountered an error. Please try again.',
        type: MessageType.error,
        format: MessageFormat.text,
      );
      
      _messages.add(errorMessage);
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Build an appropriate prompt based on comprehensive content analysis
  String _buildPromptForContent(String content) {
    // Perform comprehensive query analysis
    final analysis = _performQueryAnalysis(content);
    _log('Query Analysis: ${analysis.toString()}', level: LogLevel.debug, context: 'sendMessage');
    
    // Check for simple math first (legacy support)
    if (_isSimpleMathProblem(content)) {
      _log('Using simple math prompt', level: LogLevel.debug, context: 'sendMessage');
      return _buildSimpleMathPrompt(content);
    }
    
    // Build sophisticated prompt based on analysis
    return _buildAdaptivePrompt(content, analysis);
  }
  
  /// Perform comprehensive query analysis
  QueryAnalysis _performQueryAnalysis(String content) {
    final lower = content.toLowerCase().trim();
    
    return QueryAnalysis(
      subject: _identifySubject(lower),
      complexity: _assessComplexity(lower, content),
      intent: _classifyIntent(lower),
      responseType: _determineResponseType(lower, content),
      learningApproach: _selectLearningApproach(lower, content),
      keywords: _extractKeywords(lower),
      questionType: _identifyQuestionType(lower),
      requiresExamples: _needsExamples(lower),
      requiresSteps: _needsStepByStep(lower),
    );
  }

  /// Identify the subject/domain of the query with enhanced precision
  SubjectType _identifySubject(String content) {
    final contentLower = content.toLowerCase();
    
    final mathKeywords = ['math', 'mathematics', 'algebra', 'geometry', 'calculus', 'statistics', 'equation', 'formula', 'number', 'solve', '+', '-', '*', '/', '=', 'fraction', 'percentage'];
    final scienceKeywords = [
      // General science
      'science', 'scientific', 'experiment', 'hypothesis', 'theory', 'research', 'study', 'data', 'observation',
      // Biology
      'biology', 'biological', 'life', 'living', 'organism', 'cell', 'cellular', 'gene', 'genetic', 'dna', 'rna', 
      'protein', 'enzyme', 'evolution', 'species', 'ecosystem', 'photosynthesis', 'respiration', 'virus', 'bacteria',
      'anatomy', 'physiology', 'organ', 'tissue', 'blood', 'heart', 'brain', 'nervous', 'immune', 'reproduction',
      // Chemistry  
      'chemistry', 'chemical', 'element', 'compound', 'molecule', 'atom', 'atomic', 'ion', 'bond', 'reaction',
      'acid', 'base', 'ph', 'solution', 'mixture', 'carbon', 'oxygen', 'hydrogen', 'nitrogen', 'periodic table',
      'catalyst', 'oxidation', 'reduction', 'organic', 'inorganic', 'polymer', 'crystal', 'phase',
      // Physics
      'physics', 'physical', 'force', 'energy', 'motion', 'velocity', 'acceleration', 'gravity', 'mass', 'weight',
      'momentum', 'friction', 'pressure', 'temperature', 'heat', 'light', 'sound', 'wave', 'frequency', 'wavelength',
      'electricity', 'magnetic', 'electromagnetic', 'radiation', 'quantum', 'nuclear', 'relativity', 'thermodynamics',
      // Earth science
      'geology', 'earth', 'planet', 'solar system', 'atmosphere', 'climate', 'weather', 'ocean', 'volcano', 'earthquake',
      'mineral', 'rock', 'fossil', 'plate tectonics', 'erosion', 'sediment', 'meteorology', 'astronomy', 'star', 'galaxy'
    ];
    final historyKeywords = ['history', 'historical', 'war', 'revolution', 'century', 'ancient', 'medieval', 'empire', 'civilization', 'culture', 'timeline', 'event', 'period'];
    final literatureKeywords = ['literature', 'poem', 'poetry', 'novel', 'story', 'author', 'character', 'plot', 'theme', 'metaphor', 'symbolism', 'genre', 'writing'];
    final languageKeywords = ['grammar', 'syntax', 'vocabulary', 'language', 'pronunciation', 'spelling', 'conjugation', 'tense', 'noun', 'verb', 'adjective'];
    final philosophyKeywords = ['philosophy', 'ethics', 'morality', 'logic', 'reasoning', 'argument', 'belief', 'truth', 'knowledge', 'wisdom', 'existence'];
    final artsKeywords = ['art', 'painting', 'sculpture', 'music', 'composition', 'artist', 'creative', 'aesthetic', 'style', 'technique', 'medium'];
    final techKeywords = ['technology', 'computer', 'programming', 'code', 'software', 'algorithm', 'data', 'digital', 'internet', 'artificial intelligence'];
    final socialKeywords = ['society', 'culture', 'government', 'politics', 'economics', 'social', 'community', 'democracy', 'law', 'rights'];

    // Use case-insensitive matching for better accuracy
    if (mathKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.mathematics;
    if (scienceKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.science;
    if (historyKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.history;
    if (literatureKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.literature;
    if (languageKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.language;
    if (philosophyKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.philosophy;
    if (artsKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.arts;
    if (techKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.technology;
    if (socialKeywords.any((k) => contentLower.contains(k.toLowerCase()))) return SubjectType.socialStudies;
    
    _log('Subject classification failed for: "$content" - defaulting to general', level: LogLevel.warning, context: 'analyzeQuery');
    return SubjectType.general;
  }

  /// Assess the complexity level of the query
  QueryComplexity _assessComplexity(String content, String original) {
    final basicIndicators = ['what is', 'define', 'meaning', 'who is', 'when did', 'where is'];
    final advancedIndicators = ['analyze', 'evaluate', 'compare and contrast', 'synthesize', 'critique', 'argue', 'prove', 'derive'];
    final complexWords = ['relationship', 'implications', 'consequences', 'significance', 'methodology', 'framework', 'paradigm'];
    
    if (advancedIndicators.any((i) => content.contains(i)) || complexWords.any((w) => content.contains(w))) {
      return QueryComplexity.advanced;
    }
    if (basicIndicators.any((i) => content.contains(i)) || original.split(' ').length <= 5) {
      return QueryComplexity.basic;
    }
    return QueryComplexity.intermediate;
  }

  /// Classify the user's intent with ChatGPT-level precision
  UserIntent _classifyIntent(String content) {
    final contentLower = content.toLowerCase().trim();
    
    // CONFIRMATION INTENT - High priority for true/false, validation queries
    final confirmPatterns = [
      RegExp(r'^true or false', caseSensitive: false),
      RegExp(r'^(correct|right|wrong|yes|no)\??$', caseSensitive: false),
      RegExp(r'^is (this|that|it) (true|false|correct|right)', caseSensitive: false),
      RegExp(r'^\w+\s+(sets|rises|equals|is|was|were)\s+', caseSensitive: false), // Statement queries
      RegExp(r'^\w+.*\?(true|false)', caseSensitive: false), // Question ending with true/false
      RegExp(r'^(the \w+|\w+) (is|are|was|were|will be|can be)', caseSensitive: false), // Statement format
    ];
    if (confirmPatterns.any((p) => p.hasMatch(contentLower))) {
      _log('CONFIRMATORY intent detected for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
      return UserIntent.confirmatory;
    }
    
    // FACTUAL INTENT - Direct fact requests (ultra-precise patterns)
    final factualPatterns = [
      RegExp(r'^(who|when|where|which) (is|was|were|did|wrote|created|invented|discovered|founded)', caseSensitive: false),
      RegExp(r'^what is( the)? (capital|currency|population|date|name|meaning|definition)', caseSensitive: false),
      RegExp(r'^define \w+$', caseSensitive: false),
      RegExp(r'^what (is|are|was|were) [^?]*\?$', caseSensitive: false), // "What is DNA?", "What is gravity?"
      RegExp(r'^(who wrote|who created|who invented|who discovered)', caseSensitive: false),
      RegExp(r'^when (did|was|were)', caseSensitive: false),
      RegExp(r'^where (is|was|were)', caseSensitive: false),
    ];
    if (factualPatterns.any((p) => p.hasMatch(contentLower))) {
      _log('FACTUAL intent detected for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
      return UserIntent.factual;
    }
    
    // PROCEDURAL INTENT - Process/method requests
    final proceduralPatterns = [
      'how to', 'how do i', 'how can i', 'steps to', 'process of', 'method for', 'procedure',
      'how does', 'how is', 'show me how', 'teach me how', 'explain how'
    ];
    if (proceduralPatterns.any((p) => contentLower.contains(p))) {
      _log('PROCEDURAL intent detected for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
      return UserIntent.procedural;
    }
    
    // ANALYTICAL INTENT - Analysis/evaluation requests
    final analyticalPatterns = [
      'analyze', 'analyse', 'compare', 'contrast', 'evaluate', 'assess', 'critique', 'examine',
      'why is', 'why does', 'why do', 'explain why', 'reasoning behind', 'cause of'
    ];
    if (analyticalPatterns.any((p) => contentLower.contains(p))) {
      _log('ANALYTICAL intent detected for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
      return UserIntent.analytical;
    }
    
    // CREATIVE INTENT - Brainstorming/exploration
    final creativePatterns = [
      'brainstorm', 'ideas for', 'creative', 'imagine', 'suggest', 'possibilities',
      'come up with', 'think of', 'generate', 'invent', 'design'
    ];
    if (creativePatterns.any((p) => contentLower.contains(p))) {
      _log('CREATIVE intent detected for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
      return UserIntent.creative;
    }
    
    // Default to CONCEPTUAL for open-ended questions
    _log('CONCEPTUAL intent (default) for: "$content"', level: LogLevel.debug, context: 'analyzeQuery');
    return UserIntent.conceptual;
  }

  /// Determine appropriate response type with precise intent prediction
  ResponseType _determineResponseType(String content, String original) {
    final lower = content.toLowerCase().trim();
    final originalLength = original.split(' ').length;
    
    // EXPLICIT SIMPLE SIGNALS - Always simple regardless of content
    final explicitSimpleSignals = ['quick', 'short', 'brief', 'just tell me', 'fast', 'yes', 'no'];
    if (explicitSimpleSignals.any((s) => lower.contains(s))) {
      return ResponseType.simple;
    }
    
    // EXPLICIT LONGER SIGNALS - Always detailed
    final explicitLongerSignals = ['step-by-step', 'in detail', 'detailed', 'comprehensive', 'thorough', 'explain fully', 'walk me through', 'breakdown', 'analyze'];
    if (explicitLongerSignals.any((s) => lower.contains(s))) {
      return ResponseType.longer;
    }
    
    // FACTUAL/DIRECT QUERIES - Should be simple
    if (_isDirectFactualQuery(lower)) {
      return ResponseType.simple;
    }
    
    // TRUE/FALSE or CONFIRMATION QUERIES - Always simple
    if (_isConfirmationQuery(lower)) {
      return ResponseType.simple;
    }
    
    // VERY SHORT QUERIES (1-3 words) - Usually simple unless conceptual
    if (originalLength <= 3 && !_isOpenConceptualQuery(lower)) {
      return ResponseType.simple;
    }
    
    // MATHEMATICAL EXPRESSIONS - Simple unless asking for process
    if (_isMathExpression(lower) && !lower.contains('how') && !lower.contains('why')) {
      return ResponseType.simple;
    }
    
    // OPEN-ENDED CONCEPTUAL - Medium
    if (_isOpenConceptualQuery(lower)) {
      return ResponseType.medium;
    }
    
    // PROCEDURAL OR ANALYTICAL - Longer
    if (_isProceduralOrAnalytical(lower)) {
      return ResponseType.longer;
    }
    
    // DEFAULT: Lean toward simple for ambiguous cases
    return originalLength <= 5 ? ResponseType.simple : ResponseType.medium;
  }
  
  /// Check if it's a direct factual query that should get simple answer
  bool _isDirectFactualQuery(String content) {
    final factualPatterns = [
      RegExp(r'^who (wrote|is|was|created|invented|discovered)'),
      RegExp(r'^what (is the|was the) (capital|currency|population)'),
      RegExp(r'^when (did|was|were)'),
      RegExp(r'^where (is|was|are|were)'),
      RegExp(r'^define \w+$'),
      RegExp(r'^what is [a-z]+ \?$'), // "what is X?" where X is single word
    ];
    
    return factualPatterns.any((pattern) => pattern.hasMatch(content));
  }
  
  /// Check if it's a confirmation/true-false query with surgical precision
  bool _isConfirmationQuery(String content) {
    final confirmationPatterns = [
      // Explicit true/false questions
      RegExp(r'^true or false'),
      RegExp(r'^is (this|that|it) (true|false|correct|right|wrong)'),
      RegExp(r'^(correct|right|wrong)\?$'),
      
      // Statement-style questions (key improvement)
      RegExp(r'^the \w+\s+(sets|rises|moves|rotates|orbits)\s+in\s+the\s+\w+$'), // "the sun sets in the west"
      RegExp(r'^\w+\s+(sets|rises|moves|is|equals|makes|causes|creates)\s+'), // "sun sets", "water boils"
      RegExp(r'^\w+\s+\w+\s+(is|are|was|were)\s+\w+$'), // "water is wet", "birds are animals"
      RegExp(r'^\d+\s*[\+\-\*\/]\s*\d+\s*=\s*\d+$'), // "1+1=2" statements
      
      // Scientific facts stated as assertions
      RegExp(r'^(gravity|light|sound|heat|energy|matter)\s+(is|are|causes|creates)'),
      RegExp(r'^(plants|animals|humans|cells)\s+(need|require|produce|make)'),
      
      // Historical/factual statements
      RegExp(r'^\w+\s+(invented|discovered|wrote|created|founded)\s+'),
      RegExp(r'^(world war|the war|the revolution)\s+(started|ended|began)\s+in\s+\d+'),
    ];
    
    return confirmationPatterns.any((pattern) => pattern.hasMatch(content));
  }
  
  /// Check if it's an open conceptual query that warrants medium response
  bool _isOpenConceptualQuery(String content) {
    final conceptualPatterns = [
      RegExp(r'^what is (gravity|photosynthesis|democracy|evolution|quantum)'), // Complex concepts
      RegExp(r'^what (causes|makes|determines)'),
      RegExp(r'^(explain|describe) \w+$'), // Single concept explanation
      RegExp(r'^what.+(difference|relationship)'), // Comparative questions
    ];
    
    return conceptualPatterns.any((pattern) => pattern.hasMatch(content));
  }
  
  /// Check if it's a procedural or analytical query needing longer response
  bool _isProceduralOrAnalytical(String content) {
    final proceduralAnalytical = [
      'how to', 'how do i', 'how does', 'why does', 'analyze', 'compare', 'evaluate',
      'process', 'method', 'procedure', 'steps', 'causes and effects'
    ];
    
    return proceduralAnalytical.any((pattern) => content.contains(pattern));
  }
  
  /// Check if it's a mathematical expression
  bool _isMathExpression(String content) {
    return RegExp(r'^\d+\s*[\+\-\*\/]\s*\d+').hasMatch(content) ||
           RegExp(r'^true or false.*\d+.*\d+').hasMatch(content);
  }

  /// Select appropriate learning approach
  LearningApproach _selectLearningApproach(String content, String original) {
    final questioningIndicators = ['why', 'how', 'what if', 'suppose'];
    final exampleIndicators = ['example', 'instance', 'case', 'illustration'];
    final analogyIndicators = ['like', 'similar to', 'compare to', 'analogous'];
    final stepIndicators = ['step', 'process', 'procedure', 'method', 'sequence'];
    
    if (questioningIndicators.any((i) => content.contains(i))) return LearningApproach.socratic;
    if (exampleIndicators.any((i) => content.contains(i))) return LearningApproach.exampleBased;
    if (analogyIndicators.any((i) => content.contains(i))) return LearningApproach.analogical;
    if (stepIndicators.any((i) => content.contains(i))) return LearningApproach.scaffolded;
    
    return LearningApproach.direct;
  }

  /// Extract key keywords from the query
  List<String> _extractKeywords(String content) {
    final words = content.split(' ').where((w) => w.length > 3).toList();
    final stopWords = ['what', 'how', 'why', 'when', 'where', 'who', 'which', 'that', 'this', 'with', 'from', 'they', 'have', 'will', 'been', 'said', 'each', 'more', 'than'];
    return words.where((w) => !stopWords.contains(w)).take(5).toList();
  }

  /// Identify question type
  String _identifyQuestionType(String content) {
    if (content.startsWith('what')) return 'Definition/Information';
    if (content.startsWith('how')) return 'Process/Method';
    if (content.startsWith('why')) return 'Explanation/Reasoning';
    if (content.startsWith('when')) return 'Temporal';
    if (content.startsWith('where')) return 'Location/Context';
    if (content.startsWith('who')) return 'Person/Entity';
    if (content.contains('?')) return 'Direct Question';
    return 'Statement/Request';
  }

  /// Check if examples are needed
  bool _needsExamples(String content) {
    final exampleIndicators = ['example', 'instance', 'case', 'illustration', 'demonstrate', 'show me'];
    return exampleIndicators.any((i) => content.contains(i)) || content.contains('what is') || content.contains('how to');
  }

  /// Check if step-by-step approach is needed
  bool _needsStepByStep(String content) {
    final stepIndicators = ['step', 'process', 'procedure', 'method', 'how to', 'walk me through', 'guide'];
    return stepIndicators.any((i) => content.contains(i));
  }

  /// Build simple math prompt (legacy support)
  String _buildSimpleMathPrompt(String content) {
    return '''Answer this simple math problem VERY briefly (maximum 25 words):
"$content"

Give just the answer and ask if they want a quiz. Example: "2+2=4. Would you like to practice basic math with a quiz?"

Be concise, direct, and encouraging.''';
  }

  /// Build adaptive prompt based on comprehensive analysis
  String _buildAdaptivePrompt(String content, QueryAnalysis analysis) {
    // Update conversation context
    _updateConversationContext(analysis);
    
    final subjectContext = _getSubjectContext(analysis.subject);
    final complexityGuidance = _getComplexityGuidance(analysis.complexity);
    final approachStrategy = _getApproachStrategy(analysis.learningApproach);
    final responseStructure = _getResponseStructure(analysis.responseType);
    final contextualGuidance = _getContextualGuidance();
    final pedagogicalTechniques = _getPedagogicalTechniques(analysis.intent, analysis.complexity);
    
    return '''You are a world-class AI tutor specializing in $subjectContext. 
Student query: "$content"

CURRENT ANALYSIS:
- Subject: ${analysis.subject.name}
- Complexity: ${analysis.complexity.name}
- Intent: ${analysis.intent.name}
- Learning Style: ${analysis.learningApproach.name}
- Question Type: ${analysis.questionType}
- Keywords: ${analysis.keywords.join(', ')}

CONVERSATION CONTEXT:
$contextualGuidance

RESPONSE REQUIREMENTS:
$responseStructure

PEDAGOGICAL APPROACH:
$approachStrategy

EDUCATIONAL TECHNIQUES:
- $pedagogicalTechniques

COMPLEXITY GUIDANCE:
$complexityGuidance

SPECIAL REQUIREMENTS:
${analysis.requiresExamples ? '✓ Include concrete examples and real-world applications' : ''}
${analysis.requiresSteps ? '✓ Provide step-by-step breakdown or process' : ''}

QUALITY STANDARDS:
- Be pedagogically sound and evidence-based
- Adapt language to $_currentDifficulty level
- Build upon established knowledge
- Maintain student engagement
- Encourage active learning
- Provide accurate, verified information

Deliver a response that rivals the best AI tutors like ChatGPT, Claude, and Gemini.''';
  }

  /// Update conversation context with new analysis
  void _updateConversationContext(QueryAnalysis analysis) {
    // Track query history
    _queryHistory.add(analysis);
    if (_queryHistory.length > 10) {
      _queryHistory.removeAt(0); // Keep last 10 queries
    }
    
    // Update topic frequency
    for (final keyword in analysis.keywords) {
      _topicFrequency[keyword] = (_topicFrequency[keyword] ?? 0) + 1;
    }
    
    // Track conversation topics
    if (!_conversationTopics.contains(analysis.subject.name)) {
      _conversationTopics.add(analysis.subject.name);
    }
    
    // Update dominant subject
    final subjectCounts = <SubjectType, int>{};
    for (final query in _queryHistory) {
      subjectCounts[query.subject] = (subjectCounts[query.subject] ?? 0) + 1;
    }
    _dominantSubject = subjectCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Update user complexity level
    final complexityCounts = <QueryComplexity, int>{};
    for (final query in _queryHistory) {
      complexityCounts[query.complexity] = (complexityCounts[query.complexity] ?? 0) + 1;
    }
    _userComplexityLevel = complexityCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    
    // Track learning approach preference
    _lastLearningApproach = analysis.learningApproach.name;
  }

  /// Get contextual guidance based on conversation history
  String _getContextualGuidance() {
    final guidance = <String>[];
    
    if (_dominantSubject != null) {
      guidance.add('- Primary subject focus: ${_dominantSubject!.name}');
    }
    
    if (_userComplexityLevel != null) {
      guidance.add('- User complexity level: ${_userComplexityLevel!.name}');
    }
    
    if (_lastLearningApproach != null) {
      guidance.add('- Preferred learning approach: $_lastLearningApproach');
    }
    
    if (_conversationTopics.isNotEmpty) {
      guidance.add('- Previous topics: ${_conversationTopics.take(3).join(', ')}');
    }
    
    final frequentTopics = _topicFrequency.entries
        .where((e) => e.value > 1)
        .take(3)
        .map((e) => e.key)
        .toList();
    
    if (frequentTopics.isNotEmpty) {
      guidance.add('- Frequent topics: ${frequentTopics.join(', ')}');
    }
    
    return guidance.isEmpty ? 'No prior context available' : guidance.join('\n');
  }

  /// Get advanced pedagogical techniques based on user intent
  String _getPedagogicalTechniques(UserIntent intent, QueryComplexity complexity) {
    final techniques = <String>[];
    
    switch (intent) {
      case UserIntent.factual:
        techniques.addAll([
          'Use clear definitions and explanations',
          'Provide accurate, verified information',
          'Include relevant context and background'
        ]);
        break;
      case UserIntent.conceptual:
        techniques.addAll([
          'Connect to prior knowledge and experiences',
          'Use multiple representations (visual, verbal, symbolic)',
          'Encourage active processing through questioning'
        ]);
        break;
      case UserIntent.procedural:
        techniques.addAll([
          'Break down into clear, sequential steps',
          'Demonstrate with worked examples',
          'Provide opportunities for guided practice'
        ]);
        break;
      case UserIntent.analytical:
        techniques.addAll([
          'Encourage critical thinking and evaluation',
          'Present multiple perspectives',
          'Guide through analysis frameworks'
        ]);
        break;
      case UserIntent.creative:
        techniques.addAll([
          'Encourage divergent thinking',
          'Provide open-ended exploration',
          'Support brainstorming and idea generation'
        ]);
        break;
      case UserIntent.confirmatory:
        techniques.addAll([
          'Validate correct understanding',
          'Gently correct misconceptions',
          'Reinforce key concepts'
        ]);
        break;
    }
    
    // Add complexity-specific techniques
    switch (complexity) {
      case QueryComplexity.basic:
        techniques.add('Use simple language and concrete examples');
        break;
      case QueryComplexity.intermediate:
        techniques.add('Connect concepts and encourage deeper thinking');
        break;
      case QueryComplexity.advanced:
        techniques.add('Challenge assumptions and encourage synthesis');
        break;
    }
    
    return techniques.join('\n- ');
  }

  /// Get subject-specific context
  String _getSubjectContext(SubjectType subject) {
    switch (subject) {
      case SubjectType.mathematics:
        return 'mathematics with focus on problem-solving, logical reasoning, and practical applications';
      case SubjectType.science:
        return 'science with emphasis on scientific method, evidence-based reasoning, and real-world phenomena';
      case SubjectType.history:
        return 'history with attention to chronology, cause-and-effect, and historical context';
      case SubjectType.literature:
        return 'literature with focus on analysis, interpretation, and literary devices';
      case SubjectType.language:
        return 'language with emphasis on communication, grammar, and linguistic patterns';
      case SubjectType.philosophy:
        return 'philosophy with focus on critical thinking, logical arguments, and ethical reasoning';
      case SubjectType.arts:
        return 'arts with attention to creativity, expression, and aesthetic appreciation';
      case SubjectType.technology:
        return 'technology with focus on innovation, problem-solving, and digital literacy';
      case SubjectType.socialStudies:
        return 'social studies with emphasis on civic understanding and cultural awareness';
      case SubjectType.general:
        return 'general education with interdisciplinary connections';
    }
  }

  /// Get complexity-appropriate guidance
  String _getComplexityGuidance(QueryComplexity complexity) {
    switch (complexity) {
      case QueryComplexity.basic:
        return 'Use simple, clear language. Focus on fundamental concepts. Provide direct answers with minimal jargon.';
      case QueryComplexity.intermediate:
        return 'Use moderate complexity. Connect to prior knowledge. Include some technical terms with explanations.';
      case QueryComplexity.advanced:
        return 'Use sophisticated language. Encourage critical thinking. Include multiple perspectives and nuanced analysis.';
    }
  }

  /// Get learning approach strategy with advanced pedagogical techniques
  String _getApproachStrategy(LearningApproach approach) {
    switch (approach) {
      case LearningApproach.direct:
        return '''DIRECT INSTRUCTION:
- For SIMPLE responses: Be extremely concise, give only essential information
- For MEDIUM/LONGER: Provide clear, structured explanations
- Use precise terminology with definitions when needed
- Present information logically and sequentially''';
        
      case LearningApproach.socratic:
        return '''SOCRATIC METHOD:
- Ask probing questions to guide discovery
- Build on student responses with follow-up questions
- Help students identify their own assumptions
- Use "What if..." and "How do you know..." questions
- Encourage critical thinking through inquiry''';
        
      case LearningApproach.exampleBased:
        return '''EXAMPLE-BASED LEARNING:
- Provide multiple concrete examples
- Show worked problems with detailed steps
- Connect examples to real-world applications
- Use "For instance..." and "Consider this example..."
- Progress from simple to complex examples''';
        
      case LearningApproach.analogical:
        return '''ANALOGICAL REASONING:
- Use familiar concepts to explain new ideas
- Draw parallels between different domains
- Use "Think of it like..." comparisons
- Create visual or conceptual metaphors
- Help transfer knowledge from known to unknown''';
        
      case LearningApproach.scaffolded:
        return '''SCAFFOLDED INSTRUCTION:
- Break complex concepts into smaller parts
- Provide temporary support that can be removed
- Use "First, then, next, finally..." structure
- Check understanding at each step
- Build progressively toward independence''';
    }
  }

  /// Get response structure guidance
  String _getResponseStructure(ResponseType responseType) {
    switch (responseType) {
      case ResponseType.simple:
        return '''RESPONSE LENGTH: ULTRA-CONCISE - Maximum 15 tokens (words). Match ChatGPT brevity.
EXAMPLES OF PERFECT SIMPLE RESPONSES:
- "Who wrote Romeo and Juliet?" → "William Shakespeare"
- "What is DNA?" → "DNA is genetic material containing hereditary information"
- "What is gravity?" → "Gravity is the force that attracts objects toward Earth"
- "The sun sets in the west" → "True"
- "2+2=?" → "4"

RULES:
- Factual questions: ONLY the direct answer, no biography or extra context
- Yes/No or True/False: Single word answer only
- Math problems: Just the numerical answer
- Definitions: Essential meaning in 5-10 words maximum
- NEVER add "hope this helps" or explanatory padding
- BE BRUTALLY CONCISE like ChatGPT''';
      case ResponseType.medium:
        return 'RESPONSE LENGTH: 3-5 sentences (one focused paragraph). Include main concept plus key supporting points.';
      case ResponseType.longer:
        return 'RESPONSE LENGTH: Detailed, well-structured response. Use sections, bullet points, or numbered steps. Include introduction, main content, and summary.';
    }
  }

  /// Check if the content is a simple math problem
  bool _isSimpleMathProblem(String content) {
    final trimmed = content.trim();
    _log('Checking math patterns for: "$trimmed"', level: LogLevel.debug, context: '_isSimpleMath');
    
    // Simple patterns for basic math
    final mathPatterns = [
      RegExp(r'^\d+\s*[\+\-\*\/]\s*\d+$'), // 1+1, 5-3, 2*4, 8/2
      RegExp(r'^what\s+is\s+\d+\s*[\+\-\*\/]\s*\d+\??$', caseSensitive: false), // what is 1+1?
      RegExp(r'^\d+\s*[\+\-\*\/]\s*\d+\s*=\s*\?$'), // 1+1=?
    ];
    
    for (int i = 0; i < mathPatterns.length; i++) {
      final matches = mathPatterns[i].hasMatch(trimmed);
      _log('Pattern $i: ${mathPatterns[i].pattern} -> $matches', level: LogLevel.debug, context: '_isSimpleMath');
      if (matches) {
        _log('Simple math detected!', level: LogLevel.debug, context: '_isSimpleMath');
        return true;
      }
    }
    
    _log('Not simple math', level: LogLevel.debug, context: '_isSimpleMath');
    return false;
  }

  /// Check if message is a quiz answer
  bool _isQuizAnswer(String content) {
    final trimmed = content.trim().toUpperCase();
    final result = _activeQuiz != null && 
           (trimmed == 'A' || trimmed == 'B' || trimmed == 'C' || trimmed == 'D');
    _log('_isQuizAnswer: content="$content", trimmed="$trimmed", _activeQuiz=${_activeQuiz != null}, result=$result', level: LogLevel.debug, context: '_isQuizAnswer');
    return result;
  }

  /// Process quiz answer
  Future<void> _processQuizAnswer(String answer) async {
    if (_activeQuiz == null || _currentSession == null) return;
    
    try {
      _isGenerating = true;
      notifyListeners();
      
      // Add user answer message
      final userMessage = ChatMessage(
        id: 'answer_${DateTime.now().millisecondsSinceEpoch}',
        content: answer.toUpperCase(),
        type: MessageType.user,
        format: MessageFormat.text,
        metadata: {'type': 'quiz_answer'},
      );
      
      _messages.add(userMessage);
      
      // Process answer and get result
      final resultMessage = await _tutorService.processQuizAnswer(
        answer: answer,
        sessionId: _currentSession!.id,
        conceptId: _activeQuiz!.conceptId,
        correctIndex: _activeQuiz!.correctIndex,
        explanation: _activeQuiz!.explanation,
      );
      
      _messages.add(resultMessage);
      
      // Update user profile
      final userId = _tutorService.auth.currentUser?.uid;
      if (userId != null) {
        _userProfile = _tutorService.getUserProfile(userId);
      }
      
      _activeQuiz = null;
      _updateQuickReplies();
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Check if content contains quiz pattern
  bool _containsQuizPattern(String content) {
    return content.contains('A)') && content.contains('B)') && 
           content.contains('C)') && content.contains('D)');
  }

  /// Parse quiz from AI response
  void _parseQuizFromResponse(String content) {
    _log('Parsing quiz from response: "${content.substring(0, content.length > 100 ? 100 : content.length)}..."', level: LogLevel.debug, context: '_parseQuizFromResponse');
    // Simple quiz parsing - in production, use more robust parsing
    if (_containsQuizPattern(content)) {
      _log('Quiz detected! Creating QuizQuestion...', level: LogLevel.debug, context: '_parseQuizFromResponse');
      // This is a quiz - create a QuizQuestion object
      _activeQuiz = QuizQuestion(
        id: 'quiz_${DateTime.now().millisecondsSinceEpoch}',
        question: 'Quiz question from AI',
        options: ['Option A', 'Option B', 'Option C', 'Option D'],
        correctIndex: 0, // Would need to be determined by AI
        explanation: 'Explanation provided after answer',
        conceptId: _currentConcept?.id ?? 'general',
        difficulty: 5,
      );
      
      // Add quiz answer quick replies
      _quickReplies = ['A', 'B', 'C', 'D'];
    }
  }

  /// Update quick reply suggestions based on context
  void _updateQuickReplies() {
    if (_activeQuiz != null) {
      _quickReplies = ['A', 'B', 'C', 'D'];
    } else if (!hasActiveSession) {
      _quickReplies = [
        'Start learning session',
        'Show my progress',
        'View badges',
      ];
    } else {
      final suggestions = [
        'Give me a quiz',
        'Show my progress',
        'I need a hint',
        'Explain this differently',
        'Next topic',
        'Practice problems',
      ];
      
      // Rotate suggestions to keep them fresh
      final startIndex = DateTime.now().minute % suggestions.length;
      _quickReplies = [
        suggestions[startIndex % suggestions.length],
        suggestions[(startIndex + 1) % suggestions.length],
        suggestions[(startIndex + 2) % suggestions.length],
        suggestions[(startIndex + 3) % suggestions.length],
      ];
    }
  }

  /// Request a hint for the current problem
  Future<void> requestHint() async {
    if (_currentSession == null) return;
    await sendMessage("Can you give me a hint?");
  }

  /// Request a quiz
  Future<void> requestQuiz() async {
    if (_currentSession == null) return;
    await sendMessage("Give me a practice quiz");
  }

  /// Check progress
  Future<void> checkProgress() async {
    if (_currentSession == null) return;
    await sendMessage("Show me my progress");
  }

  /// Toggle progress display
  void toggleProgressDisplay() {
    _showProgress = !_showProgress;
    notifyListeners();
  }

  /// Toggle badges display
  void toggleBadgesDisplay() {
    _showBadges = !_showBadges;
    notifyListeners();
  }

  /// Update session subject
  void updateSubject(String subject) {
    _currentSubject = subject;
    
    // Get recommended concept for new subject
    final userId = _tutorService.auth.currentUser?.uid;
    if (userId != null) {
      _currentConcept = _tutorService.getNextRecommendedConcept(
        userId,
        subject,
      );
    }
    
    _updateQuickReplies();
    notifyListeners();
  }

  /// Update session difficulty
  void updateDifficulty(String difficulty) {
    _currentDifficulty = difficulty;
    notifyListeners();
  }

  /// Add learning goal
  void addLearningGoal(String goal) {
    if (!_learningGoals.contains(goal)) {
      _learningGoals.add(goal);
      notifyListeners();
    }
  }

  /// Remove learning goal
  void removeLearningGoal(String goal) {
    _learningGoals.remove(goal);
    notifyListeners();
  }

  /// End the current session
  Future<void> endSession() async {
    if (_currentSession != null) {
      try {
        await _tutorService.endAdaptiveSession(_currentSession!.id);
        
        // Show session summary
        final summary = _generateSessionSummary();
        
        final summaryMessage = ChatMessage(
          id: 'summary_${DateTime.now().millisecondsSinceEpoch}',
          content: summary,
          type: MessageType.assistant,
          format: MessageFormat.structured,
          metadata: {'type': 'session_summary'},
        );
        
        _messages.add(summaryMessage);
        notifyListeners();
        
        // Clear session after delay
        await Future.delayed(const Duration(seconds: 3));
        
        _currentSession = null;
        _messages.clear();
        _activeQuiz = null;
        _sessionMetrics.clear();
        _updateQuickReplies();
        notifyListeners();
      } catch (e) {
        _error = 'Failed to end session: $e';
        notifyListeners();
      }
    }
  }

  /// Generate session summary
  String _generateSessionSummary() {
    final duration = _sessionMetrics['duration'] ?? 0;
    final quizzes = _sessionMetrics['quizzesTaken'] ?? 0;
    final correct = _sessionMetrics['correctAnswers'] ?? 0;
    final engagement = _sessionMetrics['engagementScore'] ?? 0.0;
    final pointsEarned = (_userProfile?.totalPoints ?? 0) - 
                         (_sessionMetrics['startPoints'] ?? 0);

    return '''
📚 **Session Complete!**

⏱️ **Duration:** $duration minutes
📝 **Quizzes Taken:** $quizzes
✅ **Correct Answers:** $correct
💪 **Engagement Score:** ${(engagement * 100).toStringAsFixed(0)}%
🏆 **Points Earned:** +$pointsEarned

${_getSessionFeedback(engagement)}

Great job today! See you next time! 👋
''';
  }

  /// Get session feedback based on performance
  String _getSessionFeedback(double engagement) {
    if (engagement >= 0.8) {
      return "🌟 Outstanding session! You're making incredible progress!";
    } else if (engagement >= 0.6) {
      return "💪 Great work! You're really engaged and learning well!";
    } else if (engagement >= 0.4) {
      return "👍 Good session! Keep up the steady progress!";
    } else {
      return "🌱 Every step counts! Come back tomorrow to continue learning!";
    }
  }

  /// Get badge details
  Map<String, String> getBadgeDetails(String badgeId) {
    final badges = {
      'first_session': '🎯 First Session - Started your learning journey!',
      'streak_3': '🔥 3 Day Streak - Learning 3 days in a row!',
      'streak_7': '💎 Week Warrior - 7 day learning streak!',
      'points_100': '💯 Century - Earned 100 points!',
      'points_500': '🏆 High Achiever - Earned 500 points!',
      'concepts_10': '🌟 Knowledge Seeker - Mastered 10 concepts!',
      'perfect_quiz': '✨ Perfect Score - Aced a quiz!',
    };
    
    return {
      'name': badges[badgeId]?.split(' - ')[0] ?? badgeId,
      'description': badges[badgeId]?.split(' - ')[1] ?? 'Achievement unlocked!',
    };
  }

  /// Get user analytics
  Map<String, dynamic> getUserAnalytics() {
    final userId = _tutorService.auth.currentUser?.uid;
    if (userId == null) return {};
    
    return _tutorService.getUserAnalytics(userId);
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Validate and optimize response to meet production quality standards
  String _validateAndOptimizeResponse(String response, QueryAnalysis analysis, String originalQuery) {
    _log('Validating response for query: "$originalQuery"', level: LogLevel.debug, context: '_validateAndOptimizeResponse');
    _log('Analysis: ${analysis.responseType.name} response expected', level: LogLevel.debug, context: '_validateAndOptimizeResponse');
    
    // Clean up the response
    String optimized = response.trim();
    
      // Remove common AI padding phrases for simple responses
      if (analysis.responseType == ResponseType.simple) {
        // Remove unhelpful padding phrases
        final paddingPatterns = [
          RegExp(r'^(sure,?\s*|absolutely,?\s*|of course,?\s*)', caseSensitive: false),
          RegExp(r'\s*(i hope this helps|hope this helps|let me know if you need more information).*$', caseSensitive: false),
          RegExp(r'\s*(is there anything else|any other questions|anything else you[^.]*like to know).*$', caseSensitive: false),
          RegExp(r'^(here.s the answer:?\s*|the answer is:?\s*)', caseSensitive: false),
        ];      for (final pattern in paddingPatterns) {
        optimized = optimized.replaceAll(pattern, '').trim();
      }
      
      // Validate token count for simple responses (max 15 tokens)
      final tokenCount = optimized.split(RegExp(r'\s+')).length;
      _log('Token count: $tokenCount (max 15 for simple)', level: LogLevel.debug, context: '_validateAndOptimizeResponse');
      
      if (tokenCount > 15) {
        _log('Response too long! Applying emergency compression...', level: LogLevel.warning, context: '_validateAndOptimizeResponse');
        
        // Emergency compression for over-length responses
        if (analysis.intent == UserIntent.factual) {
          // For factual queries, extract just the core answer
          final sentences = optimized.split(RegExp(r'[.!?]+'));
          if (sentences.isNotEmpty) {
            optimized = sentences.first.trim();
            // Remove leading "The answer is" or similar
            optimized = optimized.replaceAll(RegExp(r'^(the answer is:?\s*|it is:?\s*)', caseSensitive: false), '');
          }
        } else if (analysis.intent == UserIntent.confirmatory) {
          // For confirmation queries, force True/False format
          if (optimized.toLowerCase().contains('true') || optimized.toLowerCase().contains('correct') || optimized.toLowerCase().contains('yes')) {
            optimized = 'True';
          } else if (optimized.toLowerCase().contains('false') || optimized.toLowerCase().contains('incorrect') || optimized.toLowerCase().contains('no')) {
            optimized = 'False';
          }
        }
        
        final newTokenCount = optimized.split(RegExp(r'\s+')).length;
        _log('Compressed to $newTokenCount tokens: "$optimized"', level: LogLevel.info, context: '_validateAndOptimizeResponse');
      }
    }
    
    // Final validation
    if (analysis.responseType == ResponseType.simple && optimized.split(RegExp(r'\s+')).length > 15) {
      _log('EMERGENCY: Still too long, applying brutal compression', level: LogLevel.error, context: '_validateAndOptimizeResponse');
      // Last resort: take first few words only
      final tokens = optimized.split(RegExp(r'\s+'));
      optimized = tokens.take(15).join(' ');
    }
    
    _log('Final response: "$optimized"', level: LogLevel.info, context: '_validateAndOptimizeResponse');
    return optimized;
  }

  /// Reset provider state
  void reset() {
    _messages.clear();
    _currentSession = null;
    _isGenerating = false;
    _error = null;
    _activeQuiz = null;
    _sessionMetrics.clear();
    _showProgress = false;
    _showBadges = false;
    _updateQuickReplies();
    notifyListeners();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }
}
