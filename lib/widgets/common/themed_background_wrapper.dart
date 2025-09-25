import 'package:flutter/material.dart';
import 'animated_particle_background.dart';

/// A wrapper widget that provides a themed animated particle background
/// This widget ensures consistent background styling across the app
/// while being theme-aware
class ThemedBackgroundWrapper extends StatelessWidget {
  final Widget child;
  final int? particleCount;

  const ThemedBackgroundWrapper({
    super.key,
    required this.child,
    this.particleCount,
  });

  @override
  Widget build(BuildContext context) {
    // Use specific colors for dark theme
    // These colors are exclusive to the dark theme and won't affect future themes
    const darkThemeGradientColors = [
      Color(0xFF515B9B), // Lighter blue-purple
      Color(0xFF1C1F35), // Darker blue-gray
    ];

    return AnimatedParticleBackground(
      gradientColors: darkThemeGradientColors,
      particleCount: particleCount ?? 60,
      child: child,
    );
  }
}