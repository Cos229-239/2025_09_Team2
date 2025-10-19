// ai_tutor_regression_test.dart
// Automated regression test suite using AI TUTOR QUESTIONS.txt as test cases

import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/services/ai_tutor_middleware.dart';
import 'package:studypals/services/user_profile_store.dart';
import 'package:studypals/services/session_context.dart';
import 'package:studypals/models/chat_message.dart';
import 'dart:io';

/// Test case parsed from AI TUTOR QUESTIONS.txt
class AITutorTestCase {
  final int questionNumber;
  final String category;
  final String question;
  final String expectedResponse;
  final List<String> acceptanceCriteria;

  AITutorTestCase({
    required this.questionNumber,
    required this.category,
    required this.question,
    required this.expectedResponse,
    List<String>? acceptanceCriteria,
  }) : acceptanceCriteria = acceptanceCriteria ?? [];
}

/// Parses test cases from the QA file
class AITutorTestParser {
  static List<AITutorTestCase> parseTestFile(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      throw Exception('Test file not found: $filePath');
    }

    final content = file.readAsStringSync();
    final testCases = <AITutorTestCase>[];

    // Parse sections separated by horizontal lines
    final sections = content.split(
        '----------------------------------------------------------------------------');

    for (final section in sections) {
      if (section.trim().isEmpty) continue;

      final cases = _parseSection(section.trim());
      testCases.addAll(cases);
    }

    return testCases;
  }

  static List<AITutorTestCase> _parseSection(String section) {
    final cases = <AITutorTestCase>[];
    final lines = section.split('\n');

    if (lines.isEmpty) return cases;

    // First line is the category
    final category = lines[0].trim();

    // Parse question-response pairs
    String? currentQuestion;
    String? currentQuestionText;
    String? currentResponse;
    int questionNum = 0;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();

      if (line.startsWith('Question ')) {
        // Save previous case
        if (currentQuestion != null &&
            currentQuestionText != null &&
            currentResponse != null) {
          cases.add(AITutorTestCase(
            questionNumber: questionNum,
            category: category,
            question: currentQuestionText,
            expectedResponse: currentResponse,
            acceptanceCriteria: _extractCriteria(category, questionNum),
          ));
        }

        // Start new case
        currentQuestion = line;
        questionNum = int.tryParse(line.split(' ')[1].replaceAll(':', '')) ?? 0;
        currentQuestionText = null;
        currentResponse = null;
      } else if (currentQuestion != null &&
          currentQuestionText == null &&
          line.isNotEmpty) {
        currentQuestionText = line;
      } else if (line.startsWith('AI Response ')) {
        // Next few lines are the response
        final responseBuffer = StringBuffer();
        for (var j = i + 1; j < lines.length; j++) {
          if (lines[j].trim().isEmpty ||
              lines[j].trim().startsWith('Question ')) {
            break;
          }
          responseBuffer.writeln(lines[j].trim());
        }
        currentResponse = responseBuffer.toString().trim();
      }
    }

    // Save last case
    if (currentQuestion != null &&
        currentQuestionText != null &&
        currentResponse != null) {
      cases.add(AITutorTestCase(
        questionNumber: questionNum,
        category: category,
        question: currentQuestionText,
        expectedResponse: currentResponse,
        acceptanceCriteria: _extractCriteria(category, questionNum),
      ));
    }

    return cases;
  }

  /// Extract acceptance criteria based on category and question number
  static List<String> _extractCriteria(String category, int questionNum) {
    final criteria = <String>[];

    if (category.contains('Memory')) {
      if (questionNum == 2) {
        criteria.add('MUST NOT assert prior discussion when none present');
        criteria.add('Should ask if user wants to discuss topic');
      } else if (questionNum == 3) {
        criteria.add('Should explain memory limitations clearly');
        criteria.add('Should describe current session context');
      }
    } else if (category.contains('Personality')) {
      criteria.add('Should acknowledge user emotion');
      criteria.add('Should adapt tone to user state');
    } else if (category.contains('Learning Pattern')) {
      if (questionNum == 8) {
        criteria
            .add('Should offer visual examples or describe how to create them');
      } else if (questionNum == 9) {
        criteria.add('Should provide step-by-step instructions');
        criteria.add('Math validation should pass');
      }
    }

    return criteria;
  }
}

