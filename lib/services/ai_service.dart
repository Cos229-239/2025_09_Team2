import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:studypals/models/card.dart';
import 'package:studypals/models/user.dart';
import 'package:studypals/models/study_analytics.dart';
import 'package:studypals/services/multimodal_error_handler.dart';

/// AI Provider types
enum AIProvider { openai, google, anthropic, localModel, ollama }

/// AI Service for intelligent study features
/// 
/// TODO: CRITICAL AI SERVICE IMPLEMENTATION GAPS
/// - Need to implement proper API key management and secure storage
/// - Add comprehensive error handling and retry logic for all AI providers
/// - Implement token counting and rate limiting to prevent API quota exhaustion
/// - Add response validation and content filtering for inappropriate AI outputs
/// - Need to implement proper caching system for AI responses to reduce costs
/// - Add support for streaming responses for better user experience
/// - Implement fallback mechanisms when primary AI provider is unavailable
/// - Need proper prompt engineering validation and injection attack prevention
/// - Add comprehensive logging and monitoring for AI service usage
/// - Implement cost tracking and budget management for AI API calls
/// - Need to add user consent and privacy handling for AI-generated content
/// - Add support for custom fine-tuned models and domain-specific prompts
class AIService {
  // Model constants for different AI capabilities
  static const String _textModel = 'gemini-2.0-flash';  // Your current text model
  static const String _imageModel = 'gemini-2.5-flash-image-preview';  // New image model
  
  AIProvider _provider = AIProvider.google;
  String _apiKey = '';
  String _baseUrl = '';

  /// Configure the AI service with provider and API key
  /// 
  /// TODO: SECURITY AND CONFIGURATION IMPROVEMENTS NEEDED
  /// - Implement secure API key storage using Flutter Secure Storage
  /// - Add API key validation and format checking for each provider
  /// - Need environment-specific configuration management (dev/prod)
  /// - Add connection testing and health checks during configuration
  /// - Implement proper error handling for invalid configurations
  /// - Add support for dynamic provider switching based on availability
  /// - Need rate limiting configuration per provider
  /// - Add audit logging for configuration changes
  void configure({
    required AIProvider provider,
    required String apiKey,
    String? customBaseUrl,
  }) {
    _provider = provider;
    _apiKey = apiKey;

    switch (provider) {
      case AIProvider.openai:
        _baseUrl = 'https://api.openai.com/v1';
        break;
      case AIProvider.google:
        _baseUrl = 'https://generativelanguage.googleapis.com/v1beta';
        break;
      case AIProvider.anthropic:
        _baseUrl = 'https://api.anthropic.com/v1';
        break;
      case AIProvider.ollama:
        _baseUrl = customBaseUrl ?? 'http://localhost:11434/api';
        break;
      case AIProvider.localModel:
        _baseUrl = customBaseUrl ?? 'http://localhost:8000';
        break;
    }
  }

  /// Check if AI service is properly configured
  bool get isConfigured => _apiKey.isNotEmpty && _baseUrl.isNotEmpty;

  /// Generate personalized flashcards from study text
  /// 
  /// NOW ENHANCED WITH FULL PERSONALIZATION:
  /// - Uses User model for learning style adaptation (visual/auditory/kinesthetic/reading)
  /// - Adapts difficulty based on user preferences and performance
  /// - Considers user's educational background (school/major) for context
  /// - Personalizes question types based on user preferences
  /// - Integrates with user study schedule and preferences
  /// - Adapts content format based on user's preferred learning approach
  /// 
  /// TODO: FUTURE ENHANCEMENTS
  /// - Add support for image-based flashcards and multimedia content
  /// - Implement spaced repetition algorithm integration for optimal timing
  /// - Add content moderation and appropriateness checking
  /// - Enhanced duplicate detection and question quality scoring
  Future<List<FlashCard>> generateFlashcardsFromText(
      String content, String subject, User user,
      {int count = 5, StudyAnalytics? analytics}) async {
    // Add overall timeout for the entire generation process
    try {
      return await _performFlashcardGeneration(content, subject, user, count: count, analytics: analytics)
          .timeout(const Duration(seconds: 60));
    } catch (e) {
      debugPrint('Flashcard generation timeout or error: $e');
      return _createFallbackFlashcards(subject, content, count: count, user: user);
    }
  }

  /// Generate flashcards with dual model approach:
  /// - Uses gemini-2.0-flash for text generation
  /// - PRIMARY: Uses gemini-2.5-flash-image-preview for image generation
  /// - FALLBACK: Uses existing JSON-based interactive diagram system if image generation fails
  /// This is the recommended method for visual learners
  Future<List<FlashCard>> generateFlashcardsWithDualModels(
    String content,
    String subject,
    User user, {
    int count = 5,
    StudyAnalytics? analytics,
  }) async {
    debugPrint('=== Dual Model Flashcard Generation ===');
    debugPrint('Text Model: $_textModel');
    debugPrint('Image Model: $_imageModel');
    debugPrint('Learning Style: ${user.preferences.learningStyle}');
    
    try {
      // Step 1: Generate text content using gemini-2.0-flash
      final textCards = await generateFlashcardsFromText(
        content,
        subject,
        user,
        count: count,
        analytics: analytics,
      );
      
      debugPrint('Generated ${textCards.length} text cards');
      
      // Step 2: Enhance with visual content for visual/adaptive learners
      if (user.preferences.learningStyle == 'visual' || 
          user.preferences.learningStyle == 'adaptive') {
        final visualCards = await _enhanceWithVisualContent(textCards, subject, user);
        debugPrint('Enhanced cards with visual content using $_imageModel');
        return visualCards;
      }
      
      // Step 3: For non-visual learners, just add proper metadata
      final cardsWithMetadata = textCards.map((card) {
        final metadata = <String, String>{
          'textModel': _textModel,
          'hasAIGeneratedImage': 'false',
          'subject': subject,
          'learningStyle': user.preferences.learningStyle,
        };
        
        return FlashCard(
          id: card.id,
          deckId: card.deckId,
          type: card.type,
          front: card.front,
          back: card.back,
          difficulty: card.difficulty,
          multipleChoiceOptions: card.multipleChoiceOptions,
          correctAnswerIndex: card.correctAnswerIndex,
          lastQuizAttempt: card.lastQuizAttempt,
          lastQuizCorrect: card.lastQuizCorrect,
          imageUrl: card.imageUrl,
          diagramData: card.diagramData,
          visualMetadata: metadata,
        );
      }).toList();
      
      return cardsWithMetadata;
    } catch (e) {
      debugPrint('Dual model generation error: $e');
      return _createFallbackFlashcards(subject, content, count: count, user: user);
    }
  }

