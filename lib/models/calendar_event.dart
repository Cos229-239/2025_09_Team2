import 'package:flutter/material.dart';
import 'task.dart';
import 'daily_quest.dart';
import 'social_session.dart';
import 'pet.dart';

/// Unified calendar event model that represents all activities in StudyPals
/// This model aggregates different types of events (tasks, quests, sessions, etc.)
/// into a single unified interface for calendar display and management
class CalendarEvent {
  /// Unique identifier for this calendar event
  final String id;

  /// Display title for the event
  final String title;

  /// Detailed description of the event
  final String description;

  /// Type of event (task, quest, session, etc.)
  final CalendarEventType type;

  /// Start date and time of the event
  final DateTime startTime;

  /// End date and time of the event (optional for all-day events)
  final DateTime? endTime;

  /// Whether this is an all-day event
  final bool isAllDay;

  /// Priority level (1 = low, 2 = medium, 3 = high)
  final int priority;

  /// Current status of the event
  final CalendarEventStatus status;

  /// Color to display this event in the calendar
  final Color color;

  /// Icon to represent this event type
  final IconData icon;

  /// Tags for categorization and filtering
  final List<String> tags;

  /// Reference to the original object (Task, DailyQuest, etc.)
  final dynamic sourceObject;

  /// Whether this event can be edited
  final bool isEditable;

  /// Whether this event can be completed/marked as done
  final bool isCompletable;

  /// Progress percentage (0.0 to 1.0) for trackable events
  final double? progress;

  /// Estimated duration in minutes (for tasks and sessions)
  final int? estimatedMinutes;

  /// Participants (for social sessions)
  final List<String>? participants;

  /// Location or meeting link (for social sessions)
  final String? location;

  /// Whether this is a recurring event
  final bool isRecurring;

  /// Recurrence pattern (daily, weekly, monthly)
  final RecurrencePattern? recurrencePattern;

  /// Reminder settings
  final List<EventReminder> reminders;

  /// Creation timestamp
  final DateTime createdAt;

