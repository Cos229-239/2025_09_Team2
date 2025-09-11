/// Virtual pet model for gamification in StudyPals
/// The pet grows and changes mood based on user's study activity and progress
class Pet {
  // ID of the user who owns this pet
  final String userId;
  // Type/appearance of the pet (cat, dog, dragon, etc.)
  final PetSpecies species;
  // Current level of the pet (increases with XP)
  final int level;
  // Current experience points accumulated by studying
  final int xp;
  // List of unlocked gear/accessories for the pet
  final List<String> gear;
  // Current emotional state of the pet
  final PetMood mood;
  // When this pet was first created
  final DateTime createdAt;

  /// Constructor for creating a Pet instance
  /// @param userId - Required owner's user ID
  /// @param species - Required pet type/appearance
  /// @param level - Pet's level (defaults to 1)
  /// @param xp - Experience points (defaults to 0)
  /// @param gear - Unlocked accessories (defaults to empty list)
  /// @param mood - Current mood (defaults to happy)
  /// @param createdAt - Creation time (defaults to now)
  Pet({
    required this.userId, // Must specify pet owner
    required this.species, // Must choose pet type
    this.level = 1, // Start at level 1
    this.xp = 0, // Start with no experience
    this.gear = const [], // Start with no gear
    this.mood = PetMood.happy, // Start happy
    DateTime? createdAt, // Optional creation time
  }) : createdAt = createdAt ??
            DateTime.now(); // Default to current time if not provided

  /// Calculates XP required to reach the next level
  /// Each level requires level * 100 XP (level 1→2 needs 100, level 2→3 needs 200, etc.)
  /// @return Amount of XP needed for next level
  int get xpForNextLevel => level * 100;

  /// Calculates progress toward next level as a percentage (0.0 to 1.0)
  /// Used for progress bars in the UI
  /// @return Decimal representing progress (0.0 = no progress, 1.0 = ready to level up)
  double get xpProgress => xp / xpForNextLevel;

  /// Adds experience points to the pet and handles level-ups
  /// When enough XP is gained, the pet automatically levels up
  /// @param amount - XP to add (usually earned from completing tasks/studying)
  /// @return New Pet instance with updated XP, level, and mood
  Pet addXP(int amount) {
    int newXP = xp + amount; // Add the earned XP to current total
    int newLevel = level; // Start with current level

    // Check if pet should level up (possibly multiple times)
    while (newXP >= newLevel * 100) {
      // While we have enough XP for next level
      newXP -= newLevel * 100; // Subtract XP cost for leveling up
      newLevel++; // Increase level by 1
    }

    // Return new pet instance with updated stats
    return Pet(
      userId: userId, // Keep same owner
      species: species, // Keep same species
      level: newLevel, // Updated level
      xp: newXP, // Remaining XP after level-ups
      gear: gear, // Keep current gear
      mood: _calculateMood(
          newLevel, newXP), // Recalculate mood based on new stats
      createdAt: createdAt, // Keep original creation time
    );
  }

  /// Calculates pet's mood based on current progress toward next level
  /// Pets are happier when they're closer to leveling up
  /// @param level - Current level of the pet
  /// @param xp - Current XP within the level
  /// @return PetMood enum representing emotional state
  PetMood _calculateMood(int level, int xp) {
    // Calculate what percentage of level progress we have
    if (xp > level * 80) return PetMood.excited; // 80%+ progress = excited
    if (xp > level * 50) return PetMood.happy; // 50-80% progress = happy
    if (xp > level * 20) return PetMood.content; // 20-50% progress = content
    return PetMood.sleepy; // 0-20% progress = sleepy
  }

  /// Converts Pet object to JSON map for database storage
  /// @return Map containing all pet data in JSON-serializable format
  Map<String, dynamic> toJson() => {
        'userId': userId, // Store owner ID as string
        'species': species.toString(), // Convert enum to string representation
        'level': level, // Store level as integer
        'xp': xp, // Store XP as integer
        'gear': gear, // Store gear list as-is
        'mood': mood.toString(), // Convert enum to string representation
        'createdAt':
            createdAt.toIso8601String(), // Convert DateTime to ISO string
      };

  /// Creates Pet object from JSON map (from database or API)
  /// @param json - Map containing pet data
  /// @return New Pet instance populated with data from JSON
  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
        userId: json['userId'] as String, // Extract owner ID
        species: PetSpecies.values.firstWhere(
          // Find matching species enum
          (e) =>
              e.toString() == json['species'], // Compare string representations
          orElse: () => PetSpecies.cat, // Default to cat if no match
        ),
        level: json['level'] as int, // Extract level as integer
        xp: json['xp'] as int, // Extract XP as integer
        gear: List<String>.from(
            (json['gear'] as List?) ?? []), // Convert gear to List<String>
        mood: PetMood.values.firstWhere(
          // Find matching mood enum
          (e) => e.toString() == json['mood'], // Compare string representations
          orElse: () => PetMood.happy, // Default to happy if no match
        ),
        createdAt: DateTime.parse(
            json['createdAt'] as String), // Parse ISO string to DateTime
      );
}

/// Available pet species/types that users can choose from
/// Each species has different visual appearance in the UI
enum PetSpecies {
  cat, // Domestic cat pet
  dog, // Domestic dog pet
  dragon, // Mythical dragon pet
  owl, // Wise owl pet
  fox // Clever fox pet
}

/// Pet mood states that affect visual appearance and animations
/// Mood changes based on study progress and pet care
enum PetMood {
  sleepy, // Low energy, needs more study activity
  content, // Satisfied, moderate progress
  happy, // Good progress, pet is pleased
  excited // Excellent progress, pet is thrilled
}
