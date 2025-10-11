import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:studypals/utils/responsive_spacing.dart';
import 'package:studypals/screens/day_itinerary_screen.dart';
import 'package:studypals/providers/calendar_provider.dart';

/// Widget that displays a compact calendar view with current date highlighted
/// Shows scrollable weeks with the current date highlighted in blue
class CalendarDisplayWidget extends StatefulWidget {
  const CalendarDisplayWidget({super.key});

  @override
  State<CalendarDisplayWidget> createState() => _CalendarDisplayWidgetState();
}

class _CalendarDisplayWidgetState extends State<CalendarDisplayWidget> {
  late final PageController _pageController;
  final int _centerPage = 1000; // Center page index
  DateTime _currentWeekStart = DateTime.now();
  int _currentPageIndex = 1000;
  bool _isAnimating = false;
  double _panStartX = 0.0;
  bool _isHovering = false;
  double? _lastPointerX;
  DateTime? _lastSwipeTime;

  @override
  void initState() {
    super.initState();
    // Calculate the start of the current week using device's current date
    final now = DateTime.now();
    _currentWeekStart = now.subtract(Duration(days: now.weekday % 7));
    _currentPageIndex = _centerPage;
    
    // Initialize page controller for controlled transitions
    _pageController = PageController(
      initialPage: _centerPage,
      viewportFraction: 1.0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Use minimum space needed
      children: [
        // Month and year header with week navigation
        Row(
          children: [
            Expanded(
              child: _buildMonthYearHeader(context),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Week day headers
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => Expanded(
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF6FB8E9),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 3),

        // Controlled calendar with hover and swipe detection
        Flexible(
          child: MouseRegion(
            onEnter: _handleMouseEnter,
            onExit: _handleMouseExit,
            child: Listener(
              onPointerMove: _handlePointerMove,
              onPointerDown: _handlePointerDown,
              onPointerUp: _handlePointerUp,
              child: GestureDetector(
                onPanStart: _handlePanStart,
                onPanUpdate: _handlePanUpdate,
                onPanEnd: _handlePanEnd,
                onTap: () {}, // Enable tap detection for better gesture recognition
                behavior: HitTestBehavior.translucent, // Allow gestures to pass through to children
                child: SizedBox(
                  height: ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton) * 0.75,
                  width: double.infinity, // Ensure full width coverage
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    physics: kIsWeb ? const NeverScrollableScrollPhysics() : const PageScrollPhysics(), // Enable native scrolling on mobile
                    itemBuilder: (context, index) => _buildWeekView(context, index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthYearHeader(BuildContext context) {
    // Get the representative date for the currently displayed week
    final weekOffset = _getWeekOffset();
    final displayWeekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
    final weekDays = List.generate(7, (index) => displayWeekStart.add(Duration(days: index)));
    
    // Use smarter month detection for weeks that span multiple months
    final selectedMonth = _getDisplayMonth(weekDays);
    final selectedYear = _getDisplayYear(weekDays, selectedMonth);
    
    final currentMonth = _getMonthName(selectedMonth);

    return Text(
      '$currentMonth $selectedYear',
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
    );
  }

  Widget _buildWeekView(BuildContext context, int pageIndex) {
    final weekOffset = pageIndex - _centerPage;
    final weekStart = _currentWeekStart.add(Duration(days: weekOffset * 7));
    final weekDays = List.generate(7, (index) => weekStart.add(Duration(days: index)));
    
    // Get the current display month using the same logic as the header
    final displayMonth = _getDisplayMonth(weekDays);

    return SizedBox(
      width: double.infinity,
      key: ValueKey('week_$pageIndex'), // Unique key for each week
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: weekDays
            .map((date) => Expanded(
                  child: Consumer<CalendarProvider>(
                    builder: (context, provider, child) {
                      final events = provider.getEventsForDay(date);
                      return GestureDetector(
                        onTap: () => _onDayTapped(context, date),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              height: ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton) * 0.55,
                              width: ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton) * 0.55,
                              decoration: BoxDecoration(
                                color: _isToday(date)
                                    ? const Color(0xFF6FB8E9)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${date.day}',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: _getDayTextColor(date, displayMonth),
                                        fontWeight: _isToday(date)
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                ),
                              ),
                            ),
                            // Event indicator dot below the circle - always show space for consistent alignment
                            SizedBox(
                              height: 8, // Reduced height to save space
                              child: events.isNotEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 1), // Minimal top padding
                                      child: Center(
                                        child: Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFF6FB8E9), // Always blue, regardless of selected date
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPageIndex = page;
      _isAnimating = false;
    });
  }

  /// Handle mouse enter for hover detection
  void _handleMouseEnter(PointerEvent event) {
    _isHovering = true;
  }

  /// Handle mouse exit for hover detection
  void _handleMouseExit(PointerEvent event) {
    _isHovering = false;
    _lastPointerX = null;
  }

  /// Handle pointer movement for swipe detection while hovering
  void _handlePointerMove(PointerMoveEvent event) {
    if (!_isHovering || _isAnimating) return;
    
    final currentX = event.localPosition.dx;
    
    if (_lastPointerX != null) {
      final deltaX = currentX - _lastPointerX!;
      const minSwipeDistance = kIsWeb ? 30.0 : 15.0; // Lower threshold for mobile
      
      // Check if we have significant movement for a swipe
      if (deltaX.abs() > minSwipeDistance) {
        final now = DateTime.now();
        
        // Throttle swipes to prevent multiple rapid triggers
        if (_lastSwipeTime == null || 
            now.difference(_lastSwipeTime!).inMilliseconds > 300) {
          
          if (deltaX > 0) {
            // Moving right - go to previous week
            _moveToWeek(-1);
          } else {
            // Moving left - go to next week
            _moveToWeek(1);
          }
          
          _lastSwipeTime = now;
          _lastPointerX = null; // Reset to prevent continuous triggering
        }
      }
    }
    
    _lastPointerX = currentX;
  }

  /// Handle pointer down
  void _handlePointerDown(PointerDownEvent event) {
    _lastPointerX = event.localPosition.dx;
  }

  /// Handle pointer up
  void _handlePointerUp(PointerUpEvent event) {
    // Keep the existing pan gesture logic for click-and-drag
  }

  /// Handle pan start to capture initial position
  void _handlePanStart(DragStartDetails details) {
    _panStartX = details.localPosition.dx;
  }

  /// Handle pan update for gesture tracking
  void _handlePanUpdate(DragUpdateDetails details) {
    // Track current position for better swipe detection
    final currentX = details.localPosition.dx;
    final deltaX = currentX - _panStartX;
    
    // For very fast swipes, we might want to trigger immediately
    if (deltaX.abs() > 50 && !_isAnimating) {
      // Optional: trigger on significant movement during update
      // This helps catch very fast swipes that might not have high velocity
    }
  }

  /// Handle pan end to determine swipe direction and animate exactly one week
  void _handlePanEnd(DragEndDetails details) {
    if (_isAnimating) return; // Prevent multiple animations
    
    // Add throttling to ensure only one swipe per gesture
    final now = DateTime.now();
    if (_lastSwipeTime != null && 
        now.difference(_lastSwipeTime!).inMilliseconds < 300) {
      return; // Too soon since last swipe, ignore this gesture
    }
    
    final velocity = details.velocity.pixelsPerSecond.dx;
    final primaryVelocity = details.primaryVelocity ?? 0.0;
    // Lower thresholds for mobile devices
    final minSwipeVelocity = kIsWeb ? 50.0 : 25.0; // Much lower threshold for mobile
    
    // Check both velocity types for better swipe detection
    final effectiveVelocity = velocity.abs() > primaryVelocity.abs() ? velocity : primaryVelocity;
    
    bool swipeDetected = false;
    
    if (effectiveVelocity.abs() > minSwipeVelocity) {
      if (effectiveVelocity > 0) {
        // Swipe right - go to previous week
        _moveToWeek(-1);
        swipeDetected = true;
      } else {
        // Swipe left - go to next week
        _moveToWeek(1);
        swipeDetected = true;
      }
    } else {
      // Also check the distance traveled for slow but deliberate swipes
      final panDistance = details.localPosition.dx - _panStartX;
      const minSwipeDistance = 20.0; // Lower minimum distance for swipe recognition
      
      if (panDistance.abs() > minSwipeDistance) {
        if (panDistance > 0) {
          // Swipe right - go to previous week
          _moveToWeek(-1);
          swipeDetected = true;
        } else {
          // Swipe left - go to next week
          _moveToWeek(1);
          swipeDetected = true;
        }
      }
    }
    
    // Update last swipe time only if a swipe was actually detected and executed
    if (swipeDetected) {
      _lastSwipeTime = now;
    }
  }

  /// Move exactly one week in the specified direction
  void _moveToWeek(int direction) {
    if (_isAnimating) return;
    
    _isAnimating = true;
    final targetPage = _currentPageIndex + direction;
    
    _pageController.animateToPage(
      targetPage,
      duration: const Duration(milliseconds: 300), // Smooth but quick
      curve: Curves.easeOutQuart, // Natural deceleration
    ).then((_) {
      _isAnimating = false;
    });
  }

  int _getWeekOffset() {
    return _currentPageIndex - _centerPage;
  }

  bool _isToday(DateTime date) {
    // Use device's current date
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  /// Smart month detection for weeks spanning multiple months
  /// Priority: 1) Month containing today, 2) Month with most days, 3) Later month
  int _getDisplayMonth(List<DateTime> weekDays) {
    final today = DateTime.now(); // Use device's current date
    
    // Count days per month in this week
    final monthCounts = <int, int>{};
    for (final day in weekDays) {
      monthCounts[day.month] = (monthCounts[day.month] ?? 0) + 1;
    }
    
    // Priority 1: If today is in this week, use today's month
    for (final day in weekDays) {
      if (_isToday(day)) {
        return today.month;
      }
    }
    
    // Priority 2: Use month with the most days
    var maxCount = 0;
    var selectedMonth = weekDays.first.month;
    
    monthCounts.forEach((month, count) {
      if (count > maxCount) {
        maxCount = count;
        selectedMonth = month;
      } else if (count == maxCount && month > selectedMonth) {
        // Priority 3: If tie, choose the later month (for month transitions)
        selectedMonth = month;
      }
    });
    
    return selectedMonth;
  }

  /// Get appropriate year for the selected month
  int _getDisplayYear(List<DateTime> weekDays, int selectedMonth) {
    // Find a day in the week that matches the selected month
    for (final day in weekDays) {
      if (day.month == selectedMonth) {
        return day.year;
      }
    }
    
    // Fallback to first day's year (shouldn't happen)
    return weekDays.first.year;
  }

  /// Get text color for calendar days based on month and today status
  Color _getDayTextColor(DateTime date, int displayMonth) {
    // Today always gets white text (on blue background)
    if (_isToday(date)) {
      return Colors.white;
    }
    
    // Days from other months get muted gray color
    if (date.month != displayMonth) {
      return const Color(0xFF4A4D52);
    }
    
    // Days from current month get default text color
    return const Color(0xFFFFFFFF); // White for dark theme
  }

  /// Handle day tap to navigate to day itinerary
  void _onDayTapped(BuildContext context, DateTime date) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayItineraryScreen(
          selectedDate: date,
        ),
      ),
    );
  }
}