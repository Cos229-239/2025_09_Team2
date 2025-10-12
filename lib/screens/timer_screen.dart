import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/timer_provider.dart';
import '../services/firestore_service.dart';

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

/// Saved custom timer for quick selection
class SavedTimer {
  final String? id; // Firestore document ID
  final String label;
  final int hours;
  final int minutes;
  final int seconds;
  final bool includeBreakTimer;
  final int breakMinutes;
  final int cycles;
  final DateTime savedAt;

  const SavedTimer({
    this.id,
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

  /// Create SavedTimer from Firestore document
  factory SavedTimer.fromFirestore(Map<String, dynamic> data) {
    return SavedTimer(
      id: data['id'] as String?,
      label: data['label'] as String,
      hours: data['hours'] as int,
      minutes: data['minutes'] as int,
      seconds: data['seconds'] as int,
      includeBreakTimer: data['includeBreakTimer'] as bool,
      breakMinutes: data['breakMinutes'] as int,
      cycles: data['cycles'] as int,
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'hours': hours,
      'minutes': minutes,
      'seconds': seconds,
      'includeBreakTimer': includeBreakTimer,
      'breakMinutes': breakMinutes,
      'cycles': cycles,
    };
  }
}

/// Apple-style timer screen with scroll wheels for hours, minutes, and seconds
class TimerScreen extends StatefulWidget {
  const TimerScreen({super.key});

  @override
  State<TimerScreen> createState() => _TimerScreenState();
}

class _TimerScreenState extends State<TimerScreen> {
  // UI state only (timer state is now in provider)
  bool _showPresets = true; // Toggle between sessions and custom timer
  SavedTimer? _selectedTimerDetails; // Track selected timer for detailed view
  bool _timerStartedFromSavedTimers =
      false; // Track if timer was started from saved timers list
  String? _editingTimerId; // Track if we're editing an existing timer

  // Custom timer picker state
  int _selectedHours = 0;
  int _selectedMinutes = 0;
  int _selectedSeconds = 0;

  // Custom timer advanced options
  bool _includeBreakTimer = false;
  int _breakMinutes = 5;
  int _iterationCount = 1;
  final TextEditingController _labelController = TextEditingController();

  // Saved custom timers for quick selection (includes converted study techniques)
  List<SavedTimer> _savedTimers = [
    // Study Technique Presets converted to Saved Timers (these won't be saved to Firebase)
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
          seconds: 25 * 60,
          isBreak: false,
          instructions: 'Focus deeply on your task. Eliminate distractions.',
          color: Color(0xFFEF5350),
        ),
        SessionPhase(
          name: 'Short Break',
          seconds: 5 * 60,
          isBreak: true,
          instructions: 'Take a break! Stretch, hydrate, and relax.',
          color: Color(0xFF4CAF50),
        ),
        SessionPhase(
          name: 'Focus Time',
          seconds: 25 * 60,
          isBreak: false,
          instructions: 'Focus deeply on your task. Eliminate distractions.',
          color: Color(0xFFEF5350),
        ),
        SessionPhase(
          name: 'Short Break',
          seconds: 5 * 60,
          isBreak: true,
          instructions: 'Take a break! Stretch, hydrate, and relax.',
          color: Color(0xFF4CAF50),
        ),
        SessionPhase(
          name: 'Focus Time',
          seconds: 25 * 60,
          isBreak: false,
          instructions: 'Focus deeply on your task. Eliminate distractions.',
          color: Color(0xFFEF5350),
        ),
        SessionPhase(
          name: 'Short Break',
          seconds: 5 * 60,
          isBreak: true,
          instructions: 'Take a break! Stretch, hydrate, and relax.',
          color: Color(0xFF4CAF50),
        ),
        SessionPhase(
          name: 'Focus Time',
          seconds: 25 * 60,
          isBreak: false,
          instructions: 'Focus deeply on your task. Eliminate distractions.',
          color: Color(0xFFEF5350),
        ),
        SessionPhase(
          name: 'Short Break',
          seconds: 5 * 60,
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
          seconds: 90 * 60,
          isBreak: false,
          instructions:
              'Enter deep work mode. No interruptions for 90 minutes.',
          color: Color(0xFF6FB8E9),
        ),
        SessionPhase(
          name: 'Recharge Break',
          seconds: 30 * 60,
          isBreak: true,
          instructions:
              'Take a longer break. Walk, rest, or do light activity.',
          color: Color(0xFF4CAF50),
        ),
        SessionPhase(
          name: 'Deep Focus',
          seconds: 90 * 60,
          isBreak: false,
          instructions:
              'Enter deep work mode. No interruptions for 90 minutes.',
          color: Color(0xFF6FB8E9),
        ),
        SessionPhase(
          name: 'Recharge Break',
          seconds: 30 * 60,
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
          seconds: 45 * 60,
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
  void initState() {
    super.initState();
    // Register callbacks for timer completion events
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.setOnTimerComplete(() {
      if (mounted) {
        _showTimerCompleteDialog();
      }
    });
    timerProvider.setOnSessionComplete(() {
      if (mounted) {
        _showSessionCompleteDialog();
      }
    });

    // Load saved timers from Firebase
    _loadSavedTimers();
  }

  bool _hasLoadedTimers = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check if timer is running and switch to active timer view
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    if (timerProvider.timerState != TimerState.idle) {
      // Timer is running, switch to active timer view
      if (_showPresets) {
        setState(() {
          _showPresets = false;
        });
      }
    }

    // Reload timers every time the screen becomes active
    // This ensures timers are refreshed when navigating back from another screen
    if (!_hasLoadedTimers || ModalRoute.of(context)?.isCurrent == true) {
      _loadSavedTimers();
      _hasLoadedTimers = true;
    }
  }

  /// Load saved timers from Firestore
  Future<void> _loadSavedTimers() async {
    try {
      final firestoreService = FirestoreService();
      final timersData = await firestoreService.getSavedTimers();

      if (mounted) {
        setState(() {
          // Keep the preset timers (Pomodoro, Deep Work, Time-Box, Quick Study) and add user's saved timers
          final presetTimers = _savedTimers
              .where((timer) =>
                  timer.label == 'Pomodoro Focus' ||
                  timer.label == 'Deep Work Session' ||
                  timer.label == 'Time-Box Focus' ||
                  timer.label == 'Quick Study')
              .toList();

          final userTimers =
              timersData.map((data) => SavedTimer.fromFirestore(data)).toList();

          _savedTimers = [...presetTimers, ...userTimers];
        });

        debugPrint('✅ Loaded ${timersData.length} user timers from Firebase');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved timers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load saved timers: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  void _resetCustomTimerSettings() {
    setState(() {
      _selectedHours = 0;
      _selectedMinutes = 0;
      _selectedSeconds = 0;
      _includeBreakTimer = false;
      _breakMinutes = 5;
      _iterationCount = 1;
      _labelController.clear();
      _editingTimerId = null; // Clear editing state
    });

    // Reset scroll controllers to initial positions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_hoursController.hasClients) {
        _hoursController.jumpToItem(0);
      }
      if (_minutesController.hasClients) {
        _minutesController.jumpToItem(0);
      }
      if (_secondsController.hasClients) {
        _secondsController.jumpToItem(0);
      }
    });
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

    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.setSelectedTime(
        _selectedHours, _selectedMinutes, _selectedSeconds);

    // Get the timer name from label controller or use default
    final timerName = _labelController.text.trim().isEmpty
        ? 'Custom Timer'
        : _labelController.text.trim();

    timerProvider.startTimer(name: timerName);

    // Reset custom timer settings and switch to active timer view
    _resetCustomTimerSettings();
    setState(() {
      _showPresets = false;
    });
  }

  void _startSession(TimerSession session) {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.startSession(session);

    setState(() {
      _showPresets = false; // Switch to Active Timer tab
    });
  }

  void _pauseTimer() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.pauseTimer();
  }

  void _resumeTimer() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    timerProvider.resumeTimer();
  }

