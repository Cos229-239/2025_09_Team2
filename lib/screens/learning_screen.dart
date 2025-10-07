import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/task_provider.dart';
import 'package:studypals/providers/note_provider.dart';
import 'package:studypals/providers/deck_provider.dart';
import 'package:studypals/models/deck.dart';
import 'package:studypals/screens/task_list_screen.dart';
import 'package:studypals/screens/create_note_screen.dart';
import 'package:studypals/screens/flashcard_detail_screen.dart';
import 'package:studypals/models/task.dart';
import 'package:studypals/widgets/ai/ai_flashcard_generator.dart';
import '../widgets/common/themed_background_wrapper.dart';

/// Custom scroll physics for single-page-at-a-time movement
class SinglePageScrollPhysics extends ScrollPhysics {
  const SinglePageScrollPhysics({super.parent});

  @override
  SinglePageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SinglePageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => const SpringDescription(
    mass: 80, // Very heavy mass for immediate stopping
    stiffness: 200, // Very high stiffness for instant snap
    damping: 1.0, // Maximum damping to prevent any overshoot
  );

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // Prevent any scrolling beyond current page boundaries
    final page = position.pixels / position.viewportDimension;
    final targetPage = page.round();
    final maxOffset = targetPage * position.viewportDimension;
    final minOffset = targetPage * position.viewportDimension;
    
    // Clamp to current page boundaries
    if (value < minOffset && position.pixels <= minOffset) {
      return value - minOffset;
    }
    if (value > maxOffset && position.pixels >= maxOffset) {
      return value - maxOffset;
    }
    
    return super.applyBoundaryConditions(position, value);
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // Force immediate stop at the nearest page
    final page = position.pixels / position.viewportDimension;
    final targetPage = velocity > 0 ? page.ceil() : page.floor();
    final targetPixels = targetPage * position.viewportDimension;
    
    // Clamp target to valid range
    final clampedTarget = targetPixels.clamp(
      0.0, 
      (position.maxScrollExtent).toDouble(),
    );
    
    // Create simulation that goes directly to target page
    return ScrollSpringSimulation(
      spring,
      position.pixels,
      clampedTarget,
      velocity,
      tolerance: toleranceFor(position),
    );
  }
}

/// Learning hub screen that provides access to all learning-related features
/// Includes tasks (daily/weekly), flashcards (with search, quiz, study modes), and notes
class LearningScreen extends StatefulWidget {
  const LearningScreen({super.key});

  @override
  State<LearningScreen> createState() => _LearningScreenState();
}

