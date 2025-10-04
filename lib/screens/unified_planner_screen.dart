import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_event.dart';
import '../widgets/planner/enhanced_calendar_widget.dart';
import '../widgets/planner/calendar_stats_widget.dart';
import 'day_itinerary_screen.dart';

/// Enhanced planner screen with unified calendar system
class UnifiedPlannerScreen extends StatefulWidget {
  const UnifiedPlannerScreen({super.key});

  @override
  State<UnifiedPlannerScreen> createState() => _UnifiedPlannerScreenState();
}

class _UnifiedPlannerScreenState extends State<UnifiedPlannerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _showStats = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StudyPals Calendar'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              setState(() => _showStats = !_showStats);
            },
            icon: Icon(
              _showStats ? Icons.calendar_month : Icons.analytics,
            ),
            tooltip: _showStats ? 'Show Calendar' : 'Show Statistics',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: ListTile(
                  leading: Icon(Icons.refresh),
                  title: Text('Refresh'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'auto_refresh',
                child: ListTile(
                  leading: Icon(Icons.sync),
                  title: Text('Toggle Auto Refresh'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'schedule_breaks',
                child: ListTile(
                  leading: Icon(Icons.free_breakfast),
                  title: Text('Schedule Study Breaks'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'suggestions',
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('Smart Suggestions'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'exit',
                child: ListTile(
                  leading: Icon(Icons.exit_to_app),
                  title: Text('Exit Calendar'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: _showStats
            ? null
            : TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_month),
                    text: 'Calendar',
                  ),
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'Agenda',
                  ),
                  Tab(
                    icon: Icon(Icons.schedule),
                    text: 'Timeline',
                  ),
                ],
              ),
      ),
      body: _showStats
          ? const SingleChildScrollView(
              child: CalendarStatsWidget(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarView(),
                _buildAgendaView(),
                _buildTimelineView(),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildCalendarView() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: provider.refreshAllEvents,
<<<<<<< Updated upstream
          child: EnhancedCalendarWidget(
            onDaySelected: (date, events) {
              // Optional: Navigate to day detail view
            },
            onEventTapped: _showEventDetails,
            enableQuickCreate: true,
            showFilters: true,
            showEventList: true,
=======
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: EnhancedCalendarWidget(
              onDaySelected: (date, events) {
                // Navigate to day detail view
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DayItineraryScreen(
                      selectedDate: date,
                    ),
                  ),
                );
              },
              onEventTapped: _showEventDetails,
              enableQuickCreate: true,
              showFilters: true,
              showEventList: true,
            ),
>>>>>>> Stashed changes
          ),
        );
      },
    );
  }

  Widget _buildAgendaView() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final upcomingEvents = provider.getUpcomingEvents();
        final overdueEvents = provider.getOverdueEvents();
        final currentEvents = provider.getCurrentEvents();

        return RefreshIndicator(
          onRefresh: provider.refreshAllEvents,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current events
                if (currentEvents.isNotEmpty) ...[
                  _buildAgendaSection(
                    'Happening Now',
                    currentEvents,
                    Colors.green,
                    Icons.play_circle_filled,
                  ),
                  const SizedBox(height: 24),
                ],

                // Overdue events
                if (overdueEvents.isNotEmpty) ...[
                  _buildAgendaSection(
                    'Overdue',
                    overdueEvents,
                    Colors.red,
                    Icons.warning,
                  ),
                  const SizedBox(height: 24),
                ],

                // Upcoming events
                _buildAgendaSection(
                  'Upcoming (Next 7 Days)',
                  upcomingEvents,
                  Colors.blue,
                  Icons.schedule,
                ),

                // Quick actions
                const SizedBox(height: 32),
                _buildQuickActions(provider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimelineView() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final todayEvents = provider.getEventsForDay(DateTime.now());

        if (todayEvents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 64,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'No events scheduled for today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the + button to create your first event',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                      ),
                ),
              ],
            ),
          );
        }

        // Sort events by start time
        final sortedEvents = List<CalendarEvent>.from(todayEvents)
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

        return RefreshIndicator(
          onRefresh: provider.refreshAllEvents,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final event = sortedEvents[index];
              final isFirst = index == 0;
              final isLast = index == sortedEvents.length - 1;

              return _buildTimelineItem(
                event,
                isFirst: isFirst,
                isLast: isLast,
                showTime: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAgendaSection(
    String title,
    List<CalendarEvent> events,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(
                '${events.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...events.map((event) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildEventCard(event),
            )),
      ],
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    return InkWell(
      onTap: () => _showEventDetails(event),
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
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Icon(
              event.icon,
              color: event.color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.formattedTime,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                  ),
                  if (event.description.isNotEmpty &&
                      event.description != event.title)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        event.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Column(
              children: [
                if (event.isHappeningNow)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                if (event.isCompletable)
                  IconButton(
                    icon: Icon(
                      event.status == CalendarEventStatus.completed
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: event.status == CalendarEventStatus.completed
                          ? Colors.green
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.5),
                    ),
                    onPressed: () => _toggleEventCompletion(event),
                    tooltip: event.status == CalendarEventStatus.completed
                        ? 'Mark as incomplete'
                        : 'Mark as complete',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(
    CalendarEvent event, {
    required bool isFirst,
    required bool isLast,
    required bool showTime,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline column
        SizedBox(
          width: 60,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: event.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 60,
                  color: Colors.grey.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),

        // Time column
        if (showTime)
          SizedBox(
            width: 80,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.jm().format(event.startTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (event.endTime != null)
                  Text(
                    DateFormat.jm().format(event.endTime!),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
              ],
            ),
          ),

        // Event card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: _buildEventCard(event),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions(CalendarProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildQuickActionChip(
              'Schedule Study Session',
              Icons.school,
              Colors.blue,
              () => _createQuickEvent(CalendarEventType.studySession),
            ),
            _buildQuickActionChip(
              'Add Task',
              Icons.task_alt,
              Colors.orange,
              () => _createQuickEvent(CalendarEventType.task),
            ),
            _buildQuickActionChip(
              'Plan Break',
              Icons.free_breakfast,
              Colors.green,
              () => _createQuickEvent(CalendarEventType.breakReminder),
            ),
            _buildQuickActionChip(
              'Smart Schedule',
              Icons.lightbulb_outline,
              Colors.purple,
              _showSmartSuggestions,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionChip(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _showCreateEventDialog,
      icon: const Icon(Icons.add),
      label: const Text('New Event'),
      tooltip: 'Create new calendar event',
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Calendar Filters',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Customize your view',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                    ),
                  ],
                ),
              ),

              // Event type filters
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Event Types'),
              ),
              ...CalendarEventType.values.map((type) {
                final isActive = provider.activeFilters.contains(type);
                return CheckboxListTile(
                  title: Text(type.displayName),
                  secondary: Icon(type.defaultIcon, color: type.defaultColor),
                  value: isActive,
                  onChanged: (value) => provider.toggleEventTypeFilter(type),
                );
              }),

              const Divider(),

              // Status filters
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Status'),
              ),
              ...CalendarEventStatus.values.map((status) {
                if (status == CalendarEventStatus.expired ||
                    status == CalendarEventStatus.postponed) {
                  return const SizedBox.shrink();
                }

                final isActive = provider.statusFilters.contains(status);
                return CheckboxListTile(
                  title: Text(status.name),
                  value: isActive,
                  onChanged: (value) => provider.toggleStatusFilter(status),
                );
              }),

              const Divider(),

              // Auto-refresh toggle
              SwitchListTile(
                title: const Text('Auto Refresh'),
                subtitle: const Text('Automatically sync events'),
                value: provider.autoRefresh,
                onChanged: provider.setAutoRefresh,
              ),

              // Clear filters
              ListTile(
                leading: const Icon(Icons.clear_all),
                title: const Text('Clear All Filters'),
                onTap: () {
                  provider.clearFilters();
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleMenuAction(String action) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);

    switch (action) {
      case 'refresh':
        provider.refreshAllEvents();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Events refreshed')),
        );
        break;
      case 'auto_refresh':
        provider.setAutoRefresh(!provider.autoRefresh);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              provider.autoRefresh
                  ? 'Auto refresh enabled'
                  : 'Auto refresh disabled',
            ),
          ),
        );
        break;
      case 'schedule_breaks':
        provider.scheduleStudyBreaks();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Study breaks scheduled')),
        );
        break;
      case 'suggestions':
        _showSmartSuggestions();
        break;
      case 'exit':
        Navigator.of(context).pop();
        break;
    }
  }

  void _showEventDetails(CalendarEvent event) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Event header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        event.icon,
                        color: event.color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.type.displayName,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: event.color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (event.isCompletable)
                      IconButton(
                        icon: Icon(
                          event.status == CalendarEventStatus.completed
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          color: event.status == CalendarEventStatus.completed
                              ? Colors.green
                              : null,
                        ),
                        onPressed: () => _toggleEventCompletion(event),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Event details
                if (event.description.isNotEmpty) ...[
                  _buildDetailSection(
                    'Description',
                    event.description,
                    Icons.description,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildDetailSection(
                  'Time',
                  event.formattedTime,
                  Icons.schedule,
                ),
                const SizedBox(height: 16),

                if (event.location != null) ...[
                  _buildDetailSection(
                    'Location',
                    event.location!,
                    Icons.location_on,
                  ),
                  const SizedBox(height: 16),
                ],

                if (event.tags.isNotEmpty) ...[
                  _buildDetailSection(
                    'Tags',
                    event.tags.join(', '),
                    Icons.label,
                  ),
                  const SizedBox(height: 16),
                ],

                if (event.estimatedMinutes != null) ...[
                  _buildDetailSection(
                    'Duration',
                    '${event.estimatedMinutes} minutes',
                    Icons.timer,
                  ),
                  const SizedBox(height: 24),
                ],

                // Action buttons
                Row(
                  children: [
                    if (event.isEditable) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editEvent(event);
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to related screen based on event type
                          _navigateToEventSource(event);
                        },
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  void _showCreateEventDialog() {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => QuickCreateEventDialog(
        selectedDate: provider.selectedDay,
        onEventCreated: (event) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Event "${event.title}" created'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _createQuickEvent(CalendarEventType type) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => QuickCreateEventDialog(
        selectedDate: provider.selectedDay,
        onEventCreated: (event) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${type.displayName} created'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _editEvent(CalendarEvent event) {
    // Implementation for editing events
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit functionality coming soon')),
    );
  }

  void _toggleEventCompletion(CalendarEvent event) {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.completeEvent(event);
  }

  void _navigateToEventSource(CalendarEvent event) {
    // Navigate to the appropriate screen based on event type
    switch (event.type) {
      case CalendarEventType.task:
        // Navigate to task detail
        break;
      case CalendarEventType.dailyQuest:
        // Navigate to quest screen
        break;
      case CalendarEventType.socialSession:
        // Navigate to social session
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Navigation not implemented yet')),
        );
    }
  }

  void _showSmartSuggestions() {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    final suggestions = provider.generateScheduleSuggestions(
      eventType: CalendarEventType.studySession,
      durationMinutes: 60,
    );

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Schedule Suggestions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              if (suggestions.isEmpty)
                const Text('No suggestions available at this time.')
              else
                ...suggestions.map((suggestion) => ListTile(
                      leading: Icon(
                        suggestion.icon,
                        color: suggestion.color,
                      ),
                      title: Text(suggestion.title),
                      subtitle: Text(suggestion.formattedTime),
                      trailing: ElevatedButton(
                        onPressed: () async {
                          final navigator = Navigator.of(context);
                          final scaffoldMessenger =
                              ScaffoldMessenger.of(context);
                          navigator.pop();
                          final event = await provider.createEvent(
                            title: 'Study Session',
                            description: 'Scheduled study session',
                            type: CalendarEventType.studySession,
                            startTime: suggestion.startTime,
                            endTime: suggestion.endTime,
                            estimatedMinutes: suggestion.estimatedMinutes,
                          );

                          if (event != null && mounted) {
                            scaffoldMessenger.showSnackBar(
                              const SnackBar(
                                content: Text('Study session scheduled'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        child: const Text('Schedule'),
                      ),
                    )),
            ],
          ),
        );
      },
    );
  }
}