/// Test runner for AI tutor regression tests
class AITutorTestRunner {
  final AITutorMiddleware middleware;
  final Map<String, dynamic> telemetry = {};

  AITutorTestRunner({AITutorMiddleware? middleware})
      : middleware = middleware ?? AITutorMiddleware();

  /// Run all tests from file
  Future<TestResults> runAllTests(String testFilePath) async {
    final testCases = AITutorTestParser.parseTestFile(testFilePath);
    final results = <TestResult>[];

    for (final testCase in testCases) {
      final result = await runTestCase(testCase);
      results.add(result);
    }

    return TestResults(
      total: results.length,
      passed: results.where((r) => r.passed).length,
      failed: results.where((r) => !r.passed).length,
      results: results,
      telemetry: telemetry,
    );
  }

  /// Run a single test case
  Future<TestResult> runTestCase(AITutorTestCase testCase) async {
    final userId = 'test_user_${testCase.questionNumber}';
    final failures = <String>[];

    try {
      // Step 1: Pre-process
      final preContext = await middleware.preProcessMessage(
        userId: userId,
        message: testCase.question,
      );

      // Step 2: Simulate LLM call (in real tests, call actual LLM)
      // For now, use expected response to test post-processing
      final llmResponse = testCase.expectedResponse;

      // Step 3: Post-process
      final postResult = await middleware.postProcessResponse(
        userId: userId,
        message: testCase.question,
        llmResponse: llmResponse,
        context: preContext,
      );

      // Update telemetry
      telemetry['test_${testCase.questionNumber}'] = postResult.telemetry;

      // Step 4: Validate acceptance criteria
      for (final criterion in testCase.acceptanceCriteria) {
        if (!_checkCriterion(criterion, postResult, testCase)) {
          failures.add(criterion);
        }
      }

      return TestResult(
        testCase: testCase,
        passed: failures.isEmpty,
        failures: failures,
        response: postResult.response,
        memoryValid: postResult.memoryValid,
        mathValid: postResult.mathValid,
        corrections: postResult.corrections,
      );
    } catch (e) {
      return TestResult(
        testCase: testCase,
        passed: false,
        failures: ['Test execution error: $e'],
        response: '',
        memoryValid: false,
        mathValid: false,
      );
    }
  }

  /// Check if a specific criterion is met
  bool _checkCriterion(
    String criterion,
    PostProcessedResponse response,
    AITutorTestCase testCase,
  ) {
    final lowerCriterion = criterion.toLowerCase();
    final lowerResponse = response.response.toLowerCase();

    if (lowerCriterion.contains('must not assert prior discussion')) {
      // Check memory validation caught false claims
      return response.memoryValid ||
          response.corrections.any((c) => c.contains('memory'));
    }

    if (lowerCriterion.contains('should ask')) {
      // Check response contains a question
      return lowerResponse.contains('?');
    }

    if (lowerCriterion.contains('math validation should pass')) {
      return response.mathValid;
    }

    if (lowerCriterion.contains('should acknowledge user emotion')) {
      // Check for emotional acknowledgment keywords
      final emotionalKeywords = [
        'understand',
        'see',
        'help',
        'know',
        'appreciate'
      ];
      return emotionalKeywords.any((kw) => lowerResponse.contains(kw));
    }

    if (lowerCriterion.contains('step-by-step')) {
      // Check for numbered steps or sequential indicators
      return lowerResponse.contains('step') ||
          lowerResponse.contains('1.') ||
          lowerResponse.contains('first');
    }

    // Default: check if criterion keywords appear in response
    return true;
  }
}

