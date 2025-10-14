import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';

// TODO: Enhanced Calendar Widget - Missing Advanced Calendar Features
// - Quick create functionality for events not fully implemented
// - No drag-and-drop event rescheduling
// - Missing calendar sync with external services (Google Calendar, Outlook)
// - No recurring event patterns (daily, weekly, monthly)
// - Missing time zone support for global users
// - No calendar sharing and collaboration features
// - Missing smart conflict detection and resolution
// - No calendar export functionality (iCal, CSV)
// - Missing calendar views (agenda, week, day)
// - No calendar search and filtering by content
// - Missing calendar printing and offline access
// - No integration with calendar widgets on mobile platforms

/// Enhanced calendar widget that displays unified events from all StudyPals activities
/// Supports multiple view modes, filtering, event interaction, and smart scheduling
class EnhancedCalendarWidget extends StatefulWidget {
  /// Callback for when a day is selected
  final Function(DateTime, List<CalendarEvent>)? onDaySelected;

  /// Callback for when an event is tapped
  final Function(CalendarEvent)? onEventTapped;

  /// Whether to show the filter bar
  final bool showFilters;

  /// Whether to show the mini event list
  final bool showEventList;

  /// Initial calendar format
  final CalendarFormat initialFormat;

  /// Whether to enable event creation by tapping empty slots
  final bool enableQuickCreate;

  const EnhancedCalendarWidget({
    super.key,
    this.onDaySelected,
    this.onEventTapped,
    this.showFilters = true,
    this.showEventList = true,
    this.initialFormat = CalendarFormat.month,
    this.enableQuickCreate = false,
  });

  @override
  State<EnhancedCalendarWidget> createState() => _EnhancedCalendarWidgetState();
}

