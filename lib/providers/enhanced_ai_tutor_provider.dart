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
import '../services/ai_tutor_middleware.dart';
import '../services/session_context.dart';
import '../services/user_profile_store.dart';
import '../services/web_search_service.dart';
import '../config/gemini_config.dart';
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
  
  // AI Tutor Middleware components for production-ready validation
  SessionContext? _sessionContext;
  UserProfileStore? _userProfileStore;
  
  // Web search integration for real-time information
  late final WebSearchService _webSearchService;
  String? _userId; // Track current user ID for rate limiting

  EnhancedAITutorProvider(this._tutorService) {
    _instanceCount++;
    _log('EnhancedAITutorProvider instance #$_instanceCount created', level: LogLevel.debug);
    
    // Initialize web search service
    _webSearchService = WebSearchService();
    _webSearchService.initialize();
    print('🌐 DEBUG: WebSearchService initialized. isAvailable=${_webSearchService.isAvailable}, enableWebSearch=${GeminiConfig.enableWebSearch}');
    _log('WebSearchService initialized (enabled: ${GeminiConfig.enableWebSearch})', level: LogLevel.debug);
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
      
      // Initialize AI Tutor Middleware components for production
      // CRITICAL: Initialize for ALL users (including demo/anonymous)
      _userProfileStore = UserProfileStore();
      _log('✅ UserProfileStore initialized', level: LogLevel.info, context: 'initialize');
      
      _updateQuickReplies();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize: $e';
      _log('❌ Initialization error: $e', level: LogLevel.error, context: 'initialize');
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
      
      // Initialize SessionContext for middleware tracking
      _sessionContext = SessionContext(
        userId: userId,
        maxMessages: 100, // Store more context for better memory validation
      );
      // Add existing messages to context if any
      for (final msg in _messages) {
        _sessionContext!.addMessage(msg);
      }
      _log('✅ SessionContext initialized for subject: $_currentSubject with ${_messages.length} existing messages', 
           level: LogLevel.info, context: 'startAdaptiveSession');
      
      // Add system message to show middleware is active
      if (_messages.isEmpty) {
        final systemMessage = ChatMessage(
          id: 'system_${DateTime.now().millisecondsSinceEpoch}',
          content: '''━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ **AI Tutor Middleware ACTIVATED**

Your session now includes:
• 🧠 Memory validation (prevents false claims)
• ➗ Math verification (validates calculations)  
• 📊 Learning style detection (adapts to you)
• 💾 Session context tracking (remembers conversation)

Ask me anything - all responses will be validated!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''',
          type: MessageType.assistant,
          format: MessageFormat.text,
        );
        _messages.add(systemMessage);
      }
      
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
      
      // 🔥 REMOVED DUPLICATE: _messages.add(userMessage)
      // Don't add here - addUserMessage() already adds to _sessionMessages, which _messages references
      
      // ========== CRITICAL: Add to SessionContext for memory tracking ==========
      if (_sessionContext != null) {
        _sessionContext!.addMessage(userMessage);
        _log('📝 Added user message to SessionContext', level: LogLevel.info, context: 'sendMessage');
      }
      
      // 🔥 Add user message to service for Firestore tracking (this also adds to _sessionMessages)
      if (_currentSession != null) {
        _tutorService.addUserMessage(_currentSession!.id, userMessage);
        _log('Added user message via service. Total messages: ${_messages.length}', level: LogLevel.debug, context: 'sendMessage');
      }
      
      _isGenerating = true;
      _quickReplies.clear();
      notifyListeners();
      
      // Store user ID for rate limiting
      _userId = user?.id ?? _tutorService.auth.currentUser?.uid;

      // ========== 🌐 WEB SEARCH INTEGRATION ==========
      // Check if this query needs web search
      final needsWebSearch = _needsWebSearch(content.trim());
      print('🔍 DEBUG: needsWebSearch=$needsWebSearch, isAvailable=${_webSearchService.isAvailable}, query="${content.trim()}"');
      _log('needsWebSearch: $needsWebSearch, isAvailable: ${_webSearchService.isAvailable}', level: LogLevel.info, context: 'sendMessage');
      
      // Generate AI response using the working AI provider or web search
      String rawResponseContent;
      if (needsWebSearch && _webSearchService.isAvailable) {
        print('🌐 DEBUG: Web search TRIGGERED!');
        _log('🔍 Web search triggered for query: "$content"', level: LogLevel.info, context: 'sendMessage');
        
        try {
          // Perform web search with conversation context
          final searchResult = await _webSearchService.search(
            content.trim(),
            conversationContext: _sessionContext?.getContextSummary(),
            userId: _userId,
          );
          
          if (searchResult.hasError) {
            _log('⚠️ Web search failed: ${searchResult.error}', level: LogLevel.warning, context: 'sendMessage');
            // Fallback to local AI
            if (_aiProvider != null && _aiProvider!.isAIEnabled) {
              final prompt = await _buildPromptForContent(content.trim());
              rawResponseContent = await _aiProvider!.aiService.callGoogleAIWithRetry(prompt, 0);
            } else {
              rawResponseContent = searchResult.answer; // Use error message
            }
          } else {
            // Web search successful!
            rawResponseContent = searchResult.answer;
            
            // Add web search attribution
            final attribution = StringBuffer('\n\n');
            attribution.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            attribution.writeln('🌐 **Information Source: Web Search**');
            attribution.writeln('📅 Retrieved: ${_formatDate(searchResult.timestamp)}');
            if (searchResult.fromCache) {
              attribution.writeln('⚡ Cached result (fresh)');
            }
            attribution.writeln();
            attribution.writeln('*Note: This information was gathered from current online sources.');
            attribution.writeln('For academic citations, please verify with primary sources.*');
            attribution.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            
            rawResponseContent += attribution.toString();
            
            _log('✅ Web search successful (${searchResult.fromCache ? "cached" : "fresh"})', level: LogLevel.info, context: 'sendMessage');
          }
        } catch (e) {
          _log('❌ Web search error: $e', level: LogLevel.error, context: 'sendMessage');
          // Fallback to local AI
          if (_aiProvider != null && _aiProvider!.isAIEnabled) {
            final prompt = await _buildPromptForContent(content.trim());
            rawResponseContent = await _aiProvider!.aiService.callGoogleAIWithRetry(prompt, 0);
          } else {
            rawResponseContent = 'I apologize, but I encountered an error. Please try again!';
          }
        }
      } else if (_aiProvider != null && _aiProvider!.isAIEnabled) {
        // Use the working AI service that handles flashcards
        final prompt = await _buildPromptForContent(content.trim());
        
        rawResponseContent = await _aiProvider!.aiService.callGoogleAIWithRetry(prompt, 0);
        _log('🤖 Raw AI response received (${rawResponseContent.length} chars)', level: LogLevel.info, context: 'sendMessage');
      } else {
        rawResponseContent = 'I apologize, but I encountered an error. Please try again!';
      }
      
      // ========== CRITICAL: Process through AI Tutor Middleware ==========
      String finalResponseContent;
      if (_sessionContext != null && _userProfileStore != null) {
        _log('🔄 Processing response through AI Tutor Middleware...', level: LogLevel.info, context: 'sendMessage');
        
        final processedResponse = await AITutorMiddleware.processAIResponse(
          userQuery: content.trim(),
          aiResponse: rawResponseContent,
          sessionContext: _sessionContext!,
          userProfileStore: _userProfileStore!,
        );
        
        finalResponseContent = processedResponse.finalResponse;
        
        // Log all middleware findings
        if (processedResponse.memoryIssues.isNotEmpty) {
          _log('⚠️ MEMORY ISSUES DETECTED:', level: LogLevel.warning, context: 'sendMessage');
          for (final issue in processedResponse.memoryIssues) {
            _log('  - Claim: "${issue.claim}"', level: LogLevel.warning, context: 'sendMessage');
            _log('    Honest Alternative: "${issue.honestAlternative}"', level: LogLevel.warning, context: 'sendMessage');
          }
        } else {
          _log('✅ No false memory claims detected', level: LogLevel.info, context: 'sendMessage');
        }
        
        if (processedResponse.mathIssues.isNotEmpty) {
          _log('⚠️ MATH ISSUES DETECTED:', level: LogLevel.warning, context: 'sendMessage');
          for (final issue in processedResponse.mathIssues) {
            _log('  - Expression: "${issue.expression}" - ${issue.description}', level: LogLevel.warning, context: 'sendMessage');
          }
        } else if (processedResponse.mathValidations.isNotEmpty) {
          _log('✅ Math validated: ${processedResponse.mathValidations.length} expressions checked', level: LogLevel.info, context: 'sendMessage');
        }
        
        if (processedResponse.detectedLearningStyle != null) {
          final style = processedResponse.detectedLearningStyle!;
          final dominant = style.preferences.getDominantStyle();
          _log('📊 Learning Style Detected: $dominant (confidence: ${style.confidence.toStringAsFixed(2)})', level: LogLevel.info, context: 'sendMessage');
          _log('  - Visual: ${style.preferences.visual.toStringAsFixed(2)}', level: LogLevel.info, context: 'sendMessage');
          _log('  - Auditory: ${style.preferences.auditory.toStringAsFixed(2)}', level: LogLevel.info, context: 'sendMessage');
          _log('  - Kinesthetic: ${style.preferences.kinesthetic.toStringAsFixed(2)}', level: LogLevel.info, context: 'sendMessage');
          _log('  - Reading: ${style.preferences.reading.toStringAsFixed(2)}', level: LogLevel.info, context: 'sendMessage');
        }
        
        _log('✅ Middleware processing complete', level: LogLevel.info, context: 'sendMessage');
        
        // ========== ADD VISIBLE STATUS BADGES TO RESPONSE ==========
        final statusBadges = StringBuffer();
        statusBadges.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        statusBadges.writeln('🔍 **AI Tutor Validation Status:**');
        statusBadges.writeln();
        
        if (processedResponse.memoryIssues.isEmpty) {
          statusBadges.writeln('✅ Memory Check: PASSED');
        } else {
          statusBadges.writeln('⚠️ Memory Check: ${processedResponse.memoryIssues.length} issue(s) detected');
        }
        
        if (processedResponse.mathIssues.isEmpty && processedResponse.mathValidations.isNotEmpty) {
          statusBadges.writeln('✅ Math Validation: ${processedResponse.mathValidations.length} expression(s) verified');
        } else if (processedResponse.mathIssues.isNotEmpty) {
          statusBadges.writeln('⚠️ Math Check: ${processedResponse.mathIssues.length} issue(s) found');
        } else {
          statusBadges.writeln('ℹ️ Math Check: No math expressions found');
        }
        
        if (processedResponse.detectedLearningStyle != null) {
          final style = processedResponse.detectedLearningStyle!;
          final dominant = style.preferences.getDominantStyle();
          statusBadges.writeln('📊 Learning Style: $dominant (${(style.confidence * 100).toStringAsFixed(0)}% confidence)');
        } else {
          statusBadges.writeln('ℹ️ Learning Style: Analyzing...');
        }
        
        statusBadges.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        statusBadges.writeln();
        
        // Prepend status badges to response
        finalResponseContent = statusBadges.toString() + finalResponseContent;
        
      } else {
        // Fallback: No middleware available
        _log('⚠️ SessionContext or UserProfileStore not available, skipping middleware', level: LogLevel.warning, context: 'sendMessage');
        final analysis = _performQueryAnalysis(content.trim());
        finalResponseContent = _validateAndOptimizeResponse(rawResponseContent, analysis, content.trim());
        
        // Add warning badge when middleware is not available
        final warningBadge = StringBuffer();
        warningBadge.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        warningBadge.writeln('⚠️ **AI Tutor Middleware: NOT ACTIVE**');
        warningBadge.writeln('Session not initialized. Start a new session to enable validation.');
        warningBadge.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        warningBadge.writeln();
        finalResponseContent = warningBadge.toString() + finalResponseContent;
      }
      
      final aiResponse = ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: finalResponseContent,
        type: MessageType.assistant,
        format: MessageFormat.text,
      );

      _messages.add(aiResponse);
      _log('Added AI response to list. Total messages: ${_messages.length}', level: LogLevel.debug, context: 'sendMessage');
      
      // ========== CRITICAL: Add AI response to SessionContext ==========
      if (_sessionContext != null) {
        _sessionContext!.addMessage(aiResponse);
        _log('📝 Added AI response to SessionContext', level: LogLevel.info, context: 'sendMessage');
      }
      
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
      _log('❌ Error in sendMessage: $e', level: LogLevel.error, context: 'sendMessage');
      
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
  Future<String> _buildPromptForContent(String content) async {
    // Perform comprehensive query analysis
    final analysis = _performQueryAnalysis(content);
    _log('Query Analysis: ${analysis.toString()}', level: LogLevel.debug, context: 'sendMessage');
    
    // Check for simple math first (legacy support)
    if (_isSimpleMathProblem(content)) {
      _log('Using simple math prompt', level: LogLevel.debug, context: 'sendMessage');
      return _buildSimpleMathPrompt(content);
    }
    
    // Build sophisticated prompt based on analysis
    return await _buildAdaptivePrompt(content, analysis);
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
  Future<String> _buildAdaptivePrompt(String content, QueryAnalysis analysis) async {
    // Update conversation context
    _updateConversationContext(analysis);
    
    final subjectContext = _getSubjectContext(analysis.subject);
    final complexityGuidance = _getComplexityGuidance(analysis.complexity);
    final approachStrategy = _getApproachStrategy(analysis.learningApproach);
    final responseStructure = _getResponseStructure(analysis.responseType);
    final contextualGuidance = _getContextualGuidance();
    final pedagogicalTechniques = _getPedagogicalTechniques(analysis.intent, analysis.complexity);
    
    // 🔥 CHATGPT-LEVEL CONTEXT AWARENESS: Include full conversation history
    final conversationHistory = await _buildConversationHistoryAsync();
    
    // 🎯 SEMANTIC SEARCH: Find relevant past discussions for memory/recall queries
    final relevantContext = _buildRelevantContext(content, analysis);
    
    return '''You are a world-class AI tutor specializing in $subjectContext. 

$conversationHistory

$relevantContext

═══════════════════════════════════════════════════════
🎯 CURRENT STUDENT QUERY: "$content"
═══════════════════════════════════════════════════════

QUERY ANALYSIS:
- Subject: ${analysis.subject.name}
- Complexity: ${analysis.complexity.name}
- Intent: ${analysis.intent.name}
- Learning Style: ${analysis.learningApproach.name}
- Question Type: ${analysis.questionType}
- Keywords: ${analysis.keywords.join(', ')}

SESSION INSIGHTS:
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
- Build upon established knowledge from this conversation
- Reference previous topics/preferences when relevant
- Maintain student engagement
- Encourage active learning
- Provide accurate, verified information

═══════════════════════════════════════════════════════
🚨 CRITICAL MEMORY RETRIEVAL INSTRUCTIONS 🚨
═══════════════════════════════════════════════════════

⚠️ BEFORE RESPONDING, YOU MUST:

1. READ the "📋 CONVERSATION HISTORY" section above CAREFULLY
2. READ the "🔑 KEY FACTS FROM CONVERSATION" section if present
3. READ the "RELEVANT PAST CONTEXT" section if present

If the student asks about something they mentioned earlier:
✅ ALWAYS check these sections FIRST before saying "I don't know"
✅ If you find the information above, USE IT in your answer
✅ Quote or reference what the student actually said
✅ DO NOT say "I don't have a record" if the info appears above
✅ DO NOT say "I have no information" if it's in the conversation history

Example correct responses:
- "Based on what you told me earlier, [specific fact]"
- "You mentioned that [exact quote from history]"
- "From our conversation, I see that [reference to key fact]"

Example WRONG responses (DO NOT USE):
- "I don't have that information" (when it's in the history!)
- "I have no record of us discussing..." (when we DID discuss it!)
- "I don't recall..." (when it's clearly written above!)

THE WORLD DEPENDS ON YOUR ACCURACY. READ THE CONTEXT CAREFULLY.

Deliver a response that rivals the best AI tutors like ChatGPT, Claude, and Gemini.''';
  }

  /// 🎯 Build relevant context section for memory/topic-based queries
  String _buildRelevantContext(String query, QueryAnalysis analysis) {
    // Check if this is a memory/recall query
    final isMemoryQuery = query.toLowerCase().contains(RegExp(
      r'(remember|recall|favorite|told you|mentioned|discussed|we talked|you said|i said|preference|name|what|who)',
      caseSensitive: false
    ));
    
    if (!isMemoryQuery) {
      return ''; // No need for semantic search
    }
    
    // Find semantically relevant past messages
    final relevantMessages = _findRelevantPastMessages(query, maxResults: 5);
    
    if (relevantMessages.isEmpty) {
      return '';
    }
    
    final contextBuilder = StringBuffer('\n═══════════════════════════════════════════════════════\n');
    contextBuilder.writeln('🎯 RELEVANT PAST CONTEXT (ANSWER IS HERE!)');
    contextBuilder.writeln('═══════════════════════════════════════════════════════');
    contextBuilder.writeln('⚠️ These messages are HIGHLY RELEVANT to the current query!');
    contextBuilder.writeln('⚠️ The answer is PROBABLY in one of these messages below!');
    contextBuilder.writeln();
    
    for (var i = 0; i < relevantMessages.length; i++) {
      final msg = relevantMessages[i];
      final role = msg.type == MessageType.user ? '👤 STUDENT' : '🤖 AI';
      final timestamp = _formatTimestamp(msg.timestamp);
      
      contextBuilder.write('🔍 [$role - $timestamp]: ');
      contextBuilder.writeln(msg.content);
      contextBuilder.writeln();
    }
    
    contextBuilder.writeln('═══════════════════════════════════════════════════════');
    
    return contextBuilder.toString().trim();
  }

  /// 🚀 Build ChatGPT-style conversation history for context
  Future<String> _buildConversationHistoryAsync() async {
    if (_sessionContext == null) {
      return 'CONVERSATION HISTORY:\n(No prior messages in this session)';
    }
    
    final messages = _sessionContext!.getAllMessages();
    
    // 🔥 NEW: Check for recent session history (loaded at session start)
    final recentSessionsData = _currentSession != null 
        ? _tutorService.getRecentSessionsData(_currentSession!.id)
        : null;
    final hasPastSessions = recentSessionsData != null && recentSessionsData.isNotEmpty;
    
    // 🔥 NEW: Load actual past session messages
    List<ChatMessage> pastMessages = [];
    if (hasPastSessions && _currentSession != null) {
      try {
        pastMessages = await _tutorService.getPastSessionMessages(_currentSession!.id);
      } catch (e) {
        _log('⚠️ Could not load past messages: $e', level: LogLevel.warning, context: '_buildConversationHistory');
      }
    }
    
    if (messages.isEmpty && pastMessages.isEmpty && !hasPastSessions) {
      return 'CONVERSATION HISTORY:\n(No prior messages in this session)';
    }
    
    // Get recent messages (last 20 for context, similar to ChatGPT's approach)
    final recentMessages = messages.length > 20 
        ? messages.sublist(messages.length - 20) 
        : messages;
    
    final historyBuilder = StringBuffer('═══════════════════════════════════════════════════════\n');
    historyBuilder.writeln('📋 CONVERSATION HISTORY (READ THIS CAREFULLY!)');
    historyBuilder.writeln('═══════════════════════════════════════════════════════');
    
    // 🔥 NEW: Add cross-session context if available
    if (hasPastSessions) {
      final lastSession = recentSessionsData.first;
      final daysSinceLastSession = DateTime.now().difference(lastSession['startTime'] as DateTime).inDays;
      
      historyBuilder.writeln('🕐 PAST SESSIONS AVAILABLE:');
      historyBuilder.writeln('   Last session: ${lastSession['subject']} - $daysSinceLastSession day(s) ago');
      historyBuilder.writeln('   Total recent sessions: ${recentSessionsData.length}');
      historyBuilder.writeln('   Past messages loaded: ${pastMessages.length}');
      historyBuilder.writeln();
      historyBuilder.writeln('⚠️ IMPORTANT: When user asks about "yesterday" or past discussions,');
      historyBuilder.writeln('   reference these past sessions with actual message history below!');
      historyBuilder.writeln();
    }
    
    // 🔥 NEW: Include past session messages if available
    if (pastMessages.isNotEmpty) {
      historyBuilder.writeln('════════════ PAST SESSION MESSAGES (LAST 7 DAYS) ════════════');
      historyBuilder.writeln('⚠️ READ THESE CAREFULLY - They contain context from previous days!');
      historyBuilder.writeln();
      
      for (var i = 0; i < pastMessages.length; i++) {
        final msg = pastMessages[i];
        final role = msg.type == MessageType.user ? '👤 STUDENT' : '🤖 AI';
        final timestamp = _formatTimestamp(msg.timestamp);
        
        historyBuilder.write('[PAST - $role${timestamp.isNotEmpty ? " - $timestamp" : ""}]: ');
        historyBuilder.writeln(msg.content);
        historyBuilder.writeln();
      }
      
      historyBuilder.writeln('════════════ END OF PAST SESSION MESSAGES ════════════');
      historyBuilder.writeln();
    }
    
    historyBuilder.writeln('════════════ CURRENT SESSION MESSAGES ════════════');
    historyBuilder.writeln('Showing ${recentMessages.length} most recent messages from ${messages.length} total in current session');
    historyBuilder.writeln();
    
    for (var i = 0; i < recentMessages.length; i++) {
      final msg = recentMessages[i];
      final role = msg.type == MessageType.user ? '👤 STUDENT' : '🤖 AI';
      final timestamp = _formatTimestamp(msg.timestamp);
      
      historyBuilder.write('[$role${timestamp.isNotEmpty ? " - $timestamp" : ""}]: ');
      historyBuilder.writeln(msg.content);
      historyBuilder.writeln(); // Add spacing for readability
    }
    
    // 🔥 EXTRACT KEY FACTS - Make them impossible to miss!
    // Combine current + past messages for fact extraction
    final allMessagesForFacts = [...pastMessages, ...messages];
    final keyFacts = _extractKeyFacts(allMessagesForFacts);
    if (keyFacts.isNotEmpty) {
      historyBuilder.writeln('═══════════════════════════════════════════════════════');
      historyBuilder.writeln('🔑 KEY FACTS FROM ALL CONVERSATIONS (MEMORIZE THESE!):');
      historyBuilder.writeln('═══════════════════════════════════════════════════════');
      for (var i = 0; i < keyFacts.length; i++) {
        historyBuilder.writeln('${i + 1}. ${keyFacts[i]}');
      }
      historyBuilder.writeln();
    }
    
    // Add topic summary if available
    final topics = _sessionContext!.getRecentTopics(topK: 5);
    if (topics.isNotEmpty) {
      final topicNames = topics.map((t) => '${t.topic} (×${t.mentionCount})').toList();
      historyBuilder.writeln('📊 KEY TOPICS: ${topicNames.join(' • ')}');
    }
    
    historyBuilder.writeln('═══════════════════════════════════════════════════════');
    
    return historyBuilder.toString().trim();
  }

  /// 🔑 Extract key facts from conversation that must be remembered
  List<String> _extractKeyFacts(List<ChatMessage> messages) {
    final facts = <String>[];
    
    // Patterns that indicate important facts (focusing on proper nouns and specific information)
    final factPatterns = [
      // "X is Y" statements (but require capitalized X for proper nouns)
      RegExp(r'([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)\s+is\s+(.+?)(?:\.|,|;|$)', caseSensitive: true),
      
      // "My name is Y" or "I'm studying X" - user preferences
      RegExp(r'my\s+name\s+(?:is|was)\s+([A-Z][a-zA-Z]+)', caseSensitive: true),
      RegExp(r"i(?:'m|\s+am)\s+studying\s+([a-z][a-zA-Z\s]+?)(?:\.|,|;|$)", caseSensitive: false),
      RegExp(r"i(?:'m|\s+am)\s+interested\s+in\s+([a-z][a-zA-Z\s]+?)(?:\.|,|;|$)", caseSensitive: false),
      
      // Subject/Topic mentions (multi-word topics like "quadratic equations")
      RegExp(r'(?:about|studying|learning|topic|subject)\s+(?:is\s+)?([a-z][a-zA-Z\s]{3,30}?)(?:\.|,|;|$)', caseSensitive: false),
      
      // Numerical facts (e.g., "speed of light is 3x10^8")
      RegExp(r'([a-z][a-zA-Z\s]+?)\s+(?:is|equals?|=)\s+([0-9][0-9\.\^\*\+\-\/x×÷±√∞πe\s]+)(?:\.|,|;|$)', caseSensitive: false),
      
      // Institution/Organization names (capitalize first letter)
      RegExp(r'(?:at|from|university|college|school)\s+([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)', caseSensitive: true),
    ];
    
    // Exclude common words that shouldn't be facts
    final excludeWords = {
      'help', 'check', 'learning', 'confidence', 'validation', 'memory',
      'mathematics', 'math', 'studying', 'hello', 'good', 'great', 'sure',
      'okay', 'thanks', 'please', 'question', 'answer', 'example',
    };
    
    for (final msg in messages) {
      if (msg.type != MessageType.user) continue;
      
      final content = msg.content;
      
      // Extract using patterns
      for (final pattern in factPatterns) {
        final matches = pattern.allMatches(content);
        for (final match in matches) {
          if (match.groupCount >= 1) {
            // Clean and add the fact
            final fact = match.group(0)?.trim();
            if (fact != null && fact.length > 5 && fact.length < 150) {
              // Skip if it's just a common word
              final factLower = fact.toLowerCase();
              final shouldExclude = excludeWords.any((word) => factLower.contains(word));
              if (!shouldExclude) {
                facts.add(fact);
              }
            }
          }
        }
      }
    }
    
    // Deduplicate and limit to most recent 10 facts
    final uniqueFacts = facts.toSet().toList();
    return uniqueFacts.length > 10 
        ? uniqueFacts.sublist(uniqueFacts.length - 10)
        : uniqueFacts;
  }

  /// 🎯 Find semantically relevant past messages for current query
  List<ChatMessage> _findRelevantPastMessages(String query, {int maxResults = 5}) {
    if (_sessionContext == null) return [];
    
    final allMessages = _sessionContext!.getAllMessages();
    if (allMessages.isEmpty) return [];
    
    // Extract keywords from current query (preserve capitalization for proper nouns!)
    final queryKeywords = _extractRelevantKeywords(query.toLowerCase());
    final properNouns = _extractProperNouns(query); // NEW: Detect names like "Reginald"
    
    if (queryKeywords.isEmpty && properNouns.isEmpty) return [];
    
    // Score each message by keyword overlap
    final scoredMessages = <Map<String, dynamic>>[];
    
    for (final message in allMessages) {
      final contentLower = message.content.toLowerCase();
      final contentOriginal = message.content;
      var score = 0.0;
      
      // Score regular keywords
      for (final keyword in queryKeywords) {
        if (contentLower.contains(keyword)) {
          score += 1.0;
          // Bonus for exact keyword match vs partial
          if (contentLower.split(RegExp(r'\W+')).contains(keyword)) {
            score += 0.5;
          }
        }
      }
      
      // Score proper nouns (case-sensitive, higher weight!)
      for (final properNoun in properNouns) {
        if (contentOriginal.contains(properNoun)) {
          score += 5.0; // 🔥 MUCH higher weight for proper nouns (names, etc.)
        } else if (contentLower.contains(properNoun.toLowerCase())) {
          score += 2.0; // Still good even if case doesn't match
        }
      }
      
      // Recency bonus (prefer recent messages)
      final age = DateTime.now().difference(message.timestamp).inMinutes;
      final recencyBonus = 1.0 / (1.0 + age / 60.0); // Decay over hours
      score += recencyBonus * 0.3;
      
      // Bonus for user messages (more likely to contain facts)
      if (message.type == MessageType.user) {
        score += 0.5;
      }
      
      if (score > 0) {
        scoredMessages.add({
          'message': message,
          'score': score,
        });
      }
    }
    
    // Sort by score and take top results
    scoredMessages.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    return scoredMessages
        .take(maxResults)
        .map((m) => m['message'] as ChatMessage)
        .toList();
  }

  /// 🔍 Extract proper nouns (capitalized words) that are likely names
  List<String> _extractProperNouns(String text) {
    final properNouns = <String>[];
    
    // Split into words and find capitalized ones (but not first word of sentence)
    final words = text.split(RegExp(r'\s+'));
    
    for (var i = 0; i < words.length; i++) {
      final word = words[i].replaceAll(RegExp(r'[^\w]'), ''); // Remove punctuation
      
      // Must be capitalized, > 2 chars, and not a common word
      if (word.length > 2 && word[0] == word[0].toUpperCase()) {
        // Skip if it's the first word of a sentence (might just be capitalized)
        final isFirstWord = i == 0 || (i > 0 && words[i - 1].endsWith('.'));
        
        // Common capitalized words to skip
        final commonWords = {'The', 'I', 'My', 'What', 'When', 'Where', 'Who', 'Why', 'How', 'Can', 'Could', 'Would', 'Should'};
        
        if (!isFirstWord || !commonWords.contains(word)) {
          properNouns.add(word);
        }
      }
    }
    
    return properNouns;
  }

  /// Extract meaningful keywords for semantic search
  List<String> _extractRelevantKeywords(String text) {
    final stopWords = {
      // Basic stop words
      'the', 'a', 'an', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for',
      'of', 'with', 'by', 'from', 'as', 'is', 'was', 'are', 'were', 'be',
      'been', 'being', 'have', 'has', 'had', 'do', 'does', 'did', 'will',
      'would', 'should', 'could', 'may', 'might', 'must', 'can', 'what',
      'which', 'who', 'when', 'where', 'why', 'how', 'this', 'that',
      
      // 🔥 NEW: Exclude generic teaching/help words (prevent "check", "help", "learning" extraction)
      'help', 'check', 'learning', 'study', 'understand', 'explain', 'show',
      'tell', 'give', 'make', 'get', 'see', 'know', 'think', 'want', 'need',
      'like', 'use', 'work', 'try', 'ask', 'answer', 'question', 'problem',
      'example', 'practice', 'test', 'quiz', 'lesson', 'topic', 'subject',
      
      // Exclude middleware/validation terms
      'confidence', 'validation', 'badge', 'memory', 'passed', 'failed',
      'detected', 'style', 'mode', 'level', 'score', 'result', 'status',
      
      // Exclude generic words that appear in every conversation
      'please', 'thanks', 'okay', 'yes', 'yeah', 'sure', 'right', 'well',
      'just', 'also', 'even', 'still', 'now', 'then', 'here', 'there',
      'some', 'any', 'all', 'both', 'each', 'every', 'other', 'such',
    };
    
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => 
            word.length > 2 && 
            !stopWords.contains(word) &&
            // 🔥 NEW: Only keep words with meaningful characters (exclude pure numbers unless part of expression)
            RegExp(r'[a-z]').hasMatch(word)
        )
        .toList();
    
    return words.toSet().toList();
  }

  /// 🌐 Detect if a query needs web search
  bool _needsWebSearch(String query) {
    final queryLower = query.toLowerCase();
    
    // Patterns that indicate need for current/factual information
    final searchIndicators = [
      // Question words about real-world facts
      r'who is\b',
      r'what is the name',
      r'where is\b',
      r'when did\b',
      r'when was\b',
      
      // Current/recent information requests
      r'\bcurrent\b',
      r'\blatest\b',
      r'\btoday\b',
      r'\bnow\b',
      r'\brecent\b',
      r'\bthis year\b',
      r'\bthis month\b',
      
      // Educational institutions (like Full Sail example)
      r'\buniversity\b',
      r'\bcollege\b',
      r'\bschool\b',
      r'\bprofessor\b',
      r'\bteacher\b',
      r'\binstructor\b',
      r'\bcourse\b',
      
      // Real-time data
      r'\bweather\b',
      r'\bnews\b',
      r'\bstock\b',
      r'\bprice\b',
      r'\brate\b',
      
      // Specific factual queries
      r'works for\b',
      r'employed by\b',
      r'located at\b',
      r'teaches\b',
    ];
    
    for (final pattern in searchIndicators) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(queryLower)) {
        _log('Web search indicator detected: "$pattern" in query', level: LogLevel.debug, context: '_needsWebSearch');
        return true;
      }
    }
    
    // Don't use web search for conversational/teaching queries
    final conversationalIndicators = [
      r'^(can you |could you |will you |would you )(help|explain|teach|show)',
      r'^how (do|does|can|to)\b',
      r'^(what|why) (is|are|does|do|did|would|should)',
      r'(practice|quiz|test|example|problem)',
      r'(understand|confused|clarify)',
    ];
    
    for (final pattern in conversationalIndicators) {
      if (RegExp(pattern, caseSensitive: false).hasMatch(queryLower)) {
        // These are teaching requests, not factual lookups
        return false;
      }
    }
    
    return false;
  }

  /// Format date for web search attribution
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format timestamp for conversation history
  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
    
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
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
      
      // 🔥 REMOVED DUPLICATE: _messages.add(userMessage)
      // Don't add here - addUserMessage() already adds to _sessionMessages, which _messages references
      
      // 🔥 Add user message to service for Firestore tracking (this also adds to _sessionMessages)
      _tutorService.addUserMessage(_currentSession!.id, userMessage);
      
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
