import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:studypals/providers/task_provider.dart';
import 'package:studypals/providers/note_provider.dart';
import 'package:studypals/providers/deck_provider.dart';
import 'package:studypals/providers/calendar_provider.dart';
import 'package:studypals/models/deck.dart';
import 'package:studypals/models/card.dart';
import 'package:studypals/models/note.dart';
import 'package:studypals/models/calendar_event.dart';
import 'package:studypals/screens/task_list_screen.dart';
import 'package:studypals/screens/note_detail_screen.dart';
import 'package:studypals/screens/flashcard_detail_screen.dart';
import 'package:studypals/models/task.dart';
import 'package:studypals/widgets/ai/ai_flashcard_generator.dart';
import 'package:studypals/widgets/notes/create_note_form_simple.dart' as simple;
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
  bool _isCompletedTasksExpanded = false; // Track collapse/expand state for completed tasks
  
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

  /// Extract plain text from Quill Delta JSON
  String _getPlainTextFromDelta(String content) {
    if (content.isEmpty) return '';
    
    try {
      // Try to parse as JSON (Quill Delta format)
      final jsonData = jsonDecode(content);
      
      if (jsonData is List) {
        // Extract text from delta operations
        final StringBuffer buffer = StringBuffer();
        for (var op in jsonData) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        return buffer.toString().trim();
      }
    } catch (e) {
      // If parsing fails, return the content as-is (might be plain text)
      return content;
    }
    
    return content;
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
        debugPrint('🔍 FlashcardsTab - Total decks: ${deckProvider.decks.length}');
        debugPrint('🔍 FlashcardsTab - Is loading: ${deckProvider.isLoading}');
        
        // Filter decks based on search query
        final filteredDecks = deckProvider.decks.where((deck) {
          return deck.title.toLowerCase().contains(_flashcardSearchQuery.toLowerCase()) ||
                 deck.tags.any((tag) => tag.toLowerCase().contains(_flashcardSearchQuery.toLowerCase()));
        }).toList();
        
        debugPrint('🔍 FlashcardsTab - Filtered decks: ${filteredDecks.length}');

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
                  filled: true,
                  fillColor: const Color(0xFF242628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
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
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          color: const Color(0xFF242628),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _showDeckModeSelection(context, deck);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
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
                                  const SizedBox(width: 12),
                                  // Quiz grade circular chart (always show - 0% if no quiz taken)
                                  _buildGradeCircularChart(deck.lastQuizGrade ?? 0.0),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    icon: const Icon(
                                      Icons.more_vert,
                                      color: Color(0xFF888888),
                                    ),
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _showEditDeckDialog(context, deck, deckProvider);
                                      } else if (value == 'delete') {
                                        _showDeleteDeckDialog(context, deck, deckProvider);
                                      } else if (value == 'calendar') {
                                        _showAddToCalendarDialog(context, deck);
                                      } else if (value == 'add_cards') {
                                        _showAddCardsDialog(context, deck, deckProvider);
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
                                        value: 'add_cards',
                                        child: Row(
                                          children: [
                                            Icon(Icons.add_circle, size: 18),
                                            SizedBox(width: 12),
                                            Text('Add Cards'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'calendar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 12),
                                            const Text('Add to Calendar'),
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

  /// Build notes tab with search bar, note list, and create button  
  Widget _buildNotesTab() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        // Filter notes based on search query
        final filteredNotes = noteProvider.notes.where((note) {
          final plainTextContent = _getPlainTextFromDelta(note.contentMd);
          return note.title.toLowerCase().contains(_noteSearchQuery.toLowerCase()) ||
                 plainTextContent.toLowerCase().contains(_noteSearchQuery.toLowerCase()) ||
                 note.tags.any((tag) => tag.toLowerCase().contains(_noteSearchQuery.toLowerCase()));
        }).toList();

        // Sort notes by updated date (most recent first)
        filteredNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _noteSearchController,
                decoration: InputDecoration(
                  hintText: 'Search notes...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _noteSearchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _noteSearchController.clear();
                            setState(() {
                              _noteSearchQuery = '';
                            });
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFF242628),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF6FB8E9),
                      width: 2.0,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _noteSearchQuery = value;
                  });
                },
              ),
            ),
            
            // Note list
            Expanded(
              child: filteredNotes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.note_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _noteSearchQuery.isEmpty
                                ? 'No notes yet'
                                : 'No notes match your search',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _noteSearchQuery.isEmpty
                                ? 'Create your first note to get started'
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
                      itemCount: filteredNotes.length,
                      itemBuilder: (context, index) {
                        final note = filteredNotes[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          color: const Color(0xFF242628),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              _showNoteModeSelection(context, note);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.note,
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
                                          note.title,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        if (note.tags.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: note.tags.take(3).map((tag) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                tag,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Color(0xFF6FB8E9),
                                                ),
                                              ),
                                            )).toList(),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Text(
                                          note.contentMd.isEmpty 
                                            ? 'No content' 
                                            : _getPlainTextFromDelta(note.contentMd),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.access_time,
                                              size: 16,
                                              color: Colors.grey[500],
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatTimeAgo(note.updatedAt),
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
                                        _showEditNoteDialog(context, note, noteProvider);
                                      } else if (value == 'delete') {
                                        _showDeleteNoteDialog(context, note, noteProvider);
                                      } else if (value == 'calendar') {
                                        _showAddNoteToCalendarDialog(context, note);
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
                                      PopupMenuItem(
                                        value: 'calendar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                                            const SizedBox(width: 12),
                                            const Text('Add to Calendar'),
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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('Create Note button clicked'); // Debug output
                    _showCreateNoteModal(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Note'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 64), // Extra spacing above AI tutor
          ],
        );
      },
    );
  }

  /// Build the learning tasks section with actual task content
  Widget _buildTasksSection() {
    return Consumer<TaskProvider>(
      builder: (context, taskProvider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskSectionInline(
              title: "Today's Tasks",
              tasks: _getTodayTasks(taskProvider.tasks),
              icon: Icons.today,
              emptyMessage: "No tasks due today",
            ),
            const SizedBox(height: 24),
            _buildTaskSectionInline(
              title: "This Week's Tasks",
              tasks: _getThisWeekTasks(taskProvider.tasks),
              icon: Icons.view_week,
              emptyMessage: "No tasks due this week",
            ),
            const SizedBox(height: 24),
            _buildTaskSectionInline(
              title: "This Month's Tasks",
              tasks: _getThisMonthTasks(taskProvider.tasks),
              icon: Icons.calendar_month,
              emptyMessage: "No tasks due this month",
            ),
            const SizedBox(height: 24),
            _buildCompletedTasksSection(taskProvider.tasks),
          ],
        );
      },
    );
  }

  /// Get tasks due today
  List<Task> _getTodayTasks(List<Task> allTasks) {
    final today = DateTime.now();
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      return task.dueAt!.year == today.year &&
          task.dueAt!.month == today.month &&
          task.dueAt!.day == today.day;
    }).toList();
  }

  /// Get tasks due this week
  List<Task> _getThisWeekTasks(List<Task> allTasks) {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      // Exclude today's tasks as they're shown in the today section
      final isToday = task.dueAt!.year == today.year &&
          task.dueAt!.month == today.month &&
          task.dueAt!.day == today.day;
      if (isToday) return false;
      
      return task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get tasks due this month
  List<Task> _getThisMonthTasks(List<Task> allTasks) {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    
    return allTasks.where((task) {
      if (task.dueAt == null || task.status == TaskStatus.completed) return false;
      
      // Exclude tasks already shown in today and this week sections
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      final isInCurrentWeek = task.dueAt!.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfWeek.add(const Duration(days: 1)));
      if (isInCurrentWeek) return false;
      
      return task.dueAt!.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
          task.dueAt!.isBefore(endOfMonth.add(const Duration(days: 1)));
    }).toList();
  }

  /// Get completed tasks
  List<Task> _getCompletedTasks(List<Task> allTasks) {
    return allTasks.where((task) => task.status == TaskStatus.completed).toList()
      ..sort((a, b) => (b.dueAt ?? DateTime.now()).compareTo(a.dueAt ?? DateTime.now()));
  }

  /// Build a task section with header and task list inline
  Widget _buildTaskSectionInline({
    required String title,
    required List<Task> tasks,
    required IconData icon,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6FB8E9),
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFD9D9D9), // Light text for dark theme
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${tasks.length}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6FB8E9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Task list or empty message
        if (tasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF242628), // Match dashboard header color
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.task_alt,
                  size: 40,
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.7),
                ),
                const SizedBox(height: 8),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFD9D9D9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ...tasks.take(3).map((task) => _buildInlineTaskCard(task)),
        
        // Show more button if there are more than 3 tasks
        if (tasks.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListScreen(),
                    ),
                  );
                },
                child: Text(
                  'View all ${tasks.length} tasks',
                  style: const TextStyle(
                    color: Color(0xFF6FB8E9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build collapsible completed tasks section
  Widget _buildCompletedTasksSection(List<Task> allTasks) {
    final completedTasks = _getCompletedTasks(allTasks);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Collapsible header
        InkWell(
          onTap: () {
            setState(() {
              _isCompletedTasksExpanded = !_isCompletedTasksExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  _isCompletedTasksExpanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6FB8E9),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle,
                  color: const Color(0xFF4CAF50),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Completed Tasks',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFD9D9D9), // Light text for dark theme
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${completedTasks.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Expanded task list or empty message
        if (_isCompletedTasksExpanded) ...[
          const SizedBox(height: 12),
          if (completedTasks.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF242628),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6FB8E9).withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.task_alt,
                    size: 40,
                    color: const Color(0xFF6FB8E9).withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No completed tasks yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFD9D9D9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else
            ...completedTasks.map((task) => _buildInlineTaskCard(task)),
        ],
      ],
    );
  }

  /// Build individual task card for inline display
  Widget _buildInlineTaskCard(Task task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 1,
        color: const Color(0xFF242628), // Match dashboard header color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _showTaskDetailsInline(task),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Task status checkbox
                GestureDetector(
                  onTap: () => _toggleTaskStatusInline(task),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: task.status == TaskStatus.completed
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFF6FB8E9),
                        width: 2,
                      ),
                      color: task.status == TaskStatus.completed
                          ? const Color(0xFF4CAF50)
                          : Colors.transparent,
                    ),
                    child: task.status == TaskStatus.completed
                        ? const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                
                // Task content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                          color: task.status == TaskStatus.completed
                              ? const Color(0xFF888888)
                              : const Color(0xFFD9D9D9), // Light text for dark theme
                        ),
                      ),
                      if (task.dueAt != null) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 12,
                              color: const Color(0xFF888888), // Lighter grey for dark theme
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDueDateInline(task.dueAt!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF888888), // Lighter grey for dark theme
                              ),
                            ),
                          ],
                        ),
                      ],
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

  /// Format due date for inline display
  String _formatDueDateInline(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (taskDate == today) {
      return 'Due today';
    } else if (taskDate == tomorrow) {
      return 'Due tomorrow';
    } else if (taskDate.isBefore(today)) {
      final diff = today.difference(taskDate).inDays;
      return 'Overdue by $diff day${diff > 1 ? 's' : ''}';
    } else {
      final diff = taskDate.difference(today).inDays;
      return 'Due in $diff day${diff > 1 ? 's' : ''}';
    }
  }

  /// Toggle task completion status inline
  void _toggleTaskStatusInline(Task task) {
    final provider = Provider.of<TaskProvider>(context, listen: false);
    final newStatus = task.status == TaskStatus.completed
        ? TaskStatus.pending
        : TaskStatus.completed;
    
    // Create updated task
    final updatedTask = Task(
      id: task.id,
      title: task.title,
      estMinutes: task.estMinutes,
      dueAt: task.dueAt,
      priority: task.priority,
      tags: task.tags,
      status: newStatus,
      linkedNoteId: task.linkedNoteId,
      linkedDeckId: task.linkedDeckId,
    );
    
    provider.updateTask(updatedTask);
  }

  /// Show task details inline
  void _showTaskDetailsInline(Task task) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(task.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Estimated time: ${task.estMinutes} minutes'),
            if (task.dueAt != null)
              Text('Due: ${_formatDueDateInline(task.dueAt!)}'),
            Text('Priority: ${_getPriorityTextInline(task.priority)}'),
            if (task.tags.isNotEmpty)
              Text('Tags: ${task.tags.join(', ')}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Get priority text inline
  String _getPriorityTextInline(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'Unknown';
    }
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

  /// Build circular chart showing quiz grade percentage
  Widget _buildGradeCircularChart(double grade) {
    final gradeColor = grade > 0 ? _getGradeColor(grade) : const Color(0xFF888888);
    final percentage = (grade * 100).round();
    final displayText = '$percentage%';
    
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 4,
              backgroundColor: Colors.transparent,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF242628),
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              value: grade,
              strokeWidth: 4,
              backgroundColor: const Color(0xFF242628),
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
            ),
          ),
          // Percentage text or dash if no quiz taken
          Text(
            displayText,
            style: TextStyle(
              color: gradeColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Get color based on grade percentage
  Color _getGradeColor(double grade) {
    // Return color based on grade percentage (0.0 to 1.0)
    if (grade >= 0.9) {
      return const Color(0xFF4CAF50); // Excellent - Green
    } else if (grade >= 0.8) {
      return const Color(0xFF6FB8E9); // Great - Blue
    } else if (grade >= 0.7) {
      return const Color(0xFFFFB74D); // Good - Amber
    } else if (grade >= 0.6) {
      return const Color(0xFFFF9800); // Fair - Orange
    } else {
      return const Color(0xFFEF5350); // Needs Improvement - Red
    }
  }

  /// Show AI flashcard generator as a modal overlay
  void _showAIFlashcardGeneratorModal(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF242628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
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
                          Icons.auto_awesome,
                          color: Color(0xFF6FB8E9),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Flashcard Generator',
                              style: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create flashcards using AI',
                              style: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFFD9D9D9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area with AI Flashcard Generator
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: const SingleChildScrollView(
                      child: AIFlashcardGenerator(),
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

  /// Show mode selection dialog for note (view/edit)
  void _showNoteModeSelection(BuildContext context, Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF242628),
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
                        Icons.note,
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
                            note.title,
                            style: const TextStyle(
                              color: Color(0xFFD9D9D9),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Updated ${_formatTimeAgo(note.updatedAt)}',
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
                
                const Text(
                  'Choose your action:',
                  style: TextStyle(
                    color: Color(0xFFD9D9D9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // View Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(
                            note: note,
                            startInEditMode: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.visibility),
                    label: const Text('View Note'),
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
                
                // Edit Mode Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteDetailScreen(
                            note: note,
                            startInEditMode: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Note'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF242628),
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
                
                const SizedBox(height: 12),
                
                // Generate Flashcards Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Extract plain text from note content
                      final plainText = _getPlainTextFromDelta(note.contentMd);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Scaffold(
                            appBar: AppBar(
                              title: const Text('Generate Flashcards'),
                              backgroundColor: const Color(0xFF242628),
                              foregroundColor: const Color(0xFFD9D9D9),
                            ),
                            backgroundColor: const Color(0xFF1A1A1A),
                            body: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: AIFlashcardGenerator(
                                  initialTopic: note.title,
                                  initialText: plainText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate Flashcards'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
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

  /// Show create note modal dialog
  void _showCreateNoteModal(BuildContext context) {
    debugPrint('_showCreateNoteModal called'); // Debug output
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF242628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
              maxHeight: 700,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
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
                          Icons.note_add,
                          color: Color(0xFF6FB8E9),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create Note',
                              style: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Create a new study note',
                              style: TextStyle(
                                color: Color(0xFFD9D9D9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(
                          Icons.close,
                          color: Color(0xFFD9D9D9),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Content area with Create Note Form
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: simple.CreateNoteForm(
                      onSaveNote: (Note note) {
                        Provider.of<NoteProvider>(context, listen: false).addNote(note);
                        Navigator.of(context).pop();
                      },
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

  /// Show dialog to edit an existing note
  void _showEditNoteDialog(BuildContext context, Note note, NoteProvider noteProvider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          note: note,
          startInEditMode: true,
        ),
      ),
    );
  }

  /// Show delete confirmation dialog for note
  void _showDeleteNoteDialog(BuildContext context, Note note, NoteProvider noteProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF242628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          title: const Text(
            'Delete Note',
            style: TextStyle(
              color: Color(0xFFD9D9D9),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "${note.title}"? This action cannot be undone.',
            style: const TextStyle(
              color: Color(0xFFD9D9D9),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFFD9D9D9),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await noteProvider.deleteNote(note.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note deleted successfully')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error deleting note: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
  void _showDeckModeSelection(BuildContext context, Deck deck) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: const Color(0xFF242628),
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
                      backgroundColor: const Color(0xFF242628),
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
        backgroundColor: const Color(0xFF242628),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF6FB8E9),
            width: 2,
          ),
        ),
        title: const Text(
          'Edit Deck',
          style: TextStyle(color: Color(0xFFD9D9D9)),
        ),
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
        backgroundColor: const Color(0xFF242628),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: Color(0xFF6FB8E9),
            width: 2,
          ),
        ),
        title: const Text(
          'Delete Deck',
          style: TextStyle(color: Color(0xFFD9D9D9)),
        ),
        content: Text(
          'Are you sure you want to delete "${deck.title}"? This action cannot be undone.',
          style: const TextStyle(color: Color(0xFFD9D9D9)),
        ),
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

  /// Show dialog to add cards to an existing deck
  void _showAddCardsDialog(BuildContext context, Deck deck, DeckProvider deckProvider) {
    showDialog(
      context: context,
      builder: (context) => _AddCardsDialog(deck: deck, deckProvider: deckProvider),
    );
  }

  /// Show dialog to add deck to calendar
  void _showAddToCalendarDialog(BuildContext context, Deck deck) {
    // Default to tomorrow at 10 AM
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    int selectedDuration = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF242628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFF6FB8E9),
                  width: 2,
                ),
              ),
              title: const Text(
                'Schedule Flashcard Study',
                style: TextStyle(color: Color(0xFFD9D9D9)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule study time for "${deck.title}"',
                      style: const TextStyle(color: Color(0xFFD9D9D9)),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF6FB8E9)),
                      title: const Text('Date', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Time Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Color(0xFF6FB8E9)),
                      title: const Text('Time', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: Text(
                        selectedTime.format(context),
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                      ),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Duration Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer, color: Color(0xFF6FB8E9)),
                      title: const Text('Duration', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: DropdownButton<int>(
                        value: selectedDuration,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF242628),
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 minutes')),
                          DropdownMenuItem(value: 30, child: Text('30 minutes')),
                          DropdownMenuItem(value: 45, child: Text('45 minutes')),
                          DropdownMenuItem(value: 60, child: Text('1 hour')),
                          DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                          DropdownMenuItem(value: 120, child: Text('2 hours')),
                        ],
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6FB8E9),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF6FB8E9), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${deck.cards.length} card${deck.cards.length == 1 ? '' : 's'} to review',
                              style: const TextStyle(color: Color(0xFFD9D9D9)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addToCalendar(context, deck, selectedDate, selectedDuration);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FB8E9),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Calendar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Add deck to calendar as a study event
  void _addToCalendar(BuildContext context, Deck deck, DateTime scheduledTime, int durationMinutes) async {
    try {
      // Create the calendar event from the deck
      final event = CalendarEvent.fromDeck(
        deck: deck,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );

      // Add to calendar provider
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      final addedEvent = await calendarProvider.addFlashcardStudyEvent(event);

      if (addedEvent != null && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${deck.title}" to calendar for ${scheduledTime.month}/${scheduledTime.day} at ${TimeOfDay.fromDateTime(scheduledTime).format(context)}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to planner screen
                Navigator.pushNamed(context, '/planner');
              },
            ),
          ),
        );
      } else if (context.mounted) {
        // Show error from provider
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to calendar'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show dialog to add note to calendar
  void _showAddNoteToCalendarDialog(BuildContext context, Note note) {
    // Default to tomorrow at 10 AM
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    selectedDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 10, 0);
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    int selectedDuration = 30; // Default 30 minutes

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF242628),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: Color(0xFF6FB8E9),
                  width: 2,
                ),
              ),
              title: const Text(
                'Schedule Note Review',
                style: TextStyle(color: Color(0xFFD9D9D9)),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule review time for "${note.title}"',
                      style: const TextStyle(color: Color(0xFFD9D9D9)),
                    ),
                    const SizedBox(height: 20),
                    
                    // Date Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF6FB8E9)),
                      title: const Text('Date', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: Text(
                        '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                      ),
                      onTap: () async {
                        final DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() {
                            selectedDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              selectedDate.hour,
                              selectedDate.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Time Picker
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Color(0xFF6FB8E9)),
                      title: const Text('Time', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: Text(
                        selectedTime.format(context),
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                      ),
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) {
                          setState(() {
                            selectedTime = picked;
                            selectedDate = DateTime(
                              selectedDate.year,
                              selectedDate.month,
                              selectedDate.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                    ),
                    
                    // Duration Selector
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.timer, color: Color(0xFF6FB8E9)),
                      title: const Text('Duration', style: TextStyle(color: Color(0xFFD9D9D9))),
                      subtitle: DropdownButton<int>(
                        value: selectedDuration,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF242628),
                        style: const TextStyle(color: Color(0xFFD9D9D9)),
                        items: const [
                          DropdownMenuItem(value: 15, child: Text('15 minutes')),
                          DropdownMenuItem(value: 30, child: Text('30 minutes')),
                          DropdownMenuItem(value: 45, child: Text('45 minutes')),
                          DropdownMenuItem(value: 60, child: Text('1 hour')),
                          DropdownMenuItem(value: 90, child: Text('1.5 hours')),
                          DropdownMenuItem(value: 120, child: Text('2 hours')),
                        ],
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedDuration = newValue;
                            });
                          }
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF6FB8E9),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFF6FB8E9), size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Note: ${note.title}${note.tags.isNotEmpty ? ' (${note.tags.join(', ')})' : ''}',
                              style: const TextStyle(color: Color(0xFFD9D9D9)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _addNoteToCalendar(context, note, selectedDate, selectedDuration);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6FB8E9),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add to Calendar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Add note to calendar as a review event
  void _addNoteToCalendar(BuildContext context, Note note, DateTime scheduledTime, int durationMinutes) async {
    try {
      // Create the calendar event from the note
      final event = CalendarEvent.fromNote(
        note: note,
        scheduledTime: scheduledTime,
        durationMinutes: durationMinutes,
      );

      // Add to calendar provider
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
      final addedEvent = await calendarProvider.createEvent(
        title: event.title,
        description: event.description,
        type: event.type,
        startTime: event.startTime,
        endTime: event.endTime,
        priority: event.priority,
        tags: event.tags,
        estimatedMinutes: event.estimatedMinutes,
        reminders: event.reminders,
      );

      if (addedEvent != null && context.mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "${note.title}" to calendar for ${scheduledTime.month}/${scheduledTime.day} at ${TimeOfDay.fromDateTime(scheduledTime).format(context)}'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to planner screen
                Navigator.pushNamed(context, '/planner');
              },
            ),
          ),
        );
      } else if (context.mounted) {
        // Show error from provider
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add to calendar'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add to calendar: $e'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dialog for adding multiple cards to a deck
class _AddCardsDialog extends StatefulWidget {
  final Deck deck;
  final DeckProvider deckProvider;

  const _AddCardsDialog({required this.deck, required this.deckProvider});

  @override
  State<_AddCardsDialog> createState() => _AddCardsDialogState();
}

class _AddCardsDialogState extends State<_AddCardsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  final _option1Controller = TextEditingController();
  final _option2Controller = TextEditingController();
  final _option3Controller = TextEditingController();
  final _option4Controller = TextEditingController();
  
  CardType _selectedType = CardType.basic;
  int _difficulty = 3;
  int _correctAnswerIndex = 0;
  int _cardsAdded = 0;

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _option1Controller.dispose();
    _option2Controller.dispose();
    _option3Controller.dispose();
    _option4Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF242628),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFF6FB8E9),
          width: 2,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add Cards to "${widget.deck.title}"',
            style: const TextStyle(color: Color(0xFFD9D9D9)),
          ),
          const SizedBox(height: 4),
          Text(
            'Cards added: $_cardsAdded',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card Type Selector
              DropdownButtonFormField<CardType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Card Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: CardType.basic,
                    child: Row(
                      children: [
                        Icon(Icons.article, size: 20),
                        SizedBox(width: 8),
                        Text('Basic (Front/Back)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: CardType.multipleChoice,
                    child: Row(
                      children: [
                        Icon(Icons.quiz, size: 20),
                        SizedBox(width: 8),
                        Text('Multiple Choice'),
                      ],
                    ),
                  ),
                ],
                onChanged: (CardType? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedType = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // Front/Question
              TextFormField(
                controller: _frontController,
                decoration: InputDecoration(
                  labelText: _selectedType == CardType.multipleChoice
                      ? 'Question *'
                      : 'Front (Question) *',
                  hintText: 'Enter the question or prompt',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the front content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              if (_selectedType == CardType.basic) ...[
                // Back/Answer for basic cards
                TextFormField(
                  controller: _backController,
                  decoration: const InputDecoration(
                    labelText: 'Back (Answer) *',
                    hintText: 'Enter the answer',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter the back content';
                    }
                    return null;
                  },
                ),
              ] else if (_selectedType == CardType.multipleChoice) ...[
                // Multiple choice options
                Text(
                  'Answer Options',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                
                _buildOptionField(_option1Controller, 'Option 1 *', 0),
                const SizedBox(height: 8),
                _buildOptionField(_option2Controller, 'Option 2 *', 1),
                const SizedBox(height: 8),
                _buildOptionField(_option3Controller, 'Option 3 *', 2),
                const SizedBox(height: 8),
                _buildOptionField(_option4Controller, 'Option 4 *', 3),
                const SizedBox(height: 16),
                
                // Correct answer selector
                Text(
                  'Correct Answer: Option ${_correctAnswerIndex + 1}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                ),
              ],
              const SizedBox(height: 16),
              
              // Difficulty Selector
              Text(
                'Difficulty',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(5, (index) {
                  final difficulty = index + 1;
                  final isSelected = _difficulty == difficulty;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < 4 ? 4 : 0,
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _difficulty = difficulty;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$difficulty',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(_cardsAdded > 0 ? 'Done' : 'Cancel'),
        ),
        if (_cardsAdded > 0)
          TextButton(
            onPressed: _addAnotherCard,
            child: const Text('Add Another'),
          ),
        ElevatedButton(
          onPressed: _saveCard,
          child: Text(_cardsAdded > 0 ? 'Add & Continue' : 'Add Card'),
        ),
      ],
    );
  }

  Widget _buildOptionField(TextEditingController controller, String label, int index) {
    final isCorrect = _correctAnswerIndex == index;
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green : Colors.grey,
                  width: isCorrect ? 2 : 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: isCorrect ? Colors.green : Colors.grey,
                  width: isCorrect ? 2 : 1,
                ),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Required';
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isCorrect ? Colors.green : Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _correctAnswerIndex = index;
            });
          },
          tooltip: 'Mark as correct answer',
        ),
      ],
    );
  }

  void _saveCard() {
    if (!_formKey.currentState!.validate()) return;

    // Create the new card
    final newCard = FlashCard(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deckId: widget.deck.id,
      type: _selectedType,
      front: _frontController.text.trim(),
      back: _selectedType == CardType.basic
          ? _backController.text.trim()
          : _option1Controller.text.trim(), // Use first option as back for MC
      multipleChoiceOptions: _selectedType == CardType.multipleChoice
          ? [
              _option1Controller.text.trim(),
              _option2Controller.text.trim(),
              _option3Controller.text.trim(),
              _option4Controller.text.trim(),
            ]
          : [],
      correctAnswerIndex: _selectedType == CardType.multipleChoice ? _correctAnswerIndex : 0,
      difficulty: _difficulty,
    );

    // Add card to deck
    widget.deckProvider.addCardToDeck(widget.deck.id, newCard);

    setState(() {
      _cardsAdded++;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Card added! Total: $_cardsAdded'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    // Clear form for next card
    _clearForm();
  }

  void _addAnotherCard() {
    _clearForm();
  }

  void _clearForm() {
    _frontController.clear();
    _backController.clear();
    _option1Controller.clear();
    _option2Controller.clear();
    _option3Controller.clear();
    _option4Controller.clear();
    setState(() {
      _difficulty = 3;
      _correctAnswerIndex = 0;
    });
  }
}
