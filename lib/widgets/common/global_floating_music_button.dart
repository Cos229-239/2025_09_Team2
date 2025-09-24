import 'package:flutter/material.dart';
import '../../screens/spotify_integration_screen.dart';

/// A global floating music button that persists across all app screens
/// Uses an Overlay to stay visible during navigation
/// 
/// TODO: GLOBAL FLOATING MUSIC BUTTON IMPLEMENTATION GAPS
/// - Current implementation is UI ONLY - NO REAL MUSIC PLAYBACK FUNCTIONALITY
/// - Button redirects to Spotify screen but no actual music integration
/// - Need to implement real music player controls (play, pause, skip, volume)
/// - Missing integration with actual music streaming services
/// - Need to implement proper music state management across app navigation
/// - Missing now playing information display (song title, artist, album art)
/// - Need to implement proper audio session management and interruption handling
/// - Missing integration with device media controls and lock screen controls
/// - Need to implement proper background audio playback capabilities
/// - Missing integration with user's music preferences and study playlists
/// - Need to implement proper accessibility features for music controls
/// - Missing integration with focus modes and study session audio management
/// - Need to implement proper error handling for music service failures
/// - Missing battery optimization for background music playback
class GlobalFloatingMusicButton {
  static OverlayEntry? _overlayEntry;
  static bool _isVisible = false;
  static Offset _position = const Offset(20, 100);
  static const double _buttonSize = 56.0;

  /// Show the floating music button
  static void show(BuildContext context) {
    if (_isVisible || _overlayEntry != null) return;

    // Get screen size for initial positioning
    final screenSize = MediaQuery.of(context).size;
    if (_position == const Offset(20, 100)) {
      _position = Offset(
        screenSize.width - _buttonSize - 20,
        screenSize.height * 0.3,
      );
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => _FloatingMusicButtonWidget(
        position: _position,
        onPositionChanged: (newPosition) {
          _position = newPosition;
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _isVisible = true;
  }

  /// Hide the floating music button
  static void hide() {
    if (!_isVisible || _overlayEntry == null) return;

    _overlayEntry!.remove();
    _overlayEntry = null;
    _isVisible = false;
  }

  /// Update the position of the floating button
  static void updatePosition(Offset newPosition) {
    _position = newPosition;
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Check if the button is currently visible
  static bool get isVisible => _isVisible;
}

/// The actual floating music button widget
class _FloatingMusicButtonWidget extends StatefulWidget {
  final Offset position;
  final Function(Offset) onPositionChanged;

  const _FloatingMusicButtonWidget({
    required this.position,
    required this.onPositionChanged,
  });

  @override
  State<_FloatingMusicButtonWidget> createState() =>
      _FloatingMusicButtonWidgetState();
}

class _FloatingMusicButtonWidgetState
    extends State<_FloatingMusicButtonWidget> {
  late Offset _currentPosition;
  static const double _buttonSize = 56.0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      // Update position based on drag
      _currentPosition += details.delta;

      // Get current screen size
      final screenSize = MediaQuery.of(context).size;

      // Keep button within screen bounds
      _currentPosition = Offset(
        _currentPosition.dx.clamp(0, screenSize.width - _buttonSize),
        _currentPosition.dy.clamp(0, screenSize.height - _buttonSize - 80),
      );

      // Update the global position
      widget.onPositionChanged(_currentPosition);
    });
  }

  void _onTap() {
    // Navigate to Spotify integration screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SpotifyIntegrationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _currentPosition.dx,
      top: _currentPosition.dy,
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onTap: _onTap,
        child: Container(
          width: _buttonSize,
          height: _buttonSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(_buttonSize / 2),
              onTap: _onTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
