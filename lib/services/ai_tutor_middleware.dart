// ai_tutor_middleware.dart
// Pre and post processing hooks for AI tutor responses

import '../models/user_profile_data.dart';
import '../models/chat_message.dart';
import '../services/session_context.dart';
import '../services/user_profile_store.dart';
import '../services/learning_style_detector.dart';
import '../services/memory_claim_validator.dart';
import '../services/math_engine.dart';
import '../config/feature_flags.dart';
import 'dart:developer' as developer;

/// Context prepared for LLM call
class PreProcessedContext {
  final SessionContext sessionContext;
  final UserProfileData? profile;
  final DetectedLearningStyle? detectedStyle;
  final String systemPrompt;
  final Map<String, dynamic> metadata;

  PreProcessedContext({
    required this.sessionContext,
    this.profile,
    this.detectedStyle,
    required this.systemPrompt,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
}

/// Result of post-processing
class PostProcessedResponse {
  final String response;
  final bool memoryValid;
  final bool mathValid;
  final List<String> corrections;
  final Map<String, dynamic> telemetry;

  PostProcessedResponse({
    required this.response,
    required this.memoryValid,
    required this.mathValid,
    List<String>? corrections,
    Map<String, dynamic>? telemetry,
  })  : corrections = corrections ?? [],
        telemetry = telemetry ?? {};

  bool get hasIssues => !memoryValid || !mathValid;
  int get issueCount => (memoryValid ? 0 : 1) + (mathValid ? 0 : 1);
}

/// Middleware for AI tutor request/response processing
class AITutorMiddleware {
  final UserProfileStore _profileStore;
  final Map<String, SessionContext> _sessions = {};

  AITutorMiddleware({
    UserProfileStore? profileStore,
  }) : _profileStore = profileStore ?? UserProfileStore();

  /// Pre-process user message before sending to LLM
  Future<PreProcessedContext> preProcessMessage({
    required String userId,
    required String message,
    int maxMessages = 50,
  }) async {
    developer.log('Pre-processing message for user: $userId',
        name: 'AITutorMiddleware');

    // Get or create session context
    var sessionContext = _sessions[userId];
    if (sessionContext == null) {
      sessionContext = SessionContext(userId: userId, maxMessages: maxMessages);
      _sessions[userId] = sessionContext;
    }

    // Load user profile (if opted in)
    UserProfileData? profile;
    try {
      profile = await _profileStore.getProfile(userId);
    } catch (e) {
      developer.log('Error loading profile: $e',
          name: 'AITutorMiddleware', error: e);
    }

    // Detect learning style from session + current message
    DetectedLearningStyle? detectedStyle;
    try {
      detectedStyle = LearningStyleDetector.estimate(
        sessionContext: sessionContext,
        currentMessage: message,
      );
      
      developer.log('Learning style detected: ${detectedStyle.getSummary()}',
          name: 'AITutorMiddleware');
    } catch (e) {
      developer.log('Error detecting learning style: $e',
          name: 'AITutorMiddleware', error: e);
    }

    // Build enhanced system prompt
    final systemPrompt = _buildSystemPrompt(
      profile: profile,
      sessionContext: sessionContext,
      detectedStyle: detectedStyle,
    );

    return PreProcessedContext(
      sessionContext: sessionContext,
      profile: profile,
      detectedStyle: detectedStyle,
      systemPrompt: systemPrompt,
      metadata: {
        'messageLength': message.length,
        'sessionMessageCount': sessionContext.getAllMessages().length,
        'hasProfile': profile != null,
        'styleConfidence': detectedStyle?.confidence ?? 0.0,
      },
    );
  }

  /// Post-process LLM response before returning to user
  Future<PostProcessedResponse> postProcessResponse({
    required String userId,
    required String message,
    required String llmResponse,
    PreProcessedContext? context,
  }) async {
    developer.log('Post-processing response for user: $userId',
        name: 'AITutorMiddleware');

    final corrections = <String>[];
    final telemetry = <String, dynamic>{};
    var finalResponse = llmResponse;

    // Get session context
    final sessionContext = _sessions[userId] ?? 
        SessionContext(userId: userId);
    
    final profile = context?.profile;

    // Step 1: Memory Claim Validation (if enabled)
    var memoryValid = true;
    if (FeatureFlags.isEnabled('memoryValidation', userId)) {
      try {
        final memoryValidation = MemoryClaimValidator.validate(
          response: llmResponse,
          sessionContext: sessionContext,
          profile: profile,
          threshold: 0.75,
        );

        memoryValid = memoryValidation.valid;
        telemetry['memoryClaimsDetected'] = memoryValidation.claims.length;
        telemetry['invalidMemoryClaims'] = 
            memoryValidation.claims.where((c) => !c.isValid).length;

        if (!memoryValid && memoryValidation.correctedResponse != null) {
          finalResponse = memoryValidation.correctedResponse!;
          corrections.add('Corrected false memory claims');
          developer.log('Memory claims corrected',
              name: 'AITutorMiddleware');
        }
      } catch (e) {
        developer.log('Error in memory validation: $e',
            name: 'AITutorMiddleware', error: e);
        telemetry['memoryValidationError'] = e.toString();
      }
    }

    // Step 2: Math Validation (if enabled)
    var mathValid = true;
    if (FeatureFlags.isEnabled('mathValidation', userId)) {
      try {
        final mathValidation = await MathEngine.validateAndAnnotate(llmResponse);
        
        mathValid = mathValidation.valid;
        telemetry['mathExpressionsFound'] = 
            mathValidation.calculatedValues?.length ?? 0;
        telemetry['mathIssues'] = mathValidation.issues.length;

        if (!mathValid && mathValidation.correctedSteps != null) {
          finalResponse += '\n\n---\n**Math Verification:**\n${mathValidation.correctedSteps}';
          corrections.add('Added math corrections');
          developer.log('Math corrections added',
              name: 'AITutorMiddleware');
        }
      } catch (e) {
        developer.log('Error in math validation: $e',
            name: 'AITutorMiddleware', error: e);
        telemetry['mathValidationError'] = e.toString();
      }
    }

    // Step 3: Safety & Fallback for multiple failures
    if (!memoryValid && !mathValid) {
      developer.log('Multiple validation failures detected - using fallback',
          name: 'AITutorMiddleware');
      
      finalResponse = _generateFallbackResponse(
        userMessage: message,
        memoryIssue: !memoryValid,
        mathIssue: !mathValid,
      );
      corrections.add('Used safety fallback');
      telemetry['usedFallback'] = true;
    }

    // Update session context with the interaction
    try {
      sessionContext.addMessage(ChatMessage(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        content: message,
        type: MessageType.user,
        format: MessageFormat.text,
      ));
      
      sessionContext.addMessage(ChatMessage(
        id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
        content: finalResponse,
        type: MessageType.assistant,
        format: MessageFormat.text,
      ));
    } catch (e) {
      developer.log('Error updating session context: $e',
          name: 'AITutorMiddleware', error: e);
    }

    return PostProcessedResponse(
      response: finalResponse,
      memoryValid: memoryValid,
      mathValid: mathValid,
      corrections: corrections,
      telemetry: telemetry,
    );
  }

  /// Build enhanced system prompt with context
  String _buildSystemPrompt({
    UserProfileData? profile,
    required SessionContext sessionContext,
    DetectedLearningStyle? detectedStyle,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('System: You are StudyPals Tutor, an expert educational AI assistant.');
    buffer.writeln();
    
    buffer.writeln('CONTEXT PROVIDED:');
    
    // Profile information
    if (profile != null && profile.optInFlags.profileStorage) {
      buffer.writeln('- User Profile: Available (opted in)');
      buffer.writeln('  - Dominant Learning Style: ${profile.learningPreferences.getDominantStyle()}');
      buffer.writeln('  - Preferred Detail Level: ${profile.learningPreferences.preferredDepth}');
      if (profile.skillScores.subjectMastery.isNotEmpty) {
        buffer.writeln('  - Subject Mastery: ${profile.skillScores.subjectMastery.keys.join(", ")}');
      }
    } else {
      buffer.writeln('- User Profile: Not available (user has not opted in)');
    }
    
    // Session context
    buffer.writeln('- Session Context: ${sessionContext.getAllMessages().length} messages');
    final recentTopics = sessionContext.getRecentTopics(topK: 5);
    if (recentTopics.isNotEmpty) {
      buffer.writeln('  - Recent Topics: ${recentTopics.map((t) => t.topic).join(", ")}');
    }
    
    // Detected learning style
    if (detectedStyle != null) {
      buffer.writeln('- Detected Learning Style (current session):');
      buffer.writeln('  - Visual: ${(detectedStyle.preferences.visual * 100).toStringAsFixed(0)}%');
      buffer.writeln('  - Auditory: ${(detectedStyle.preferences.auditory * 100).toStringAsFixed(0)}%');
      buffer.writeln('  - Kinesthetic: ${(detectedStyle.preferences.kinesthetic * 100).toStringAsFixed(0)}%');
      buffer.writeln('  - Reading: ${(detectedStyle.preferences.reading * 100).toStringAsFixed(0)}%');
      buffer.writeln('  - Preferred Depth: ${detectedStyle.preferences.preferredDepth}');
    }
    
    buffer.writeln();
    buffer.writeln('CRITICAL RULES:');
    buffer.writeln('1. NEVER assert prior conversations or stored facts unless sessionContext or userProfile contains supporting evidence.');
    buffer.writeln('   - Use semantic search threshold of 0.75 for memory claims.');
    buffer.writeln('   - If uncertain, ask "Would you like me to explain X?" instead of "We discussed X".');
    buffer.writeln();
    buffer.writeln('2. ALWAYS structure responses in this format:');
    buffer.writeln('   - Start with a 1-2 sentence SHORT ANSWER');
    buffer.writeln('   - Follow with an "Expand" section with examples and details');
    buffer.writeln('   - End with "Next Actions" (2-3 suggestions)');
    buffer.writeln();
    buffer.writeln('3. For mathematical calculations:');
    buffer.writeln('   - Show step-by-step derivation');
    buffer.writeln('   - Double-check arithmetic');
    buffer.writeln('   - Verify final answer');
    buffer.writeln();
    buffer.writeln('4. Emotional awareness:');
    buffer.writeln('   - Acknowledge user emotions (frustration, excitement, confusion)');
    buffer.writeln('   - Offer calming, supportive scaffolding questions');
    buffer.writeln('   - Adapt tone to match user state');
    buffer.writeln();
    buffer.writeln('5. Learning style adaptation:');
    if (detectedStyle != null) {
      final recommendations = LearningStyleDetector.getRecommendations(detectedStyle);
      for (final rec in recommendations) {
        buffer.writeln('   - $rec');
      }
    } else {
      buffer.writeln('   - Offer multiple formats (text, visual descriptions, examples)');
    }
    
    return buffer.toString();
  }

  /// Generate safe fallback response when multiple validations fail
  String _generateFallbackResponse({
    required String userMessage,
    required bool memoryIssue,
    required bool mathIssue,
  }) {
    final buffer = StringBuffer();
    
    buffer.writeln('I want to make sure I give you the most accurate help possible.');
    buffer.writeln();
    
    if (memoryIssue) {
      buffer.writeln('I noticed some uncertainty about our conversation history. ');
    }
    
    if (mathIssue) {
      buffer.writeln('I also want to double-check any calculations to ensure accuracy. ');
    }
    
    buffer.writeln();
    buffer.writeln('To help you best, I can:');
    buffer.writeln('1. **Quick Summary**: Give you a brief overview of the topic');
    buffer.writeln('2. **Step-by-Step Solution**: Walk through the problem methodically');
    buffer.writeln('3. **Extended Explanation**: Provide comprehensive coverage with examples');
    buffer.writeln();
    buffer.writeln('Which approach would be most helpful for you right now?');
    
    return buffer.toString();
  }

  /// Clear session for a user
  void clearSession(String userId) {
    _sessions.remove(userId);
    developer.log('Session cleared for user: $userId',
        name: 'AITutorMiddleware');
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats(String userId) {
    final session = _sessions[userId];
    if (session == null) {
      return {'exists': false};
    }
    return session.getStatistics();
  }
  
  /// ========== PRODUCTION-READY: Complete AI Response Processing ==========
  /// Static method for one-call processing without maintaining middleware instance
  static Future<ProcessedAIResponse> processAIResponse({
    required String userQuery,
    required String aiResponse,
    required SessionContext sessionContext,
    required UserProfileStore userProfileStore,
  }) async {
    developer.log('🔄 Processing AI response through middleware pipeline',
        name: 'AITutorMiddleware');
    
    // 1. Detect learning style from current query
    DetectedLearningStyle? detectedStyle;
    try {
      detectedStyle = LearningStyleDetector.estimate(
        sessionContext: sessionContext,
        currentMessage: userQuery,
      );
      developer.log('📊 Learning style detected: ${detectedStyle.getSummary()}',
          name: 'AITutorMiddleware');
    } catch (e) {
      developer.log('⚠️ Error detecting learning style: $e',
          name: 'AITutorMiddleware', error: e);
    }
    
    // 2. Validate memory claims
    final memoryIssues = <MemoryIssue>[];
    try {
      final memoryResult = MemoryClaimValidator.validate(
        response: aiResponse,
        sessionContext: sessionContext,
      );
      
      if (!memoryResult.valid && memoryResult.claims.isNotEmpty) {
        for (final claim in memoryResult.claims.where((c) => !c.isValid)) {
          // Generate honest alternative for each false claim
          final honestAlt = MemoryClaimValidator.generateHonestAlternative(
            sessionContext.getRecentTopics(topK: 3)
                .map((t) => t.topic)
                .join(', '),
          );
          memoryIssues.add(MemoryIssue(
            claim: claim.claimText,
            honestAlternative: honestAlt,
          ));
        }
        developer.log('⚠️ Found ${memoryIssues.length} false memory claims',
            name: 'AITutorMiddleware');
      } else {
        developer.log('✅ No false memory claims detected',
            name: 'AITutorMiddleware');
      }
    } catch (e) {
      developer.log('⚠️ Error validating memory: $e',
          name: 'AITutorMiddleware', error: e);
    }
    
    // 3. Validate math expressions
    final mathIssues = <MathIssue>[];
    final mathValidations = <MathValidation>[];
    try {
      final mathResults = await MathEngine.validateAndAnnotate(aiResponse);
      
      if (mathResults.hasIssues) {
        for (final issueText in mathResults.issues) {
          mathIssues.add(MathIssue(
            expression: issueText.split(':').first.trim(),
            description: issueText,
            severity: 'warning',
          ));
        }
        developer.log('⚠️ Found ${mathIssues.length} math issues',
            name: 'AITutorMiddleware');
      }
      
      if (mathResults.valid && mathResults.calculatedValues != null) {
        for (final entry in mathResults.calculatedValues!.entries) {
          mathValidations.add(MathValidation(
            expression: entry.key,
            result: entry.value.toString(),
            explanation: 'Validated: ${entry.key} = ${entry.value}',
          ));
        }
        developer.log('✅ Validated ${mathValidations.length} math expressions',
            name: 'AITutorMiddleware');
      }
    } catch (e) {
      developer.log('⚠️ Error validating math: $e',
          name: 'AITutorMiddleware', error: e);
    }
    
    // 4. Build final response
    String finalResponse = aiResponse;
    
    // If there are memory issues, prepend corrections
    if (memoryIssues.isNotEmpty) {
      final corrections = memoryIssues
          .map((issue) => '${issue.honestAlternative}')
          .join('\n\n');
      finalResponse = '$corrections\n\n$aiResponse';
      developer.log('🔧 Prepended memory corrections to response',
          name: 'AITutorMiddleware');
    }
    
    // If there are math issues, append warnings
    if (mathIssues.isNotEmpty) {
      final warnings = mathIssues
          .map((issue) => '⚠️ Math check: ${issue.expression} - ${issue.description}')
          .join('\n');
      finalResponse = '$finalResponse\n\n$warnings';
      developer.log('🔧 Appended math warnings to response',
          name: 'AITutorMiddleware');
    }
    
    developer.log('✅ Middleware processing complete',
        name: 'AITutorMiddleware');
    
    return ProcessedAIResponse(
      finalResponse: finalResponse,
      detectedLearningStyle: detectedStyle,
      memoryIssues: memoryIssues,
      mathIssues: mathIssues,
      mathValidations: mathValidations,
    );
  }
}

/// Complete processed response with all validations
class ProcessedAIResponse {
  final String finalResponse;
  final DetectedLearningStyle? detectedLearningStyle;
  final List<MemoryIssue> memoryIssues;
  final List<MathIssue> mathIssues;
  final List<MathValidation> mathValidations;
  
  ProcessedAIResponse({
    required this.finalResponse,
    this.detectedLearningStyle,
    List<MemoryIssue>? memoryIssues,
    List<MathIssue>? mathIssues,
    List<MathValidation>? mathValidations,
  })  : memoryIssues = memoryIssues ?? [],
        mathIssues = mathIssues ?? [],
        mathValidations = mathValidations ?? [];
        
  bool get hasIssues => memoryIssues.isNotEmpty || mathIssues.isNotEmpty;
  int get issueCount => memoryIssues.length + mathIssues.length;
}

/// Memory claim issue details
class MemoryIssue {
  final String claim;
  final String honestAlternative;
  
  MemoryIssue({
    required this.claim,
    required this.honestAlternative,
  });
}

/// Math validation issue details
class MathIssue {
  final String expression;
  final String description;
  final String severity;
  
  MathIssue({
    required this.expression,
    required this.description,
    required this.severity,
  });
}

/// Math validation success details
class MathValidation {
  final String expression;
  final String result;
  final String explanation;
  
  MathValidation({
    required this.expression,
    required this.result,
    required this.explanation,
  });
}
