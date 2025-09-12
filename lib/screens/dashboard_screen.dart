// git changes
// Import Flutter's material design components for UI elements
import 'package:flutter/material.dart';
// Import Provider package for accessing state management across widgets
import 'package:provider/provider.dart';
// Import screen for flashcard study interface
import 'package:studypals/screens/flashcard_study_screen.dart'; // Flashcard study interface
// Import custom dashboard widgets that display different app features
import 'package:studypals/widgets/dashboard/pet_widget.dart'; // Virtual pet display and interactions
import 'package:studypals/widgets/dashboard/today_tasks_widget.dart'; // Today's tasks overview
import 'package:studypals/widgets/dashboard/due_cards_widget.dart'; // Flashcards due for review
import 'package:studypals/widgets/dashboard/quick_stats_widget.dart'; // Study statistics summary
// Import AI widgets for intelligent study features
import 'package:studypals/widgets/ai/ai_flashcard_generator.dart'; // AI-powered flashcard generation
import 'package:studypals/widgets/ai/ai_tutor_chat.dart'; // AI study assistant chat
import 'package:studypals/widgets/ai/ai_settings_widget.dart'; // AI configuration settings
// Import state providers for loading data from different app modules
import 'package:studypals/providers/app_state.dart'; // Global app state for authentication
import 'package:studypals/providers/task_provider.dart'; // Task management state
import 'package:studypals/providers/deck_provider.dart'; // Flashcard deck state
import 'package:studypals/providers/pet_provider.dart'; // Virtual pet state
import 'package:studypals/providers/srs_provider.dart'; // Spaced repetition system state
import 'package:studypals/providers/daily_quest_provider.dart'; // Daily quest gamification state
// Import models for deck and card data
import 'package:studypals/models/deck.dart'; // Deck model for flashcard collections
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
  // Index of currently selected tab in bottom navigation (0 = Dashboard, 1 = Planner, etc.)
  int _selectedIndex = 0;

  // List of screen widgets corresponding to each navigation tab
  // Each widget represents a different section of the app
  final List<Widget> _pages = [
    const DashboardHome(), // Main dashboard with widgets (index 0)
    const PlannerScreen(), // Calendar/planning interface (index 1)
    const NotesScreen(), // Note-taking interface (index 2)
    const DecksScreen(), // Flashcard deck management (index 3)
    const ProgressScreen(), // Progress tracking and analytics (index 4)
  ];

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
    final questProvider =
        Provider.of<DailyQuestProvider>(context, listen: false); // Daily quest data access

    // Load all data sources concurrently using Future.wait for better performance
    // If one fails, others can still complete successfully
    await Future.wait([
      taskProvider.loadTasks(), // Load all tasks from database
      deckProvider.loadDecks(), // Load all flashcard decks from database
      petProvider.loadPet(), // Load virtual pet data from database
      srsProvider
          .loadReviews(), // Load spaced repetition review data from database
      questProvider.loadTodaysQuests(), // Load daily quests and generate if needed
    ]);
  }

  /// Builds the dashboard screen with bottom navigation
  /// @param context - Build context containing theme and navigation information
  /// @return Widget tree representing the dashboard with navigation
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Display the currently selected page based on navigation index
      body: _pages[_selectedIndex],

      // Bottom navigation bar for switching between app sections
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex, // Highlight currently selected tab

        // Handle tab selection by updating the selected index
        onDestinationSelected: (index) {
          setState(() {
            // Trigger rebuild with new selection
            _selectedIndex = index; // Update selected tab index
          });
        },

        // Define navigation destinations (tabs) with icons and labels
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard), // Dashboard tab icon
            label: 'Dashboard', // Dashboard tab label
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_today), // Calendar tab icon
            label: 'Planner', // Planner tab label
          ),
          NavigationDestination(
            icon: Icon(Icons.note), // Notes tab icon
            label: 'Notes', // Notes tab label
          ),
          NavigationDestination(
            icon: Icon(Icons.style), // Decks tab icon
            label: 'Decks', // Decks tab label
          ),
          NavigationDestination(
            icon: Icon(Icons.insights), // Progress tab icon
            label: 'Progress', // Progress tab label
          ),
        ],
      ),
    );
  }
}

