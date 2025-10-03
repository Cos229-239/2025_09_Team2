// TODO: Dashboard Screen - Major Integration and Feature Gaps
// - All providers load data but many have placeholder implementations
// - No real-time data synchronization with Firebase
// - Missing pull-to-refresh functionality
// - No offline mode support with sync when reconnected
// - Missing personalized dashboard customization
// - No dashboard analytics or usage tracking
// - Missing quick actions and shortcuts
// - No widget reordering or customization
// - Missing search functionality across all data
// - No batch operations or bulk actions
// - Missing dashboard performance optimization
// - No accessibility features for screen readers

// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
import 'dart:math';
// Import Provider package for accessing state management across widgets
import 'package:provider/provider.dart';
// Import screen for flashcard study interface
import 'package:studypals/screens/flashcard_study_screen.dart'; // Flashcard study interface
// Import additional screens for hamburger menu navigation
import 'package:studypals/screens/achievement_screen.dart'; // Achievement and rewards screen
import 'package:studypals/screens/social_screen.dart'; // Social learning screen
import 'package:studypals/screens/profile_settings_screen.dart'; // Profile settings screen
import 'package:studypals/screens/settings_screen.dart'; // Main settings screen
// Import planner screen
import 'package:studypals/screens/planner_page.dart';
// Import creation screens for notes and tasks
import 'package:studypals/screens/create_note_screen.dart'; // Note creation screen
import 'package:studypals/screens/create_task_screen.dart'; // Task creation screen
// Import learning screen
import 'package:studypals/screens/learning_screen.dart'; // Learning hub screen
// Import custom dashboard widgets that display different app features
import 'package:studypals/widgets/dashboard/due_cards_widget.dart'; // Flashcards due for review
import 'package:studypals/widgets/dashboard/progress_graph_widget.dart'; // Progress graph widget
import 'package:studypals/widgets/dashboard/pet_display_widget.dart'; // Pet display widget
import 'package:studypals/widgets/dashboard/calendar_display_widget.dart'; // Calendar display widget
// Import custom icon widgets
import 'package:studypals/widgets/icons/profile_icon.dart'; // Custom profile icon
// Import AI widgets for intelligent study features
import 'package:studypals/widgets/ai/ai_flashcard_generator.dart'; // AI-powered flashcard generation
import 'package:studypals/widgets/ai/ai_tutor_chat.dart'; // AI Tutor chat interface
import 'package:studypals/screens/unified_planner_screen.dart'; // Unified planner screen
// Import state providers for loading data from different app modules
import 'package:studypals/providers/task_provider.dart'; // Task management state
import 'package:studypals/providers/note_provider.dart'; // Notes management state
import 'package:studypals/providers/deck_provider.dart'; // Flashcard deck state
import 'package:studypals/providers/pet_provider.dart'; // Virtual pet state
import 'package:studypals/providers/srs_provider.dart'; // Spaced repetition system state
import 'package:studypals/providers/ai_provider.dart'; // AI provider state
import 'package:studypals/providers/daily_quest_provider.dart'; // Daily quest gamification state
import 'package:studypals/models/task.dart'; // Task model
import 'package:studypals/providers/notification_provider.dart'; // Notification system state
import 'package:studypals/utils/responsive_spacing.dart'; // Responsive spacing utility
import 'package:studypals/services/ai_service.dart'; // AI service for provider enum
// Import notification widgets for LinkedIn-style notifications
import 'package:studypals/widgets/notifications/notification_panel.dart'; // Notification bell and panel
// Import models for deck and card data
import 'package:studypals/models/deck.dart'; // Deck model for flashcard collections
import 'package:studypals/models/note.dart'; // Note model for study notes
import 'package:studypals/models/daily_quest.dart'; // Daily quest model for gamification
// Import flashcard study screen for studying decks
//import 'package:studypals/screens/flashcard_study_screen.dart'; // Flashcard study interface

/// Custom painter for outlined bar chart icon
/// Creates a bar chart icon with outlined bars instead of filled ones
class OutlinedBarChartPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  OutlinedBarChartPainter({
    required this.color,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale factors based on the SVG viewBox (24x24) to fit our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Bar 1 (left, shortest) - corresponds to path with height from 13.125 to 19.875
    final bar1Rect = Rect.fromLTWH(
      3 * scaleX, // x position
      13.125 * scaleY, // y position
      3.375 * scaleX, // width (4.125 + 2.25 - 3)
      6.75 * scaleY, // height (19.875 - 13.125)
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar1Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );

    // Bar 2 (middle) - corresponds to path with height from 8.625 to 19.875
    final bar2Rect = Rect.fromLTWH(
      9.75 * scaleX, // x position
      8.625 * scaleY, // y position
      3.375 * scaleX, // width
      11.25 * scaleY, // height (19.875 - 8.625)
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar2Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );

    // Bar 3 (right, tallest) - corresponds to path with height from 4.125 to 19.875
    final bar3Rect = Rect.fromLTWH(
      16.5 * scaleX, // x position
      4.125 * scaleY, // y position
      3.375 * scaleX, // width
      15.75 * scaleY, // height (19.875 - 4.125)
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar3Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for animated bar chart icon with hover-pinch effect
/// Recreates the Lottie "hover-pinch" animation where bars extend and contract in sequence
class AnimatedBarChartPainter extends CustomPainter {
  final Color color;
  final double animationProgress; // 0.0 to 1.0 for complete animation cycle
  final double strokeWidth;
  final bool isFilled; // New parameter to control fill/stroke mode

  AnimatedBarChartPainter({
    required this.color,
    required this.animationProgress,
    this.strokeWidth = 1.5,
    this.isFilled = false, // Default to outlined (stroke) mode
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors based on the SVG viewBox (24x24) to fit our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    final paint = Paint()
      ..color = color
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Calculate individual bar animation progress based on staggered timing from Lottie
    // Bar 1 (left): starts at frame 0 (0%), peaks at frame 15 (25%), returns at frame 50 (83.3%)
    double bar1Progress =
        _calculateBarProgress(animationProgress, 0.0, 0.25, 0.833);

    // Bar 2 (middle): starts at frame 5 (8.3%), peaks at frame 20 (33.3%), returns at frame 55 (91.6%)
    double bar2Progress =
        _calculateBarProgress(animationProgress, 0.083, 0.333, 0.916);

    // Bar 3 (right): starts at frame 10 (16.6%), peaks at frame 25 (41.6%), returns at frame 60 (100%)
    double bar3Progress =
        _calculateBarProgress(animationProgress, 0.166, 0.416, 1.0);

    // Base bar heights (normal state)
    const double bar1BaseHeight = 6.75;
    const double bar2BaseHeight = 11.25;
    const double bar3BaseHeight = 15.75;

    // Extension amounts during animation (30 units extension like in Lottie)
    const double extensionAmount = 30.0 * 0.2; // Scale down for icon size

    // Bar 1 (left, shortest) with animation
    final bar1Height = bar1BaseHeight + (extensionAmount * bar1Progress);
    final bar1Y = 19.875 - bar1Height; // Grow upward from bottom
    final bar1Rect = Rect.fromLTWH(
      3 * scaleX,
      bar1Y * scaleY,
      3.375 * scaleX,
      bar1Height * scaleY,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar1Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );

    // Bar 2 (middle) with animation
    final bar2Height = bar2BaseHeight + (extensionAmount * bar2Progress);
    final bar2Y = 19.875 - bar2Height; // Grow upward from bottom
    final bar2Rect = Rect.fromLTWH(
      9.75 * scaleX,
      bar2Y * scaleY,
      3.375 * scaleX,
      bar2Height * scaleY,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar2Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );

    // Bar 3 (right, tallest) with animation
    final bar3Height = bar3BaseHeight + (extensionAmount * bar3Progress);
    final bar3Y = 19.875 - bar3Height; // Grow upward from bottom
    final bar3Rect = Rect.fromLTWH(
      16.5 * scaleX,
      bar3Y * scaleY,
      3.375 * scaleX,
      bar3Height * scaleY,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar3Rect, Radius.circular(1.125 * scaleX)),
      paint,
    );
  }

  /// Calculates animation progress for individual bars with staggered timing
  /// [progress] Overall animation progress (0.0 to 1.0)
  /// [startTime] When this bar starts animating (0.0 to 1.0)
  /// [peakTime] When this bar reaches maximum extension (0.0 to 1.0)
  /// [endTime] When this bar returns to normal (0.0 to 1.0)
  double _calculateBarProgress(
      double progress, double startTime, double peakTime, double endTime) {
    if (progress < startTime) {
      return 0.0; // Not started yet
    } else if (progress < peakTime) {
      // Growing phase (0 to 1)
      double phaseProgress = (progress - startTime) / (peakTime - startTime);
      return _easeInOut(phaseProgress);
    } else if (progress < endTime) {
      // Shrinking phase (1 to 0)
      double phaseProgress = (progress - peakTime) / (endTime - peakTime);
      return 1.0 - _easeInOut(phaseProgress);
    } else {
      return 0.0; // Animation complete
    }
  }

  /// Custom easing function matching Lottie curves
  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is AnimatedBarChartPainter &&
        (oldDelegate.animationProgress != animationProgress ||
            oldDelegate.isFilled != isFilled);
  }
}

/// Custom painter for tasks/assignment icon based on provided SVG
/// Draws an exact replica of the SVG clipboard design
class TasksIconPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double strokeWidth;
  final Color backgroundColor; // Background color for transparent effect
  final double animationProgress; // Animation progress from 0.0 to 1.0

  TasksIconPainter({
    required this.color,
    required this.isFilled,
    this.strokeWidth = 1.5,
    this.backgroundColor = const Color(0xFF1C1F35), // Default purple background
    this.animationProgress = 0.0, // Default no animation
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors from SVG viewBox (500x500) to our icon size
    final scaleX = size.width / 500;
    final scaleY = size.height / 500;

    // Calculate bounce animation offset (clipboard moves up and down)
    // Based on Lottie animation: moves up at start, then back down
    double bounceOffset = 0.0;
    if (animationProgress > 0.0) {
      // Create a bounce effect: up from frames 1-20, down from frames 20-59
      double bouncePhase = animationProgress;
      if (bouncePhase <= 0.333) {
        // First third - move up
        bounceOffset = -6.0 * _easeInOut(bouncePhase * 3) * scaleY;
      } else if (bouncePhase <= 0.983) {
        // Rest - move back down
        double returnPhase = (bouncePhase - 0.333) / (0.983 - 0.333);
        bounceOffset = -6.0 * (1.0 - _easeInOut(returnPhase)) * scaleY;
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (isFilled) {
      // FILLED STATE: Inverted design - solid clipboard with hollow/white text lines
      paint.style = PaintingStyle.fill;

      // Draw the entire clipboard as one solid filled shape (apply bounce animation)
      final fullClipboard = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          83.362 * scaleX, // Main clipboard left
          (62.324 * scaleY) + bounceOffset, // Main clipboard top + bounce
          296.828 * scaleX, // Width: 380.19 - 83.362
          396.526 * scaleY, // Height: 458.303 - 62.324
        ),
        Radius.circular(36.452 * scaleX), // Main border radius
      );
      canvas.drawRRect(fullClipboard, paint);

      // Top clip/header area (same color as main clipboard, also bounces)
      final headerClip = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          182.304 * scaleX, // Header left
          (41.702 * scaleY) + bounceOffset, // Header top + bounce
          135.395 * scaleX, // Header width: 317.699 - 182.304
          72.905 * scaleY, // Header height: includes overlap
        ),
        Radius.circular(15.622 * scaleX), // Header radius
      );
      canvas.drawRRect(headerClip, paint);

      // Now create transparent text lines by drawing background-colored rounded rectangles
      final transparentTextPaint = Paint()
        ..color =
            backgroundColor // Use background color to create transparent effect
        ..style = PaintingStyle.fill;

      // Calculate which text lines should be visible based on animation progress
      // Based on Lottie: lines draw on sequentially starting around frame 16-22
      double line1Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.0, 0.467)
          : 1.0;
      double line2Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.05, 0.517)
          : 1.0;
      double line3Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.1, 0.567)
          : 1.0;

      // First transparent text line (with bounce offset and progressive width)
      if (line1Progress > 0.0) {
        final line1Width = 177.057 * scaleX * line1Progress;
        final hollowLine1 = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            161.473 * scaleX,
            (228.964 * scaleY) + bounceOffset, // Apply bounce to text lines too
            line1Width, // Animated width
            31.245 * scaleY,
          ),
          Radius.circular(15.622 * scaleX),
        );
        canvas.drawRRect(hollowLine1, transparentTextPaint);
      }

      // Second transparent text line (with bounce offset and progressive width)
      if (line2Progress > 0.0) {
        final line2Width = 177.057 * scaleX * line2Progress;
        final hollowLine2 = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            161.473 * scaleX,
            (286.663 * scaleY) + bounceOffset, // Apply bounce
            line2Width, // Animated width
            31.245 * scaleY,
          ),
          Radius.circular(15.622 * scaleX),
        );
        canvas.drawRRect(hollowLine2, transparentTextPaint);
      }

      // Third transparent text line (shorter, with bounce offset and progressive width)
      if (line3Progress > 0.0) {
        final line3Width = 72.905 * scaleX * line3Progress;
        final hollowLine3 = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            161.473 * scaleX,
            (343.737 * scaleY) + bounceOffset, // Apply bounce
            line3Width, // Animated width (shorter line)
            31.245 * scaleY,
          ),
          Radius.circular(15.622 * scaleX),
        );
        canvas.drawRRect(hollowLine3, transparentTextPaint);
      }
    } else {
      // OUTLINED STATE: Draw stroke-only version (also with bounce animation)
      paint.style = PaintingStyle.stroke;

      // Main clipboard outline (with bounce)
      final clipboardOutline = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          83.362 * scaleX,
          (62.324 * scaleY) + bounceOffset, // Apply bounce
          296.828 * scaleX,
          396.526 * scaleY,
        ),
        Radius.circular(36.452 * scaleX),
      );
      canvas.drawRRect(clipboardOutline, paint);

      // Inner document outline (with bounce)
      final innerOutline = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          119.814 * scaleX,
          (98.776 * scaleY) + bounceOffset, // Apply bounce
          260.572 * scaleX,
          322.074 * scaleY,
        ),
        Radius.circular(5.208 * scaleX),
      );
      canvas.drawRRect(innerOutline, paint);

      // Header clip outline (with bounce)
      final headerOutline = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          182.304 * scaleX,
          (41.702 * scaleY) + bounceOffset, // Apply bounce
          135.395 * scaleX,
          72.905 * scaleY,
        ),
        Radius.circular(15.622 * scaleX),
      );
      canvas.drawRRect(headerOutline, paint);

      // Draw text lines as strokes (with progressive drawing animation)
      final textPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      // Calculate line progress for outlined state (same timing as filled)
      double line1Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.0, 0.467)
          : 1.0;
      double line2Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.05, 0.517)
          : 1.0;
      double line3Progress = animationProgress > 0.0
          ? _calculateLineProgress(animationProgress, 0.1, 0.567)
          : 1.0;

      // First text line (with bounce and progressive drawing)
      if (line1Progress > 0.0) {
        final line1EndX = 161.473 * scaleX + (177.057 * scaleX * line1Progress);
        canvas.drawLine(
          Offset(161.473 * scaleX,
              (244.586 * scaleY) + bounceOffset), // Start with bounce
          Offset(line1EndX,
              (244.586 * scaleY) + bounceOffset), // End with progressive length
          textPaint,
        );
      }

      // Second text line (with bounce and progressive drawing)
      if (line2Progress > 0.0) {
        final line2EndX = 161.473 * scaleX + (177.057 * scaleX * line2Progress);
        canvas.drawLine(
          Offset(161.473 * scaleX,
              (302.285 * scaleY) + bounceOffset), // Start with bounce
          Offset(line2EndX,
              (302.285 * scaleY) + bounceOffset), // End with progressive length
          textPaint,
        );
      }

      // Third text line (shorter, with bounce and progressive drawing)
      if (line3Progress > 0.0) {
        final line3EndX = 161.473 * scaleX + (72.905 * scaleX * line3Progress);
        canvas.drawLine(
          Offset(161.473 * scaleX,
              (359.359 * scaleY) + bounceOffset), // Start with bounce
          Offset(
              line3EndX,
              (359.359 * scaleY) +
                  bounceOffset), // End with progressive length (shorter)
          textPaint,
        );
      }
    }
  }

  /// Easing function for smooth animations
  double _easeInOut(double t) {
    return t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;
  }

  /// Calculate progress for individual text lines drawing animation
  /// [progress] Overall animation progress (0.0 to 1.0)
  /// [startTime] When this line starts drawing (0.0 to 1.0)
  /// [endTime] When this line finishes drawing (0.0 to 1.0)
  double _calculateLineProgress(
      double progress, double startTime, double endTime) {
    if (progress < startTime) {
      return 0.0; // Not started yet
    } else if (progress > endTime) {
      return 1.0; // Fully drawn
    } else {
      // Drawing in progress - smooth progression
      double phaseProgress = (progress - startTime) / (endTime - startTime);
      return _easeInOut(phaseProgress);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is TasksIconPainter &&
        (oldDelegate.isFilled != isFilled ||
            oldDelegate.backgroundColor != backgroundColor ||
            oldDelegate.animationProgress != animationProgress);
  }
}

/// Main dashboard screen with bottom navigation between different app sections
/// This is a StatefulWidget because it manages navigation state and data loading
class DashboardScreen extends StatefulWidget {
  // Constructor with optional key for widget identification
  const DashboardScreen({super.key});

