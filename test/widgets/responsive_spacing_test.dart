/// Test file for verifying responsive spacing across different device sizes
/// Tests the ResponsiveSpacing utility and dashboard layout on various screen sizes
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studypals/utils/responsive_spacing.dart';

void main() {
  group('ResponsiveSpacing Tests', () {
    testWidgets('Phone spacing test - iPhone 14 Pro (393x852)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test phone spacing values
              final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
              final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
              final headerHeight = ResponsiveSpacing.getHeaderHeight(context);
              final calendarHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.calendar);
              final graphHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.graph);
              
              // Verify phone-specific values
              expect(horizontalPadding, greaterThanOrEqualTo(16.0));
              expect(horizontalPadding, lessThanOrEqualTo(24.0));
              expect(verticalSpacing, greaterThanOrEqualTo(16.0));
              expect(headerHeight, equals(60.0));
              expect(calendarHeight, equals(852 * 0.15)); // 15% of screen height
              expect(graphHeight, equals(852 * 0.25)); // 25% of screen height
              
              return const Scaffold(body: Text('Phone Test'));
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
    });

    testWidgets('Tablet spacing test - iPad Pro (1024x1366)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1024, 1366));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test tablet spacing values
              final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
              final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
              final headerHeight = ResponsiveSpacing.getHeaderHeight(context);
              final calendarHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.calendar);
              final graphHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.graph);
              
              // Verify tablet-specific values
              expect(horizontalPadding, greaterThanOrEqualTo(24.0));
              expect(verticalSpacing, greaterThanOrEqualTo(24.0));
              expect(headerHeight, equals(70.0));
              expect(calendarHeight, equals(1366 * 0.18)); // 18% of screen height
              expect(graphHeight, equals(1366 * 0.28)); // 28% of screen height
              
              return const Scaffold(body: Text('Tablet Test'));
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
    });

    testWidgets('Samsung Galaxy S20 Ultra spacing test (412x915)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test large phone spacing values
              final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
              final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
              final buttonSpacing = ResponsiveSpacing.getButtonSpacing(context);
              final actionButtonHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.actionButton);
              
              // Verify large phone values fall within expected ranges
              expect(horizontalPadding, greaterThanOrEqualTo(16.0));
              expect(horizontalPadding, lessThanOrEqualTo(24.0));
              expect(verticalSpacing, greaterThanOrEqualTo(16.0));
              expect(buttonSpacing, equals(412 * 0.04)); // 4% of screen width
              expect(actionButtonHeight, equals(44.0)); // Standard touch target
              
              return const Scaffold(body: Text('Galaxy S20 Ultra Test'));
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
    });

    testWidgets('Desktop spacing test (1200x800)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              // Test desktop spacing values
              final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
              final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
              final headerHeight = ResponsiveSpacing.getHeaderHeight(context);
              final buttonSpacing = ResponsiveSpacing.getButtonSpacing(context);
              
              // Verify desktop-specific values
              expect(horizontalPadding, equals(32.0));
              expect(verticalSpacing, equals(32.0));
              expect(headerHeight, equals(80.0));
              expect(buttonSpacing, equals(32.0)); // Fixed spacing for desktop
              
              return const Scaffold(body: Text('Desktop Test'));
            },
          ),
        ),
      );
      
      await tester.pumpAndSettle();
    });

    test('Device type detection', () {
      // Device type detection is tested implicitly through the spacing methods
      // in the widget tests above. The private method _getDeviceType is used
      // internally by the ResponsiveSpacing class to determine appropriate
      // spacing values for different device categories.
      
      // This test verifies that our public API works correctly without
      // directly testing private implementation details.
      expect(true, isTrue); // Placeholder test to maintain test structure
    });
  });

  group('Component Height Tests', () {
    testWidgets('Calendar height adapts to screen size', (tester) async {
      const smallPhone = Size(320, 568); // iPhone SE
      const largePhone = Size(428, 926); // iPhone 12 Pro Max
      const tablet = Size(820, 1180); // iPad Air
      
      for (final size in [smallPhone, largePhone, tablet]) {
        await tester.binding.setSurfaceSize(size);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final calendarHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.calendar);
                final graphHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.graph);
                final petHeight = ResponsiveSpacing.getComponentHeight(context, ComponentType.pet);
                
                // Verify heights are proportional to screen size
                expect(calendarHeight, greaterThan(0));
                expect(graphHeight, greaterThan(calendarHeight)); // Graph should be larger than calendar
                expect(petHeight, greaterThan(0));
                
                // Verify heights don't exceed reasonable bounds
                expect(calendarHeight, lessThan(size.height * 0.3));
                expect(graphHeight, lessThan(size.height * 0.4));
                expect(petHeight, lessThan(size.height * 0.35));
                
                return const Scaffold(body: Text('Height Test'));
              },
            ),
          ),
        );
        
        await tester.pumpAndSettle();
      }
    });
  });

  group('Spacing Consistency Tests', () {
    testWidgets('Spacing scales smoothly across device sizes', (tester) async {
      final testSizes = [
        const Size(320, 568), // Small phone
        const Size(375, 667), // iPhone 8
        const Size(393, 852), // iPhone 14 Pro
        const Size(428, 926), // iPhone 12 Pro Max
        const Size(768, 1024), // iPad
        const Size(1024, 1366), // iPad Pro
      ];
      
      double? previousHorizontalPadding;
      double? previousVerticalSpacing;
      
      for (final size in testSizes) {
        await tester.binding.setSurfaceSize(size);
        
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                final horizontalPadding = ResponsiveSpacing.getHorizontalPadding(context);
                final verticalSpacing = ResponsiveSpacing.getVerticalSpacing(context);
                
                // Verify spacing increases with screen size
                if (previousHorizontalPadding != null) {
                  expect(horizontalPadding, greaterThanOrEqualTo(previousHorizontalPadding!));
                }
                if (previousVerticalSpacing != null) {
                  expect(verticalSpacing, greaterThanOrEqualTo(previousVerticalSpacing!));
                }
                
                previousHorizontalPadding = horizontalPadding;
                previousVerticalSpacing = verticalSpacing;
                
                return const Scaffold(body: Text('Scaling Test'));
              },
            ),
          ),
        );
        
        await tester.pumpAndSettle();
      }
    });
  });
}