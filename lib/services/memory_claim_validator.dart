// memory_claim_validator.dart
// Validates claims about prior conversations to prevent false memory

import '../services/session_context.dart';
import '../models/user_profile_data.dart';
import 'dart:developer' as developer;

/// Result of memory claim validation
class MemoryValidationResult {
  final bool valid;
  final List<MemoryClaim> claims;
  final String? correctedResponse;

  MemoryValidationResult({
    required this.valid,
    List<MemoryClaim>? claims,
    this.correctedResponse,
  }) : claims = claims ?? [];

  bool get hasInvalidClaims => claims.any((c) => !c.isValid);
}

/// A claim about prior conversation or user information
class MemoryClaim {
  final String claimText;
  final String topic;
  final bool isValid;
  final double confidence;
  final String? evidence;

  MemoryClaim({
    required this.claimText,
    required this.topic,
    required this.isValid,
    required this.confidence,
    this.evidence,
  });
}

/// Validates memory claims in AI responses
class MemoryClaimValidator {
  // PRODUCTION-READY: Comprehensive patterns to catch ALL memory claims
  static final _memoryPatterns = [
    // Direct past conversation references
    RegExp(r"we discussed ([\w\s]+)", caseSensitive: false),
    RegExp(r"we talked about ([\w\s]+)", caseSensitive: false),
    RegExp(r"we covered ([\w\s]+)", caseSensitive: false),
    RegExp(r"we explored ([\w\s]+)", caseSensitive: false),
    RegExp(r"we went over ([\w\s]+)", caseSensitive: false),
    RegExp(r"we looked at ([\w\s]+)", caseSensitive: false),
    RegExp(r"we reviewed ([\w\s]+)", caseSensitive: false),
    RegExp(r"we examined ([\w\s]+)", caseSensitive: false),

    // User statements/actions
    RegExp(r"you (told|said|mentioned|asked|stated|explained) (me )?([\w\s]+)",
        caseSensitive: false),
    RegExp(r"you asked about ([\w\s]+)", caseSensitive: false),
    RegExp(r"you were interested in ([\w\s]+)", caseSensitive: false),
    RegExp(r"you wanted to (know|learn|understand) (about )?([\w\s]+)",
        caseSensitive: false),

    // Temporal references
    RegExp(r"(earlier|previously|before|last time) (we |you |I )?([\w\s]+)",
        caseSensitive: false),
    RegExp(
        r"(in|during) (our|the) (last|previous|earlier) (session|conversation|discussion|chat) ([\w\s]*)",
        caseSensitive: false),

    // Memory/recall language
    RegExp(r"(remember|recall|recollect) (when |that |how |our )?([\w\s]+)",
        caseSensitive: false),
    RegExp(r"(I|we) remember ([\w\s]+)", caseSensitive: false),
    RegExp(r"as (I|we) (mentioned|discussed|said|explained|noted) ([\w\s]+)",
        caseSensitive: false),
    RegExp(r"(do you |don't you )?remember (when |that |how )?([\w\s]+)",
        caseSensitive: false),

    // Teaching/learning references
    RegExp(
        r"(when |as )(I|we) (taught|showed|explained|demonstrated) (you )?([\w\s]+)",
        caseSensitive: false),
    RegExp(r"you (learned|studied|practiced|worked on) ([\w\s]+)",
        caseSensitive: false),
    RegExp(r"(in|from) (our|the) ([\w\s]+) (lesson|session|discussion)",
        caseSensitive: false),

    // User preferences/characteristics
    RegExp(r"your (learning style|preference|interest|goal) (is|was) ([\w\s]+)",
        caseSensitive: false),
    RegExp(r"you prefer ([\w\s]+)", caseSensitive: false),
    RegExp(r"you (like|enjoy|want) ([\w\s]+)", caseSensitive: false),
    RegExp(r"you're (interested in|working on|focusing on) ([\w\s]+)",
        caseSensitive: false),

    // Session/context references
    RegExp(
        r"(based on|from) our (previous|earlier|last) (conversation|discussion|session|chat)",
        caseSensitive: false),
    RegExp(
        r"(continuing|building on) (from |on )?(where we left off|our discussion|what we covered)",
        caseSensitive: false),

    // Specific topic claims
    RegExp(
        r"(we|you|I) (already |just )?(went through|covered|finished|completed) ([\w\s]+)",
        caseSensitive: false),
    RegExp(r"(since|after) we (discussed|talked about|covered) ([\w\s]+)",
        caseSensitive: false),
  ];

  /// Validate memory claims in a response
  static MemoryValidationResult validate({
    required String response,
    required SessionContext sessionContext,
    UserProfileData? profile,
    double threshold = 0.75,
  }) {
    final claims = <MemoryClaim>[];
    var hasInvalidClaims = false;

    // Check for memory claim patterns
    for (final pattern in _memoryPatterns) {
      final matches = pattern.allMatches(response);

      for (final match in matches) {
        final claimText = match.group(0) ?? '';
        final topic = match.group(1) ?? '';

        // Verify claim against session context and profile
        final verification = _verifyClaim(
          topic: topic,
          sessionContext: sessionContext,
          profile: profile,
          threshold: threshold,
        );

        claims.add(verification);

        if (!verification.isValid) {
          hasInvalidClaims = true;
          developer.log(
              'Invalid memory claim detected: "$claimText" (confidence: ${verification.confidence})',
              name: 'MemoryClaimValidator');
        }
      }
    }

    String? correctedResponse;
    if (hasInvalidClaims) {
      correctedResponse = _correctResponse(response, claims, threshold);
    }

    return MemoryValidationResult(
      valid: !hasInvalidClaims,
      claims: claims,
      correctedResponse: correctedResponse,
    );
  }

