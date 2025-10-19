import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/study_analytics_provider.dart';

/// A detailed screen showing comprehensive learning progress analytics
class DetailedProgressScreen extends StatefulWidget {
  const DetailedProgressScreen({super.key});

  @override
  State<DetailedProgressScreen> createState() => _DetailedProgressScreenState();
}

class _DetailedProgressScreenState extends State<DetailedProgressScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _timeRange = 30; // Default to 30 days
  
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        title: const Text(
          'Learning Progress',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Performance'),
            Tab(text: 'Time Spent'),
            Tab(text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPerformanceTab(),
          _buildTimeSpentTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }
  
  Widget _buildPerformanceTab() {
    return Consumer<StudyAnalyticsProvider>(
      builder: (context, analytics, child) {
        if (analytics.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (analytics.error != null) {
          return Center(child: Text('Could not load analytics: ${analytics.error}'));
        }
        
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeRangeSelector(),
              const SizedBox(height: 24),
              _buildSubjectPerformanceChart(analytics),
              const SizedBox(height: 32),
              _buildRetentionCard(analytics),
              const SizedBox(height: 32),
              _buildDifficultyDistributionCard(analytics),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTimeSpentTab() {
    return Consumer<StudyAnalyticsProvider>(
      builder: (context, analytics, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTimeDistributionPieChart(analytics),
              const SizedBox(height: 32),
              _buildProductivityTimelineCard(analytics),
              const SizedBox(height: 32),
              _buildSessionComparisonCard(analytics),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildInsightsTab() {
    return Consumer<StudyAnalyticsProvider>(
      builder: (context, analytics, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLearningGapsCard(analytics),
              const SizedBox(height: 24),
              _buildRecommendationsCard(analytics),
              const SizedBox(height: 24),
              _buildProgressPredictionCard(analytics),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildTimeRangeSelector() {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Range:',
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(width: 8), // Add spacing
            Flexible(
              child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 7, label: Text('Week')),
                ButtonSegment(value: 30, label: Text('Month')),
                ButtonSegment(value: 90, label: Text('3 Months')),
              ],
              selected: {_timeRange},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _timeRange = newSelection.first;
                });
              },
              style: SegmentedButtonTheme.of(context).style,
            ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSubjectPerformanceChart(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final subjectData = analytics.getSubjectProgressData(_timeRange);
    
    // List of colors to use for different subjects
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      const Color(0xFFFF8A65),
      const Color(0xFF4DD0E1),
      const Color(0xFFFFD54F),
      const Color(0xFFAB47BC),
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subject Performance',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Track your mastery across different subjects',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: _timeRange.toDouble() - 1,
                  minY: 0,
                  maxY: 100,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: colorScheme.onSurface.withValues(alpha: 0.2),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: _timeRange > 30 ? 15 : 7,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % (_timeRange > 30 ? 15 : 7) != 0) {
                            return const SizedBox.shrink();
                          }
                          
                          final date = DateTime.now().subtract(
                            Duration(days: _timeRange - value.toInt() - 1)
                          );
                          
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              '${value.toInt()}%',
                              style: TextStyle(
                                color: colorScheme.onSurface.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    for (int i = 0; i < subjectData.entries.length; i++)
                      LineChartBarData(
                        spots: subjectData.values.elementAt(i),
                        isCurved: true,
                        color: colors[i % colors.length],
                        barWidth: 3,
                        dotData: FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors[i % colors.length].withValues(alpha: 0.15),
                        ),
                      ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                        return touchedBarSpots.map((barSpot) {
                          final index = barSpot.barIndex;
                          final subject = subjectData.keys.elementAt(index);
                          return LineTooltipItem(
                            '$subject: ${barSpot.y.toInt()}%',
                            TextStyle(
                              color: colors[index % colors.length],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (int i = 0; i < subjectData.entries.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: colors[i % colors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        subjectData.keys.elementAt(i),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeDistributionPieChart(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeDistribution = analytics.getSubjectTimeDistribution();
    
    // List of colors to use for different subjects
    final colors = [
      colorScheme.primary,
      colorScheme.secondary,
      colorScheme.tertiary,
      const Color(0xFFFF8A65),
      const Color(0xFF4DD0E1),
      const Color(0xFFFFD54F),
      const Color(0xFFAB47BC),
    ];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Study Time Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'How you allocate your study time across subjects',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (int i = 0; i < timeDistribution.entries.length; i++)
                            PieChartSectionData(
                              value: timeDistribution.values.elementAt(i),
                              title: '${(timeDistribution.values.elementAt(i) * 100).toInt()}%',
                              color: colors[i % colors.length],
                              radius: 100,
                              titleStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (int i = 0; i < timeDistribution.entries.length; i++) ...[
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  timeDistribution.keys.elementAt(i),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // The following widgets are placeholders that would be implemented with real data
  
  Widget _buildRetentionCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Knowledge Retention',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Knowledge retention graph based on spaced repetition intervals would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDifficultyDistributionCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Distribution',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Chart showing distribution of easy, moderate, and difficult cards across subjects would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProductivityTimelineCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productivity Timeline',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Chart showing your most productive study hours during the day would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionComparisonCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session Comparison',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Comparison of solo study sessions vs. social study sessions effectiveness would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLearningGapsCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learning Gaps',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Heatmap visualization of problematic topics and knowledge gaps would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRecommendationsCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('AI-generated recommendations for what to study next based on your performance data would be displayed here.'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressPredictionCard(StudyAnalyticsProvider analytics) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress Projection',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text('Prediction of your future progress based on current study patterns would be displayed here.'),
          ],
        ),
      ),
    );
  }
}