import 'package:flutter/material.dart';

/// Responsive spacing utility for consistent spacing across different device sizes
/// Handles spacing for phones, tablets, and desktops with proper adaptations
class ResponsiveSpacing {
  /// Gets the screen width from context
  static double _getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Gets the screen height from context
  static double _getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Determines device type based on screen width
  static DeviceType _getDeviceType(BuildContext context) {
    double width = _getScreenWidth(context);
    if (width < 600) {
      return DeviceType.phone;
    } else if (width < 1024) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// Gets horizontal padding based on device type
  static double getHorizontalPadding(BuildContext context) {
    DeviceType deviceType = _getDeviceType(context);
    double width = _getScreenWidth(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        // For phones: 16px padding, scales slightly with width
        return 16.0 + (width - 320) * 0.02;
      case DeviceType.tablet:
        // For tablets: 24px padding, scales with width
        return 24.0 + (width - 600) * 0.03;
      case DeviceType.desktop:
        // For desktop: 32px padding
        return 32.0;
    }
  }

  /// Gets vertical spacing between components based on device type
  static double getVerticalSpacing(BuildContext context) {
    DeviceType deviceType = _getDeviceType(context);
    double height = _getScreenHeight(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        // For phones: 16px spacing, scales with height
        return 16.0 + (height - 600) * 0.015;
      case DeviceType.tablet:
        // For tablets: 24px spacing
        return 24.0 + (height - 800) * 0.01;
      case DeviceType.desktop:
        // For desktop: 32px spacing
        return 32.0;
    }
  }

  /// Gets small spacing for tight layouts
  static double getSmallSpacing(BuildContext context) {
    return getVerticalSpacing(context) * 0.5;
  }

  /// Gets large spacing for major sections
  static double getLargeSpacing(BuildContext context) {
    return getVerticalSpacing(context) * 1.5;
  }

  /// Gets header height based on device type
  static double getHeaderHeight(BuildContext context) {
    DeviceType deviceType = _getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return 60.0;
      case DeviceType.tablet:
        return 70.0;
      case DeviceType.desktop:
        return 80.0;
    }
  }

  /// Gets bottom navigation height based on device type
  static double getBottomNavHeight(BuildContext context) {
    DeviceType deviceType = _getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return 70.0;
      case DeviceType.tablet:
        return 75.0;
      case DeviceType.desktop:
        return 80.0;
    }
  }

  /// Gets component height based on device type and content
  static double getComponentHeight(BuildContext context, ComponentType type) {
    DeviceType deviceType = _getDeviceType(context);
    double height = _getScreenHeight(context);
    
    switch (type) {
      case ComponentType.calendar:
        switch (deviceType) {
          case DeviceType.phone:
            return height * 0.15; // 15% of screen height
          case DeviceType.tablet:
            return height * 0.18; // 18% of screen height
          case DeviceType.desktop:
            return height * 0.20; // 20% of screen height
        }
      case ComponentType.graph:
        switch (deviceType) {
          case DeviceType.phone:
            return height * 0.25; // 25% of screen height
          case DeviceType.tablet:
            return height * 0.28; // 28% of screen height
          case DeviceType.desktop:
            return height * 0.30; // 30% of screen height
        }
      case ComponentType.pet:
        switch (deviceType) {
          case DeviceType.phone:
            return height * 0.20; // 20% of screen height
          case DeviceType.tablet:
            return height * 0.22; // 22% of screen height
          case DeviceType.desktop:
            return height * 0.25; // 25% of screen height
        }
      case ComponentType.actionButton:
        switch (deviceType) {
          case DeviceType.phone:
            return 44.0; // Standard touch target size
          case DeviceType.tablet:
            return 48.0;
          case DeviceType.desktop:
            return 52.0;
        }
    }
  }

  /// Gets button spacing based on device type
  static double getButtonSpacing(BuildContext context) {
    DeviceType deviceType = _getDeviceType(context);
    double width = _getScreenWidth(context);
    
    switch (deviceType) {
      case DeviceType.phone:
        return width * 0.04; // 4% of screen width
      case DeviceType.tablet:
        return width * 0.03; // 3% of screen width
      case DeviceType.desktop:
        return 32.0; // Fixed spacing for desktop
    }
  }

  /// Gets content width with proper margins
  static double getContentWidth(BuildContext context) {
    double screenWidth = _getScreenWidth(context);
    double horizontalPadding = getHorizontalPadding(context);
    return screenWidth - (horizontalPadding * 2);
  }

  /// Gets safe area padding accounting for notches and navigation
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    MediaQueryData mediaQuery = MediaQuery.of(context);
    double horizontalPadding = getHorizontalPadding(context);
    double verticalSpacing = getVerticalSpacing(context);
    
    return EdgeInsets.only(
      left: horizontalPadding,
      right: horizontalPadding,
      top: mediaQuery.padding.top + verticalSpacing,
      bottom: mediaQuery.padding.bottom + verticalSpacing,
    );
  }
}

/// Device type enumeration
enum DeviceType {
  phone,
  tablet,
  desktop,
}

/// Component type enumeration for sizing
enum ComponentType {
  calendar,
  graph,
  pet,
  actionButton,
}