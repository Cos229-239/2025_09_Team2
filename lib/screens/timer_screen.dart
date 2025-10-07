import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'dart:async';

/// Study technique preset data model
class StudyPreset {
  final String name;
  final String description;
  final int minutes;
  final String technique;
  final IconData icon;
  final Color color;

  const StudyPreset({
    required this.name,
    required this.description,
    required this.minutes,
    required this.technique,
    required this.icon,
    required this.color,
  });
}

/// Timer session data model for automatic flow
class TimerSession {
  final String name;
  final String description;
  final List<SessionPhase> phases;
  final String technique;
  final IconData icon;
  final Color primaryColor;

  const TimerSession({
    required this.name,
    required this.description,
    required this.phases,
    required this.technique,
    required this.icon,
    required this.primaryColor,
  });
}

/// Individual phase within a timer session
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

/// Saved custom timer for quick selection
class SavedTimer {
  final String label;
  final int hours;
  final int minutes;
  final int seconds;
  final bool includeBreakTimer;
  final int breakMinutes;
  final int cycles;
  final DateTime savedAt;

  const SavedTimer({
    required this.label,
    required this.hours,
    required this.minutes,
    required this.seconds,
    required this.includeBreakTimer,
    required this.breakMinutes,
    required this.cycles,
    required this.savedAt,
  });

  int get totalSeconds => (hours * 3600) + (minutes * 60) + seconds;