class _EnhancedCalendarWidgetState extends State<EnhancedCalendarWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Provider is accessed directly in Consumer widgets
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF242628),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6FB8E9).withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (widget.showFilters) _buildFilterBar(),
            _buildCalendar(),
            if (widget.showEventList) _buildEventList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFF242628),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              bottom: BorderSide(
                color: Color(0xFF6FB8E9),
                width: 0.5,
              ),
            ),
          ),
          child: Column(
            children: [
              // Format toggle buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Calendar View',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFD9D9D9),
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      _buildFormatButton('Month', CalendarFormat.month),
                      const SizedBox(width: 8),
                      _buildFormatButton('2 Weeks', CalendarFormat.twoWeeks),
                      const SizedBox(width: 8),
                      _buildFormatButton('Week', CalendarFormat.week),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Event type filters
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: CalendarEventType.values
                    .where((type) =>
                        type != CalendarEventType.breakReminder &&
                        type != CalendarEventType.meeting &&
                        type != CalendarEventType.custom &&
                        type != CalendarEventType.dailyQuest &&
                        type != CalendarEventType.petCare &&
                        type != CalendarEventType.deadline)
                    .map((type) {
                  final isActive = provider.activeFilters.contains(type);
                  return FilterChip(
                    label: Text(type.displayName),
                    selected: isActive,
                    onSelected: (selected) =>
                        provider.toggleEventTypeFilter(type),
                    avatar: Icon(
                      type.defaultIcon,
                      size: 16,
                      color: isActive ? Colors.white : const Color(0xFF6FB8E9),
                    ),
                    backgroundColor: const Color(0xFF242628),
                    selectedColor: const Color(0xFF6FB8E9),
                    checkmarkColor: Colors.white,
                    side: BorderSide(
                      color: isActive ? const Color(0xFF6FB8E9) : const Color(0xFF6FB8E9).withOpacity(0.3),
                      width: isActive ? 2 : 1,
                    ),
                    labelStyle: TextStyle(
                      color: isActive ? Colors.white : const Color(0xFFD9D9D9),
                    ),
                  );
                }).toList(),
              ),

              // Search and additional controls
              if (provider.filteredEvents.isNotEmpty ||
                  provider.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: provider.setSearchQuery,
                          style: const TextStyle(color: Color(0xFFD9D9D9)),
                          decoration: InputDecoration(
                            hintText: 'Search events...',
                            hintStyle: TextStyle(color: const Color(0xFFD9D9D9).withOpacity(0.5)),
                            prefixIcon: const Icon(Icons.search, color: Color(0xFF6FB8E9)),
                            suffixIcon: provider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, color: Color(0xFF6FB8E9)),
                                    onPressed: () =>
                                        provider.setSearchQuery(''),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6FB8E9),
                                width: 1,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF6FB8E9).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF6FB8E9),
                                width: 2,
                              ),
                            ),
                            filled: true,
                            fillColor: const Color(0xFF242628),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: provider.clearFilters,
                        icon: const Icon(Icons.filter_alt_off, color: Color(0xFF6FB8E9)),
                        tooltip: 'Clear filters',
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFormatButton(String label, CalendarFormat format) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final isSelected = provider.calendarFormat == format;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: OutlinedButton(
            onPressed: () => provider.setCalendarFormat(format),
            style: OutlinedButton.styleFrom(
              backgroundColor: isSelected
                  ? const Color(0xFF6FB8E9)
                  : Colors.transparent,
              foregroundColor: isSelected
                  ? Colors.white
                  : const Color(0xFF6FB8E9),
              side: BorderSide(
                color: const Color(0xFF6FB8E9),
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendar() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SizedBox(
            height: 400,
            child: Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6FB8E9)),
            )),
          );
        }

        if (provider.errorMessage != null) {
          return Container(
            height: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Color(0xFFEF5350),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error loading calendar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD9D9D9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshAllEvents,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FB8E9),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        return TableCalendar<CalendarEvent>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: provider.focusedDay,
          selectedDayPredicate: (day) => isSameDay(provider.selectedDay, day),
          calendarFormat: provider.calendarFormat,
          eventLoader: provider.getEventsForDay,
          onDaySelected: (selectedDay, focusedDay) {
            provider.setSelectedDay(selectedDay);
            provider.setFocusedDay(focusedDay);
            final events = provider.getEventsForDay(selectedDay);
            widget.onDaySelected?.call(selectedDay, events);
          },
          onFormatChanged: provider.setCalendarFormat,
          onPageChanged: provider.setFocusedDay,
          availableGestures: AvailableGestures.all,

          // Styling
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            weekendTextStyle: const TextStyle(
              color: Color(0xFFD9D9D9),
            ),
            holidayTextStyle: const TextStyle(
              color: Color(0xFFD9D9D9),
            ),
            defaultTextStyle: const TextStyle(
              color: Color(0xFFD9D9D9),
            ),
            selectedDecoration: const BoxDecoration(
              color: Color(0xFF6FB8E9),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: const Color(0xFF6FB8E9).withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 4,
            markerSize: 6,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            markersAlignment: Alignment.bottomCenter,
          ),

          headerStyle: const HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: EdgeInsets.symmetric(vertical: 16),
            titleTextStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9D9D9),
                  fontSize: 18,
                ),
          ),

          daysOfWeekStyle: const DaysOfWeekStyle(
            weekdayStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9D9D9),
                ),
            weekendStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD9D9D9),
                ),
          ),

          // Event markers
          calendarBuilders: CalendarBuilders<CalendarEvent>(
            markerBuilder: (context, day, events) {
              if (events.isEmpty) return null;

              return Positioned(
                bottom: 2,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: events.take(4).map((event) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF6FB8E9),
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              final events = provider.getEventsForDay(day);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF6FB8E9),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (events.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${events.length}',
                            style: const TextStyle(
                              color: Color(0xFF6FB8E9),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            todayBuilder: (context, day, focusedDay) {
              final events = provider.getEventsForDay(day);
              return Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB8E9).withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${day.day}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (events.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 1),
                          width: 14,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${events.length}',
                              style: const TextStyle(
                                color: Color(0xFF6FB8E9),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            dowBuilder: (context, day) {
              final weekdayName = [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun'
              ];

              return Center(
                child: Text(
                  weekdayName[day.weekday - 1],
                  style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD9D9D9),
                      ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEventList() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final events = provider.filteredEvents;

        if (events.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: const Color(0xFFD9D9D9).withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events for this day',
                  style: TextStyle(
                        color: const Color(0xFFD9D9D9).withOpacity(0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create a new event',
                  style: TextStyle(
                        color: const Color(0xFFD9D9D9).withOpacity(0.5),
                        fontSize: 14,
                      ),
                ),
                if (widget.enableQuickCreate) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () =>
                        _showQuickCreateDialog(provider.selectedDay),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Event'),
                  ),
                ],
              ],
            ),
          );
        }

        return Container(
          constraints: const BoxConstraints(maxHeight: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Events (${events.length})',
                      style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD9D9D9),
                            fontSize: 16,
                          ),
                    ),
                    if (widget.enableQuickCreate)
                      IconButton(
                        onPressed: () =>
                            _showQuickCreateDialog(provider.selectedDay),
                        icon: const Icon(Icons.add, color: Color(0xFF6FB8E9)),
                        tooltip: 'Create new event',
                      ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return _buildEventTile(event);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEventTile(CalendarEvent event) {
    return InkWell(
      onTap: () => widget.onEventTapped?.call(event),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF242628),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF6FB8E9).withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              event.icon,
              color: event.color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFD9D9D9),
                                    fontSize: 14,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (event.priority > 1) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(event.priority),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _getPriorityLabel(event.priority),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    event.formattedTime,
                    style: TextStyle(
                          color: const Color(0xFFD9D9D9).withOpacity(0.7),
                          fontSize: 12,
                        ),
                  ),
                  if (event.description.isNotEmpty &&
                      event.description != event.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description,
                        style: TextStyle(
                              color: const Color(0xFFD9D9D9).withOpacity(0.6),
                              fontSize: 12,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (event.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: event.tags.take(3).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: event.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: event.color,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                if (event.isCompletable)
                  IconButton(
                    icon: Icon(
                      event.status == CalendarEventStatus.completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: event.status == CalendarEventStatus.completed
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFD9D9D9).withOpacity(0.5),
                    ),
                    onPressed: () => _toggleEventCompletion(event),
                    tooltip: event.status == CalendarEventStatus.completed
                        ? 'Mark as incomplete'
                        : 'Mark as complete',
                  ),
                if (event.isHappeningNow)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (event.isOverdue)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF5350),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'OVERDUE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showQuickCreateDialog(DateTime selectedDate) {
    showDialog(
      context: context,
      builder: (context) => QuickCreateEventDialog(
        selectedDate: selectedDate,
        onEventCreated: (event) {
          // Event will be automatically added through the provider
        },
      ),
    );
  }

  void _toggleEventCompletion(CalendarEvent event) {
    if (!event.isCompletable) return;

    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.completeEvent(event);
  }

  Color _getPriorityColor(int priority) {
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

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'LOW';
      case 2:
        return 'MED';
      case 3:
        return 'HIGH';
      default:
        return '';
    }
  }
}

