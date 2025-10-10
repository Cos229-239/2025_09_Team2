import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/calendar_event.dart';
import '../providers/calendar_provider.dart';

/// Screen that displays a detailed itinerary for a selected day
class DayItineraryScreen extends StatefulWidget {
  final DateTime selectedDate;

  const DayItineraryScreen({
    super.key,
    required this.selectedDate,
  });

  @override
  State<DayItineraryScreen> createState() => _DayItineraryScreenState();
}

class _DayItineraryScreenState extends State<DayItineraryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          DateFormat('EEEE, MMMM d, y').format(widget.selectedDate),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          final events = provider.getEventsForDay(widget.selectedDate);
          final sortedEvents = [...events]
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          return Column(
            children: [
              // Day overview header
              _buildDayOverviewHeader(context, events),

              // Events list
              Expanded(
                child: events.isEmpty
                    ? _buildEmptyState(context)
                    : _buildEventsList(context, sortedEvents),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewEvent(context),
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDayOverviewHeader(
      BuildContext context, List<CalendarEvent> events) {
    final isToday = _isToday(widget.selectedDate);
    final isPast = widget.selectedDate.isBefore(DateTime.now());
    final completedEvents =
        events.where((e) => e.status == CalendarEventStatus.completed).length;
    final totalEvents = events.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isToday
                    ? Icons.today
                    : isPast
                        ? Icons.history
                        : Icons.event,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday
                          ? 'Today\'s Schedule'
                          : isPast
                              ? 'Past Day'
                              : 'Upcoming Day',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getRelativeDateString(widget.selectedDate),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Statistics row
          Row(
            children: [
              _buildStatChip(
                context,
                'Total Events',
                totalEvents.toString(),
                Icons.event_note,
              ),
              const SizedBox(width: 12),
              if (totalEvents > 0)
                _buildStatChip(
                  context,
                  'Completed',
                  '$completedEvents/$totalEvents',
                  Icons.check_circle,
                ),
              const Spacer(),
              _buildProgressIndicator(context, totalEvents, completedEvents),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator(
      BuildContext context, int total, int completed) {
    if (total == 0) return const SizedBox.shrink();

    final progress = completed / total;
    return SizedBox(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 4,
          ),
          Center(
            child: Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_available,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No events scheduled',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'This day is free! Tap the + button to add an event.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _createNewEvent(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(BuildContext context, List<CalendarEvent> events) {
    return RefreshIndicator(
      onRefresh: () async {
        await Provider.of<CalendarProvider>(context, listen: false)
            .refreshAllEvents();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: events.length + 1, // +1 for spacing at bottom
        itemBuilder: (context, index) {
          if (index == events.length) {
            return const SizedBox(height: 80); // Space for FAB
          }

          final event = events[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildEventCard(event),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return InkWell(
      onTap: () => _showEventDetails(context, event),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: event.color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: event.color.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Time indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),

            // Event icon
            Icon(
              event.icon,
              color: event.color,
              size: 24,
            ),
            const SizedBox(width: 16),

            // Event details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        event.formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      if (event.estimatedMinutes != null) ...[
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timer,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.estimatedMinutes}min',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                        ),
                      ],
                    ],
                  ),
                  if (event.description.isNotEmpty &&
                      event.description != event.title) ...[
                    const SizedBox(height: 6),
                    Text(
                      event.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[700],
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // Status indicator & actions
            Column(
              children: [
                // Status indicator
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(event.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(event.status),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action menu
                PopupMenuButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey[600],
                    size: 18,
                  ),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'view',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, size: 16),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    if (event.isEditable)
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    switch (value) {
                      case 'view':
                        _showEventDetails(context, event);
                        break;
                      case 'edit':
                        _editEvent(context, event);
                        break;
                      case 'delete':
                        _deleteEvent(context, event);
                        break;
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.scheduled:
        return Colors.blue;
      case CalendarEventStatus.inProgress:
        return Colors.orange;
      case CalendarEventStatus.completed:
        return Colors.green;
      case CalendarEventStatus.cancelled:
        return Colors.red;
      case CalendarEventStatus.expired:
        return Colors.grey;
      case CalendarEventStatus.postponed:
        return Colors.amber;
    }
  }

  String _getStatusText(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.scheduled:
        return 'Scheduled';
      case CalendarEventStatus.inProgress:
        return 'In Progress';
      case CalendarEventStatus.completed:
        return 'Completed';
      case CalendarEventStatus.cancelled:
        return 'Cancelled';
      case CalendarEventStatus.expired:
        return 'Expired';
      case CalendarEventStatus.postponed:
        return 'Postponed';
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getRelativeDateString(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final compareDate = DateTime(date.year, date.month, date.day);

    final difference = compareDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference > 1 && difference <= 7) return 'In $difference days';
    if (difference < -1 && difference >= -7) return '${-difference} days ago';
    if (difference > 7) return 'In ${(difference / 7).round()} weeks';
    return 'More than a week ago';
  }

  void _createNewEvent(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(
        selectedDate: widget.selectedDate,
        isEditMode: false,
      ),
    );
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => _EventDetailsDialog(event: event),
    );
  }

  void _editEvent(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => _EventFormDialog(
        selectedDate: widget.selectedDate,
        isEditMode: true,
        existingEvent: event,
      ),
    );
  }

  void _deleteEvent(BuildContext context, CalendarEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              
              // Delete the event from CalendarProvider and Firestore
              final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
              final success = await calendarProvider.deleteEvent(event);
              
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Deleted: ${event.title}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to delete event'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Event creation/editing form dialog
class _EventFormDialog extends StatefulWidget {
  final DateTime selectedDate;
  final bool isEditMode;
  final CalendarEvent? existingEvent;

  const _EventFormDialog({
    required this.selectedDate,
    required this.isEditMode,
    this.existingEvent,
  });

  @override
  State<_EventFormDialog> createState() => _EventFormDialogState();
}

class _EventFormDialogState extends State<_EventFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _estimatedMinutesController;

  late DateTime _startTime;
  late DateTime? _endTime;
  late CalendarEventType _selectedType;
  late int _priority;
  late bool _isAllDay;

  @override
  void initState() {
    super.initState();

    // Initialize controllers and values
    if (widget.isEditMode && widget.existingEvent != null) {
      final event = widget.existingEvent!;
      _titleController = TextEditingController(text: event.title);
      _descriptionController = TextEditingController(text: event.description);
      _locationController = TextEditingController(text: event.location ?? '');
      _estimatedMinutesController = TextEditingController(
        text: event.estimatedMinutes?.toString() ?? '',
      );
      _startTime = event.startTime;
      _endTime = event.endTime;
      _selectedType = event.type;
      _priority = event.priority;
      _isAllDay = event.isAllDay;
    } else {
      _titleController = TextEditingController();
      _descriptionController = TextEditingController();
      _locationController = TextEditingController();
      _estimatedMinutesController = TextEditingController();
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9, // Default to 9 AM
        0,
      );
      _endTime = null;
      _selectedType = CalendarEventType.custom;
      _priority = 1;
      _isAllDay = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _estimatedMinutesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      widget.isEditMode ? Icons.edit : Icons.add_circle,
                      color: Theme.of(context).primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.isEditMode ? 'Edit Event' : 'Create Event',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Event Title *',
                    hintText: 'Enter event title',
                    prefixIcon: Icon(Icons.title),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Add details about this event',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Event type dropdown
                DropdownButtonFormField<CalendarEventType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Event Type *',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                  items: CalendarEventType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Row(
                        children: [
                          Icon(type.defaultIcon, size: 18, color: type.defaultColor),
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

                // All-day toggle
                SwitchListTile(
                  title: const Text('All-day event'),
                  subtitle: const Text('This event lasts the entire day'),
                  value: _isAllDay,
                  onChanged: (value) {
                    setState(() => _isAllDay = value);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),

                // Start time picker
                InkWell(
                  onTap: () => _selectStartTime(context),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Start Time *',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _isAllDay
                          ? DateFormat('MMM d, y').format(_startTime)
                          : DateFormat('MMM d, y • h:mm a').format(_startTime),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // End time picker (optional)
                if (!_isAllDay)
                  InkWell(
                    onTap: () => _selectEndTime(context),
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'End Time (Optional)',
                        prefixIcon: const Icon(Icons.access_time),
                        border: const OutlineInputBorder(),
                        suffixIcon: _endTime != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() => _endTime = null);
                                },
                              )
                            : null,
                      ),
                      child: Text(
                        _endTime != null
                            ? DateFormat('MMM d, y • h:mm a').format(_endTime!)
                            : 'Not set',
                        style: TextStyle(
                          color: _endTime != null ? null : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                if (!_isAllDay) const SizedBox(height: 16),

                // Estimated duration (for tasks and custom events)
                if (_selectedType == CalendarEventType.task ||
                    _selectedType == CalendarEventType.custom)
                  TextFormField(
                    controller: _estimatedMinutesController,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Duration (minutes)',
                      hintText: 'e.g., 30',
                      prefixIcon: Icon(Icons.timer),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                if (_selectedType == CalendarEventType.task ||
                    _selectedType == CalendarEventType.custom)
                  const SizedBox(height: 16),

                // Priority selector
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Priority',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildPriorityChip(1, 'Low', Colors.green),
                        const SizedBox(width: 8),
                        _buildPriorityChip(2, 'Medium', Colors.orange),
                        const SizedBox(width: 8),
                        _buildPriorityChip(3, 'High', Colors.red),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location (for meetings and sessions)
                if (_selectedType == CalendarEventType.socialSession ||
                    _selectedType == CalendarEventType.custom)
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Location / Meeting Link',
                      hintText: 'Enter location or link',
                      prefixIcon: Icon(Icons.location_on),
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_selectedType == CalendarEventType.socialSession ||
                    _selectedType == CalendarEventType.custom)
                  const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _saveEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: Text(widget.isEditMode ? 'Update' : 'Create'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityChip(int priority, String label, Color color) {
    final isSelected = _priority == priority;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _priority = priority),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? color : Colors.grey[600],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      if (_isAllDay) {
        setState(() {
          _startTime = DateTime(date.year, date.month, date.day);
        });
      } else {
        if (!mounted) return;
        
        final time = await showTimePicker(
          context: this.context, // Use State's context
          initialTime: TimeOfDay.fromDateTime(_startTime),
        );

        if (time != null && mounted) {
          setState(() {
            _startTime = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          });
        }
      }
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime.add(const Duration(hours: 1)),
      firstDate: _startTime,
      lastDate: DateTime(2030),
    );

    if (date != null && mounted) {
      if (!mounted) return;
      
      final time = await showTimePicker(
        context: this.context, // Use State's context
        initialTime: _endTime != null
            ? TimeOfDay.fromDateTime(_endTime!)
            : TimeOfDay.fromDateTime(_startTime.add(const Duration(hours: 1))),
      );

      if (time != null && mounted) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    try {
      int? estimatedMinutes;
      if (_estimatedMinutesController.text.isNotEmpty) {
        estimatedMinutes = int.tryParse(_estimatedMinutesController.text);
      }

      if (widget.isEditMode && widget.existingEvent != null) {
        // Update existing event
        final updatedEvent = widget.existingEvent!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          startTime: _startTime,
          endTime: _endTime,
          isAllDay: _isAllDay,
          priority: _priority,
          estimatedMinutes: estimatedMinutes,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          updatedAt: DateTime.now(),
        );

        final result = await provider.updateEvent(updatedEvent);
        
        if (result != null && navigator.mounted) {
          navigator.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Event updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (navigator.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to update event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        // Create new event
        final result = await provider.createEvent(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: _selectedType,
          startTime: _startTime,
          endTime: _endTime,
          isAllDay: _isAllDay,
          priority: _priority,
          estimatedMinutes: estimatedMinutes,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
        );

        if (result != null && navigator.mounted) {
          navigator.pop();
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Event created successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else if (navigator.mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Failed to create event'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (navigator.mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Event details view dialog
class _EventDetailsDialog extends StatelessWidget {
  final CalendarEvent event;

  const _EventDetailsDialog({required this.event});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with event color
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: event.color.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(event.icon, color: event.color, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _buildStatusChip(context),
                ],
              ),
            ),

            // Event details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (event.description.isNotEmpty && event.description != event.title) ...[
                    _buildDetailRow(
                      Icons.description,
                      'Description',
                      event.description,
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDetailRow(
                    Icons.event,
                    'Type',
                    event.type.displayName,
                  ),
                  const SizedBox(height: 16),

                  _buildDetailRow(
                    Icons.access_time,
                    'Time',
                    event.isAllDay
                        ? 'All day - ${DateFormat('MMM d, y').format(event.startTime)}'
                        : event.formattedTime,
                  ),
                  const SizedBox(height: 16),

                  if (event.estimatedMinutes != null) ...[
                    _buildDetailRow(
                      Icons.timer,
                      'Duration',
                      '${event.estimatedMinutes} minutes',
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDetailRow(
                    Icons.flag,
                    'Priority',
                    _getPriorityText(event.priority),
                  ),
                  const SizedBox(height: 16),

                  if (event.location != null && event.location!.isNotEmpty) ...[
                    _buildDetailRow(
                      Icons.location_on,
                      'Location',
                      event.location!,
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (event.tags.isNotEmpty) ...[
                    _buildDetailRow(
                      Icons.label,
                      'Tags',
                      event.tags.join(', '),
                    ),
                    const SizedBox(height: 16),
                  ],

                  _buildDetailRow(
                    Icons.calendar_today,
                    'Created',
                    DateFormat('MMM d, y • h:mm a').format(event.createdAt),
                  ),

                  if (event.createdAt != event.updatedAt) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(
                      Icons.update,
                      'Last Updated',
                      DateFormat('MMM d, y • h:mm a').format(event.updatedAt),
                    ),
                  ],
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (event.isEditable)
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context); // Close details
                        // Open edit dialog
                        showDialog(
                          context: context,
                          builder: (context) => _EventFormDialog(
                            selectedDate: event.startTime,
                            isEditMode: true,
                            existingEvent: event,
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color statusColor;
    switch (event.status) {
      case CalendarEventStatus.completed:
        statusColor = Colors.green;
        break;
      case CalendarEventStatus.inProgress:
        statusColor = Colors.orange;
        break;
      case CalendarEventStatus.cancelled:
        statusColor = Colors.red;
        break;
      case CalendarEventStatus.expired:
        statusColor = Colors.grey;
        break;
      case CalendarEventStatus.postponed:
        statusColor = Colors.amber;
        break;
      default:
        statusColor = Colors.blue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(event.status),
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            event.status.toString().split('.').last.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(CalendarEventStatus status) {
    switch (status) {
      case CalendarEventStatus.completed:
        return Icons.check_circle;
      case CalendarEventStatus.inProgress:
        return Icons.play_circle;
      case CalendarEventStatus.cancelled:
        return Icons.cancel;
      case CalendarEventStatus.expired:
        return Icons.history;
      case CalendarEventStatus.postponed:
        return Icons.schedule;
      default:
        return Icons.event;
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Normal';
    }
  }
}
