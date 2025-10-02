import 'package:flutter/material.dart';
import 'package:studypals/utils/responsive_spacing.dart';

/// Widget that displays a compact calendar view with current date highlighted
/// Shows the current week with the current date highlighted in blue
class CalendarDisplayWidget extends StatelessWidget {
  const CalendarDisplayWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonth = _getMonthName(now.month);
    final currentYear = now.year;

    // Calculate the week containing today
    final startOfWeek = now.subtract(Duration(days: now.weekday % 7));
    final weekDays =
        List.generate(7, (index) => startOfWeek.add(Duration(days: index)));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // No padding for alignment
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month and year header
          Text(
            '$currentMonth $currentYear',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
          ),
          const SizedBox(height: 16),

          // Week day headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                .map((day) => Expanded(
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: const Color(0xFF6FB8E9),
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: ResponsiveSpacing.getSmallSpacing(context) * 0.5),

          // Week dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: weekDays
                .map((date) => Expanded(
                      child: Container(
                        height: ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton) * 0.8,
                        decoration: BoxDecoration(
                          color: _isToday(date)
                              ? const Color(0xFF6FB8E9)
                              : Colors.transparent,
                          shape: BoxShape.circle, // Changed to circular shape
                        ),
                        child: Center(
                          child: Text(
                            '${date.day}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: _isToday(date)
                                      ? Colors.white
                                      : Theme.of(context).textTheme.bodyMedium?.color,
                                  fontWeight: _isToday(date)
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}