  String get formattedTime {
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

/// Timer state enum
enum TimerState { idle, running, paused, breakTime, completed }

/// Apple-style timer screen with scroll wheels for hours, minutes, and seconds
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // Basic timer state
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _showPresets = true; // Toggle between sessions and custom timer
  SavedTimer? _selectedTimerDetails; // Track selected timer for detailed view

  // Advanced session state
  TimerState _timerState = TimerState.idle;
  TimerSession? _activeSession;
  int _currentPhaseIndex = 0;
  int _sessionCycle = 1;
  int _totalSessionsCompleted = 0;

  // Custom timer advanced options
  bool _includeBreakTimer = false;
  int _breakMinutes = 5;
  int _iterationCount = 1;
  final String _customTimerLabel = '';
  final bool _showCustomOptions = false;
  final TextEditingController _labelController = TextEditingController();

  // Saved custom timers for quick selection (includes converted study techniques)
  final List<SavedTimer> _savedTimers = [
    // Study Technique Presets converted to Saved Timers
    SavedTimer(
      label: 'Pomodoro Focus',
      hours: 0,
      minutes: 25,
      seconds: 0,
      includeBreakTimer: true,
      breakMinutes: 5,
      cycles: 1,
      savedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SavedTimer(
      label: 'Deep Work Session',
      hours: 1,
      minutes: 30,
      seconds: 0,
      includeBreakTimer: true,
      breakMinutes: 25,
      cycles: 1,
      savedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SavedTimer(
      label: 'Time-Box Focus',
      hours: 0,
      minutes: 45,
      seconds: 0,
      includeBreakTimer: false,
      breakMinutes: 5,
      cycles: 1,
      savedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    // User's custom saved timers appear after presets
    SavedTimer(
      label: 'Quick Study',
      hours: 0,
      minutes: 15,
      seconds: 0,
      includeBreakTimer: false,
      breakMinutes: 5,
      cycles: 1,
      savedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  // Timer session definitions with automatic phase transitions
  static const List<TimerSession> _timerSessions = [
    TimerSession(
      name: 'Pomodoro Cycle',
      description: 'Complete focus + break cycle',
      technique: 'Pomodoro Technique',
      icon: Icons.timer,
      primaryColor: Color(0xFFEF5350),
      phases: [
        SessionPhase(
          name: 'Focus Time',
          minutes: 25,
          isBreak: false,
          instructions: 'Focus deeply on your task. Eliminate distractions.',
          color: Color(0xFFEF5350),
        ),
        SessionPhase(
          name: 'Short Break',
          minutes: 5,
          isBreak: true,
          instructions: 'Take a break! Stretch, hydrate, and relax.',
          color: Color(0xFF4CAF50),
        ),
      ],
    ),
    TimerSession(
      name: 'Deep Work Cycle',
      description: '90-min focus + recharge break',
      technique: '90-Minute Focus Cycle',
      icon: Icons.psychology,
      primaryColor: Color(0xFF6FB8E9),
      phases: [
        SessionPhase(
          name: 'Deep Focus',
          minutes: 90,
          isBreak: false,
          instructions:
              'Enter deep work mode. No interruptions for 90 minutes.',
          color: Color(0xFF6FB8E9),
        ),
        SessionPhase(
          name: 'Recharge Break',
          minutes: 25,
          isBreak: true,
          instructions:
              'Take a longer break. Walk, rest, or do light activity.',
          color: Color(0xFF4CAF50),
        ),
      ],
    ),
    TimerSession(
      name: 'Time-Box Session',
      description: 'Fixed duration focused work',
      technique: 'Time-Boxing',
      icon: Icons.schedule,
      primaryColor: Color(0xFFFFA726),
      phases: [
        SessionPhase(
          name: 'Time-Box Work',
          minutes: 45,
          isBreak: false,
          instructions: 'Work within the time limit. Stop when time is up.',
          color: Color(0xFFFFA726),
        ),
      ],
    ),
  ];

  // Scroll controllers for the picker wheels
  final FixedExtentScrollController _hoursController =
      FixedExtentScrollController();
  final FixedExtentScrollController _minutesController =
      FixedExtentScrollController();
  final FixedExtentScrollController _secondsController =
      FixedExtentScrollController();

  @override
  void dispose() {
    // Only cancel timer if it's idle (user has stopped it)
    // This allows timer to continue running when navigating away
    if (_timerState == TimerState.idle) {
      _timer?.cancel();
    }
    
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _startTimer() {
    final totalSeconds =
        (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;

    if (totalSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set a time greater than 0')),
      );
      return;
    }

    setState(() {
      _timerState = TimerState.running;
      _remainingSeconds = totalSeconds;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _showTimerCompleteDialog();
        }
      });
    });
  }

  void _startSession(TimerSession session) {
    setState(() {
      _activeSession = session;
      _currentPhaseIndex = 0;
      _sessionCycle = 1;
      _remainingSeconds = session.phases[0].minutes * 60;
      _timerState = TimerState.running;
      _showPresets = false; // Switch to Active Timer tab
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          _sessionPhaseComplete();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.paused;
    });
  }

  void _resumeTimer() {
    setState(() {
      _timerState = TimerState.running;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          _stopTimer();
          _showTimerCompleteDialog();
        }
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _timerState = TimerState.idle;
      _remainingSeconds = 0;
      _activeSession = null;
      _currentPhaseIndex = 0;
      _sessionCycle = 1;
      // Stay in Custom Timer area when timer stops
    });
  }

  void _sessionPhaseComplete() {
    if (_activeSession == null) return;

    // Check if there's a next phase in the session
    if (_currentPhaseIndex + 1 < _activeSession!.phases.length) {
      // Move to next phase (e.g., from focus to break)
      setState(() {
        _currentPhaseIndex++;
        _remainingSeconds =
            _activeSession!.phases[_currentPhaseIndex].minutes * 60;
        _timerState = TimerState.breakTime;
      });

      // Auto-start the break phase
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
            _sessionComplete();
          }
        });
      });
    } else {
      // This was the last phase
      _sessionComplete();
    }
  }

  void _sessionComplete() {
    setState(() {
      _totalSessionsCompleted++;
      _timerState = TimerState.idle;
      _activeSession = null;
      _currentPhaseIndex = 0;
      _sessionCycle = 1;
      _remainingSeconds = 0;
    });

    // Show completion dialog
    _showSessionCompleteDialog();
  }

  void _showSessionCompleteDialog() {
    if (_activeSession == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242628), // Dashboard header color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
        ),
        title: Text(
          'Session Complete!',
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Great work! You\'ve completed your ${_activeSession!.name} session.',
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Color(0xFF6FB8E9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Start another session of the same type
              _startSession(_activeSession!);
            },
            child: const Text(
              'Start Another',
              style: TextStyle(
                color: Color(0xFF6FB8E9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTimerCompleteDialog() {
    // Determine if this was a session timer and show appropriate message
    String title = 'Timer Complete!';
    String content = 'Your timer has finished.';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242628), // Dashboard header color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF6FB8E9),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStudyTechniquesInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242628), // Dashboard header color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
        ),
        title: const Text(
          'Study Techniques Guide',
          style: TextStyle(
            color: Color(0xFFD9D9D9),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTechniqueInfo(
                'Pomodoro Technique',
                '25 minutes focused study + 5 minutes rest\nRepeat 4 times, then take 15-30 minute break',
                'Building focus, overcoming procrastination, maintaining energy',
                const Color(0xFFEF5350),
                Icons.timer,
              ),
              const SizedBox(height: 20),
              _buildTechniqueInfo(
                '90-Minute Focus Cycle',
                'One deep-focus block of ~90 minutes + 20-30 minute recharge break',
                'Reading, problem-solving, project work requiring immersion',
                const Color(0xFF6FB8E9),
                Icons.psychology,
              ),
              const SizedBox(height: 20),
              _buildTechniqueInfo(
                'Time-Boxing',
                'Assign exact start-and-end times for tasks\nStop when time ends to prevent perfectionism',
                'Structured task completion, preventing overwork',
                const Color(0xFFFFA726),
                Icons.schedule,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Got it!',
              style: TextStyle(color: Color(0xFF6FB8E9)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTechniqueInfo(String title, String structure, String bestFor,
      Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Structure: $structure',
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Best for: $bestFor',
            style: TextStyle(
              color: const Color(0xFFD9D9D9).withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16181A), // Dashboard background color
      appBar: AppBar(
        backgroundColor: const Color(0xFF16181A), // Dashboard background color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios,
              color: Color(0xFF6FB8E9)), // Dashboard primary accent
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Timer',
          style: TextStyle(
            color: Color(0xFFD9D9D9), // Dashboard text color
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showStudyTechniquesInfo,
            icon: const Icon(
              Icons.info_outline,
              color: Color(0xFF6FB8E9),
            ),
            tooltip: 'Study Techniques Info',
          ),
        ],
      ),
      body: Column(
        children: [
          // Timer display or picker wheels - use flexible instead of expanded for better space utilization
          Flexible(
            flex: _timerState != TimerState.idle ? 3 : 1,
            child: _timerState != TimerState.idle
                ? _buildTimerDisplay()
                : _buildTimerPicker(),
          ),

          // Control buttons - only show when timer is running
          if (_timerState != TimerState.idle)
            Flexible(
              flex: 1,
              child: _buildControlButtons(),
            ),
        ],
      ),
    );
  }

  Widget _buildTimerDisplay() {
    if (_activeSession != null) {
      return _buildSessionDisplay();
    } else {
      return _buildBasicTimerDisplay();
    }
  }

  Widget _buildSessionDisplay() {
    if (_activeSession == null) return Container();

    final currentPhase = _activeSession!.phases[_currentPhaseIndex];
    final nextPhase = _currentPhaseIndex + 1 < _activeSession!.phases.length
        ? _activeSession!.phases[_currentPhaseIndex + 1]
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Session name and progress
          Text(
            _activeSession!.name,
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Phase ${_currentPhaseIndex + 1} of ${_activeSession!.phases.length}',
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 30),

          // Current and next phase display
          Row(
            children: [
              // Current phase
              Expanded(
                flex: 2,
                child: _buildPhaseCard(
                  title: 'Current: ${currentPhase.name}',
                  time: _formatTime(_remainingSeconds),
                  color: currentPhase.color,
                  isActive: true,
                  instructions: currentPhase.instructions,
                ),
              ),

              if (nextPhase != null) ...[
                const SizedBox(width: 16),
                // Next phase (queued)
                Expanded(
                  flex: 1,
                  child: _buildPhaseCard(
                    title: 'Next: ${nextPhase.name}',
                    time: _formatTime(nextPhase.minutes * 60),
                    color: nextPhase.color,
                    isActive: false,
                    instructions: nextPhase.instructions,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 20),

          // Status text with phase-specific styling
          Text(
            _getSessionStatusText(),
            style: TextStyle(
              color: _getSessionStatusColor(),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseCard({
    required String title,
    required String time,
    required Color color,
    required bool isActive,
    required String instructions,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242628), // Dashboard header color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : color.withValues(alpha: 0.3),
          width: isActive ? 3 : 1,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase title
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: isActive ? 16 : 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Time display
          Text(
            time,
            style: TextStyle(
              color: const Color(0xFFD9D9D9),
              fontSize: isActive ? 32 : 20,
              fontWeight: FontWeight.w300,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),

          if (isActive) ...[
            const SizedBox(height: 8),
            // Instructions for active phase
            Text(
              instructions,
              style: const TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicTimerDisplay() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Large timer display
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF6FB8E9), // Dashboard primary accent
                width: 8,
              ),
            ),
            child: Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: Color(0xFFD9D9D9), // Dashboard text color
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Status text
          Text(
            _timerState == TimerState.paused
                ? 'Paused'
                : _timerState == TimerState.breakTime
                    ? 'Break Time'
                    : 'Timer Running',
            style: TextStyle(
              color: _timerState == TimerState.paused
                  ? const Color(0xFF6FB8E9)
                  : _timerState == TimerState.breakTime
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFD9D9D9), // Dashboard colors
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _getSessionStatusText() {
    switch (_timerState) {
      case TimerState.paused:
        return 'Session Paused';
      case TimerState.breakTime:
        return 'Break Time - Relax and Recharge';
      case TimerState.running:
        return _activeSession!.phases[_currentPhaseIndex].isBreak
            ? 'Break Time Active'
            : 'Focus Session Active';
      default:
        return 'Session Ready';
    }
  }

  Color _getSessionStatusColor() {
    switch (_timerState) {
      case TimerState.paused:
        return const Color(0xFF6FB8E9);
      case TimerState.breakTime:
        return const Color(0xFF4CAF50);
      case TimerState.running:
        return _activeSession!.phases[_currentPhaseIndex].isBreak
            ? const Color(0xFF4CAF50)
            : const Color(0xFFEF5350);
      default:
        return const Color(0xFFD9D9D9);
    }
  }

  Widget _buildTimerPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.start, // Changed from center to start
        children: [
          // Toggle between presets and active/custom timer
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF242628), // Dashboard header color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF6FB8E9),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPresets = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _showPresets
                            ? const Color(0xFF6FB8E9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Saved Timers',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _showPresets
                              ? const Color(0xFF16181A)
                              : const Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showPresets = false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !_showPresets
                            ? const Color(0xFF6FB8E9)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _timerState != TimerState.idle ? 'Current Timer' : 'Custom Timer',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: !_showPresets
                              ? const Color(0xFF16181A)
                              : const Color(0xFFD9D9D9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Add spacing whether timer is active or not
          const SizedBox(height: 30),

          // Show presets or custom/current timer based on toggle and timer state
          Expanded(
            child: _showPresets 
              ? _buildStudyPresets() 
              : (_timerState != TimerState.idle 
                  ? _buildActiveTimer() 
                  : _buildCustomTimer()),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPresets() {
    return Column(
      children: [
        // Section header
        const Text(
          'Saved Timer Presets',
          style: TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),

        // Show timer details if one is selected, otherwise show timer grid
        if (_selectedTimerDetails != null) ...[
          Expanded(
            child: SingleChildScrollView(
              child: _buildTimerDetailsView(_selectedTimerDetails!),
            ),
          ),
        ] else ...[
          // Saved timer options displayed as wrapped cards
          if (_savedTimers.isNotEmpty) ...[
            Wrap(
              spacing: 16, // Horizontal spacing between cards
              runSpacing: 16, // Vertical spacing between rows
              children: _savedTimers.asMap().entries.map((entry) {
                final index = entry.key;
                final timer = entry.value;
                return _buildSavedTimerPresetCard(timer, index);
              }).toList(),
            ),
          ] else ...[
            const Text(
              'No saved timers yet. Create some in the Custom Timer section!',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 30),
        ],
      ],
    );
  }

  // Get study technique description for preset timers
  String _getStudyTechniqueDescription(String timerLabel) {
    switch (timerLabel) {
      case 'Pomodoro Focus':
        return 'The Pomodoro Technique involves working in focused 25-minute intervals followed by 5-minute breaks. This method helps maintain concentration, prevents burnout, and makes large tasks more manageable by breaking them into smaller, timed segments.';
      case 'Deep Work Session':
        return 'Deep Work sessions are extended periods (90+ minutes) of focused, cognitively demanding work without distractions. This technique is ideal for complex tasks requiring sustained attention and produces high-quality output in less time.';
      case 'Time-Box Focus':
        return 'Time-boxing allocates specific time periods to tasks, creating urgency and preventing perfectionism. This 45-minute focused session helps you work efficiently within constraints and maintain momentum without breaks.';
      default:
        return 'This is a custom timer you created. Adjust the study duration and break intervals to match your personal learning preferences and attention span.';
    }
  }

  Widget _buildTimerDetailsView(SavedTimer timer) {
    final bool isPresetTimer = ['Pomodoro Focus', 'Deep Work Session', 'Time-Box Focus'].contains(timer.label);
    
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF242628),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6FB8E9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with timer name and close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  timer.label,
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedTimerDetails = null;
                  });
                },
                icon: const Icon(
                  Icons.close,
                  color: Color(0xFF6FB8E9),
                  size: 24,
                ),
              ),
            ],
          ),
          
          if (isPresetTimer) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6FB8E9), width: 1),
              ),
              child: const Text(
                'Study Technique',
                style: TextStyle(
                  color: Color(0xFF6FB8E9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          
          const SizedBox(height: 20),
          
          // Timer specifications
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Study Time',
                  timer.formattedTime,
                  Icons.schedule,
                ),
              ),
              if (timer.includeBreakTimer)
                Expanded(
                  child: _buildDetailItem(
                    'Break Time',
                    '${timer.breakMinutes} min',
                    Icons.coffee,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'Cycles',
                  '${timer.cycles}',
                  Icons.repeat,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Total Time',
                  timer.includeBreakTimer 
                    ? _formatTotalTime(timer.totalSeconds + (timer.breakMinutes * 60 * timer.cycles))
                    : timer.formattedTime,
                  Icons.timer,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            isPresetTimer ? 'Study Technique Description:' : 'Description:',
            style: const TextStyle(
              color: Color(0xFF6FB8E9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _getStudyTechniqueDescription(timer.label),
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Start the timer directly
                    setState(() {
                      _selectedHours = timer.hours;
                      _selectedMinutes = timer.minutes;
                      _selectedSeconds = timer.seconds;
                      _includeBreakTimer = timer.includeBreakTimer;
                      _breakMinutes = timer.breakMinutes;
                      _iterationCount = timer.cycles;
                      _labelController.text = timer.label;
                      _selectedTimerDetails = null;
                    });
                    _startCustomTimer();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FB8E9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Timer',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // Load timer settings and switch to custom timer view
                    setState(() {
                      _selectedHours = timer.hours;
                      _selectedMinutes = timer.minutes;
                      _selectedSeconds = timer.seconds;
                      _includeBreakTimer = timer.includeBreakTimer;
                      _breakMinutes = timer.breakMinutes;
                      _iterationCount = timer.cycles;
                      _labelController.text = timer.label;
                      _selectedTimerDetails = null;
                      _showPresets = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6FB8E9),
                    side: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Customize',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6FB8E9),
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0B0B0),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTotalTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildActiveTimer() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Timer title and status
          Text(
            _activeSession?.name ?? 'Custom Timer',
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_activeSession != null) ...[
            const SizedBox(height: 8),
            Text(
              _activeSession!.phases[_currentPhaseIndex].name,
              style: TextStyle(
                color: _activeSession!.phases[_currentPhaseIndex].color,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          const SizedBox(height: 40),
          
          // Large timer display
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF242628),
              border: Border.all(
                color: const Color(0xFF6FB8E9),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _formatTime(_remainingSeconds),
                    style: const TextStyle(
                      color: Color(0xFFD9D9D9),
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _timerState == TimerState.paused ? 'PAUSED' : 'RUNNING',
                    style: TextStyle(
                      color: _timerState == TimerState.paused 
                        ? const Color(0xFFFF9800) 
                        : const Color(0xFF4CAF50),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Control buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Pause/Resume button
              ElevatedButton(
                onPressed: _timerState == TimerState.paused 
                  ? _resumeTimer 
                  : _pauseTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6FB8E9),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _timerState == TimerState.paused 
                        ? Icons.play_arrow 
                        : Icons.pause,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timerState == TimerState.paused ? 'Resume' : 'Pause',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Stop button
              OutlinedButton(
                onPressed: () {
                  _stopTimer();
                  setState(() {
                    _timerState = TimerState.idle;
                    _activeSession = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFEF5350),
                  side: const BorderSide(color: Color(0xFFEF5350), width: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.stop, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Stop',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          // Session progress (if applicable)
          if (_activeSession != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF242628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Session Progress',
                    style: const TextStyle(
                      color: Color(0xFF6FB8E9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'Phase',
                            style: const TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${_currentPhaseIndex + 1}/${_activeSession!.phases.length}',
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                      ),
                      Column(
                        children: [
                          Text(
                            'Instructions',
                            style: const TextStyle(
                              color: Color(0xFFB0B0B0),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _activeSession!.phases[_currentPhaseIndex].instructions,
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSavedTimerPresetCard(SavedTimer timer, int index) {
    return Container(
      width: 160,
      height: 130, // Fixed height for consistent card sizing
      decoration: BoxDecoration(
        color: const Color(0xFF242628), // Dashboard header color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF6FB8E9), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Show detailed view of the timer
            setState(() {
              _selectedTimerDetails = timer;
            });
          },
          onLongPress: () {
            // Remove timer from saved list
            setState(() {
              _savedTimers.removeAt(index);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted timer "${timer.label}"'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'UNDO',
                  onPressed: () {
                    setState(() {
                      _savedTimers.insert(index, timer);
                    });
                  },
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(10), // Reduced from 12
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Timer icon and name
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 36, // Reduced from 40
                        height: 36, // Reduced from 40
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer,
                          color: Color(0xFF6FB8E9),
                          size: 20, // Reduced from 24
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced from 8
                      Text(
                        timer.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontSize: 12, // Reduced from 14
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Timer details
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        timer.formattedTime,
                        style: const TextStyle(
                          color: Color(0xFF6FB8E9),
                          fontSize: 14, // Reduced from 16
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (timer.includeBreakTimer)
                        Text(
                          '+ ${timer.breakMinutes}min break',
                          style: const TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalSessionCard(TimerSession session) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF242628), // Dashboard header color
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: session.primaryColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: session.primaryColor.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _startSession(session),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: session.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  session.icon,
                  color: session.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),

              // Name
              Text(
                session.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Duration info
              Text(
                session.phases.map((p) => '${p.minutes}m').join(' + '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: session.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),

              // Technique type
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: session.primaryColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.technique.split(' ').first, // Just first word
                  style: TextStyle(
                    color: session.primaryColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomTimer() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // All-in-One Timer Container
          _buildUnifiedTimerContainer(),

          const SizedBox(height: 12), // Reduced from 20

          // Start Timer Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startCustomTimer,
              icon: const Icon(Icons.play_arrow, size: 20),
              label: const Text(
                'Start Timer',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FB8E9),
                foregroundColor: const Color(0xFF16181A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),

          // Extended bottom padding for scrollable container
          const SizedBox(height: 44), // Extended by 40px (4 + 40 = 44)
        ],
      ),
    );
  }

  Widget _buildUnifiedTimerContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF242628), // Dashboard header color
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF6FB8E9),
          width: 2,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            const Center(
              child: Text(
                'Custom Timer Setup',
                style: TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 18, // Reduced from 20
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 16), // Reduced from 20

            // Main Timer Pickers
            const Text(
              'Timer Duration:',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 15, // Reduced from 16
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10), // Reduced from 12

            Container(
              height: 100, // Reduced from 120
              decoration: BoxDecoration(
                color: const Color(0xFF16181A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  // Hours
                  _buildCompactPickerWheel(
                    controller: _hoursController,
                    itemCount: 25,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedHours = index;
                      });
                    },
                    suffix: _selectedHours == 1 ? ' hour' : ' hours',
                  ),

                  // Minutes
                  _buildCompactPickerWheel(
                    controller: _minutesController,
                    itemCount: 60,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedMinutes = index;
                      });
                    },
                    suffix: _selectedMinutes == 1 ? ' min' : ' min',
                  ),

                  // Seconds
                  _buildCompactPickerWheel(
                    controller: _secondsController,
                    itemCount: 60,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        _selectedSeconds = index;
                      });
                    },
                    suffix: _selectedSeconds == 1 ? ' sec' : ' sec',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10), // Reduced from 12

            // Selected time display
            Center(
              child: Text(
                _formatSelectedTime(),
                style: const TextStyle(
                  color: Color(0xFFD9D9D9),
                  fontSize: 16, // Reduced from 18
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),

            const SizedBox(height: 16), // Reduced from 20

            // Timer Label
            const Text(
              'Timer Label (optional):',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 15, // Reduced from 16
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6), // Reduced from 8
            TextField(
              controller: _labelController,
              style: const TextStyle(color: Color(0xFFD9D9D9)),
              decoration: InputDecoration(
                hintText: 'e.g., "Study Session", "Deep Focus"',
                hintStyle: const TextStyle(color: Color(0xFF6B6B6B)),
                filled: true,
                fillColor: const Color(0xFF16181A),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8), // Reduced vertical padding
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF6FB8E9)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide:
                      const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16), // Reduced from 20

            // Break timer option
            Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: Checkbox(
                    value: _includeBreakTimer,
                    onChanged: (value) =>
                        setState(() => _includeBreakTimer = value ?? false),
                    activeColor: const Color(0xFF6FB8E9),
                    checkColor: const Color(0xFF16181A),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Include break timer with cycles',
                    style: TextStyle(
                      color: Color(0xFFD9D9D9),
                      fontSize: 15, // Reduced from 16
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),

            if (_includeBreakTimer) ...[
              const SizedBox(
                  height: 20), // Increased spacing when break timer is enabled

              // Break Duration and Cycles in a Row
              Row(
                children: [
                  // Break Duration
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Break duration:',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15, // Slightly larger text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10), // More spacing
                        Container(
                          height: 90, // Increased height for better visibility
                          decoration: BoxDecoration(
                            color: const Color(0xFF16181A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6FB8E9),
                              width: 1,
                            ),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 28, // Larger items for better usability
                            scrollController: FixedExtentScrollController(
                                initialItem: _breakMinutes - 1),
                            onSelectedItemChanged: (index) {
                              // Add haptic feedback on every scroll tick
                              HapticFeedback.selectionClick();
                              setState(() => _breakMinutes = index + 1);
                            },
                            children: List.generate(30, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1} min',
                                  style: const TextStyle(
                                    color: Color(0xFFD9D9D9),
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Number of Cycles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Number of cycles:',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 15, // Slightly larger text
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 10), // More spacing
                        Container(
                          height: 90, // Increased height for better visibility
                          decoration: BoxDecoration(
                            color: const Color(0xFF16181A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF6FB8E9),
                              width: 1,
                            ),
                          ),
                          child: CupertinoPicker(
                            itemExtent: 28, // Larger items for better usability
                            scrollController: FixedExtentScrollController(
                                initialItem: _iterationCount - 1),
                            onSelectedItemChanged: (index) {
                              // Add haptic feedback on every scroll tick
                              HapticFeedback.selectionClick();
                              setState(() => _iterationCount = index + 1);
                            },
                            children: List.generate(10, (index) {
                              return Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFFD9D9D9),
                                    fontSize: 13, // Larger text
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveCustomTimer,
                icon: const Icon(Icons.save, size: 16),
                label: const Text('Save Timer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Compact version of picker wheel for the unified container
  Widget _buildCompactPickerWheel({
    required FixedExtentScrollController controller,
    required int itemCount,
    required ValueChanged<int> onSelectedItemChanged,
    required String suffix,
  }) {
    return Expanded(
      child: CupertinoPicker(
        scrollController: controller,
        itemExtent: 25, // Reduced from 30
        onSelectedItemChanged: (index) {
          // Add haptic feedback on every scroll tick
          HapticFeedback.selectionClick();
          onSelectedItemChanged(index);
        },
        children: List.generate(itemCount, (index) {
          return Center(
            child: Text(
              '$index$suffix',
              style: const TextStyle(
                color: Color(0xFFD9D9D9),
                fontSize: 13, // Reduced from 14
                fontWeight: FontWeight.w400,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _saveCustomTimer() {
    if (_selectedHours == 0 && _selectedMinutes == 0 && _selectedSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a timer duration before saving'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final label = _labelController.text.trim();
    final newTimer = SavedTimer(
      label: label.isEmpty ? 'Custom Timer ${_savedTimers.length + 1}' : label,
      hours: _selectedHours,
      minutes: _selectedMinutes,
      seconds: _selectedSeconds,
      includeBreakTimer: _includeBreakTimer,
      breakMinutes: _breakMinutes,
      cycles: _iterationCount,
      savedAt: DateTime.now(),
    );

    setState(() {
      _savedTimers.add(newTimer);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Timer "${newTimer.label}" saved!'),
        backgroundColor: const Color(0xFF6FB8E9),
      ),
    );

    // Clear the label after saving
    _labelController.clear();
  }

  void _startCustomTimer() {
    final totalSeconds =
        (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;
    if (totalSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set a time greater than 0'),
          backgroundColor: Color(0xFFEF5350),
        ),
      );
      return;
    }

    if (_includeBreakTimer) {
      // Create a custom session with study and break phases
      final customSession = TimerSession(
        name: _labelController.text.trim().isEmpty
            ? 'Custom Session'
            : _labelController.text.trim(),
        description:
            'Custom ${_formatSelectedTime()} + ${_breakMinutes}min break × $_iterationCount',
        technique: 'Custom Timer',
        icon: Icons.timer_outlined,
        primaryColor: const Color(0xFF6FB8E9),
        phases: List.generate(_iterationCount * 2 - 1, (index) {
          if (index % 2 == 0) {
            // Study phase
            return SessionPhase(
              name: 'Study Time',
              minutes: totalSeconds ~/ 60,
              isBreak: false,
              instructions: 'Focus on your task for the set duration.',
              color: const Color(0xFF6FB8E9),
            );
          } else {
            // Break phase (except for the last iteration)
            return SessionPhase(
              name: 'Break Time',
              minutes: _breakMinutes,
              isBreak: true,
              instructions: 'Take a break and recharge.',
              color: const Color(0xFF4CAF50),
            );
          }
        }),
      );
      _startSession(customSession);
    } else {
      // Start simple timer
      setState(() {
        _remainingSeconds = totalSeconds;
        _timerState = TimerState.running;
        _showPresets = false; // Switch to Active Timer tab
      });
      _startTimer();
    }
  }

  Widget _buildControlButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_timerState != TimerState.idle) ...[
            // Pause/Resume button
            _buildControlButton(
              onPressed:
                  _timerState == TimerState.paused ? _resumeTimer : _pauseTimer,
              color: const Color(0xFF6FB8E9), // Dashboard primary accent
              child: Text(
                _timerState == TimerState.paused ? 'Resume' : 'Pause',
                style: const TextStyle(
                  color: Color(0xFFD9D9D9), // Dashboard text color
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Stop button
            _buildControlButton(
              onPressed: _stopTimer,
              color: const Color(0xFFEF5350), // Dashboard error color
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFD9D9D9), // Dashboard text color
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          // Green start button removed - users should use the blue "Start Timer" button in custom timer section
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: 120,
      height: 50,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(25),
          child: Center(child: child),
        ),
      ),
    );
  }

  String _formatSelectedTime() {
    if (_selectedHours == 0 && _selectedMinutes == 0 && _selectedSeconds == 0) {
      return 'Set a timer';
    }

    final totalSeconds =
        (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;
    return _formatTime(totalSeconds);
  }
}
