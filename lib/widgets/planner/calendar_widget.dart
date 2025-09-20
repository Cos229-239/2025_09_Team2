import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/task.dart';

class CalendarWidget extends StatelessWidget {
  final Map<DateTime, List<Task>> events;
  final Function(DateTime) onDaySelected;

  const CalendarWidget({
    super.key,
    required this.events,
    required this.onDaySelected,
  });

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Task>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: DateTime.now(),
      calendarFormat: CalendarFormat.month,
      eventLoader: (day) {
        final date = DateTime(day.year, day.month, day.day);
        return events[date] ?? [];
      },
      onDaySelected: (selectedDay, focusedDay) {
        onDaySelected(selectedDay);
      },
      calendarStyle: const CalendarStyle(
        outsideDaysVisible: false,
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
