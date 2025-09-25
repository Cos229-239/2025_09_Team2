import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:studypals/models/card.dart';
import 'package:studypals/models/user.dart';
import 'package:studypals/models/study_analytics.dart';

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
      return _createFallbackFlashcards(subject, content, count: count);
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
      return _createFallbackFlashcards(subject, content, count: count);
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

      List<FlashCard> generatedCards = cardsData
          .map((cardJson) => FlashCard(
                id: DateTime.now().millisecondsSinceEpoch.toString() +
                    cardsData.indexOf(cardJson).toString(),
                deckId: 'ai_generated',
                type: CardType.basic,
                front: cardJson['question'] ?? 'Question',
                back: _buildPersonalizedAnswer(cardJson, user),
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
              ))
          .toList();

      // If we didn't get enough cards, supplement with fallback cards
      if (generatedCards.length < count) {
        debugPrint(
            'Generated ${generatedCards.length} cards (expected $count)');
        final shortfall = count - generatedCards.length;
        debugPrint('Creating $shortfall additional fallback cards');

        final fallbackCards =
            _createFallbackFlashcards(subject, content, count: shortfall);
        generatedCards.addAll(fallbackCards);

        debugPrint('Final card count: ${generatedCards.length}');
      }

      return generatedCards;
    } catch (e) {
      debugPrint('AI flashcard generation error: $e');
      debugPrint('Raw response might not be valid JSON');
      return _createFallbackFlashcards(subject, content, count: count);
    }
  }

  /// Generate personalized prompt based on user preferences and learning style
  String _generatePersonalizedPrompt(String content, String subject, User user, int count, {StudyAnalytics? analytics}) {
    final prefs = user.preferences;
    final learningStyle = prefs.learningStyle;
    final difficultyPref = prefs.difficultyPreference;
    final showHints = prefs.showHints;
    
    // Build personalization context
    String personalContext = _buildPersonalizationContext(user, analytics);
    String learningStyleInstructions = _getLearningStyleInstructions(learningStyle);
    String difficultyInstructions = _getDifficultyInstructions(difficultyPref, subject, analytics);
    String questionTypeInstructions = _getQuestionTypeInstructions(user);
    String performanceContext = _buildPerformanceContext(subject, analytics);
    
    return '''
PERSONALIZED FLASHCARD GENERATION FOR ${user.name.toUpperCase()}

User Profile Context:
$personalContext

Learning Style Adaptation:
$learningStyleInstructions

Difficulty Preference:
$difficultyInstructions
$performanceContext
Create exactly $count flashcards about $subject. Topic: $content

$questionTypeInstructions

CRITICAL: You MUST create exactly $count flashcards. No more, no less.

You MUST respond with ONLY a valid JSON array containing exactly $count objects. No explanation, no extra text.

Format:
[
  {
    "question": "What is...", 
    "answer": "The answer is...",
    "multipleChoiceOptions": ["Option A", "Option B", "Option C", "Option D"],
    "correctAnswerIndex": 2,
    "difficulty": 3${showHints ? ',\n    "explanation": "Additional explanation or context"' : ''}
  }
]

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

  /// Build comprehensive personalization context from user data
  String _buildPersonalizationContext(User user, [StudyAnalytics? analytics]) {
    final prefs = user.preferences;
    final profile = <String>[];
    
    // Educational background
    if (user.school != null) profile.add('Student at ${user.school}');
    if (user.major != null) profile.add('Studying ${user.major}');
    if (user.age != null) profile.add('Age ${user.age}');
    if (user.graduationYear != null) profile.add('Expected graduation: ${user.graduationYear}');
    
    // Learning preferences
    profile.add('Learning style: ${prefs.learningStyle}');
    profile.add('Difficulty preference: ${prefs.difficultyPreference}');
    
    // Study habits
    profile.add('Study schedule: ${prefs.studyStartHour}:00 - ${prefs.studyEndHour}:00');
    profile.add('Max cards per day: ${prefs.maxCardsPerDay}');
    profile.add('Study days: ${prefs.studyDaysNames.join(', ')}');
    profile.add('Break interval: ${prefs.breakInterval} minutes');
    
    // Preferences that affect content
    if (prefs.showHints) profile.add('Prefers detailed explanations');
    if (prefs.autoPlayAudio) profile.add('Audio learner');
    
    // Language and accessibility
    profile.add('Language: ${prefs.language}');
    if (prefs.fontSize != 1.0) profile.add('Font size preference: ${(prefs.fontSize * 100).round()}%');
    
    // Performance context if available
    if (analytics != null) {
      profile.add('Overall performance level: ${analytics.performanceLevel}');
      profile.add('Study streak: ${analytics.currentStreak} days');
      if (analytics.totalStudyTime > 0) {
        profile.add('Total study time: ${analytics.totalStudyTime} minutes');  
      }
    }
    
    return profile.join(', ');
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
    
    return '''QUESTION TYPE VARIETY AND OPTIMIZATION:
- Use primarily multiple choice format with high-quality distractors
- Ensure questions test understanding, not just memorization
- Include application-based scenarios when appropriate
- Vary question stems (What, How, Why, When, Which, etc.)
- Make questions relevant to the user's educational context

$subjectSpecific

QUALITY STANDARDS:
- Questions should be clear, unambiguous, and grammatically correct
- Distractors should be plausible but clearly incorrect upon careful analysis
- Avoid trick questions that rely on ambiguous wording
- Ensure cultural sensitivity and inclusive examples
- Use current, relevant examples that connect to the user's experience''';
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
    
    // Overall performance level
    context.add('User Performance Level: ${analytics.performanceLevel}');
    
    // Subject-specific performance if available
    if (performance != null) {
      context.add('Subject Performance: ${(performance.accuracy * 100).round()}% accuracy');
      context.add('Performance Trend: ${performance.trendDescription}');
      
      // Specific guidance based on performance
      if (performance.accuracy < 0.6) {
        context.add('Focus: Foundational concepts - user needs more basic support');
      } else if (performance.accuracy > 0.85) {
        context.add('Focus: Advanced concepts - user ready for challenges');
      }
      
      if (performance.averageResponseTime > 30) {
        context.add('Note: User takes time to think - allow for complex reasoning');
      }
    }
    
    // Struggling and strong subjects for context
    if (analytics.strugglingSubjects.isNotEmpty) {
      context.add('User struggles with: ${analytics.strugglingSubjects.join(', ')}');
    }
    if (analytics.strongSubjects.isNotEmpty) {
      context.add('User excels at: ${analytics.strongSubjects.join(', ')}');
    }
    
    // Learning patterns
    final patterns = analytics.learningPatterns;
    if (patterns.mostEffectiveLearningStyle != 'adaptive') {
      context.add('Most effective learning style: ${patterns.mostEffectiveLearningStyle}');
    }
    if (patterns.preferredStudyTime != 'flexible') {
      context.add('Optimal study time: ${patterns.preferredStudyTime}');
    }
    
    return context.isNotEmpty ? '\nPERFORMANCE CONTEXT:\n${context.join('\n')}\n' : '';
  }

  /// Build personalized answer with additional context if user prefers hints
  String _buildPersonalizedAnswer(Map<String, dynamic> cardJson, User user) {
    String baseAnswer = cardJson['answer'] ?? 'Answer';
    
    if (user.preferences.showHints && cardJson['explanation'] != null) {
      return '$baseAnswer\n\nℹ️ ${cardJson['explanation']}';
    }
    
    return baseAnswer;
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
      {int count = 5}) {
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

    // Generate the requested number of cards, cycling through templates if needed
    final cards = <FlashCard>[];
    for (int i = 0; i < count; i++) {
      final template = templates[i % templates.length];
      cards.add(FlashCard(
        id: (i + 1).toString(),
        deckId: 'ai_generated',
        type: CardType.basic,
        front: template['front'] as String,
        back: template['back'] as String,
        multipleChoiceOptions: List<String>.from(template['options'] as List),
        correctAnswerIndex: template['correctIndex'] as int,
        difficulty: template['difficulty'] as int,
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
    debugPrint(
        'URL: $_baseUrl/models/gemini-1.5-flash:generateContent?key=${_apiKey.substring(0, 8)}...');
    debugPrint('Prompt length: ${prompt.length}');

    try {
      final response = await http.post(
        Uri.parse(
            '$_baseUrl/models/gemini-1.5-flash:generateContent?key=$_apiKey'),
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
}
