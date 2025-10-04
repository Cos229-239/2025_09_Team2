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

  Widget _buildDayOverviewHeader(BuildContext context, List<CalendarEvent> events) {
    final isToday = _isToday(widget.selectedDate);
    final isPast = widget.selectedDate.isBefore(DateTime.now());
    final completedEvents = events.where((e) => e.status == CalendarEventStatus.completed).length;
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
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isToday ? Icons.today : isPast ? Icons.history : Icons.event,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isToday ? 'Today\'s Schedule' : isPast ? 'Past Day' : 'Upcoming Day',
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

  Widget _buildStatChip(BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
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

  Widget _buildProgressIndicator(BuildContext context, int total, int completed) {
    if (total == 0) return const SizedBox.shrink();
    
    final progress = completed / total;
    return Container(
      width: 60,
      height: 60,
      child: Stack(
        children: [
          CircularProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withOpacity(0.3),
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
        await Provider.of<CalendarProvider>(context, listen: false).refreshAllEvents();
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
          color: event.color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: event.color.withOpacity(0.2),
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
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ],
                  ),
                  if (event.description.isNotEmpty && event.description != event.title) ...[
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    return date.year == now.year && date.month == now.month && date.day == now.day;
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
    // TODO: Implement event creation dialog
    // This should open the same event creation dialog used in the calendar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Event creation coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    // TODO: Implement event details dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Showing details for: ${event.title}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _editEvent(BuildContext context, CalendarEvent event) {
    // TODO: Implement event editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Editing: ${event.title}'),
        duration: const Duration(seconds: 2),
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
            onPressed: () {
              // TODO: Implement event deletion
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted: ${event.title}'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}