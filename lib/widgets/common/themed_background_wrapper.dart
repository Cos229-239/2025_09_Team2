import 'package:flutter/material.dart';

/// A wrapper widget that provides a themed solid background
/// This widget ensures consistent background styling across the app
/// while being theme-aware
class ThemedBackgroundWrapper extends StatelessWidget {
  final Widget child;

  const ThemedBackgroundWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    // Use specific colors for dark theme
    // Solid background color from Figma design
    const backgroundColor = Color(0xFF16181A);

    return Container(
      color: backgroundColor,
      child: child,
    );
  }
}