/// Main dashboard home screen displaying key app widgets
/// Shows virtual pet, today's tasks, due cards, and quick statistics
class DashboardHome extends StatelessWidget {
  // Constructor with optional key for widget identification
  const DashboardHome({super.key});

  /// Builds the app bar action buttons (notifications, settings, and logout)
  /// Separated into method to keep build method clean and organized
  /// @param context - Build context for navigation and state access
  /// @return List of IconButton widgets for the app bar actions
  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      // Notifications button - shows app notifications and reminders
      IconButton(
        icon: const Icon(Icons.notifications), // Bell icon for notifications
        onPressed: () {
          // Future implementation: Navigate to notifications panel
          // Will show study reminders, achievements, task completions, pet interactions
          // Navigation will be implemented when notifications screen is created
        },
      ),

      // Settings button - opens app configuration panel
      IconButton(
        icon: const Icon(Icons.settings), // Gear icon for settings
        onPressed: () {
          // Future implementation: Navigate to settings screen
          // Will handle app configuration, themes, notifications, data export
          // Navigation will be implemented when settings screen is created
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
      // App bar with title and action buttons
      appBar: AppBar(
        title: const Text('Today'), // Screen title indicating today's overview
        actions: _buildAppBarActions(
            context), // Notifications, settings, and logout buttons
      ),

      // Scrollable body containing dashboard widgets
      body: const SingleChildScrollView(
        // Allow vertical scrolling if content overflows
        padding: EdgeInsets.all(16), // Consistent padding around content

        // Vertical layout of dashboard widgets
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start, // Align widgets to start (left) edge
          children: [
            // Virtual pet widget - shows pet status and allows interactions
            PetWidget(),

            // Spacing between widgets for visual separation
            SizedBox(height: 20),

            // Today's tasks widget - displays tasks due today with quick actions
            TodayTasksWidget(),

            // Spacing between widgets
            SizedBox(height: 20),

            // Due cards widget - shows flashcards that need review today
            DueCardsWidget(),

            // Spacing between widgets
            SizedBox(height: 20),

            // Quick stats widget - displays study progress and statistics
            QuickStatsWidget(),

            // Spacing between widgets
            SizedBox(height: 20),

            // AI flashcard generator - create cards using AI
            AIFlashcardGenerator(),

            // Spacing between widgets
            SizedBox(height: 20),

            // AI tutor chat - study assistant
            SizedBox(
              height: 300,
              child: AITutorChat(),
            ),

            // Spacing between widgets
            SizedBox(height: 20),

            // AI settings - configure AI features
            AISettingsWidget(),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for calendar/planning functionality
/// Will be replaced with full calendar interface in future versions
class PlannerScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const PlannerScreen({super.key});

  /// Builds placeholder content indicating feature is coming soon
  /// @param context - Build context containing theme information
  /// @return Widget tree showing placeholder content
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with screen title
      appBar: AppBar(title: const Text('Planner')),

      // Centered placeholder content
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          children: [
            // Large calendar icon to indicate planner functionality
            const Icon(Icons.calendar_today, size: 64, color: Colors.grey),

            // Spacing between icon and text
            const SizedBox(height: 16),

            // Coming soon message with appropriate text style
            Text('Planner coming soon!',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

/// Placeholder screen for note-taking functionality
/// Will be replaced with full note editor and management interface
class NotesScreen extends StatelessWidget {
  // Constructor with optional key for widget identification
  const NotesScreen({super.key});

  /// Builds placeholder content indicating feature is coming soon
  /// @param context - Build context containing theme information
  /// @return Widget tree showing placeholder content
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar with screen title
      appBar: AppBar(title: const Text('Notes')),

      // Centered placeholder content
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center, // Center content vertically
          children: [
            // Large note icon to indicate note-taking functionality
            const Icon(Icons.note, size: 64, color: Colors.grey),

            // Spacing between icon and text
            const SizedBox(height: 16),

            // Coming soon message with appropriate text style
            Text('Notes coming soon!',
                style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
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

          if (decks.isEmpty) {
            // Show empty state when no decks exist
            return Center(
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
                    'Create flashcards using the AI Generator\nin the dashboard.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          // Show list of decks
          return ListView.builder(
            padding: const EdgeInsets.all(16),
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
                                    style: const TextStyle(fontSize: 12),
                                  ),
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