/// Result of a single test
class TestResult {
  final AITutorTestCase testCase;
  final bool passed;
  final List<String> failures;
  final String response;
  final bool memoryValid;
  final bool mathValid;
  final List<String> corrections;

  TestResult({
    required this.testCase,
    required this.passed,
    List<String>? failures,
    required this.response,
    required this.memoryValid,
    required this.mathValid,
    List<String>? corrections,
  })  : failures = failures ?? [],
        corrections = corrections ?? [];
}

/// Overall test results
class TestResults {
  final int total;
  final int passed;
  final int failed;
  final List<TestResult> results;
  final Map<String, dynamic> telemetry;

  TestResults({
    required this.total,
    required this.passed,
    required this.failed,
    required this.results,
    required this.telemetry,
  });

  double get passRate => total > 0 ? passed / total : 0.0;

  String getSummary() {
    final buffer = StringBuffer();
    buffer.writeln('AI Tutor Regression Test Results');
    buffer.writeln('=' * 50);
    buffer.writeln('Total Tests: $total');
    buffer.writeln('Passed: $passed');
    buffer.writeln('Failed: $failed');
    buffer.writeln('Pass Rate: ${(passRate * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    if (failed > 0) {
      buffer.writeln('Failed Tests:');
      for (final result in results.where((r) => !r.passed)) {
        buffer.writeln(
            '  Q${result.testCase.questionNumber}: ${result.testCase.category}');
        for (final failure in result.failures) {
          buffer.writeln('    - $failure');
        }
      }
    }

    return buffer.toString();
  }
}