  /// Creates the mutable state object for this widget
  /// @return State object managing dashboard navigation and data loading
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

/// Private state class managing bottom navigation and data initialization
/// Handles tab switching between Dashboard, Planner, Notes, Decks, and Progress
class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  /// Widget initialization lifecycle method
  /// Called once when the widget is first created
  @override
  void initState() {
    super.initState(); // Call parent initialization

    // Schedule data loading to happen after the first frame is built
    // This prevents blocking the UI during initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData(); // Load all app data asynchronously
    });
  }

  /// Loads data from all providers concurrently to populate the dashboard
  /// Called after the widget is built to avoid blocking initial UI render
  /// Uses Future.wait to load all data sources in parallel for better performance
  Future<void> _loadData() async {
    // Get provider instances without listening to changes (data loading only)
    final taskProvider =
        Provider.of<TaskProvider>(context, listen: false); // Task data access
    final deckProvider =
        Provider.of<DeckProvider>(context, listen: false); // Deck data access
    final petProvider =
        Provider.of<PetProvider>(context, listen: false); // Pet data access
    final srsProvider =
        Provider.of<SRSProvider>(context, listen: false); // SRS data access
    final questProvider = Provider.of<DailyQuestProvider>(context,
        listen: false); // Daily quest data access
    final aiProvider = Provider.of<StudyPalsAIProvider>(context,
        listen: false); // AI provider access
    final notificationProvider = Provider.of<NotificationProvider>(context,
        listen: false); // Notification system access

    // Auto-configure Google AI upon dashboard initialization
    try {
      await aiProvider.configureAI(
        provider: AIProvider.google,
        apiKey: 'AIzaSyCqWTq-SFuam7FTMe2OVcAiriqleRrf30Q',
        //apiKey: 'AIzaSyAasLmobMCyBiDAm3x9PqT11WX5ck3OhMA',
      );
      debugPrint('Google AI automatically configured on dashboard load');
    } catch (e) {
      debugPrint('Failed to auto-configure AI on dashboard load: $e');
    }

    // Load all data sources concurrently using Future.wait for better performance
    // If one fails, others can still complete successfully
    await Future.wait([
      taskProvider.loadTasks(), // Load all tasks from database
      deckProvider.loadDecks(), // Load all flashcard decks from database
      petProvider.loadPet(), // Load virtual pet data from database
      srsProvider
          .loadReviews(), // Load spaced repetition review data from database
      questProvider
          .loadTodaysQuests(), // Load daily quests and generate if needed
      notificationProvider.loadNotifications(), // Load existing notifications
    ]);

    // Set up quest completion callback for notifications
    questProvider.setQuestCompletionCallback((quest) {
      notificationProvider.notifyQuestCompleted(quest);
    });

    // Generate quiz and review notifications based on loaded data
    try {
      await notificationProvider.checkQuizNotifications(
        quests: questProvider.quests,
        dueCards: srsProvider.dueReviews,
      );
      debugPrint('Checked and generated quiz notifications');
    } catch (e) {
      debugPrint('Error generating notifications: $e');
    }
  }

  /// Builds the dashboard screen with bottom navigation
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the dashboard with navigation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display only the dashboard home screen (no more navigation)
      body: DashboardHome(onNavigate: (index) {
        // Handle navigation by opening different screens directly
        switch (index) {
          case 1: // Planner
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (context) => const UnifiedPlannerScreen()),
            );
            break;
          case 2: // Notes
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotesScreen()),
            );
            break;
          case 3: // Decks
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const DecksScreen()),
            );
            break;
          case 4: // Progress
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProgressScreen()),
            );
            break;
        }
      }),
    );
  }
}

/// Main dashboard home screen displaying key app widgets
/// Shows virtual pet, today's tasks, due cards, and quick statistics
class DashboardHome extends StatefulWidget {
  final Function(int)? onNavigate;

  // Constructor with optional key for widget identification
  const DashboardHome({super.key, this.onNavigate});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  // Animation controllers for each navigation button
  late List<AnimationController> _iconAnimationControllers;
  late List<Animation<double>> _scaleAnimations;
  late List<Animation<double>> _bounceAnimations; // For vertical bounce effect

  // Animation controller for Stats button bar chart transition
  late AnimationController _statsIconController;
  late Animation<double> _statsIconAnimation;

  // Animation controller for Home button hover-pinch effect
  late AnimationController _homeIconController;
  late Animation<double> _homeIconAnimation;

  // Animation controller for Pet button paws hover-pinch effect
  late AnimationController _petIconController;
  late Animation<double> _petIconAnimation;

  // Animation controller for Social button hugging effect
  late AnimationController _socialIconController;
  late Animation<double> _socialIconAnimation;

  // Animation controller for Learn button tassel sway effect
  late AnimationController _learnIconController;
  Animation<double>? _learnIconAnimation;

  // Animation controller for Tasks button clipboard animation
  late AnimationController _tasksAnimationController;
  late Animation<double> _tasksAnimation;

  // Notification panel state and animation
  bool _isNotificationPanelOpen = false;
  late AnimationController _notificationPanelController;
  late Animation<double> _notificationPanelAnimation;

