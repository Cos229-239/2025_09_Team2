import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

/// Widget that displays user study progress as a graph
/// Shows a line chart with study metrics over time
class ProgressGraphWidget extends StatefulWidget {
  const ProgressGraphWidget({super.key});

  @override
  State<ProgressGraphWidget> createState() => _ProgressGraphWidgetState();
}

class _ProgressGraphWidgetState extends State<ProgressGraphWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16181A), // Hollow - match background color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FB8E9), // New blue border color
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            // Background gradient effect - hollow appearance
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF16181A), // Match main background
                    const Color(0xFF16181A), // Keep same for hollow effect
                  ],
                ),
              ),
            ),

            // Graph content - tight to borders like reference image
            Padding(
              padding: const EdgeInsets.all(4),
              child: _buildGraph(context),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the actual graph visualization
  Widget _buildGraph(BuildContext context) {
    // Generate sample data points for the graph
    final List<FlSpot> dataPoints = _generateSampleData();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: false,
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: 30,
        minY: 0,
        maxY: 100,
        lineBarsData: [
          // Main data line (blue gradient)
          LineChartBarData(
            spots: dataPoints,
            isCurved: true,
            color: const Color(0xFF64B5F6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF64B5F6),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF64B5F6).withOpacity(0.3),
                  const Color(0xFF64B5F6).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Secondary data line (cyan/teal)
          LineChartBarData(
            spots: _generateSecondaryData(),
            isCurved: true,
            color: const Color(0xFF4DD0E1),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: const Color(0xFF4DD0E1),
                  strokeWidth: 0,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF4DD0E1).withOpacity(0.2),
                  const Color(0xFF4DD0E1).withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                return LineTooltipItem(
                  '${barSpot.y.toInt()}',
                  TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color ?? const Color(0xFFD9D9D9),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Generate sample data points for the primary graph line
  List<FlSpot> _generateSampleData() {
    final random = math.Random(42); // Fixed seed for consistent data
    final List<FlSpot> spots = [];

    double currentValue = 20;
    for (int i = 0; i <= 30; i++) {
      // Add some randomness with upward trend
      currentValue += random.nextDouble() * 8 - 2;
      currentValue = currentValue.clamp(10, 90);

      spots.add(FlSpot(i.toDouble(), currentValue));
    }

    return spots;
  }

  /// Generate sample data points for the secondary graph line
  List<FlSpot> _generateSecondaryData() {
    final random = math.Random(24); // Different seed
    final List<FlSpot> spots = [];

    double currentValue = 30;
    for (int i = 0; i <= 30; i++) {
      // Add some randomness with upward trend
      currentValue += random.nextDouble() * 6 - 1.5;
      currentValue = currentValue.clamp(15, 85);

      spots.add(FlSpot(i.toDouble(), currentValue));
    }

    return spots;
  }
}
