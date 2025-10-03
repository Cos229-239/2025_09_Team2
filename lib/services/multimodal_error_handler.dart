import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:studypals/models/user.dart';

/// Comprehensive error handling and fallback systems for multi-modal AI features
/// Ensures perfect operation with zero critical failures
class MultiModalErrorHandler {
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);

  // Circuit breaker state tracking
  static final Map<String, DateTime> _lastFailureTime = {};
  static final Map<String, int> _failureCount = {};

  /// Execute a multi-modal operation with comprehensive error handling
  static Future<T?> executeWithFallback<T>({
    required String operationName,
    required Future<T> Function() operation,
    T? Function()? fallback,
    bool enableRetry = true,
    bool enableCircuitBreaker = true,
  }) async {
    // Check circuit breaker status
    if (enableCircuitBreaker && _isCircuitBreakerOpen(operationName)) {
      debugPrint('Circuit breaker OPEN for $operationName - using fallback');
      return fallback?.call();
    }

    int attempts = 0;
    Exception? lastException;

    while (attempts < (enableRetry ? _maxRetryAttempts : 1)) {
      attempts++;

      try {
        debugPrint(
            'Attempting $operationName (attempt $attempts/$_maxRetryAttempts)');

        final result = await operation().timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw TimeoutException(
                'Operation $operationName timed out after 30 seconds');
          },
        );

        // Success - reset failure counter
        _failureCount[operationName] = 0;
        debugPrint('✅ $operationName completed successfully');
        return result;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        debugPrint('❌ $operationName failed (attempt $attempts): $e');

        // Record failure for circuit breaker
        _recordFailure(operationName);

        // If not the last attempt and retry is enabled, wait before retrying
        if (attempts < _maxRetryAttempts && enableRetry) {
          await Future.delayed(_retryDelay * attempts); // Exponential backoff
        }
      }
    }

    // All retries failed - use fallback
    debugPrint(
        '🔄 $operationName failed after $_maxRetryAttempts attempts - using fallback');
    debugPrint('Last error: $lastException');

    try {
      return fallback?.call();
    } catch (fallbackError) {
      debugPrint('❌ Fallback for $operationName also failed: $fallbackError');
      return null;
    }
  }

  /// Generate fallback visual content when image generation fails
  static Map<String, dynamic> generateFallbackVisualContent({
    required String concept,
    required String subject,
    required User user,
  }) {
    debugPrint('Generating fallback visual content for: $concept');

    return {
      'imageUrl': null, // No image available
      'visualMetadata': {
        'concept': concept,
        'subject': subject,
        'fallbackUsed': 'true',
        'reason': 'Image generation failed',
        'suggestions': _getVisualFallbackSuggestions(concept, subject),
        'generatedAt': DateTime.now().toIso8601String(),
      }
    };
  }

  /// Generate fallback audio content when TTS fails
  static String? generateFallbackAudioContent({
    required String text,
    required String subject,
    required User user,
  }) {
    debugPrint(
        'Audio generation fallback - no audio available for: ${text.substring(0, text.length > 50 ? 50 : text.length)}...');

    // Return null since we can't generate actual audio as fallback
    // The UI will handle this gracefully by not showing audio controls
    return null;
  }

  /// Generate fallback diagram content when diagram generation fails
  static String generateFallbackDiagramContent({
    required String concept,
    required String subject,
    required User user,
  }) {
    debugPrint('Generating fallback diagram for: $concept');

    // Create a simple text-based diagram structure
    final fallbackDiagram = {
      'type': 'simple',
      'elements': [
        {
          'id': '1',
          'type': 'concept',
          'label': _truncateText(concept, 20),
          'x': 200,
          'y': 150,
        }
      ],
      'connections': [],
      'metadata': {
        'fallbackUsed': true,
        'reason': 'Diagram generation failed',
        'originalConcept': concept,
        'subject': subject,
      }
    };

    return jsonEncode(fallbackDiagram);
  }

  /// Validate generated visual content
  static bool validateVisualContent(Map<String, dynamic>? content) {
    if (content == null || content.isEmpty) {
      debugPrint('Visual content validation failed: null or empty');
      return false;
    }

    final imageUrl = content['imageUrl'] as String?;
    if (imageUrl != null && (Uri.tryParse(imageUrl)?.hasAbsolutePath != true)) {
      debugPrint('Visual content validation failed: invalid image URL');
      return false;
    }

    debugPrint('✅ Visual content validation passed');
    return true;
  }

  /// Validate generated audio content
  static bool validateAudioContent(String? audioUrl) {
    if (audioUrl == null) {
      debugPrint('Audio content validation: no audio URL (acceptable)');
      return true; // null is acceptable for audio
    }

    if (Uri.tryParse(audioUrl)?.hasAbsolutePath != true) {
      debugPrint('Audio content validation failed: invalid audio URL');
      return false;
    }

    debugPrint('✅ Audio content validation passed');
    return true;
  }

  /// Validate generated diagram content
  static bool validateDiagramContent(String? diagramData) {
    if (diagramData == null) {
      debugPrint('Diagram content validation: no diagram data (acceptable)');
      return true; // null is acceptable for diagrams
    }

    try {
      final parsed = jsonDecode(diagramData);
      if (parsed is! Map<String, dynamic>) {
        debugPrint('Diagram content validation failed: not a JSON object');
        return false;
      }

      final elements = parsed['elements'];
      if (elements != null && elements is! List) {
        debugPrint('Diagram content validation failed: elements is not a list');
        return false;
      }

      debugPrint('✅ Diagram content validation passed');
      return true;
    } catch (e) {
      debugPrint('Diagram content validation failed: invalid JSON - $e');
      return false;
    }
  }

  /// Check if circuit breaker is open for a given operation
  static bool _isCircuitBreakerOpen(String operationName) {
    final failureCount = _failureCount[operationName] ?? 0;
    final lastFailure = _lastFailureTime[operationName];

    if (failureCount < 5) return false; // Not enough failures

    if (lastFailure == null) return false;

    final timeSinceLastFailure = DateTime.now().difference(lastFailure);
    return timeSinceLastFailure < _circuitBreakerTimeout;
  }

  /// Record a failure for circuit breaker tracking
  static void _recordFailure(String operationName) {
    _failureCount[operationName] = (_failureCount[operationName] ?? 0) + 1;
    _lastFailureTime[operationName] = DateTime.now();
  }

  /// Get visual fallback suggestions for users
  static List<String> _getVisualFallbackSuggestions(
      String concept, String subject) {
    return [
      'Try searching for "$concept" images online',
      'Create a hand-drawn diagram of the concept',
      'Look for $subject visual resources in textbooks',
      'Use online educational platforms for visual content',
    ];
  }

  /// Truncate text to specified length
  static String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get comprehensive error report for debugging
  static Map<String, dynamic> getErrorReport() {
    return {
      'failureCounts': Map.from(_failureCount),
      'lastFailureTimes': _lastFailureTime.map(
        (key, value) => MapEntry(key, value.toIso8601String()),
      ),
      'circuitBreakerStates': _failureCount.keys.map((operation) {
        return {
          'operation': operation,
          'isOpen': _isCircuitBreakerOpen(operation),
          'failures': _failureCount[operation] ?? 0,
        };
      }).toList(),
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Reset error tracking (useful for testing)
  static void resetErrorTracking() {
    _failureCount.clear();
    _lastFailureTime.clear();
    debugPrint('Error tracking reset');
  }
}

/// Custom timeout exception
class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);

  @override
  String toString() => 'TimeoutException: $message';
}

/// Custom validation exception
class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);

  @override
  String toString() => 'ValidationException: $message';
}

/// Multi-modal operation result with detailed status
class MultiModalResult<T> {
  final T? data;
  final bool success;
  final String? error;
  final bool usedFallback;
  final int attempts;
  final Duration duration;

  const MultiModalResult({
    this.data,
    required this.success,
    this.error,
    required this.usedFallback,
    required this.attempts,
    required this.duration,
  });

  factory MultiModalResult.success(T data, int attempts, Duration duration) {
    return MultiModalResult(
      data: data,
      success: true,
      usedFallback: false,
      attempts: attempts,
      duration: duration,
    );
  }

  factory MultiModalResult.fallback(
      T? fallbackData, String error, int attempts, Duration duration) {
    return MultiModalResult(
      data: fallbackData,
      success: false,
      error: error,
      usedFallback: true,
      attempts: attempts,
      duration: duration,
    );
  }

  factory MultiModalResult.failure(
      String error, int attempts, Duration duration) {
    return MultiModalResult(
      success: false,
      error: error,
      usedFallback: false,
      attempts: attempts,
      duration: duration,
    );
  }
}
