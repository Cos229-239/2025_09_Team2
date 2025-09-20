import 'package:flutter/foundation.dart';
import '../models/task.dart';

class PlannerProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<Task>> _events = {};

  List<Task> get tasks => _tasks;
  DateTime get selectedDay => _selectedDay;
  Map<DateTime, List<Task>> get events => _events;

  PlannerProvider() {
    _initializeDemoTasks();
  }

  void _initializeDemoTasks() {
    final now = DateTime.now();
    _tasks = [
      Task(
        id: '1',
        title: "Study Session",
        estMinutes: 60,
        dueAt: now,
        status: TaskStatus.pending,
      ),
      Task(
        id: '2',
        title: "Complete Assignment",
        estMinutes: 30,
        dueAt: now,
        status: TaskStatus.completed,
      ),
      Task(
        id: '3',
        title: "Plan sprint",
        estMinutes: 45,
        dueAt: now.add(const Duration(days: 1)),
        status: TaskStatus.pending,
      ),
    ];
    _groupEvents();
  }

  void _groupEvents() {
    _events = {};
    for (var task in _tasks) {
      if (task.dueAt != null) {
        final normalizedDay =
            DateTime.utc(task.dueAt!.year, task.dueAt!.month, task.dueAt!.day);
        _events.putIfAbsent(normalizedDay, () => []).add(task);
      }
    }
    notifyListeners();
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  void addTask(Task task) {
    _tasks.add(task);
    _groupEvents();
  }

  void updateTask(Task task) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      _groupEvents();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((task) => task.id == id);
    _groupEvents();
  }

  void updateTaskStatus(Task task, bool completed) {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task.copyWith(
        status: completed ? TaskStatus.completed : TaskStatus.pending,
      );
      _groupEvents();
    }
  }
}
