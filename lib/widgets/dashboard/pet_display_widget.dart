import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/pet_provider.dart';
import 'package:studypals/models/pet.dart';

/// Widget that displays the user's virtual pet in a 3D-ready container
/// This is a placeholder for future 3D rendering integration
class PetDisplayWidget extends StatefulWidget {
  const PetDisplayWidget({super.key});

  @override
  State<PetDisplayWidget> createState() => _PetDisplayWidgetState();
}

class _PetDisplayWidgetState extends State<PetDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();

    // Create floating animation for the pet
    _floatController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(
      begin: -10.0,
      end: 10.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PetProvider>(
      builder: (context, petProvider, child) {
        final pet = petProvider.currentPet;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2A3050),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF6FB8E9), // New blue border color
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // Background with artistic gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A3050),
                        const Color(0xFF1C1F35),
                        const Color(0xFF2A3050).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),

                // Decorative circles in background (like in the image)
                Positioned(
                  top: 20,
                  left: 20,
                  child: _buildDecorativeCircle(
                      30, Colors.white.withValues(alpha: 0.05)),
                ),
                Positioned(
                  top: 40,
                  right: 60,
                  child: _buildDecorativeCircle(
                      20, Colors.white.withValues(alpha: 0.03)),
                ),
                Positioned(
                  bottom: 50,
                  left: 80,
                  child: _buildDecorativeCircle(
                      25, Colors.white.withValues(alpha: 0.04)),
                ),
                Positioned(
                  bottom: 30,
                  right: 40,
                  child: _buildDecorativeCircle(
                      35, Colors.white.withValues(alpha: 0.05)),
                ),

                // Main content - pet display expanded
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Pet display area (3D placeholder) - expanded
                      Expanded(
                        child: AnimatedBuilder(
                          animation: _floatAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: Center(
                                child: _buildPetDisplay(context, pet),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Pet stats bar
                      _buildStatsBar(context, pet),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build decorative circle for background ambiance
  Widget _buildDecorativeCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  /// Build the pet display (placeholder for 3D model)
  Widget _buildPetDisplay(BuildContext context, pet) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 160,
        maxHeight: 160,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect behind pet
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF6FB8E9)
                      .withValues(alpha: 0.3), // New blue color
                  const Color(0xFF6FB8E9)
                      .withValues(alpha: 0.1), // New blue color
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Pet placeholder (replace with 3D model later)
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6FB8E9)
                      .withValues(alpha: 0.6), // New blue color
                  const Color(0xFF6FB8E9)
                      .withValues(alpha: 0.4), // New blue color
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6FB8E9)
                      .withValues(alpha: 0.3), // New blue color
                  blurRadius: 15,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.pets,
                size: 40,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),

          // Decorative sparkles
          Positioned(
            top: 10,
            right: 15,
            child: _buildSparkle(8),
          ),
          Positioned(
            bottom: 20,
            left: 10,
            child: _buildSparkle(6),
          ),
          Positioned(
            top: 30,
            left: 20,
            child: _buildSparkle(7),
          ),
        ],
      ),
    );
  }

  /// Build sparkle decoration
  Widget _buildSparkle(double size) {
    return Icon(
      Icons.star,
      size: size,
      color: Colors.white.withValues(alpha: 0.6),
    );
  }

  /// Build stats bar showing pet level, XP, and mood
  Widget _buildStatsBar(BuildContext context, Pet? pet) {
    final xpProgress = pet != null ? (pet.xpProgress * 100).toInt() : 0;
    final level = pet?.level ?? 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1F35).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              const Color(0xFF6FB8E9).withValues(alpha: 0.2), // New blue color
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            icon: Icons.grade,
            label: 'Level',
            value: level,
            color: const Color(0xFF6FB8E9), // New blue color
            isPercentage: false,
          ),
          _buildStatItem(
            context,
            icon: Icons.trending_up,
            label: 'XP Progress',
            value: xpProgress,
            color: Colors.blue,
            isPercentage: true,
          ),
          _buildStatItem(
            context,
            icon: Icons.emoji_emotions,
            label: 'Mood',
            value: _getMoodLevel(pet?.mood),
            color: Colors.green,
            isPercentage: true,
          ),
        ],
      ),
    );
  }

  /// Get mood as a percentage value for display
  int _getMoodLevel(PetMood? mood) {
    if (mood == null) return 75;
    switch (mood) {
      case PetMood.sleepy:
        return 25;
      case PetMood.content:
        return 50;
      case PetMood.happy:
        return 75;
      case PetMood.excited:
        return 100;
    }
  }

  /// Build individual stat item
  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int value,
    required Color color,
    bool isPercentage = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 24,
          color: color.withValues(alpha: 0.8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 10,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          isPercentage ? '$value%' : '$value',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
