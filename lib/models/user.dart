/// User model representing a StudyPals application user
/// Contains all user data including preferences and authentication status
class User {
  // Unique identifier for the user (usually from authentication service)
  final String id;
  // User's email address for login and communication
  final String email;
  // Display name of the user
  final String name;
  // Email verification status for account security
  final bool isEmailVerified;
  // Timestamp when the user account was created
  final DateTime createdAt;
  // User's personalized study preferences and settings
  final UserPreferences preferences;

  /// Constructor for creating a User instance
  /// @param id - Required unique identifier
  /// @param email - Required email address
  /// @param name - Required display name
  /// @param isEmailVerified - Email verification status (defaults to false)
  /// @param createdAt - Optional creation time (defaults to now)
  /// @param preferences - Optional preferences (defaults to UserPreferences())
  User({
    required this.id,        // Must provide user ID
    required this.email,     // Must provide email
    required this.name,      // Must provide name
    this.isEmailVerified = false, // Default to unverified
    DateTime? createdAt,     // Optional, will default to current time
    UserPreferences? preferences, // Optional, will use defaults
  }) : createdAt = createdAt ?? DateTime.now(),           // Set to now if not provided
        preferences = preferences ?? UserPreferences();   // Use default preferences if not provided

  /// Converts User object to JSON map for database storage
  /// @return Map with string keys and dynamic values for JSON serialization
  Map<String, dynamic> toJson() => {
    'id': id,                                    // Store user ID as string
    'email': email,                              // Store email as string
    'name': name,                                // Store name as string
    'isEmailVerified': isEmailVerified,          // Store verification status as boolean
    'createdAt': createdAt.toIso8601String(),    // Convert DateTime to ISO string format
    'preferences': preferences.toJson(),         // Convert preferences object to JSON
  };

  /// Creates User object from JSON map (from database or API)
  /// @param json - Map containing user data
  /// @return New User instance populated with data from JSON
  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json['id'] as String,                    // Extract ID as string
    email: json['email'] as String,              // Extract email as string
    name: json['name'] as String,                // Extract name as string
    isEmailVerified: json['isEmailVerified'] as bool? ?? false, // Extract verification status
    createdAt: DateTime.parse(json['createdAt'] as String), // Parse ISO string to DateTime
    preferences: UserPreferences.fromJson(json['preferences'] as Map<String, dynamic>), // Parse preferences
  );
}

/// User preferences for customizing study experience
/// Contains settings for study sessions, daily limits, and scheduling
class UserPreferences {
  // Hour when user typically starts studying (24-hour format)
  final int studyStartHour;
  // Hour when user typically stops studying (24-hour format)
  final int studyEndHour;
  // Maximum number of flashcards to review per day
  final int maxCardsPerDay;
  // Maximum study time in minutes per day
  final int maxMinutesPerDay;

  /// Constructor for UserPreferences with sensible defaults
  /// @param studyStartHour - When to start studying (default: 9 AM)
  /// @param studyEndHour - When to stop studying (default: 9 PM)
  /// @param maxCardsPerDay - Daily card limit (default: 20)
  /// @param maxMinutesPerDay - Daily time limit in minutes (default: 180 = 3 hours)
  UserPreferences({
    this.studyStartHour = 9,      // Default start: 9 AM
    this.studyEndHour = 21,       // Default end: 9 PM
    this.maxCardsPerDay = 20,     // Default: 20 cards per day
    this.maxMinutesPerDay = 180,  // Default: 3 hours (180 minutes) per day
  });

  /// Converts UserPreferences to JSON map for storage
  /// @return Map with preference settings as key-value pairs
  Map<String, dynamic> toJson() => {
    'studyStartHour': studyStartHour,       // Store start hour as integer
    'studyEndHour': studyEndHour,           // Store end hour as integer
    'maxCardsPerDay': maxCardsPerDay,       // Store card limit as integer
    'maxMinutesPerDay': maxMinutesPerDay,   // Store time limit as integer
  };

  /// Creates UserPreferences from JSON map
  /// @param json - Map containing preference data
  /// @return New UserPreferences instance with settings from JSON
  factory UserPreferences.fromJson(Map<String, dynamic> json) => UserPreferences(
    studyStartHour: json['studyStartHour'] as int,     // Extract start hour
    studyEndHour: json['studyEndHour'] as int,         // Extract end hour
    maxCardsPerDay: json['maxCardsPerDay'] as int,     // Extract card limit
    maxMinutesPerDay: json['maxMinutesPerDay'] as int, // Extract time limit
  );
}
