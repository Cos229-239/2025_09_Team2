import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/calendar_event.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';
import 'task_provider.dart';
import 'daily_quest_provider.dart';
import 'social_session_provider.dart';
import 'pet_provider.dart';

/// Comprehensive calendar provider that unifies all StudyPals activities
/// This provider aggregates events from all sources and provides a unified calendar interface
class CalendarProvider with ChangeNotifier {
  // Firestore service for database operations
  final FirestoreService _firestoreService = FirestoreService();

  // Firebase Auth for user authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Current selected date in the calendar
  DateTime _selectedDay = DateTime.now();

  // Calendar format (month, 2weeks, week)
  CalendarFormat _calendarFormat = CalendarFormat.month;

  // Focused day for calendar navigation
  DateTime _focusedDay = DateTime.now();

  // All unified calendar events from all sources
  final Map<DateTime, List<CalendarEvent>> _events = {};

  // Events filtered by current selection criteria
  List<CalendarEvent> _filteredEvents = [];

  // Active event type filters
  final Set<CalendarEventType> _activeFilters =
      Set.from(CalendarEventType.values);

  // Event status filters
  final Set<CalendarEventStatus> _statusFilters = {
    CalendarEventStatus.scheduled,
    CalendarEventStatus.inProgress,
  };

  // Priority filters (1=low, 2=medium, 3=high)
  final Set<int> _priorityFilters = {1, 2, 3};

  // Search query for event filtering
  String _searchQuery = '';

  // Loading state
  bool _isLoading = false;

  // Error state
  String? _errorMessage;

  // Auto-refresh settings
  bool _autoRefresh = true;

  // Reference to other providers for data synchronization
  TaskProvider? _taskProvider;
  DailyQuestProvider? _questProvider;
  SocialSessionProvider? _socialProvider;
  PetProvider? _petProvider;

  // Getters
  DateTime get selectedDay => _selectedDay;
  CalendarFormat get calendarFormat => _calendarFormat;
  DateTime get focusedDay => _focusedDay;
  List<CalendarEvent> get filteredEvents => _filteredEvents;
  Set<CalendarEventType> get activeFilters => Set.from(_activeFilters);
  Set<CalendarEventStatus> get statusFilters => Set.from(_statusFilters);
  Set<int> get priorityFilters => Set.from(_priorityFilters);
  String get searchQuery => _searchQuery;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get autoRefresh => _autoRefresh;

  /// Initialize the calendar provider with references to other providers
  void initialize({
    TaskProvider? taskProvider,
    DailyQuestProvider? questProvider,
    SocialSessionProvider? socialProvider,
    PetProvider? petProvider,
  }) {
    _taskProvider = taskProvider;
    _questProvider = questProvider;
    _socialProvider = socialProvider;
    _petProvider = petProvider;

    // Set up listeners for real-time updates
    _setupProviderListeners();

    // Initial data load
    refreshAllEvents();

    // Set up auto-refresh if enabled
    if (_autoRefresh) {
      _setupAutoRefresh();
    }
  }

  /// Check if pet care reminders are enabled in user preferences
  Future<bool> _arePetCareRemindersEnabled() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false; // Default to disabled for guest users
      
      final userProfile = await _firestoreService.getUserProfile(user.uid);
      if (userProfile == null) return false; // Default to disabled if no profile
      
      final preferences = userProfile['preferences'] as Map<String, dynamic>?;
      if (preferences == null) return false; // Default to disabled if no preferences
      
