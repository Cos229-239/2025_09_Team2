import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../providers/study_analytics_provider.dart';
import '../../screens/detailed_progress_screen.dart';

/// A card widget for the dashboard that shows a summarized view of learning progress
class LearningProgressCard extends StatelessWidget {
  const LearningProgressCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Learning Progress',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.arrow_forward, color: colorScheme.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DetailedProgressScreen(),
                      ),
                    );
                  },
                  tooltip: 'View Detailed Progress',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Consumer<StudyAnalyticsProvider>(
              builder: (context, analytics, child) {
                if (analytics.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (analytics.error != null) {
                  return Center(
                    child: Text(
                      'Could not load analytics',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    ),
                  );
                }

                return Column(
                  children: [
                    SizedBox(
                      height: 100,
                      child: _buildProgressChart(context, analytics),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Mastery',
                          '${analytics.overallMasteryPercentage.toInt()}%',
                          Icons.school,
                          colorScheme.primary,
                        ),
                        _buildStatItem(
                          context,
                          'Study Streak',
                          '${analytics.currentStreak} days',
                          Icons.local_fire_department,
                          colorScheme.secondary,
                        ),
                        _buildStatItem(
                          context,
                          'Cards Today',
                          analytics.cardsReviewedToday.toString(),
                          Icons.badge,
                          colorScheme.tertiary,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart(BuildContext context, StudyAnalyticsProvider analytics) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: 100,
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                final day = DateTime.now().subtract(Duration(days: 6 - index));
                final dayName = _getDayName(day.weekday);
                return LineTooltipItem(
                  '$dayName: ${barSpot.y.toInt()}%',
                  TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: analytics.weeklyPerformanceData,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}