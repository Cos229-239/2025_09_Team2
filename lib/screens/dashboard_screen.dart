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
// Import Provider package for accessing state management across widgets
import 'package:provider/provider.dart';
// Import screen for flashcard study interface
import 'package:studypals/screens/flashcard_study_screen.dart'; // Flashcard study interface
// Import AI system test screen for validation
import 'package:studypals/screens/ai_system_test_screen.dart'; // AI system validation
// Import settings screen for app configuration
import 'package:studypals/screens/settings_screen.dart'; // Settings and configuration screen
// Import planner screen
import 'package:studypals/screens/planner_page.dart';
// Import creation screens for notes and tasks
import 'package:studypals/screens/create_note_screen.dart'; // Note creation screen
import 'package:studypals/screens/create_task_screen.dart'; // Task creation screen
// Import custom dashboard widgets that display different app features
import 'package:studypals/widgets/dashboard/due_cards_widget.dart'; // Flashcards due for review
// Import animated particle background
import 'package:studypals/widgets/common/animated_particle_background.dart';
// Import AI widgets for intelligent study features
import 'package:studypals/widgets/ai/ai_flashcard_generator.dart'; // AI-powered flashcard generation
import 'package:studypals/widgets/ai/ai_assistant_widget.dart'; // AI Assistant with persona selection
import 'package:studypals/widgets/common/modern_hamburger_menu.dart'; // Modern hamburger menu
import 'package:studypals/screens/unified_planner_screen.dart'; // Unified planner screen
// Import state providers for loading data from different app modules
import 'package:studypals/providers/app_state.dart'; // Global app state for authentication
import 'package:studypals/providers/task_provider.dart'; // Task management state
import 'package:studypals/providers/note_provider.dart'; // Notes management state
import 'package:studypals/providers/deck_provider.dart'; // Flashcard deck state
import 'package:studypals/providers/pet_provider.dart'; // Virtual pet state
import 'package:studypals/providers/srs_provider.dart'; // Spaced repetition system state
import 'package:studypals/providers/ai_provider.dart'; // AI provider state
import 'package:studypals/providers/daily_quest_provider.dart'; // Daily quest gamification state
import 'package:studypals/models/task.dart'; // Task model
import 'package:studypals/providers/notification_provider.dart'; // Notification system state
import 'package:studypals/services/ai_service.dart'; // AI service for provider enum
// Import notification widgets for LinkedIn-style notifications
import 'package:studypals/widgets/notifications/notification_panel.dart'; // Notification bell and panel
// Import models for deck and card data
import 'package:studypals/models/deck.dart'; // Deck model for flashcard collections
import 'package:studypals/models/note.dart'; // Note model for study notes
import 'package:studypals/models/daily_quest.dart'; // Daily quest model for gamification
// Import flashcard study screen for studying decks
//import 'package:studypals/screens/flashcard_study_screen.dart'; // Flashcard study interface

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
class _DashboardScreenState extends State<DashboardScreen> {
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
        apiKey: 'AIzaSyAasLmobMCyBiDAm3x9PqT11WX5ck3OhMA',
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
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Builds the app bar action buttons (notifications, settings, and logout)
  /// Separated into method to keep build method clean and organized
  /// @param context - Build context for navigation and state access
  /// @return List of IconButton widgets for the app bar actions
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // LinkedIn-style notification bell with unread count badge
      const NotificationBellIcon(),

