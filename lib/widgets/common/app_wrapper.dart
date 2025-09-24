import 'package:flutter/material.dart';
import 'global_floating_music_button.dart';

/// Wrapper widget that provides global app functionality like floating music button
class AppWrapper extends StatefulWidget {
  final Widget child;

  const AppWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Show the floating music button after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        GlobalFloatingMusicButton.show(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Hide the floating music button when the app is disposed
    GlobalFloatingMusicButton.hide();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes
    switch (state) {
      case AppLifecycleState.resumed:
        // Show the button when app is resumed
        if (mounted && !GlobalFloatingMusicButton.isVisible) {
          GlobalFloatingMusicButton.show(context);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Hide the button when app is paused or detached
        GlobalFloatingMusicButton.hide();
        break;
      case AppLifecycleState.inactive:
        // Keep the button visible when inactive (e.g., during navigation)
        break;
      case AppLifecycleState.hidden:
        GlobalFloatingMusicButton.hide();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