  /// Last updated timestamp
  final DateTime updatedAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.startTime,
    this.endTime,
    this.isAllDay = false,
    this.priority = 1,
    this.status = CalendarEventStatus.scheduled,
    required this.color,
    required this.icon,
    this.tags = const [],
    this.sourceObject,
    this.isEditable = true,
    this.isCompletable = false,
    this.progress,
    this.estimatedMinutes,
    this.participants,
    this.location,
    this.isRecurring = false,
    this.recurrencePattern,
    this.reminders = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a CalendarEvent from a Task
  factory CalendarEvent.fromTask(Task task) {
    return CalendarEvent(
      id: 'task_${task.id}',
      title: task.title,
      description: 'Task: ${task.title}',
      type: CalendarEventType.task,
      startTime: task.dueAt ?? DateTime.now().add(const Duration(hours: 1)),
      endTime: task.dueAt?.add(Duration(minutes: task.estMinutes)),
      priority: task.priority,
      status: _taskStatusToCalendarStatus(task.status),
      color: _getPriorityColor(task.priority),
      icon: Icons.task_alt,
      tags: task.tags,
      sourceObject: task,
      isEditable: true,
      isCompletable: true,
      estimatedMinutes: task.estMinutes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a CalendarEvent from a DailyQuest
  factory CalendarEvent.fromDailyQuest(DailyQuest quest) {
    return CalendarEvent(
      id: 'quest_${quest.id}',
      title: quest.title,
      description: quest.description,
      type: CalendarEventType.dailyQuest,
      startTime: quest.createdAt,
      endTime: quest.expiresAt,
      isAllDay: true,
      priority: quest.priority,
      status: quest.isCompleted
          ? CalendarEventStatus.completed
          : (quest.isExpired
              ? CalendarEventStatus.expired
              : CalendarEventStatus.scheduled),
      color: _getQuestTypeColor(quest.type),
      icon: _getQuestTypeIcon(quest.type),
      tags: [quest.type.displayName],
      sourceObject: quest,
      isEditable: false,
      isCompletable: true,
      progress: quest.progressPercentage,
      createdAt: quest.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a CalendarEvent from a SocialSession
  factory CalendarEvent.fromSocialSession(SocialSession session) {
    return CalendarEvent(
      id: 'session_${session.id}',
      title: session.title,
      description: '${session.type.displayName}: ${session.description}',
      type: CalendarEventType.socialSession,
      startTime: session.scheduledTime,
      endTime: session.scheduledTime.add(session.duration),
      priority: 2,
      status: _sessionStatusToCalendarStatus(session.status),
      color: _getSessionTypeColor(session.type),
      icon: _getSessionTypeIcon(session.type),
      tags: ['social', session.type.displayName.toLowerCase()],
      sourceObject: session,
      isEditable: session.hostId == 'current_user_id', // Mock user check
      isCompletable: false,
      estimatedMinutes: session.duration.inMinutes,
      participants: session.participantIds,
      location: 'Online StudyPals Session',
      createdAt: session.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a pet care reminder event
  factory CalendarEvent.fromPetCare(Pet pet, PetCareType careType) {
    final now = DateTime.now();
    final nextCareTime = _getNextCareTime(careType, pet);

    return CalendarEvent(
      id: 'pet_${pet.userId}_${careType.name}',
      title: 'Pet Care: ${careType.displayName}',
      description: 'Time to ${careType.description} your ${pet.species.name}!',
      type: CalendarEventType.petCare,
      startTime: nextCareTime,
      endTime: nextCareTime.add(const Duration(minutes: 15)),
      priority: pet.mood == PetMood.sleepy ? 3 : 1,
      status: CalendarEventStatus.scheduled,
      color: _getPetMoodColor(pet.mood),
      icon: _getPetCareIcon(careType),
      tags: ['pet', careType.name, pet.species.name.toLowerCase()],
      sourceObject: pet,
      isEditable: false,
      isCompletable: true,
      isRecurring: true,
      recurrencePattern: _getPetCareRecurrence(careType),
      reminders: [
        EventReminder(
          type: ReminderType.notification,
          minutesBefore: 30,
          message: 'Your ${pet.species.name} needs ${careType.description}!',
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a study session event
  factory CalendarEvent.studySession({
    required String id,
    required String title,
    required DateTime startTime,
    required int durationMinutes,
    List<String> deckIds = const [],
    String? location,
  }) {
    return CalendarEvent(
      id: 'study_$id',
      title: title,
      description:
          'Personal study session${deckIds.isNotEmpty ? ' with ${deckIds.length} deck(s)' : ''}',
      type: CalendarEventType.studySession,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: durationMinutes)),
      priority: 2,
      status: CalendarEventStatus.scheduled,
      color: Colors.blue,
      icon: Icons.school,
      tags: ['study', 'personal'],
      isEditable: true,
      isCompletable: true,
      estimatedMinutes: durationMinutes,
      location: location,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Creates a break/rest reminder event
  factory CalendarEvent.breakReminder({
    required String id,
    required DateTime startTime,
    int durationMinutes = 15,
  }) {
    return CalendarEvent(
      id: 'break_$id',
      title: 'Study Break',
      description: 'Time for a well-deserved break!',
      type: CalendarEventType.breakReminder,
      startTime: startTime,
      endTime: startTime.add(Duration(minutes: durationMinutes)),
      priority: 1,
      status: CalendarEventStatus.scheduled,
      color: Colors.green,
      icon: Icons.free_breakfast,
      tags: ['break', 'wellness'],
      isEditable: true,
      isCompletable: true,
      estimatedMinutes: durationMinutes,
      reminders: [
        EventReminder(
          type: ReminderType.notification,
          minutesBefore: 0,
          message: 'Time for a break! Rest your mind and recharge.',
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Checks if this event occurs on a specific date
  bool occursOnDate(DateTime date) {
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    return eventDate.isAtSameMomentAs(targetDate);
  }

  /// Checks if this event is occurring now
  bool get isHappeningNow {
    final now = DateTime.now();
    if (endTime == null) return false;
    return now.isAfter(startTime) && now.isBefore(endTime!);
  }

  /// Checks if this event is upcoming (starts within the next hour)
  bool get isUpcoming {
    final now = DateTime.now();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    return startTime.isAfter(now) && startTime.isBefore(oneHourFromNow);
  }

  /// Checks if this event is overdue
  bool get isOverdue {
    final now = DateTime.now();
    return endTime != null &&
        now.isAfter(endTime!) &&
        status == CalendarEventStatus.scheduled;
  }

  /// Gets the duration of this event
  Duration? get duration {
    if (endTime == null) return null;
    return endTime!.difference(startTime);
  }

  /// Gets a formatted time string for display
  String get formattedTime {
    if (isAllDay) return 'All day';
    if (endTime == null) return 'Starts at ${_formatTime(startTime)}';
    return '${_formatTime(startTime)} - ${_formatTime(endTime!)}';
  }

  /// Creates a copy with updated fields
  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    CalendarEventType? type,
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    int? priority,
    CalendarEventStatus? status,
    Color? color,
    IconData? icon,
    List<String>? tags,
    dynamic sourceObject,
    bool? isEditable,
    bool? isCompletable,
    double? progress,
    int? estimatedMinutes,
    List<String>? participants,
    String? location,
    bool? isRecurring,
    RecurrencePattern? recurrencePattern,
    List<EventReminder>? reminders,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      tags: tags ?? this.tags,
      sourceObject: sourceObject ?? this.sourceObject,
      isEditable: isEditable ?? this.isEditable,
      isCompletable: isCompletable ?? this.isCompletable,
      progress: progress ?? this.progress,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'isAllDay': isAllDay,
      'priority': priority,
      'status': status.name,
      'color': (color.r * 255.0).round() << 16 |
          (color.g * 255.0).round() << 8 |
          (color.b * 255.0).round(),
      'icon': icon.codePoint,
      'tags': tags,
      'isEditable': isEditable,
      'isCompletable': isCompletable,
      'progress': progress,
      'estimatedMinutes': estimatedMinutes,
      'participants': participants,
      'location': location,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern?.toJson(),
      'reminders': reminders.map((r) => r.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates from JSON
  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      type: CalendarEventType.values.firstWhere((e) => e.name == json['type']),
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      isAllDay: json['isAllDay'] ?? false,
      priority: json['priority'] ?? 1,
      status: CalendarEventStatus.values
          .firstWhere((e) => e.name == json['status']),
      color: Color(json['color']),
      icon: IconData(json['icon'], fontFamily: 'MaterialIcons'),
      tags: List<String>.from(json['tags'] ?? []),
      isEditable: json['isEditable'] ?? true,
      isCompletable: json['isCompletable'] ?? false,
      progress: json['progress']?.toDouble(),
      estimatedMinutes: json['estimatedMinutes'],
      participants: json['participants'] != null
          ? List<String>.from(json['participants'])
          : null,
      location: json['location'],
      isRecurring: json['isRecurring'] ?? false,
      recurrencePattern: json['recurrencePattern'] != null
          ? RecurrencePattern.fromJson(json['recurrencePattern'])
          : null,
      reminders: json['reminders'] != null
          ? (json['reminders'] as List)
              .map((r) => EventReminder.fromJson(r))
              .toList()
          : [],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // Helper methods for status conversions
  static CalendarEventStatus _taskStatusToCalendarStatus(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return CalendarEventStatus.scheduled;
      case TaskStatus.inProgress:
        return CalendarEventStatus.inProgress;
      case TaskStatus.completed:
        return CalendarEventStatus.completed;
      case TaskStatus.cancelled:
        return CalendarEventStatus.cancelled;
    }
  }

  static CalendarEventStatus _sessionStatusToCalendarStatus(
      SessionStatus status) {
    switch (status) {
      case SessionStatus.scheduled:
        return CalendarEventStatus.scheduled;
      case SessionStatus.live:
        return CalendarEventStatus.inProgress;
      case SessionStatus.completed:
        return CalendarEventStatus.completed;
      case SessionStatus.cancelled:
        return CalendarEventStatus.cancelled;
    }
  }

  // Helper methods for colors
  static Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.study:
        return Colors.blue;
      case QuestType.quiz:
        return Colors.purple;
      case QuestType.streak:
        return Colors.orange;
      case QuestType.perfectScore:
        return Colors.yellow;
      case QuestType.timeSpent:
        return Colors.green;
      case QuestType.newCards:
        return Colors.cyan;
      case QuestType.review:
        return Colors.indigo;
    }
  }

  static Color _getSessionTypeColor(SessionType type) {
    switch (type) {
      case SessionType.quiz:
        return Colors.purple;
      case SessionType.study:
        return Colors.blue;
      case SessionType.challenge:
        return Colors.red;
      case SessionType.group:
        return Colors.green;
    }
  }

  static Color _getPetMoodColor(PetMood mood) {
    switch (mood) {
      case PetMood.happy:
        return Colors.green;
      case PetMood.sleepy:
        return Colors.red;
      case PetMood.excited:
        return Colors.orange;
      case PetMood.content:
        return Colors.blue;
    }
  }

  // Helper methods for icons
  static IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.study:
        return Icons.book;
      case QuestType.quiz:
        return Icons.quiz;
      case QuestType.streak:
        return Icons.local_fire_department;
      case QuestType.perfectScore:
        return Icons.star;
      case QuestType.timeSpent:
        return Icons.timer;
      case QuestType.newCards:
        return Icons.fiber_new;
      case QuestType.review:
        return Icons.refresh;
    }
  }

  static IconData _getSessionTypeIcon(SessionType type) {
    switch (type) {
      case SessionType.quiz:
        return Icons.quiz;
      case SessionType.study:
        return Icons.group_work;
      case SessionType.challenge:
        return Icons.emoji_events;
      case SessionType.group:
        return Icons.groups;
    }
  }

  static IconData _getPetCareIcon(PetCareType type) {
    switch (type) {
      case PetCareType.feed:
        return Icons.restaurant;
      case PetCareType.play:
        return Icons.sports_esports;
      case PetCareType.clean:
        return Icons.cleaning_services;
      case PetCareType.exercise:
        return Icons.directions_run;
    }
  }

  // Helper methods for pet care
  static DateTime _getNextCareTime(PetCareType careType, Pet pet) {
    final now = DateTime.now();
    switch (careType) {
      case PetCareType.feed:
        return now.add(const Duration(hours: 8));
      case PetCareType.play:
        return now.add(const Duration(hours: 4));
      case PetCareType.clean:
        return now.add(const Duration(days: 1));
      case PetCareType.exercise:
        return now.add(const Duration(hours: 6));
    }
  }

  static RecurrencePattern _getPetCareRecurrence(PetCareType type) {
    switch (type) {
      case PetCareType.feed:
        return RecurrencePattern.custom(hours: 8);
      case PetCareType.play:
        return RecurrencePattern.custom(hours: 4);
      case PetCareType.clean:
        return RecurrencePattern.daily();
      case PetCareType.exercise:
        return RecurrencePattern.custom(hours: 6);
    }
  }

  static String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final amPm = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $amPm';
  }
}

/// Types of calendar events in StudyPals
enum CalendarEventType {
  task,
  dailyQuest,
  socialSession,
  studySession,
  petCare,
  breakReminder,
  deadline,
  exam,
  meeting,
  custom,
}

/// Status of calendar events
enum CalendarEventStatus {
  scheduled,
  inProgress,
  completed,
  cancelled,
  expired,
  postponed,
}

/// Types of pet care activities
enum PetCareType {
  feed,
  play,
  clean,
  exercise,
}

extension PetCareTypeExtension on PetCareType {
  String get displayName {
    switch (this) {
      case PetCareType.feed:
        return 'Feed';
      case PetCareType.play:
        return 'Play';
      case PetCareType.clean:
        return 'Clean';
      case PetCareType.exercise:
        return 'Exercise';
    }
  }

  String get description {
    switch (this) {
      case PetCareType.feed:
        return 'feed';
      case PetCareType.play:
        return 'play with';
      case PetCareType.clean:
        return 'clean up after';
      case PetCareType.exercise:
        return 'exercise';
    }
  }
}

/// Recurrence pattern for repeating events
class RecurrencePattern {
  final RecurrenceType type;
  final int interval;
  final List<int>? daysOfWeek; // 1-7 (Monday-Sunday)
  final int? dayOfMonth; // 1-31
  final DateTime? endDate;
  final int? maxOccurrences;

  const RecurrencePattern({
    required this.type,
    this.interval = 1,
    this.daysOfWeek,
    this.dayOfMonth,
    this.endDate,
    this.maxOccurrences,
  });

  factory RecurrencePattern.daily() =>
      const RecurrencePattern(type: RecurrenceType.daily);
  factory RecurrencePattern.weekly() =>
      const RecurrencePattern(type: RecurrenceType.weekly);
  factory RecurrencePattern.monthly() =>
      const RecurrencePattern(type: RecurrenceType.monthly);

  factory RecurrencePattern.custom({int? hours, int? days, int? weeks}) {
    if (hours != null) {
      return RecurrencePattern(type: RecurrenceType.hourly, interval: hours);
    } else if (days != null) {
      return RecurrencePattern(type: RecurrenceType.daily, interval: days);
    } else if (weeks != null) {
      return RecurrencePattern(type: RecurrenceType.weekly, interval: weeks);
    }
    return RecurrencePattern.daily();
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'interval': interval,
      'daysOfWeek': daysOfWeek,
      'dayOfMonth': dayOfMonth,
      'endDate': endDate?.toIso8601String(),
      'maxOccurrences': maxOccurrences,
    };
  }

  factory RecurrencePattern.fromJson(Map<String, dynamic> json) {
    return RecurrencePattern(
      type: RecurrenceType.values.firstWhere((e) => e.name == json['type']),
      interval: json['interval'] ?? 1,
      daysOfWeek: json['daysOfWeek'] != null
          ? List<int>.from(json['daysOfWeek'])
          : null,
      dayOfMonth: json['dayOfMonth'],
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      maxOccurrences: json['maxOccurrences'],
    );
  }
}

enum RecurrenceType {
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
}

/// Reminder settings for calendar events
class EventReminder {
  final ReminderType type;
  final int minutesBefore;
  final String message;
  final bool isEnabled;

  const EventReminder({
    required this.type,
    required this.minutesBefore,
    required this.message,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'minutesBefore': minutesBefore,
      'message': message,
      'isEnabled': isEnabled,
    };
  }

  factory EventReminder.fromJson(Map<String, dynamic> json) {
    return EventReminder(
      type: ReminderType.values.firstWhere((e) => e.name == json['type']),
      minutesBefore: json['minutesBefore'],
      message: json['message'],
      isEnabled: json['isEnabled'] ?? true,
    );
  }
}

enum ReminderType {
  notification,
  email,
  sms,
}

/// Extension to provide display properties for calendar event types
extension CalendarEventTypeExtension on CalendarEventType {
  String get displayName {
    switch (this) {
      case CalendarEventType.task:
        return 'Task';
      case CalendarEventType.dailyQuest:
        return 'Daily Quest';
      case CalendarEventType.socialSession:
        return 'Social Session';
      case CalendarEventType.studySession:
        return 'Study Session';
      case CalendarEventType.petCare:
        return 'Pet Care';
      case CalendarEventType.breakReminder:
        return 'Break';
      case CalendarEventType.deadline:
        return 'Deadline';
      case CalendarEventType.exam:
        return 'Exam';
      case CalendarEventType.meeting:
        return 'Meeting';
      case CalendarEventType.custom:
        return 'Event';
    }
  }

  IconData get defaultIcon {
    switch (this) {
      case CalendarEventType.task:
        return Icons.task_alt;
      case CalendarEventType.dailyQuest:
        return Icons.emoji_events;
      case CalendarEventType.socialSession:
        return Icons.group_work;
      case CalendarEventType.studySession:
        return Icons.school;
      case CalendarEventType.petCare:
        return Icons.pets;
      case CalendarEventType.breakReminder:
        return Icons.free_breakfast;
      case CalendarEventType.deadline:
        return Icons.schedule;
      case CalendarEventType.exam:
        return Icons.quiz;
      case CalendarEventType.meeting:
        return Icons.meeting_room;
      case CalendarEventType.custom:
        return Icons.event;
    }
  }

  Color get defaultColor {
    switch (this) {
      case CalendarEventType.task:
        return Colors.blue;
      case CalendarEventType.dailyQuest:
        return Colors.purple;
      case CalendarEventType.socialSession:
        return Colors.green;
      case CalendarEventType.studySession:
        return Colors.orange;
      case CalendarEventType.petCare:
        return Colors.brown;
      case CalendarEventType.breakReminder:
        return Colors.teal;
      case CalendarEventType.deadline:
        return Colors.red;
      case CalendarEventType.exam:
        return Colors.deepPurple;
      case CalendarEventType.meeting:
        return Colors.indigo;
      case CalendarEventType.custom:
        return Colors.grey;
    }
  }
}