      return preferences['petCareReminders'] as bool? ?? false; // Default to disabled
    } catch (e) {
      debugPrint('Error checking pet care reminders preference: $e');
      return false; // Default to disabled on error
    }
  }

  /// Gets all events for a specific date
  List<CalendarEvent> getEventsForDay(DateTime day) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  /// Gets events occurring in a date range
  List<CalendarEvent> getEventsInRange(DateTime start, DateTime end) {
    final events = <CalendarEvent>[];
    for (var day = start;
        day.isBefore(end) || day.isAtSameMomentAs(end);
        day = day.add(const Duration(days: 1))) {
      events.addAll(getEventsForDay(day));
    }
    return events;
  }

  /// Gets upcoming events (next 7 days)
  List<CalendarEvent> getUpcomingEvents() {
    final now = DateTime.now();
    final sevenDaysFromNow = now.add(const Duration(days: 7));
    return getEventsInRange(now, sevenDaysFromNow)
        .where((event) => event.startTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Gets overdue events
  List<CalendarEvent> getOverdueEvents() {
    return _events.values
        .expand((events) => events)
        .where((event) => event.isOverdue)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Gets events happening right now
  List<CalendarEvent> getCurrentEvents() {
    return _events.values
        .expand((events) => events)
        .where((event) => event.isHappeningNow)
        .toList();
  }

  /// Updates selected day and refreshes filtered events
  void setSelectedDay(DateTime selectedDay) {
    _selectedDay = selectedDay;
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Updates calendar format
  void setCalendarFormat(CalendarFormat format) {
    _calendarFormat = format;
    notifyListeners();
  }

  /// Updates focused day
  void setFocusedDay(DateTime focusedDay) {
    _focusedDay = focusedDay;
    notifyListeners();
  }

  /// Toggles event type filter
  void toggleEventTypeFilter(CalendarEventType type) {
    if (_activeFilters.contains(type)) {
      _activeFilters.remove(type);
    } else {
      _activeFilters.add(type);
    }
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Toggles event status filter
  void toggleStatusFilter(CalendarEventStatus status) {
    if (_statusFilters.contains(status)) {
      _statusFilters.remove(status);
    } else {
      _statusFilters.add(status);
    }
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Toggles priority filter
  void togglePriorityFilter(int priority) {
    if (_priorityFilters.contains(priority)) {
      _priorityFilters.remove(priority);
    } else {
      _priorityFilters.add(priority);
    }
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Updates search query and filters events
  void setSearchQuery(String query) {
    _searchQuery = query;
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Clears all filters
  void clearFilters() {
    _activeFilters.clear();
    _activeFilters.addAll(CalendarEventType.values);
    _statusFilters.clear();
    _statusFilters.addAll(
        [CalendarEventStatus.scheduled, CalendarEventStatus.inProgress]);
    _priorityFilters.clear();
    _priorityFilters.addAll({1, 2, 3});
    _searchQuery = '';
    _updateFilteredEvents();
    notifyListeners();
  }

  /// Sets auto-refresh enabled/disabled
  void setAutoRefresh(bool enabled) {
    _autoRefresh = enabled;
    if (enabled) {
      _setupAutoRefresh();
    }
    notifyListeners();
  }

  /// Refreshes all events from all sources
  Future<void> refreshAllEvents() async {
    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        _refreshCalendarEvents(), // Load from Firestore
        _refreshTaskEvents(),
        _refreshQuestEvents(),
        _refreshSocialEvents(),
        _refreshPetCareEvents(),
      ]);

      _updateFilteredEvents();
    } catch (e) {
      _setError('Failed to refresh events: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load calendar events from Firestore
  Future<void> _refreshCalendarEvents() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return; // No user, skip loading
      }

      // Clear calendar-only event types (not derived from other providers)
      _removeEventsByType(CalendarEventType.studySession);
      _removeEventsByType(CalendarEventType.flashcardStudy);
      _removeEventsByType(CalendarEventType.custom);
      _removeEventsByType(CalendarEventType.meeting);
      _removeEventsByType(CalendarEventType.exam);
      _removeEventsByType(CalendarEventType.deadline);
      _removeEventsByType(CalendarEventType.breakReminder);

      final eventMaps = await _firestoreService.getUserCalendarEvents(user.uid);
      
      debugPrint('📅 Loading ${eventMaps.length} calendar events from Firestore');
      
      for (final eventMap in eventMaps) {
        try {
          final event = _convertFirestoreToCalendarEvent(eventMap);
          _addEventToMap(event);
          debugPrint('  ✅ Loaded event: ${event.title} (${event.type})');
        } catch (e) {
          // Skip individual event conversion errors
          debugPrint('  ❌ Error converting calendar event: $e');
        }
      }
      
      debugPrint('📅 Finished loading calendar events');
    } catch (e) {
      debugPrint('❌ Error loading calendar events from Firestore: $e');
    }
  }

  /// Helper method to convert Firestore document data to CalendarEvent
  CalendarEvent _convertFirestoreToCalendarEvent(Map<String, dynamic> data) {
    return CalendarEvent.fromJson(data);
  }

  /// Creates a new calendar event
  Future<CalendarEvent?> createEvent({
    required String title,
    required String description,
    required CalendarEventType type,
    required DateTime startTime,
    DateTime? endTime,
    bool isAllDay = false,
    int priority = 1,
    List<String> tags = const [],
    int? estimatedMinutes,
    List<String>? participants,
    String? location,
    bool isRecurring = false,
    RecurrencePattern? recurrencePattern,
    List<EventReminder> reminders = const [],
  }) async {
    try {
      _setLoading(true);

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _setError('No user logged in');
        return null;
      }

      final event = CalendarEvent(
        id: _generateEventId(type),
        title: title,
        description: description,
        type: type,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        priority: priority,
        status: CalendarEventStatus.scheduled,
        color: type.defaultColor,
        icon: type.defaultIcon,
        tags: tags,
        isEditable: true,
        isCompletable: type == CalendarEventType.task ||
            type == CalendarEventType.dailyQuest,
        estimatedMinutes: estimatedMinutes,
        participants: participants,
        location: location,
        isRecurring: isRecurring,
        recurrencePattern: recurrencePattern,
        reminders: reminders,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Convert to JSON for Firestore
      final eventData = event.toJson();
      eventData.remove('id'); // Firestore will generate the ID

      debugPrint('💾 Saving calendar event to Firestore: $title (type: $type)');

      // Save to Firestore
      final docId = await _firestoreService.createCalendarEvent(user.uid, eventData);
      if (docId == null) {
        debugPrint('❌ Failed to save event to Firestore');
        _setError('Failed to save event to database');
        return null;
      }

      debugPrint('✅ Event saved to Firestore with ID: $docId');

      // Create event with Firestore-generated ID
      final savedEvent = event.copyWith(id: docId);

      // Add to internal events map
      _addEventToMap(savedEvent);

      // Create corresponding object in appropriate provider
      await _createSourceObject(savedEvent);

      _updateFilteredEvents();
      return savedEvent;
    } catch (e) {
      _setError('Failed to create event: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Adds a flashcard study event to the calendar
  /// This is a convenience method for adding flashcard study sessions
  Future<CalendarEvent?> addFlashcardStudyEvent(CalendarEvent event) async {
    if (event.type != CalendarEventType.flashcardStudy) {
      _setError('Event must be of type flashcardStudy');
      return null;
    }

    try {
      _setLoading(true);

      // Get current user
      final user = _auth.currentUser;
      if (user == null) {
        _setError('No user logged in');
        return null;
      }

      // Convert to JSON for Firestore
      final eventData = event.toJson();
      eventData.remove('id'); // Firestore will generate the ID

      debugPrint('💾 Saving flashcard study event to Firestore: ${event.title}');

      // Save to Firestore
      final docId = await _firestoreService.createCalendarEvent(user.uid, eventData);
      if (docId == null) {
        debugPrint('❌ Failed to save flashcard study event to Firestore');
        _setError('Failed to save flashcard study event to database');
        return null;
      }

      debugPrint('✅ Flashcard study event saved to Firestore with ID: $docId');

      // Create event with Firestore-generated ID
      final savedEvent = event.copyWith(id: docId);

      // Add to internal events map
      _addEventToMap(savedEvent);

      // Flashcard events don't need source objects created
      // The deck is already stored in the event's sourceObject field

      _updateFilteredEvents();
      return savedEvent;
    } catch (e) {
      _setError('Failed to add flashcard study event: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Updates an existing calendar event
  Future<CalendarEvent?> updateEvent(CalendarEvent event) async {
    try {
      _setLoading(true);

      // Update in Firestore
      final eventData = event.toJson();
      eventData.remove('id'); // Don't update the ID field
      final success = await _firestoreService.updateCalendarEvent(event.id, eventData);
      
      if (!success) {
        _setError('Failed to update event in database');
        return null;
      }

      // Update in internal events map
      _updateEventInMap(event);

      // Update source object if needed
      await _updateSourceObject(event);

      _updateFilteredEvents();
      return event;
    } catch (e) {
      _setError('Failed to update event: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Deletes a calendar event
  Future<bool> deleteEvent(CalendarEvent event) async {
    try {
      _setLoading(true);

      debugPrint('🗑️ Deleting calendar event: ${event.title} (ID: ${event.id})');

      // Delete from Firestore (archives it)
      final success = await _firestoreService.deleteCalendarEvent(event.id);
      
      if (!success) {
        debugPrint('❌ Failed to delete event from Firestore');
        _setError('Failed to delete event from database');
        return false;
      }

      debugPrint('✅ Event deleted from Firestore successfully');

      // Remove from internal events map
      _removeEventFromMap(event);
      debugPrint('✅ Event removed from internal map');

      // Delete source object if needed
      await _deleteSourceObject(event);

      _updateFilteredEvents();
      debugPrint('✅ Calendar event deletion completed');
      return true;
    } catch (e) {
      debugPrint('❌ Error deleting calendar event: $e');
      _setError('Failed to delete event: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Marks an event as completed
  Future<bool> completeEvent(CalendarEvent event) async {
    if (!event.isCompletable) return false;

    final updatedEvent = event.copyWith(
      status: CalendarEventStatus.completed,
      updatedAt: DateTime.now(),
    );

    return await updateEvent(updatedEvent) != null;
  }

  /// Schedules study break reminders based on study sessions
  void scheduleStudyBreaks() {
    final studyEvents = _events.values
        .expand((events) => events)
        .where((event) => event.type == CalendarEventType.studySession)
        .toList();

    for (final studyEvent in studyEvents) {
      if (studyEvent.duration != null && studyEvent.duration!.inMinutes >= 45) {
        // Schedule break every 45 minutes for long study sessions
        final breakTime = studyEvent.startTime.add(const Duration(minutes: 45));
        final breakEvent = CalendarEvent.breakReminder(
          id: 'break_${studyEvent.id}',
          startTime: breakTime,
          durationMinutes: 15,
        );
        _addEventToMap(breakEvent);
      }
    }

    _updateFilteredEvents();
    notifyListeners();
  }

  /// Generates smart schedule suggestions based on existing events
  List<CalendarEvent> generateScheduleSuggestions({
    required CalendarEventType eventType,
    required int durationMinutes,
    DateTime? preferredDate,
  }) {
    final suggestions = <CalendarEvent>[];
    final targetDate =
        preferredDate ?? DateTime.now().add(const Duration(days: 1));

    // Find available time slots
    final availableSlots = _findAvailableTimeSlots(
      date: targetDate,
      durationMinutes: durationMinutes,
    );

    for (final slot in availableSlots.take(3)) {
      // Top 3 suggestions
      final suggestion = CalendarEvent(
        id: 'suggestion_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Suggested ${eventType.displayName}',
        description: 'Smart scheduling suggestion',
        type: eventType,
        startTime: slot,
        endTime: slot.add(Duration(minutes: durationMinutes)),
        priority: 2,
        status: CalendarEventStatus.scheduled,
        color: eventType.defaultColor.withValues(alpha: 0.7),
        icon: eventType.defaultIcon,
        isEditable: true,
        isCompletable: eventType == CalendarEventType.task,
        estimatedMinutes: durationMinutes,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      suggestions.add(suggestion);
    }

    return suggestions;
  }

  /// Gets calendar statistics
  Map<String, dynamic> getCalendarStats() {
    final allEvents = _events.values.expand((events) => events).toList();

    return {
      'totalEvents': allEvents.length,
      'upcomingEvents': getUpcomingEvents().length,
      'overdueEvents': getOverdueEvents().length,
      'completedEvents': allEvents
          .where((e) => e.status == CalendarEventStatus.completed)
          .length,
      'eventsByType': _getEventCountByType(allEvents),
      'eventsByPriority': _getEventCountByPriority(allEvents),
      'averageEventsPerDay': _getAverageEventsPerDay(),
      'studyTimeThisWeek': _getStudyTimeThisWeek(),
    };
  }

  // Private helper methods

  void _setupProviderListeners() {
    _taskProvider?.addListener(_onTasksChanged);
    _questProvider?.addListener(_onQuestsChanged);
    _socialProvider?.addListener(_onSocialChanged);
    _petProvider?.addListener(_onPetChanged);
  }

  void _setupAutoRefresh() {
    // Implementation would use a timer for periodic refresh
    // Timer.periodic(_refreshInterval, (_) => refreshAllEvents());
  }

  void _onTasksChanged() {
    _refreshTaskEvents();
  }

  void _onQuestsChanged() {
    _refreshQuestEvents();
  }

  void _onSocialChanged() {
    _refreshSocialEvents();
  }

  void _onPetChanged() {
    _refreshPetCareEvents();
  }

  Future<void> _refreshTaskEvents() async {
    if (_taskProvider == null) return;

    final tasks = _taskProvider!.tasks;
    _removeEventsByType(CalendarEventType.task);

    for (final task in tasks) {
      final event = CalendarEvent.fromTask(task);
      _addEventToMap(event);
    }
  }

  Future<void> _refreshQuestEvents() async {
    if (_questProvider == null) return;

    final quests = _questProvider!.quests;
    _removeEventsByType(CalendarEventType.dailyQuest);

    for (final quest in quests) {
      final event = CalendarEvent.fromDailyQuest(quest);
      _addEventToMap(event);
    }
  }

  Future<void> _refreshSocialEvents() async {
    if (_socialProvider == null) return;

    final sessions = _socialProvider!.allSessions;
    _removeEventsByType(CalendarEventType.socialSession);

    for (final session in sessions) {
      final event = CalendarEvent.fromSocialSession(session);
      _addEventToMap(event);
    }
  }

  Future<void> _refreshPetCareEvents() async {
    if (_petProvider == null) return;

    final pet = _petProvider!.currentPet;
    _removeEventsByType(CalendarEventType.petCare);

    // Check if pet care reminders are enabled in user preferences
    final areEnabled = await _arePetCareRemindersEnabled();
    
    // Create pet care reminders for different care types only if enabled
    if (pet != null && areEnabled) {
      for (final careType in PetCareType.values) {
        final event = CalendarEvent.fromPetCare(pet, careType);
        _addEventToMap(event);
      }
    }
  }

  void _addEventToMap(CalendarEvent event) {
    final day = DateTime(
        event.startTime.year, event.startTime.month, event.startTime.day);
    if (_events[day] == null) {
      _events[day] = [];
    }

    // Remove existing event with same ID if any
    _events[day]!.removeWhere((e) => e.id == event.id);

    // Add new event
    _events[day]!.add(event);

    // Sort events by start time
    _events[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  void _updateEventInMap(CalendarEvent event) {
    // Remove from old day if date changed
    for (final dayEvents in _events.values) {
      dayEvents.removeWhere((e) => e.id == event.id);
    }

    // Add to new day
    _addEventToMap(event);
  }

  void _removeEventFromMap(CalendarEvent event) {
    for (final dayEvents in _events.values) {
      dayEvents.removeWhere((e) => e.id == event.id);
    }
  }

  void _removeEventsByType(CalendarEventType type) {
    for (final dayEvents in _events.values) {
      dayEvents.removeWhere((e) => e.type == type);
    }
  }

  void _updateFilteredEvents() {
    final selectedDayEvents = getEventsForDay(_selectedDay);

    _filteredEvents = selectedDayEvents.where((event) {
      // Filter by event type
      if (!_activeFilters.contains(event.type)) return false;

      // Filter by status
      if (!_statusFilters.contains(event.status)) return false;

      // Filter by priority
      if (!_priorityFilters.contains(event.priority)) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return event.title.toLowerCase().contains(query) ||
            event.description.toLowerCase().contains(query) ||
            event.tags.any((tag) => tag.toLowerCase().contains(query));
      }

      return true;
    }).toList();

    // Sort filtered events
    _filteredEvents.sort((a, b) {
      // First by start time
      final timeComparison = a.startTime.compareTo(b.startTime);
      if (timeComparison != 0) return timeComparison;

      // Then by priority (high to low)
      return b.priority.compareTo(a.priority);
    });
  }

  Future<void> _createSourceObject(CalendarEvent event) async {
    switch (event.type) {
      case CalendarEventType.task:
        // Create task in task provider
        if (_taskProvider != null) {
          final task = Task(
            id: event.id,
            title: event.title,
            estMinutes: event.estimatedMinutes ?? 60,
            dueAt: event.endTime,
            priority: event.priority,
            tags: event.tags,
            status: TaskStatus.pending,
          );
          await _taskProvider!.addTask(task);
        }
        break;
      case CalendarEventType.studySession:
        // Create study session (implementation depends on study session provider)
        break;
      case CalendarEventType.flashcardStudy:
        // Flashcard events don't need a source object - the Deck is already stored in sourceObject field
        break;
      default:
        // Other event types might not have source objects
        break;
    }
  }

  Future<void> _updateSourceObject(CalendarEvent event) async {
    if (event.sourceObject == null) return;

    switch (event.type) {
      case CalendarEventType.task:
        // Update task in task provider
        break;
      default:
        break;
    }
  }

  Future<void> _deleteSourceObject(CalendarEvent event) async {
    if (event.sourceObject == null) return;

    switch (event.type) {
      case CalendarEventType.task:
        // Delete task from task provider
        break;
      default:
        break;
    }
  }

  List<DateTime> _findAvailableTimeSlots({
    required DateTime date,
    required int durationMinutes,
  }) {
    final slots = <DateTime>[];
    final existingEvents = getEventsForDay(date);

    // Define working hours (9 AM to 9 PM)
    final startHour = 9;
    final endHour = 21;

    // Check each 30-minute slot
    for (int hour = startHour; hour < endHour; hour++) {
      for (int minute = 0; minute < 60; minute += 30) {
        final slotStart =
            DateTime(date.year, date.month, date.day, hour, minute);
        final slotEnd = slotStart.add(Duration(minutes: durationMinutes));

        // Check if this slot conflicts with existing events
        final hasConflict = existingEvents.any((event) {
          return (slotStart.isBefore(event.endTime ?? event.startTime) &&
              slotEnd.isAfter(event.startTime));
        });

        if (!hasConflict && slotEnd.hour < endHour) {
          slots.add(slotStart);
        }
      }
    }

    return slots;
  }

  Map<String, int> _getEventCountByType(List<CalendarEvent> events) {
    final counts = <String, int>{};
    for (final event in events) {
      counts[event.type.displayName] =
          (counts[event.type.displayName] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, int> _getEventCountByPriority(List<CalendarEvent> events) {
    final counts = <int, int>{};
    for (final event in events) {
      counts[event.priority] = (counts[event.priority] ?? 0) + 1;
    }
    return counts;
  }

  double _getAverageEventsPerDay() {
    if (_events.isEmpty) return 0.0;
    final totalEvents =
        _events.values.fold(0, (sum, events) => sum + events.length);
    return totalEvents / _events.length;
  }

  int _getStudyTimeThisWeek() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final studyEvents = getEventsInRange(weekStart, weekEnd)
        .where((event) =>
            event.type == CalendarEventType.studySession ||
            event.type == CalendarEventType.socialSession)
        .toList();

    return studyEvents.fold(0, (total, event) {
      return total + (event.estimatedMinutes ?? 0);
    });
  }

  String _generateEventId(CalendarEventType type) {
    return '${type.name}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    // Remove listeners
    _taskProvider?.removeListener(_onTasksChanged);
    _questProvider?.removeListener(_onQuestsChanged);
    _socialProvider?.removeListener(_onSocialChanged);
    _petProvider?.removeListener(_onPetChanged);

    super.dispose();
  }
}
