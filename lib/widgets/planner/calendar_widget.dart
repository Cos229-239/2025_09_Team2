import 'package:flutter/material.dart';
import '../../models/planner/task.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarWidget extends StatefulWidget {
  final Map<DateTime, List<Task>> events;
  final Function(DateTime) onDaySelected;

  const CalendarWidget({
    required this.events,
    required this.onDaySelected,
    super.key,
  });

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  List<Task> _getEventsForDay(DateTime day) {
    DateTime normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return widget.events[normalizedDay] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return TableCalendar<Task>(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      eventLoader: _getEventsForDay,
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        widget.onDaySelected(selectedDay);
      },
      calendarStyle: const CalendarStyle(
        markersMaxCount: 3,
        markerDecoration: BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}