  /// Verify a specific claim
  static MemoryClaim _verifyClaim({
    required String topic,
    required SessionContext sessionContext,
    UserProfileData? profile,
    required double threshold,
  }) {
    var confidence = 0.0;
    String? evidence;

    // Check session context for topic
    final hasDiscussed =
        sessionContext.hasDiscussedTopic(topic, threshold: threshold);

    if (hasDiscussed) {
      confidence = 0.8;
      final topics = sessionContext.getRecentTopics(topK: 20);
      final matchingTopic = topics.firstWhere(
        (t) =>
            t.topic.toLowerCase().contains(topic.toLowerCase()) ||
            topic.toLowerCase().contains(t.topic.toLowerCase()),
        orElse: () => topics.first,
      );
      evidence = matchingTopic.context;
    }

    // Check profile for preferences
    if (profile != null && _isPreferenceClaim(topic)) {
      final profileConfidence = _checkProfile(topic, profile);
      if (profileConfidence > confidence) {
        confidence = profileConfidence;
        evidence = 'User profile data';
      }
    }

    final isValid = confidence >= threshold;

    return MemoryClaim(
      claimText: topic,
      topic: topic,
      isValid: isValid,
      confidence: confidence,
      evidence: evidence,
    );
  }

  /// Check if claim is about user preferences
  static bool _isPreferenceClaim(String topic) {
    final preferenceKeywords = [
      'learning style',
      'preference',
      'prefer',
      'like',
      'interest',
      'enjoy',
      'visual',
      'auditory',
      'kinesthetic',
    ];

    return preferenceKeywords
        .any((keyword) => topic.toLowerCase().contains(keyword));
  }

  /// Check profile for claim evidence
  static double _checkProfile(String topic, UserProfileData profile) {
    final lowerTopic = topic.toLowerCase();

    // Check learning style preferences
    if (lowerTopic.contains('visual') &&
        profile.learningPreferences.visual > 0.6) {
      return 0.9;
    }
    if (lowerTopic.contains('auditory') &&
        profile.learningPreferences.auditory > 0.6) {
      return 0.9;
    }
    if (lowerTopic.contains('kinesthetic') &&
        profile.learningPreferences.kinesthetic > 0.6) {
      return 0.9;
    }

    // Check subject mastery
    for (final subject in profile.skillScores.subjectMastery.keys) {
      if (lowerTopic.contains(subject.toLowerCase())) {
        return 0.8;
      }
    }

    return 0.0;
  }

  /// Correct response by fixing invalid claims
  static String _correctResponse(
    String response,
    List<MemoryClaim> claims,
    double threshold,
  ) {
    var corrected = response;

    for (final claim in claims) {
      if (!claim.isValid) {
        // Replace false memory claims with honest statements
        final corrections = [
          "I don't have a record of discussing ${claim.topic}",
          "I don't recall us talking about ${claim.topic}",
          "I'm not sure we've covered ${claim.topic} yet",
        ];

        // Find the best correction based on context
        final correction = corrections[0]; // Use first for now

        // Create a corrected statement
        final honestStatement =
            "$correction. Would you like me to explain ${claim.topic} now, "
            "or would you prefer to continue from where you think we left off?";

        // Try to locate and replace the false claim
        // This is simplified - in production, use more sophisticated NLP
        corrected =
            _replaceClaimInText(corrected, claim.claimText, honestStatement);
      }
    }

    return corrected;
  }

  /// Replace claim in text (simplified approach)
  static String _replaceClaimInText(
    String text,
    String claim,
    String replacement,
  ) {
    // Find sentence containing the claim
    final sentences = text.split(RegExp(r'[.!?]+'));
    final buffer = StringBuffer();

    var replaced = false;
    for (var i = 0; i < sentences.length; i++) {
      final sentence = sentences[i].trim();

      if (!replaced && sentence.toLowerCase().contains(claim.toLowerCase())) {
        buffer.write(replacement);
        replaced = true;
      } else if (sentence.isNotEmpty) {
        buffer.write(sentence);
        if (i < sentences.length - 1) {
          buffer.write('. ');
        }
      }
    }

    return buffer.toString();
  }

  /// Generate honest alternative when memory claim is invalid
  static String generateHonestAlternative(String topic) {
    return '''I don't have a record of us discussing $topic in our conversation history. 

However, I'd be happy to help you with $topic! Would you like me to:
1. Provide a quick summary or overview
2. Continue from where you think we left off
3. Start fresh with a comprehensive explanation

Which would be most helpful for you?''';
  }
}
