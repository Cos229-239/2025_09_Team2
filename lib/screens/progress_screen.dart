import 'package:flutter/material.dart';
import 'detailed_progress_screen.dart';

/// Progress Screen - Displays user's learning progress and statistics
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Simply show the detailed progress screen
    return const DetailedProgressScreen();
  }
}
