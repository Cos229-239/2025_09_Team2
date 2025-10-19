import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_event.dart';
import '../widgets/planner/enhanced_calendar_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF242628),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242628),
        title: const Text(
          'StudyPals Calendar',
          style: TextStyle(color: Color(0xFFD9D9D9)),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFD9D9D9)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6FB8E9)),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        bottom: TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFF6FB8E9),
                labelColor: const Color(0xFF6FB8E9),
                unselectedLabelColor: const Color(0xFFD9D9D9).withOpacity(0.6),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.calendar_month),
                    text: 'Calendar',
                  ),
                  Tab(
                    icon: Icon(Icons.list),
                    text: 'Agenda',
                  ),
                ],
              ),
      ),
      body: TabBarView(
              controller: _tabController,
              children: [
                _buildCalendarView(),
                _buildAgendaView(),
              ],
            ),
      drawer: _buildDrawer(),
    );
  }

  Widget _buildCalendarView() {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: provider.refreshAllEvents,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: EnhancedCalendarWidget(
              onDaySelected: (date, events) {
                provider.setSelectedDay(date);
                // Navigate to day itinerary view
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
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
              style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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
          color: const Color(0xFF242628),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF6FB8E9).withOpacity(0.3),
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
                    style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD9D9D9),
                          fontSize: 15,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    event.formattedTime,
                    style: TextStyle(
                          color: const Color(0xFFD9D9D9).withOpacity(0.7),
                          fontSize: 13,
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
              ],
            ),
          ],
        ),
      ),
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
              const Color(0xFF6FB8E9),
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
              const Color(0xFF4CAF50),
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

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF242628),
      child: Consumer<CalendarProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color(0xFF6FB8E9),
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
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Event Types', style: TextStyle(color: Color(0xFFD9D9D9))),
              ),
              ...CalendarEventType.values.map((type) {
                final isActive = provider.activeFilters.contains(type);
                return CheckboxListTile(
                  title: Text(type.displayName, style: TextStyle(color: Color(0xFFD9D9D9))),
                  secondary: Icon(type.defaultIcon, color: type.defaultColor),
                  value: isActive,
                  activeColor: const Color(0xFF6FB8E9),
                  checkColor: Colors.white,
                  onChanged: (value) => provider.toggleEventTypeFilter(type),
                );
              }),

              const Divider(color: Color(0xFF6FB8E9), thickness: 0.5),

              // Status filters
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Status', style: TextStyle(color: Color(0xFFD9D9D9))),
              ),
              ...CalendarEventStatus.values.map((status) {
                if (status == CalendarEventStatus.expired ||
                    status == CalendarEventStatus.postponed) {
                  return const SizedBox.shrink();
                }

                final isActive = provider.statusFilters.contains(status);
                return CheckboxListTile(
                  title: Text(status.name, style: TextStyle(color: Color(0xFFD9D9D9))),
                  value: isActive,
                  activeColor: const Color(0xFF6FB8E9),
                  checkColor: Colors.white,
                  onChanged: (value) => provider.toggleStatusFilter(status),
                );
              }),

              const Divider(color: Color(0xFF6FB8E9), thickness: 0.5),

              // Auto-refresh toggle
              SwitchListTile(
                title: const Text('Auto Refresh', style: TextStyle(color: Color(0xFFD9D9D9))),
                subtitle: const Text('Automatically sync events', style: TextStyle(color: Color(0xFFD9D9D9))),
                value: provider.autoRefresh,
                activeColor: const Color(0xFF6FB8E9),
                onChanged: provider.setAutoRefresh,
              ),

              // Clear filters
              ListTile(
                leading: const Icon(Icons.clear_all, color: Color(0xFF6FB8E9)),
                title: const Text('Clear All Filters', style: TextStyle(color: Color(0xFFD9D9D9))),
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
            decoration: const BoxDecoration(
              color: Color(0xFF242628),
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
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
                      color: const Color(0xFF6FB8E9).withOpacity(0.5),
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
                        color: const Color(0xFF242628),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: event.color,
                          width: 2,
                        ),
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
                            style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFD9D9D9),
                                  fontSize: 20,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.type.displayName,
                            style: TextStyle(
                                  color: event.color,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
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
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFD9D9D9),
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
              color: const Color(0xFF6FB8E9),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD9D9D9),
                    fontSize: 14,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 14,
          ),
        ),
      ],
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
