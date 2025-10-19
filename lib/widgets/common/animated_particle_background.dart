import 'package:flutter/material.dart';
import 'dart:math';

// TODO: Animated Particle Background - Performance and Feature Gaps
// - No particle physics or collision detection
// - Missing interactive particles that respond to touch
// - No dynamic particle count based on device performance
// - Missing different particle shapes and effects
// - No optimization for low-end devices (performance scaling)
// - Missing particle trails or motion blur effects
// - No sound interaction or audio-visual synchronization
// - Missing seasonal or theme-based particle variations
// - No GPU acceleration for large particle counts
// - Missing particle pooling for memory efficiency
// - No customizable particle behaviors or patterns
// - Missing accessibility considerations for motion sensitivity

class AnimatedParticleBackground extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final int particleCount;

  const AnimatedParticleBackground({
    super.key,
    required this.child,
    required this.gradientColors,
    this.particleCount = 50,
  });

  @override
  State<AnimatedParticleBackground> createState() =>
      _AnimatedParticleBackgroundState();
}

class _AnimatedParticleBackgroundState extends State<AnimatedParticleBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration:
          const Duration(minutes: 5), // Ultra slow 5-minute animation cycle
      vsync: this,
    );

    // Create particles
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_createParticle());
    }

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Particle _createParticle() {
    return Particle(
      x: _random.nextDouble(),
      y: _random.nextDouble(),
      size: _random.nextDouble() * 3 + 1,
      speed: _random.nextDouble() * 0.02 + 0.005, // Ultra slow speed range
      opacity: _random.nextDouble() * 0.3 + 0.1,
      direction: _random.nextDouble() * 2 * pi,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.gradientColors,
        ),
      ),
      child: Stack(
        children: [
          // Particle layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _controller.value),
                );
              },
            ),
          ),
          // Content layer
          widget.child,
        ],
      ),
    );
  }
}

class Particle {
  double x;
  double y;
  final double size;
  final double speed;
  final double opacity;
  final double direction;

  Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.direction,
  });
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white.withValues(alpha: 0.1);

    for (final particle in particles) {
      // Update particle position with slightly more movement (still subtle)
      particle.x += cos(particle.direction) * particle.speed * 0.002;
      particle.y += sin(particle.direction) * particle.speed * 0.002;

      // Wrap around screen edges
      if (particle.x > 1.0) particle.x = 0.0;
      if (particle.x < 0.0) particle.x = 1.0;
      if (particle.y > 1.0) particle.y = 0.0;
      if (particle.y < 0.0) particle.y = 1.0;

      // Draw particle
      paint.color = Colors.white.withValues(alpha: particle.opacity * 0.5);
      canvas.drawCircle(
        Offset(particle.x * size.width, particle.y * size.height),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
