// learning_style_detector.dart
// Detects user learning preferences from conversation patterns

import '../models/user_profile_data.dart';
import '../models/chat_message.dart';
import 'session_context.dart';
import 'dart:developer' as developer;

/// Detected learning style from conversation analysis
class DetectedLearningStyle {
  final LearningStylePreferences preferences;
  final double confidence; // 0.0 to 1.0
  final Map<String, List<String>> evidence; // style -> example phrases

  DetectedLearningStyle({
    required this.preferences,
    required this.confidence,
    Map<String, List<String>>? evidence,
  }) : evidence = evidence ?? {};

  String getSummary() {
    final dominant = preferences.getDominantStyle();
    final depth = preferences.preferredDepth;
    return 'Dominant: $dominant ($depth detail) - Confidence: ${(confidence * 100).toStringAsFixed(0)}%';
  }
}

/// Detects learning styles from user messages and interaction patterns
class LearningStyleDetector {
  // Visual indicators
  static final _visualKeywords = {
    'show',
    'see',
    'look',
    'visual',
    'diagram',
    'picture',
    'image',
    'graph',
    'chart',
    'illustration',
    'draw',
    'sketch',
    'color',
    'map',
    'video',
    'watch',
    'visualize',
    'display',
    'example',
    'demonstration'
  };

  // Auditory indicators
  static final _auditoryKeywords = {
    'explain',
    'tell',
    'say',
    'hear',
    'listen',
    'sound',
    'speak',
    'talk',
    'discuss',
    'describe',
    'verbal',
    'lecture',
    'audio',
    'voice',
    'read aloud',
    'pronunciation',
    'rhythm',
    'tone'
  };

  // Kinesthetic/hands-on indicators
  static final _kinestheticKeywords = {
    'do',
    'practice',
    'try',
    'hands-on',
    'interactive',
    'experiment',
    'build',
    'make',
    'create',
    'work through',
    'apply',
    'exercise',
    'activity',
    'physical',
    'movement',
    'touch',
    'feel',
    'manipulate'
  };

  // Reading/writing indicators
  static final _readingKeywords = {
    'write',
    'read',
    'text',
    'note',
    'list',
    'summary',
    'outline',
    'document',
    'article',
    'book',
    'essay',
    'definition',
    'description',
    'written',
    'bullet points',
    'paragraph'
  };

  // Depth preference indicators
  static final _briefKeywords = {
    'quick',
    'brief',
    'short',
    'simple',
    'concise',
    'summary',
    'tldr',
    'key points',
    'main idea',
    'overview',
    'just tell me',
    'in a nutshell'
  };

  static final _detailedKeywords = {
    'detailed',
    'explain fully',
    'comprehensive',
    'in-depth',
    'thorough',
    'complete',
    'all the details',
    'step-by-step',
    'elaborate',
    'extensive',
    'deep dive',
    'everything'
  };

