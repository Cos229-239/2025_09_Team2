# Hover-Pinch Bar Chart Animation Test

## What the Animation Does

The new hover-pinch animation for the stats icon recreates the Lottie "wired-outline-153-bar-chart-hover-pinch.json" effect:

1. **Staggered Timing**: Each bar animates at different times:
   - Bar 1 (left): Starts immediately, peaks at 25% of animation, returns at 83%
   - Bar 2 (middle): Starts at 8%, peaks at 33%, returns at 91%
   - Bar 3 (right): Starts at 16%, peaks at 41%, returns at 100%

2. **Extension Effect**: Each bar extends upward by a scaled amount when activated, then contracts back to normal

3. **Smooth Easing**: Uses custom easing function matching Lottie curves for natural motion

## How to Test

1. Navigate to the dashboard screen
2. Tap the stats icon (bar chart) in the bottom navigation
3. Watch for the hover-pinch animation where bars extend and contract in sequence
4. Animation duration: 1000ms (1 second) to match the 60-frame Lottie timing

## Implementation Details

- **Custom Painter**: `AnimatedBarChartPainter` handles the hover-pinch effect
- **Animation Controller**: `_statsIconController` manages the 1-second animation
- **Staggered Timing**: Individual bar progress calculated with `_calculateBarProgress()`
- **Visual Effect**: Bars grow upward from their base positions, then return smoothly

## Expected Behavior

When you tap the stats icon, you should see:
1. Left bar extends first
2. Middle bar follows shortly after
3. Right bar extends last
4. All bars contract back in the same staggered pattern
5. Smooth, professional animation matching the original Lottie design