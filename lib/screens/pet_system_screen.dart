import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:studypals/providers/pet_provider.dart';
import 'package:studypals/models/pet.dart';

/// Pet System Screen - Complete pet interaction and care system
/// Features all interactions from the pet system requirements:
/// - Heart bar for advancing pet to next level
/// - Earn pet candy by study time with buddy
/// - Buddy interaction options
/// - Play together options
/// - Give toy
/// - Dress pet
/// - Background furniture
/// - Take snapshot
/// - Bar for access based on interactions
class PetSystemScreen extends StatefulWidget {
  const PetSystemScreen({super.key});

  @override
  State<PetSystemScreen> createState() => _PetSystemScreenState();
}

class _PetSystemScreenState extends State<PetSystemScreen> with TickerProviderStateMixin {
  late AnimationController _petAnimationController;
  late Animation<double> _petBounceAnimation;
  
  String? _selectedCategory; // Track which interaction category is selected
  PetSpecies? _previewingSpecies; // Track which pet species is being previewed

  @override
  void initState() {
    super.initState();
    
    // Initialize pet bounce animation
    _petAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    
    _petBounceAnimation = Tween<double>(
      begin: -5.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: _petAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _petAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1C2E),
      appBar: AppBar(
        title: const Text(
          'Pet System',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF242638),
        elevation: 0,
        automaticallyImplyLeading: false, // Removes the back arrow
        actions: [
          Consumer<PetProvider>(
            builder: (context, petProvider, child) {
              // Only show change pet button if user has a pet
              if (petProvider.currentPet != null) {
                return IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Change Pet',
                  onPressed: () {
                    _showChangePetDialog(context, petProvider);
                  },
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: Consumer<PetProvider>(
        builder: (context, petProvider, child) {
          final pet = petProvider.currentPet;

          // Show loading only while actually loading
          if (petProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading your Study Buddy...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          // If not loading and no pet exists, show create pet screen or preview
          if (pet == null) {
            // If previewing a species, show preview screen
            if (_previewingSpecies != null) {
              return _buildPetPreviewScreen(context, petProvider, _previewingSpecies!);
            }
            // Otherwise show selection screen
            return _buildCreatePetScreen(context, petProvider);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Heart Bar for advancing pet to next level
                _buildHeartBar(context, pet),
                const SizedBox(height: 24),
                
                // Pet Display Area
                _buildPetDisplay(context, pet),
                const SizedBox(height: 24),
                
                // Pet Stats Card
                _buildStatsCard(context, pet, petProvider),
                const SizedBox(height: 24),
                
                // Interaction Categories
                _buildInteractionCategories(context, petProvider),
                const SizedBox(height: 16),
                
                // Display selected category actions
                if (_selectedCategory != null)
                  _buildCategoryActions(context, _selectedCategory!, petProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build heart bar showing progress to next level
  Widget _buildHeartBar(BuildContext context, Pet pet) {
    final progress = pet.xpProgress;
    final hearts = (progress * 10).ceil().clamp(0, 10); // 0-10 hearts based on XP progress
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Level ${pet.level}',
                style: const TextStyle(
                  color: Color(0xFF6FB8E9),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Heart icons display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(10, (index) {
              final isFilled = index < hearts;
              return Icon(
                isFilled ? Icons.favorite : Icons.favorite_border,
                color: isFilled ? Colors.pinkAccent : Colors.grey[700],
                size: 24,
              );
            }),
          ),
          
          const SizedBox(height: 8),
          
          // XP Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6FB8E9)),
              minHeight: 8,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            '${pet.xp} / ${pet.xpForNextLevel} XP',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  /// Build pet display with animation
  Widget _buildPetDisplay(BuildContext context, Pet pet) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2A3050),
            const Color(0xFF1A1C2E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decorative elements
          Positioned(
            top: 20,
            right: 20,
            child: Icon(
              Icons.star,
              color: Colors.white.withValues(alpha: 0.1),
              size: 40,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 30,
            child: Icon(
              Icons.star,
              color: Colors.white.withValues(alpha: 0.08),
              size: 30,
            ),
          ),
          
          // Animated pet display
          Center(
            child: AnimatedBuilder(
              animation: _petBounceAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _petBounceAnimation.value),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Pet avatar (placeholder for 3D model)
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              const Color(0xFF6FB8E9).withValues(alpha: 0.6),
                              const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 70,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Pet name/type
                      Text(
                        _getPetSpeciesName(pet.species),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Pet mood
                      Text(
                        _getMoodEmoji(pet.mood),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build stats card showing candy, toys, interactions
  Widget _buildStatsCard(BuildContext context, Pet pet, PetProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pet Stats',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.cookie,
                label: 'Candy',
                value: '0', // TODO: Add to pet model
                color: Colors.pink,
              ),
              _buildStatItem(
                icon: Icons.toys,
                label: 'Toys',
                value: pet.gear.length.toString(),
                color: Colors.amber,
              ),
              _buildStatItem(
                icon: Icons.touch_app,
                label: 'Interactions',
                value: '0', // TODO: Add to pet model
                color: Colors.green,
              ),
              _buildStatItem(
                icon: Icons.access_time,
                label: 'Study Time',
                value: '0h', // TODO: Add tracking
                color: Colors.blue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// Build interaction categories
  Widget _buildInteractionCategories(BuildContext context, PetProvider provider) {
    final categories = [
      {'id': 'buddy', 'icon': Icons.favorite, 'label': 'Buddy', 'color': Colors.pinkAccent},
      {'id': 'play', 'icon': Icons.sports_esports, 'label': 'Play', 'color': Colors.orange},
      {'id': 'toy', 'icon': Icons.toys, 'label': 'Give Toy', 'color': Colors.amber},
      {'id': 'dress', 'icon': Icons.checkroom, 'label': 'Dress', 'color': Colors.purple},
      {'id': 'furniture', 'icon': Icons.chair, 'label': 'Furniture', 'color': Colors.teal},
      {'id': 'snapshot', 'icon': Icons.camera_alt, 'label': 'Snapshot', 'color': Colors.blue},
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interactions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((category) {
              final isSelected = _selectedCategory == category['id'];
              return _buildCategoryButton(
                icon: category['icon'] as IconData,
                label: category['label'] as String,
                color: category['color'] as Color,
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedCategory = isSelected ? null : category['id'] as String;
                  });
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.3) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[400],
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build category-specific actions
  Widget _buildCategoryActions(BuildContext context, String category, PetProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3050),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: _getCategoryContent(context, category, provider),
    );
  }

  Widget _getCategoryContent(BuildContext context, String category, PetProvider provider) {
    switch (category) {
      case 'buddy':
        return _buildBuddyActions(context, provider);
      case 'play':
        return _buildPlayActions(context, provider);
      case 'toy':
        return _buildToyActions(context, provider);
      case 'dress':
        return _buildDressActions(context, provider);
      case 'furniture':
        return _buildFurnitureActions(context, provider);
      case 'snapshot':
        return _buildSnapshotActions(context, provider);
      default:
        return const SizedBox();
    }
  }

  /// Buddy interaction actions
  Widget _buildBuddyActions(BuildContext context, PetProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Study with Buddy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Earn pet candy based on the amount of time you study with your buddy!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.feedPet();
                  _showInteractionFeedback(context, 'Fed your buddy! +15 XP');
                },
                icon: const Icon(Icons.restaurant),
                label: const Text('Feed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  provider.playWithPet();
                  _showInteractionFeedback(context, 'Played with buddy! +20 XP');
                },
                icon: const Icon(Icons.favorite),
                label: const Text('Pet'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.pinkAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Play together actions
  Widget _buildPlayActions(BuildContext context, PetProvider provider) {
    final playOptions = [
      {'icon': Icons.sports_soccer, 'label': 'Fetch', 'xp': 25},
      {'icon': Icons.pool, 'label': 'Swim', 'xp': 30},
      {'icon': Icons.run_circle, 'label': 'Run', 'xp': 20},
      {'icon': Icons.emoji_emotions, 'label': 'Tricks', 'xp': 35},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Play Together',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Choose an activity to play with your pet!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: playOptions.map((option) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 80) / 2,
              child: ElevatedButton(
                onPressed: () {
                  provider.addXP(option['xp'] as int, source: option['label'] as String);
                  _showInteractionFeedback(
                    context,
                    '${option['label']}! +${option['xp']} XP',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A4060),
                  padding: const EdgeInsets.all(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      option['icon'] as IconData,
                      color: Colors.orange,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      option['label'] as String,
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      '+${option['xp']} XP',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Give toy actions
  Widget _buildToyActions(BuildContext context, PetProvider provider) {
    final toys = [
      {'icon': Icons.sports_baseball, 'label': 'Ball', 'candy': 50},
      {'icon': Icons.pets, 'label': 'Plush Toy', 'candy': 75},
      {'icon': Icons.circle, 'label': 'Frisbee', 'candy': 60},
      {'icon': Icons.build, 'label': 'Puzzle Toy', 'candy': 100},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Give Toy',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Give your pet a toy! Costs candy earned from studying.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: toys.map((toy) {
            return Card(
              color: const Color(0xFF3A4060),
              child: InkWell(
                onTap: () {
                  _showInteractionFeedback(
                    context,
                    'Gave ${toy['label']}! Your pet is happy! (Requires ${toy['candy']} candy)',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        toy['icon'] as IconData,
                        color: Colors.amber,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        toy['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cookie,
                            color: Colors.pink,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${toy['candy']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Dress pet actions
  Widget _buildDressActions(BuildContext context, PetProvider provider) {
    final outfits = [
      {'icon': Icons.school, 'label': 'School Uniform', 'candy': 100},
      {'icon': Icons.star, 'label': 'Star Costume', 'candy': 150},
      {'icon': Icons.whatshot, 'label': 'Cool Jacket', 'candy': 120},
      {'icon': Icons.diamond, 'label': 'Royal Outfit', 'candy': 200},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dress Your Pet',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Customize your pet\'s appearance with cool outfits!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: outfits.map((outfit) {
            return Card(
              color: const Color(0xFF3A4060),
              child: InkWell(
                onTap: () {
                  _showInteractionFeedback(
                    context,
                    'Dressed in ${outfit['label']}! (Requires ${outfit['candy']} candy)',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        outfit['icon'] as IconData,
                        color: Colors.purple,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        outfit['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cookie,
                            color: Colors.pink,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${outfit['candy']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Background furniture actions
  Widget _buildFurnitureActions(BuildContext context, PetProvider provider) {
    final furniture = [
      {'icon': Icons.bed, 'label': 'Cozy Bed', 'candy': 80},
      {'icon': Icons.desk, 'label': 'Study Desk', 'candy': 100},
      {'icon': Icons.chair, 'label': 'Comfy Chair', 'candy': 60},
      {'icon': Icons.dashboard, 'label': 'Play Mat', 'candy': 70},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Background Furniture',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Decorate your pet\'s space with furniture!',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: furniture.map((item) {
            return Card(
              color: const Color(0xFF3A4060),
              child: InkWell(
                onTap: () {
                  _showInteractionFeedback(
                    context,
                    'Added ${item['label']}! (Requires ${item['candy']} candy)',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        color: Colors.teal,
                        size: 40,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['label'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cookie,
                            color: Colors.pink,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${item['candy']}',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Snapshot actions
  Widget _buildSnapshotActions(BuildContext context, PetProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Take Snapshot',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Capture memories with your pet! Snapshots are saved to your gallery.',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showInteractionFeedback(
                    context,
                    'Snapshot taken! Check your gallery.',
                  );
                },
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _showInteractionFeedback(
                    context,
                    'Opening gallery...',
                  );
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('View Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3A4060),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Show feedback after interaction
  void _showInteractionFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(message),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6FB8E9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Helper to get pet species name
  String _getPetSpeciesName(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return 'Study Cat';
      case PetSpecies.dog:
        return 'Study Dog';
      case PetSpecies.dragon:
        return 'Study Dragon';
      case PetSpecies.owl:
        return 'Study Owl';
      case PetSpecies.fox:
        return 'Study Fox';
    }
  }

  /// Helper to get mood emoji
  String _getMoodEmoji(PetMood mood) {
    switch (mood) {
      case PetMood.excited:
        return '🤩';
      case PetMood.happy:
        return '😊';
      case PetMood.content:
        return '😌';
      case PetMood.sleepy:
        return '😴';
    }
  }

  /// Build create pet screen for new users
  Widget _buildCreatePetScreen(BuildContext context, PetProvider petProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets,
              size: 100,
              color: Color(0xFF6FB8E9),
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome to Pet System!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose your Study Buddy to keep you motivated!',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            
            // Pet species selection
            const Text(
              'Choose Your Pet:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: [
                _buildPetSpeciesOption(
                  context,
                  petProvider,
                  PetSpecies.cat,
                  '🐱',
                  'Cat',
                ),
                _buildPetSpeciesOption(
                  context,
                  petProvider,
                  PetSpecies.dog,
                  '🐶',
                  'Dog',
                ),
                _buildPetSpeciesOption(
                  context,
                  petProvider,
                  PetSpecies.dragon,
                  '🐉',
                  'Dragon',
                ),
                _buildPetSpeciesOption(
                  context,
                  petProvider,
                  PetSpecies.owl,
                  '🦉',
                  'Owl',
                ),
                _buildPetSpeciesOption(
                  context,
                  petProvider,
                  PetSpecies.fox,
                  '🦊',
                  'Fox',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual pet species selection card
  Widget _buildPetSpeciesOption(
    BuildContext context,
    PetProvider petProvider,
    PetSpecies species,
    String emoji,
    String name,
  ) {
    return GestureDetector(
      onTap: () {
        // Show preview instead of creating immediately
        setState(() {
          _previewingSpecies = species;
        });
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3050),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6FB8E9).withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 50),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to preview',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build pet preview screen showing features before final selection
  Widget _buildPetPreviewScreen(
    BuildContext context,
    PetProvider petProvider,
    PetSpecies species,
  ) {
    final speciesName = _getPetSpeciesName(species);
    final speciesEmoji = _getSpeciesEmoji(species);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Back button to return to selection
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _previewingSpecies = null;
                });
              },
              icon: const Icon(Icons.arrow_back, color: Color(0xFF6FB8E9)),
              label: const Text(
                'Back to Selection',
                style: TextStyle(color: Color(0xFF6FB8E9)),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Pet preview display
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2A3050),
                  const Color(0xFF1A1C2E),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    speciesEmoji,
                    style: const TextStyle(fontSize: 100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    speciesName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Features section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Features:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                ..._getPetFeatures(species).map((feature) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Color(0xFF6FB8E9),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Special abilities
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3050),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF6FB8E9).withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Special Trait:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _getSpecialTrait(species),
                  style: const TextStyle(
                    color: Color(0xFF6FB8E9),
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Choose this pet button
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                await petProvider.createDefaultPet(species);
                if (context.mounted) {
                  setState(() {
                    _previewingSpecies = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🎉 $speciesName is now your Study Buddy!'),
                      backgroundColor: const Color(0xFF6FB8E9),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6FB8E9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Choose $speciesName',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Get emoji for pet species
  String _getSpeciesEmoji(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return '🐱';
      case PetSpecies.dog:
        return '🐶';
      case PetSpecies.dragon:
        return '🐉';
      case PetSpecies.owl:
        return '🦉';
      case PetSpecies.fox:
        return '🦊';
    }
  }

  /// Get features list for each pet species
  List<String> _getPetFeatures(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return [
          'Independent and curious companion',
          'Bonus XP for late-night study sessions',
          'Purrs when you complete tasks',
          'Loves cozy study environments',
          'Perfect for focused learners',
        ];
      case PetSpecies.dog:
        return [
          'Loyal and energetic friend',
          'Bonus XP for consistent daily habits',
          'Excited when you reach study goals',
          'Great for motivation and accountability',
          'Perfect for active learners',
        ];
      case PetSpecies.dragon:
        return [
          'Powerful and mythical guardian',
          'Bonus XP for completing difficult tasks',
          'Breathes fire when you level up',
          'Collects treasure (achievements)',
          'Perfect for ambitious learners',
        ];
      case PetSpecies.owl:
        return [
          'Wise and knowledgeable mentor',
          'Bonus XP for reading and research',
          'Hoots wisdom when you study',
          'Best for intellectual pursuits',
          'Perfect for analytical learners',
        ];
      case PetSpecies.fox:
        return [
          'Clever and adaptable buddy',
          'Bonus XP for creative problem-solving',
          'Quick and playful personality',
          'Great for learning new skills',
          'Perfect for versatile learners',
        ];
    }
  }

  /// Get special trait description for each species
  String _getSpecialTrait(PetSpecies species) {
    switch (species) {
      case PetSpecies.cat:
        return '✨ "Night Owl Mode" - Extra XP boost during evening study sessions!';
      case PetSpecies.dog:
        return '✨ "Streak Master" - Multiplies XP when maintaining study streaks!';
      case PetSpecies.dragon:
        return '✨ "Dragon\'s Hoard" - Rare chance to find bonus achievements!';
      case PetSpecies.owl:
        return '✨ "Wisdom Boost" - Increases XP from flashcard reviews!';
      case PetSpecies.fox:
        return '✨ "Quick Learner" - Bonus XP when mastering new topics fast!';
    }
  }

  /// Show dialog to change pet species
  void _showChangePetDialog(BuildContext context, PetProvider petProvider) {
    final currentPet = petProvider.currentPet!;
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A3050),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(
              color: Color(0xFF6FB8E9),
              width: 2,
            ),
          ),
          title: const Text(
            'Change Your Pet',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a new pet to accompany you on your study journey!',
                style: TextStyle(
                  color: Colors.grey[300],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6FB8E9).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6FB8E9).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF6FB8E9),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your Level ${currentPet.level} and ${currentPet.xp} XP will be kept!',
                        style: const TextStyle(
                          color: Color(0xFF6FB8E9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // Pet selection grid
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: PetSpecies.values.map((species) {
                  final isCurrentPet = species == currentPet.species;
                  return GestureDetector(
                    onTap: isCurrentPet ? null : () async {
                      Navigator.of(dialogContext).pop();
                      await petProvider.changePetSpecies(species);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '🎉 Changed to ${_getPetSpeciesName(species)}! Your progress is preserved.',
                            ),
                            backgroundColor: const Color(0xFF6FB8E9),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 90,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCurrentPet 
                          ? const Color(0xFF6FB8E9).withValues(alpha: 0.3)
                          : const Color(0xFF1A1C2E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentPet
                            ? const Color(0xFF6FB8E9)
                            : Colors.grey.withValues(alpha: 0.3),
                          width: isCurrentPet ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _getSpeciesEmoji(species),
                            style: TextStyle(
                              fontSize: 32,
                              color: isCurrentPet ? Colors.white : Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getPetSpeciesName(species).replaceAll('Study ', ''),
                            style: TextStyle(
                              color: isCurrentPet ? Colors.white : Colors.grey[400],
                              fontSize: 12,
                              fontWeight: isCurrentPet ? FontWeight.bold : FontWeight.normal,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (isCurrentPet)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'Current',
                                style: TextStyle(
                                  color: Color(0xFF6FB8E9),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        );
      },
    );
  }
}
