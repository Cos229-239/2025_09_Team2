import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../models/calendar_event.dart';

/// Widget displaying calendar statistics and insights
class CalendarStatsWidget extends StatelessWidget {
  const CalendarStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final stats = provider.getCalendarStats();
        final upcomingEvents = provider.getUpcomingEvents();
        final overdueEvents = provider.getOverdueEvents();
        final currentEvents = provider.getCurrentEvents();

        return Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Calendar Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: provider.refreshAllEvents,
                      icon: Icon(
                        Icons.refresh,
                        color: Theme.of(context).primaryColor,
                      ),
                      tooltip: 'Refresh events',
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Current status row
                if (currentEvents.isNotEmpty) ...[
                  _buildStatusSection(
                    context,
                    title: 'Happening Now',
                    events: currentEvents,
                    icon: Icons.play_circle_filled,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 16),
                ],

                if (overdueEvents.isNotEmpty) ...[
                  _buildStatusSection(
                    context,
                    title: 'Overdue',
                    events: overdueEvents,
                    icon: Icons.warning,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                ],

                _buildStatusSection(
                  context,
                  title: 'Upcoming (7 days)',
                  events: upcomingEvents,
                  icon: Icons.schedule,
                  color: Colors.blue,
                ),
                const SizedBox(height: 20),

                // Statistics grid
                _buildStatsGrid(context, stats),
                const SizedBox(height: 20),

                // Study time this week
                _buildStudyTimeCard(context, stats['studyTimeThisWeek'] ?? 0),
                const SizedBox(height: 16),

                // Event type distribution
                _buildEventTypeDistribution(
                    context, stats['eventsByType'] ?? {}),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
    BuildContext context, {
    required String title,
    required List<CalendarEvent> events,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${events.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: events.take(3).map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        event.icon,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          event.title,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        event.formattedTime,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            if (events.length > 3)
              Text(
                '+${events.length - 3} more',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          context,
          title: 'Total Events',
          value: '${stats['totalEvents'] ?? 0}',
          icon: Icons.event,
          color: Colors.purple,
        ),
        _buildStatCard(
          context,
          title: 'Completed',
          value: '${stats['completedEvents'] ?? 0}',
          icon: Icons.check_circle,
          color: Colors.green,
        ),
        _buildStatCard(
          context,
          title: 'Average/Day',
          value: '${(stats['averageEventsPerDay'] ?? 0.0).toStringAsFixed(1)}',
          icon: Icons.trending_up,
          color: Colors.orange,
        ),
        _buildStatCard(
          context,
          title: 'This Week',
          value: '${_getEventsThisWeek()}',
          icon: Icons.calendar_today,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeCard(BuildContext context, int studyMinutes) {
    final hours = studyMinutes / 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withValues(alpha: 0.1),
            Theme.of(context).primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Study Time This Week',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${hours.toStringAsFixed(1)} hours',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$studyMinutes minutes total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                          ),
                    ),
                    const SizedBox(height: 4),
                    _buildProgressBar(
                      context,
                      progress:
                          (hours / 40).clamp(0.0, 1.0), // Target: 40 hours/week
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _getStudyTimeEncouragement(hours),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.8),
                  fontStyle: FontStyle.italic,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context,
      {required double progress, required Color color}) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(3),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTypeDistribution(
    BuildContext context,
    Map<String, int> eventsByType,
  ) {
    if (eventsByType.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Distribution',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...eventsByType.entries.map((entry) {
          final percentage =
              eventsByType.values.fold(0, (sum, value) => sum + value) > 0
                  ? (entry.value /
                      eventsByType.values.fold(0, (sum, value) => sum + value))
                  : 0.0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    entry.key,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getEventTypeColor(entry.key),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${entry.value}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _getEventTypeColor(String eventType) {
    final typeMap = {
      'Task': Colors.blue,
      'Daily Quest': Colors.purple,
      'Social Session': Colors.green,
      'Study Session': Colors.orange,
      'Pet Care': Colors.brown,
      'Break': Colors.teal,
    };
    return typeMap[eventType] ?? Colors.grey;
  }

  String _getStudyTimeEncouragement(double hours) {
    if (hours >= 35) return "Excellent! You're crushing your study goals! 🏆";
    if (hours >= 20) return "Great work! You're making solid progress! 📚";
    if (hours >= 10) return "Good effort! Keep building that momentum! 💪";
    if (hours >= 5) return "Nice start! Let's aim for more study time! ⭐";
    return "Time to hit the books! Your future self will thank you! 🚀";
  }

  int _getEventsThisWeek() {
    // This would need to be calculated from the provider
    // For now, return a placeholder
    return 12; // Placeholder
  }
}

/// Compact version of calendar stats for dashboard use
class CompactCalendarStats extends StatelessWidget {
  const CompactCalendarStats({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, provider, child) {
        final upcomingEvents = provider.getUpcomingEvents();
        final overdueEvents = provider.getOverdueEvents();
        final currentEvents = provider.getCurrentEvents();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Today\'s Schedule',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                if (currentEvents.isNotEmpty) ...[
                  _buildQuickStat(
                    context,
                    'Happening Now',
                    currentEvents.length,
                    Colors.green,
                    Icons.play_circle_filled,
                  ),
                  const SizedBox(height: 8),
                ],
                if (overdueEvents.isNotEmpty) ...[
                  _buildQuickStat(
                    context,
                    'Overdue',
                    overdueEvents.length,
                    Colors.red,
                    Icons.warning,
                  ),
                  const SizedBox(height: 8),
                ],
                _buildQuickStat(
                  context,
                  'Upcoming',
                  upcomingEvents.length,
                  Colors.blue,
                  Icons.schedule,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to full calendar
                    },
                    icon: const Icon(Icons.calendar_month, size: 16),
                    label: const Text('View Calendar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(
    BuildContext context,
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
