// flashcard_calendar_integration_test.dart
// Tests for flashcard-to-calendar integration feature
// Run with: flutter test test/flashcard_calendar_integration_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/models/calendar_event.dart';
import 'package:studypals/models/deck.dart';
import 'package:studypals/models/card.dart';
import 'package:flutter/material.dart';

void main() {
  group('Flashcard Calendar Event Tests', () {
    late Deck testDeck;

    setUp(() {
      // Create a test deck with flashcards
      testDeck = Deck(
        id: 'test_deck_123',
        title: 'Biology Exam Review',
        tags: ['biology', 'exam', 'science'],
        cards: [
          FlashCard(
            id: 'card1',
            deckId: 'test_deck_123',
            type: CardType.basic,
            front: 'What is photosynthesis?',
            back: 'The process by which plants convert light energy into chemical energy',
            difficulty: 3,
            multipleChoiceOptions: const [],
            correctAnswerIndex: 0,
          ),
          FlashCard(
            id: 'card2',
            deckId: 'test_deck_123',
            type: CardType.basic,
            front: 'What is mitosis?',
            back: 'Cell division resulting in two identical daughter cells',
            difficulty: 2,
            multipleChoiceOptions: const [],
            correctAnswerIndex: 0,
          ),
          FlashCard(
            id: 'card3',
            deckId: 'test_deck_123',
            type: CardType.basic,
            front: 'What is DNA?',
            back: 'Deoxyribonucleic acid - genetic material',
            difficulty: 3,
            multipleChoiceOptions: const [],
            correctAnswerIndex: 0,
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    test('CalendarEventType.flashcardStudy enum exists', () {
      expect(CalendarEventType.flashcardStudy, isNotNull);
      expect(CalendarEventType.values.contains(CalendarEventType.flashcardStudy), isTrue);
    });

    test('CalendarEventType.flashcardStudy has correct display properties', () {
      final type = CalendarEventType.flashcardStudy;
      
      expect(type.displayName, equals('Flashcard Study'));
      expect(type.defaultIcon, equals(Icons.style));
      expect(type.defaultColor, equals(Colors.deepPurple));
    });

    test('Creates flashcard study event from deck with default duration', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event, isNotNull);
      expect(event.type, equals(CalendarEventType.flashcardStudy));
      expect(event.title, equals('Study: Biology Exam Review'));
      expect(event.startTime, equals(scheduledTime));
      expect(event.sourceObject, equals(testDeck));
      expect(event.tags, contains('flashcards'));
      expect(event.tags, contains('study'));
      expect(event.tags, contains('biology'));
      expect(event.tags, contains('exam'));
      expect(event.isEditable, isTrue);
      expect(event.isCompletable, isTrue);
    });

    test('Creates flashcard study event with custom duration', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      const customDuration = 45;
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
        durationMinutes: customDuration,
      );

      expect(event.estimatedMinutes, equals(customDuration));
      expect(event.endTime, equals(scheduledTime.add(const Duration(minutes: customDuration))));
    });

    test('Calculates estimated duration based on card count', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      // 3 cards * 2 minutes each = 6 minutes (min 15)
      expect(event.estimatedMinutes, greaterThanOrEqualTo(15));
      expect(event.estimatedMinutes, lessThanOrEqualTo(120));
    });

    test('Description includes card count', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event.description, contains('3 flashcards'));
      expect(event.description, contains('Biology Exam Review'));
    });

    test('Event includes reminder notification', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event.reminders, isNotEmpty);
      expect(event.reminders.first.type, equals(ReminderType.notification));
      expect(event.reminders.first.minutesBefore, equals(15));
      expect(event.reminders.first.message, contains(testDeck.title));
    });

    test('Event ID is unique for same deck scheduled at different times', () {
      final time1 = DateTime.now().add(const Duration(days: 1));
      final time2 = DateTime.now().add(const Duration(days: 2));
      
      final event1 = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: time1,
      );
      
      final event2 = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: time2,
      );

      expect(event1.id, isNot(equals(event2.id)));
      expect(event1.id, contains('flashcard_'));
      expect(event1.id, contains(testDeck.id));
      expect(event2.id, contains('flashcard_'));
      expect(event2.id, contains(testDeck.id));
    });

    test('Event has correct status and priority', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event.status, equals(CalendarEventStatus.scheduled));
      expect(event.priority, equals(2)); // Medium priority
    });

    test('Event color and icon are appropriate for flashcards', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event.color, equals(Colors.deepPurple));
      expect(event.icon, equals(Icons.style));
    });

    test('Event includes deck tags in event tags', () {
      final scheduledTime = DateTime.now().add(const Duration(days: 1));
      
      final event = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: scheduledTime,
      );

      expect(event.tags, contains('flashcards'));
      expect(event.tags, contains('study'));
      expect(event.tags, contains('biology'));
      expect(event.tags, contains('exam'));
      expect(event.tags, contains('science'));
    });

    test('Flashcard events are distinguishable from other event types', () {
      final flashcardEvent = CalendarEvent.fromDeck(
        deck: testDeck,
        scheduledTime: DateTime.now(),
      );

      final studyEvent = CalendarEvent.studySession(
        id: 'study1',
        title: 'Study Session',
        startTime: DateTime.now(),
        durationMinutes: 60,
      );

      expect(flashcardEvent.type, equals(CalendarEventType.flashcardStudy));
      expect(studyEvent.type, equals(CalendarEventType.studySession));
      expect(flashcardEvent.type, isNot(equals(studyEvent.type)));
      expect(flashcardEvent.icon, equals(Icons.style));
      expect(studyEvent.icon, equals(Icons.school));
    });
  });
}
