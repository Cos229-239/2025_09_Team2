/// Manual testing guide for responsive spacing
///
/// This guide helps you verify that the dashboard spacing works correctly
/// across different device sizes as shown in the attached image.
///
/// Test the following device configurations:
library;

// DEVICE CONFIGURATIONS TO TEST:
//
// 1. iPhone 14 Pro (393 x 852 logical pixels)
//    - Should use phone-specific spacing (16-20px base padding)
//    - Calendar height: ~128px (15% of 852)
//    - Graph height: ~213px (25% of 852)
//    - Action buttons: 44px height
//    - Navigation icons: compact spacing
//
// 2. iPad Pro (1024 x 1366 logical pixels)
//    - Should use tablet spacing (24-32px base padding)
//    - Calendar height: ~246px (18% of 1366)
//    - Graph height: ~382px (28% of 1366)
//    - Action buttons: 48px height
//    - Navigation icons: medium spacing
//
// 3. Samsung Galaxy S20 Ultra (412 x 915 logical pixels)
//    - Should use large phone spacing (16-22px base padding)
//    - Calendar height: ~137px (15% of 915)
//    - Graph height: ~229px (25% of 915)
//    - Action buttons: 44px height
//    - Button spacing: ~16px (4% of 412)

/// MANUAL TESTING STEPS:
///
/// 1. Open the app on each target device or use device simulator
/// 2. Navigate to the dashboard home screen
/// 3. Verify the following layout matches the attached image:
///
///    ✓ Header spacing from top edge
///    ✓ Calendar widget proportional height
///    ✓ Spacing between calendar and graph
///    ✓ Graph widget proportional height
///    ✓ Spacing between graph and action buttons
///    ✓ Action button row spacing (Calendar | Progress)
///    ✓ Spacing between action buttons and next content
///    ✓ Pet widget proportional height
///    ✓ Bottom navigation icon spacing
///    ✓ Bottom navigation padding
///
/// 4. Test in both portrait and landscape orientations
/// 5. Verify smooth transitions when rotating device
/// 6. Check that touch targets remain accessible (minimum 44px)

import 'package:flutter/material.dart';

class ResponsiveTestingHelper {
  /// Test widget to display current spacing values for debugging
  static Widget buildSpacingDebugInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            'Screen: ${MediaQuery.of(context).size.width} x ${MediaQuery.of(context).size.height}'),
        Text('Device Type: ${_getDeviceTypeName(context)}'),
        Text('Horizontal Padding: ${_getHorizontalPadding(context)}px'),
        Text('Vertical Spacing: ${_getVerticalSpacing(context)}px'),
        Text('Header Height: ${_getHeaderHeight(context)}px'),
        Text('Calendar Height: ${_getCalendarHeight(context)}px'),
        Text('Graph Height: ${_getGraphHeight(context)}px'),
        Text('Pet Height: ${_getPetHeight(context)}px'),
        Text('Action Button Height: ${_getActionButtonHeight(context)}px'),
        Text('Button Spacing: ${_getButtonSpacing(context)}px'),
      ],
    );
  }

  static String _getDeviceTypeName(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 'Phone';
    if (width < 1024) return 'Tablet';
    return 'Desktop';
  }

  static double _getHorizontalPadding(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return 16.0 + (width - 320) * 0.02;
    } else if (width < 1024) {
      return 24.0 + (width - 600) * 0.03;
    } else {
      return 32.0;
    }
  }

  static double _getVerticalSpacing(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    if (MediaQuery.of(context).size.width < 600) {
      return 16.0 + (height - 600) * 0.015;
    } else if (MediaQuery.of(context).size.width < 1024) {
      return 24.0 + (height - 800) * 0.01;
    } else {
      return 32.0;
    }
  }

  static double _getHeaderHeight(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 60.0;
    if (width < 1024) return 70.0;
    return 80.0;
  }

  static double _getCalendarHeight(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return height * 0.15;
    if (width < 1024) return height * 0.18;
    return height * 0.20;
  }

  static double _getGraphHeight(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return height * 0.25;
    if (width < 1024) return height * 0.28;
    return height * 0.30;
  }

  static double _getPetHeight(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return height * 0.20;
    if (width < 1024) return height * 0.22;
    return height * 0.25;
  }

  static double _getActionButtonHeight(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return 44.0;
    if (width < 1024) return 48.0;
    return 52.0;
  }

  static double _getButtonSpacing(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    if (width < 600) return width * 0.04;
    if (width < 1024) return width * 0.03;
    return 32.0;
  }
}

/// Widget to overlay spacing information on the dashboard for testing
class DebugSpacingOverlay extends StatelessWidget {
  final Widget child;
  final bool showDebugInfo;

  const DebugSpacingOverlay({
    super.key,
    required this.child,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDebugInfo) return child;

    return Stack(
      children: [
        child,
        Positioned(
          top: 50,
          right: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: ResponsiveTestingHelper.buildSpacingDebugInfo(context),
          ),
        ),
      ],
    );
  }
}