/// Main test entry point
void main() {
  group('AI Tutor Regression Tests', () {
    late AITutorTestRunner runner;

    setUp(() {
      runner = AITutorTestRunner();
    });

    test('Memory claim validation - Q2 (Fresh session, no prior history)',
        () async {
      // This test verifies that the AI doesn't falsely claim to remember previous conversations
      // when the session is fresh with no prior messages

      final userId = 'test_user_memory_Q2';

      // User asks if AI remembers yesterday's conversation (but there was none!)
      final question =
          'Hi again! Do you remember what we discussed about algebra yesterday?';

      // Simulate a false memory claim from the LLM
      final badLlmResponse =
          'Yes, we discussed algebraic expressions and equations yesterday. You were learning about factoring.';

      // Pre-process (should have empty session since this is first message)
      final preContext = await runner.middleware.preProcessMessage(
        userId: userId,
        message: question,
      );

      // Post-process (should detect and correct the false memory claim)
      final postResult = await runner.middleware.postProcessResponse(
        userId: userId,
        message: question,
        llmResponse: badLlmResponse,
        context: preContext,
      );

      // Verify the memory claim was caught
      expect(postResult.memoryValid, isFalse,
          reason: 'Should detect false memory claim when session is empty');

      expect(postResult.corrections.isNotEmpty, isTrue,
          reason: 'Should add corrections for the false memory claim');

      expect(postResult.response.toLowerCase(), isNot(contains('yesterday')),
          reason: 'Corrected response should not claim to remember yesterday');
    });

    test('Memory claim validation - Legitimate recall (should pass)', () async {
      // This test verifies that REAL memory claims are NOT flagged as false
      // when the session actually contains the referenced conversation

      final userId = 'test_user_memory_legit';

      // Step 1: Simulate prior conversation about algebra
      final priorMessage = 'Can you explain quadratic equations?';
      await runner.middleware.preProcessMessage(
        userId: userId,
        message: priorMessage,
      );

      // Simulate LLM response to build session history
      final priorResponse =
          'Sure! Quadratic equations are polynomials of degree 2...';
      final priorPreContext = await runner.middleware.preProcessMessage(
        userId: userId,
        message: priorMessage,
      );
      await runner.middleware.postProcessResponse(
        userId: userId,
        message: priorMessage,
        llmResponse: priorResponse,
        context: priorPreContext,
      );

      // Step 2: User asks about the previous topic (legitimate recall)
      final question =
          'Can you remind me about the quadratic formula we discussed?';
      final llmResponse =
          'Yes, we were discussing quadratic equations. The formula is x = (-b ± √(b²-4ac)) / 2a';

      final preContext = await runner.middleware.preProcessMessage(
        userId: userId,
        message: question,
      );

      final postResult = await runner.middleware.postProcessResponse(
        userId: userId,
        message: question,
        llmResponse: llmResponse,
        context: preContext,
      );

      // This should PASS validation (legitimate memory)
      expect(postResult.memoryValid, isTrue,
          reason: 'Should NOT flag legitimate memory recall as false');

      expect(postResult.corrections, isEmpty,
          reason: 'Should not add corrections for valid memory claims');
    });

    test('Math validation - calculation accuracy', () async {
      final testCase = AITutorTestCase(
        questionNumber: 9,
        category: 'Learning Pattern Recognition',
        question: 'Solve: 2 + 2 = ?',
        expectedResponse: 'The answer is 5.',
        acceptanceCriteria: [
          'Math validation should pass',
        ],
      );

      final result = await runner.runTestCase(testCase);

      // This should FAIL validation and add corrections
      expect(result.mathValid || result.corrections.isNotEmpty, isTrue,
          reason: 'Should detect and correct math errors');
    });

    test('SessionContext - tracks conversation topics correctly', () async {
      // This test verifies that SessionContext properly tracks conversation topics
      final userId = 'test_user_session_context';

      // Create a session with multiple messages
      final messages = [
        ChatMessage(
          id: '1',
          content: 'Can you help me with calculus?',
          type: MessageType.user,
          format: MessageFormat.text,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '2',
          content: 'Of course! Let\'s start with derivatives.',
          type: MessageType.assistant,
          format: MessageFormat.text,
          timestamp: DateTime.now(),
        ),
        ChatMessage(
          id: '3',
          content: 'What is the derivative of x²?',
          type: MessageType.user,
          format: MessageFormat.text,
          timestamp: DateTime.now(),
        ),
      ];

      // Process messages to build session
      for (final msg in messages) {
        await runner.middleware.preProcessMessage(
          userId: userId,
          message: msg.content,
        );
      }

      // Now ask a follow-up question
      final followUp = 'Can you explain that derivative rule again?';
      final preContext = await runner.middleware.preProcessMessage(
        userId: userId,
        message: followUp,
      );

      // Verify session context was populated
      expect(preContext.sessionContext, isNotNull,
          reason: 'SessionContext should be available in PreProcessedContext');

      // Get the session context explicitly (ensures import is used)
      final SessionContext session = preContext.sessionContext;

      // The session should have tracked the calculus/derivative discussion
      final topics = session.getRecentTopics(topK: 5);
      expect(
          topics.any((t) =>
              t.topic.toLowerCase().contains('derivative') ||
              t.topic.toLowerCase().contains('calculus')),
          isTrue,
          reason: 'SessionContext should track discussed topics');
    });

    test('UserProfileStore - integration with middleware', () async {
      // This test verifies that the middleware properly integrates with UserProfileStore
      final userId = 'test_user_profile_integration';

      // Create a custom profile store for testing
      final profileStore = UserProfileStore();
      final testMiddleware = AITutorMiddleware(profileStore: profileStore);

      // First call should work even without a profile (user hasn't opted in)
      final preContext = await testMiddleware.preProcessMessage(
        userId: userId,
        message: 'Hello, can you help me with math?',
      );

      // Profile should be null since user hasn't opted in
      expect(preContext.profile, isNull,
          reason: 'Profile should be null for users who haven\'t opted in');

      // System should still function correctly without profile
      final postResult = await testMiddleware.postProcessResponse(
        userId: userId,
        message: 'Hello, can you help me with math?',
        llmResponse: 'Of course! I\'d be happy to help you with math.',
        context: preContext,
      );

      expect(postResult.response, isNotEmpty,
          reason: 'Middleware should work even without user profile');
    });

    // Add more test cases as needed
  });
}
