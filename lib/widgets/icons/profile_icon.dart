import 'package:flutter/material.dart';

/// Custom Profile Icon Widget
/// Uses the user profile SVG icon with customizable color and size
class ProfileIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const ProfileIcon({
    super.key,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: ProfileIconPainter(
        color: color ?? Theme.of(context).iconTheme.color ?? Colors.black,
      ),
    );
  }
}

/// Custom painter for the profile icon SVG
class ProfileIconPainter extends CustomPainter {
  final Color color;

  ProfileIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final scaleX = size.width / 24.0;
    final scaleY = size.height / 24.0;

    canvas.scale(scaleX, scaleY);

    // Draw the outer circle (full person outline)
    final outerCircle = Path();
    outerCircle.addOval(Rect.fromCircle(center: const Offset(12, 12), radius: 11));
    canvas.drawPath(outerCircle, paint);

    // Draw the head (inner circle)
    final headCircle = Path();
    headCircle.addOval(Rect.fromCircle(center: const Offset(12, 9.75), radius: 3));
    canvas.drawPath(headCircle, paint);

    // Draw the body/shoulders (bottom arc)
    final bodyPath = Path();
    // Start from left shoulder area
    bodyPath.moveTo(6.018, 18.725);
    // Curve up to the neck area and back down to right shoulder
    bodyPath.cubicTo(8.5, 16.5, 10.5, 15.75, 12, 15.75);
    bodyPath.cubicTo(13.5, 15.75, 15.5, 16.5, 17.982, 18.725);
    
    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is ProfileIconPainter && oldDelegate.color != color;
  }
}