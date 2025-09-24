import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_provider.dart';

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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
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
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Format toggle buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendar View',
                    style: Theme.of(context).textTheme.titleSmall,
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
                children: CalendarEventType.values.map((type) {
                  final isActive = provider.activeFilters.contains(type);
                  return FilterChip(
                    label: Text(type.displayName),
                    selected: isActive,
                    onSelected: (selected) => provider.toggleEventTypeFilter(type),
                    avatar: Icon(
                      type.defaultIcon,
                      size: 16,
                      color: isActive ? Colors.white : type.defaultColor,
                    ),
                    backgroundColor: type.defaultColor.withValues(alpha: 0.1),
                    selectedColor: type.defaultColor,
                    checkmarkColor: Colors.white,
                  );
                }).toList(),
              ),
              
              // Search and additional controls
              if (provider.filteredEvents.isNotEmpty || provider.searchQuery.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: provider.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Search events...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: provider.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: () => provider.setSearchQuery(''),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Theme.of(context).cardColor,
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
                        icon: const Icon(Icons.filter_alt_off),
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
                  ? Theme.of(context).primaryColor 
                  : Colors.transparent,
              foregroundColor: isSelected 
                  ? Colors.white 
                  : Theme.of(context).primaryColor,
              side: BorderSide(
                color: Theme.of(context).primaryColor,
                width: isSelected ? 2 : 1,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(label, style: const TextStyle(fontSize: 12)),
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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.errorMessage != null) {
          return Container(
            height: 400,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading calendar',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage!,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: provider.refreshAllEvents,
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
            weekendTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            holidayTextStyle: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
            selectedDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            markersMaxCount: 4,
            markerSize: 6,
            markerMargin: const EdgeInsets.symmetric(horizontal: 0.5),
            markersAlignment: Alignment.bottomCenter,
          ),
          
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            headerPadding: const EdgeInsets.symmetric(vertical: 16),
            titleTextStyle: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
            ),
            weekendStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.error,
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
                      decoration: BoxDecoration(
                        color: event.color,
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
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
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
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
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
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
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
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
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
              final weekdayName = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
              final isWeekend = day.weekday == DateTime.saturday || 
                              day.weekday == DateTime.sunday;
              
              return Center(
                child: Text(
                  weekdayName[day.weekday - 1],
                  style: Theme.of(context).textTheme.bodySmall!.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isWeekend 
                        ? Theme.of(context).colorScheme.error
                        : null,
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
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events for this day',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create a new event',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                if (widget.enableQuickCreate) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showQuickCreateDialog(provider.selectedDay),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (widget.enableQuickCreate)
                      IconButton(
                        onPressed: () => _showQuickCreateDialog(provider.selectedDay),
                        icon: const Icon(Icons.add),
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
          color: event.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              width: 4,
              color: event.color,
            ),
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
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  if (event.description.isNotEmpty && event.description != event.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                          ? Colors.green
                          : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    onPressed: () => _toggleEventCompletion(event),
                    tooltip: event.status == CalendarEventStatus.completed
                        ? 'Mark as incomplete'
                        : 'Mark as complete',
                  ),
                if (event.isHappeningNow)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
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
      case 1: return Colors.blue;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1: return 'LOW';
      case 2: return 'MED';
      case 3: return 'HIGH';
      default: return '';
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
      title: const Text('Create New Event'),
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
                decoration: const InputDecoration(
                  labelText: 'Event Type',
                  border: OutlineInputBorder(),
                ),
                items: CalendarEventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.defaultIcon, size: 16, color: type.defaultColor),
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
                title: const Text('Event Date'),
                subtitle: Text(
                  DateFormat('EEEE, MMMM d, y').format(_selectedDate),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                leading: Icon(
                  Icons.calendar_today,
                  color: Theme.of(context).primaryColor,
                ),
                onTap: () => _selectDate(),
                dense: true,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
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
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              
              // All day toggle
              CheckboxListTile(
                title: const Text('All Day Event'),
                value: _isAllDay,
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
                        title: const Text('Start Time'),
                        subtitle: Text(_startTime.format(context)),
                        onTap: () => _selectTime(true),
                        dense: true,
                      ),
                    ),
                    Expanded(
                      child: ListTile(
                        title: const Text('End Time'),
                        subtitle: Text(_endTime?.format(context) ?? 'Not set'),
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
                  const Text('Priority: '),
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
                        backgroundColor: [Colors.blue, Colors.orange, Colors.red][index]
                            .withValues(alpha: 0.1),
                        selectedColor: [Colors.blue, Colors.orange, Colors.red][index],
                        labelStyle: TextStyle(
                          color: _priority == priority ? Colors.white : null,
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
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _createEvent,
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
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}