  void _stopTimer() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final wasSession = timerProvider.activeSession != null;
    final wasFromSavedTimers = _timerStartedFromSavedTimers;
    timerProvider.stopTimer();

    // Reset the flag
    _timerStartedFromSavedTimers = false;

    // If it was a session timer OR started from saved timers, go back to Saved Timers tab
    // Otherwise stay in Custom Timer area
    setState(() {
      _showPresets = (wasSession || wasFromSavedTimers) ? true : false;
    });
  }

  void _showSessionCompleteDialog() {
    final timerProvider = Provider.of<TimerProvider>(context, listen: false);
    final activeSession = timerProvider.activeSession;

    if (activeSession == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF242628), // Dashboard header color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF6FB8E9), width: 2),
        ),
        title: const Text(
          'Session Complete!',
          style: TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Great work! You\'ve completed your ${activeSession.name} session.',
          style: const TextStyle(
            color: Color(0xFFD9D9D9),
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Reset the flag and return to Saved Timers tab after completing a session
              _timerStartedFromSavedTimers = false;
              setState(() {
                _showPresets = true;
              });
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
              // Keep the saved timer flag if it was originally from saved timers
              final wasFromSavedTimers = _timerStartedFromSavedTimers;
              // Start another session of the same type
              _startSession(activeSession);
              // Restore the flag so completion returns to saved timers
              _timerStartedFromSavedTimers = wasFromSavedTimers;
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
              // Reset the flag and return to Saved Timers tab after completing a timer
              _timerStartedFromSavedTimers = false;
              setState(() {
                _showPresets = true;
              });
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
      body: _buildTimerPicker(), // Always show the main content with tabs
    );
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
                      child: Consumer<TimerProvider>(
                        builder: (context, timerProvider, child) {
                          return Text(
                            timerProvider.timerState != TimerState.idle
                                ? 'Current Timer'
                                : 'Custom Timer',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: !_showPresets
                                  ? const Color(0xFF16181A)
                                  : const Color(0xFFD9D9D9),
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
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
            child: Consumer<TimerProvider>(
              builder: (context, timerProvider, child) {
                return _showPresets
                    ? _buildStudyPresets()
                    : (timerProvider.timerState != TimerState.idle
                        ? _buildActiveTimer()
                        : _buildCustomTimer());
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyPresets() {
    return Stack(
      children: [
        // Main content - always visible
        Column(
          children: [
            // Section header
            const Text(
              'Study Techniques',
              style: TextStyle(
                color: Color(0xFFD9D9D9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Centered row of study technique cards
            Center(
              child: Wrap(
                spacing: 16, // Horizontal spacing between cards
                runSpacing: 16, // Vertical spacing if cards wrap
                alignment: WrapAlignment.center,
                children: _timerSessions.map((session) {
                  return _buildHorizontalSessionCard(session);
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // Section header for saved timers
            const Text(
              'Saved Timer Presets',
              style: TextStyle(
                color: Color(0xFFD9D9D9),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),

            // Saved timer options displayed as wrapped cards (only show when details NOT selected)
            // Filter out preset timers that are shown in Study Techniques section
            if (_selectedTimerDetails == null) ...[
              if (_savedTimers
                  .where((timer) =>
                      timer.label != 'Pomodoro Focus' &&
                      timer.label != 'Deep Work Session' &&
                      timer.label != 'Time-Box Focus')
                  .isNotEmpty) ...[
                Wrap(
                  spacing: 16, // Horizontal spacing between cards
                  runSpacing: 16, // Vertical spacing between rows
                  children: _savedTimers
                      .where((timer) =>
                          timer.label != 'Pomodoro Focus' &&
                          timer.label != 'Deep Work Session' &&
                          timer.label != 'Time-Box Focus')
                      .toList()
                      .asMap()
                      .entries
                      .map((entry) {
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
        ),

        // Overlay: Timer details view (shows on top when a timer is selected)
        if (_selectedTimerDetails != null)
          Positioned.fill(
            child: Container(
              color: const Color(0xFF1A1A1A)
                  .withValues(alpha: 0.95), // Semi-transparent dark background
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildTimerDetailsView(_selectedTimerDetails!),
              ),
            ),
          ),
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
    final bool isPresetTimer = [
      'Pomodoro Focus',
      'Deep Work Session',
      'Time-Box Focus'
    ].contains(timer.label);

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
                      ? _formatTotalTime(
                          (timer.totalSeconds + (timer.breakMinutes * 60)) *
                              timer.cycles)
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
                      _timerStartedFromSavedTimers =
                          true; // Mark as started from saved timers
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

              // Show Edit button for custom timers, Customize for preset timers
              if (!isPresetTimer) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Find the index of this timer in the saved list
                      final timerIndex = _savedTimers.indexOf(timer);

                      // Load timer settings into custom timer form for editing
                      setState(() {
                        _selectedHours = timer.hours;
                        _selectedMinutes = timer.minutes;
                        _selectedSeconds = timer.seconds;
                        _includeBreakTimer = timer.includeBreakTimer;
                        _breakMinutes = timer.breakMinutes;
                        _iterationCount = timer.cycles;
                        _labelController.text = timer.label;
                        _editingTimerId =
                            timer.id; // Track that we're editing this timer
                        _selectedTimerDetails = null;
                        _showPresets = false; // Switch to Custom Timer tab
                      });

                      // Delete the old timer from the display list (will be re-added when saved)
                      if (timerIndex != -1) {
                        setState(() {
                          _savedTimers.removeAt(timerIndex);
                        });
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Editing "${timer.label}"'),
                          backgroundColor: const Color(0xFF6FB8E9),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6FB8E9),
                      side:
                          const BorderSide(color: Color(0xFF6FB8E9), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Find the index of this timer in the saved list
                      final timerIndex = _savedTimers.indexOf(timer);

                      // Show confirmation dialog before deleting
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF242628),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(
                                color: Color(0xFFEF5350), width: 2),
                          ),
                          title: const Text(
                            'Delete Timer?',
                            style: TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          content: Text(
                            'Are you sure you want to delete "${timer.label}"?',
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Color(0xFF888888)),
                              ),
                            ),
                            TextButton(
                              onPressed: () async {
                                final navigator = Navigator.of(context);
                                final messenger = ScaffoldMessenger.of(context);

                                navigator.pop();
                                if (timerIndex != -1) {
                                  // Only delete from Firebase if it has an ID (not a preset)
                                  if (timer.id != null) {
                                    final firestoreService = FirestoreService();
                                    final success = await firestoreService
                                        .deleteTimer(timer.id!);

                                    if (success) {
                                      setState(() {
                                        _savedTimers.removeAt(timerIndex);
                                        _selectedTimerDetails = null;
                                      });
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              'Deleted timer "${timer.label}"'),
                                          backgroundColor:
                                              const Color(0xFFEF5350),
                                        ),
                                      );
                                    } else {
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Failed to delete timer. Please try again.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  } else {
                                    // Can't delete preset timers
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content:
                                            Text('Cannot delete preset timers'),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text(
                                'Delete',
                                style: TextStyle(
                                  color: Color(0xFFEF5350),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF5350),
                      side:
                          const BorderSide(color: Color(0xFFEF5350), width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.delete, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Show Customize button for preset timers
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
                      side:
                          const BorderSide(color: Color(0xFF6FB8E9), width: 2),
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
        border: Border.all(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.3), width: 1),
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
    return Consumer<TimerProvider>(
      builder: (context, timerProvider, child) {
        final activeSession = timerProvider.activeSession;
        final currentPhase = timerProvider.currentPhase;
        final timerState = timerProvider.timerState;

        return SingleChildScrollView(
          child: Column(
            children: [
              // Active Timer Container - compact version matching custom timer setup
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF242628),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6FB8E9),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Center(
                      child: Column(
                        children: [
                          Text(
                            activeSession?.name ??
                                (timerProvider.customTimerName.isEmpty
                                    ? 'Custom Timer'
                                    : timerProvider.customTimerName),
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (activeSession != null &&
                              currentPhase != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Phase ${(timerProvider.currentPhaseIndex ~/ 2) + 1} of ${activeSession.phases.length ~/ 2}',
                              style: const TextStyle(
                                color: Color(0xFFB0B0B0),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Study Time and Break Time cards (fixed positions)
                    Row(
                      children: [
                        // Study Time (always on left)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0xFF1A1A1A), // Dark content background
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: currentPhase?.isBreak == false ||
                                        activeSession == null
                                    ? const Color(0xFF6FB8E9) // Active border
                                    : const Color(0xFF6FB8E9).withValues(
                                        alpha: 0.3), // Inactive border
                                width: currentPhase?.isBreak == false ||
                                        activeSession == null
                                    ? 2
                                    : 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  currentPhase?.isBreak == false ||
                                          activeSession == null
                                      ? 'Current: Study Time'
                                      : 'Study Time',
                                  style: TextStyle(
                                    color: const Color(0xFF6FB8E9),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  // For simple timers (no session), always show countdown
                                  // For session timers, show countdown only during study phase
                                  activeSession == null ||
                                          currentPhase?.isBreak == false
                                      ? timerProvider.getFormattedTime()
                                      : _formatTime(activeSession.phases
                                          .firstWhere((p) => !p.isBreak)
                                          .seconds),
                                  style: TextStyle(
                                    color: const Color(
                                        0xFFD9D9D9), // Dashboard primary text
                                    fontSize: activeSession == null ||
                                            currentPhase?.isBreak == false
                                        ? 24
                                        : 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Focus on your task for the set duration.',
                                  style: const TextStyle(
                                    color: Color(
                                        0xFF888888), // Dashboard secondary text
                                    fontSize: 10,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Only show Break Time card if there's an active session with break phases
                        if (activeSession != null &&
                            activeSession.phases.any((p) => p.isBreak)) ...[
                          const SizedBox(width: 12),

                          // Break Time (always on right)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF1A1A1A), // Dark content background
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: currentPhase?.isBreak == true
                                      ? const Color(
                                          0xFF4CAF50) // Active border (green for break)
                                      : const Color(0xFF4CAF50).withValues(
                                          alpha: 0.3), // Inactive border
                                  width: currentPhase?.isBreak == true ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    currentPhase?.isBreak == true
                                        ? 'Current: Break Time'
                                        : 'Break Time',
                                    style: const TextStyle(
                                      color: Color(0xFF4CAF50),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    // Show countdown if currently break time, otherwise show duration
                                    currentPhase?.isBreak == true
                                        ? timerProvider.getFormattedTime()
                                        : _formatTime(activeSession.phases
                                            .firstWhere((p) => p.isBreak)
                                            .seconds),
                                    style: TextStyle(
                                      color: const Color(
                                          0xFFD9D9D9), // Dashboard primary text
                                      fontSize: currentPhase?.isBreak == true
                                          ? 24
                                          : 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Take a break and recharge.',
                                    style: const TextStyle(
                                      color: Color(
                                          0xFF888888), // Dashboard secondary text
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Status indicator
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: timerState == TimerState.paused
                            ? const Color(
                                0xFF1A1A1A) // Dark background for paused
                            : const Color(
                                0xFF1A1A1A), // Dark background for active
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: timerState == TimerState.paused
                              ? const Color(0xFF6FB8E9) // Blue for paused
                              : const Color(0xFF4CAF50), // Green for active
                          width: 1,
                        ),
                      ),
                      child: Text(
                        timerState == TimerState.paused
                            ? 'Focus Session Paused'
                            : 'Focus Session Active',
                        style: TextStyle(
                          color: timerState == TimerState.paused
                              ? const Color(0xFF6FB8E9) // Blue for paused
                              : const Color(0xFF4CAF50), // Green for active
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Control buttons
              Row(
                children: [
                  // Pause/Resume button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: timerState == TimerState.paused
                          ? _resumeTimer
                          : _pauseTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6FB8E9),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            timerState == TimerState.paused
                                ? Icons.play_arrow
                                : Icons.pause,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            timerState == TimerState.paused
                                ? 'Resume'
                                : 'Pause',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Cancel button
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _stopTimer,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF5350),
                        side: const BorderSide(
                            color: Color(0xFFEF5350), width: 2),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cancel_outlined, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
          child: Padding(
            padding: const EdgeInsets.all(10),
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
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.timer,
                          color: Color(0xFF6FB8E9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        timer.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFD9D9D9),
                          fontSize: 12,
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
                          fontSize: 14,
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

  /// Format session info as "Xm study - Ym break (xN)" or "Xm study" for single phase
  String _formatSessionInfo(TimerSession session) {
    // Find the first study phase and first break phase
    final studyPhase = session.phases.firstWhere(
      (phase) => !phase.isBreak,
      orElse: () => session.phases.first,
    );
    final breakPhase =
        session.phases.where((phase) => phase.isBreak).firstOrNull;

    // Count how many complete cycles (study + break pairs)
    int cycleCount = 0;
    if (breakPhase != null) {
      // Count study phases to determine cycles
      cycleCount = session.phases.where((phase) => !phase.isBreak).length;
    }

    // Format the display string
    if (breakPhase != null && cycleCount > 0) {
      return '${studyPhase.seconds ~/ 60}m study - ${breakPhase.seconds ~/ 60}m break (x$cycleCount)';
    } else {
      return '${studyPhase.seconds ~/ 60}m study';
    }
  }

  /// Calculate total session time in seconds
  int _getTotalSessionTimeInSeconds(TimerSession session) {
    return session.phases.fold<int>(0, (total, phase) => total + phase.seconds);
  }

  Widget _buildHorizontalSessionCard(TimerSession session) {
    return Container(
      width: 160,
      height: 180, // Fixed height to ensure all cards are the same size
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

              // Duration info formatted as "Xm study - Ym break (xN)"
              Text(
                _formatSessionInfo(session),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: session.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Total time at bottom
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: session.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: session.primaryColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Total: ${_formatTotalTime(_getTotalSessionTimeInSeconds(session))}',
                  style: TextStyle(
                    color: session.primaryColor,
                    fontSize: 10,
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

  void _saveCustomTimer() async {
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
    final timerLabel = label.isEmpty
        ? 'Custom Timer ${_savedTimers.where((t) => t.id != null).length + 1}'
        : label;
    final firestoreService = FirestoreService();
    final messenger = ScaffoldMessenger.of(context);

    // Check if we're editing an existing timer or creating a new one
    if (_editingTimerId != null) {
      // Update existing timer in Firebase
      final success = await firestoreService.updateTimer(
        timerId: _editingTimerId!,
        label: timerLabel,
        hours: _selectedHours,
        minutes: _selectedMinutes,
        seconds: _selectedSeconds,
        includeBreakTimer: _includeBreakTimer,
        breakMinutes: _breakMinutes,
        cycles: _iterationCount,
      );

      if (success) {
        debugPrint('✅ Timer updated in Firebase: $_editingTimerId');

        // Reload timers from Firebase to ensure consistency
        await _loadSavedTimers();

        messenger.showSnackBar(
          SnackBar(
            content: Text('Timer "$timerLabel" updated!'),
            backgroundColor: const Color(0xFF6FB8E9),
          ),
        );

        // Reset custom timer to default settings after saving
        _resetCustomTimerSettings();
      } else {
        debugPrint('❌ Failed to update timer in Firebase');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update timer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      // Save new timer to Firebase
      final timerId = await firestoreService.saveTimer(
        label: timerLabel,
        hours: _selectedHours,
        minutes: _selectedMinutes,
        seconds: _selectedSeconds,
        includeBreakTimer: _includeBreakTimer,
        breakMinutes: _breakMinutes,
        cycles: _iterationCount,
      );

      if (timerId != null) {
        debugPrint('✅ Timer saved to Firebase with ID: $timerId');

        // Reload timers from Firebase to ensure consistency
        await _loadSavedTimers();

        messenger.showSnackBar(
          SnackBar(
            content: Text('Timer "$timerLabel" saved!'),
            backgroundColor: const Color(0xFF6FB8E9),
          ),
        );

        // Reset custom timer to default settings after saving
        _resetCustomTimerSettings();
      } else {
        debugPrint('❌ Failed to save timer to Firebase');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to save timer. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
      // Each cycle consists of: study time + break time
      final customSession = TimerSession(
        name: _labelController.text.trim().isEmpty
            ? 'Custom Session'
            : _labelController.text.trim(),
        description:
            'Custom ${_formatSelectedTime()} + ${_breakMinutes}min break × $_iterationCount',
        technique: 'Custom Timer',
        icon: Icons.timer_outlined,
        primaryColor: const Color(0xFF6FB8E9),
        phases: List.generate(_iterationCount * 2, (index) {
          if (index % 2 == 0) {
            // Study phase (even indices: 0, 2, 4, ...)
            return SessionPhase(
              name: 'Study Time',
              seconds: totalSeconds,
              isBreak: false,
              instructions: 'Focus on your task for the set duration.',
              color: const Color(0xFF6FB8E9),
            );
          } else {
            // Break phase (odd indices: 1, 3, 5, ...)
            return SessionPhase(
              name: 'Break Time',
              seconds: _breakMinutes * 60,
              isBreak: true,
              instructions: 'Take a break and recharge.',
              color: const Color(0xFF4CAF50),
            );
          }
        }),
      );
      _startSession(customSession);
      // Reset custom timer to default settings after starting
      _resetCustomTimerSettings();
    } else {
      // Start simple timer using the regular _startTimer method (which already resets)
      _startTimer();
    }
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
