import 'package:flutter/material.dart';

// Import the timer models from the timer screen
// Note: In a real app, these would be in separate model files
class TimerSession {
  final String name;
  final String description;
  final String technique;
  final IconData icon;
  final Color primaryColor;
  final List<SessionPhase> phases;

  const TimerSession({
    required this.name,
    required this.description,
    required this.technique,
    required this.icon,
    required this.primaryColor,
    required this.phases,
  });
}

class SessionPhase {
  final String name;
  final int minutes;
  final bool isBreak;
  final String instructions;
  final Color color;

  const SessionPhase({
    required this.name,
    required this.minutes,
    required this.isBreak,
    required this.instructions,
    required this.color,
  });
}

class SavedCustomTimer {
  final String id;
  final String label;
  final int studyMinutes;
  final int breakMinutes;
  final int iterations;
  final bool hasBreakTimer;
  final DateTime createdAt;

  const SavedCustomTimer({
    required this.id,
    required this.label,
    required this.studyMinutes,
    required this.breakMinutes,
    required this.iterations,
    required this.hasBreakTimer,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'studyMinutes': studyMinutes,
        'breakMinutes': breakMinutes,
        'iterations': iterations,
        'hasBreakTimer': hasBreakTimer,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedCustomTimer.fromJson(Map<String, dynamic> json) =>
      SavedCustomTimer(
        id: json['id'],
        label: json['label'],
        studyMinutes: json['studyMinutes'],
        breakMinutes: json['breakMinutes'],
        iterations: json['iterations'],
        hasBreakTimer: json['hasBreakTimer'],
        createdAt: DateTime.parse(json['createdAt']),
      );

  TimerSession toTimerSession() {
    final phases = <SessionPhase>[];

    // Generate phases for the custom timer
    for (int i = 0; i < iterations; i++) {
      // Add study phase
      phases.add(SessionPhase(
        name: 'Study Time',
        minutes: studyMinutes,
        isBreak: false,
        instructions: 'Focus on your task for the set duration.',
        color: const Color(0xFF6FB8E9),
      ));

      // Add break phase (except for the last iteration)
      if (hasBreakTimer && i < iterations - 1) {
        phases.add(SessionPhase(
          name: 'Break Time',
          minutes: breakMinutes,
          isBreak: true,
          instructions: 'Take a break and recharge.',
          color: const Color(0xFF4CAF50),
        ));
      }
    }

    return TimerSession(
      name: label,
      description: hasBreakTimer
          ? '$studyMinutes min study + $breakMinutes min break × $iterations'
          : '$studyMinutes min study × $iterations',
      technique: 'Custom Timer',
      icon: Icons.timer_outlined,
      primaryColor: const Color(0xFF6FB8E9),
      phases: phases,
    );
  }
}