  Future<List<FlashCard>> _performFlashcardGeneration(
      String content, String subject, User user,
      {int count = 5, StudyAnalytics? analytics}) async {
    debugPrint('=== AI Flashcard Generation Debug ===');
    debugPrint('Provider: $_provider');
    debugPrint('API Key configured: ${_apiKey.isNotEmpty}');
    debugPrint('Base URL: $_baseUrl');
    debugPrint('Is configured: $isConfigured');
    debugPrint('Content: $content');
    debugPrint('Subject: $subject');
    debugPrint('Count: $count');

    if (!isConfigured) {
      debugPrint('ERROR: AI service not configured!');
      return _createFallbackFlashcards(subject, content, count: count, user: user);
    }

    try {
      final prompt = _generatePersonalizedPrompt(content, subject, user, count, analytics: analytics);

      debugPrint('Sending prompt to AI...');
      final response = await _callAI(prompt);
      debugPrint('Raw AI response: $response');

      // Clean the response to extract JSON
      String cleanResponse = response.trim();

      // Find JSON array in the response
      int startIndex = cleanResponse.indexOf('[');
      int endIndex = cleanResponse.lastIndexOf(']');

      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      } else {
        // If no complete JSON array found, try to repair truncated JSON
        if (startIndex != -1) {
          // Extract from start to end of string and try to repair
          cleanResponse = cleanResponse.substring(startIndex);
          cleanResponse = _repairTruncatedJSON(cleanResponse);
        }
      }

      debugPrint('Cleaned response: $cleanResponse');

      // Parse JSON with error handling
      List cardsData;
      try {
        cardsData = json.decode(cleanResponse) as List;
      } catch (e) {
        debugPrint('JSON parsing failed: $e');
        debugPrint('Attempting to repair JSON...');

        // Try to repair the JSON and parse again
        final repairedJSON = _repairTruncatedJSON(cleanResponse);
        debugPrint('Repaired JSON: $repairedJSON');

        try {
          cardsData = json.decode(repairedJSON) as List;
        } catch (e2) {
          debugPrint('JSON repair failed: $e2');
          debugPrint('Raw response might not be valid JSON');
          throw Exception('Failed to parse AI response as JSON');
        }
      }

      debugPrint('Parsed ${cardsData.length} cards from AI response');

      // Generate multi-modal content for each card
      List<FlashCard> generatedCards = [];
      
      for (int i = 0; i < cardsData.length; i++) {
        final cardJson = cardsData[i];
        
        // Create base flashcard
        final baseCard = FlashCard(
          id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
          deckId: 'ai_generated',
          type: _parseCardType(cardJson['cardType']),
          front: cardJson['question'] ?? 'Question',
          back: _buildPersonalizedAnswer(cardJson, user),
          clozeMask: cardJson['clozeMask'],
          multipleChoiceOptions: List<String>.from(
            cardJson['multipleChoiceOptions'] ??
                [
                  cardJson['answer'] ?? 'Answer',
                  'Option B',
                  'Option C',
                  'Option D'
                ],
          ),
          correctAnswerIndex: cardJson['correctAnswerIndex'] ?? 0,
          difficulty: cardJson['difficulty'] ?? 3,
        );

        // Generate multi-modal content based on user preferences
        FlashCard enhancedCard = await _generateMultiModalContent(
          baseCard,
          subject,
          user,
          content,
        );

        generatedCards.add(enhancedCard);
      }

      // If we didn't get enough cards, supplement with fallback cards
      if (generatedCards.length < count) {
        debugPrint(
            'Generated ${generatedCards.length} cards (expected $count)');
        final shortfall = count - generatedCards.length;
        debugPrint('Creating $shortfall additional fallback cards');

        final fallbackCards =
            _createFallbackFlashcards(subject, content, count: shortfall, user: user);
        generatedCards.addAll(fallbackCards);

        debugPrint('Final card count: ${generatedCards.length}');
      }

      return generatedCards;
    } catch (e) {
      debugPrint('AI flashcard generation error: $e');
      debugPrint('Raw response might not be valid JSON');
      return _createFallbackFlashcards(subject, content, count: count, user: user);
    }
  }

  /// Generate personalized prompt based on user preferences and learning style
  String _generatePersonalizedPrompt(String content, String subject, User user, int count, {StudyAnalytics? analytics}) {
    final prefs = user.preferences;
    final learningStyle = prefs.learningStyle;
    final difficultyPref = prefs.difficultyPreference;
    final showHints = prefs.showHints;
    
    // Build comprehensive personalization context (14+ layers)
    String personalContext = _buildPersonalizationContext(user, analytics);
    String learningStyleInstructions = _getLearningStyleInstructions(learningStyle);
    String difficultyInstructions = _getDifficultyInstructions(difficultyPref, subject, analytics);
    String questionTypeInstructions = _getQuestionTypeInstructions(user);
    String performanceContext = _buildPerformanceContext(subject, analytics);
    String multiModalInstructions = _getMultiModalInstructions(user);
    String contextualInstructions = _getContextualInstructions(user);
    String timeBasedInstructions = _getTimeBasedInstructions(user);
    String analyticsInstructions = _getAnalyticsBasedInstructions(user, analytics, subject);
    
    return '''
PERSONALIZED FLASHCARD GENERATION FOR ${user.name.toUpperCase()}

User Profile Context:
$personalContext

Learning Style Adaptation:
$learningStyleInstructions

Difficulty Preference:
$difficultyInstructions
$performanceContext

$multiModalInstructions

$contextualInstructions

$timeBasedInstructions

$analyticsInstructions

Create exactly $count flashcards about $subject. Topic: $content

$questionTypeInstructions

CRITICAL: You MUST create exactly $count flashcards. No more, no less.

You MUST respond with ONLY a valid JSON array containing exactly $count objects. No explanation, no extra text.

Format:
[
  {
    "cardType": "basic",
    "question": "What is...", 
    "answer": "The answer is...",
    "multipleChoiceOptions": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswerIndex": 2,
    "difficulty": 3,
    "clozeMask": null${showHints ? ',\n    "explanation": "Additional explanation or context"' : ''}
  },
  {
    "cardType": "cloze",
    "question": "The process of {{c1::photosynthesis}} converts light into energy",
    "answer": "photosynthesis",
    "multipleChoiceOptions": ["respiration", "photosynthesis", "transpiration", "digestion"],
    "correctAnswerIndex": 1,
    "difficulty": 2,
    "clozeMask": "{{c1::photosynthesis}}"${showHints ? ',\n    "explanation": "Additional explanation or context"' : ''}
  },
  {
    "cardType": "reverse", 
    "question": "Define: Democracy",
    "answer": "A system of government by the whole population",
    "multipleChoiceOptions": ["Monarchy", "A system of government by the whole population", "Dictatorship", "Oligarchy"],
    "correctAnswerIndex": 1,
    "difficulty": 2,
    "clozeMask": null${showHints ? ',\n    "explanation": "Additional explanation or context"' : ''}
  }
]

AVAILABLE CARD TYPES: basic, cloze, reverse, multipleChoice, trueFalse, comparison, scenario, causeEffect, sequence, definitionExample, caseStudy, problemSolving, hypothesisTesting, decisionAnalysis, systemAnalysis, prediction, evaluation, synthesis

CRITICAL Requirements:
- Create EXACTLY $count flashcards - count them carefully!
- Include exactly 4 multiple choice options for each card
- The correct answer must be one of the 4 options AND must match the "answer" field
- Set correctAnswerIndex to the position (0-3) where the correct answer appears in multipleChoiceOptions
- RANDOMIZE the correct answer position - don't always put it first! Mix between positions 0, 1, 2, and 3
- Set difficulty: 1=basic facts, 2=simple understanding, 3=application, 4=analysis, 5=advanced synthesis${showHints ? '\n- Include helpful explanations in the answer that provide additional context' : ''}
- Create realistic distractors based on difficulty and user's learning level
- Use language and examples appropriate for the user's educational background

Distractor Quality Rules:
- Wrong answers should be plausible and related to the topic
- Use common mistakes students at the user's level actually make
- Include partial truths or common misconceptions
- Make options similar in length and format
- Avoid obviously silly or unrelated options
- Consider the user's educational background when crafting distractors

PERSONALIZATION REQUIREMENTS:
- Adapt question complexity to user's educational level and preferences
- Use examples and analogies that resonate with the user's background
- Format questions according to the user's preferred learning style
- Ensure difficulty aligns with user's preference and study goals
    ''';
  }

  /// Build comprehensive personalization context from user data (14+ layers)
  String _buildPersonalizationContext(User user, [StudyAnalytics? analytics]) {
    final prefs = user.preferences;
    final profile = <String>[];
    
    // Layer 1: Educational Identity & Background
    if (user.school != null) profile.add('Institution: ${user.school}');
    if (user.major != null) profile.add('Field of study: ${user.major}');
    if (user.age != null) profile.add('Age: ${user.age}');
    if (user.graduationYear != null) {
      final yearsToGrad = user.graduationYear! - DateTime.now().year;
      profile.add('Academic level: ${yearsToGrad > 0 ? "$yearsToGrad-year student" : "Graduate"}');
    }
    
    // Layer 2: Core Learning Preferences
    profile.add('Primary learning style: ${prefs.learningStyle}');
    profile.add('Difficulty preference: ${prefs.difficultyPreference}');
    
    // Layer 3: Study Schedule & Time Management
    profile.add('Optimal study hours: ${prefs.studyStartHour}:00 - ${prefs.studyEndHour}:00');
    profile.add('Daily study capacity: ${prefs.maxCardsPerDay} cards, ${prefs.maxMinutesPerDay} minutes');
    profile.add('Study frequency: ${prefs.studyDaysNames.join(', ')}');
    
    // Layer 4: Break Patterns & Attention Span
    profile.add('Focus intervals: ${prefs.breakInterval}-minute sessions');
    profile.add('Break duration preference: ${prefs.breakDuration} minutes');
    profile.add('Card review pace: ${prefs.cardReviewDelay / 1000} seconds per card');
    
    // Layer 5: Cognitive & Memory Preferences
    profile.add('Memory aids: ${prefs.showHints ? "Prefers explanations and hints" : "Independent learning"}');
    profile.add('Sensory preference: ${prefs.autoPlayAudio ? "Audio-enhanced learning" : "Visual-focused learning"}');
    
    // Layer 6: Personality & Motivation Factors
    final currentHour = DateTime.now().hour;
    String energyLevel = currentHour < 12 ? "Morning person" : 
                        currentHour < 18 ? "Afternoon productive" : "Evening learner";
    profile.add('Energy pattern: $energyLevel');
    profile.add('Social learning: ${prefs.socialNotifications ? "Collaborative learner" : "Independent learner"}');
    
    // Layer 7: Accessibility & UI Preferences
    profile.add('Reading preference: ${prefs.fontSize}x font scaling');
    profile.add('Interface style: ${prefs.theme} theme with ${prefs.animations ? "animated" : "static"} interface');
    
    // Layer 8: Cultural & Language Context
    profile.add('Language: ${prefs.language}');
    if (user.location != null) profile.add('Geographic context: ${user.location}');
    
    // Layer 9: Technology Integration
    profile.add('Connectivity: ${prefs.offline ? "Offline-capable" : "Online-dependent"}');
    profile.add('Data management: ${prefs.autoSync ? "Auto-sync enabled" : "Manual sync"}');
    
    // Layer 10: Achievement & Progress Tracking
    profile.add('Motivation style: ${prefs.achievementNotifications ? "Achievement-driven" : "Process-focused"}');
    profile.add('Study reminders: ${prefs.studyReminders ? "Prefers reminders" : "Self-directed"}');
    
    // Layer 11: Privacy & Sharing Preferences
    profile.add('Social sharing: ${user.privacySettings.shareStudyStats ? "Public progress" : "Private progress"}');
    profile.add('Communication style: ${user.privacySettings.allowDirectMessages ? "Open to collaboration" : "Individual focus"}');
    
    // Layer 12: Experience Level & History
    profile.add('Account experience: ${user.loginCount} sessions, active since ${_formatDate(user.createdAt)}');
    if (user.lastActiveAt != null) {
      final daysSinceActive = DateTime.now().difference(user.lastActiveAt!).inDays;
      profile.add('Recent activity: ${daysSinceActive == 0 ? "Active today" : "$daysSinceActive days ago"}');
    }
    
    // Layer 13: Performance Analytics Integration
    if (analytics != null) {
      profile.add('Performance level: ${analytics.performanceLevel}');
      profile.add('Overall accuracy: ${(analytics.overallAccuracy * 100).round()}%');
      profile.add('Study consistency: ${analytics.currentStreak} day streak (longest: ${analytics.longestStreak})');
      profile.add('Study experience: ${analytics.totalCardsStudied} cards, ${analytics.totalStudyTime} minutes total');
      
      // Layer 14: Advanced Learning Patterns
      final patterns = analytics.learningPatterns;
      if (patterns.mostEffectiveLearningStyle != 'adaptive') {
        profile.add('Most effective style: ${patterns.mostEffectiveLearningStyle}');
      }
      if (patterns.preferredStudyTime != 'flexible') {
        profile.add('Peak performance: ${patterns.preferredStudyTime}');
      }
      profile.add('Avg session: ${patterns.averageSessionLength.toStringAsFixed(1)} min, ${patterns.preferredCardsPerSession} cards');
      
      // Layer 15: Subject Performance Analysis
      if (analytics.strugglingSubjects.isNotEmpty) {
        profile.add('Areas needing focus: ${analytics.strugglingSubjects.take(3).join(", ")}');
      }
      if (analytics.strongSubjects.isNotEmpty) {
        profile.add('Mastered areas: ${analytics.strongSubjects.take(3).join(", ")}');
      }
      
      // Layer 16: Performance Trend Analysis
      profile.add('Performance trend: ${analytics.recentTrend.description}');
    }
    
    return profile.join(', ');
  }

  /// Format date for user-friendly display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'today';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }
  
  /// Analytics-driven question optimization based on user performance feedback
  String _getAnalyticsBasedInstructions(User user, StudyAnalytics? analytics, String subject) {
    if (analytics == null) return '';
    
    final patterns = analytics.learningPatterns;
    final instructions = <String>[];
    
    // Analyze learning style effectiveness
    if (patterns.learningStyleEffectiveness.isNotEmpty) {
      final mostEffective = patterns.learningStyleEffectiveness.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final leastEffective = patterns.learningStyleEffectiveness.entries
          .reduce((a, b) => a.value < b.value ? a : b);
      
      instructions.add('LEARNING STYLE OPTIMIZATION:');
      instructions.add('- Most effective style: ${mostEffective.key} (${(mostEffective.value * 100).round()}% success rate)');
      instructions.add('- Avoid emphasis on: ${leastEffective.key} style questions');
      instructions.add('- Prioritize ${mostEffective.key} learning approaches in question design');
    }
    
    // Analyze topic interest correlation with performance
    if (patterns.topicInterest.isNotEmpty) {
      final highInterest = patterns.topicInterest.entries
          .where((entry) => entry.value > 0.7)
          .map((entry) => entry.key)
          .toList();
      final lowInterest = patterns.topicInterest.entries
          .where((entry) => entry.value < 0.4)
          .map((entry) => entry.key)
          .toList();
      
      if (highInterest.isNotEmpty) {
        instructions.add('HIGH ENGAGEMENT TOPICS: ${highInterest.join(', ')}');
        instructions.add('- Use these topics for examples and scenarios when possible');
        instructions.add('- Connect current subject to these areas of interest');
      }
      
      if (lowInterest.isNotEmpty) {
        instructions.add('LOW ENGAGEMENT AREAS: ${lowInterest.join(', ')}');
        instructions.add('- Make these topics more engaging with practical applications');
        instructions.add('- Use storytelling or real-world connections for these areas');
      }
    }
    
    // Common mistake pattern analysis
    if (patterns.commonMistakePatterns.isNotEmpty) {
      instructions.add('MISTAKE PREVENTION STRATEGY:');
      instructions.add('- Common user mistakes: ${patterns.commonMistakePatterns.take(3).join(', ')}');
      instructions.add('- Design distractors that specifically address these misconceptions');
      instructions.add('- Include explanations that clarify these common errors');
    }
    
    // Session optimization based on patterns
    instructions.add('SESSION OPTIMIZATION:');
    instructions.add('- Optimal session length: ${patterns.averageSessionLength.toStringAsFixed(1)} minutes');
    instructions.add('- Preferred cards per session: ${patterns.preferredCardsPerSession}');
    if (patterns.preferredStudyTime != 'flexible') {
      instructions.add('- Best performance time: ${patterns.preferredStudyTime}');
    }
    
    // Cross-subject performance insights
    final subjectPerformance = analytics.subjectPerformance[subject];
    if (subjectPerformance != null) {
      instructions.add('SUBJECT-SPECIFIC OPTIMIZATION:');
      instructions.add('- Current subject accuracy: ${(subjectPerformance.accuracy * 100).round()}%');
      instructions.add('- Performance trend: ${subjectPerformance.trendDescription}');
      
      // Question timing optimization
      if (subjectPerformance.averageResponseTime > 30) {
        instructions.add('- User needs thinking time: Create complex, analytical questions');
        instructions.add('- Avoid time-pressure tactics, allow for deep processing');
      } else if (subjectPerformance.averageResponseTime < 15) {
        instructions.add('- User responds quickly: Can handle rapid-fire recall questions');
        instructions.add('- Include more factual and definition-based questions');
      }
      
      // Recent performance adaptation
      if (subjectPerformance.recentScores.isNotEmpty) {
        final recentTrend = subjectPerformance.isImproving ? 'improving' : 'stable/declining';
        instructions.add('- Recent trend: $recentTrend');
        if (subjectPerformance.isImproving) {
          instructions.add('- Gradually increase question complexity');
          instructions.add('- Introduce more advanced concepts and applications');
        } else {
          instructions.add('- Focus on reinforcement and review');
          instructions.add('- Include more foundational questions for confidence building');
        }
      }
    }
    
    // Global performance insights
    instructions.add('ADAPTIVE DIFFICULTY CALIBRATION:');
    instructions.add('- Overall performance level: ${analytics.performanceLevel}');
    instructions.add('- Success rate: ${(analytics.overallAccuracy * 100).round()}%');
    instructions.add('- Study consistency: ${analytics.currentStreak} day streak');
    
    // Performance-based question type recommendations
    if (analytics.overallAccuracy > 0.85) {
      instructions.add('- User handles complexity well: Use advanced question formats');
      instructions.add('- Include scenario-based, analysis, and synthesis questions');
    } else if (analytics.overallAccuracy < 0.6) {
      instructions.add('- User needs support: Focus on basic recall and comprehension');
      instructions.add('- Use clear, straightforward question formats with obvious distractors');
    } else {
      instructions.add('- User at moderate level: Balance basic and intermediate questions');
      instructions.add('- Mix factual recall with application-based questions');
    }
    
    return instructions.isNotEmpty ? 
        '\nREAL-TIME ANALYTICS FEEDBACK ADAPTATION:\n${instructions.join('\n')}\n' : '';
  }
  
  /// Track question effectiveness for continuous learning
  /// This method would be called after each user response to update analytics
  Future<void> trackQuestionEffectiveness({
    required String userId,
    required String questionId,
    required CardType questionType,
    required String subject,
    required bool wasCorrect,
    required int responseTimeMs,
    required int difficulty,
    required String learningStyle,
  }) async {
    try {
      // This would integrate with the analytics service to track:
      // 1. Which question types work best for this user
      // 2. Optimal difficulty levels by subject
      // 3. Learning style effectiveness correlation
      // 4. Response time patterns
      // 5. Common mistake patterns by question type
      
      debugPrint('Tracking question effectiveness: $questionType, correct: $wasCorrect, time: ${responseTimeMs}ms');
      
      // Example analytics tracking (would be implemented with actual analytics service)
      final questionData = {
        'userId': userId,
        'questionId': questionId,
        'questionType': questionType.toString(),
        'subject': subject,
        'wasCorrect': wasCorrect,
        'responseTimeMs': responseTimeMs,
        'difficulty': difficulty,
        'learningStyle': learningStyle,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // In a real implementation, this would:
      // 1. Update user's learning pattern data
      // 2. Adjust question type preferences
      // 3. Update difficulty calibration
      // 4. Track mistake patterns
      // 5. Optimize future question generation
      
      debugPrint('Question effectiveness data recorded: $questionData');
      
    } catch (e) {
      debugPrint('Error tracking question effectiveness: $e');
    }
  }
  
  /// Generate adaptive recommendations based on performance data
  /// This provides real-time feedback to improve question generation
  Map<String, dynamic> getAdaptiveRecommendations(User user, StudyAnalytics? analytics, String subject) {
    if (analytics == null) {
      return {
        'difficulty': 'moderate',
        'questionTypes': ['basic', 'multipleChoice'],
        'focusAreas': ['foundational concepts'],
        'avoidAreas': [],
        'confidence': 0.5,
      };
    }
    
    final subjectPerf = analytics.subjectPerformance[subject];
    final patterns = analytics.learningPatterns;
    
    // Determine optimal difficulty
    String recommendedDifficulty = 'moderate';
    if (subjectPerf != null) {
      if (subjectPerf.accuracy >= 0.9) {
        recommendedDifficulty = 'challenging';
      } else if (subjectPerf.accuracy >= 0.8) {
        recommendedDifficulty = 'moderate';
      } else {
        recommendedDifficulty = 'easy';
      }
    }
    
    // Recommend question types based on effectiveness
    List<String> recommendedTypes = ['basic', 'multipleChoice'];
    if (patterns.learningStyleEffectiveness.isNotEmpty) {
      final mostEffective = patterns.learningStyleEffectiveness.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      switch (mostEffective.key.toLowerCase()) {
        case 'visual':
          recommendedTypes = ['comparison', 'scenario', 'multipleChoice'];
          break;
        case 'auditory':
          recommendedTypes = ['basic', 'trueFalse', 'causeEffect'];
          break;
        case 'kinesthetic':
          recommendedTypes = ['scenario', 'sequence', 'causeEffect'];
          break;
        case 'reading/writing':
          recommendedTypes = ['cloze', 'definitionExample', 'comparison'];
          break;
      }
    }
    
    // Focus areas based on performance
    List<String> focusAreas = [];
    List<String> avoidAreas = [];
    
    if (analytics.strugglingSubjects.contains(subject)) {
      focusAreas.addAll(['foundational concepts', 'basic terminology', 'simple applications']);
      avoidAreas.addAll(['advanced theory', 'complex scenarios']);
    } else if (analytics.strongSubjects.contains(subject)) {
      focusAreas.addAll(['advanced concepts', 'complex applications', 'analysis and synthesis']);
    } else {
      focusAreas.addAll(['balanced approach', 'progressive difficulty', 'practical applications']);
    }
    
    // Confidence level based on data availability and consistency
    double confidence = 0.5;
    if (subjectPerf != null && subjectPerf.totalCards > 20) {
      confidence = 0.8;
      if (patterns.learningStyleEffectiveness.isNotEmpty) {
        confidence = 0.9;
      }
    }
    
    return {
      'difficulty': recommendedDifficulty,
      'questionTypes': recommendedTypes,
      'focusAreas': focusAreas,
      'avoidAreas': avoidAreas,
      'confidence': confidence,
      'reasoning': 'Based on ${subjectPerf?.totalCards ?? 0} previous cards and ${analytics.totalStudyTime} minutes of study data',
    };
  }

  /// Get comprehensive learning style specific instructions
  String _getLearningStyleInstructions(String learningStyle) {
    switch (learningStyle.toLowerCase()) {
      case 'visual':
        return '''VISUAL LEARNING OPTIMIZATION:
- Emphasize spatial relationships, patterns, and visual organization
- Use descriptive language that creates vivid mental images
- Include questions about colors, shapes, diagrams, and visual layouts  
- Reference charts, graphs, mind maps, and visual memory techniques
- Ask about visual comparisons and contrasts
- Use formatting and structure that supports visual scanning
- Include questions about images, symbols, and visual representations
- Encourage visualization of concepts and processes''';
      
      case 'auditory':
        return '''AUDITORY LEARNING OPTIMIZATION:
- Focus on rhythm, sound patterns, and verbal explanations
- Use questions that can be "heard" or spoken aloud mentally
- Include rhymes, alliteration, and musical mnemonics
- Reference verbal discussions, debates, and oral presentations
- Ask about sound-based associations and acronyms
- Use conversational tone and dialogue-style examples
- Include questions about listening comprehension and spoken instructions
- Encourage verbal repetition and explanation of concepts''';
      
      case 'kinesthetic':
        return '''KINESTHETIC LEARNING OPTIMIZATION:
- Emphasize hands-on experiences and physical manipulation
- Use step-by-step processes and procedural questions
- Include real-world applications and practical scenarios
- Reference physical movement, touch, and experiential learning
- Ask "how would you physically do..." and action-oriented questions
- Use trial-and-error and experimentation examples
- Include questions about building, creating, and manipulating objects
- Encourage learning through practice and physical engagement''';
      
      case 'reading':
        return '''READING/WRITING LEARNING OPTIMIZATION:
- Provide comprehensive, well-structured text explanations
- Use detailed definitions and thorough written descriptions
- Include questions about written material and textbook content
- Reference lists, outlines, and organized written information
- Ask about categorization and written analysis
- Use formal academic language and technical terminology
- Include questions about note-taking and written summary skills
- Encourage learning through reading and writing activities''';
      
      case 'adaptive':
      default:
        return '''ADAPTIVE MULTI-MODAL LEARNING:
- Blend visual, auditory, kinesthetic, and reading approaches
- Vary question formats to engage different learning preferences
- Use mixed media references (visual + text, audio + kinesthetic)
- Adapt style based on subject complexity and content type
- Include multiple representation methods for the same concept
- Balance abstract concepts with concrete examples
- Use diverse question stems and response formats
- Provide multiple pathways to understanding the same material''';
    }
  }

  /// Get comprehensive difficulty preference specific instructions
  String _getDifficultyInstructions(String difficultyPref, [String? subject, StudyAnalytics? analytics]) {
    // Get recommended difficulty from analytics if available
    String actualDifficulty = difficultyPref;
    if (analytics != null && subject != null) {
      final recommendedDifficulty = analytics.getRecommendedDifficulty(subject);
      if (difficultyPref == 'adaptive') {
        actualDifficulty = recommendedDifficulty;
      }
    }
    
    // Add performance context
    String performanceNote = '';
    if (analytics != null && subject != null) {
      final subjectPerf = analytics.subjectPerformance[subject];
      if (subjectPerf != null) {
        if (subjectPerf.isImproving) {
          performanceNote = 'Note: User is improving in this subject - consider slightly increasing challenge.';
        } else if (subjectPerf.accuracy < 0.6) {
          performanceNote = 'Note: User struggles with this subject - provide more foundational support.';
        } else if (subjectPerf.accuracy > 0.85) {
          performanceNote = 'Note: User excels in this subject - can handle more advanced concepts.';
        }
      }
    }
    switch (actualDifficulty.toLowerCase()) {
      case 'easy':
        return '''EASY DIFFICULTY OPTIMIZATION:
- Target Bloom's Taxonomy: Knowledge and basic Comprehension (Levels 1-2)
- Focus on fundamental facts, definitions, and simple recall
- Use clear, direct language with minimal ambiguity
- Ask about basic identification, listing, and recognition
- Provide distractors that are obviously incorrect to most students
- Use familiar examples and straightforward scenarios
- Avoid complex reasoning or multi-step problem solving
- Include plenty of context clues and supportive information
${performanceNote.isNotEmpty ? '\n$performanceNote' : ''}''';
      
      case 'moderate':
        return '''MODERATE DIFFICULTY OPTIMIZATION:  
- Target Bloom's Taxonomy: Comprehension and Application (Levels 2-3)
- Balance fact recall with conceptual understanding
- Include practical application of learned principles
- Use moderately complex scenarios with clear solutions
- Provide plausible distractors based on common misconceptions
- Ask "why" and "how" questions alongside "what" questions
- Include real-world examples that require some analysis
- Challenge students while maintaining accessibility
${performanceNote.isNotEmpty ? '\n$performanceNote' : ''}''';
      
      case 'challenging':
        return '''CHALLENGING DIFFICULTY OPTIMIZATION:
- Target Bloom's Taxonomy: Analysis, Synthesis, and Evaluation (Levels 4-5)
- Focus on critical thinking and complex problem solving
- Use multi-step reasoning and interconnected concepts
- Include abstract scenarios requiring deep understanding
- Provide sophisticated distractors with subtle differences
- Ask students to compare, critique, and create solutions
- Challenge assumptions and require justification of answers
- Use advanced terminology and complex relationships
${performanceNote.isNotEmpty ? '\n$performanceNote' : ''}''';
      
      case 'adaptive':
      default:
        return '''ADAPTIVE DIFFICULTY OPTIMIZATION:
- Vary complexity based on topic sophistication and user background
- Start with foundational concepts (Level 2), progress to applications (Level 3-4)
- Mix recall, understanding, and application within the same set
- Adapt language complexity to match content difficulty
- Use scaffolded approach: simple to complex within each topic
- Balance challenge with achievability based on user's educational level
- Provide appropriate cognitive load without overwhelming
- Adjust distractors to match the cognitive demand of each question
${performanceNote.isNotEmpty ? '\n$performanceNote' : ''}''';
    }
  }

  /// Get question type instructions based on user preferences
  String _getQuestionTypeInstructions(User user) {
    String subjectSpecific = _getSubjectSpecificInstructions(user);
    
    return '''COMPREHENSIVE QUESTION TYPE VARIETY:

PRIMARY FORMATS (must include variety):
1. BASIC FLASHCARDS: Traditional Q&A format for definitions and concepts
2. CLOZE DELETION: Fill-in-the-blank with {{c1::hidden}} text format
3. REVERSE CARDS: Test both directions (concept→definition AND definition→concept)

ADVANCED FORMATS (include 3-4 per set):
4. TRUE/FALSE: Statement verification with detailed reasoning
5. MULTIPLE CHOICE: 4 options with sophisticated distractors
6. COMPARISON: "Compare X and Y" or "What's the difference between..."
7. SCENARIO-BASED: Real-world application questions
8. CAUSE-AND-EFFECT: "Why does X happen?" or "What results from Y?"
9. SEQUENCE/ORDERING: "What happens first/next/last in this process?"
10. DEFINITION-TO-EXAMPLE: "Which example best demonstrates X concept?"

SOPHISTICATED FORMATS (include 1-2 per set for advanced users):
11. CASE STUDY: Multi-paragraph scenario with analysis questions
12. PROBLEM-SOLVING CHAIN: Multi-step problems requiring logical progression
13. HYPOTHESIS TESTING: "Given this evidence, what can you conclude?"
14. DECISION ANALYSIS: "What would be the best approach and why?"
15. SYSTEM ANALYSIS: "How do these components interact?"
16. PREDICTION: "Based on these patterns, what would happen if..."
17. EVALUATION: "Assess the effectiveness of X approach"
18. SYNTHESIS: "Combine concepts A and B to solve problem C"

COGNITIVE LEVELS (distribute across cards):
- RECALL (30%): Basic facts, definitions, terminology
- COMPREHENSION (40%): Understanding concepts, explaining processes
- APPLICATION (20%): Using knowledge in new situations
- ANALYSIS (10%): Breaking down complex ideas, identifying patterns

$subjectSpecific

ADVANCED QUALITY STANDARDS:
- Vary question stems: What, How, Why, When, Which, Compare, Analyze, Apply
- Test understanding at multiple cognitive levels, not just memorization
- Include application-based scenarios relevant to user's field
- Create sophisticated distractors that reflect common misconceptions
- Use current, relevant examples that connect to the user's experience
- Ensure questions are culturally sensitive and inclusive
- Make questions challenging but fair for the user's academic level
- Include reasoning and explanation in complex questions''';
  }

  /// Get subject-specific instructions based on user's educational background
  String _getSubjectSpecificInstructions(User user) {
    final major = user.major?.toLowerCase() ?? '';
    final school = user.school?.toLowerCase() ?? '';
    
    if (major.contains('computer') || major.contains('cs') || major.contains('software') || major.contains('programming')) {
      return '''COMPUTER SCIENCE CONTEXT:
- Use programming concepts, algorithms, and technical terminology
- Include examples from software development, data structures, and systems
- Reference coding practices, debugging, and computational thinking
- Use technology and digital examples that resonate with CS students''';
    }
    
    if (major.contains('engineer')) {
      return '''ENGINEERING CONTEXT:
- Emphasize problem-solving methodologies and systematic approaches
- Include examples from design, testing, and optimization
- Reference mathematical principles and practical applications
- Use technical precision and evidence-based reasoning''';
    }
    
    if (major.contains('business') || major.contains('management') || major.contains('finance')) {
      return '''BUSINESS CONTEXT:
- Include examples from organizations, markets, and economic principles
- Reference decision-making, strategy, and analytical thinking
- Use case studies and real-world business scenarios
- Emphasize practical applications and professional contexts''';
    }
    
    if (major.contains('med') || major.contains('health') || major.contains('bio')) {
      return '''MEDICAL/HEALTH SCIENCES CONTEXT:
- Use examples from healthcare, anatomy, and biological systems
- Include clinical scenarios and evidence-based practice
- Reference patient care, diagnosis, and treatment principles
- Emphasize accuracy, precision, and life-critical decision making''';
    }
    
    if (major.contains('education') || major.contains('teaching')) {
      return '''EDUCATION CONTEXT:
- Include examples from classroom management and learning theory
- Reference pedagogical approaches and student development
- Use educational psychology and instructional design principles
- Emphasize clear communication and diverse learning needs''';
    }
    
    if (school.contains('high school') || user.age != null && user.age! <= 18) {
      return '''HIGH SCHOOL CONTEXT:
- Use age-appropriate examples and references
- Include topics relevant to teenage experiences and interests
- Reference college preparation and career exploration
- Use contemporary culture and social media examples when appropriate''';
    }
    
    return '''GENERAL ACADEMIC CONTEXT:
- Use broad, universally accessible examples
- Include interdisciplinary connections when possible
- Reference general academic skills and critical thinking
- Maintain appropriate academic rigor for college-level students''';
  }

  /// Build performance context for personalized prompts
  String _buildPerformanceContext(String subject, StudyAnalytics? analytics) {
    if (analytics == null) return '';
    
    final performance = analytics.subjectPerformance[subject];
    final context = <String>[];
    
    // Overall performance level and trend
    context.add('User Performance Level: ${analytics.performanceLevel} (${(analytics.overallAccuracy * 100).round()}% overall accuracy)');
    context.add('Study Experience: ${analytics.totalCardsStudied} cards, ${analytics.totalStudyTime} min total, ${analytics.currentStreak} day streak');
    
    // Performance trend analysis
    context.add('Performance Trend: ${analytics.recentTrend.description}');
    
    // Subject-specific performance with detailed analysis
    if (performance != null) {
      context.add('Subject Performance: ${(performance.accuracy * 100).round()}% accuracy over ${performance.totalCards} cards');
      context.add('Subject Trend: ${performance.trendDescription}');
      
      // Advanced difficulty adaptation based on performance metrics
      if (performance.accuracy < 0.5) {
        context.add('CRITICAL: User severely struggling - focus on basic definitions and simple recall');
        context.add('Strategy: Use easy vocabulary, provide multiple hints, avoid complex scenarios');
      } else if (performance.accuracy < 0.6) {
        context.add('Focus: Foundational concepts - user needs basic support with clear explanations');
        context.add('Strategy: Emphasize understanding over memorization, provide step-by-step reasoning');
      } else if (performance.accuracy < 0.7) {
        context.add('Focus: Bridging concepts - user ready for moderate challenges with support');
        context.add('Strategy: Mix basic and intermediate concepts, include practical applications');
      } else if (performance.accuracy < 0.85) {
        context.add('Focus: Intermediate concepts - user ready for standard challenges');
        context.add('Strategy: Balance theory and application, introduce more complex scenarios');
      } else if (performance.accuracy >= 0.85) {
        context.add('Focus: Advanced concepts - user excels and needs intellectual challenges');
        context.add('Strategy: Use complex scenarios, advanced terminology, multi-step reasoning');
      }
      
      // Response time adaptation
      if (performance.averageResponseTime > 45) {
        context.add('Note: User takes time to process - create questions requiring deep thought and analysis');
      } else if (performance.averageResponseTime < 15) {
        context.add('Note: User responds quickly - can handle rapid-fire factual questions');
      } else {
        context.add('Note: User has balanced response time - mix quick recall with thoughtful questions');
      }
      
      // Difficulty breakdown analysis
      if (performance.difficultyBreakdown.isNotEmpty) {
        final easyCount = performance.difficultyBreakdown['easy'] ?? 0;
        final moderateCount = performance.difficultyBreakdown['moderate'] ?? 0;
        final hardCount = performance.difficultyBreakdown['hard'] ?? 0;
        final total = easyCount + moderateCount + hardCount;
        
        if (total > 0) {
          context.add('Experience Distribution: ${((easyCount/total)*100).round()}% easy, ${((moderateCount/total)*100).round()}% moderate, ${((hardCount/total)*100).round()}% hard');
          
          // Adaptive recommendations based on distribution
          if (easyCount > moderateCount + hardCount) {
            context.add('Recommendation: User ready to progress beyond easy questions - increase moderate difficulty');
          } else if (hardCount > easyCount && performance.accuracy > 0.75) {
            context.add('Recommendation: User handles hard questions well - maintain challenging content');
          }
        }
      }
      
      // Recent performance insights
      if (performance.recentScores.isNotEmpty) {
        final recentAvg = performance.recentScores.take(3).fold(0.0, (sum, score) => sum + score) / 
                         performance.recentScores.take(3).length.toDouble();
        context.add('Recent Performance: ${(recentAvg * 100).round()}% in last ${performance.recentScores.take(3).length} sessions');
        
        if (performance.isImproving) {
          context.add('Momentum: User showing improvement - gradually increase challenge level');
        } else if (recentAvg < performance.accuracy - 0.1) {
          context.add('Momentum: Recent decline - provide more support and review');
        }
      }
    } else {
      // No subject-specific data - use overall metrics
      context.add('Subject Status: New subject for user - start with diagnostic questions to gauge level');
      if (analytics.performanceLevel == 'Expert' || analytics.performanceLevel == 'Advanced') {
        context.add('Strategy: User is advanced overall - can start with moderate to challenging questions');
      } else {
        context.add('Strategy: Start with foundational questions to establish baseline understanding');
      }
    }
    
    // Cross-subject performance insights
    if (analytics.strugglingSubjects.isNotEmpty) {
      context.add('Areas needing support: ${analytics.strugglingSubjects.take(3).join(', ')}');
      if (analytics.strugglingSubjects.contains(subject)) {
        context.add('IMPORTANT: Current subject is in user\'s struggle areas - provide extra support');
      }
    }
    if (analytics.strongSubjects.isNotEmpty) {
      context.add('User\'s strengths: ${analytics.strongSubjects.take(3).join(', ')}');
      if (analytics.strongSubjects.contains(subject)) {
        context.add('ADVANTAGE: Current subject is user\'s strength - can use advanced concepts');
      }
    }
    
    // Learning pattern insights for question adaptation
    final patterns = analytics.learningPatterns;
    if (patterns.mostEffectiveLearningStyle != 'adaptive') {
      context.add('Most effective learning style: ${patterns.mostEffectiveLearningStyle} (optimize questions for this style)');
    }
    if (patterns.preferredStudyTime != 'flexible') {
      context.add('Optimal study time: ${patterns.preferredStudyTime} (current session timing should match)');
    }
    
    // Session length and card preferences
    context.add('Session Preferences: ${patterns.averageSessionLength.toStringAsFixed(1)} min sessions, ${patterns.preferredCardsPerSession} cards per session');
    
    // Topic interest analysis
    if (patterns.topicInterest.isNotEmpty) {
      final interestedTopics = patterns.topicInterest.entries
          .where((entry) => entry.value > 0.7)
          .map((entry) => entry.key)
          .take(3)
          .join(', ');
      if (interestedTopics.isNotEmpty) {
        context.add('High Interest Topics: $interestedTopics (use these for engaging examples)');
      }
    }
    
    // Common mistake patterns
    if (patterns.commonMistakePatterns.isNotEmpty) {
      context.add('Common Mistakes: ${patterns.commonMistakePatterns.take(3).join(', ')} (address these proactively)');
    }
    
    return context.isNotEmpty ? '\nADVANCED PERFORMANCE-BASED ADAPTATION:\n${context.join('\n')}\n' : '';
  }

  /// Build personalized answer with additional context if user prefers hints
  String _buildPersonalizedAnswer(Map<String, dynamic> cardJson, User user) {
    String baseAnswer = cardJson['answer'] ?? 'Answer';
    
    if (user.preferences.showHints && cardJson['explanation'] != null) {
      return '$baseAnswer\n\nℹ️ ${cardJson['explanation']}';
    }
    
    return baseAnswer;
  }

  /// Generate multi-modal content instructions based on user preferences
  String _getMultiModalInstructions(User user) {
    final prefs = user.preferences;
    final style = prefs.learningStyle;
    
    String instructions = '\nMULTI-MODAL CONTENT GENERATION:\n';
    
    // Card type variety based on learning style
    if (style == 'visual' || style == 'adaptive') {
      instructions += '- Include visual learning cues: "Imagine...", "Picture...", "Visualize..."\n';
      instructions += '- Create cloze deletion cards for key terms: {{c1::important_term}}\n';
      instructions += '- Use spatial relationships and diagrams descriptions\n';
    }
    
    if (style == 'auditory' || style == 'adaptive') {
      instructions += '- Include mnemonics and rhymes where appropriate\n';
      instructions += '- Add phonetic pronunciations for complex terms\n';
      instructions += '- Create reverse cards for bidirectional learning\n';
    }
    
    if (style == 'kinesthetic' || style == 'adaptive') {
      instructions += '- Include hands-on examples and action steps\n';
      instructions += '- Create sequential process cards\n';
      instructions += '- Add physical analogies and movement associations\n';
    }
    
    if (style == 'reading' || style == 'adaptive') {
      instructions += '- Provide detailed textual explanations\n';
      instructions += '- Include etymology and word origins\n';
      instructions += '- Create definition-based reverse cards\n';
    }
    
    // Question type variety
    instructions += '\nVARIED QUESTION TYPES:\n';
    instructions += '- Mix card types: 60% basic, 25% cloze, 15% reverse\n';
    instructions += '- Include fill-in-the-blank: "Complete: The process of _____ involves..."\n';
    instructions += '- Add true/false concepts: "True or False: [statement]"\n';
    instructions += '- Create matching pairs: "Match the term with its definition"\n';
    instructions += '- Use ordering questions: "Arrange the following steps in order"\n';
    instructions += '- Include comparison questions: "Compare and contrast X vs Y"\n';
    
    return instructions;
  }

  /// Generate contextual instructions based on user profile and environment
  String _getContextualInstructions(User user) {
    String instructions = '\nCONTEXTUAL PERSONALIZATION:\n';
    
    // Educational context
    if (user.school != null) {
      instructions += '- Adapt content for ${user.school} academic level\n';
    }
    if (user.major != null) {
      instructions += '- Include ${user.major} field-specific examples and terminology\n';
    }
    if (user.graduationYear != null) {
      final currentYear = DateTime.now().year;
      final yearsToGrad = user.graduationYear! - currentYear;
      if (yearsToGrad > 0) {
        instructions += '- Target $yearsToGrad-year student comprehension level\n';
      }
    }
    
    // Age-appropriate content
    if (user.age != null) {
      if (user.age! < 18) {
        instructions += '- Use age-appropriate examples and references\n';
      } else if (user.age! > 30) {
        instructions += '- Include professional and life experience connections\n';
      }
    }
    
    // Cultural and language context
    instructions += '- Use ${user.preferences.language} language patterns and cultural references\n';
    if (user.location != null) {
      instructions += '- Include regional examples relevant to ${user.location}\n';
    }
    
    return instructions;
  }

  /// Generate time-based and schedule-aware instructions
  String _getTimeBasedInstructions(User user) {
    final prefs = user.preferences;
    final now = DateTime.now();
    final currentHour = now.hour;
    
    String instructions = '\nTIME-BASED ADAPTATION:\n';
    
    // Time of day optimization
    if (currentHour >= prefs.studyStartHour && currentHour <= prefs.studyEndHour) {
      instructions += '- User is in optimal study time - create moderately challenging content\n';
    } else if (currentHour < prefs.studyStartHour) {
      instructions += '- Early morning study - create energizing, clear content\n';
    } else {
      instructions += '- Evening/night study - create focused, digestible content\n';
    }
    
    // Study schedule context
    if (prefs.isStudyDay) {
      instructions += '- Today is a planned study day - include comprehensive content\n';
    } else {
      instructions += '- Casual study day - create lighter, review-focused content\n';
    }
    
    // Break interval consideration
    instructions += '- Design content for ${prefs.breakInterval}-minute study intervals\n';
    instructions += '- Target ${prefs.cardReviewDelay}ms review pace\n';
    
    return instructions;
  }

  /// Parse card type from string to CardType enum
  CardType _parseCardType(String? cardTypeString) {
    switch (cardTypeString?.toLowerCase()) {
      case 'cloze':
        return CardType.cloze;
      case 'reverse':
        return CardType.reverse;
      case 'multiplechoice':
      case 'multiple_choice':
        return CardType.multipleChoice;
      case 'truefalse':
      case 'true_false':
        return CardType.trueFalse;
      case 'comparison':
        return CardType.comparison;
      case 'scenario':
        return CardType.scenario;
      case 'causeeffect':
      case 'cause_effect':
        return CardType.causeEffect;
      case 'sequence':
      case 'ordering':
        return CardType.sequence;
      case 'definitionexample':
      case 'definition_example':
        return CardType.definitionExample;
      case 'casestudy':
      case 'case_study':
        return CardType.caseStudy;
      case 'problemsolving':
      case 'problem_solving':
        return CardType.problemSolving;
      case 'hypothesistesting':
      case 'hypothesis_testing':
        return CardType.hypothesisTesting;
      case 'decisionanalysis':
      case 'decision_analysis':
        return CardType.decisionAnalysis;
      case 'systemanalysis':
      case 'system_analysis':
        return CardType.systemAnalysis;
      case 'prediction':
        return CardType.prediction;
      case 'evaluation':
        return CardType.evaluation;
      case 'synthesis':
        return CardType.synthesis;
      case 'basic':
      default:
        return CardType.basic;
    }
  }

  /// Build enhanced answer for improved flashcards
  String _buildEnhancedAnswer(Map<String, dynamic> improved, User user) {
    String baseAnswer = improved['answer'] ?? 'Answer';
    
    if (user.preferences.showHints && improved['explanation'] != null) {
      return '$baseAnswer\n\n💡 ${improved['explanation']}';
    }
    
    return baseAnswer;
  }

  /// Create fallback flashcards when AI is unavailable
  List<FlashCard> _createFallbackFlashcards(String subject, String content,
      {int count = 5, User? user}) {
    debugPrint('Creating $count fallback flashcards for $subject');

    final templates = [
      {
        'front': 'What is the main topic of $subject?',
        'back':
            'The main topic involves fundamental concepts, principles, and problem-solving methods in $subject.',
        'options': [
          'Advanced theoretical research only',
          'The main topic involves fundamental concepts, principles, and problem-solving methods in $subject.',
          'Historical dates and events',
          'Language and literature studies',
        ],
        'correctIndex': 1,
        'difficulty': 2,
      },
      {
        'front': 'What are key concepts in $subject?',
        'back':
            'Key concepts include the fundamental principles, theories, and practical applications within this field of study.',
        'options': [
          'Only memorization of facts',
          'Unrelated scientific theories',
          'Key concepts include the fundamental principles, theories, and practical applications within this field of study.',
          'Foreign language vocabulary',
        ],
        'correctIndex': 2,
        'difficulty': 3,
      },
      {
        'front': 'Why is studying $subject important?',
        'back':
            'Studying $subject develops critical thinking, problem-solving skills, and provides knowledge applicable to real-world situations.',
        'options': [
          'It has no practical value',
          'Only for entertainment purposes',
          'Just to pass standardized tests',
          'Studying $subject develops critical thinking, problem-solving skills, and provides knowledge applicable to real-world situations.',
        ],
        'correctIndex': 3,
        'difficulty': 2,
      },
      {
        'front': 'How can you apply $subject knowledge?',
        'back':
            'You can apply this knowledge through hands-on practice, real-world problem solving, and connecting concepts to everyday situations.',
        'options': [
          'You can apply this knowledge through hands-on practice, real-world problem solving, and connecting concepts to everyday situations.',
          'Knowledge cannot be applied practically',
          'Only in theoretical discussions',
          'By avoiding any practical use',
        ],
        'correctIndex': 0,
        'difficulty': 3,
      },
      {
        'front': 'What are effective study strategies for $subject?',
        'back':
            'Effective strategies include regular practice, understanding underlying concepts, working through examples, and connecting new material to prior knowledge.',
        'options': [
          'Memorizing everything without understanding',
          'Effective strategies include regular practice, understanding underlying concepts, working through examples, and connecting new material to prior knowledge.',
          'Studying only right before exams',
          'Avoiding practice problems entirely',
        ],
        'correctIndex': 1,
        'difficulty': 2,
      },
      {
        'front': 'What tools or resources are helpful for $subject?',
        'back':
            'Helpful resources include textbooks, practice problems, online tutorials, study groups, and hands-on experimentation.',
        'options': [
          'Only expensive software',
          'Helpful resources include textbooks, practice problems, online tutorials, study groups, and hands-on experimentation.',
          'No resources are needed',
          'Just reading without practicing',
        ],
        'correctIndex': 1,
        'difficulty': 2,
      },
      {
        'front': 'How do you measure progress in $subject?',
        'back':
            'Progress can be measured through practice tests, completed exercises, understanding of complex concepts, and practical applications.',
        'options': [
          'Progress cannot be measured',
          'Only through final exams',
          'Progress can be measured through practice tests, completed exercises, understanding of complex concepts, and practical applications.',
          'By avoiding all assessments',
        ],
        'correctIndex': 2,
        'difficulty': 3,
      },
      {
        'front': 'What common mistakes should be avoided in $subject?',
        'back':
            'Common mistakes include rushing without understanding, not practicing regularly, ignoring fundamentals, and not seeking help when needed.',
        'options': [
          'Making mistakes is always good',
          'Common mistakes include rushing without understanding, not practicing regularly, ignoring fundamentals, and not seeking help when needed.',
          'Only experts make mistakes',
          'Mistakes should never be corrected',
        ],
        'correctIndex': 1,
        'difficulty': 3,
      },
      {
        'front': 'How does $subject connect to other fields?',
        'back':
            '$subject often connects to other fields through shared principles, cross-disciplinary applications, and integrated problem-solving approaches.',
        'options': [
          '$subject is completely isolated',
          'No connections exist between fields',
          '$subject often connects to other fields through shared principles, cross-disciplinary applications, and integrated problem-solving approaches.',
          'Connections are always negative',
        ],
        'correctIndex': 2,
        'difficulty': 4,
      },
      {
        'front': 'What advanced topics in $subject should be explored?',
        'back':
            'Advanced topics typically involve deeper theoretical understanding, complex problem-solving, research applications, and specialized techniques.',
        'options': [
          'Advanced topics should be avoided',
          'Advanced topics typically involve deeper theoretical understanding, complex problem-solving, research applications, and specialized techniques.',
          'Only basic concepts matter',
          'Advanced means more memorization',
        ],
        'correctIndex': 1,
        'difficulty': 4,
      },
    ];

    // Add variety to fallback cards with different types
    final cardTypes = [
      CardType.basic, 
      CardType.multipleChoice, 
      CardType.cloze, 
      CardType.reverse, 
      CardType.trueFalse,
      CardType.comparison,
      CardType.scenario,
      CardType.causeEffect
    ];
    
    // Enhanced templates for different question types
    final enhancedTemplates = [
      ...templates, // Include existing templates
      // True/False questions
      {
        'front': 'True or False: $subject is primarily theoretical with no practical applications.',
        'back': 'False - $subject has both theoretical foundations and extensive practical applications in real-world scenarios.',
        'options': ['True', 'False'],
        'correctIndex': 1,
        'difficulty': 2,
        'type': 'trueFalse',
      },
      // Comparison questions
      {
        'front': 'Compare theoretical knowledge and practical application in $subject.',
        'back': 'Theoretical knowledge provides the foundation and principles, while practical application involves implementing these concepts to solve real-world problems. Both are essential for mastery.',
        'options': [
          'Theoretical is more important than practical',
          'Practical is more important than theoretical', 
          'Both are equally important and complementary',
          'Neither is necessary for learning'
        ],
        'correctIndex': 2,
        'difficulty': 4,
        'type': 'comparison',
      },
      // Scenario-based questions
      {
        'front': 'Scenario: A student is struggling to understand $subject concepts. What would be the most effective first step?',
        'back': 'Identify specific areas of confusion, review fundamental concepts, and connect new material to prior knowledge before moving to advanced topics.',
        'options': [
          'Skip to advanced topics immediately',
          'Identify specific areas of confusion, review fundamental concepts, and connect new material to prior knowledge',
          'Memorize everything without understanding',
          'Avoid studying altogether'
        ],
        'correctIndex': 1,
        'difficulty': 3,
        'type': 'scenario',
      },
      // Cause and effect questions
      {
        'front': 'What happens when students focus only on memorization in $subject without understanding?',
        'back': 'This leads to poor retention, inability to apply knowledge, difficulty with complex problems, and reduced academic performance.',
        'options': [
          'Improved long-term learning',
          'Better problem-solving skills',
          'Poor retention and inability to apply knowledge',
          'Enhanced creativity'
        ],
        'correctIndex': 2,
        'difficulty': 3,
        'type': 'causeEffect',
      },
      // Case study questions
      {
        'front': 'Case Study: A student has been studying $subject for 3 weeks but still struggles with basic concepts. They spend 2 hours daily reading but avoid practice problems. Analysis: What is the primary issue with their study approach?',
        'back': 'The primary issue is passive learning without active practice. Reading alone doesn\'t develop problem-solving skills or test understanding. The student needs to incorporate active recall, practice problems, and self-testing.',
        'options': [
          'Not enough time spent studying',
          'Passive learning without active practice and application',
          'The subject is too difficult for them',
          'They need to memorize more facts'
        ],
        'correctIndex': 1,
        'difficulty': 4,
        'type': 'caseStudy',
      },
      // Problem-solving chain questions
      {
        'front': 'Problem-Solving Chain: Step 1: Identify the key concepts in $subject. Step 2: Understand their relationships. Step 3: Apply them to solve problems. What should be your first action when you encounter a difficult problem?',
        'back': 'Break down the problem to identify which key concepts are involved, then recall the relationships between these concepts before attempting to apply them to find a solution.',
        'options': [
          'Immediately try different solution methods',
          'Break down the problem to identify relevant key concepts',
          'Look up the answer in a textbook',
          'Skip the problem and come back later'
        ],
        'correctIndex': 1,
        'difficulty': 4,
        'type': 'problemSolving',
      },
      // Evaluation questions
      {
        'front': 'Evaluation: Assess the effectiveness of using only flashcards versus combining flashcards with practice problems for learning $subject.',
        'back': 'Combining flashcards with practice problems is more effective. Flashcards help with memorization and quick recall, while practice problems develop application skills and deep understanding. The combination addresses multiple learning needs.',
        'options': [
          'Flashcards alone are always sufficient',
          'Practice problems are unnecessary',
          'Combining both methods is most effective for comprehensive learning',
          'The methods are equally effective when used separately'
        ],
        'correctIndex': 2,
        'difficulty': 4,
        'type': 'evaluation',
      },
      // Synthesis questions
      {
        'front': 'Synthesis: Combine the concepts of active recall, spaced repetition, and practical application to design an optimal study strategy for $subject.',
        'back': 'An optimal strategy would involve: 1) Using active recall techniques (flashcards, self-quizzing) for key facts, 2) Spacing review sessions over time to improve retention, and 3) Regularly practicing real problems to develop application skills. This multi-modal approach addresses memory, timing, and understanding.',
        'options': [
          'Focus only on one technique at a time',
          'Use active recall with spaced repetition and regular practice application',
          'Memorize everything first, then practice later',
          'Only practical application is needed'
        ],
        'correctIndex': 1,
        'difficulty': 5,
        'type': 'synthesis',
      },
    ];
    
    // Generate the requested number of cards, cycling through templates if needed
    final cards = <FlashCard>[];
    for (int i = 0; i < count; i++) {
      final template = enhancedTemplates[i % enhancedTemplates.length];
      final cardType = template.containsKey('type') ? 
          _parseCardType(template['type'] as String?) : 
          cardTypes[i % cardTypes.length];
      
      String front = template['front'] as String;
      String back = template['back'] as String;
      String? clozeMask;
      List<String> options = List<String>.from(template['options'] as List);
      int correctIndex = template['correctIndex'] as int;
      
      // Modify content based on card type
      if (cardType == CardType.cloze) {
        // Convert to cloze format
        final words = back.split(' ');
        if (words.length > 3) {
          final keyWordIndex = words.length ~/ 2;
          final keyWord = words[keyWordIndex];
          clozeMask = '{{c1::$keyWord}}';
          front = back.replaceFirst(keyWord, clozeMask);
          back = keyWord;
        }
      } else if (cardType == CardType.reverse) {
        // Create reverse card (definition to term)
        if (front.contains('What is') || front.contains('What are')) {
          final temp = front;
          front = 'Define: ${back.split('.')[0]}';
          back = temp.replaceAll('What is the ', '').replaceAll('What are the ', '').replaceAll('?', '');
        }
      } else if (cardType == CardType.trueFalse) {
        // Ensure True/False format
        if (!options.contains('True') || !options.contains('False')) {
          options = ['True', 'False'];
          correctIndex = back.toLowerCase().contains('false') ? 1 : 0;
        }
      } else if (cardType == CardType.comparison) {
        // Ensure comparison format
        if (!front.toLowerCase().contains('compare')) {
          front = 'Compare and contrast: $front';
        }
      } else if (cardType == CardType.scenario) {
        // Ensure scenario format
        if (!front.toLowerCase().contains('scenario')) {
          front = 'Scenario: $front';
        }
      } else if (cardType == CardType.causeEffect) {
        // Ensure cause-effect format
        if (!front.toLowerCase().contains('what happens') && !front.toLowerCase().contains('why')) {
          front = 'What happens when: $front';
        }
      } else if (cardType == CardType.caseStudy) {
        // Ensure case study format
        if (!front.toLowerCase().contains('case study')) {
          front = 'Case Study: $front';
        }
      } else if (cardType == CardType.problemSolving) {
        // Ensure problem-solving format
        if (!front.toLowerCase().contains('problem-solving') && !front.toLowerCase().contains('step')) {
          front = 'Problem-Solving: $front';
        }
      } else if (cardType == CardType.evaluation) {
        // Ensure evaluation format
        if (!front.toLowerCase().contains('evaluation') && !front.toLowerCase().contains('assess')) {
          front = 'Evaluation: Assess $front';
        }
      } else if (cardType == CardType.synthesis) {
        // Ensure synthesis format
        if (!front.toLowerCase().contains('synthesis') && !front.toLowerCase().contains('combine')) {
          front = 'Synthesis: Combine concepts related to $front';
        }
      }
      
      // Generate diagram data for visual learners
      String? diagramData;
      if (user != null && (user.preferences.learningStyle == 'visual' || 
                          user.preferences.learningStyle == 'adaptive')) {
        final fallbackCard = FlashCard(
          id: (i + 1).toString(),
          deckId: 'ai_generated',
          type: cardType,
          front: front,
          back: back,
          difficulty: template['difficulty'] as int,
        );
        final visualMetadata = _extractVisualMetadata(fallbackCard, subject);
        diagramData = _generateDiagramData(fallbackCard, visualMetadata);
      }
      
      cards.add(FlashCard(
        id: (i + 1).toString(),
        deckId: 'ai_generated',
        type: cardType,
        front: front,
        back: back,
        clozeMask: clozeMask,
        multipleChoiceOptions: options,
        correctAnswerIndex: correctIndex,
        difficulty: template['difficulty'] as int,
        diagramData: diagramData,
      ));
    }

    return cards;
  }

  /// Generate personalized motivational pet message
  /// 
  /// NOW ENHANCED WITH PERSONALIZATION:
  /// - Uses user's name and preferences for personalized messaging
  /// - Adapts tone based on user's age and educational level
  /// - Considers user's study habits and preferences
  /// - Personalizes encouragement based on user's learning style
  Future<String> getPetMessage(
      String petName, Map<String, dynamic> userStats, User user) async {
    try {
      final userContext = _buildPersonalizationContext(user);
      final prompt = '''
      You are $petName, ${user.name}'s friendly study companion pet. 
      
      User Context: $userContext
      
      Study Performance:
      - ${user.name} studied ${userStats['cardsToday']} cards today
      - Success rate: ${userStats['successRate']}%
      
      Generate a personalized, encouraging message (max 30 words) that:
      - Uses ${user.name}'s name naturally
      - Matches their learning style (${user.preferences.learningStyle})
      - Considers their educational level and background
      - Provides appropriate encouragement based on their performance
      
      Use a cute, supportive tone with relevant emojis:
      ''';

      return await _callAI(prompt);
    } catch (e) {
      return "Great job studying today, ${user.name}! I'm proud of your hard work! 🐾";
    }
  }

  /// Get personalized study recommendation based on user stats and preferences
  Future<String> getStudyRecommendation(Map<String, dynamic> stats, User user) async {
    try {
      final userContext = _buildPersonalizationContext(user);
      final prefs = user.preferences;
      
      final prompt = '''
      User Profile: $userContext
      
      Study Performance:
      - Cards studied: ${stats['cardsStudied']}
      - Success rate: ${stats['successRate']}%
      - Study streak: ${stats['studyStreak']} days
      
      Study Preferences:
      - Preferred study time: ${prefs.studyStartHour}:00 - ${prefs.studyEndHour}:00
      - Max cards per day: ${prefs.maxCardsPerDay}
      - Learning style: ${prefs.learningStyle}
      - Difficulty preference: ${prefs.difficultyPreference}
      
      Provide a personalized study recommendation (max 50 words) that:
      - Addresses ${user.name} directly
      - Considers their learning style and preferences
      - Gives specific, actionable advice
      - Matches their educational level and goals
      ''';

      return await _callAI(prompt);
    } catch (e) {
      return "Keep up the great work, ${user.name}! Try to study a little each day to maintain your momentum.";
    }
  }

  /// Improve an existing flashcard with personalization
  Future<FlashCard> enhanceFlashcard(FlashCard originalCard, User user) async {
    try {
      final userContext = _buildPersonalizationContext(user);
      final learningStyleInstructions = _getLearningStyleInstructions(user.preferences.learningStyle);
      
      final prompt = '''
      User Profile: $userContext
      
      Learning Style Adaptation:
      $learningStyleInstructions
      
      Improve this flashcard for ${user.name}:
      Question: ${originalCard.front}
      Answer: ${originalCard.back}
      Current Difficulty: ${originalCard.difficulty}
      
      Enhance the flashcard by:
      - Making it more suitable for ${user.preferences.learningStyle} learning style
      - Adjusting complexity for ${user.preferences.difficultyPreference} difficulty preference
      - Adding context relevant to ${user.school ?? 'their educational background'}
      - Improving clarity and engagement
      
      Return as JSON: {"question": "...", "answer": "...", "explanation": "..."}
      ''';

      final response = await _callAI(prompt);
      final improved = json.decode(response);

      return FlashCard(
        id: originalCard.id,
        deckId: originalCard.deckId,
        type: originalCard.type,
        front: improved['question'] ?? originalCard.front,
        back: _buildEnhancedAnswer(improved, user),
        clozeMask: originalCard.clozeMask,
        multipleChoiceOptions: originalCard.multipleChoiceOptions,
        correctAnswerIndex: originalCard.correctAnswerIndex,
        difficulty: originalCard.difficulty,
      );
    } catch (e) {
      debugPrint('Card enhancement error: $e');
      return originalCard;
    }
  }

  /// Private method to call AI API - supports multiple providers
  Future<String> _callAI(String prompt) async {
    if (!isConfigured) {
      throw Exception('AI service not configured');
    }

    switch (_provider) {
      case AIProvider.openai:
        return await _callOpenAI(prompt);
      case AIProvider.google:
        return await _callGoogleAI(prompt);
      case AIProvider.anthropic:
        return await callAnthropic(prompt);
      case AIProvider.ollama:
        return await callOllama(prompt);
      case AIProvider.localModel:
        return await callLocalModel(prompt);
    }
  }

  /// OpenAI API call
  Future<String> _callOpenAI(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'gpt-4o-mini',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception(
          'OpenAI API call failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Google AI (Gemini) API call with retry logic
  Future<String> _callGoogleAI(String prompt) async {
    return await callGoogleAIWithRetry(prompt, 0);
  }

  Future<String> callGoogleAIWithRetry(String prompt, int retryCount) async {
    const maxRetries = 3;
    const baseDelay = Duration(seconds: 2);

    debugPrint('=== Google AI API Call (Attempt ${retryCount + 1}) ===');
    debugPrint('Base URL: $_baseUrl');
    debugPrint('API Key format: ${_apiKey.substring(0, 12)}... (length: ${_apiKey.length})');
    
    debugPrint(
        'URL: $_baseUrl/models/$_textModel:generateContent?key=${_apiKey.substring(0, 8)}...');
    debugPrint('Prompt length: ${prompt.length}');

    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/models/$_textModel:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1500,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      // Handle 503 Service Unavailable (model overloaded)
      if (response.statusCode == 503 && retryCount < maxRetries) {
        final delay = baseDelay * (retryCount + 1);
        debugPrint(
            'API overloaded (503), retrying in ${delay.inSeconds} seconds... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(delay);
        return await callGoogleAIWithRetry(prompt, retryCount + 1);
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final result =
              data['candidates'][0]['content']['parts'][0]['text'].trim();
          debugPrint('Extracted result: $result');
          return result;
        } else {
          debugPrint('No candidates in response: $data');
          throw Exception('No response from Google AI');
        }
      } else {
        debugPrint('API call failed with status ${response.statusCode}');
        throw Exception(
            'Google AI API call failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (e.toString().contains('503') && retryCount < maxRetries) {
        final delay = baseDelay * (retryCount + 1);
        debugPrint(
            'Exception indicates 503 error, retrying in ${delay.inSeconds} seconds... (${retryCount + 1}/$maxRetries)');
        await Future.delayed(delay);
        return await callGoogleAIWithRetry(prompt, retryCount + 1);
      }
      debugPrint('Exception in Google AI call: $e');
      rethrow;
    }
  }

  /// Anthropic Claude API call
  Future<String> callAnthropic(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/messages'),
      headers: {
        'x-api-key': _apiKey,
        'Content-Type': 'application/json',
        'anthropic-version': '2023-06-01',
      },
      body: json.encode({
        'model': 'claude-3-haiku-20240307',
        'max_tokens': 1500,
        'messages': [
          {'role': 'user', 'content': prompt}
        ]
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['content'][0]['text'].trim();
    } else {
      throw Exception(
          'Anthropic API call failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Ollama (Local open source models) API call
  Future<String> callOllama(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/generate'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'model': 'llama2',
        'prompt': prompt,
        'stream': false,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['response'].trim();
    } else {
      throw Exception(
          'Ollama API call failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Local model API call
  Future<String> callLocalModel(String prompt) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'model': 'local-model',
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'max_tokens': 1500,
        'temperature': 0.7,
      }),
    ).timeout(const Duration(seconds: 45));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['choices'][0]['message']['content'].trim();
    } else {
      throw Exception(
          'Local model API call failed: ${response.statusCode} - ${response.body}');
    }
  }

  /// Repairs truncated JSON by completing missing brackets and braces
  String _repairTruncatedJSON(String truncatedJSON) {
    try {
      // Remove code block markers if present
      String json = truncatedJSON.trim();
      if (json.startsWith('```json')) {
        json = json.replaceFirst('```json', '');
      }
      if (json.endsWith('```')) {
        json = json.substring(0, json.lastIndexOf('```'));
      }
      json = json.trim();

      // Count opening and closing brackets/braces
      int openBrackets = '['.allMatches(json).length;
      int closeBrackets = ']'.allMatches(json).length;
      int openBraces = '{'.allMatches(json).length;
      int closeBraces = '}'.allMatches(json).length;

      // If we have incomplete objects, try to close them
      if (openBraces > closeBraces) {
        // Check if we're in the middle of a property
        if (!json.endsWith('}') && !json.endsWith(',')) {
          // If we ended mid-property value, close with quote if needed
          if (json.split('"').length % 2 == 0) {
            json += '"';
          }
        }

        // Close missing braces
        for (int i = 0; i < (openBraces - closeBraces); i++) {
          json += '}';
        }
      }

      // Close missing brackets
      if (openBrackets > closeBrackets) {
        for (int i = 0; i < (openBrackets - closeBrackets); i++) {
          json += ']';
        }
      }

      return json;
    } catch (e) {
      debugPrint('JSON repair failed: $e');
      return truncatedJSON;
    }
  }

  /// Test AI connection
  Future<bool> testConnection() async {
    if (!isConfigured) return false;

    try {
      await _callAI(
          'Hello, this is a test. Please respond with "Connection successful".');
      return true;
    } catch (e) {
      debugPrint('AI connection test failed: $e');
      return false;
    }
  }

  /// Debug method for testing personalized flashcard generation
  Future<String> debugFlashcardGeneration(
      String content, String subject, User user) async {
    try {
      final prompt = _generatePersonalizedPrompt(content, subject, user, 5, analytics: null);
      final response = await _callAI(prompt);
      debugPrint('Raw AI Response for debugging: $response');
      return response;
    } catch (e) {
      debugPrint('Debug generation error: $e');
      return 'Error: $e';
    }
  }

  /// Generate visual representation for a concept using DALL-E API
  /// @param concept - The concept to visualize
  /// @param user - User object for personalization
  /// @param subject - Subject context for appropriate imagery
  /// @return URL to generated image or null if generation fails
  Future<String?> generateVisualRepresentation({
    required String concept,
    required User user,
    required String subject,
  }) async {
    if (!isConfigured || user.preferences.learningStyle != 'visual') {
      return null;
    }

    try {
      // Create educational prompt optimized for learning
      final visualPrompt = _buildVisualPrompt(concept, subject, user);
      
      // Call image generation API
      final imageUrl = await _generateImageWithDALLE(visualPrompt);
      
      if (imageUrl != null) {
        debugPrint('Generated visual representation for: $concept');
        return imageUrl;
      }
      
      return null;
    } catch (e) {
      debugPrint('Visual generation error: $e');
      return null;
    }
  }

  /// Generate flashcard image using Gemini 2.5 Flash Image Preview
  /// @param content - The flashcard content to visualize
  /// @param subject - Subject context for appropriate imagery
  /// @param visualType - Type of visual (flowchart, concept_map, comparison, etc.)
  /// @return Generated image data or null if generation fails
  Future<String?> generateFlashcardImageWithGemini({
    required String content,
    required String subject,
    required String visualType,
  }) async {
    if (!isConfigured) {
      debugPrint('❌ Gemini 2.5 Image: AI service not configured');
      return null;
    }

    debugPrint('🔄 Attempting Gemini 2.5 image generation...');
    debugPrint('📝 Content: $content');
    debugPrint('📚 Subject: $subject');
    debugPrint('🎨 Visual Type: $visualType');
    debugPrint('🤖 Using model: $_imageModel');
    
    final prompt = _buildImagePrompt(content, subject, visualType);
    debugPrint('🎯 Generated prompt length: ${prompt.length} characters');
    
    try {
      final url = '$_baseUrl/models/$_imageModel:generateContent?key=${_apiKey.substring(0, 8)}...';
      debugPrint('🌐 Request URL: $url');
      
      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_imageModel:generateContent?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 1500,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      debugPrint('📊 Gemini 2.5 Image response status: ${response.statusCode}');
      debugPrint('📄 Gemini 2.5 Image response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final result = data['candidates'][0]['content']['parts'][0]['text'].trim();
          debugPrint('✅ Gemini 2.5 image generation SUCCESS!');
          debugPrint('🖼️ Generated content preview: ${result.substring(0, result.length > 100 ? 100 : result.length)}...');
          return result;
        } else {
          debugPrint('⚠️ Gemini 2.5 response has no candidates');
        }
      } else {
        debugPrint('❌ Gemini 2.5 API error: ${response.statusCode}');
        debugPrint('📋 Error details: ${response.body}');
        
        // Provide helpful context for common errors
        if (response.statusCode == 429) {
          debugPrint('🚫 QUOTA EXHAUSTED: gemini-2.5-flash-image-preview has very limited free tier quotas');
          debugPrint('💡 Free tier limits: ~15 requests/day, ~1000 tokens/minute');
          debugPrint('📈 Consider upgrading to paid tier for more image generation capacity');
          debugPrint('🔄 Falling back to interactive diagrams (this is expected behavior)');
        } else if (response.statusCode == 404) {
          debugPrint('🔍 MODEL NOT FOUND: gemini-2.5-flash-image-preview may not be available in your region');
        } else if (response.statusCode == 403) {
          debugPrint('🔐 ACCESS DENIED: Model may require paid tier or special access permissions');
        }
      }
      return null;
    } catch (e) {
      debugPrint('💥 Gemini 2.5 image generation FAILED: $e');
      // Additional context for common exception patterns
      if (e.toString().contains('429')) {
        debugPrint('🚫 This is a quota limit error - totally normal for free tier usage');
      }
      return null;
    }
  }

  /// Generate audio content for auditory learners using TTS
  /// @param text - Text content to convert to audio
  /// @param user - User object for personalization
  /// @param subject - Subject context for appropriate voice settings
  /// @return URL to generated audio or null if generation fails
  Future<String?> generateAudioContent({
    required String text,
    required User user,
    required String subject,
  }) async {
    if (!isConfigured || user.preferences.learningStyle != 'auditory') {
      return null;
    }

    try {
      // Create optimized audio content
      final audioText = _buildAudioScript(text, subject, user);
      
      // Generate audio using TTS service
      final audioUrl = await _generateAudioWithTTS(audioText, user);
      
      if (audioUrl != null) {
        debugPrint('Generated audio content for auditory learning');
        return audioUrl;
      }
      
      return null;
    } catch (e) {
      debugPrint('Audio generation error: $e');
      return null;
    }
  }

  /// Generate interactive diagram data for complex concepts
  /// @param concept - The concept to diagram
  /// @param subject - Subject context for appropriate diagram type
  /// @param user - User object for personalization
  /// @return JSON diagram data or null if generation fails
  Future<String?> generateDiagramData({
    required String concept,
    required User user,
    required String subject,
  }) async {
    if (!isConfigured) return null;

    try {
      // Determine if concept benefits from diagramming
      if (_shouldGenerateDiagram(concept, subject)) {
        final diagramType = _determineDiagramType(concept, subject);
        final diagramData = await _generateDiagramJSON(concept, diagramType, user);
        
        if (diagramData != null) {
          debugPrint('Generated diagram data for: $concept');
          return diagramData;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Diagram generation error: $e');
      return null;
    }
  }

  /// Build optimized visual prompt for DALL-E
  String _buildVisualPrompt(String concept, String subject, User user) {
    final prompt = StringBuffer();
    
    // Base educational style
    prompt.write('Create a clean, educational diagram illustrating: $concept. ');
    
    // Subject-specific styling
    switch (subject.toLowerCase()) {
      case 'biology':
      case 'anatomy':
        prompt.write('Scientific illustration style, labeled anatomical features. ');
        break;
      case 'chemistry':
        prompt.write('Molecular structure diagram with clear atomic bonds. ');
        break;
      case 'physics':
        prompt.write('Technical diagram with forces, vectors, and measurements. ');
        break;
      case 'mathematics':
        prompt.write('Geometric diagram with clear mathematical relationships. ');
        break;
      case 'history':
        prompt.write('Historical illustration with period-appropriate imagery. ');
        break;
      default:
        prompt.write('Simple, clear educational diagram. ');
    }
    
    // Educational level adaptation
    if (user.age != null && user.age! < 18) {
      prompt.write('Age-appropriate, colorful, engaging visual. ');
    } else if (user.school?.toLowerCase().contains('university') == true) {
      prompt.write('Advanced academic level, detailed technical illustration. ');
    }
    
    // Final formatting
    prompt.write('Style: minimalist, high contrast, clear labels, white background.');
    
    return prompt.toString();
  }

  /// Build optimized image prompt for Gemini 2.5 Flash Image Preview
  String _buildImagePrompt(String content, String subject, String visualType) {
    return '''
Create an educational diagram showing the content: $content

The image should be a clean, academic-style $visualType with the following elements:

Subject: $subject
Visual Type: $visualType (flowchart/concept_map/comparison/structure)

Requirements:
- Professional, educational infographic style
- Clean lines and clear visual hierarchy
- High contrast for readability on mobile devices
- Use appropriate colors for $subject (blue for science, green for biology, etc.)
- Include clear labels and text that's readable when scaled down
- Minimalist design suitable for flashcard display
- White or light background with good contrast
- No photorealistic elements, focus on diagram clarity
- Style: educational diagram, clean typography, professional presentation
- Aspect ratio: 16:9 for flashcard display

The diagram should help visual learners understand the concept through clear visual elements, logical flow, and structured information presentation.

For $visualType specifically:
${_getVisualTypeInstructions(visualType)}

Subject-specific styling for $subject:
${_getSubjectSpecificStyling(subject)}
''';
  }

  /// Get specific instructions for visual type
  String _getVisualTypeInstructions(String visualType) {
    switch (visualType.toLowerCase()) {
      case 'flowchart':
        return '- Use rectangular boxes for processes, diamonds for decisions\n- Connect with clear arrows showing flow direction\n- Include start/end points\n- Use consistent spacing and alignment';
      case 'concept_map':
        return '- Central concept in the middle with related concepts around it\n- Use connecting lines with relationship labels\n- Hierarchical structure showing main and sub-concepts\n- Different colors for different concept levels';
      case 'comparison':
        return '- Side-by-side layout comparing two or more items\n- Use tables, columns, or split sections\n- Highlight similarities and differences\n- Clear categorization of compared elements';
      case 'structure':
        return '- Show organizational or physical structure\n- Use nested boxes or tree-like layout\n- Clear parent-child relationships\n- Consistent styling for same-level elements';
      case 'timeline':
        return '- Chronological layout with clear time markers\n- Events positioned along timeline\n- Use consistent spacing for time periods\n- Include key dates and descriptions';
      default:
        return '- Clear visual hierarchy with logical information flow\n- Balanced composition with appropriate spacing\n- Consistent styling throughout the diagram';
    }
  }

  /// Get subject-specific styling instructions
  String _getSubjectSpecificStyling(String subject) {
    switch (subject.toLowerCase()) {
      case 'biology':
      case 'anatomy':
        return '- Use organic shapes and natural colors (greens, blues)\n- Include anatomical accuracy where applicable\n- Use scientific terminology and proper labels';
      case 'chemistry':
        return '- Use molecular structure representations\n- Include chemical formulas and equations\n- Use standard chemistry colors and symbols';
      case 'physics':
        return '- Include mathematical formulas and equations\n- Use arrows for forces and vectors\n- Include units and measurements';
      case 'mathematics':
        return '- Use geometric shapes and mathematical notation\n- Include formulas and equations\n- Use precise geometric relationships';
      case 'history':
        return '- Use timeline elements and historical imagery\n- Include dates and historical context\n- Use period-appropriate visual elements';
      case 'computer science':
        return '- Use flowchart elements and algorithmic structures\n- Include code snippets or pseudocode\n- Use technical diagrams and system representations';
      default:
        return '- Use professional, academic styling\n- Include relevant terminology and concepts\n- Maintain educational focus and clarity';
    }
  }

  /// Build optimized audio script for TTS
  String _buildAudioScript(String text, String subject, User user) {
    final script = StringBuffer();
    
    // Add pronunciation guides for subject-specific terms
    String processedText = text;
    
    // Subject-specific pronunciations
    if (subject.toLowerCase() == 'chemistry') {
      processedText = processedText
          .replaceAll('H2O', 'H-two-O')
          .replaceAll('CO2', 'C-O-two')
          .replaceAll('NaCl', 'sodium chloride');
    } else if (subject.toLowerCase() == 'biology') {
      processedText = processedText
          .replaceAll('DNA', 'D-N-A')
          .replaceAll('RNA', 'R-N-A')
          .replaceAll('ATP', 'A-T-P');
    }
    
    // Add pauses for better comprehension
    processedText = processedText
        .replaceAll('.', '. <break time="0.5s"/>')
        .replaceAll(',', ', <break time="0.3s"/>');
    
    script.write(processedText);
    
    return script.toString();
  }

  /// Generate image using DALL-E API
  Future<String?> _generateImageWithDALLE(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/images/generations'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
          'n': 1,
          'size': '512x512',
          'response_format': 'url',
          'quality': 'standard',
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'][0]['url'] as String;
      } else {
        debugPrint('DALL-E API error: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Image generation error: $e');
      return null;
    }
  }

  /// Generate audio using TTS service
  Future<String?> _generateAudioWithTTS(String text, User user) async {
    try {
      // For now, return a placeholder URL - would integrate with real TTS service
      // In production: integrate with Google Cloud TTS, Amazon Polly, or similar
      final audioUrl = await _mockTTSGeneration(text, user);
      return audioUrl;
    } catch (e) {
      debugPrint('TTS generation error: $e');
      return null;
    }
  }

  /// Mock TTS generation for development (replace with real TTS service)
  Future<String?> _mockTTSGeneration(String text, User user) async {
    // Simulate TTS processing time
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Return mock audio URL - in production, this would be real TTS service
    return 'https://studypals-audio.com/generated/${DateTime.now().millisecondsSinceEpoch}.mp3';
  }

  /// Determine if concept should have a diagram
  bool _shouldGenerateDiagram(String concept, String subject) {
    final processKeywords = ['process', 'cycle', 'flow', 'system', 'structure', 'relationship'];
    final scienceSubjects = ['biology', 'chemistry', 'physics', 'anatomy'];
    
    final conceptLower = concept.toLowerCase();
    final subjectLower = subject.toLowerCase();
    
    return processKeywords.any((keyword) => conceptLower.contains(keyword)) ||
           scienceSubjects.contains(subjectLower);
  }

  /// Determine appropriate diagram type
  String _determineDiagramType(String concept, String subject) {
    final conceptLower = concept.toLowerCase();
    
    if (conceptLower.contains('cycle') || conceptLower.contains('process')) {
      return 'flowchart';
    } else if (conceptLower.contains('structure') || conceptLower.contains('anatomy')) {
      return 'structure';
    } else if (conceptLower.contains('relationship') || conceptLower.contains('connection')) {
      return 'network';
    } else {
      return 'concept-map';
    }
  }

  /// Generate diagram JSON data
  Future<String?> _generateDiagramJSON(String concept, String diagramType, User user) async {
    try {
      // Create basic diagram structure
      final diagram = {
        'type': diagramType,
        'concept': concept,
        'elements': _generateDiagramElements(concept, diagramType),
        'style': _getDiagramStyle(user),
        'metadata': {
          'generated_at': DateTime.now().toIso8601String(),
          'learning_style': user.preferences.learningStyle,
        }
      };
      
      return jsonEncode(diagram);
    } catch (e) {
      debugPrint('Diagram JSON generation error: $e');
      return null;
    }
  }

  /// Generate diagram elements based on concept
  List<Map<String, dynamic>> _generateDiagramElements(String concept, String diagramType) {
    // Basic element generation - in production, this would be more sophisticated
    switch (diagramType) {
      case 'flowchart':
        return [
          {'id': '1', 'type': 'start', 'label': 'Start', 'x': 100, 'y': 50},
          {'id': '2', 'type': 'process', 'label': concept, 'x': 200, 'y': 150},
          {'id': '3', 'type': 'end', 'label': 'End', 'x': 300, 'y': 250},
        ];
      case 'structure':
        return [
          {'id': '1', 'type': 'node', 'label': 'Main', 'x': 200, 'y': 100},
          {'id': '2', 'type': 'node', 'label': 'Component 1', 'x': 100, 'y': 200},
          {'id': '3', 'type': 'node', 'label': 'Component 2', 'x': 300, 'y': 200},
        ];
      default:
        return [
          {'id': '1', 'type': 'concept', 'label': concept, 'x': 200, 'y': 150},
        ];
    }
  }

  /// Get diagram styling based on user preferences
  Map<String, dynamic> _getDiagramStyle(User user) {
    return {
      'theme': user.preferences.theme,
      'fontSize': user.preferences.fontSize * 12,
      'colors': {
        'primary': user.preferences.primaryColor,
        'background': user.preferences.theme == 'dark' ? '#2c3e50' : '#ffffff',
        'text': user.preferences.theme == 'dark' ? '#ecf0f1' : '#2c3e50',
      }
    };
  }

  /// Generate flashcards optimized for visual learners using existing Gemini API
  Future<List<FlashCard>> generateVisualFlashcardsFromText(
    String content,
    String subject,
    User user, {
    int count = 5,
  }) async {
    debugPrint('=== Visual Flashcard Generation Debug ===');
    debugPrint('Content: $content');
    debugPrint('Subject: $subject');
    debugPrint('Learning Style: ${user.preferences.learningStyle}');
    
    try {
      // Generate visual-optimized prompt
      final visualPrompt = _buildVisualLearnerPrompt(content, subject, user, count);
      debugPrint('Visual prompt created');
      
      // Call existing AI system with visual prompt
      final response = await _callAI(visualPrompt);
      debugPrint('Received AI response for visual content');
      
      // Parse response into flashcards
      final baseCards = await _parseVisualFlashcardsResponse(response, subject);
      debugPrint('Parsed ${baseCards.length} base cards');
      
      // Enhance with visual elements for visual learners
      if (user.preferences.learningStyle == 'visual' || user.preferences.learningStyle == 'adaptive') {
        final enhancedCards = await _enhanceWithVisualContent(baseCards, subject, user);
        debugPrint('Enhanced ${enhancedCards.length} cards with visual content');
        return enhancedCards;
      }
      
      return baseCards;
    } catch (e) {
      debugPrint('Error in visual flashcard generation: $e');
      return _createFallbackFlashcards(subject, content, count: count, user: user);
    }
  }

  /// Build specialized prompt for visual learners
  String _buildVisualLearnerPrompt(String content, String subject, User user, int count) {
    return '''
You are creating flashcards specifically optimized for VISUAL LEARNERS studying $subject.

CRITICAL VISUAL LEARNING REQUIREMENTS:
- Include detailed visual descriptions in ALL answers
- Describe step-by-step visual processes
- Use spatial relationships and visual metaphors
- Mention colors, shapes, patterns, and diagrams when relevant
- Create content that can be easily visualized or diagrammed

Content to learn: $content

Create exactly $count flashcards in this EXACT JSON format:
[
  {
    "question": "Clear question that sets up visual thinking",
    "answer": "Detailed answer with rich visual descriptions. Include phrases like 'visualize this as...', 'imagine a diagram showing...', 'picture the process as...'",
    "cardType": "basic",
    "difficulty": 3,
    "visualHints": "Specific visual elements that would help: diagrams, charts, colors, spatial arrangements",
    "diagramType": "flowchart|concept_map|comparison|process|structure"
  }
]

Focus on creating content that naturally lends itself to visual representation. Each answer should paint a clear mental picture.
''';
  }

  /// Parse visual flashcards response with enhanced error handling
  Future<List<FlashCard>> _parseVisualFlashcardsResponse(String response, String subject) async {
    try {
      // Clean the response
      String cleanResponse = response.trim();
      int startIndex = cleanResponse.indexOf('[');
      int endIndex = cleanResponse.lastIndexOf(']');
      
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleanResponse = cleanResponse.substring(startIndex, endIndex + 1);
      }
      
      final cardsData = json.decode(cleanResponse) as List;
      
      return cardsData.map((cardJson) {
        return FlashCard(
          id: DateTime.now().millisecondsSinceEpoch.toString() + 
              cardsData.indexOf(cardJson).toString(),
          deckId: 'visual_generated',
          type: _parseCardType(cardJson['cardType']),
          front: cardJson['question'] ?? cardJson['front'] ?? 'Visual Question',
          back: cardJson['answer'] ?? cardJson['back'] ?? 'Visual Answer',
          difficulty: cardJson['difficulty'] ?? 3,
          multipleChoiceOptions: cardJson['multipleChoiceOptions'] != null 
              ? List<String>.from(cardJson['multipleChoiceOptions'])
              : ['Option A', 'Option B', 'Option C', 'Option D'],
          correctAnswerIndex: cardJson['correctAnswerIndex'] ?? 0,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error parsing visual flashcards: $e');
      return [];
    }
  }

  /// Enhance flashcards with visual content and metadata
  Future<List<FlashCard>> _enhanceWithVisualContent(
    List<FlashCard> baseCards, 
    String subject,
    User user,
  ) async {
    final enhancedCards = <FlashCard>[];
    
    for (final card in baseCards) {
      try {
        // Generate visual metadata
        final visualMetadata = _extractVisualMetadata(card, subject);
        
        String? imageUrl;
        String? diagramData;
        bool usedGeminiImage = false;
        
        if (user.preferences.learningStyle == 'visual' || user.preferences.learningStyle == 'adaptive') {
          // PRIMARY: Try to generate actual image using Gemini 2.5 Flash Image Preview
          final visualType = visualMetadata['visualType'] ?? 'concept_map';
          
          debugPrint('Attempting Gemini 2.5 image generation for card: ${card.id}');
          imageUrl = await generateFlashcardImageWithGemini(
            content: '${card.front}\n${card.back}',
            subject: subject,
            visualType: visualType,
          );
          
          if (imageUrl != null) {
            // SUCCESS: Gemini 2.5 generated an image
            usedGeminiImage = true;
            visualMetadata['hasAIGeneratedImage'] = 'true';
            visualMetadata['imageModel'] = _imageModel;
            visualMetadata['textModel'] = _textModel;
            visualMetadata['imageSource'] = 'gemini-2.5-flash-image-preview';
            debugPrint('✅ Gemini 2.5 image generation successful for card: ${card.id}');
          } else {
            // FALLBACK: Generate interactive diagram using existing JSON system
            debugPrint('⚠️ Gemini 2.5 failed (likely quota limit), using interactive diagrams for card: ${card.id}');
            debugPrint('📊 This is expected behavior - interactive diagrams work great as fallback!');
            debugPrint('💡 Interactive diagrams provide: concept maps, flowcharts, and clickable elements');
            diagramData = _generateDiagramData(card, visualMetadata);
            
            // Use existing visual placeholder with diagram
            imageUrl = _generateVisualPlaceholder(card.front, subject, visualMetadata);
            visualMetadata['hasAIGeneratedImage'] = 'false';
            visualMetadata['hasInteractiveDiagram'] = 'true';
            visualMetadata['imageSource'] = 'interactive-json-diagram';
            visualMetadata['textModel'] = _textModel;
            debugPrint('✅ Interactive diagram fallback successful for card: ${card.id}');
          }
        } else {
          // Non-visual learners: Use existing system
          imageUrl = _generateVisualPlaceholder(card.front, subject, visualMetadata);
          diagramData = _generateDiagramData(card, visualMetadata);
          visualMetadata['hasAIGeneratedImage'] = 'false';
          visualMetadata['hasInteractiveDiagram'] = 'true';
          visualMetadata['imageSource'] = 'non-visual-learner';
          visualMetadata['textModel'] = _textModel;
        }
        
        // If we used Gemini image, we don't need diagram data (image replaces diagram)
        if (usedGeminiImage) {
          diagramData = null;
          visualMetadata['hasInteractiveDiagram'] = 'false';
        }
        
        // Create enhanced flashcard
        final enhancedCard = FlashCard(
          id: card.id,
          deckId: card.deckId,
          type: card.type,
          front: card.front,
          back: card.back,
          difficulty: card.difficulty,
          multipleChoiceOptions: card.multipleChoiceOptions,
          correctAnswerIndex: card.correctAnswerIndex,
          lastQuizAttempt: card.lastQuizAttempt,
          lastQuizCorrect: card.lastQuizCorrect,
          imageUrl: imageUrl,
          diagramData: diagramData,
          visualMetadata: visualMetadata,
        );
        
        enhancedCards.add(enhancedCard);
      } catch (e) {
        debugPrint('Error enhancing card ${card.id}: $e');
        // Add original card if enhancement fails
        enhancedCards.add(card);
      }
    }
    
    return enhancedCards;
  }

  /// Extract visual metadata from flashcard content
  Map<String, String> _extractVisualMetadata(FlashCard card, String subject) {
    final metadata = <String, String>{
      'subject': subject,
      'visualType': 'enhanced_text',
      'hasVisualElements': 'true',
      'generatedAt': DateTime.now().toIso8601String(),
    };
    
    final content = '${card.front} ${card.back}'.toLowerCase();
    
    // Determine visual type based on content analysis
    if (content.contains(RegExp(r'\b(process|steps|cycle|sequence|stages?)\b'))) {
      metadata['visualType'] = 'flowchart';
      metadata['layoutType'] = 'sequential';
    } else if (content.contains(RegExp(r'\b(structure|parts|components?|anatomy)\b'))) {
      metadata['visualType'] = 'diagram';
      metadata['layoutType'] = 'hierarchical';
    } else if (content.contains(RegExp(r'\b(compare|versus|vs|difference|similarities?)\b'))) {
      metadata['visualType'] = 'comparison_chart';
      metadata['layoutType'] = 'side_by_side';
    } else if (content.contains(RegExp(r'\b(relationship|connects?|links?|network)\b'))) {
      metadata['visualType'] = 'concept_map';
      metadata['layoutType'] = 'radial';
    } else {
      metadata['visualType'] = 'concept_map';
      metadata['layoutType'] = 'radial';
    }
    
    // Add subject-specific enhancements
    if (subject.toLowerCase().contains('biology')) {
      metadata['subjectStyle'] = 'biological_diagram';
    } else if (subject.toLowerCase().contains('chemistry')) {
      metadata['subjectStyle'] = 'molecular_diagram';
    } else if (subject.toLowerCase().contains('physics')) {
      metadata['subjectStyle'] = 'scientific_diagram';
    } else if (subject.toLowerCase().contains('math')) {
      metadata['subjectStyle'] = 'mathematical_diagram';
    } else {
      metadata['subjectStyle'] = 'educational_diagram';
    }
    
    return metadata;
  }

  /// Generate visual placeholder URL for educational content
  String _generateVisualPlaceholder(String concept, String subject, Map<String, String> metadata) {
    final encodedConcept = Uri.encodeComponent(concept.replaceAll(RegExp(r'[^\w\s]'), ''));
    final visualType = metadata['visualType'] ?? 'diagram';
    
    // Create educational placeholder with visual indicators
    final placeholderText = '${encodedConcept.replaceAll('%20', '+')}_${visualType.toUpperCase()}';
    final color = _getSubjectColor(subject);
    
    return 'https://via.placeholder.com/500x400/$color/FFFFFF?text=$placeholderText';
  }

  /// Get subject-appropriate colors for visual placeholders
  String _getSubjectColor(String subject) {
    final subjectLower = subject.toLowerCase();
    if (subjectLower.contains('biology')) return '4CAF50'; // Green
    if (subjectLower.contains('chemistry')) return '2196F3'; // Blue
    if (subjectLower.contains('physics')) return 'FF9800'; // Orange
    if (subjectLower.contains('math')) return '9C27B0'; // Purple
    if (subjectLower.contains('history')) return '795548'; // Brown
    if (subjectLower.contains('literature')) return 'E91E63'; // Pink
    return '607D8B'; // Blue Grey default
  }

  /// Generate structured diagram data based on content
  String _generateDiagramData(FlashCard card, Map<String, String> metadata) {
    final visualType = metadata['visualType'] ?? 'concept_map';
    
    try {
      switch (visualType) {
        case 'flowchart':
          return json.encode(_generateFlowchartData(card));
        case 'concept_map':
          return json.encode(_generateConceptMapData(card));
        case 'comparison_chart':
          return json.encode(_generateComparisonData(card));
        case 'diagram':
          return json.encode(_generateStructuralDiagramData(card));
        default:
          return json.encode(_generateGenericDiagramData(card));
      }
    } catch (e) {
      debugPrint('Error generating diagram data: $e');
      return json.encode(_generateGenericDiagramData(card));
    }
  }

  /// Generate flowchart diagram data
  Map<String, dynamic> _generateFlowchartData(FlashCard card) {
    final steps = _extractStepsFromContent(card.back);
    final elements = <Map<String, dynamic>>[];
    
    for (int i = 0; i < steps.length; i++) {
      elements.add({
        'id': i + 1,
        'type': i == 0 ? 'start' : (i == steps.length - 1 ? 'end' : 'process'),
        'label': _truncateText(steps[i], 25),
        'x': 250,
        'y': 80 + (i * 100),
        'width': 200,
        'height': 60,
      });
    }
    
    return {
      'type': 'flowchart',
      'title': _truncateText(card.front, 30),
      'elements': elements,
      'connections': _generateFlowchartConnections(elements.length),
      'layout': 'vertical',
    };
  }

  /// Generate concept map diagram data
  Map<String, dynamic> _generateConceptMapData(FlashCard card) {
    final centralConcept = _extractMainConcept(card.front);
    final relatedConcepts = _extractRelatedConcepts(card.back);
    final elements = <Map<String, dynamic>>[];
    
    // Central concept
    elements.add({
      'id': 1,
      'type': 'central',
      'label': _truncateText(centralConcept, 20),
      'x': 250,
      'y': 200,
      'width': 120,
      'height': 60,
    });
    
    // Related concepts in circle around center
    for (int i = 0; i < relatedConcepts.length && i < 6; i++) {
      final angle = (i * 60) * (3.14159 / 180); // Convert to radians
      final radius = 120;
      elements.add({
        'id': i + 2,
        'type': 'concept',
        'label': _truncateText(relatedConcepts[i], 15),
        'x': 250 + (radius * cos(angle)),
        'y': 200 + (radius * sin(angle)),
        'width': 100,
        'height': 50,
      });
    }
    
    return {
      'type': 'concept_map',
      'title': _truncateText(card.front, 30),
      'elements': elements,
      'connections': _generateConceptMapConnections(elements.length),
      'layout': 'radial',
    };
  }

  /// Generate comparison chart data
  Map<String, dynamic> _generateComparisonData(FlashCard card) {
    final comparisonItems = _extractComparisonItems(card.back);
    final elements = <Map<String, dynamic>>[];
    
    for (int i = 0; i < comparisonItems.length && i < 2; i++) {
      elements.add({
        'id': i + 1,
        'type': 'comparison_item',
        'label': _truncateText(comparisonItems[i]['title'] ?? 'Item ${i + 1}', 20),
        'description': _truncateText(comparisonItems[i]['description'] ?? '', 50),
        'x': 100 + (i * 250),
        'y': 150,
        'width': 200,
        'height': 100,
      });
    }
    
    return {
      'type': 'comparison',
      'title': _truncateText(card.front, 30),
      'elements': elements,
      'layout': 'side_by_side',
    };
  }

  /// Generate structural diagram data
  Map<String, dynamic> _generateStructuralDiagramData(FlashCard card) {
    final components = _extractComponentsFromContent(card.back);
    final elements = <Map<String, dynamic>>[];
    
    for (int i = 0; i < components.length && i < 5; i++) {
      elements.add({
        'id': i + 1,
        'type': 'component',
        'label': _truncateText(components[i], 20),
        'x': 150 + (i % 3) * 150,
        'y': 150 + (i ~/ 3) * 100,
        'width': 120,
        'height': 60,
      });
    }
    
    return {
      'type': 'structure',
      'title': _truncateText(card.front, 30),
      'elements': elements,
      'layout': 'hierarchical',
    };
  }

  /// Generate generic diagram data as fallback
  Map<String, dynamic> _generateGenericDiagramData(FlashCard card) {
    return {
      'type': 'generic',
      'title': _truncateText(card.front, 30),
      'elements': [
        {
          'id': 1,
          'type': 'main_concept',
          'label': _truncateText(_extractMainConcept(card.front), 20),
          'x': 250,
          'y': 200,
          'width': 150,
          'height': 80,
        }
      ],
      'layout': 'centered',
    };
  }

  /// Extract sequential steps from content
  List<String> _extractStepsFromContent(String content) {
    final steps = <String>[];
    final sentences = content.split(RegExp(r'[.!?]+'));
    
    for (final sentence in sentences) {
      final trimmed = sentence.trim();
      if (trimmed.isNotEmpty && (
          trimmed.toLowerCase().contains(RegExp(r'\b(first|then|next|finally|step|stage)\b')) ||
          trimmed.contains(RegExp(r'^\d+\.')) ||
          steps.isEmpty
      )) {
        steps.add(trimmed);
      }
    }
    
    return steps.isEmpty ? [content] : steps.take(5).toList();
  }

  /// Extract main concept from question
  String _extractMainConcept(String front) {
    return front
        .replaceAll(RegExp(r'^(what|how|when|where|why|which)\s+', caseSensitive: false), '')
        .replaceAll(RegExp(r'[?!.]+$'), '')
        .trim();
  }

  /// Extract related concepts from answer
  List<String> _extractRelatedConcepts(String back) {
    final concepts = <String>[];
    final words = back.split(RegExp(r'[,\s]+'));
    
    for (final word in words) {
      final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
      if (cleaned.length > 4 && !_isCommonWord(cleaned.toLowerCase())) {
        concepts.add(cleaned);
      }
    }
    
    return concepts.take(6).toList();
  }

  /// Extract comparison items from content
  List<Map<String, String>> _extractComparisonItems(String back) {
    final sentences = back.split(RegExp(r'[.!?]+'));
    final items = <Map<String, String>>[];
    
    if (sentences.length >= 2) {
      items.add({
        'title': 'First Aspect',
        'description': sentences[0].trim(),
      });
      items.add({
        'title': 'Second Aspect', 
        'description': sentences[1].trim(),
      });
    } else {
      final halfLength = back.length ~/ 2;
      items.add({
        'title': 'Aspect A',
        'description': back.substring(0, halfLength).trim(),
      });
      items.add({
        'title': 'Aspect B',
        'description': back.substring(halfLength).trim(),
      });
    }
    
    return items;
  }

  /// Extract components from content
  List<String> _extractComponentsFromContent(String content) {
    final components = <String>[];
    
    // Look for lists or enumerated items
    final listItems = content.split(RegExp(r'[,;]'));
    for (final item in listItems) {
      final trimmed = item.trim();
      if (trimmed.isNotEmpty && trimmed.length > 3) {
        components.add(trimmed);
      }
    }
    
    // If no clear list, extract key nouns
    if (components.isEmpty) {
      final words = content.split(RegExp(r'\s+'));
      for (final word in words) {
        final cleaned = word.replaceAll(RegExp(r'[^\w]'), '');
        if (cleaned.length > 5 && !_isCommonWord(cleaned.toLowerCase())) {
          components.add(cleaned);
        }
      }
    }
    
    return components.take(5).toList();
  }

  /// Generate flowchart connections
  List<Map<String, dynamic>> _generateFlowchartConnections(int elementCount) {
    final connections = <Map<String, dynamic>>[];
    
    for (int i = 1; i < elementCount; i++) {
      connections.add({
        'from': i,
        'to': i + 1,
        'type': 'arrow',
      });
    }
    
    return connections;
  }

  /// Generate concept map connections
  List<Map<String, dynamic>> _generateConceptMapConnections(int elementCount) {
    final connections = <Map<String, dynamic>>[];
    
    // Connect all outer concepts to central concept (id: 1)
    for (int i = 2; i <= elementCount; i++) {
      connections.add({
        'from': 1,
        'to': i,
        'type': 'line',
      });
    }
    
    return connections;
  }

  /// Check if word is common and should be filtered out
  bool _isCommonWord(String word) {
    const commonWords = {
      'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with', 'by',
      'is', 'are', 'was', 'were', 'have', 'has', 'had', 'will', 'would', 'could',
      'should', 'may', 'might', 'can', 'this', 'that', 'these', 'those', 'it',
      'they', 'them', 'their', 'there', 'here', 'when', 'where', 'why', 'how',
      'what', 'which', 'who', 'whose', 'whom', 'a', 'an', 'some', 'any', 'all',
      'each', 'every', 'no', 'not', 'very', 'more', 'most', 'much', 'many'
    };
    return commonWords.contains(word);
  }

  /// Truncate text to specified length with ellipsis
  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Cosine function for positioning elements in circle
  double cos(double radians) {
    // Simple cosine approximation
    final x = radians % (2 * 3.14159);
    return 1 - (x * x) / 2 + (x * x * x * x) / 24;
  }

  /// Sine function for positioning elements in circle
  double sin(double radians) {
    // Simple sine approximation
    final x = radians % (2 * 3.14159);
    return x - (x * x * x) / 6 + (x * x * x * x * x) / 120;
  }

  /// Generate multi-modal content for a flashcard based on user preferences
  /// This orchestrates visual, audio, and diagram generation
  Future<FlashCard> _generateMultiModalContent(
    FlashCard baseCard,
    String subject,
    User user,
    String sourceContent,
  ) async {
    try {
      String? imageUrl;
      String? audioUrl;
      String? diagramData;
      Map<String, dynamic>? visualMetadata;

      final learningStyle = user.preferences.learningStyle;
      
      // Generate content based on learning style preferences
      final tasks = <Future<void>>[];

      // Visual content for visual learners or adaptive learners
      if (learningStyle == 'visual' || learningStyle == 'adaptive') {
        tasks.add(_generateVisualContentTask(baseCard, subject, user).then((result) {
          imageUrl = result['imageUrl'] as String?;
          visualMetadata = result['visualMetadata'] as Map<String, dynamic>?;
        }));
      }

      // Audio content for auditory learners or adaptive learners
      if (learningStyle == 'auditory' || learningStyle == 'adaptive') {
        tasks.add(_generateAudioContentTask(baseCard, subject, user).then((url) {
          audioUrl = url;
        }));
      }

      // Diagram content for kinesthetic/visual learners or adaptive learners
      if (learningStyle == 'kinesthetic' || 
          learningStyle == 'visual' || 
          learningStyle == 'adaptive') {
        tasks.add(_generateDiagramContentTask(baseCard, subject, user).then((data) {
          diagramData = data;
        }));
      }

      // Execute all generation tasks concurrently with timeout
      await Future.wait(tasks).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          debugPrint('Multi-modal content generation timed out for card: ${baseCard.id}');
          return <void>[];
        },
      );

      // Create enhanced flashcard with multi-modal content
      return FlashCard(
        id: baseCard.id,
        deckId: baseCard.deckId,
        type: baseCard.type,
        front: baseCard.front,
        back: baseCard.back,
        clozeMask: baseCard.clozeMask,
        multipleChoiceOptions: baseCard.multipleChoiceOptions,
        correctAnswerIndex: baseCard.correctAnswerIndex,
        difficulty: baseCard.difficulty,
        lastQuizAttempt: baseCard.lastQuizAttempt,
        lastQuizCorrect: baseCard.lastQuizCorrect,
        imageUrl: imageUrl,
        audioUrl: audioUrl,
        diagramData: diagramData,
        visualMetadata: visualMetadata?.map((key, value) => MapEntry(key, value.toString())),
      );

    } catch (e) {
      debugPrint('Error generating multi-modal content for card ${baseCard.id}: $e');
      // Return original card if multi-modal generation fails
      return baseCard;
    }
  }

  /// Generate visual content task with comprehensive error handling
  Future<Map<String, dynamic>> _generateVisualContentTask(
    FlashCard card,
    String subject,
    User user,
  ) async {
    return await MultiModalErrorHandler.executeWithFallback<Map<String, dynamic>>(
      operationName: 'visual_generation',
      operation: () async {
        final imageUrl = await generateVisualRepresentation(
          concept: card.front,
          subject: subject,
          user: user,
        );
        
        final result = {
          'imageUrl': imageUrl,
          'visualMetadata': {
            'concept': card.front,
            'subject': subject,
            'generatedAt': DateTime.now().toIso8601String(),
          }
        };
        
        // Validate the generated content
        if (!MultiModalErrorHandler.validateVisualContent(result)) {
          throw ValidationException('Generated visual content failed validation');
        }
        
        return result;
      },
      fallback: () => MultiModalErrorHandler.generateFallbackVisualContent(
        concept: card.front,
        subject: subject,
        user: user,
      ),
    ) ?? {};
  }

  /// Generate audio content task with comprehensive error handling
  Future<String?> _generateAudioContentTask(
    FlashCard card,
    String subject,
    User user,
  ) async {
    return await MultiModalErrorHandler.executeWithFallback<String?>(
      operationName: 'audio_generation',
      operation: () async {
        final audioUrl = await generateAudioContent(
          text: '${card.front}. ${card.back}',
          subject: subject,
          user: user,
        );
        
        // Validate the generated content
        if (!MultiModalErrorHandler.validateAudioContent(audioUrl)) {
          throw ValidationException('Generated audio content failed validation');
        }
        
        return audioUrl;
      },
      fallback: () => MultiModalErrorHandler.generateFallbackAudioContent(
        text: '${card.front}. ${card.back}',
        subject: subject,
        user: user,
      ),
    );
  }

  /// Generate diagram content task with comprehensive error handling
  Future<String?> _generateDiagramContentTask(
    FlashCard card,
    String subject,
    User user,
  ) async {
    return await MultiModalErrorHandler.executeWithFallback<String?>(
      operationName: 'diagram_generation',
      operation: () async {
        // Use sophisticated diagram generation instead of basic one
        final visualMetadata = _extractVisualMetadata(card, subject);
        final diagramData = _generateDiagramData(card, visualMetadata);
        
        // Validate the generated content
        if (!MultiModalErrorHandler.validateDiagramContent(diagramData)) {
          throw ValidationException('Generated diagram content failed validation');
        }
        
        return diagramData;
      },
      fallback: () => MultiModalErrorHandler.generateFallbackDiagramContent(
        concept: card.front,
        subject: subject,
        user: user,
      ),
    );
  }

  /// Check Gemini 2.5 Flash Image Preview availability and quota status
  /// This is useful for proactive quota management
  Future<Map<String, dynamic>> checkImageModelStatus() async {
    if (!isConfigured) {
      return {
        'available': false,
        'reason': 'AI service not configured',
        'fallbackRecommended': true,
      };
    }

    try {
      // Make a minimal test request to check quota/availability
      final response = await http.post(
        Uri.parse('$_baseUrl/models/$_imageModel:generateContent?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'contents': [
            {
              'parts': [
                {'text': 'Test request to check availability. Please respond with "OK".'}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 10,
          }
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {
          'available': true,
          'reason': 'Model is available and quota allows requests',
          'fallbackRecommended': false,
          'model': _imageModel,
        };
      } else if (response.statusCode == 429) {
        final errorData = json.decode(response.body);
        return {
          'available': false,
          'reason': 'Quota exceeded - free tier limits reached',
          'fallbackRecommended': true,
          'errorCode': 429,
          'details': 'Free tier has very limited quotas (~15 requests/day)',
          'suggestion': 'Interactive diagrams work great as alternative!',
          'retryAfter': _extractRetryDelay(errorData),
        };
      } else if (response.statusCode == 404) {
        return {
          'available': false,
          'reason': 'Model not found - may not be available in your region',
          'fallbackRecommended': true,
          'errorCode': 404,
        };
      } else {
        return {
          'available': false,
          'reason': 'API error: ${response.statusCode}',
          'fallbackRecommended': true,
          'errorCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'available': false,
        'reason': 'Network or API error: $e',
        'fallbackRecommended': true,
        'exception': e.toString(),
      };
    }
  }

  /// Extract retry delay from error response
  String? _extractRetryDelay(Map<String, dynamic> errorData) {
    try {
      final details = errorData['error']?['details'] as List?;
      if (details != null) {
        for (final detail in details) {
          if (detail['@type'] == 'type.googleapis.com/google.rpc.RetryInfo') {
            return detail['retryDelay'];
          }
        }
      }
    } catch (e) {
      // Ignore parsing errors
    }
    return null;
  }

  /// Log helpful information about the current setup
  void logSystemStatus() {
    debugPrint('=== StudyPals AI System Status ===');
    debugPrint('🤖 Text Model: $_textModel (${_provider.name})');
    debugPrint('🖼️ Image Model: $_imageModel');
    debugPrint('⚙️ Configured: $isConfigured');
    debugPrint('🔧 Base URL: $_baseUrl');
    
    if (isConfigured) {
      debugPrint('✅ Dual model system active');
      debugPrint('📊 Text generation: Always available with $_textModel');
      debugPrint('🎨 Image generation: Available when quota allows');
      debugPrint('🔄 Fallback: Interactive JSON diagrams always available');
    } else {
      debugPrint('❌ System not configured - check API keys');
    }
    debugPrint('=====================================');
  }
}
