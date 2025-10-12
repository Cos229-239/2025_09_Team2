import 'package:flutter/material.dart';
import '../../services/predictive_scheduling_service.dart';

// TODO: Schedule Prediction Widget - Missing AI and Prediction Features
// - Predictive scheduling service is mostly placeholder implementation
// - No actual machine learning or AI algorithms for schedule optimization
// - Missing integration with real user behavior data
// - No A/B testing for schedule recommendations
// - Missing personalization based on user performance patterns
// - No integration with external calendars for conflict detection
// - Missing weather and external factors consideration
// - No social learning schedule coordination
// - Missing predictive analytics for success probability
// - No schedule adaptation based on real-time feedback
// - Missing notification system for schedule changes
// - No export functionality for predicted schedules

/// Widget for displaying study schedule predictions
class SchedulePredictionWidget extends StatelessWidget {
  final StudySchedulePrediction prediction;
  final VoidCallback? onSchedule;
  final VoidCallback? onCustomize;

  const SchedulePredictionWidget({
    super.key,
    required this.prediction,
    this.onSchedule,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      color: const Color(0xFF242628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: const Color(0xFF6FB8E9).withAlpha((0.3 * 255).round()),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildTimeInfo(),
            const SizedBox(height: 16),
            _buildSessionDetails(),
            const SizedBox(height: 16),
            _buildReasoning(),
            const SizedBox(height: 20),
            _buildConfidenceIndicator(),
            const SizedBox(height: 20),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.schedule,
          color: Color(0xFF6FB8E9),
          size: 28,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optimal Study Time',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFFD9D9D9),
                ),
              ),
              Text(
                'AI-Predicted Schedule',
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        _buildDifficultyChip(),
      ],
    );
  }

  Widget _buildDifficultyChip() {
    final color = _getDifficultyColor();
    final label = _getDifficultyLabel();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildTimeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withAlpha((0.3 * 255).round()),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFF6FB8E9),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDateTime(prediction.recommendedTime),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF6FB8E9),
                  ),
                ),
                Text(
                  'Duration: ${_formatDuration(prediction.estimatedDuration)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6FB8E9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6FB8E9).withAlpha((0.2 * 255).round()),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${(prediction.confidenceScore * 100).round()}% confident',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6FB8E9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recommended Subjects',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFFD9D9D9),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: prediction.recommendedSubjects.map((subject) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withAlpha((0.5 * 255).round()),
                ),
              ),
              child: Text(
                subject,
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReasoning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA726).withAlpha((0.15 * 255).round()),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFA726).withAlpha((0.4 * 255).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.psychology,
                color: Color(0xFFFFA726),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'AI Reasoning',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFA726),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prediction.reasoning,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFFFA726),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    final confidence = prediction.confidenceScore;
    final color = confidence > 0.7
        ? const Color(0xFF4CAF50)
        : confidence > 0.4
            ? const Color(0xFFFFA726)
            : Colors.red;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Prediction Confidence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFD9D9D9),
              ),
            ),
            const Spacer(),
            Text(
              '${(confidence * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: confidence,
          backgroundColor: const Color(0xFF1A1A1A),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
        const SizedBox(height: 4),
        Text(
          _getConfidenceDescription(confidence),
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onSchedule,
            icon: const Icon(Icons.schedule),
            label: const Text('Schedule This'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6FB8E9),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onCustomize,
            icon: const Icon(Icons.tune),
            label: const Text('Customize'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF6FB8E9),
              side: const BorderSide(
                color: Color(0xFF6FB8E9),
                width: 2,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getDifficultyColor() {
    switch (prediction.recommendedDifficulty) {
      case StudyDifficulty.easy:
        return Colors.green;
      case StudyDifficulty.medium:
        return Colors.orange;
      case StudyDifficulty.hard:
        return Colors.red;
      case StudyDifficulty.review:
        return Colors.blue;
    }
  }

  String _getDifficultyLabel() {
    switch (prediction.recommendedDifficulty) {
      case StudyDifficulty.easy:
        return 'Easy';
      case StudyDifficulty.medium:
        return 'Medium';
      case StudyDifficulty.hard:
        return 'Challenging';
      case StudyDifficulty.review:
        return 'Review';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[dateTime.weekday - 1];
    final monthName = months[dateTime.month - 1];
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';

    return '$dayName, $monthName ${dateTime.day} at $hour:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  String _getConfidenceDescription(double confidence) {
    if (confidence > 0.8) {
      return 'Very high confidence - This schedule is highly optimized for you';
    } else if (confidence > 0.6) {
      return 'High confidence - Good alignment with your patterns';
    } else if (confidence > 0.4) {
      return 'Medium confidence - Based on available data';
    } else {
      return 'Low confidence - Need more data to improve predictions';
    }
  }
}

/// Weekly schedule view widget
class WeeklyScheduleWidget extends StatefulWidget {
  final List<StudySchedulePrediction> weeklyPredictions;
  final Function(StudySchedulePrediction)? onSchedulePrediction;

  const WeeklyScheduleWidget({
    super.key,
    required this.weeklyPredictions,
    this.onSchedulePrediction,
  });

  @override
  State<WeeklyScheduleWidget> createState() => _WeeklyScheduleWidgetState();
}

class _WeeklyScheduleWidgetState extends State<WeeklyScheduleWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            ...widget.weeklyPredictions.map(
              (prediction) => _buildDaySchedule(prediction),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.calendar_view_week,
          color: Theme.of(context).primaryColor,
          size: 24,
        ),
        const SizedBox(width: 12),
        Text(
          'Weekly Study Schedule',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildDaySchedule(StudySchedulePrediction prediction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildDayInfo(prediction.recommendedTime),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTime(prediction.recommendedTime)} (${_formatDuration(prediction.estimatedDuration)})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prediction.recommendedSubjects.join(', '),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => widget.onSchedulePrediction?.call(prediction),
            icon: const Icon(Icons.add_circle_outline),
            color: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDayInfo(DateTime dateTime) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[dateTime.weekday - 1];

    return SizedBox(
      width: 60,
      child: Column(
        children: [
          Text(
            dayName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          Text(
            '${dateTime.day}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : dateTime.hour > 12
            ? dateTime.hour - 12
            : dateTime.hour;
    final amPm = dateTime.hour < 12 ? 'AM' : 'PM';
    return '$hour:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

/// Schedule optimization factors display
class OptimizationFactorsWidget extends StatelessWidget {
  final Map<String, dynamic> optimizationFactors;

  const OptimizationFactorsWidget({
    super.key,
    required this.optimizationFactors,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Optimization Factors',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...optimizationFactors.entries.map(
              (entry) => _buildFactorRow(entry.key, entry.value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorRow(String factor, dynamic value) {
    final percentage = value is double ? (value * 100).round() : 0;
    final color = percentage > 70
        ? Colors.green
        : percentage > 40
            ? Colors.orange
            : Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _formatFactorName(factor),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '$percentage%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 80,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: Colors.grey.shade200,
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage / 100,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(2),
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFactorName(String factor) {
    switch (factor) {
      case 'timeOptimization':
        return 'Time of Day';
      case 'dayOptimization':
        return 'Day of Week';
      case 'circadianAlignment':
        return 'Circadian Rhythm';
      case 'difficultyMatch':
        return 'Difficulty Level';
      case 'subjectRelevance':
        return 'Subject Priority';
      default:
        return factor
            .split('_')
            .map((word) => word[0].toUpperCase() + word.substring(1))
            .join(' ');
    }
  }
}
