// test_helper.dart
// Setup utilities for testing

import 'package:flutter_test/flutter_test.dart';

/// Setup test environment
Future<void> setupTestEnvironment() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Note: Most services don't require Firebase for unit testing
  // They work with in-memory data structures
}

/// Helper to create test session data
/// Returns a map that can be used to initialize test sessions
Map<String, dynamic> createTestSessionData({
  String? userId,
  String? topic,
}) {
  return {
    'userId': userId ?? 'test_user_123',
    'topic': topic ?? 'test_topic',
    'timestamp': DateTime.now().toIso8601String(),
  };
}
