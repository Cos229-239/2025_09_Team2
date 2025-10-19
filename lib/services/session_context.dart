// session_context.dart
// Ephemeral conversation context manager with semantic topic tracking

import '../models/chat_message.dart';
import 'dart:developer' as developer;

/// Represents a topic mentioned in conversation
class ConversationTopic {
  final String topic;
  final double score; // Relevance score 0.0 to 1.0
  final DateTime lastMention;
  final int mentionCount;
  final String context; // Sample text where topic appeared

  ConversationTopic({
    required this.topic,
    required this.score,
    required this.lastMention,
    this.mentionCount = 1,
    this.context = '',
  });

  Map<String, dynamic> toJson() => {
        'topic': topic,
        'score': score,
        'lastMention': lastMention.toIso8601String(),
        'mentionCount': mentionCount,
        'context': context,
      };

  ConversationTopic copyWith({
    double? score,
    DateTime? lastMention,
    int? mentionCount,
    String? context,
  }) {
    return ConversationTopic(
      topic: topic,
      score: score ?? this.score,
      lastMention: lastMention ?? this.lastMention,
      mentionCount: mentionCount ?? this.mentionCount,
      context: context ?? this.context,
    );
  }
}

/// Manages ephemeral conversation context for better AI responses
class SessionContext {
  final String userId;
  final List<ChatMessage> _messages = [];
  final Map<String, ConversationTopic> _topics = {};
  final DateTime _sessionStart;
  final int _maxMessages;

  SessionContext({
    required this.userId,
    int maxMessages = 50,
  })  : _maxMessages = maxMessages,
        _sessionStart = DateTime.now();

  /// Add message to context
  void addMessage(ChatMessage message) {
    _messages.add(message);

    // Trim to max messages
    if (_messages.length > _maxMessages) {
      _messages.removeRange(0, _messages.length - _maxMessages);
    }

    // Extract and track topics
    _extractTopics(message);

    developer.log(
        'Message added to session context. Total: ${_messages.length}',
        name: 'SessionContext');
  }

  /// Get recent messages
  List<ChatMessage> getRecentMessages({int limit = 10}) {
    final startIndex = _messages.length > limit ? _messages.length - limit : 0;
    return _messages.sublist(startIndex);
  }

  /// Get all messages in session
  List<ChatMessage> getAllMessages() {
    return List.unmodifiable(_messages);
  }

  /// Get recent topics with scores
  List<ConversationTopic> getRecentTopics({
    Duration? window,
    int topK = 10,
  }) {
    final now = DateTime.now();
    final cutoff = window != null ? now.subtract(window) : _sessionStart;

    // Filter by time window and sort by score
    final recentTopics = _topics.values
        .where((topic) => topic.lastMention.isAfter(cutoff))
        .toList()
      ..sort((a, b) {
        // Sort by recency-weighted score
        final aScore = a.score * _recencyWeight(a.lastMention, now);
        final bScore = b.score * _recencyWeight(b.lastMention, now);
        return bScore.compareTo(aScore);
      });

    return recentTopics.take(topK).toList();
  }

  /// Check if a topic has been discussed
  bool hasDiscussedTopic(String topic, {double threshold = 0.5}) {
    final normalizedTopic = topic.toLowerCase().trim();

    // Exact match
    if (_topics.containsKey(normalizedTopic)) {
      return _topics[normalizedTopic]!.score >= threshold;
    }

    // Partial match (fuzzy)
    for (final entry in _topics.entries) {
      if (entry.key.contains(normalizedTopic) ||
          normalizedTopic.contains(entry.key)) {
        if (entry.value.score >= threshold) {
          return true;
        }
      }
    }

    return false;
  }

  /// Get context summary for LLM
  String getContextSummary({int messageLimit = 10}) {
    final recentMessages = getRecentMessages(limit: messageLimit);
    final recentTopics = getRecentTopics(topK: 5);

    final buffer = StringBuffer();
    buffer.writeln('Session Context:');
    buffer.writeln(
        'Duration: ${DateTime.now().difference(_sessionStart).inMinutes} minutes');
    buffer.writeln('Messages: ${_messages.length}');

    if (recentTopics.isNotEmpty) {
      buffer.writeln('\nRecent Topics:');
      for (final topic in recentTopics) {
        buffer.writeln(
            '- ${topic.topic} (score: ${topic.score.toStringAsFixed(2)}, mentions: ${topic.mentionCount})');
      }
    }

    if (recentMessages.isNotEmpty) {
      buffer.writeln('\nRecent Messages:');
      for (final msg in recentMessages) {
        final role = msg.type == MessageType.user ? 'User' : 'AI';
        final preview = msg.content.length > 100
            ? '${msg.content.substring(0, 100)}...'
            : msg.content;
        buffer.writeln('[$role]: $preview');
      }
    }

    return buffer.toString();
  }

  /// Extract topics from message content
  void _extractTopics(ChatMessage message) {
    final content = message.content.toLowerCase();

    // Simple keyword extraction (can be enhanced with NLP)
    final keywords = _extractKeywords(content);

    for (final keyword in keywords) {
      if (_topics.containsKey(keyword)) {
        // Update existing topic
        final existing = _topics[keyword]!;
        _topics[keyword] = existing.copyWith(
          lastMention: message.timestamp,
          mentionCount: existing.mentionCount + 1,
          score: (existing.score + 1.0) / 2, // Average with boost
        );
      } else {
        // Add new topic
        _topics[keyword] = ConversationTopic(
          topic: keyword,
          score: 0.7, // Initial relevance
          lastMention: message.timestamp,
          context: content.substring(
            0,
            content.length > 100 ? 100 : content.length,
          ),
        );
      }
    }
  }

  /// Extract keywords from text (simplified)
  List<String> _extractKeywords(String text) {
    // Remove common words
    final stopWords = {
      'the',
      'a',
      'an',
      'and',
      'or',
      'but',
      'in',
      'on',
      'at',
      'to',
      'for',
      'of',
      'with',
      'by',
      'from',
      'as',
      'is',
      'was',
      'are',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'will',
      'would',
      'should',
      'could',
      'may',
      'might',
      'must',
      'can',
      'i',
      'you',
      'he',
      'she',
      'it',
      'we',
      'they',
      'what',
      'which',
      'who',
      'when',
      'where',
      'why',
      'how',
      'this',
      'that',
      'these',
      'those',
    };

    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.length > 3 && !stopWords.contains(word))
        .toList();

    // Return unique keywords
    return words.toSet().toList();
  }

  /// Calculate recency weight for scoring
  double _recencyWeight(DateTime timestamp, DateTime now) {
    final ageMinutes = now.difference(timestamp).inMinutes;
    // Exponential decay: fresh topics get higher weight
    return 1.0 / (1.0 + ageMinutes / 30.0);
  }

  /// Clear session context
  void clear() {
    _messages.clear();
    _topics.clear();
    developer.log('Session context cleared for user: $userId',
        name: 'SessionContext');
  }

  /// Get session statistics
  Map<String, dynamic> getStatistics() {
    return {
      'userId': userId,
      'messageCount': _messages.length,
      'topicCount': _topics.length,
      'sessionDurationMinutes':
          DateTime.now().difference(_sessionStart).inMinutes,
      'sessionStart': _sessionStart.toIso8601String(),
    };
  }
}