class _LearningScreenState extends State<LearningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;
  final TextEditingController _noteSearchController = TextEditingController();
  final TextEditingController _flashcardSearchController = TextEditingController();
  String _noteSearchQuery = '';
  String _flashcardSearchQuery = '';
  int _currentPageIndex = 0;
  bool _isAnimating = false;
  double _startDragX = 0.0;
  bool _isDragging = false;
  DateTime? _lastPageChangeTime;
  static bool _globalPageChangeLock = false; // GLOBAL lock across all instances
  
  // ENHANCED TRACKPAD GESTURE DETECTION SYSTEM
  // This system fixes the trackpad multi-page jumping issue by properly
  // tracking scroll accumulation and gesture completion
  bool _gestureInProgress = false;
  double _scrollAccumulator = 0.0; // Accumulates scroll delta over time
  double _lastScrollVelocity = 0.0; // Track velocity for momentum detection
  DateTime? _lastScrollEventTime;
  bool _pageChangeTriggered = false; // Prevents multiple page changes per gesture
  
  // Thresholds for gesture detection
  static const double _swipeThreshold = 120.0; // Total accumulated distance for page change
  static const double _maxVelocity = 100.0; // Max scroll velocity to consider intentional
  static const int _gestureTimeoutMs = 150; // Time after last scroll event to end gesture
  static const int _cooldownMs = 200; // Minimum time between page changes

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 1.0, // Full page view
      keepPage: true, // Keep page in memory
    );
    
    // Sync tab controller with page controller
    _tabController.addListener(_onTabChanged);
    
    // Load all necessary data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TaskProvider>(context, listen: false).loadTasks();
      Provider.of<NoteProvider>(context, listen: false).loadNotes();
      Provider.of<DeckProvider>(context, listen: false).loadDecks();
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _pageController.dispose();
    _noteSearchController.dispose();
    _flashcardSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedBackgroundWrapper(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Learning'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          bottom: TabBar(
            controller: _tabController,
            onTap: _onTabTapped, // Handle manual tab taps
            tabs: const [
              Tab(icon: Icon(Icons.assignment), text: 'Learning Tasks'),
              Tab(icon: Icon(Icons.style), text: 'Flash Cards'),
              Tab(icon: Icon(Icons.note), text: 'Notes'),
            ],
          ),
        ),
        body: Listener(
          onPointerSignal: _onPointerSignal, // Enhanced trackpad gesture detection
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: PageView(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              physics: const NeverScrollableScrollPhysics(), // Disable default scrolling
              pageSnapping: true,
              children: [
                _buildTasksTab(),
                _buildFlashcardsTab(),
                _buildNotesTab(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Handle tab taps to sync with PageView
  void _onTabTapped(int index) {
    _moveToPage(index);
  }

  /// Handle page changes to sync with TabBar
  void _onPageChanged(int index) {
    // Ensure we only move one page at a time
    final targetIndex = _clampPageIndex(index);
    
    setState(() {
      _currentPageIndex = targetIndex;
    });
    
    // Sync tab controller without animation to prevent conflicts
    if (_tabController.index != targetIndex) {
      _tabController.index = targetIndex;
    }
  }

  /// Handle tab controller changes (for programmatic changes)
  void _onTabChanged() {
    if (_tabController.indexIsChanging && !_isAnimating) {
      _isAnimating = true;
      _pageController.animateToPage(
        _tabController.index,
        duration: const Duration(milliseconds: 250), // Fast snap
        curve: Curves.easeOutCubic,
      ).then((_) {
        _isAnimating = false;
      });
    }
  }

  /// Clamp page index to ensure only one page movement at a time
  int _clampPageIndex(int newIndex) {
    // Only allow movement of 1 page at a time
    final diff = (newIndex - _currentPageIndex).abs();
    if (diff > 1) {
      // If trying to move more than 1 page, limit to 1 page in that direction
      if (newIndex > _currentPageIndex) {
        return _currentPageIndex + 1;
      } else {
        return _currentPageIndex - 1;
      }
    }
    
    // Ensure within bounds
    return newIndex.clamp(0, 2);
  }

  /// Handle pan start for manual gesture control
  void _onPanStart(DragStartDetails details) {
    _startDragX = details.localPosition.dx;
    _isDragging = true;
  }

  /// Handle pan update for manual gesture control
  void _onPanUpdate(DragUpdateDetails details) {
    // We don't need to do anything during update, just track the gesture
  }

  /// Handle pan end to determine swipe direction and move exactly one page
  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isAnimating) {
      _isDragging = false;
      return;
    }

    _isDragging = false;
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    const minSwipeVelocity = 300.0; // Minimum velocity to trigger swipe
    
    int targetPage = _currentPageIndex;

    // Determine swipe direction based on velocity
    if (velocity.abs() > minSwipeVelocity) {
      if (velocity > 0) {
        // Swiping right - go to next page
        targetPage = (_currentPageIndex + 1).clamp(0, 2);
      } else {
        // Swiping left - go to previous page  
        targetPage = (_currentPageIndex - 1).clamp(0, 2);
      }
    } else {
      // Check distance if velocity is low
      final currentX = details.localPosition.dx;
      final deltaX = currentX - _startDragX;
      const minSwipeDistance = 50.0;
      
      if (deltaX.abs() > minSwipeDistance) {
        if (deltaX > 0) {
          // Swiping right - go to next page
          targetPage = (_currentPageIndex + 1).clamp(0, 2);
        } else {
          // Swiping left - go to previous page
          targetPage = (_currentPageIndex - 1).clamp(0, 2);
        }
      }
    }

    // Only move if target is different and within bounds
    if (targetPage != _currentPageIndex && !_isAnimating) {
      _moveToPage(targetPage);
    }
  }

  // ENHANCED TRACKPAD GESTURE DETECTION
  // This replaces the old boundary-based system with a more robust approach
  // that properly handles trackpad momentum and prevents multi-page jumps
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // GLOBAL PROTECTION: Block during animation or if locked
      if (_globalPageChangeLock || _isAnimating) {
        return;
      }
      
      final now = DateTime.now();
      final deltaX = event.scrollDelta.dx;
      
      // Ignore very small deltas (noise)
      if (deltaX.abs() < 0.5) return;
      
      // Calculate time since last scroll event
      final timeSinceLastScroll = _lastScrollEventTime == null 
          ? 1000 
          : now.difference(_lastScrollEventTime!).inMilliseconds;
      
      // Check if this is a new gesture or continuation of existing one
      if (!_gestureInProgress || timeSinceLastScroll > _gestureTimeoutMs) {
        _startNewGesture(deltaX, now);
      } else {
        _continueGesture(deltaX, now);
      }
      
      _lastScrollEventTime = now;
      _scheduleGestureEndDetection();
    }
  }
  
  /// Start a new trackpad gesture
  /// ISSUE FIX: Properly initialize gesture state to prevent cross-contamination
  void _startNewGesture(double deltaX, DateTime now) {
    // Only start if enough time has passed since last page change (cooldown)
    if (_lastPageChangeTime != null && 
        now.difference(_lastPageChangeTime!).inMilliseconds < _cooldownMs) {
      return; // Still in cooldown period
    }
    
    _gestureInProgress = true;
    _scrollAccumulator = deltaX; // Start accumulating from this delta
    _pageChangeTriggered = false; // Fresh gesture, no page change yet
    _lastScrollVelocity = deltaX.abs();
    
    // Check if we immediately hit the threshold (for very fast swipes)
    _checkSwipeThreshold();
  }
  
  /// Continue existing trackpad gesture
  /// ISSUE FIX: Proper accumulation and direction consistency
  void _continueGesture(double deltaX, DateTime now) {
    // If this gesture already triggered a page change, ignore further events
    if (_pageChangeTriggered) {
      return;
    }
    
    // Calculate current velocity (deltaX per ms)
    final timeDelta = now.difference(_lastScrollEventTime!).inMilliseconds;
    if (timeDelta > 0) {
      _lastScrollVelocity = deltaX.abs() / timeDelta;
    }
    
    // Only accumulate if the scroll is in consistent direction and not too fast
    // ISSUE FIX: Reject momentum scrolling by checking velocity
    if (_lastScrollVelocity <= _maxVelocity) {
      final currentDirection = deltaX > 0 ? 1 : -1;
      final accumulatedDirection = _scrollAccumulator > 0 ? 1 : -1;
      
      // Only accumulate if direction is consistent
      if (currentDirection == accumulatedDirection || _scrollAccumulator.abs() < 10) {
        _scrollAccumulator += deltaX;
        _checkSwipeThreshold();
      }
    }
    // If velocity is too high, this is likely momentum - ignore
  }
  
  /// Check if accumulated scroll has reached the swipe threshold
  /// ISSUE FIX: Clear threshold logic with single page change per gesture
  void _checkSwipeThreshold() {
    if (_pageChangeTriggered || _scrollAccumulator.abs() < _swipeThreshold) {
      return; // Either already triggered or not enough distance
    }
    
    // Determine target page based on scroll direction
    int? targetPage;
    if (_scrollAccumulator > 0) {
      // Scrolling right/positive - go to next page (swipe right = next)
      if (_currentPageIndex < 2) {
        targetPage = _currentPageIndex + 1;
      }
    } else {
      // Scrolling left/negative - go to previous page (swipe left = previous)  
      if (_currentPageIndex > 0) {
        targetPage = _currentPageIndex - 1;
      }
    }
    
    // Execute page change if valid target
    if (targetPage != null) {
      _pageChangeTriggered = true; // Mark this gesture as used
      _lastPageChangeTime = DateTime.now();
      _moveToPage(targetPage);
    }
  }
  
  /// Schedule gesture end detection
  /// ISSUE FIX: Proper timeout handling for gesture completion
  void _scheduleGestureEndDetection() {
    Future.delayed(Duration(milliseconds: _gestureTimeoutMs), () {
      final now = DateTime.now();
      if (_lastScrollEventTime != null && 
          now.difference(_lastScrollEventTime!).inMilliseconds >= _gestureTimeoutMs &&
          _gestureInProgress) {
        _endGesture();
      }
    });
  }
  
  /// End current trackpad gesture
  /// ISSUE FIX: Clean reset of all gesture state
  void _endGesture() {
    _gestureInProgress = false;
    _scrollAccumulator = 0.0;
    _lastScrollVelocity = 0.0;
    _pageChangeTriggered = false;
    // Keep _lastPageChangeTime for cooldown protection
  }
  

  


  /// ULTIMATE protected page movement - prevents multiple changes per gesture only
  void _moveToPage(int targetPage) {
    // GLOBAL PROTECTION: If animation is happening, block
    if (_globalPageChangeLock || _isAnimating || targetPage == _currentPageIndex) {
      return;
    }
    
    // Validate single page movement only
    final clampedTarget = targetPage.clamp(0, 2);
    final distance = (clampedTarget - _currentPageIndex).abs();
    
    if (distance != 1) return; // Must be exactly 1 page
    
    // ACTIVATE GLOBAL LOCK - blocks concurrent page changes only
    _globalPageChangeLock = true;
    _isAnimating = true;
    
    _pageController.animateToPage(
      clampedTarget,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    ).then((_) {
      _isAnimating = false;
      // Release global lock quickly - only block during animation
      Future.delayed(const Duration(milliseconds: 100), () {
        _globalPageChangeLock = false;
      });
    });
  }

  /// Build tasks tab with learning tasks section
  Widget _buildTasksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTasksSection(),
        ],
      ),
    );
  }

  /// Build flashcards tab with search bar, deck list, and create button  
  Widget _buildFlashcardsTab() {
    return Consumer<DeckProvider>(
      builder: (context, deckProvider, child) {
        // Filter decks based on search query
        final filteredDecks = deckProvider.decks.where((deck) {
          return deck.title.toLowerCase().contains(_flashcardSearchQuery.toLowerCase()) ||
                 deck.tags.any((tag) => tag.toLowerCase().contains(_flashcardSearchQuery.toLowerCase()));
        }).toList();

        // Sort decks by updated date (most recent first)
        filteredDecks.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _flashcardSearchController,
                decoration: InputDecoration(
                  hintText: 'Search flashcard decks...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _flashcardSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _flashcardSearchController.clear();
                            setState(() {
                              _flashcardSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _flashcardSearchQuery = value;
                  });
                },
              ),
            ),
            
            // Deck list
            Expanded(
              child: filteredDecks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.style_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _flashcardSearchQuery.isEmpty
                                ? 'No flashcard decks yet'
                                : 'No decks match your search',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _flashcardSearchQuery.isEmpty
                                ? 'Create your first deck to get started'
                                : 'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredDecks.length,
                      itemBuilder: (context, index) {
                        final deck = filteredDecks[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () {
                              _showDeckModeSelection(context, deck);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.style,
                                      color: Colors.blue,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deck.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (deck.tags.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: deck.tags.take(3).map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.layers,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${deck.cards.length} cards',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTimeAgo(deck.updatedAt),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[500],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDeckDialog(context, deck, deckProvider);
                                      } else if (value == 'delete') {
                                        _showDeleteDeckDialog(context, deck, deckProvider);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 18),
                                            SizedBox(width: 12),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 18, color: Colors.red),
                                            SizedBox(width: 12),
                                            Text('Delete', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                    child: Icon(
                                      Icons.more_vert,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Create button at bottom with extra spacing above AI tutor
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAIFlashcardGeneratorModal(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Deck'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build notes tab with notes section
  Widget _buildNotesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNotesSection(),
        ],
      ),
    );
  }

  /// Build the learning tasks section with daily and weekly tasks
  Widget _buildTasksSection() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        final allTasks = taskProvider.tasks
            .where((task) => task.status != TaskStatus.completed)
            .toList();

        // Filter tasks for today (daily tasks)
        final today = DateTime.now();
        final dailyTasks = allTasks.where((task) {
          if (task.dueAt == null) return false;
          return task.dueAt!.year == today.year &&
              task.dueAt!.month == today.month &&
              task.dueAt!.day == today.day;
        }).toList();

        // Filter tasks for this week (weekly tasks)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        final weeklyTasks = allTasks.where((task) {
          if (task.dueAt == null) return false;
          return task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

        return Column(
          children: [
            // Daily tasks
            _buildTaskCard(
              context,
              title: 'daily tasks',
              count: dailyTasks.length,
              icon: Icons.today,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Weekly tasks
            _buildTaskCard(
              context,
              title: 'Weekly tasks',
              count: weeklyTasks.length,
              icon: Icons.calendar_today,
              color: Colors.purple,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TaskListScreen(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// Build a task card with icon and count
  Widget _buildTaskCard(
    BuildContext context, {
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count ${count == 1 ? 'task' : 'tasks'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  /// Build the notes section with search bar and create functionality
  Widget _buildNotesSection() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final notes = noteProvider.notes;
        final filteredNotes = _noteSearchQuery.isEmpty
            ? notes
            : notes.where((note) {
                return note.title
                        .toLowerCase()
                        .contains(_noteSearchQuery.toLowerCase()) ||
                    note.contentMd
                        .toLowerCase()
                        .contains(_noteSearchQuery.toLowerCase());
              }).toList();

        return Column(
          children: [
            // Notes still with search bar
            Card(
              elevation: 2,
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.note, color: Colors.amber, size: 24),
                ),
                title: const Text(
                  'Notes still with search bar',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  '${notes.length} ${notes.length == 1 ? 'note' : 'notes'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        // Search bar
                        TextField(
                          controller: _noteSearchController,
                          decoration: InputDecoration(
                            hintText: 'Search notes...',
                            prefixIcon: const Icon(Icons.search, size: 20),
                            suffixIcon: _noteSearchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _noteSearchController.clear();
                                      setState(() {
                                        _noteSearchQuery = '';
                                      });
                                    },
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _noteSearchQuery = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),

                        // Notes list
                        if (filteredNotes.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              _noteSearchQuery.isEmpty
                                  ? 'No notes available'
                                  : 'No notes found',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredNotes.length,
                            itemBuilder: (context, index) {
                              final note = filteredNotes[index];
                              return ListTile(
                                dense: true,
                                leading: const Icon(Icons.note, size: 20),
                                title: Text(
                                  note.title,
                                  style: const TextStyle(fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  note.contentMd,
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: const Icon(Icons.arrow_forward_ios,
                                    size: 14),
                                onTap: () {
                                  // Navigate to note details (can be enhanced later)
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Viewing: ${note.title}'),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Create note button
            Card(
              elevation: 2,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateNoteScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey[400]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Format time ago for display (e.g., "2 hours ago", "3 days ago")
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Show AI flashcard generator as a modal overlay
  void _showAIFlashcardGeneratorModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('AI Flashcard Generator'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: AIFlashcardGenerator(),
          ),
        ),
      ),
    );
  }

  /// Show mode selection dialog for deck
  void _showDeckModeSelection(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF2A3050),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF6FB8E9),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.style,
                        color: Color(0xFF6FB8E9),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            deck.title,
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${deck.cards.length} cards',
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Choose your study mode:',
                  style: const TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Study Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardDetailScreen(
                            deck: deck,
                            startInQuizMode: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.school),
                    label: const Text('Study Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Quiz Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FlashcardDetailScreen(
                            deck: deck,
                            startInQuizMode: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.quiz),
                    label: const Text('Quiz Mode'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A3050),
                      foregroundColor: const Color(0xFF6FB8E9),
                      side: const BorderSide(
                        color: Color(0xFF6FB8E9),
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Cancel Button
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFFD9D9D9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Show dialog to edit an existing deck
  void _showEditDeckDialog(BuildContext context, Deck deck, DeckProvider deckProvider) {
    final titleController = TextEditingController(text: deck.title);
    final tagsController = TextEditingController(text: deck.tags.join(', '));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Deck'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Deck Title',
                hintText: 'Enter deck title',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (optional)',
                hintText: 'Enter tags separated by commas',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.trim().isNotEmpty) {
                final tags = tagsController.text
                    .split(',')
                    .map((tag) => tag.trim())
                    .where((tag) => tag.isNotEmpty)
                    .toList();

                final updatedDeck = deck.copyWith(
                  title: titleController.text.trim(),
                  tags: tags,
                  updatedAt: DateTime.now(),
                );

                deckProvider.updateDeck(updatedDeck);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show dialog to confirm deck deletion
  void _showDeleteDeckDialog(BuildContext context, Deck deck, DeckProvider deckProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Deck'),
        content: Text('Are you sure you want to delete "${deck.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              deckProvider.deleteDeck(deck.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
