import 'package:flutter/material.dart';
import '../models/task.dart';

class PlannerProvider extends ChangeNotifier {
  DateTime _selectedDay = DateTime.now();
  final Map<DateTime, List<Task>> _events = {};

  DateTime get selectedDay => _selectedDay;
  Map<DateTime, List<Task>> get events => _events;

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void addTask(Task task) {
    final date = DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
    _events[date] = [...(_events[date] ?? []), task];
    notifyListeners();
  }

  void updateTask(Task task) {
    // Remove from old date
    _events.forEach((date, tasks) {
      _events[date] = tasks.where((t) => t.id != task.id).toList();
    });

    // Add to new date
    if (task.dueAt != null) {
      final date =
          DateTime(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
      _events[date] = [...(_events[date] ?? []), task];
    }

    notifyListeners();
  }

  void deleteTask(String taskId) {
    _events.forEach((date, tasks) {
      _events[date] = tasks.where((t) => t.id != taskId).toList();
    });
    notifyListeners();
  }

  void updateTaskStatus(Task task, bool isCompleted) {
    final updatedTask = task.copyWith(
      status: isCompleted ? TaskStatus.completed : TaskStatus.pending,
    );
    updateTask(updatedTask);
  }
}
