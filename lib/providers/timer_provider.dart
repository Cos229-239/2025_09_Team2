import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// Timer state enum
enum TimerState { idle, running, paused, breakTime, completed }

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

/// Provider to manage timer state across app navigation
/// This ensures the timer continues running even when user leaves the timer page
class TimerProvider extends ChangeNotifier {
  // Timer state
  Timer? _timer;
  int _remainingSeconds = 0;
  TimerState _timerState = TimerState.idle;
  
  // Session state
  TimerSession? _activeSession;
  int _currentPhaseIndex = 0;
  int _sessionCycle = 1;
  int _totalSessionsCompleted = 0;
  
  // Custom timer settings
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;
  bool _includeBreakTimer = false;
  int _breakMinutes = 5;
  
  // Callback for timer completion (to show dialogs)
  Function()? _onTimerComplete;
  Function()? _onSessionComplete;
  Function()? _onPhaseChange;

  // Getters
  int get remainingSeconds => _remainingSeconds;
  TimerState get timerState => _timerState;
  TimerSession? get activeSession => _activeSession;
  int get currentPhaseIndex => _currentPhaseIndex;
  int get sessionCycle => _sessionCycle;
  int get totalSessionsCompleted => _totalSessionsCompleted;
  int get selectedHours => _selectedHours;
  int get selectedMinutes => _selectedMinutes;
  int get selectedSeconds => _selectedSeconds;
  bool get includeBreakTimer => _includeBreakTimer;
  int get breakMinutes => _breakMinutes;
  
  bool get isTimerRunning => _timerState == TimerState.running || _timerState == TimerState.breakTime;
  bool get isTimerPaused => _timerState == TimerState.paused;
  bool get isTimerActive => _timerState != TimerState.idle && _timerState != TimerState.completed;

  // Get current phase if in a session
  SessionPhase? get currentPhase {
    if (_activeSession != null && _currentPhaseIndex < _activeSession!.phases.length) {
      return _activeSession!.phases[_currentPhaseIndex];
    }
    return null;
  }

  // Setters for timer configuration
  void setSelectedTime(int hours, int minutes, int seconds) {
    _selectedHours = hours;
    _selectedMinutes = minutes;
    _selectedSeconds = seconds;
    notifyListeners();
  }

  void setBreakTimer(bool enabled, int minutes) {
    _includeBreakTimer = enabled;
    _breakMinutes = minutes;
    notifyListeners();
  }

  // Register callbacks for UI events
  void setOnTimerComplete(Function()? callback) {
    _onTimerComplete = callback;
  }

  void setOnSessionComplete(Function()? callback) {
    _onSessionComplete = callback;
  }

  void setOnPhaseChange(Function()? callback) {
    _onPhaseChange = callback;
  }

  /// Start a custom timer with the configured time
  void startTimer() {
    final totalSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;

    if (totalSeconds == 0) {
      debugPrint('Timer: Cannot start timer with 0 seconds');
      return;
    }

    _remainingSeconds = totalSeconds;
    _timerState = TimerState.running;
    _startTimerTick();
    notifyListeners();
  }

  /// Start a session-based timer (e.g., Pomodoro)
  void startSession(TimerSession session) {
    _activeSession = session;
    _currentPhaseIndex = 0;
    _sessionCycle = 1;
    _remainingSeconds = session.phases[0].minutes * 60;
    _timerState = TimerState.running;
    _startTimerTick();
    notifyListeners();
  }

  /// Internal method to start the periodic timer tick
  void _startTimerTick() {
    _timer?.cancel(); // Cancel any existing timer
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
      } else {
        timer.cancel();
        _handleTimerComplete();
      }
    });
  }

  /// Pause the currently running timer
  void pauseTimer() {
    _timer?.cancel();
    _timerState = TimerState.paused;
    notifyListeners();
  }

  /// Resume a paused timer
  void resumeTimer() {
    if (_timerState != TimerState.paused) return;
    
    _timerState = TimerState.running;
    _startTimerTick();
    notifyListeners();
  }

  /// Stop and reset the timer
  void stopTimer() {
    _timer?.cancel();
    _timerState = TimerState.idle;
    _remainingSeconds = 0;
    _activeSession = null;
    _currentPhaseIndex = 0;
    _sessionCycle = 1;
    notifyListeners();
  }

  /// Handle timer completion (called when timer reaches 0)
  void _handleTimerComplete() {
    if (_activeSession != null) {
      _handleSessionPhaseComplete();
    } else {
      // Simple timer completed
      _timerState = TimerState.completed;
      _onTimerComplete?.call();
      notifyListeners();
      
      // Auto-reset after a moment
      Future.delayed(const Duration(seconds: 1), () {
        if (_timerState == TimerState.completed) {
          stopTimer();
        }
      });
    }
  }

  /// Handle completion of a session phase (e.g., Pomodoro focus phase)
  void _handleSessionPhaseComplete() {
    if (_activeSession == null) return;

    // Check if there's a next phase in the session
    if (_currentPhaseIndex + 1 < _activeSession!.phases.length) {
      // Move to next phase (e.g., from focus to break)
      _currentPhaseIndex++;
      _remainingSeconds = _activeSession!.phases[_currentPhaseIndex].minutes * 60;
      _timerState = TimerState.breakTime;
      _onPhaseChange?.call();
      
      // Auto-start the break phase
      _startTimerTick();
      notifyListeners();
    } else {
      // This was the last phase - session complete
      _handleSessionComplete();
    }
  }

  /// Handle complete session (all phases done)
  void _handleSessionComplete() {
    _totalSessionsCompleted++;
    _timerState = TimerState.completed;
    _onSessionComplete?.call();
    notifyListeners();
    
    // Don't auto-reset session - let user decide to start another
  }

  /// Format remaining time as HH:MM:SS
  String getFormattedTime() {
    final hours = _remainingSeconds ~/ 3600;
    final minutes = (_remainingSeconds % 3600) ~/ 60;
    final seconds = _remainingSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Get progress as a percentage (0.0 to 1.0)
  double getProgress() {
    if (_activeSession != null && currentPhase != null) {
      final totalSeconds = currentPhase!.minutes * 60;
      return 1.0 - (_remainingSeconds / totalSeconds);
    } else if (_selectedHours > 0 || _selectedMinutes > 0 || _selectedSeconds > 0) {
      final totalSeconds = (_selectedHours * 3600) + (_selectedMinutes * 60) + _selectedSeconds;
      return 1.0 - (_remainingSeconds / totalSeconds);
    }
    return 0.0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