  // Hamburger menu state and animation
  bool _isHamburgerMenuOpen = false;
  late AnimationController _hamburgerMenuController;
  late Animation<double> _hamburgerMenuAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // Animate icons when tab changes
      _animateTabChange(_selectedTabIndex, _tabController.index);
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });

    // Initialize animation controllers for each navigation button (5 buttons)
    _iconAnimationControllers = List.generate(
      5,
      (index) => AnimationController(
        duration:
            const Duration(milliseconds: 400), // Slightly shorter for subtlety
        vsync: this,
      ),
    );

    // Initialize Stats icon animation controller (for bar chart pinch effect)
    _statsIconController = AnimationController(
      duration:
          const Duration(milliseconds: 1000), // 60 frames at 60fps = 1000ms
      vsync: this,
    );
    _statsIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsIconController,
      curve: Curves.easeInOut,
    ));

    // Initialize Home icon hover-pinch animation controller
    _homeIconController = AnimationController(
      duration: const Duration(milliseconds: 1000), // 1 second to match Lottie
      vsync: this,
    );
    _homeIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _homeIconController,
      curve: Curves.easeInOut,
    ));

    // Initialize Pet icon paws hover-pinch animation controller
    _petIconController = AnimationController(
      duration: const Duration(
          milliseconds: 1000), // 1 second to match Lottie (60 frames at 60fps)
      vsync: this,
    );
    _petIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _petIconController,
      curve: Curves.easeInOut,
    ));

    // Initialize Social icon hugging animation controller  
    _socialIconController = AnimationController(
      duration: const Duration(milliseconds: 1600), // Longer duration for full hug-and-release cycle
      vsync: this,
    );
    _socialIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _socialIconController,
      curve: Curves.easeInOutBack, // Smooth back-and-forth curve for hug-release effect
    ));

    // Initialize Learn icon tassel sway animation controller
    _learnIconController = AnimationController(
      duration: const Duration(milliseconds: 2000), // Gentle 2-second sway cycle
      vsync: this,
    );
    _learnIconAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _learnIconController,
      curve: Curves.easeInOut, // Smooth sway motion
    ));

    // Initialize Tasks icon clipboard animation controller
    _tasksAnimationController = AnimationController(
      duration: const Duration(
          milliseconds: 1000), // 1 second animation (60 frames at 60fps)
      vsync: this,
    );
    _tasksAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _tasksAnimationController,
      curve: Curves.easeInOut,
    ));

    // Initialize notification panel animation controller
    _notificationPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _notificationPanelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _notificationPanelController,
      curve: Curves.easeInOut,
    ));

    // Initialize hamburger menu animation controller
    _hamburgerMenuController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _hamburgerMenuAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hamburgerMenuController,
      curve: Curves.easeInOut,
    ));

    // Create subtle scale animations (very light growth)
    _scaleAnimations = _iconAnimationControllers
        .map(
          (controller) => Tween<double>(
            begin: 1.0,
            end: 1.08, // Much smaller scale increase
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.easeOut, // Smooth ease out
          )),
        )
        .toList();

    // Create vertical bounce animations (upward movement)
    _bounceAnimations = _iconAnimationControllers
        .map(
          (controller) => Tween<double>(
            begin: 0.0,
            end: -3.0, // Negative value for upward movement (3 pixels up)
          ).animate(CurvedAnimation(
            parent: controller,
            curve: Curves.bounceOut, // Bounce effect for vertical movement
          )),
        )
        .toList();

    // Start with first tab selected
    _iconAnimationControllers[0].forward();
    _homeIconController
        .forward(); // Start home animation since it's the default tab
  }

  /// Animate transition between tabs
  void _animateTabChange(int oldIndex, int newIndex) {
    // Reverse animation for previously selected tab
    _iconAnimationControllers[oldIndex].reverse();
    // Forward animation for newly selected tab
    _iconAnimationControllers[newIndex].forward();

    // Special handling for Home button (index 0)
    if (newIndex == 0) {
      _homeIconController.forward();
    } else if (oldIndex == 0) {
      _homeIconController.reverse();
    }

    // Special handling for Learn button (index 1)
    if (newIndex == 1) {
      if (_learnIconAnimation != null) {
        _learnIconController.repeat(reverse: true); // Start gentle tassel sway animation
      }
    } else if (oldIndex == 1) {
      if (_learnIconAnimation != null) {
        _learnIconController.stop(); // Stop the sway animation
        _learnIconController.reset(); // Reset to normal position
      }
    }

    // Special handling for AI Tutor button (index 2)
    if (newIndex == 2) {
      _statsIconController.forward();
    } else if (oldIndex == 2) {
      _statsIconController.reverse();
    }

    // Special handling for Social button (index 3)
    if (newIndex == 3) {
      _socialIconController.forward(); // Play hug-and-release animation once
    } else if (oldIndex == 3) {
      _socialIconController.stop(); // Stop the animation
      _socialIconController.reset(); // Reset to normal position
    }

    // Special handling for Pet button (index 4)
    if (newIndex == 4) {
      _petIconController.forward();
    } else if (oldIndex == 4) {
      _petIconController.reverse();
    }
  }

  /// Build expand-from-bottom transition animation for tabs
  /// Creates an effect where pages appear to expand from the toolbar button
  Widget _buildExpandTransition(int tabIndex, Widget child) {
    // Calculate animation progress for this specific tab
    final animation = _tabController.animation!;
    final value = (animation.value - tabIndex).abs();
    
    // Only animate when transitioning to/from this tab
    if (value > 1.0) {
      return const SizedBox.shrink(); // Hide completely when far from active
    }
    
    // Calculate progress (1.0 when fully visible, 0.0 when hidden)
    final progress = (1.0 - value).clamp(0.0, 1.0);
    
    // Scale animation: starts small (from button) and grows to full screen
    final scale = 0.2 + (progress * 0.8); // Start at 20% scale
    
    // Vertical translation: starts from bottom toolbar position
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalOffset = (screenHeight * 0.4) * (1.0 - progress); // Start from 40% down
    
    // Opacity for smooth fade-in effect
    final opacity = Curves.easeIn.transform(progress);
    
    // Apply transforms: translate, scale, and fade
    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.scale(
        scale: scale,
        alignment: Alignment.bottomCenter, // Anchor scaling to bottom
        child: Opacity(
          opacity: opacity,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30 * (1.0 - progress)), // Round corners during transition
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Dispose all animation controllers
    for (var controller in _iconAnimationControllers) {
      controller.dispose();
    }
    _statsIconController.dispose();
    _homeIconController.dispose();
    _petIconController.dispose();
    _socialIconController.dispose();
    _learnIconController.dispose();
    _tasksAnimationController.dispose();
    _notificationPanelController.dispose();
    _hamburgerMenuController.dispose();
    super.dispose();
  }

  /// Builds the app bar action buttons (notifications and profile)
  /// Separated into method to keep build method clean and organized
  /// @param context - Build context for navigation and state access
  /// @return List of IconButton widgets for the app bar actions
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // LinkedIn-style notification bell with unread count badge
      SizedBox(
        width: 48, // Standard IconButton width for consistency
        height: 48, // Standard IconButton height for consistency
        child: Center(
          child: NotificationBellIcon(
            onTap: _toggleNotificationPanel,
            isSelected: _isNotificationPanelOpen,
          ),
        ),
      ),

      // Profile button - navigates to profile settings screen
      SizedBox(
        width: 48, // Standard IconButton width for consistency
        height: 48, // Standard IconButton height for consistency
        child: Center(
          child: GestureDetector(
            onTap: () {
              // Navigate to profile settings screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileSettingsScreen(),
                ),
              );
            },
            child: const ProfileIcon(size: 28),
          ),
        ),
      ),
    ];
  }

  /// Toggle notification panel slide animation
  void _toggleNotificationPanel() {
    setState(() {
      _isNotificationPanelOpen = !_isNotificationPanelOpen;
      if (_isNotificationPanelOpen) {
        _notificationPanelController.forward();
        // Close hamburger menu if open
        if (_isHamburgerMenuOpen) {
          _isHamburgerMenuOpen = false;
          _hamburgerMenuController.reverse();
        }
      } else {
        _notificationPanelController.reverse();
      }
    });
  }

  /// Toggle hamburger menu dropdown animation
  void _toggleHamburgerMenu() {
    setState(() {
      _isHamburgerMenuOpen = !_isHamburgerMenuOpen;
      if (_isHamburgerMenuOpen) {
        _hamburgerMenuController.forward();
        // Close notification panel if open
        if (_isNotificationPanelOpen) {
          _isNotificationPanelOpen = false;
          _notificationPanelController.reverse();
        }
      } else {
        _hamburgerMenuController.reverse();
      }
    });
  }

  /// Builds the main dashboard content with app widgets
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the dashboard home screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main dashboard content
          Container(
            color: const Color(0xFF16181A), // Solid background color from Figma
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to control animation
              children: [
                // Tab 0: Home tab - responsive dashboard content - Wrapped with animation
                AnimatedBuilder(
                  animation: _tabController.animation!,
                  builder: (context, child) => _buildExpandTransition(0, child!),
                  child: Stack(
                    children: [
                      // Main home tab content
                      SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status bar area for time, WiFi, notch spacing
                          _buildStatusBar(context),
                          
                          // Header with responsive spacing
                          Container(
                            height: ResponsiveSpacing.getHeaderHeight(context),
                            color: const Color(0xFF242628),
                            padding: EdgeInsets.symmetric(
                              horizontal: ResponsiveSpacing.getHorizontalPadding(context),
                              vertical: ResponsiveSpacing.getSmallSpacing(context),
                            ),
                            child: _buildHeader(context),
                          ),

                          // Horizontal divider line - full width
                          Container(
                            width: double.infinity,
                            height: 3.0,
                            color: const Color(0xFF6FB8E9),
                          ),

                          // Content section with responsive padding
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.fromLTRB(
                                ResponsiveSpacing.getHorizontalPadding(context),
                                ResponsiveSpacing.getVerticalSpacing(context) * 0.5, // Small top margin
                        ResponsiveSpacing.getHorizontalPadding(context),
                        ResponsiveSpacing.getHorizontalPadding(context),
                      ),
                      child: Column(
                        children: [
                          // Calendar Display Widget with responsive height
                          SizedBox(
                            height: ResponsiveSpacing.getComponentHeight(context, ComponentType.calendar),
                            child: const CalendarDisplayWidget(),
                          ),

                          SizedBox(height: ResponsiveSpacing.getVerticalSpacing(context)),

                          // Progress Graph Widget with responsive height
                          SizedBox(
                            height: ResponsiveSpacing.getComponentHeight(context, ComponentType.graph),
                            child: const ProgressGraphWidget(),
                          ),

                          SizedBox(height: ResponsiveSpacing.getVerticalSpacing(context)),

                          // Calendar and Progress buttons row with responsive spacing
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  label: 'Calendar',
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const UnifiedPlannerScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(width: ResponsiveSpacing.getButtonSpacing(context)),
                              Expanded(
                                child: _buildActionButton(
                                  context,
                                  label: 'Progress',
                                  onTap: () {
                                    _tabController.animateTo(
                                        2); // Navigate to AI Tutor tab
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: ResponsiveSpacing.getVerticalSpacing(context)),

                          // Pet Display Widget with responsive height
                          SizedBox(
                            height: ResponsiveSpacing.getComponentHeight(context, ComponentType.pet),
                            child: const PetDisplayWidget(),
                          ),

                          // Extra bottom spacing to account for floating navigation
                          SizedBox(height: ResponsiveSpacing.getVerticalSpacing(context) * 1.5),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
                      // Notification panel overlay within home tab
                      _buildNotificationPanelOverlay(context),
                      // Hamburger menu overlay within home tab
                      _buildHamburgerMenuOverlay(context),
                    ],
                  ),
                ),
            // Tab 1: Learn tab (Flashcards/Decks) - Wrapped with animation
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) => _buildExpandTransition(1, child!),
              child: _buildLearnTab(),
            ),
            // Tab 2: AI Tutor tab - Wrapped with animation
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) => _buildExpandTransition(2, child!),
              child: _buildAITutorTab(),
            ),
            // Tab 3: Social tab - Wrapped with animation
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) => _buildExpandTransition(3, child!),
              child: _buildSocialTab(),
            ),
            // Tab 4: Pet tab - Wrapped with animation
            AnimatedBuilder(
              animation: _tabController.animation!,
              builder: (context, child) => _buildExpandTransition(4, child!),
              child: _buildPetTab(),
            ),
          ],
        ),
      ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          ResponsiveSpacing.getHorizontalPadding(context), // Left padding matching dashboard containers
          0, // No top padding
          ResponsiveSpacing.getHorizontalPadding(context), // Right padding matching dashboard containers  
          ResponsiveSpacing.getHorizontalPadding(context), // Bottom padding matching horizontal container spacing
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Floating navigation toolbar with rounded corners
            Container(
              height: 68, // Adjusted to fit content with exact AI Tutor spacing
              decoration: BoxDecoration(
                color: const Color(0xFF242628), // Dark background color
                borderRadius: BorderRadius.circular(34), // Rounded corners (half of height for pill shape)
                border: Border.all(
                  color: const Color(0xFF6FB8E9), // Blue border
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24), // Internal padding
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavButton(
                      context,
                      index: 0,
                      icon: Icons.home,
                      label: 'Home',
                      isSelected: _selectedTabIndex == 0,
                      onTap: () => _tabController.animateTo(0),
                    ),
                    _buildNavButton(
                      context,
                      index: 1,
                      icon: Icons.school,
                      label: 'Learn',
                      isSelected: _selectedTabIndex == 1,
                      onTap: () => _tabController.animateTo(1),
                    ),
                    // Empty space for floating AI Tutor button
                    const Expanded(child: SizedBox()),
                    _buildNavButton(
                      context,
                      index: 3,
                      icon: Icons.people,
                      label: 'Social',
                      isSelected: _selectedTabIndex == 3,
                      onTap: () => _tabController.animateTo(3),
                    ),
                    _buildNavButton(
                      context,
                      index: 4,
                      icon: Icons.pets,
                      label: 'Pet',
                      isSelected: _selectedTabIndex == 4,
                      onTap: () => _tabController.animateTo(4),
                    ),
                  ],
                ),
              ),
            ),
            // Floating AI Tutor button positioned above the toolbar
            Positioned(
              top: -31, // Moved down 4 pixels (from -35 to -31)
              left: 0,
              right: 0,
              child: Center(
                child: _buildFloatingAIButton(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the status bar with time, connectivity, and notch spacing
  Widget _buildStatusBar(BuildContext context) {
    return StreamBuilder<DateTime>(
      stream: Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now()),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        
        return Container(
          height: 44, // Standard status bar height with notch consideration
          color: const Color(0xFF242628), // Match header color
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveSpacing.getHorizontalPadding(context),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Time display
              Text(
                timeString,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              // Connectivity indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // WiFi signal icon
                  Icon(
                    Icons.wifi,
                    size: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  const SizedBox(width: 8),
                  // Battery icon (optional)
                  Icon(
                    Icons.battery_full,
                    size: 18,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Build slide-down notification panel overlay
  Widget _buildNotificationPanelOverlay(BuildContext context) {
    return AnimatedBuilder(
      animation: _notificationPanelAnimation,
      builder: (context, child) {
        // Don't show anything when closed or animation value is 0
        if (_notificationPanelAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }
        
        // Now that we're inside the SafeArea, we can position relative to the content
        // Calculate the position after status bar + header + blue divider
        final headerHeight = ResponsiveSpacing.getHeaderHeight(context);
        final statusBarHeight = MediaQuery.of(context).padding.top;
        final dividerHeight = 3.0;
        
        // Position right after the blue divider line within the SafeArea + 43px offset (42 + 1)
        final topPosition = statusBarHeight + headerHeight + dividerHeight + 43.0;
        
        // Calculate height to cover calendar and progress containers
        final calendarHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.calendar);
        final progressHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.graph);
        final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
        final panelHeight = calendarHeight + progressHeight + (verticalSpacing * 3) + 100 - 65; // Reduced by 65px (66 - 1)
        
        return Positioned(
          top: topPosition, // Position right after the blue divider
          left: 0,
          right: 0,
          child: ClipRect(
            child: SizedBox(
              height: panelHeight * _notificationPanelAnimation.value, // Animate height from 0 to full
              child: Container(
                margin: EdgeInsets.symmetric(
                  horizontal: ResponsiveSpacing.getHorizontalPadding(context),
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF242628), // Match header color
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  border: Border.all(
                    color: const Color(0xFF6FB8E9),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  child: NotificationPanel(
                    onClose: _toggleNotificationPanel,
                    isBottomSheet: false,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build hamburger menu dropdown overlay with animation
  Widget _buildHamburgerMenuOverlay(BuildContext context) {
    return AnimatedBuilder(
      animation: _hamburgerMenuAnimation,
      builder: (context, child) {
        // Don't show anything when closed or animation value is 0
        if (_hamburgerMenuAnimation.value == 0.0) {
          return const SizedBox.shrink();
        }
        
        // Calculate position - menu appears from top on the left side
        final statusBarHeight = 44.0; // Custom status bar height
        final headerHeight = ResponsiveSpacing.getHeaderHeight(context);
        final systemStatusBar = MediaQuery.of(context).padding.top; // System notch/status bar
        final dividerHeight = 3.0;
        
        // Position right after: system status bar + custom status bar + header + divider
        final topPosition = systemStatusBar + statusBarHeight + headerHeight + dividerHeight;
        
        // Menu takes partial width from the left side
        final screenWidth = MediaQuery.of(context).size.width;
        final menuWidth = screenWidth * 0.42; // 42% of screen width - wider to fit "Flash Cards"
        
        // Calculate height to fit content (9 menu items)
        // Each item: 14px top + 14px bottom padding = 28px per item + ListView padding
        const menuItemHeight = 50.0; // Approximate height per item with padding
        const numberOfItems = 9;
        const listPadding = 24.0; // Top and bottom padding
        final menuHeight = (menuItemHeight * numberOfItems) + listPadding;
        
        return Positioned(
          top: topPosition,
          left: 0,
          width: menuWidth * _hamburgerMenuAnimation.value, // Animate width from 0 to full
          height: menuHeight * _hamburgerMenuAnimation.value, // Also animate height for smoother effect
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(20), // Rounded bottom-right corner
            ),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF242628), // Same as header background
                border: Border(
                  right: BorderSide(
                    color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                    offset: const Offset(2, 0),
                  ),
                ],
              ),
              child: _buildHamburgerMenuContent(context),
            ),
          ),
        );
      },
    );
  }

  /// Build hamburger menu content
  Widget _buildHamburgerMenuContent(BuildContext context) {
    return Container(
      color: const Color(0xFF242628), // Same as header background
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        children: [

        // Menu items
        _buildHamburgerMenuItem(
          context,
          icon: Icons.note,
          title: 'Notes',
          color: Colors.amber,
          onTap: () {
            _toggleHamburgerMenu();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotesScreen(),
              ),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.style,
          title: 'Flash Cards',
          color: Colors.blue,
          onTap: () {
            _toggleHamburgerMenu();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const DecksScreen(),
              ),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.emoji_events,
          title: 'Badges',
          color: Colors.orange,
          onTap: () {
            _toggleHamburgerMenu();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AchievementScreen(),
              ),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.timer,
          title: 'Timer',
          color: Colors.red,
          onTap: () {
            _toggleHamburgerMenu();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Timer feature coming soon!')),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.shopping_bag,
          title: 'Shop',
          color: Colors.green,
          onTap: () {
            _toggleHamburgerMenu();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Shop feature coming soon!')),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.music_note,
          title: 'Music',
          color: Colors.purple,
          onTap: () {
            _toggleHamburgerMenu();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Music feature coming soon!')),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.feedback,
          title: 'Feedback',
          color: Colors.teal,
          onTap: () {
            _toggleHamburgerMenu();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Feedback feature coming soon!')),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.settings,
          title: 'Settings',
          color: Colors.grey,
          onTap: () {
            _toggleHamburgerMenu();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SettingsScreen(),
              ),
            );
          },
        ),
        _buildHamburgerMenuItem(
          context,
          icon: Icons.help,
          title: 'Help',
          color: Colors.blueGrey,
          onTap: () {
            _toggleHamburgerMenu();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Help feature coming soon!')),
            );
          },
        ),
      ],
      ),
    );
  }

  /// Build a menu item for the hamburger menu - styled like the image
  Widget _buildHamburgerMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Row(
          children: [
            // Icon on the left
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(width: 16), // Space between icon and text
            // Text on the right - wrapped in Expanded to prevent overflow
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFCCCCCC), // Light gray text like in the image
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow gracefully
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the header section with greeting and action buttons
  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Ensure all elements are centered vertically
      children: [
        // Simple hamburger menu icon at the top left with functionality
        SizedBox(
          width: 48, // Standard IconButton width for consistency
          height: 48, // Standard IconButton height for consistency
          child: Center(
            child: GestureDetector(
              onTap: _toggleHamburgerMenu,
              child: AnimatedRotation(
                turns: _isHamburgerMenuOpen ? 0.125 : 0.0, // Rotate 45 degrees when open
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  _isHamburgerMenuOpen ? Icons.close : Icons.menu,
                  color: _isHamburgerMenuOpen 
                    ? const Color(0xFF6FB8E9)
                    : Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),

        // Main content
        Expanded(
          child: Text(
            'Study Pals',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),

        // Action buttons on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center, // Ensure right icons are centered too
          children: _buildAppBarActions(context),
        ),
      ],
    );
  }

  /// Build action button for Calendar and Progress
  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveSpacing.getHorizontalPadding(context) * 0.75,
          vertical: ResponsiveSpacing.getSmallSpacing(context) * 0.75,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF16181A), // Hollow - match background color
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF6FB8E9), // New blue color - solid border
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ),
    );
  }

  /* Removed unused method _buildCardsAndNotesRow
  /// Build flash cards and notes row with login screen styling
  Widget _buildCardsAndNotesRow(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
        // Flash Cards section
        Expanded(
          child: Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius:
                  Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                      ? (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .borderRadius
                      : BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6FB8E9),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to flash cards
                  widget.onNavigate?.call(3); // Decks tab
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Flash Cards',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6FB8E9)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.style,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Notes section
        Expanded(
          child: Container(
            height: 120,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius:
                  Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                      ? (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .borderRadius
                      : BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6FB8E9),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // Navigate to notes
                  widget.onNavigate?.call(2); // Notes tab
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Notes',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6FB8E9),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6FB8E9)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.note_alt,
                          size: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  } */

  /// Build Learn tab content (Flashcards/Decks)
  Widget _buildLearnTab() {
    // Use the new Learning Screen with all learning features
    return const LearningScreen();
  }

  /// Build AI Tutor tab content
  Widget _buildAITutorTab() {
    return const AITutorChat(); // Use the actual AI Tutor chat interface
  }

  /// Build Social tab content - Navigate to SocialScreen
  Widget _buildSocialTab() {
    return const SocialScreen();
  }

  /// Build Pet tab content
  Widget _buildPetTab() {
    return SafeArea(
      child: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final pet = petProvider.currentPet;

          if (pet == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your Study Pal...'),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Your Study Pal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 20),
                // Pet avatar
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: const Icon(
                    Icons.pets,
                    size: 60,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Level ${pet.level}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${pet.xp}/${pet.xpForNextLevel} XP',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                // XP Progress bar
                LinearProgressIndicator(
                  value: pet.xp / pet.xpForNextLevel,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Keep studying to level up your pet!',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build individual navigation button matching the image layout with animations
  Widget _buildNavButton(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimations[index],
          _bounceAnimations[index],
        ]),
        builder: (context, child) {
          return Transform.translate(
            offset:
                Offset(0, _bounceAnimations[index].value), // Vertical bounce
            child: Transform.scale(
              scale: _scaleAnimations[index].value,
              alignment: Alignment
                  .bottomCenter, // Scale from bottom center to keep bottom anchored
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icon container with consistent height for alignment
                        SizedBox(
                          height: 40, // Fixed height to ensure all icons align horizontally
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeInOut,
                              padding: EdgeInsets.all(label == 'AI Tutor' && isSelected ? 
                                2.0 : // Minimal padding for AI Tutor when selected
                                1.0), // Minimal padding for all other icons
                              decoration: BoxDecoration(
                                color: (label == 'AI Tutor' && isSelected) 
                                    ? const Color(0xFF6FB8E9) // Blue background for selected AI Tutor
                                    : Colors.transparent, // Transparent for others
                                borderRadius: BorderRadius.circular(label == 'AI Tutor' && isSelected ? 24 : 16),
                                border: (label != 'AI Tutor' || !isSelected) ? Border.all(
                                  color: Colors.transparent,
                                  width: 0,
                                ) : null,
                              ),
                              child: _buildIconWithHollowEffect(
                                  icon, isSelected, label),
                            ),
                          ),
                        ),
                        // No spacing - text immediately under icon
                        // Label text with consistent baseline alignment
                        SizedBox(
                          height: 14, // Fixed height to ensure all text aligns horizontally
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style:
                                  Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: (label == 'AI Tutor' && isSelected)
                                                ? Colors.white // White text for selected AI Tutor
                                                : (label == 'AI Tutor')
                                                    ? const Color(0xFF6FB8E9) // Blue for unselected AI Tutor
                                                    : const Color(0xFFCFCFCF), // Gray for all others
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w500,
                                            fontSize: 10, // Reduced from 11 to fit better
                                          ) ??
                                      const TextStyle(),
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build floating AI Tutor button with hollow circle design
  Widget _buildFloatingAIButton(BuildContext context) {
    final isSelected = _selectedTabIndex == 2;
    
    return AnimatedBuilder(
      animation: _scaleAnimations[2], // Use existing animation for AI Tutor
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimations[2].value,
          child: GestureDetector(
            onTap: () => _tabController.animateTo(2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? const Color(0xFF6FB8E9) 
                      : const Color(0xFF242628), // Match footer background when not selected
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6FB8E9),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: isSelected 
                      ? Colors.white 
                      : const Color(0xFF6FB8E9),
                    size: 28,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'AI Tutor',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: isSelected
                      ? const Color(0xFF6FB8E9)
                      : const Color(0xFFCFCFCF),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 11,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build icon with hollow effect for Stats and Pet buttons when not selected
  Widget _buildIconWithHollowEffect(
      IconData icon, bool isSelected, String label) {
    // For Home button, use animated custom SVG painter
    if (label == 'Home') {
      return AnimatedBuilder(
        animation: _homeIconAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(28, 28),
            painter: AnimatedHomeIconPainter(
              color: isSelected 
                ? const Color(0xFF6FB8E9) // Blue when selected
                : const Color(0xFFCFCFCF), // Gray when not selected
              isFilled: isSelected,
              animationProgress: isSelected ? _homeIconAnimation.value : 0.0,
            ),
          );
        },
      );
    }

    if (label == 'Tasks') {
      return AnimatedBuilder(
        animation: _tasksAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(28, 28),
            painter: TasksIconPainter(
              color: const Color(0xFF6FB8E9),
              isFilled: isSelected, // Filled when selected, outlined when not
              strokeWidth: 1.5,
              backgroundColor: const Color(
                  0xFF1C1F35), // Purple background for transparent effect
              animationProgress: isSelected
                  ? _tasksAnimation.value
                  : 0.0, // Only animate when selected
            ),
          );
        },
      );
    }

    // For Stats button, use animated bar chart with smooth transition
    if (label == 'Stats') {
      return AnimatedBuilder(
        animation: _statsIconAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(28, 28),
            painter: AnimatedBarChartPainter(
              color: const Color(0xFF6FB8E9),
              animationProgress: isSelected ? _statsIconAnimation.value : 0.0,
              strokeWidth: 1.5,
              isFilled: isSelected, // Filled when selected, outlined when not
            ),
          );
        },
      );
    }

    // For Learn button, use custom graduation cap icon with tassel sway animation
    if (label == 'Learn') {
      // Check if animation is initialized
      if (_learnIconAnimation == null) {
        return CustomPaint(
          size: const Size(28, 28),
          painter: GraduationCapPainter(
            color: isSelected 
              ? const Color(0xFF6FB8E9)
              : const Color(0xFFCFCFCF),
            isFilled: isSelected,
            strokeWidth: 1.5,
            animationValue: 0.0,
          ),
        );
      }
      
      return AnimatedBuilder(
        animation: _learnIconAnimation!,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(28, 28),
            painter: GraduationCapPainter(
              color: isSelected 
                ? const Color(0xFF6FB8E9) // Blue when selected
                : const Color(0xFFCFCFCF), // Gray when not selected
              isFilled: isSelected, // Filled when selected, outlined when not
              strokeWidth: 1.5,
              animationValue: isSelected ? _learnIconAnimation!.value : 0.0, // Only animate when selected
            ),
          );
        },
      );
    }

    // For Social button, use custom users/people icon with hugging animation
    if (label == 'Social') {
      return AnimatedBuilder(
        animation: _socialIconAnimation,
        builder: (context, child) {
          return CustomPaint(
            size: const Size(28, 28),
            painter: SocialIconPainter(
              color: isSelected 
                ? const Color(0xFF6FB8E9) // Blue when selected
                : const Color(0xFFCFCFCF), // Gray when not selected
              isFilled: isSelected, // Filled when selected, outlined when not
              strokeWidth: 1.5,
              animationValue: _socialIconAnimation.value, // Add hugging animation
            ),
          );
        },
      );
    }

    // For Pet button, use custom paw icon with animated overlay
    if (label == 'Pet') {
      return AnimatedBuilder(
        animation: _petIconAnimation,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Base paw icon using custom painter
              CustomPaint(
                size: const Size(32, 32),
                painter: AnimatedPawsPainter(
                  color: isSelected 
                    ? const Color(0xFF6FB8E9) // Blue when selected
                    : const Color(0xFFCFCFCF), // Gray when not selected
                  animationProgress: 0.0, // No animation for base icon
                  isFilled:
                      isSelected, // Filled when selected, outlined when not
                  strokeWidth: 1.5,
                ),
              ),
              // Animated paw prints overlay (only when selected and animating)
              if (isSelected && _petIconAnimation.value > 0.0)
                CustomPaint(
                  size: const Size(32, 32),
                  painter: AnimatedPawsPainter(
                    color: const Color(0xFF6FB8E9), // Blue for animation overlay
                    animationProgress: _petIconAnimation.value,
                    isFilled: true, // Filled when selected
                    strokeWidth: 1.5,
                  ),
                ),
            ],
          );
        },
      );
    }

    // For other buttons, use blue for selected and gray for non-selected
    Color iconColor;
    if (label == 'AI Tutor' && isSelected) {
      iconColor = Colors.white; // White icon on blue background
    } else if (label == 'AI Tutor') {
      iconColor = const Color(0xFF6FB8E9); // Blue when not selected
    } else if (isSelected) {
      iconColor = const Color(0xFF6FB8E9); // Blue when selected
    } else {
      iconColor = const Color(0xFFCFCFCF); // Gray when not selected
    }

    return Icon(
      icon,
      size: label == 'AI Tutor' && isSelected ? 32 : 28, // Larger size for selected AI Tutor
      color: iconColor,
    );
  }
}

/// Screen for calendar/planning functionality
/// Shows a calendar and task management interface
class PlannerScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        onGenerateRoute: (settings) {
          return MaterialPageRoute(
            builder: (context) => const PlannerPage(),
            settings: settings,
          );
        },
      ),
    );
  }
}