/// Dialog for quickly creating calendar events
class QuickCreateEventDialog extends StatefulWidget {
  final DateTime selectedDate;
  final Function(CalendarEvent) onEventCreated;

  const QuickCreateEventDialog({
    super.key,
    required this.selectedDate,
    required this.onEventCreated,
  });

  @override
  State<QuickCreateEventDialog> createState() => _QuickCreateEventDialogState();
}

class _QuickCreateEventDialogState extends State<QuickCreateEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  CalendarEventType _selectedType = CalendarEventType.task;
  late DateTime _selectedDate;
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay? _endTime;
  int _priority = 1;
  bool _isAllDay = false;
  final List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242628),
      title: const Text('Create New Event', style: TextStyle(color: Color(0xFFD9D9D9))),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Event type selection
              DropdownButtonFormField<CalendarEventType>(
                initialValue: _selectedType,
                dropdownColor: const Color(0xFF242628),
                style: const TextStyle(color: Color(0xFFD9D9D9)),
                decoration: InputDecoration(
                  labelText: 'Event Type',
                  labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
                  filled: true,
                  fillColor: const Color(0xFF242628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF6FB8E9).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                  ),
                ),
                items: CalendarEventType.values
                    .where((type) =>
                        type != CalendarEventType.breakReminder &&
                        type != CalendarEventType.meeting &&
                        type != CalendarEventType.custom &&
                        type != CalendarEventType.dailyQuest &&
                        type != CalendarEventType.petCare &&
                        type != CalendarEventType.deadline)
                    .map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.defaultIcon,
                            size: 16, color: const Color(0xFF6FB8E9)),
                        const SizedBox(width: 8),
                        Text(type.displayName),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date selection
              ListTile(
                title: const Text('Event Date', style: TextStyle(color: Color(0xFFD9D9D9))),
                subtitle: Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: const TextStyle(
                        color: Color(0xFF6FB8E9),
                        fontWeight: FontWeight.w500,
                      ),
                ),
                leading: const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF6FB8E9),
                ),
                onTap: () => _selectDate(),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: const Color(0xFF6FB8E9).withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFFD9D9D9)),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
                  filled: true,
                  fillColor: const Color(0xFF242628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF6FB8E9).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF5350)),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFEF5350), width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Color(0xFFD9D9D9)),
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  labelStyle: const TextStyle(color: Color(0xFF6FB8E9)),
                  filled: true,
                  fillColor: const Color(0xFF242628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: const Color(0xFF6FB8E9).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // All day toggle
              CheckboxListTile(
                title: const Text('All Day Event', style: TextStyle(color: Color(0xFFD9D9D9))),
                value: _isAllDay,
                activeColor: const Color(0xFF6FB8E9),
                checkColor: Colors.white,
                onChanged: (value) {
                  setState(() => _isAllDay = value ?? false);
                },
                dense: true,
              ),

              if (!_isAllDay) ...[
                // Time selection
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        title: const Text('Start Time', style: TextStyle(color: Color(0xFFD9D9D9), fontSize: 13)),
                        subtitle: Text(_startTime.format(context), style: const TextStyle(color: Color(0xFF6FB8E9))),
                        onTap: () => _selectTime(true),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time', style: TextStyle(color: Color(0xFFD9D9D9), fontSize: 13)),
                        subtitle: Text(_endTime?.format(context) ?? 'Not set', style: const TextStyle(color: Color(0xFF6FB8E9))),
                        onTap: () => _selectTime(false),
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],

              // Priority selection
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Priority: ', style: TextStyle(color: Color(0xFFD9D9D9))),
                  const SizedBox(width: 8),
                  ...List.generate(3, (index) {
                    final priority = index + 1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(['Low', 'Medium', 'High'][index]),
                        selected: _priority == priority,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _priority = priority);
                          }
                        },
                        backgroundColor: const Color(0xFF242628),
                        selectedColor: [
                          const Color(0xFF6FB8E9),
                          Colors.orange,
                          const Color(0xFFEF5350)
                        ][index],
                        side: BorderSide(
                          color: [
                            const Color(0xFF6FB8E9),
                            Colors.orange,
                            const Color(0xFFEF5350)
                          ][index],
                        ),
                        labelStyle: TextStyle(
                          color: _priority == priority ? Colors.white : const Color(0xFFD9D9D9),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFD9D9D9),
          ),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createEvent,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6FB8E9),
            foregroundColor: Colors.white,
          ),
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime ?? _startTime;
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      setState(() {
        if (isStartTime) {
          _startTime = selectedTime;
        } else {
          _endTime = selectedTime;
        }
      });
    }
  }

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  void _createEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = Provider.of<CalendarProvider>(context, listen: false);

    final startDateTime = _isAllDay
        ? _selectedDate
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime.hour,
            _startTime.minute,
          );

    final endDateTime = _isAllDay
        ? null
        : _endTime != null
            ? DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
                _endTime!.hour,
                _endTime!.minute,
              )
            : startDateTime.add(const Duration(hours: 1));

    final event = await provider.createEvent(
      title: _titleController.text,
      description: _descriptionController.text.isEmpty
          ? _titleController.text
          : _descriptionController.text,
      type: _selectedType,
      startTime: startDateTime,
      endTime: endDateTime,
      isAllDay: _isAllDay,
      priority: _priority,
      tags: _tags,
    );

    if (event != null) {
      widget.onEventCreated(event);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Event "${event.title}" created successfully'),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
      }
    }
  }
}