      // AI System Test button - validates AI features
      IconButton(
        icon: const Icon(Icons.psychology, color: Colors.orange), 
        tooltip: 'AI System Validation',
        onPressed: () {
          // Navigate to AI system test screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AISystemTestScreen(),
            ),
          );
        },
      ),

      // Settings button - opens app configuration panel
      IconButton(
        icon: const Icon(Icons.settings), // Gear icon for settings
        onPressed: () {
          // Navigate to settings screen
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const SettingsScreen(),
            ),
          );
        },
      ),

      // Logout button - signs out the current user
      IconButton(
        icon: const Icon(Icons.logout), // Logout icon
        onPressed: () async {
          // Confirm logout with user
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          );

          if (shouldLogout == true && context.mounted) {
            // Sign out the user through AppState
            await Provider.of<AppState>(context, listen: false).logout();
          }
        },
      ),
    ];
  }

  /// Builds the main dashboard content with app widgets
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the dashboard home screen
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedParticleBackground(
        gradientColors: const [
          Color(0xFF515B9B), // Lighter blue-purple from Figma
          Color(0xFF1C1F35), // Darker blue-gray from Figma
        ],
        particleCount: 60,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Home tab - responsive dashboard content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Fixed header section
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.1,
                      child: _buildHeader(context),
                    ),

                    const SizedBox(height: 8),

                    // Flexible calendar section
                    Expanded(
                      flex: 4,
                      child: _buildCalendarSection(context),
                    ),

                    const SizedBox(height: 8),

                    // Flexible cards row
                    Expanded(
                      flex: 2,
                      child: _buildCardsAndNotesRow(context),
                    ),

                    const SizedBox(height: 8),

                    // Flexible AI assistant section
                    const Expanded(
                      flex: 2,
                      child: AIAssistantWidget(),
                    ),

                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Tasks tab
            _buildTasksTab(),
            // Stats tab
            _buildStatsTab(),
            // Pet tab
            _buildPetTab(),
          ],
        ),
      ),

      // Bottom navigation bar with Home, Tasks, Stats, and Pet buttons
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
            left: 16, right: 16, top: 16), // Remove bottom margin
        decoration: BoxDecoration(
          color: const Color(0xFF2A3050), // Same color as Flash Cards container
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            // No bottom radius to make it look like it runs off screen
          ),
          border: const Border(
            top: BorderSide(color: Color(0xFFF8B67F), width: 2),
            left: BorderSide(color: Color(0xFFF8B67F), width: 2),
            right: BorderSide(color: Color(0xFFF8B67F), width: 2),
            // No bottom border to enhance the "runs off screen" effect
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -4), // Shadow going upward
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 5,
              spreadRadius: 0,
              offset: const Offset(0, -2), // Shadow going upward
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // XP Progress bar at the top
              Consumer<PetProvider>(
                builder: (context, petProvider, child) {
                  final pet = petProvider.currentPet;
                  if (pet == null) {
                    return const Text('Loading pet...');
                  }
                  final currentXP = pet.xp;
                  final maxXP = pet.xpForNextLevel;
                  final progress = currentXP / maxXP;

                  return Column(
                    children: [
                      // XP text and progress bar
                      Row(
                        children: [
                          Text(
                            'XP $currentXP/$maxXP',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavButton(
                    context,
                    icon: Icons.home,
                    label: 'Home',
                    isSelected: _selectedTabIndex == 0,
                    onTap: () {
                      _tabController.animateTo(0);
                    },
                  ),
                  _buildNavButton(
                    context,
                    icon: Icons.assignment,
                    label: 'Tasks',
                    isSelected: _selectedTabIndex == 1,
                    onTap: () {
                      _tabController.animateTo(1);
                    },
                  ),
                  _buildNavButton(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Stats',
                    isSelected: _selectedTabIndex == 2,
                    onTap: () {
                      _tabController.animateTo(2);
                    },
                  ),
                  _buildNavButton(
                    context,
                    icon: Icons.pets,
                    label: 'Pet',
                    isSelected: _selectedTabIndex == 3,
                    onTap: () {
                      _tabController.animateTo(3);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the header section with greeting and action buttons
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Hamburger menu at the top left
        const ModernHamburgerMenu(),
        const SizedBox(width: 12),

        // Main content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Study Pals',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4),
              Consumer<AppState>(
                builder: (context, appState, child) {
                  return Text(
                    'Hi ${appState.currentUser?.name ?? 'User'}, Ready to study?',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  );
                },
              ),
            ],
          ),
        ),

        // Action buttons on the right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildAppBarActions(context),
        ),
      ],
    );
  }

  /// Build the calendar section matching the attached image layout
  Widget _buildCalendarSection(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to enhanced calendar when calendar section is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UnifiedPlannerScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3050),
          borderRadius: Theme.of(context).cardTheme.shape
                  is RoundedRectangleBorder
              ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder)
                  .borderRadius
              : BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFF8B67F),
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
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Left side - Today's Progress with circular indicator
              Column(
                children: [
                  // Date display
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A3050),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFF8B67F),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'SEP',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF8B67F),
                                    letterSpacing: 1.0,
                                  ),
                        ),
                        Text(
                          '${DateTime.now().day}',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF8B67F),
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Today's Progress label and circular progress
                  Text(
                    'Todays\nProgress',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 6),

                  // Circular progress indicator
                  Consumer<TaskProvider>(
                    builder: (context, taskProvider, child) {
                      final completedTasks = taskProvider.tasks
                          .where((task) => task.status == TaskStatus.completed)
                          .length;
                      final totalTasks = taskProvider.tasks.length;
                      final progress =
                          totalTasks > 0 ? completedTasks / totalTasks : 0.0;

                      return SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment
                              .center, // This centers the stack contents
                          children: [
                            // Position the circular progress indicator
                            Positioned.fill(
                              child: CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 4,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHigh,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFFF8B67F),
                                ),
                              ),
                            ),
                            // Center the text exactly in the middle
                            Text(
                              '${(progress * 100).round()}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFF8B67F),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Right side - Calendar grid
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month navigation header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(
                          Icons.chevron_left,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          size: 20,
                        ),
                        Text(
                          'SEPTEMBER',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Calendar grid
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildCalendarGrid(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ), // Close Row
        ), // Close Padding
      ), // Close Container
    ); // Close InkWell
  }

  /// Build the calendar grid matching the image
  Widget _buildCalendarGrid(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    // Week day headers
    const weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Column(
      children: [
        // Week day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: weekDays
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: const Color(
                              0xFFF8B67F), // Match Flash Cards border color
                          fontWeight: FontWeight
                              .w600, // Slightly bolder to match button styling
                        ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),

        // Calendar days grid
        ...List.generate((daysInMonth + startWeekday + 6) ~/ 7, (weekIndex) {
          final isLastWeek =
              weekIndex == ((daysInMonth + startWeekday + 6) ~/ 7) - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (dayIndex) {
                    final dayNumber =
                        weekIndex * 7 + dayIndex - startWeekday + 1;
                    final isCurrentMonth =
                        dayNumber > 0 && dayNumber <= daysInMonth;
                    final isToday = isCurrentMonth && dayNumber == now.day;

                    return Expanded(
                      child: SizedBox(
                        height: 28,
                        child: isCurrentMonth
                            ? InkWell(
                                onTap: () {
                                  // Navigate to enhanced calendar when day is tapped
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const UnifiedPlannerScreen(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: isToday
                                        ? const Color(0xFFF8B67F)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(
                                    child: Text(
                                      dayNumber.toString(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: isToday
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .onPrimary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                            fontWeight: isToday
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                    ),
                                  ),
                                ),
                              )
                            : const SizedBox(),
                      ),
                    );
                  }),
                ),
              ),
              // Add horizontal line after each row except the last one
              if (!isLastWeek)
                Container(
                  height: 1,
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                ),
            ],
          );
        }),
      ],
    );
  }

  /// Build flash cards and notes row with login screen styling
  Widget _buildCardsAndNotesRow(BuildContext context) {
    return Row(
      children: [
        // Flash Cards section
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius:
                  Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                      ? (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .borderRadius
                      : BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF8B67F),
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
                  padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8B67F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF8B67F)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.style,
                          size: 24,
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
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius:
                  Theme.of(context).cardTheme.shape is RoundedRectangleBorder
                      ? (Theme.of(context).cardTheme.shape
                              as RoundedRectangleBorder)
                          .borderRadius
                      : BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF8B67F),
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
                  padding: const EdgeInsets.all(16),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8B67F),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF8B67F)
                                  .withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.note_alt,
                          size: 24,
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
      ],
    );
  }

  /// Build Tasks tab content
  Widget _buildTasksTab() {
    return SafeArea(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Tasks',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showCreateTaskDialog(context),
                ),
              ],
            ),
          ),
          // Tasks list
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, taskProvider, child) {
                if (taskProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tasks = taskProvider.tasks;
                if (tasks.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No tasks yet'),
                        Text('Create your first task!'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return _buildSimpleTaskCard(task);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build Stats tab content
  Widget _buildStatsTab() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // Study stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Cards Studied',
                    '150',
                    Icons.style,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Study Streak',
                    '7 days',
                    Icons.local_fire_department,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Tasks Done',
                    '23',
                    Icons.task_alt,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Notes Created',
                    '45',
                    Icons.note,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  /// Build stat card widget
  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Show create task dialog
  void _showCreateTaskDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create task dialog - Coming soon!')),
    );
  }

  /// Build simple task card for dashboard
  Widget _buildSimpleTaskCard(Task task) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: task.status == TaskStatus.completed
              ? Colors.green.withValues(alpha: 0.2)
              : Colors.blue.withValues(alpha: 0.2),
          child: Icon(
            task.status == TaskStatus.completed ? Icons.check : Icons.task_alt,
            color: task.status == TaskStatus.completed
                ? Colors.green
                : Colors.blue,
          ),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.status == TaskStatus.completed
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Text('${task.estMinutes} min'),
        trailing: task.dueAt != null
            ? Text(
                _formatDate(task.dueAt!),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              )
            : null,
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays == -1) {
      return 'Tomorrow';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else {
      return '${-difference.inDays} days';
    }
  }

  /// Build individual navigation button matching the image layout
  Widget _buildNavButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon container with selection styling
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3050),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFF8B67F),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 28,
                    color: const Color(0xFFF8B67F),
                  ),
                ),
                const SizedBox(height: 4),
                // Label text
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected
                            ? const Color(0xFFF8B67F)
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 11,
                      ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[600],
                                  ),
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
                                  color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Text(
                                selectedDueDate != null
                                    ? 'Due: ${_formatDate(selectedDueDate!)}'
                                    : 'Set due date (optional)',
                                style: TextStyle(
                                  color: selectedDueDate != null
                                      ? Colors.black
                                      : Colors.grey[600],
                                ),
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