  /// Estimate learning style from session context and current message
  static DetectedLearningStyle estimate({
    required SessionContext sessionContext,
    String? currentMessage,
  }) {
    final messages = sessionContext.getAllMessages();

    // Combine all user messages
    final userMessages = messages
        .where((m) => m.type == MessageType.user)
        .map((m) => m.content.toLowerCase())
        .toList();

    if (currentMessage != null) {
      userMessages.add(currentMessage.toLowerCase());
    }

    final allText = userMessages.join(' ');

    // Calculate style scores
    final visualScore = _calculateStyleScore(allText, _visualKeywords);
    final auditoryScore = _calculateStyleScore(allText, _auditoryKeywords);
    final kinestheticScore =
        _calculateStyleScore(allText, _kinestheticKeywords);
    final readingScore = _calculateStyleScore(allText, _readingKeywords);

    // Calculate depth preference
    final briefScore = _calculateStyleScore(allText, _briefKeywords);
    final detailedScore = _calculateStyleScore(allText, _detailedKeywords);

    final preferredDepth = briefScore > detailedScore * 1.5
        ? 'brief'
        : detailedScore > briefScore * 1.5
            ? 'detailed'
            : 'medium';

    // Calculate confidence based on amount of data
    final messageCount = userMessages.length;
    final confidence =
        _calculateConfidence(messageCount, allText.split(' ').length);

    // Collect evidence
    final evidence = <String, List<String>>{
      'visual': _findEvidence(allText, _visualKeywords),
      'auditory': _findEvidence(allText, _auditoryKeywords),
      'kinesthetic': _findEvidence(allText, _kinestheticKeywords),
      'reading': _findEvidence(allText, _readingKeywords),
    };

    developer.log(
        'Learning style detected: V:$visualScore A:$auditoryScore K:$kinestheticScore R:$readingScore',
        name: 'LearningStyleDetector');

    return DetectedLearningStyle(
      preferences: LearningStylePreferences(
        visual: visualScore,
        auditory: auditoryScore,
        kinesthetic: kinestheticScore,
        reading: readingScore,
        preferredDepth: preferredDepth,
      ),
      confidence: confidence,
      evidence: evidence,
    );
  }

  /// Calculate style score from keyword frequency
  static double _calculateStyleScore(String text, Set<String> keywords) {
    var matchCount = 0;
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      if (keywords.contains(word)) {
        matchCount++;
      }
    }

    // Normalize to 0-1 range with diminishing returns
    final wordCount = words.length;
    if (wordCount == 0) return 0.5; // Default neutral

    final frequency = matchCount / wordCount;
    return (frequency * 20).clamp(0.0, 1.0); // Scale up but cap at 1.0
  }

  /// Calculate confidence based on data available
  static double _calculateConfidence(int messageCount, int wordCount) {
    // Need at least 5 messages and 100 words for high confidence
    final messageConfidence = (messageCount / 5.0).clamp(0.0, 1.0);
    final wordConfidence = (wordCount / 100.0).clamp(0.0, 1.0);

    return (messageConfidence + wordConfidence) / 2.0;
  }

  /// Find example phrases that match keywords
  static List<String> _findEvidence(String text, Set<String> keywords) {
    final evidence = <String>[];
    final sentences = text.split(RegExp(r'[.!?]+'));

    for (final sentence in sentences) {
      for (final keyword in keywords) {
        if (sentence.contains(keyword)) {
          final cleaned = sentence.trim();
          if (cleaned.isNotEmpty && evidence.length < 3) {
            evidence.add(cleaned.length > 80
                ? '${cleaned.substring(0, 80)}...'
                : cleaned);
          }
          break;
        }
      }
    }

    return evidence;
  }

  /// Get recommendations based on detected style
  static List<String> getRecommendations(DetectedLearningStyle style) {
    final recommendations = <String>[];
    final prefs = style.preferences;

    if (prefs.visual > 0.6) {
      recommendations.add('Include diagrams, charts, or visual examples');
      recommendations.add('Use color coding and formatting for clarity');
    }

    if (prefs.auditory > 0.6) {
      recommendations.add('Provide verbal explanations and analogies');
      recommendations.add('Use conversational, descriptive language');
    }

    if (prefs.kinesthetic > 0.6) {
      recommendations.add('Offer hands-on exercises and practice problems');
      recommendations.add('Include interactive examples and experiments');
    }

    if (prefs.reading > 0.6) {
      recommendations.add('Provide written summaries and bullet points');
      recommendations.add('Include references to additional reading materials');
    }

    if (prefs.preferredDepth == 'brief') {
      recommendations.add('Keep responses concise with key takeaways');
      recommendations.add('Offer expandable sections for more detail');
    } else if (prefs.preferredDepth == 'detailed') {
      recommendations.add('Provide comprehensive explanations');
      recommendations.add('Include step-by-step breakdowns');
    }

    return recommendations;
  }
}