/// Enhanced notes screen with task integration and filtering options
/// Displays both notes and tasks with filtering capabilities
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Load data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final noteProvider = Provider.of<NoteProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final questProvider =
          Provider.of<DailyQuestProvider>(context, listen: false);
      noteProvider.loadNotes();
      taskProvider.loadTasks();
      questProvider.loadTodaysQuests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notes & Tasks'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.note), text: 'Notes'),
            Tab(icon: Icon(Icons.task_alt), text: 'Tasks'),
            Tab(icon: Icon(Icons.emoji_events), text: 'Quests'),
            Tab(icon: Icon(Icons.view_agenda), text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search notes and tasks...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildNotesTab(),
                _buildTasksTab(),
                _buildQuestsTab(),
                _buildAllTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build notes-only tab
  Widget _buildNotesTab() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        if (noteProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredNotes = noteProvider.searchNotes(_searchQuery);

        if (filteredNotes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.note,
            title: _searchQuery.isEmpty ? 'No notes yet' : 'No notes found',
            subtitle: _searchQuery.isEmpty
                ? 'Create your first study note'
                : 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredNotes.length,
          itemBuilder: (context, index) {
            final note = filteredNotes[index];
            return _buildNoteCard(note);
          },
        );
      },
    );
  }

  /// Build tasks-only tab
  Widget _buildTasksTab() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        if (taskProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredTasks = taskProvider.searchTasks(_searchQuery);

        if (filteredTasks.isEmpty) {
          return _buildEmptyState(
            icon: Icons.task_alt,
            title: _searchQuery.isEmpty ? 'No tasks yet' : 'No tasks found',
            subtitle: _searchQuery.isEmpty
                ? 'Create your first task'
                : 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredTasks.length,
          itemBuilder: (context, index) {
            final task = filteredTasks[index];
            return _buildTaskCard(task);
          },
        );
      },
    );
  }

  /// Build quests-only tab
  Widget _buildQuestsTab() {
    return Consumer<DailyQuestProvider>(
      builder: (context, questProvider, child) {
        if (questProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredQuests = questProvider.quests.where((quest) {
          if (_searchQuery.isEmpty) return true;
          final lowerQuery = _searchQuery.toLowerCase();
          return quest.title.toLowerCase().contains(lowerQuery) ||
              quest.description.toLowerCase().contains(lowerQuery) ||
              quest.type.displayName.toLowerCase().contains(lowerQuery);
        }).toList();

        if (filteredQuests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.emoji_events,
            title: _searchQuery.isEmpty ? 'No quests today' : 'No quests found',
            subtitle: _searchQuery.isEmpty
                ? 'Daily quests will be generated automatically'
                : 'Try a different search term',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: filteredQuests.length,
          itemBuilder: (context, index) {
            final quest = filteredQuests[index];
            return _buildQuestCard(quest, questProvider);
          },
        );
      },
    );
  }

  /// Build combined notes, tasks, and quests tab
  Widget _buildAllTab() {
    return Consumer3<NoteProvider, TaskProvider, DailyQuestProvider>(
      builder: (context, noteProvider, taskProvider, questProvider, child) {
        if (noteProvider.isLoading ||
            taskProvider.isLoading ||
            questProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final filteredNotes = noteProvider.searchNotes(_searchQuery);
        final filteredTasks = taskProvider.searchTasks(_searchQuery);

        // Filter quests based on search query
        final filteredQuests = questProvider.quests.where((quest) {
          if (_searchQuery.isEmpty) return true;
          final lowerQuery = _searchQuery.toLowerCase();
          return quest.title.toLowerCase().contains(lowerQuery) ||
              quest.description.toLowerCase().contains(lowerQuery) ||
              quest.type.displayName.toLowerCase().contains(lowerQuery);
        }).toList();

        if (filteredNotes.isEmpty &&
            filteredTasks.isEmpty &&
            filteredQuests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.view_agenda,
            title: _searchQuery.isEmpty ? 'No content yet' : 'No results found',
            subtitle: _searchQuery.isEmpty
                ? 'Create notes, tasks, or complete quests to get started'
                : 'Try a different search term',
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Daily Quests section
            if (filteredQuests.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Daily Quests (${filteredQuests.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange.shade700,
                      ),
                ),
              ),
              ...filteredQuests
                  .map((quest) => _buildQuestCard(quest, questProvider)),
              const SizedBox(height: 16),
            ],

            // Notes section
            if (filteredNotes.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Notes (${filteredNotes.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                ),
              ),
              ...filteredNotes.map((note) => _buildNoteCard(note)),
              const SizedBox(height: 16),
            ],

            // Tasks section
            if (filteredTasks.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Tasks (${filteredTasks.length})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                ),
              ),
              ...filteredTasks.map((task) => _buildTaskCard(task)),
            ],
          ],
        );
      },
    );
  }

  /// Build note card widget
  Widget _buildNoteCard(Note note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Icon(Icons.note, color: Colors.blue.shade700),
        ),
        title: Text(
          note.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (note.contentMd.isNotEmpty)
              Text(
                note.contentMd.length > 100
                    ? '${note.contentMd.substring(0, 100)}...'
                    : note.contentMd,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (note.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: note.tags
                    .take(3)
                    .map(
                      (tag) => Chip(
                        label: Text(tag,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.blue,
                                fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.blue.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: Text(
          _formatDate(note.updatedAt),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        onTap: () => _editNote(note),
      ),
    );
  }

  /// Build task card widget
  Widget _buildTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              _getTaskStatusColor(task.status).withValues(alpha: 0.2),
          child: Icon(
            _getTaskStatusIcon(task.status),
            color: _getTaskStatusColor(task.status),
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  '${task.estMinutes} min',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                if (task.dueAt != null) ...[
                  const SizedBox(width: 16),
                  Icon(Icons.schedule, size: 14, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(task.dueAt!),
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: task.tags
                    .take(3)
                    .map(
                      (tag) => Chip(
                        label: Text(tag,
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.green,
                                fontWeight: FontWeight.w600)),
                        backgroundColor: Colors.green.shade50,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
        trailing: _buildPriorityIndicator(task.priority),
        onTap: () => _editTask(task),
      ),
    );
  }

  /// Build a quest card widget
  Widget _buildQuestCard(DailyQuest quest, DailyQuestProvider questProvider) {
    final progressPercent = quest.currentProgress / quest.targetCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleQuestTap(quest, questProvider),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: quest.isCompleted
                          ? Colors.green.withValues(alpha: 0.1)
                          : _getQuestTypeColor(quest.type)
                              .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      quest.isCompleted
                          ? Icons.check_circle
                          : _getQuestTypeIcon(quest.type),
                      color: quest.isCompleted
                          ? Colors.green
                          : _getQuestTypeColor(quest.type),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quest.title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    decoration: quest.isCompleted
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quest.description,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '${quest.expReward}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!quest.isCompleted) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progressPercent,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getQuestTypeColor(quest.type),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${quest.currentProgress}/${quest.targetCount}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Handle quest card tap
  void _handleQuestTap(DailyQuest quest, DailyQuestProvider questProvider) {
    // Show quest details dialog or navigate to appropriate screen
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                _getQuestTypeIcon(quest.type),
                color: _getQuestTypeColor(quest.type),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(quest.title)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(quest.description),
              const SizedBox(height: 16),
              if (!quest.isCompleted) ...[
                Text(
                  'Progress: ${quest.currentProgress}/${quest.targetCount}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: quest.currentProgress / quest.targetCount,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getQuestTypeColor(quest.type),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    '${quest.expReward} XP Reward',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            if (!quest.isCompleted &&
                quest.currentProgress >= quest.targetCount)
              ElevatedButton(
                onPressed: () {
                  questProvider.completeQuest(quest.id);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Quest completed! +${quest.expReward} XP'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Complete Quest'),
              ),
          ],
        );
      },
    );
  }

  /// Get quest type icon
  IconData _getQuestTypeIcon(QuestType type) {
    switch (type) {
      case QuestType.study:
        return Icons.school;
      case QuestType.quiz:
        return Icons.quiz;
      case QuestType.streak:
        return Icons.local_fire_department;
      case QuestType.perfectScore:
        return Icons.star;
      case QuestType.timeSpent:
        return Icons.access_time;
      case QuestType.newCards:
        return Icons.new_releases;
      case QuestType.review:
        return Icons.refresh;
    }
  }

  /// Get quest type color
  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.study:
        return Colors.blue;
      case QuestType.quiz:
        return Colors.purple;
      case QuestType.streak:
        return Colors.orange;
      case QuestType.perfectScore:
        return Colors.yellow[700]!;
      case QuestType.timeSpent:
        return Colors.teal;
      case QuestType.newCards:
        return Colors.green;
      case QuestType.review:
        return Colors.indigo;
    }
  }

  /// Build empty state widget
  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade500,
                ),
          ),
        ],
      ),
    );
  }

  /// Build priority indicator widget
  Widget _buildPriorityIndicator(int priority) {
    Color color;
    String text;

    switch (priority) {
      case 3:
        color = Colors.red;
        text = 'HIGH';
        break;
      case 2:
        color = Colors.orange;
        text = 'MED';
        break;
      default:
        color = Colors.green;
        text = 'LOW';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Get task status color
  Color _getTaskStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get task status icon
  IconData _getTaskStatusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.completed:
        return Icons.check_circle;
      case TaskStatus.inProgress:
        return Icons.play_circle;
      case TaskStatus.cancelled:
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// Show create dialog for notes or tasks
  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New'),
        content: const Text('What would you like to create?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createNote();
            },
            child: const Text('Note'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _createTask();
            },
            child: const Text('Task'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Create new note
  void _createNote() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CreateNoteScreen(),
      ),
    )
        .then((result) {
      // Refresh the notes list if a note was successfully created
      if (result == true && mounted) {
        Provider.of<NoteProvider>(context, listen: false).loadNotes();
      }
    });
  }

  /// Create new task
  void _createTask() {
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => const CreateTaskScreen(),
      ),
    )
        .then((result) {
      // Refresh the tasks list if a task was successfully created
      if (result == true && mounted) {
        Provider.of<TaskProvider>(context, listen: false).loadTasks();
      }
    });
  }

  /// Edit existing note
  void _editNote(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final titleController = TextEditingController(text: note.title);
        final contentController = TextEditingController(text: note.contentMd);
        final tagsController =
            TextEditingController(text: note.tags.join(', '));

        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.note, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Note'),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tagsController,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Delete note
                Provider.of<NoteProvider>(context, listen: false)
                    .deleteNote(note.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Note deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedNote = note.copyWith(
                  title: titleController.text.trim(),
                  contentMd: contentController.text.trim(),
                  tags: tagsController.text
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty)
                      .toList(),
                  updatedAt: DateTime.now(),
                );

                Provider.of<NoteProvider>(context, listen: false)
                    .updateNote(updatedNote);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Note updated')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  /// Edit existing task
  void _editTask(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final titleController = TextEditingController(text: task.title);
        final tagsController =
            TextEditingController(text: task.tags.join(', '));
        final estMinutesController =
            TextEditingController(text: task.estMinutes.toString());
        TaskStatus selectedStatus = task.status;
        int selectedPriority = task.priority;
        DateTime? selectedDueDate = task.dueAt;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Row(
                children: [
                  Icon(
                    _getTaskStatusIcon(task.status),
                    color: _getTaskStatusColor(task.status),
                  ),
                  const SizedBox(width: 8),
                  const Text('Edit Task'),
                ],
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskStatus>(
                              initialValue: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Status',
                                border: OutlineInputBorder(),
                              ),
                              items: TaskStatus.values.map((status) {
                                return DropdownMenuItem(
                                  value: status,
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getTaskStatusIcon(status),
                                        color: _getTaskStatusColor(status),
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(status.name),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStatus = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<int>(
                              initialValue: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: 'Priority',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 1,
                                    child: Row(children: [
                                      Icon(Icons.low_priority,
                                          color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Low')
                                    ])),
                                DropdownMenuItem(
                                    value: 2,
                                    child: Row(children: [
                                      Icon(Icons.priority_high,
                                          color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Medium')
                                    ])),
                                DropdownMenuItem(
                                    value: 3,
                                    child: Row(children: [
                                      Icon(Icons.priority_high,
                                          color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('High')
                                    ])),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedPriority = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: estMinutesController,
                              decoration: const InputDecoration(
                                labelText: 'Estimated Minutes',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: tagsController,
                              decoration: const InputDecoration(
                                labelText: 'Tags (comma separated)',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDueDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDueDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  color: Theme.of(context).iconTheme.color),
                              const SizedBox(width: 8),
                              Text(
                                selectedDueDate != null
                                    ? 'Due: ${_formatDate(selectedDueDate!)}'
                                    : 'Set due date (optional)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              const Spacer(),
                              if (selectedDueDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 16),
                                  onPressed: () {
                                    setState(() {
                                      selectedDueDate = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Delete task
                    Provider.of<TaskProvider>(context, listen: false)
                        .deleteTask(task.id);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task deleted'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                  child:
                      const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
                ElevatedButton(
                  onPressed: () {
                    final updatedTask = task.copyWith(
                      title: titleController.text.trim(),
                      status: selectedStatus,
                      priority: selectedPriority,
                      estMinutes: int.tryParse(estMinutesController.text) ??
                          task.estMinutes,
                      dueAt: selectedDueDate,
                      tags: tagsController.text
                          .split(',')
                          .map((tag) => tag.trim())
                          .where((tag) => tag.isNotEmpty)
                          .toList(),
                    );

                    Provider.of<TaskProvider>(context, listen: false)
                        .updateTask(updatedTask);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Task updated')),
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Flashcard deck management screen
/// Shows all created decks including AI-generated ones
class DecksScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const DecksScreen({super.key});

  /// Builds the deck list interface
  /// @param context - Build context containing theme information
  /// @return Widget tree showing user's flashcard decks
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with descriptive screen title
      appBar: AppBar(title: const Text('Flashcard Decks')),

      // Consumer to listen to deck provider changes
      body: Consumer<DeckProvider>(
        builder: (context, deckProvider, child) {
          final decks = deckProvider.decks;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Flashcard Generator at the top
                const AIFlashcardGenerator(),

                const SizedBox(height: 24),

                // Flashcard Review section
                const DueCardsWidget(),

                const SizedBox(height: 24),

                // Decks section header
                Text(
                  'Your Decks',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),

                const SizedBox(height: 16),

                if (decks.isEmpty)
                  // Show empty state when no decks exist
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.style, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'No decks yet!',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Create flashcards using the AI Generator above.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                else
                  // Show list of decks
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: decks.length,
                    itemBuilder: (context, index) {
                      final deck = decks[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.style, color: Colors.white),
                          ),
                          title: Text(
                            deck.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${deck.cards.length} cards'),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: deck.tags
                                    .map((tag) => Chip(
                                          label: Text(
                                            tag,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.indigo,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          backgroundColor:
                                              Colors.indigo.shade50,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                        ))
                                    .toList(),
                              ),
                            ],
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Navigate to flashcard study screen
                            if (deck.cards.isNotEmpty) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      FlashcardStudyScreen(deck: deck),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Deck "${deck.title}" has no cards to study'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder screen for progress tracking and analytics
/// Will be replaced with charts, statistics, and achievement tracking
class ProgressScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const ProgressScreen({super.key});

  /// Builds placeholder content indicating feature is coming soon
  /// @param context - Build context containing theme information
  /// @return Widget tree showing placeholder content
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with descriptive screen title
      appBar: AppBar(title: const Text('Progress')),

      // Centered placeholder content
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          children: [
            // Large analytics icon to indicate progress tracking functionality
            const Icon(Icons.insights, size: 64, color: Colors.grey),

            // Spacing between icon and text
            const SizedBox(height: 16),

            // Coming soon message with appropriate text style
            Text('Progress tracking coming soon!',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

/// Simple flashcard viewer for studying decks
class SimpleFlashcardViewer extends StatefulWidget {
  final Deck deck;

  const SimpleFlashcardViewer({
    super.key,
    required this.deck,
  });

  @override
  State<SimpleFlashcardViewer> createState() => _SimpleFlashcardViewerState();
}

class _SimpleFlashcardViewerState extends State<SimpleFlashcardViewer> {
  int _currentCardIndex = 0;
  bool _showAnswer = false;

  void _nextCard() {
    setState(() {
      if (_currentCardIndex < widget.deck.cards.length - 1) {
        _currentCardIndex++;
        _showAnswer = false;
      }
    });
  }

  void _previousCard() {
    setState(() {
      if (_currentCardIndex > 0) {
        _currentCardIndex--;
        _showAnswer = false;
      }
    });
  }

  void _toggleAnswer() {
    setState(() {
      _showAnswer = !_showAnswer;
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.deck.cards[_currentCardIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${widget.deck.title} - ${_currentCardIndex + 1}/${widget.deck.cards.length}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Card(
                  elevation: 8,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAnswer ? 'Answer:' : 'Question:',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _showAnswer ? card.back : card.front,
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: _toggleAnswer,
                          child: Text(
                              _showAnswer ? 'Show Question' : 'Show Answer'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _currentCardIndex > 0 ? _previousCard : null,
                  child: const Text('Previous'),
                ),
                Text(
                  '${_currentCardIndex + 1} / ${widget.deck.cards.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ElevatedButton(
                  onPressed: _currentCardIndex < widget.deck.cards.length - 1
                      ? _nextCard
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for settings gear icon using SVG path
class SettingsGearPainter extends CustomPainter {
  final Color? color;

  SettingsGearPainter({this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color ?? Colors.grey.shade600
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Convert SVG path to Flutter coordinates
    // SVG viewBox is 0 0 24 24, so we scale to our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Outer gear path: M10.343 3.94c.09-.542.56-.94 1.11-.94h1.093c.55 0 1.02.398 1.11.94l.149.894...
    path.moveTo(10.343 * scaleX, 3.94 * scaleY);

    // Top gear tooth
    path.cubicTo(
      10.433 * scaleX,
      3.398 * scaleY,
      10.903 * scaleX,
      3.0 * scaleY,
      11.453 * scaleX,
      3.0 * scaleY,
    );
    path.lineTo(12.546 * scaleX, 3.0 * scaleY);
    path.cubicTo(
      13.096 * scaleX,
      3.0 * scaleY,
      13.566 * scaleX,
      3.398 * scaleY,
      13.656 * scaleX,
      3.94 * scaleY,
    );

    // Top right curve
    path.lineTo(13.805 * scaleX, 4.834 * scaleY);
    path.cubicTo(
      13.875 * scaleX,
      5.258 * scaleY,
      14.189 * scaleX,
      5.598 * scaleY,
      14.585 * scaleX,
      5.764 * scaleY,
    );
    path.cubicTo(
      14.983 * scaleX,
      5.928 * scaleY,
      15.44 * scaleX,
      5.906 * scaleY,
      15.79 * scaleX,
      5.656 * scaleY,
    );

    // Right gear tooth
    path.lineTo(16.527 * scaleX, 5.129 * scaleY);
    path.cubicTo(
      16.977 * scaleX,
      4.449 * scaleY,
      17.587 * scaleX,
      4.499 * scaleY,
      17.977 * scaleX,
      4.579 * scaleY,
    );
    path.lineTo(18.75 * scaleX, 5.353 * scaleY);
    path.cubicTo(
      19.14 * scaleX,
      5.742 * scaleY,
      19.19 * scaleX,
      6.355 * scaleY,
      18.87 * scaleX,
      6.803 * scaleY,
    );

    // Continue the gear outline...
    // Right side continuing clockwise
    path.lineTo(18.343 * scaleX, 7.54 * scaleY);
    path.cubicTo(
      18.093 * scaleX,
      7.89 * scaleY,
      18.071 * scaleX,
      8.346 * scaleY,
      18.236 * scaleX,
      8.744 * scaleY,
    );
    path.cubicTo(
      18.401 * scaleX,
      9.141 * scaleY,
      18.741 * scaleX,
      9.454 * scaleY,
      19.166 * scaleX,
      9.524 * scaleY,
    );

    // Right gear extension
    path.lineTo(20.059 * scaleX, 9.673 * scaleY);
    path.cubicTo(
      20.601 * scaleX,
      9.763 * scaleY,
      20.999 * scaleX,
      10.232 * scaleY,
      20.999 * scaleX,
      10.782 * scaleY,
    );
    path.lineTo(20.999 * scaleX, 11.876 * scaleY);
    path.cubicTo(
      20.999 * scaleX,
      12.426 * scaleY,
      20.601 * scaleX,
      12.896 * scaleY,
      20.059 * scaleX,
      12.986 * scaleY,
    );

    // Bottom right
    path.lineTo(19.165 * scaleX, 13.135 * scaleY);
    path.cubicTo(
      18.741 * scaleX,
      13.205 * scaleY,
      18.401 * scaleX,
      13.518 * scaleY,
      18.236 * scaleX,
      13.915 * scaleY,
    );
    path.cubicTo(
      18.071 * scaleX,
      14.313 * scaleY,
      18.093 * scaleX,
      14.769 * scaleY,
      18.343 * scaleX,
      15.119 * scaleY,
    );

    // Bottom gear tooth
    path.lineTo(18.87 * scaleX, 15.857 * scaleY);
    path.cubicTo(
      19.19 * scaleX,
      16.304 * scaleY,
      19.14 * scaleX,
      16.917 * scaleY,
      18.75 * scaleX,
      17.307 * scaleY,
    );
    path.lineTo(17.977 * scaleX, 18.08 * scaleY);
    path.cubicTo(
      17.587 * scaleX,
      18.469 * scaleY,
      16.977 * scaleX,
      18.519 * scaleY,
      16.527 * scaleX,
      18.199 * scaleY,
    );

    // Continue back to starting point (simplified for brevity)
    path.lineTo(15.79 * scaleX, 17.672 * scaleY);
    path.cubicTo(
      15.44 * scaleX,
      17.422 * scaleY,
      14.983 * scaleX,
      17.4 * scaleY,
      14.585 * scaleX,
      17.564 * scaleY,
    );
    path.cubicTo(
      14.189 * scaleX,
      17.73 * scaleY,
      13.875 * scaleX,
      18.07 * scaleY,
      13.805 * scaleX,
      18.494 * scaleY,
    );

    // Bottom
    path.lineTo(13.656 * scaleX, 19.388 * scaleY);
    path.cubicTo(
      13.566 * scaleX,
      19.93 * scaleY,
      13.096 * scaleX,
      20.328 * scaleY,
      12.546 * scaleX,
      20.328 * scaleY,
    );
    path.lineTo(11.453 * scaleX, 20.328 * scaleY);
    path.cubicTo(
      10.903 * scaleX,
      20.328 * scaleY,
      10.433 * scaleX,
      19.93 * scaleY,
      10.343 * scaleX,
      19.388 * scaleY,
    );

    // Continue back up left side
    path.lineTo(10.194 * scaleX, 18.494 * scaleY);
    path.cubicTo(
      10.124 * scaleX,
      18.07 * scaleY,
      9.81 * scaleX,
      17.73 * scaleY,
      9.413 * scaleX,
      17.564 * scaleY,
    );
    path.cubicTo(
      9.015 * scaleX,
      17.4 * scaleY,
      8.559 * scaleX,
      17.422 * scaleY,
      8.209 * scaleX,
      17.672 * scaleY,
    );

    // Left gear tooth
    path.lineTo(7.472 * scaleX, 18.199 * scaleY);
    path.cubicTo(
      7.025 * scaleX,
      18.519 * scaleY,
      6.412 * scaleX,
      18.469 * scaleY,
      6.023 * scaleX,
      18.08 * scaleY,
    );
    path.lineTo(5.25 * scaleX, 17.307 * scaleY);
    path.cubicTo(
      4.86 * scaleX,
      16.917 * scaleY,
      4.81 * scaleX,
      16.304 * scaleY,
      5.13 * scaleX,
      15.857 * scaleY,
    );

    // Complete the path back to start
    path.lineTo(5.657 * scaleX, 15.119 * scaleY);
    path.cubicTo(
      5.907 * scaleX,
      14.769 * scaleY,
      5.929 * scaleX,
      14.313 * scaleY,
      5.764 * scaleX,
      13.915 * scaleY,
    );
    path.cubicTo(
      5.599 * scaleX,
      13.518 * scaleY,
      5.259 * scaleX,
      13.205 * scaleY,
      4.834 * scaleX,
      13.135 * scaleY,
    );

    // Left extension
    path.lineTo(3.94 * scaleX, 12.986 * scaleY);
    path.cubicTo(
      3.398 * scaleX,
      12.896 * scaleY,
      3.0 * scaleX,
      12.426 * scaleY,
      3.0 * scaleX,
      11.876 * scaleY,
    );
    path.lineTo(3.0 * scaleX, 10.782 * scaleY);
    path.cubicTo(
      3.0 * scaleX,
      10.232 * scaleY,
      3.398 * scaleX,
      9.763 * scaleY,
      3.94 * scaleX,
      9.673 * scaleY,
    );

    // Back up left side
    path.lineTo(4.834 * scaleX, 9.524 * scaleY);
    path.cubicTo(
      5.259 * scaleX,
      9.454 * scaleY,
      5.599 * scaleX,
      9.141 * scaleY,
      5.764 * scaleX,
      8.744 * scaleY,
    );
    path.cubicTo(
      5.929 * scaleX,
      8.346 * scaleY,
      5.907 * scaleX,
      7.89 * scaleY,
      5.657 * scaleX,
      7.54 * scaleY,
    );

    path.lineTo(5.13 * scaleX, 6.803 * scaleY);
    path.cubicTo(
      4.81 * scaleX,
      6.355 * scaleY,
      4.86 * scaleX,
      5.742 * scaleY,
      5.25 * scaleX,
      5.353 * scaleY,
    );
    path.lineTo(6.023 * scaleX, 4.579 * scaleY);
    path.cubicTo(
      6.412 * scaleX,
      4.19 * scaleY,
      7.025 * scaleX,
      4.14 * scaleY,
      7.472 * scaleX,
      4.46 * scaleY,
    );

    path.lineTo(8.209 * scaleX, 4.987 * scaleY);
    path.cubicTo(
      8.559 * scaleX,
      5.237 * scaleY,
      9.015 * scaleX,
      5.259 * scaleY,
      9.413 * scaleX,
      5.094 * scaleY,
    );
    path.cubicTo(
      9.81 * scaleX,
      4.929 * scaleY,
      10.124 * scaleX,
      4.589 * scaleY,
      10.194 * scaleX,
      4.165 * scaleY,
    );

    path.close();

    canvas.drawPath(path, paint);

    // Draw the inner circle: M15 12a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z
    final innerPath = Path();
    final centerX = 12 * scaleX;
    final centerY = 12 * scaleY;
    final radius = 3 * scaleX;

    innerPath.addOval(Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: radius,
    ));

    canvas.drawPath(innerPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

/// Custom painter for home icon with outlined and filled states plus hover-pinch animation
/// Based on comprehensive home icon design with roof, walls, windows, and door elements
class AnimatedHomeIconPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double animationProgress; // 0.0 to 1.0 for hover-pinch animation
  final double strokeWidth;

  AnimatedHomeIconPainter({
    required this.color,
    required this.isFilled,
    required this.animationProgress,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale factors based on the SVG viewBox (24x24) to fit our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Apply hover-pinch animation to the entire house
    final center = Offset(size.width / 2, size.height / 2);
    final pinchScale =
        1.0 - (animationProgress * 0.05); // Subtle 5% pinch effect

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pinchScale);
    canvas.translate(-center.dx, -center.dy);

    if (isFilled) {
      // Filled version using exact SVG paths with door animation
      paint.style = PaintingStyle.fill;

      // Door animation progress - starts open, closes in middle, opens again
      double doorProgress;
      if (animationProgress <= 0.33) {
        // Phase 1: Door closes from open to closed (0-33%)
        doorProgress = 1.0 - (animationProgress / 0.33); // 1.0 to 0.0
      } else if (animationProgress <= 0.66) {
        // Phase 2: Door stays closed (33-66%)
        doorProgress = 0.0;
      } else {
        // Phase 3: Door opens from closed to open (66-100%)
        doorProgress = (animationProgress - 0.66) / (1.0 - 0.66); // 0.0 to 1.0
      }

      // First SVG path: d="M11.47 3.841a.75.75 0 0 1 1.06 0l8.69 8.69a.75.75 0 1 0 1.06-1.061l-8.689-8.69a2.25 2.25 0 0 0-3.182 0l-8.69 8.69a.75.75 0 1 0 1.061 1.06l8.69-8.689Z"
      final roofPath = Path();

      // Starting point M11.47 3.841
      roofPath.moveTo(11.47 * scaleX, 3.841 * scaleY);

      // Arc curve a.75.75 0 0 1 1.06 0 - simplified as line to end point
      roofPath.lineTo(12.53 * scaleX, 3.841 * scaleY); // 11.47 + 1.06 = 12.53

      // Line l8.69 8.69
      roofPath.lineTo(21.22 * scaleX,
          12.531 * scaleY); // 12.53 + 8.69 = 21.22, 3.841 + 8.69 = 12.531

      // Arc a.75.75 0 1 0 1.06-1.061 - simplified as line
      roofPath.lineTo(22.28 * scaleX,
          11.47 * scaleY); // 21.22 + 1.06 = 22.28, 12.531 - 1.061 = 11.47

      // Line l-8.689-8.69
      roofPath.lineTo(13.591 * scaleX,
          2.78 * scaleY); // 22.28 - 8.689 = 13.591, 11.47 - 8.69 = 2.78

      // Arc a2.25 2.25 0 0 0-3.182 0 - simplified as line
      roofPath.lineTo(
          10.409 * scaleX, 2.78 * scaleY); // 13.591 - 3.182 = 10.409

      // Line l-8.69 8.69
      roofPath.lineTo(1.719 * scaleX,
          11.47 * scaleY); // 10.409 - 8.69 = 1.719, 2.78 + 8.69 = 11.47

      // Arc a.75.75 0 1 0 1.061 1.06 - simplified as line
      roofPath.lineTo(2.78 * scaleX,
          12.531 * scaleY); // 1.719 + 1.061 = 2.78, 11.47 + 1.06 = 12.531

      // Line l8.69-8.689 back to start - Z closes the path
      roofPath.lineTo(
          11.47 * scaleX,
          3.841 *
              scaleY); // 2.78 + 8.69 = 11.47, 12.531 - 8.689 = 3.842 ≈ 3.841

      roofPath.close();
      canvas.drawPath(roofPath, paint);

      // Second SVG path: d="m12 5.432 8.159 8.159c.03.03.06.058.091.086v6.198c0 1.035-.84 1.875-1.875 1.875H15a.75.75 0 0 1-.75-.75v-4.5a.75.75 0 0 0-.75-.75h-3a.75.75 0 0 0-.75.75V21a.75.75 0 0 1-.75.75H5.625a1.875 1.875 0 0 1-1.875-1.875v-6.198a2.29 2.29 0 0 0 .091-.086L12 5.432Z"
      final housePath = Path();

      // Starting point m12 5.432
      housePath.moveTo(12 * scaleX, 5.432 * scaleY);

      // Line l8.159 8.159
      housePath.lineTo(20.159 * scaleX,
          13.591 * scaleY); // 12 + 8.159 = 20.159, 5.432 + 8.159 = 13.591

      // Curve c.03.03.06.058.091.086 - simplified as small offset
      housePath.lineTo(20.25 * scaleX,
          13.677 * scaleY); // 20.159 + 0.091 = 20.25, 13.591 + 0.086 = 13.677

      // Vertical line v6.198
      housePath.lineTo(
          20.25 * scaleX, 19.875 * scaleY); // 13.677 + 6.198 = 19.875

      // House right side with rounded corner - c0 1.035-.84 1.875-1.875 1.875
      housePath.lineTo(18.375 * scaleX,
          21.75 * scaleY); // 20.25 - 1.875 = 18.375, 19.875 + 1.875 = 21.75
      housePath.lineTo(15 * scaleX, 21.75 * scaleY); // H15

      // Right door frame - a.75.75 0 0 1-.75-.75
      housePath.lineTo(
          14.25 * scaleX, 21 * scaleY); // 15 - 0.75 = 14.25, 21.75 - 0.75 = 21

      // Create animated door opening by modifying the path
      final doorTopY = 21 - (4.5 * doorProgress); // Animate door from bottom up
      housePath.lineTo(14.25 * scaleX, doorTopY * scaleY); // v-4.5 animated

      // Door top - a.75.75 0 0 0-.75-.75
      housePath.lineTo(13.5 * scaleX,
          doorTopY * scaleY - 0.75 * scaleY); // 14.25 - 0.75 = 13.5

      // Door top edge - h-3
      housePath.lineTo(
          10.5 * scaleX, doorTopY * scaleY - 0.75 * scaleY); // 13.5 - 3 = 10.5

      // Left door frame - a.75.75 0 0 0-.75.75
      housePath.lineTo(9.75 * scaleX, doorTopY * scaleY); // 10.5 - 0.75 = 9.75

      // Left door side animated
      housePath.lineTo(9.75 * scaleX, 21 * scaleY); // Back down to V21

      // Left side of house - a.75.75 0 0 1-.75.75
      housePath.lineTo(
          9 * scaleX, 21.75 * scaleY); // 9.75 - 0.75 = 9, 21 + 0.75 = 21.75

      // House left side - H5.625
      housePath.lineTo(5.625 * scaleX, 21.75 * scaleY);

      // Left wall with rounded corner - a1.875 1.875 0 0 1-1.875-1.875
      housePath.lineTo(3.75 * scaleX,
          19.875 * scaleY); // 5.625 - 1.875 = 3.75, 21.75 - 1.875 = 19.875

      // Left wall up - v-6.198
      housePath.lineTo(
          3.75 * scaleX, 13.677 * scaleY); // 19.875 - 6.198 = 13.677

      // Small curve back to start - a2.29 2.29 0 0 0 .091-.086
      housePath.lineTo(3.841 * scaleX,
          13.591 * scaleY); // 3.75 + 0.091 = 3.841, 13.677 - 0.086 = 13.591

      // Line back to start - L12 5.432
      housePath.lineTo(12 * scaleX, 5.432 * scaleY);

      housePath.close();
      canvas.drawPath(housePath, paint);
    } else {
      // Outlined version: draw stroke paths with perfect connectivity
      paint.style = PaintingStyle.stroke;

      // First draw the roof outline above the house (matching selected version)
      final roofOutlinePath = Path();
      roofOutlinePath.moveTo(2.25 * scaleX, 12 * scaleY); // Start from far left
      roofOutlinePath.lineTo(
          11.204 * scaleX, 3.045 * scaleY); // Left roof line up to peak

      // Curved peak section
      roofOutlinePath.cubicTo(
        11.644 * scaleX,
        2.606 * scaleY,
        12.356 * scaleX,
        2.606 * scaleY,
        12.795 * scaleX,
        3.045 * scaleY,
      );

      roofOutlinePath.lineTo(
          21.75 * scaleX, 12 * scaleY); // Right roof line down to far right
      canvas.drawPath(roofOutlinePath, paint);

      // Main house body with perfect connectivity
      final housePath = Path();

      // Start from bottom left corner
      housePath.moveTo(4.5 * scaleX, 19.875 * scaleY);

      // Left wall up
      housePath.lineTo(4.5 * scaleX, 9.75 * scaleY);

      // Left roof line to peak (ensuring perfect connection)
      housePath.lineTo(11.204 * scaleX, 3.045 * scaleY);

      // Curved peak section - ensuring smooth connection
      housePath.cubicTo(
        11.644 * scaleX,
        2.606 * scaleY,
        12.356 * scaleX,
        2.606 * scaleY,
        12.795 * scaleX,
        3.045 * scaleY,
      );

      // Right roof line down (perfectly connected)
      housePath.lineTo(19.5 * scaleX, 9.75 * scaleY);

      // Right wall down
      housePath.lineTo(19.5 * scaleX, 19.875 * scaleY);

      // Right side of house with rounded corner
      housePath.lineTo(18.375 * scaleX,
          21 * scaleY); // c.621 0 1.125-.504 1.125-1.125 approximation

      // Right door frame
      housePath.lineTo(14.25 * scaleX, 21 * scaleY);
      housePath.lineTo(14.25 * scaleX, 15 * scaleY); // v-4.875 door frame up

      // Door top with rounded corners
      housePath.lineTo(13.125 * scaleX, 15 * scaleY); // h-1.125
      housePath.lineTo(10.875 * scaleX, 15 * scaleY); // h-2.25 door width
      housePath.lineTo(9.75 * scaleX, 15 * scaleY); // h-1.125

      // Left door frame down
      housePath.lineTo(9.75 * scaleX, 21 * scaleY); // V21

      // Left side of house
      housePath.lineTo(5.625 * scaleX, 21 * scaleY); // H5.625
      housePath.lineTo(
          4.5 * scaleX, 19.875 * scaleY); // rounded corner back to start

      // Close the path for perfect connectivity
      housePath.close();

      canvas.drawPath(housePath, paint);

      // Draw the door bottom line separately to complete the door frame
      final doorBottomPath = Path();
      doorBottomPath.moveTo(9.75 * scaleX, 21 * scaleY);
      doorBottomPath.lineTo(14.25 * scaleX, 21 * scaleY);
      canvas.drawPath(doorBottomPath, paint);
    }

    canvas.restore(); // Restore canvas transformation
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is AnimatedHomeIconPainter &&
        (oldDelegate.isFilled != isFilled ||
            oldDelegate.color != color ||
            oldDelegate.animationProgress != animationProgress);
  }
}

/// Custom painter for EXACT JSON paw design with claw extension animation
/// Based on wired-lineal-448-paws-animal-morph-nails JSON specifications
class AnimatedPawsPainter extends CustomPainter {
  final Color color;
  final double animationProgress; // 0.0 to 1.0 for complete animation cycle
  final double strokeWidth;
  final bool isFilled; // Controls whether to show claws extended

  AnimatedPawsPainter({
    required this.color,
    required this.animationProgress,
    required this.isFilled,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Scale factors from SVG viewBox (430x430) to widget size
    final scaleX = size.width / 430;
    final scaleY = size.height / 430;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Apply hover-pinch animation to the entire paw
    final center = Offset(size.width / 2, size.height / 2);
    final pinchScale =
        1.0 - (animationProgress * 0.05); // Subtle 5% pinch effect

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(pinchScale);
    canvas.translate(-center.dx, -center.dy);

    if (isFilled) {
      paint.style = PaintingStyle.fill;

      // MAIN PAW PAD - same as outline version but filled
      final mainPadPath = Path();
      mainPadPath.moveTo((109.109 + 215) * scaleX, (130.262 + 215) * scaleY);
      mainPadPath.cubicTo(
        (109.109 + 215) * scaleX,
        (130.262 + 215 + 75.942) * scaleY,
        (109.109 + 215 - 69.674) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
        (109.109 + 215 - 101.565) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 - 33.341) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 + 59.64) * scaleY,
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 - 13.936) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 - 56.093) * scaleY,
        (109.109 + 215 - 101.565 - 101.565 + 45.472) * scaleX,
        (130.262 + 215 - 137.038) * scaleY,
        (109.109 + 215 - 101.565) * scaleX,
        (130.262 + 215 - 137.038) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 + 101.565) * scaleX,
        (130.262 + 215 - 137.038 + 80.945) * scaleY,
        (109.109 + 215) * scaleX,
        (130.262 + 215) * scaleY,
        (109.109 + 215) * scaleX,
        (130.262 + 215) * scaleY,
      );
      mainPadPath.close();
      canvas.drawPath(mainPadPath, paint);

      // FINGER PAD 1 - top left, same positioning as outline but filled with animated claws
      canvas.save();
      canvas.translate((215 - 120.015) * scaleX, (215 - 34.427) * scaleY);
      canvas.rotate(-20 * 3.14159 / 180);
      final pad1Path = Path();

      if (animationProgress > 0.0) {
        // Animated claw extending and retracting - creates a scratch motion
        // Progress: 0 → 0.5 (extend) → 1.0 (retract back)
        double clawProgress;
        if (animationProgress <= 0.5) {
          // First half: extend claws (0 to 1)
          clawProgress = animationProgress * 2;
        } else {
          // Second half: retract claws (1 back to 0)
          clawProgress = (1.0 - animationProgress) * 2;
        }

        final clawExtension = clawProgress * 18; // Scale the claw extension (reduced from 30 for much smaller, subtle claws)
        pad1Path.moveTo(32.645 * scaleX * 0.6, -109.234 * scaleY * 0.6);
        pad1Path.cubicTo(
          (32.645 - 0.736) * scaleX * 0.6,
          (-109.234 + 32.507) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
        );
        pad1Path.cubicTo(
          (-32.979) * scaleX * 0.6, (-110.72) * scaleY * 0.6,
          (-4.422) * scaleX * 0.6, (-168.263 - clawExtension) * scaleY * 0.6,
          (1.981) * scaleX * 0.6,
          (-191.461 * clawProgress) * scaleY * 0.6, // Extended claw tip
        );
        pad1Path.cubicTo(
          (6.739) * scaleX * 0.6,
          (-168.037) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
        );
        pad1Path.close();
      } else {
        // Regular oval when not animating
        pad1Path.addOval(Rect.fromCenter(
          center: const Offset(0, 0),
          width: 50 * scaleX,
          height: 90 * scaleY,
        ));
      }
      canvas.drawPath(pad1Path, paint);
      canvas.restore();

      // FINGER PAD 2 - same positioning as outline but filled with animated claws
      canvas.save();
      canvas.translate((215 - 46.985) * scaleX, (215 - 106.927) * scaleY);
      canvas.rotate(-14 * 3.14159 / 180);
      final pad2Path = Path();

      if (animationProgress > 0.0) {
        // Animated claw extending and retracting
        double clawProgress;
        if (animationProgress <= 0.5) {
          clawProgress = animationProgress * 2;
        } else {
          clawProgress = (1.0 - animationProgress) * 2;
        }

        final clawExtension = clawProgress * 18; // Reduced from 30 for much smaller, subtle claws
        pad2Path.moveTo(32.645 * scaleX * 0.6, -109.234 * scaleY * 0.6);
        pad2Path.cubicTo(
          (32.645 - 0.736) * scaleX * 0.6,
          (-109.234 + 32.507) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
        );
        pad2Path.cubicTo(
          (-32.979) * scaleX * 0.6,
          (-110.72) * scaleY * 0.6,
          (-4.422) * scaleX * 0.6,
          (-168.263 - clawExtension) * scaleY * 0.6,
          (1.981) * scaleX * 0.6,
          (-191.461 * clawProgress) * scaleY * 0.6,
        );
        pad2Path.cubicTo(
          (6.739) * scaleX * 0.6,
          (-168.037) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
        );
        pad2Path.close();
      } else {
        pad2Path.addOval(Rect.fromCenter(
          center: const Offset(0, 0),
          width: 50 * scaleX,
          height: 90 * scaleY,
        ));
      }
      canvas.drawPath(pad2Path, paint);
      canvas.restore();

      // FINGER PAD 3 - same positioning as outline but filled with animated claws
      canvas.save();
      canvas.translate((215 + 56.015) * scaleX, (215 - 112.427) * scaleY);
      canvas.rotate(6 * 3.14159 / 180);
      final pad3Path = Path();

      if (animationProgress > 0.0) {
        // Animated claw extending and retracting
        double clawProgress;
        if (animationProgress <= 0.5) {
          clawProgress = animationProgress * 2;
        } else {
          clawProgress = (1.0 - animationProgress) * 2;
        }

        final clawExtension = clawProgress * 18; // Reduced from 30 for much smaller, subtle claws
        pad3Path.moveTo(32.645 * scaleX * 0.6, -109.234 * scaleY * 0.6);
        pad3Path.cubicTo(
          (32.645 - 0.736) * scaleX * 0.6,
          (-109.234 + 32.507) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
        );
        pad3Path.cubicTo(
          (-32.979) * scaleX * 0.6,
          (-110.72) * scaleY * 0.6,
          (-4.422) * scaleX * 0.6,
          (-168.263 - clawExtension) * scaleY * 0.6,
          (1.981) * scaleX * 0.6,
          (-191.461 * clawProgress) * scaleY * 0.6,
        );
        pad3Path.cubicTo(
          (6.739) * scaleX * 0.6,
          (-168.037) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
        );
        pad3Path.close();
      } else {
        pad3Path.addOval(Rect.fromCenter(
          center: const Offset(0, 0),
          width: 50 * scaleX,
          height: 90 * scaleY,
        ));
      }
      canvas.drawPath(pad3Path, paint);
      canvas.restore();

      // FINGER PAD 4 - same positioning as outline but filled with animated claws
      canvas.save();
      canvas.translate((215 + 120.015) * scaleX, (215 - 34.427) * scaleY);
      canvas.rotate(20 * 3.14159 / 180);
      final pad4Path = Path();

      if (animationProgress > 0.0) {
        // Animated claw extending and retracting
        double clawProgress;
        if (animationProgress <= 0.5) {
          clawProgress = animationProgress * 2;
        } else {
          clawProgress = (1.0 - animationProgress) * 2;
        }

        final clawExtension = clawProgress * 18; // Reduced from 30 for much smaller, subtle claws
        pad4Path.moveTo(32.645 * scaleX * 0.6, -109.234 * scaleY * 0.6);
        pad4Path.cubicTo(
          (32.645 - 0.736) * scaleX * 0.6,
          (-109.234 + 32.507) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
          (-1.499) * scaleX * 0.6,
          (-51.118) * scaleY * 0.6,
        );
        pad4Path.cubicTo(
          (-32.979) * scaleX * 0.6,
          (-110.72) * scaleY * 0.6,
          (-4.422) * scaleX * 0.6,
          (-168.263 - clawExtension) * scaleY * 0.6,
          (1.981) * scaleX * 0.6,
          (-191.461 * clawProgress) * scaleY * 0.6,
        );
        pad4Path.cubicTo(
          (6.739) * scaleX * 0.6,
          (-168.037) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
          (32.645) * scaleX * 0.6,
          (-109.234) * scaleY * 0.6,
        );
        pad4Path.close();
      } else {
        pad4Path.addOval(Rect.fromCenter(
          center: const Offset(0, 0),
          width: 50 * scaleX,
          height: 90 * scaleY,
        ));
      }
      canvas.drawPath(pad4Path, paint);
      canvas.restore();
    } else {
      // OUTLINED STYLE - exact SVG stroke coordinates
      paint.style = PaintingStyle.stroke;
      paint.strokeWidth = 12.6 * scaleX; // SVG specifies stroke-width="12.6"

      // MAIN PAW PAD - exact outline SVG path coordinates
      // SVG: "M109.109 130.262c0 75.942-69.674 13.936-101.565 13.936-33.341 0-101.565 59.64-101.565-13.936 0-56.093 45.472-137.038 101.565-137.038s101.565 80.945 101.565 137.038"
      // with transform="translate(215 215)"
      final mainPadPath = Path();
      mainPadPath.moveTo((109.109 + 215) * scaleX, (130.262 + 215) * scaleY);
      mainPadPath.cubicTo(
        (109.109 + 215) * scaleX,
        (130.262 + 215 + 75.942) * scaleY,
        (109.109 + 215 - 69.674) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
        (109.109 + 215 - 101.565) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 - 33.341) * scaleX,
        (130.262 + 215 + 13.936) * scaleY,
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 + 59.64) * scaleY,
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 - 13.936) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 - 101.565) * scaleX,
        (130.262 + 215 - 56.093) * scaleY,
        (109.109 + 215 - 101.565 - 101.565 + 45.472) * scaleX,
        (130.262 + 215 - 137.038) * scaleY,
        (109.109 + 215 - 101.565) * scaleX,
        (130.262 + 215 - 137.038) * scaleY,
      );
      mainPadPath.cubicTo(
        (109.109 + 215 - 101.565 + 101.565) * scaleX,
        (130.262 + 215 - 137.038 + 80.945) * scaleY,
        (109.109 + 215) * scaleX,
        (130.262 + 215) * scaleY,
        (109.109 + 215) * scaleX,
        (130.262 + 215) * scaleY,
      );
      mainPadPath.close();
      canvas.drawPath(mainPadPath, paint);

      // FINGER PAD 1 - top left, mirroring the right side positioning
      canvas.save();
      canvas.translate((215 - 120.015) * scaleX,
          (215 - 34.427) * scaleY); // Mirror of FINGER PAD 4
      canvas.rotate(-20 *
          3.14159 /
          180); // Mirror rotation: -20 degrees (opposite of +20)
      final pad1Path = Path();
      pad1Path.addOval(Rect.fromCenter(
        center: const Offset(0, 0),
        width: 50 * scaleX,
        height: 90 * scaleY,
      ));
      canvas.drawPath(pad1Path, paint);
      canvas.restore();

      // FINGER PAD 2 - top center-left, repositioned
      canvas.save();
      canvas.translate((215 - 46.985) * scaleX, (215 - 106.927) * scaleY);
      canvas.rotate(-14 * 3.14159 / 180);
      final pad2Path = Path();
      pad2Path.addOval(Rect.fromCenter(
        center: const Offset(0, 0),
        width: 50 * scaleX,
        height: 90 * scaleY,
      ));
      canvas.drawPath(pad2Path, paint);
      canvas.restore();

      // FINGER PAD 3 - rotation 6°
      canvas.save();
      canvas.translate((215 + 56.015) * scaleX, (215 - 112.427) * scaleY);
      canvas.rotate(6 * 3.14159 / 180);
      final pad3Path = Path();
      pad3Path.addOval(Rect.fromCenter(
        center: const Offset(0, 0),
        width: 50 * scaleX,
        height: 90 * scaleY,
      ));
      canvas.drawPath(pad3Path, paint);
      canvas.restore();

      // FINGER PAD 4 - rotation 20°
      canvas.save();
      canvas.translate((215 + 120.015) * scaleX, (215 - 34.427) * scaleY);
      canvas.rotate(20 * 3.14159 / 180);
      final pad4Path = Path();
      pad4Path.addOval(Rect.fromCenter(
        center: const Offset(0, 0),
        width: 50 * scaleX,
        height: 90 * scaleY,
      ));
      canvas.drawPath(pad4Path, paint);
      canvas.restore();
    }

    canvas.restore(); // Restore canvas transformation
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is AnimatedPawsPainter &&
        (oldDelegate.animationProgress != animationProgress ||
            oldDelegate.isFilled != isFilled ||
            oldDelegate.color != color);
  }
}

class HomeIconPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double strokeWidth;

  HomeIconPainter({
    required this.color,
    required this.isFilled,
    this.strokeWidth = 1.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Scale factors based on the SVG viewBox (24x24) to fit our size
    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    if (isFilled) {
      // Filled version: use the new solid SVG design
      paint.style = PaintingStyle.fill;

      // First path: d="M11.47 3.841a.75.75 0 0 1 1.06 0l8.69 8.69a.75.75 0 1 0 1.06-1.061l-8.689-8.69a2.25 2.25 0 0 0-3.182 0l-8.69 8.69a.75.75 0 1 0 1.061 1.06l8.69-8.689Z"
      final roofPath = Path();

      // Starting point M11.47 3.841
      roofPath.moveTo(11.47 * scaleX, 3.841 * scaleY);

      // Arc curve a.75.75 0 0 1 1.06 0 - simplified as straight line to end point
      roofPath.lineTo(12.53 * scaleX, 3.841 * scaleY); // 11.47 + 1.06 = 12.53

      // Line l8.69 8.69
      roofPath.lineTo(21.22 * scaleX,
          12.531 * scaleY); // 12.53 + 8.69 = 21.22, 3.841 + 8.69 = 12.531

      // Arc a.75.75 0 1 0 1.06-1.061 - simplified as curve
      roofPath.lineTo(22.28 * scaleX,
          11.47 * scaleY); // 21.22 + 1.06 = 22.28, 12.531 - 1.061 = 11.47

      // Line l-8.689-8.69
      roofPath.lineTo(13.591 * scaleX,
          2.78 * scaleY); // 22.28 - 8.689 = 13.591, 11.47 - 8.69 = 2.78

      // Arc a2.25 2.25 0 0 0-3.182 0 - simplified
      roofPath.lineTo(
          10.409 * scaleX, 2.78 * scaleY); // 13.591 - 3.182 = 10.409

      // Line l-8.69 8.69
      roofPath.lineTo(1.719 * scaleX,
          11.47 * scaleY); // 10.409 - 8.69 = 1.719, 2.78 + 8.69 = 11.47

      // Arc a.75.75 0 1 0 1.061 1.06 - simplified
      roofPath.lineTo(2.78 * scaleX,
          12.531 * scaleY); // 1.719 + 1.061 = 2.78, 11.47 + 1.06 = 12.531

      // Line l8.69-8.689 back to start
      roofPath.lineTo(
          11.47 * scaleX,
          3.841 *
              scaleY); // 2.78 + 8.69 = 11.47, 12.531 - 8.689 = 3.842 ≈ 3.841

      roofPath.close();
      canvas.drawPath(roofPath, paint);

      // Second path: d="m12 5.432 8.159 8.159c.03.03.06.058.091.086v6.198c0 1.035-.84 1.875-1.875 1.875H15a.75.75 0 0 1-.75-.75v-4.5a.75.75 0 0 0-.75-.75h-3a.75.75 0 0 0-.75.75V21a.75.75 0 0 1-.75.75H5.625a1.875 1.875 0 0 1-1.875-1.875v-6.198a2.29 2.29 0 0 0 .091-.086L12 5.432Z"
      final housePath = Path();

      // Starting point m12 5.432
      housePath.moveTo(12 * scaleX, 5.432 * scaleY);

      // Line l8.159 8.159
      housePath.lineTo(20.159 * scaleX,
          13.591 * scaleY); // 12 + 8.159 = 20.159, 5.432 + 8.159 = 13.591

      // Curve c.03.03.06.058.091.086 - simplified as small offset
      housePath.lineTo(20.25 * scaleX,
          13.677 * scaleY); // 20.159 + 0.091 = 20.25, 13.591 + 0.086 = 13.677

      // Vertical line v6.198
      housePath.lineTo(
          20.25 * scaleX, 19.875 * scaleY); // 13.677 + 6.198 = 19.875

      // House right side with rounded corner - simplified
      housePath.lineTo(
          18.375 * scaleX, 19.875 * scaleY); // 20.25 - 1.875 = 18.375
      housePath.lineTo(15 * scaleX, 19.875 * scaleY); // H15

      // Door frame right side
      housePath.lineTo(14.25 * scaleX, 19.875 * scaleY); // 15 - 0.75 = 14.25
      housePath.lineTo(
          14.25 * scaleX, 15.375 * scaleY); // v-4.5, 19.875 - 4.5 = 15.375
      housePath.lineTo(13.5 * scaleX, 15.375 * scaleY); // 14.25 - 0.75 = 13.5

      // Door top
      housePath.lineTo(10.5 * scaleX, 15.375 * scaleY); // h-3, 13.5 - 3 = 10.5

      // Door frame left side
      housePath.lineTo(9.75 * scaleX, 15.375 * scaleY); // 10.5 - 0.75 = 9.75
      housePath.lineTo(9.75 * scaleX,
          19.875 * scaleY); // V21, but adjusted to 19.875 to match
      housePath.lineTo(9 * scaleX, 19.875 * scaleY); // 9.75 - 0.75 = 9

      // House left side
      housePath.lineTo(5.625 * scaleX, 19.875 * scaleY); // H5.625
      housePath.lineTo(3.75 * scaleX, 19.875 * scaleY); // 5.625 - 1.875 = 3.75

      // Left wall up
      housePath.lineTo(
          3.75 * scaleX, 13.677 * scaleY); // v-6.198, 19.875 - 6.198 = 13.677

      // Small curve back to start
      housePath.lineTo(
          3.841 * scaleX, 13.591 * scaleY); // c.091-.086 simplified
      housePath.lineTo(12 * scaleX, 5.432 * scaleY); // Back to start

      housePath.close();
      canvas.drawPath(housePath, paint);
    } else {
      // Outlined version: draw stroke paths
      paint.style = PaintingStyle.stroke;

      // Roof line: m2.25 12 8.954-8.955c.44-.439 1.152-.439 1.591 0L21.75 12
      final roofPath = Path();
      roofPath.moveTo(2.25 * scaleX, 12 * scaleY);
      roofPath.lineTo(11.204 * scaleX, 3.045 * scaleY);
      // Curved section approximated as smooth connection
      roofPath.cubicTo(
        11.644 * scaleX,
        2.606 * scaleY,
        12.356 * scaleX,
        2.606 * scaleY,
        12.795 * scaleX,
        3.045 * scaleY,
      );
      roofPath.lineTo(21.75 * scaleX, 12 * scaleY);
      canvas.drawPath(roofPath, paint);

      // House body: M4.5 9.75v10.125c0 .621.504 1.125 1.125 1.125H9.75v-4.875c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125V21h4.125c.621 0 1.125-.504 1.125-1.125V9.75
      final bodyPath = Path();
      bodyPath.moveTo(4.5 * scaleX, 9.75 * scaleY);
      bodyPath.lineTo(4.5 * scaleX, 19.875 * scaleY); // 9.75 + 10.125 = 19.875
      bodyPath.lineTo(5.625 * scaleX, 19.875 * scaleY); // 4.5 + 1.125 = 5.625
      bodyPath.lineTo(9.75 * scaleX, 19.875 * scaleY);
      bodyPath.lineTo(9.75 * scaleX, 15 * scaleY); // 19.875 - 4.875 = 15
      bodyPath.lineTo(10.875 * scaleX, 15 * scaleY); // 9.75 + 1.125 = 10.875
      bodyPath.lineTo(13.125 * scaleX, 15 * scaleY); // 10.875 + 2.25 = 13.125
      bodyPath.lineTo(14.25 * scaleX, 15 * scaleY); // 13.125 + 1.125 = 14.25
      bodyPath.lineTo(14.25 * scaleX, 21 * scaleY);
      bodyPath.lineTo(18.375 * scaleX, 21 * scaleY); // 14.25 + 4.125 = 18.375
      bodyPath.lineTo(19.5 * scaleX, 21 * scaleY); // 18.375 + 1.125 = 19.5
      bodyPath.lineTo(19.5 * scaleX, 19.875 * scaleY); // 21 - 1.125 = 19.875
      bodyPath.lineTo(19.5 * scaleX, 9.75 * scaleY);
      canvas.drawPath(bodyPath, paint);

      // Door frame: M8.25 21h8.25
      final doorPath = Path();
      doorPath.moveTo(8.25 * scaleX, 21 * scaleY);
      doorPath.lineTo(16.5 * scaleX, 21 * scaleY); // 8.25 + 8.25 = 16.5
      canvas.drawPath(doorPath, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is HomeIconPainter &&
        (oldDelegate.isFilled != isFilled || oldDelegate.color != color);
  }
}

/// Custom painter for graduation cap icon (Learn tab)
class GraduationCapPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double strokeWidth;
  final double animationValue;

  GraduationCapPainter({
    required this.color,
    required this.isFilled,
    this.strokeWidth = 1.5,
    this.animationValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;
    
    // Calculate tassel sway animation
    // animationValue goes from 0.0 to 1.0, create gentle sway from -1 to +1
    final swayProgress = (animationValue * 2.0) - 1.0; // Convert 0-1 to -1 to +1  
    final maxSwayDistance = 1.5 * scaleX; // Maximum sway distance
    final tasselSwayOffset = maxSwayDistance * sin(swayProgress * pi); // Smooth sine wave motion

    if (isFilled) {
      // Filled version using exact SVG paths from reference
      paint.style = PaintingStyle.fill;

      // First path: d="M11.7 2.805a.75.75 0 0 1 .6 0A60.65 60.65 0 0 1 22.83 8.72a.75.75 0 0 1-.231 1.337 49.948 49.948 0 0 0-9.902 3.912l-.003.002c-.114.06-.227.119-.34.18a.75.75 0 0 1-.707 0A50.88 50.88 0 0 0 7.5 12.173v-.224c0-.131.067-.248.172-.311a54.615 54.615 0 0 1 4.653-2.52.75.75 0 0 0-.65-1.352 56.123 56.123 0 0 0-4.78 2.589 1.858 1.858 0 0 0-.859 1.228 49.803 49.803 0 0 0-4.634-1.527.75.75 0 0 1-.231-1.337A60.653 60.653 0 0 1 11.7 2.805Z"
      final path1 = Path();
      path1.moveTo(11.7 * scaleX, 2.805 * scaleY);
      path1.cubicTo(11.85 * scaleX, 2.73 * scaleY, 12.15 * scaleX, 2.73 * scaleY, 12.3 * scaleX, 2.805 * scaleY);
      path1.cubicTo(16.2 * scaleX, 4.5 * scaleY, 20.1 * scaleX, 6.5 * scaleY, 22.83 * scaleX, 8.72 * scaleY);
      path1.cubicTo(22.91 * scaleX, 8.82 * scaleY, 22.91 * scaleX, 9.02 * scaleY, 22.599 * scaleX, 10.057 * scaleY);
      path1.cubicTo(19.8 * scaleX, 11.2 * scaleY, 16.2 * scaleX, 12.8 * scaleY, 12.697 * scaleX, 13.969 * scaleY);
      path1.lineTo(12.694 * scaleX, 13.971 * scaleY);
      path1.cubicTo(12.58 * scaleX, 14.031 * scaleY, 12.467 * scaleX, 14.09 * scaleY, 12.354 * scaleX, 14.151 * scaleY);
      path1.cubicTo(12.12 * scaleX, 14.28 * scaleY, 11.88 * scaleX, 14.28 * scaleY, 11.647 * scaleX, 14.151 * scaleY);
      path1.cubicTo(10.2 * scaleX, 13.5 * scaleY, 8.8 * scaleX, 12.9 * scaleY, 7.5 * scaleX, 12.173 * scaleY);
      path1.lineTo(7.5 * scaleX, 11.949 * scaleY);
      path1.cubicTo(7.567 * scaleX, 11.818 * scaleY, 7.634 * scaleX, 11.701 * scaleY, 7.672 * scaleX, 11.638 * scaleY);
      path1.cubicTo(9.2 * scaleX, 10.5 * scaleY, 10.9 * scaleX, 9.6 * scaleY, 12.325 * scaleX, 9.118 * scaleY);
      path1.cubicTo(12.45 * scaleX, 9.068 * scaleY, 12.52 * scaleX, 8.918 * scaleY, 11.675 * scaleX, 7.766 * scaleY);
      path1.cubicTo(10.1 * scaleX, 8.4 * scaleY, 8.7 * scaleX, 9.3 * scaleY, 6.895 * scaleX, 10.355 * scaleY);
      path1.cubicTo(6.56 * scaleX, 10.55 * scaleY, 6.3 * scaleX, 10.9 * scaleY, 6.036 * scaleX, 11.583 * scaleY);
      path1.cubicTo(4.5 * scaleX, 11.2 * scaleY, 2.9 * scaleX, 10.7 * scaleY, 1.402 * scaleX, 10.056 * scaleY);
      path1.cubicTo(1.31 * scaleX, 10.02 * scaleY, 1.25 * scaleX, 9.86 * scaleY, 1.171 * scaleX, 8.719 * scaleY);
      path1.cubicTo(4.2 * scaleX, 6.4 * scaleY, 7.8 * scaleX, 4.2 * scaleY, 11.7 * scaleX, 2.805 * scaleY);
      path1.close();
      canvas.drawPath(path1, paint);

      // Second path: d="M13.06 15.473a48.45 48.45 0 0 1 7.666-3.282c.134 1.414.22 2.843.255 4.284a.75.75 0 0 1-.46.711 47.87 47.87 0 0 0-8.105 4.342.75.75 0 0 1-.832 0 47.87 47.87 0 0 0-8.104-4.342.75.75 0 0 1-.461-.71c.035-1.442.121-2.87.255-4.286.921.304 1.83.634 2.726.99v1.27a1.5 1.5 0 0 0-.14 2.508c-.09.38-.222.753-.397 1.11.452.213.901.434 1.346.66a6.727 6.727 0 0 0 .551-1.607 1.5 1.5 0 0 0 .14-2.67v-.645a48.549 48.549 0 0 1 3.44 1.667 2.25 2.25 0 0 0 2.12 0Z"
      final path2 = Path();
      path2.moveTo(13.06 * scaleX, 15.473 * scaleY);
      path2.cubicTo(16.2 * scaleX, 14.1 * scaleY, 18.8 * scaleX, 13.0 * scaleY, 20.726 * scaleX, 12.191 * scaleY);
      path2.cubicTo(20.86 * scaleX, 13.605 * scaleY, 20.946 * scaleX, 15.034 * scaleY, 20.981 * scaleX, 16.475 * scaleY);
      path2.cubicTo(20.981 * scaleX, 16.725 * scaleY, 20.85 * scaleX, 16.95 * scaleY, 20.521 * scaleX, 17.186 * scaleY);
      path2.cubicTo(18.2 * scaleX, 18.8 * scaleY, 15.4 * scaleX, 20.4 * scaleY, 12.416 * scaleX, 21.528 * scaleY);
      path2.cubicTo(12.28 * scaleX, 21.59 * scaleY, 12.14 * scaleX, 21.59 * scaleY, 11.584 * scaleX, 21.528 * scaleY);
      path2.cubicTo(8.6 * scaleX, 20.4 * scaleY, 5.8 * scaleX, 18.8 * scaleY, 3.48 * scaleX, 17.186 * scaleY);
      path2.cubicTo(3.15 * scaleX, 16.95 * scaleY, 3.019 * scaleX, 16.725 * scaleY, 3.019 * scaleX, 16.476 * scaleY);
      path2.cubicTo(3.054 * scaleX, 15.034 * scaleY, 3.14 * scaleX, 13.606 * scaleY, 3.274 * scaleX, 12.19 * scaleY);
      path2.cubicTo(4.195 * scaleX, 12.494 * scaleY, 5.104 * scaleX, 12.824 * scaleY, 6.0 * scaleX, 13.18 * scaleY);
      path2.lineTo(6.0 * scaleX, 14.45 * scaleY);
      path2.cubicTo(5.86 * scaleX, 15.95 * scaleY, 6.86 * scaleX, 16.458 * scaleY, 7.0 * scaleX, 16.958 * scaleY);
      path2.cubicTo(6.91 * scaleX, 17.338 * scaleY, 6.778 * scaleX, 17.711 * scaleY, 6.603 * scaleX, 18.068 * scaleY);
      path2.cubicTo(7.055 * scaleX, 18.281 * scaleY, 7.504 * scaleX, 18.502 * scaleY, 7.949 * scaleX, 18.728 * scaleY);
      path2.cubicTo(8.5 * scaleX, 17.121 * scaleY, 8.5 * scaleX, 17.058 * scaleY, 8.089 * scaleX, 16.058 * scaleY);
      path2.lineTo(8.089 * scaleX, 15.413 * scaleY);
      path2.cubicTo(9.72 * scaleX, 16.08 * scaleY, 11.209 * scaleX, 16.747 * scaleY, 12.529 * scaleX, 17.08 * scaleY);
      path2.cubicTo(13.279 * scaleX, 17.21 * scaleY, 13.649 * scaleX, 16.88 * scaleY, 13.649 * scaleX, 16.38 * scaleY);
      path2.lineTo(13.06 * scaleX, 15.473 * scaleY);
      path2.close();
      canvas.drawPath(path2, paint);

      // Third path: d="M4.462 19.462c.42-.419.753-.89 1-1.395.453.214.902.435 1.347.662a6.742 6.742 0 0 1-1.286 1.794.75.75 0 0 1-1.06-1.06Z"  
      // This is the tassel that should hang straight down - now with sway animation
      final path3 = Path();
      path3.moveTo((4.462 * scaleX) + tasselSwayOffset, 19.462 * scaleY);
      path3.lineTo((5.462 * scaleX) + tasselSwayOffset, 18.067 * scaleY); // Straight up first
      path3.lineTo((6.809 * scaleX) + tasselSwayOffset, 18.729 * scaleY); // Then right and slightly down
      path3.lineTo((5.523 * scaleX) + tasselSwayOffset, 20.523 * scaleY); // Straight down to bottom
      path3.lineTo((4.462 * scaleX) + tasselSwayOffset, 19.462 * scaleY); // Back to start
      path3.close();
      canvas.drawPath(path3, paint);

    } else {
      // Outlined version - keep existing complex implementation
      paint.style = PaintingStyle.stroke;
      
      // Exact SVG path implementation
      // Path 1: M4.26 10.147a60.438 60.438 0 0 0-.491 6.347A48.62 48.62 0 0 1 12 20.904a48.62 48.62 0 0 1 8.232-4.41 60.46 60.46 0 0 0-.491-6.347
      final mainCapPath = Path();
      mainCapPath.moveTo(4.26 * scaleX, 10.147 * scaleY);
      
      // Create the curved bottom part of the graduation cap
      mainCapPath.cubicTo(
        4.1 * scaleX, 13.0 * scaleY,    // Control point 1
        3.9 * scaleX, 15.5 * scaleY,    // Control point 2  
        3.769 * scaleX, 16.494 * scaleY // End point (10.147 + 6.347)
      );
      
      mainCapPath.cubicTo(
        6.0 * scaleX, 19.0 * scaleY,    // Control point 1
        9.0 * scaleX, 20.5 * scaleY,    // Control point 2
        12 * scaleX, 20.904 * scaleY    // Center bottom point
      );
      
      mainCapPath.cubicTo(
        15.0 * scaleX, 20.5 * scaleY,    // Control point 1
        18.0 * scaleX, 19.0 * scaleY,    // Control point 2
        20.232 * scaleX, 16.494 * scaleY // Right side point (12 + 8.232, same as left)
      );
      
      mainCapPath.cubicTo(
        20.1 * scaleX, 15.5 * scaleY,     // Control point 1
        19.9 * scaleX, 13.0 * scaleY,     // Control point 2
        19.741 * scaleX, 10.147 * scaleY  // Back to right edge
      );

      canvas.drawPath(mainCapPath, paint);

      // Path 2: The top ridge/fold of the graduation cap going upward
      // m-15.482 0a50.636 50.636 0 0 0-2.658-.813A59.906 59.906 0 0 1 12 3.493a59.903 59.903 0 0 1 10.399 5.84c-.896.248-1.783.52-2.658.814
      final topRidgePath = Path();
      topRidgePath.moveTo(4.259 * scaleX, 10.147 * scaleY); // 19.741 - 15.482
      
      topRidgePath.cubicTo(
        3.5 * scaleX, 9.8 * scaleY,     // Control point 1
        2.8 * scaleX, 9.5 * scaleY,     // Control point 2  
        1.601 * scaleX, 9.334 * scaleY  // Left edge point (4.259 - 2.658, 10.147 - 0.813)
      );
      
      topRidgePath.cubicTo(
        5.0 * scaleX, 6.0 * scaleY,     // Control point 1
        8.5 * scaleX, 4.0 * scaleY,     // Control point 2
        12 * scaleX, 3.493 * scaleY     // Top center point
      );
      
      topRidgePath.cubicTo(
        15.5 * scaleX, 4.0 * scaleY,     // Control point 1
        19.0 * scaleX, 6.0 * scaleY,     // Control point 2
        22.399 * scaleX, 9.333 * scaleY  // Right edge point (12 + 10.399)
      );
      
      topRidgePath.cubicTo(
        21.5 * scaleX, 9.6 * scaleY,     // Control point 1
        20.6 * scaleX, 9.8 * scaleY,     // Control point 2
        19.741 * scaleX, 10.147 * scaleY // Back to right edge
      );

      canvas.drawPath(topRidgePath, paint);

      // Path 3: Center connecting lines
      // m-15.482 0A50.717 50.717 0 0 1 12 13.489a50.702 50.702 0 0 1 7.74-3.342
      final centerLines = Path();
      centerLines.moveTo(4.259 * scaleX, 10.147 * scaleY);
      centerLines.cubicTo(
        7.0 * scaleX, 11.5 * scaleY,     // Control point 1
        9.5 * scaleX, 12.8 * scaleY,     // Control point 2
        12 * scaleX, 13.489 * scaleY     // Center point
      );
      centerLines.cubicTo(
        15.0 * scaleX, 12.2 * scaleY,     // Control point 1
        17.5 * scaleX, 11.0 * scaleY,     // Control point 2
        19.74 * scaleX, 10.147 * scaleY   // Right edge point (12 + 7.74)
      );

      canvas.drawPath(centerLines, paint);

      // Tassel circle: M6.75 15a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5 - with sway animation
      final tasselPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;

      canvas.drawCircle(
        Offset((6.75 * scaleX) + tasselSwayOffset, 15 * scaleY),
        0.75 * scaleX,
        tasselPaint,
      );

      // Tassel string connections - with sway animation
      // Zm0 0v-3.675A55.378 55.378 0 0 1 12 8.443
      canvas.drawLine(
        Offset((6.75 * scaleX) + tasselSwayOffset, 15 * scaleY),
        Offset((6.75 * scaleX) + (tasselSwayOffset * 0.3), 11.325 * scaleY), // Less sway at top connection point
        paint,
      );

      // Curved line to center - with sway animation
      final tasselCurve = Path();
      tasselCurve.moveTo((6.75 * scaleX) + (tasselSwayOffset * 0.3), 11.325 * scaleY);
      tasselCurve.cubicTo(
        8.5 * scaleX, 10.0 * scaleY,     // Control point 1 - no sway, connected to cap
        10.0 * scaleX, 9.0 * scaleY,     // Control point 2 - no sway, connected to cap
        12 * scaleX, 8.443 * scaleY      // Connect to cap center - no sway
      );
      canvas.drawPath(tasselCurve, paint);

      // Additional tassel detail - with sway animation
      // m-7.007 11.55A5.981 5.981 0 0 0 6.75 15.75v-1.5
      final tasselDetail = Path();
      tasselDetail.moveTo((4.993 * scaleX) + tasselSwayOffset, 19.993 * scaleY); // 12 - 7.007, 8.443 + 11.55
      tasselDetail.cubicTo(
        5.5 * scaleX, 18.0 * scaleY,     // Control point 1
        6.0 * scaleX, 16.8 * scaleY,     // Control point 2
        (6.75 * scaleX) + tasselSwayOffset, 15.75 * scaleY    // End point with sway
      );
      tasselDetail.lineTo((6.75 * scaleX) + tasselSwayOffset, 14.25 * scaleY); // 15.75 - 1.5 with sway
      
      canvas.drawPath(tasselDetail, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is GraduationCapPainter &&
        (oldDelegate.isFilled != isFilled || 
         oldDelegate.color != color ||
         oldDelegate.strokeWidth != strokeWidth ||
         oldDelegate.animationValue != animationValue);
  }
}

/// Custom painter for social/people icon (Social tab)
class SocialIconPainter extends CustomPainter {
  final Color color;
  final bool isFilled;
  final double strokeWidth;
  final double animationValue; // Animation progress from 0.0 to 1.0

  SocialIconPainter({
    required this.color,
    required this.isFilled,
    this.strokeWidth = 1.5,
    this.animationValue = 0.0, // Default to no animation
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = isFilled ? PaintingStyle.fill : PaintingStyle.stroke;

    final scaleX = size.width / 24;
    final scaleY = size.height / 24;

    // Calculate hugging animation offsets - side figures move closer to center and back
    // Animation goes: 0.0 → 0.5 (max hug) → 1.0 (back to normal)
    final hugProgress = animationValue <= 0.5 
        ? animationValue * 2.0  // 0.0 to 1.0 in first half
        : (1.0 - animationValue) * 2.0; // 1.0 to 0.0 in second half
    final hugOffset = hugProgress * 1.5; // Maximum 1.5 units closer to center
    final leftHugX = 5.25 + hugOffset; // Left figure moves right
    final rightHugX = 18.75 - hugOffset; // Right figure moves left

    if (isFilled) {
      // Filled version using the provided filled SVG paths
      paint.style = PaintingStyle.fill;

      // First path: d="M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0ZM15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0ZM6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z"
      final mainPath = Path();
      
      // Center head: M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0Z
      mainPath.addOval(Rect.fromCenter(
        center: Offset(12 * scaleX, 6.75 * scaleY), // 8.25 + 3.75 = 12
        width: 7.5 * scaleX,
        height: 7.5 * scaleY,
      ));
      
      // Right head: M15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0Z (moves left during animation)
      mainPath.addOval(Rect.fromCenter(
        center: Offset(rightHugX * scaleX, 9.75 * scaleY), // Animated X position
        width: 6 * scaleX,
        height: 6 * scaleY,
      ));
      
      // Left head: M2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0Z (moves right during animation)
      mainPath.addOval(Rect.fromCenter(
        center: Offset(leftHugX * scaleX, 9.75 * scaleY), // Animated X position
        width: 6 * scaleX,
        height: 6 * scaleY,
      ));
      
      // Main body: M6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z
      final bodyLeftX = 6.31 + hugOffset * 0.5; // Body sides also move but less dramatically
      final bodyRightX = 18.709 - hugOffset * 0.5;
      
      mainPath.moveTo(bodyLeftX * scaleX, 15.117 * scaleY);
      mainPath.cubicTo(
        8.0 * scaleX, 13.5 * scaleY,
        10.0 * scaleX, 12.0 * scaleY,
        12 * scaleX, 12 * scaleY
      );
      mainPath.cubicTo(
        14.0 * scaleX, 12.0 * scaleY,
        16.0 * scaleX, 13.5 * scaleY,
        bodyRightX * scaleX, 19.498 * scaleY
      );
      mainPath.cubicTo(
        (bodyRightX - 0.122) * scaleX, 19.69 * scaleY,
        (bodyRightX - 0.272) * scaleX, 19.82 * scaleY,
        (bodyRightX - 0.372) * scaleX, 20.066 * scaleY
      );
      mainPath.cubicTo(
        16.5 * scaleX, 21.2 * scaleY,
        14.3 * scaleX, 21.75 * scaleY,
        12 * scaleX, 21.75 * scaleY
      );
      mainPath.cubicTo(
        9.695 * scaleX, 21.75 * scaleY,
        7.53 * scaleX, 21.138 * scaleY,
        (bodyLeftX - 0.647) * scaleX, 20.066 * scaleY
      );
      mainPath.cubicTo(
        (bodyLeftX - 0.747) * scaleX, 19.82 * scaleY,
        (bodyLeftX - 0.897) * scaleX, 19.69 * scaleY,
        (bodyLeftX - 1.019) * scaleX, 19.498 * scaleY
      );
      mainPath.cubicTo(
        (bodyLeftX - 0.51) * scaleX, 17.8 * scaleY,
        (bodyLeftX - 0.26) * scaleX, 16.5 * scaleY,
        bodyLeftX * scaleX, 15.117 * scaleY
      );
      mainPath.close();
      canvas.drawPath(mainPath, paint);

      // Second path: d="M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047ZM20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z"
      final sidePath = Path();
      
      // Animated side body positions for hugging effect
      final leftSideX = 5.082 + hugOffset * 0.3; // Left side moves right slightly
      final rightSideX = 20.226 - hugOffset * 0.3; // Right side moves left slightly
      final leftSideBodyX = 18.918 - hugOffset * 0.3; // Right side body moves left
      
      // Left side body: M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047Z
      sidePath.moveTo(leftSideX * scaleX, 14.254 * scaleY);
      sidePath.cubicTo(
        (leftSideX - 0.582) * scaleX, 16.8 * scaleY,
        (leftSideX - 0.882) * scaleX, 18.5 * scaleY,
        (leftSideX - 1.308) * scaleX, 19.389 * scaleY
      );
      sidePath.cubicTo(
        2.8 * scaleX, 19.2 * scaleY,
        2.0 * scaleX, 19.0 * scaleY,
        2.01 * scaleX, 18.949 * scaleY
      );
      sidePath.lineTo(1.895 * scaleX, 18.909 * scaleY);
      sidePath.cubicTo(
        1.7 * scaleX, 18.8 * scaleY,
        1.6 * scaleX, 18.6 * scaleY,
        1.522 * scaleX, 18.422 * scaleY
      );
      sidePath.lineTo(1.512 * scaleX, 18.301 * scaleY);
      sidePath.cubicTo(
        1.8 * scaleX, 16.5 * scaleY,
        3.2 * scaleX, 14.8 * scaleY,
        leftSideX * scaleX, 14.254 * scaleY
      );
      sidePath.close();
      
      // Right side body: M20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z
      sidePath.moveTo(rightSideX * scaleX, 19.389 * scaleY);
      sidePath.cubicTo(
        (rightSideX - 0.626) * scaleX, 16.8 * scaleY,
        (rightSideX - 0.926) * scaleX, 15.0 * scaleY,
        leftSideBodyX * scaleX, 14.254 * scaleY
      );
      sidePath.cubicTo(
        (leftSideBodyX + 1.882) * scaleX, 14.8 * scaleY,
        (leftSideBodyX + 3.282) * scaleX, 16.5 * scaleY,
        22.488 * scaleX, 18.301 * scaleY
      );
      sidePath.lineTo(22.478 * scaleX, 18.422 * scaleY);
      sidePath.cubicTo(
        22.4 * scaleX, 18.6 * scaleY,
        22.3 * scaleX, 18.8 * scaleY,
        22.105 * scaleX, 18.908 * scaleY
      );
      sidePath.lineTo(21.99 * scaleX, 18.948 * scaleY);
      sidePath.cubicTo(
        21.2 * scaleX, 19.15 * scaleY,
        20.8 * scaleX, 19.3 * scaleY,
        rightSideX * scaleX, 19.389 * scaleY
      );
      sidePath.close();
      
      canvas.drawPath(sidePath, paint);

    } else {
      // Outlined version - use the same shape as filled but as stroke
      paint.style = PaintingStyle.stroke;

      // Use the exact same paths as the filled version but draw them as outlines
      final mainPath = Path();
      
      // Center head: M8.25 6.75a3.75 3.75 0 1 1 7.5 0 3.75 3.75 0 0 1-7.5 0Z
      mainPath.addOval(Rect.fromCenter(
        center: Offset(12 * scaleX, 6.75 * scaleY), // 8.25 + 3.75 = 12
        width: 7.5 * scaleX,
        height: 7.5 * scaleY,
      ));
      
      // Right head: M15.75 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0Z (animated)
      mainPath.addOval(Rect.fromCenter(
        center: Offset(rightHugX * scaleX, 9.75 * scaleY), // Animated X position
        width: 6 * scaleX,
        height: 6 * scaleY,
      ));
      
      // Left head: M2.25 9.75a3 3 0 1 1 6 0 3 3 0 0 1-6 0Z (animated)
      mainPath.addOval(Rect.fromCenter(
        center: Offset(leftHugX * scaleX, 9.75 * scaleY), // Animated X position
        width: 6 * scaleX,
        height: 6 * scaleY,
      ));
      
      // Main body: M6.31 15.117A6.745 6.745 0 0 1 12 12a6.745 6.745 0 0 1 6.709 7.498.75.75 0 0 1-.372.568A12.696 12.696 0 0 1 12 21.75c-2.305 0-4.47-.612-6.337-1.684a.75.75 0 0 1-.372-.568 6.787 6.787 0 0 1 1.019-4.38Z
      mainPath.moveTo(6.31 * scaleX, 15.117 * scaleY);
      mainPath.cubicTo(
        8.0 * scaleX, 13.5 * scaleY,
        10.0 * scaleX, 12.0 * scaleY,
        12 * scaleX, 12 * scaleY
      );
      mainPath.cubicTo(
        14.0 * scaleX, 12.0 * scaleY,
        16.0 * scaleX, 13.5 * scaleY,
        18.709 * scaleX, 19.498 * scaleY
      );
      mainPath.cubicTo(
        18.587 * scaleX, 19.69 * scaleY,
        18.437 * scaleX, 19.82 * scaleY,
        18.337 * scaleX, 20.066 * scaleY
      );
      mainPath.cubicTo(
        16.5 * scaleX, 21.2 * scaleY,
        14.3 * scaleX, 21.75 * scaleY,
        12 * scaleX, 21.75 * scaleY
      );
      mainPath.cubicTo(
        9.695 * scaleX, 21.75 * scaleY,
        7.53 * scaleX, 21.138 * scaleY,
        5.663 * scaleX, 20.066 * scaleY
      );
      mainPath.cubicTo(
        5.563 * scaleX, 19.82 * scaleY,
        5.413 * scaleX, 19.69 * scaleY,
        5.291 * scaleX, 19.498 * scaleY
      );
      mainPath.cubicTo(
        5.8 * scaleX, 17.8 * scaleY,
        6.05 * scaleX, 16.5 * scaleY,
        6.31 * scaleX, 15.117 * scaleY
      );
      mainPath.close();
      canvas.drawPath(mainPath, paint);

      // Side body paths as outlines
      final sidePath = Path();
      
      // Left side body: M5.082 14.254a8.287 8.287 0 0 0-1.308 5.135 9.687 9.687 0 0 1-1.764-.44l-.115-.04a.563.563 0 0 1-.373-.487l-.01-.121a3.75 3.75 0 0 1 3.57-4.047Z
      sidePath.moveTo(5.082 * scaleX, 14.254 * scaleY);
      sidePath.cubicTo(
        4.5 * scaleX, 16.8 * scaleY,
        4.2 * scaleX, 18.5 * scaleY,
        3.774 * scaleX, 19.389 * scaleY
      );
      sidePath.cubicTo(
        2.8 * scaleX, 19.2 * scaleY,
        2.0 * scaleX, 19.0 * scaleY,
        2.01 * scaleX, 18.949 * scaleY
      );
      sidePath.lineTo(1.895 * scaleX, 18.909 * scaleY);
      sidePath.cubicTo(
        1.7 * scaleX, 18.8 * scaleY,
        1.6 * scaleX, 18.6 * scaleY,
        1.522 * scaleX, 18.422 * scaleY
      );
      sidePath.lineTo(1.512 * scaleX, 18.301 * scaleY);
      sidePath.cubicTo(
        1.8 * scaleX, 16.5 * scaleY,
        3.2 * scaleX, 14.8 * scaleY,
        5.082 * scaleX, 14.254 * scaleY
      );
      sidePath.close();
      
      // Right side body: M20.226 19.389a8.287 8.287 0 0 0-1.308-5.135 3.75 3.75 0 0 1 3.57 4.047l-.01.121a.563.563 0 0 1-.373.486l-.115.04c-.567.2-1.156.349-1.764.441Z
      sidePath.moveTo(20.226 * scaleX, 19.389 * scaleY);
      sidePath.cubicTo(
        19.6 * scaleX, 16.8 * scaleY,
        19.3 * scaleX, 15.0 * scaleY,
        18.918 * scaleX, 14.254 * scaleY
      );
      sidePath.cubicTo(
        20.8 * scaleX, 14.8 * scaleY,
        22.2 * scaleX, 16.5 * scaleY,
        22.488 * scaleX, 18.301 * scaleY
      );
      sidePath.lineTo(22.478 * scaleX, 18.422 * scaleY);
      sidePath.cubicTo(
        22.4 * scaleX, 18.6 * scaleY,
        22.3 * scaleX, 18.8 * scaleY,
        22.105 * scaleX, 18.908 * scaleY
      );
      sidePath.lineTo(21.99 * scaleX, 18.948 * scaleY);
      sidePath.cubicTo(
        21.2 * scaleX, 19.15 * scaleY,
        20.8 * scaleX, 19.3 * scaleY,
        20.226 * scaleX, 19.389 * scaleY
      );
      sidePath.close();
      
      canvas.drawPath(sidePath, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is SocialIconPainter &&
        (oldDelegate.isFilled != isFilled || 
         oldDelegate.color != color ||
         oldDelegate.strokeWidth != strokeWidth ||
         oldDelegate.animationValue != animationValue);
  }
}
