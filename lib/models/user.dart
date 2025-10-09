/// User model representing a StudyPals application user
/// Contains all user data including preferences, profile, and authentication status
///
/// TODO: CRITICAL USER MODEL IMPLEMENTATION GAPS
/// - Current model structure is basic and missing many essential user features
/// - Need to implement proper user roles and permissions system
/// - Missing integration with social features (friends, followers, groups)
/// - Need to implement user achievement and gamification data structure
/// - Missing proper subscription and billing information management
/// - Need to implement user study statistics and learning analytics
/// - Missing integration with device management and session tracking
/// - Need to implement proper user preference synchronization across devices
/// - Missing user activity feed and interaction history
/// - Need to implement proper user verification levels and trust scores
/// - Missing integration with educational institution verification system
/// - Need to implement user content creation and sharing permissions
/// - Missing proper user data export and portability features
/// - Need to implement user reporting and moderation history
/// - Missing integration with accessibility preferences and requirements
/// - Need to implement proper user onboarding progress tracking
/// - Missing integration with external service connections (Google, Spotify, etc.)
/// - Need to implement user study streak and habit tracking data
class User {
  // Core Identity Fields
  final String id; // Unique identifier for the user (Firebase UID)
  final String email; // User's email address for login and communication
  final String name; // Display name of the user
  final String? username; // Unique username (optional for display)

  // Profile Information
  final String? profilePictureUrl; // URL to user's profile picture
  final String? phoneNumber; // User's phone number (optional)
  final DateTime? dateOfBirth; // User's date of birth (optional)
  final String? bio; // User's biography/description (max 500 chars)
  final String? location; // User's location/city (optional)
  final String? school; // Educational institution (optional)
  final String? major; // Field of study/major (optional)
  final int? graduationYear; // Expected graduation year (optional)

  // Account Status & Security
  final bool isEmailVerified; // Email verification status for account security
  final bool isPhoneVerified; // Phone verification status (for 2FA)
  final bool isProfileComplete; // Whether user completed onboarding
  final bool isActive; // Account active status
  final DateTime createdAt; // Timestamp when the user account was created
  final DateTime? lastActiveAt; // Last activity timestamp
  final DateTime? lastLoginAt; // Last login timestamp

  // Privacy & Settings
  final UserPrivacySettings privacySettings; // Privacy preferences
  final UserPreferences preferences; // Study preferences and settings

  // Analytics & Engagement
  final int loginCount; // Total number of logins
  final Map<String, dynamic> metadata; // Additional flexible data storage

  /// Constructor for creating a User instance
  /// Core fields are required, profile and optional fields have defaults
  User({
    required this.id,
    required this.email,
    required this.name,
    this.username,
    this.profilePictureUrl,
    this.phoneNumber,
    this.dateOfBirth,
    this.bio,
    this.location,
    this.school,
    this.major,
    this.graduationYear,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isProfileComplete = false,
    this.isActive = true,
    DateTime? createdAt,
    this.lastActiveAt,
    this.lastLoginAt,
    UserPrivacySettings? privacySettings,
    UserPreferences? preferences,
    this.loginCount = 1,
    Map<String, dynamic>? metadata,
  })  : createdAt = createdAt ?? DateTime.now(),
        privacySettings = privacySettings ?? UserPrivacySettings(),
        preferences = preferences ?? UserPreferences(),
        metadata = metadata ?? <String, dynamic>{};

  /// Converts User object to JSON map for database storage
  Map<String, dynamic> toJson() => {
        // Core Identity
        'id': id,
        'email': email,
        'name': name,
        'username': username,

        // Profile Information
        'profilePictureUrl': profilePictureUrl,
        'phoneNumber': phoneNumber,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'bio': bio,
        'location': location,
        'school': school,
        'major': major,
        'graduationYear': graduationYear,

        // Account Status & Security
        'isEmailVerified': isEmailVerified,
        'isPhoneVerified': isPhoneVerified,
        'isProfileComplete': isProfileComplete,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),

        // Settings
        'privacySettings': privacySettings.toJson(),
        'preferences': preferences.toJson(),

        // Analytics
        'loginCount': loginCount,
        'metadata': metadata,
      };

  /// Creates User object from JSON map (from database or API)
  factory User.fromJson(Map<String, dynamic> json) => User(
        // Core Identity
        id: json['id'] as String,
        email: json['email'] as String,
        name: json['name'] as String,
        username: json['username'] as String?,

        // Profile Information
        profilePictureUrl: json['profilePictureUrl'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        dateOfBirth: json['dateOfBirth'] != null
            ? DateTime.parse(json['dateOfBirth'] as String)
            : null,
        bio: json['bio'] as String?,
        location: json['location'] as String?,
        school: json['school'] as String?,
        major: json['major'] as String?,
        graduationYear: json['graduationYear'] as int?,

        // Account Status & Security
        isEmailVerified: json['isEmailVerified'] as bool? ?? false,
        isPhoneVerified: json['isPhoneVerified'] as bool? ?? false,
        isProfileComplete: json['isProfileComplete'] as bool? ?? false,
        isActive: json['isActive'] as bool? ?? true,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastActiveAt: json['lastActiveAt'] != null
            ? DateTime.parse(json['lastActiveAt'] as String)
            : null,
        lastLoginAt: json['lastLoginAt'] != null
            ? DateTime.parse(json['lastLoginAt'] as String)
            : null,

        // Settings
        privacySettings: json['privacySettings'] != null
            ? UserPrivacySettings.fromJson(
                json['privacySettings'] as Map<String, dynamic>)
            : UserPrivacySettings(),
        preferences: json['preferences'] != null
            ? UserPreferences.fromJson(
                json['preferences'] as Map<String, dynamic>)
            : UserPreferences(),

        // Analytics
        loginCount: json['loginCount'] as int? ?? 1,
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );

  /// Helper method to copy user with updated fields
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? username,
    String? profilePictureUrl,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
    bool? isEmailVerified,
    bool? isPhoneVerified,
    bool? isProfileComplete,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    DateTime? lastLoginAt,
    UserPrivacySettings? privacySettings,
    UserPreferences? preferences,
    int? loginCount,
    Map<String, dynamic>? metadata,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      username: username ?? this.username,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      school: school ?? this.school,
      major: major ?? this.major,
      graduationYear: graduationYear ?? this.graduationYear,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      privacySettings: privacySettings ?? this.privacySettings,
      preferences: preferences ?? this.preferences,
      loginCount: loginCount ?? this.loginCount,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if profile is considered complete for onboarding
  bool get hasCompleteProfile {
    return isEmailVerified &&
        bio != null &&
        bio!.isNotEmpty &&
        (school != null || major != null);
  }

  /// Get user's age if date of birth is provided
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  /// Get user's display name with fallback
  String get displayName =>
      name.isNotEmpty ? name : username ?? email.split('@').first;
}

/// User privacy settings for controlling data sharing and visibility
class UserPrivacySettings {
  final bool profileVisible; // Whether profile is visible to others
  final bool emailVisible; // Whether email is visible to others
  final bool phoneVisible; // Whether phone is visible to others
  final bool locationVisible; // Whether location is visible to others
  final bool birthdateVisible; // Whether birthdate is visible to others
  final bool
      allowStudySessionInvites; // Allow others to invite to study sessions
  final bool allowDirectMessages; // Allow direct messages from other users
  final bool showOnlineStatus; // Show online/offline status
  final bool shareStudyStats; // Share study statistics publicly
  final bool allowAnalytics; // Allow usage analytics collection
  final bool marketingEmails; // Allow marketing emails
  final bool studyReminders; // Allow study reminder notifications
  final bool achievementNotifications; // Allow achievement notifications

  UserPrivacySettings({
    this.profileVisible = true,
    this.emailVisible = false,
    this.phoneVisible = false,
    this.locationVisible = false,
    this.birthdateVisible = false,
    this.allowStudySessionInvites = true,
    this.allowDirectMessages = true,
    this.showOnlineStatus = true,
    this.shareStudyStats = true,
    this.allowAnalytics = true,
    this.marketingEmails = false,
    this.studyReminders = true,
    this.achievementNotifications = true,
  });

  Map<String, dynamic> toJson() => {
        'profileVisible': profileVisible,
        'emailVisible': emailVisible,
        'phoneVisible': phoneVisible,
        'locationVisible': locationVisible,
        'birthdateVisible': birthdateVisible,
        'allowStudySessionInvites': allowStudySessionInvites,
        'allowDirectMessages': allowDirectMessages,
        'showOnlineStatus': showOnlineStatus,
        'shareStudyStats': shareStudyStats,
        'allowAnalytics': allowAnalytics,
        'marketingEmails': marketingEmails,
        'studyReminders': studyReminders,
        'achievementNotifications': achievementNotifications,
      };

  factory UserPrivacySettings.fromJson(Map<String, dynamic> json) =>
      UserPrivacySettings(
        profileVisible: json['profileVisible'] as bool? ?? true,
        emailVisible: json['emailVisible'] as bool? ?? false,
        phoneVisible: json['phoneVisible'] as bool? ?? false,
        locationVisible: json['locationVisible'] as bool? ?? false,
        birthdateVisible: json['birthdateVisible'] as bool? ?? false,
        allowStudySessionInvites:
            json['allowStudySessionInvites'] as bool? ?? true,
        allowDirectMessages: json['allowDirectMessages'] as bool? ?? true,
        showOnlineStatus: json['showOnlineStatus'] as bool? ?? true,
        shareStudyStats: json['shareStudyStats'] as bool? ?? true,
        allowAnalytics: json['allowAnalytics'] as bool? ?? true,
        marketingEmails: json['marketingEmails'] as bool? ?? false,
        studyReminders: json['studyReminders'] as bool? ?? true,
        achievementNotifications:
            json['achievementNotifications'] as bool? ?? true,
      );

  UserPrivacySettings copyWith({
    bool? profileVisible,
    bool? emailVisible,
    bool? phoneVisible,
    bool? locationVisible,
    bool? birthdateVisible,
    bool? allowStudySessionInvites,
    bool? allowDirectMessages,
    bool? showOnlineStatus,
    bool? shareStudyStats,
    bool? allowAnalytics,
    bool? marketingEmails,
    bool? studyReminders,
    bool? achievementNotifications,
  }) {
    return UserPrivacySettings(
      profileVisible: profileVisible ?? this.profileVisible,
      emailVisible: emailVisible ?? this.emailVisible,
      phoneVisible: phoneVisible ?? this.phoneVisible,
      locationVisible: locationVisible ?? this.locationVisible,
      birthdateVisible: birthdateVisible ?? this.birthdateVisible,
      allowStudySessionInvites:
          allowStudySessionInvites ?? this.allowStudySessionInvites,
      allowDirectMessages: allowDirectMessages ?? this.allowDirectMessages,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      shareStudyStats: shareStudyStats ?? this.shareStudyStats,
      allowAnalytics: allowAnalytics ?? this.allowAnalytics,
      marketingEmails: marketingEmails ?? this.marketingEmails,
      studyReminders: studyReminders ?? this.studyReminders,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
    );
  }
}

/// User preferences for customizing study experience and app behavior
/// Contains settings for study sessions, notifications, themes, and learning preferences
class UserPreferences {
  // Study Schedule Settings
  final int
      studyStartHour; // Hour when user typically starts studying (24-hour format)
  final int
      studyEndHour; // Hour when user typically stops studying (24-hour format)
  final int maxCardsPerDay; // Maximum number of flashcards to review per day
  final int maxMinutesPerDay; // Maximum study time in minutes per day
  final List<int>
      studyDaysOfWeek; // Days of week for study (1=Monday, 7=Sunday)
  final int breakInterval; // Minutes between study breaks
  final int breakDuration; // Duration of breaks in minutes

  // Learning Preferences
  final String learningStyle; // 'visual', 'auditory', 'kinesthetic', 'reading'
  final String
      difficultyPreference; // 'easy', 'moderate', 'challenging', 'adaptive'
  final bool showHints; // Whether to show hints for difficult questions
  final bool autoPlayAudio; // Auto-play audio for flashcards
  final int cardReviewDelay; // Delay between cards in milliseconds

  // Notification Settings
  final bool studyReminders; // Daily study reminder notifications
  final bool achievementNotifications; // Achievement unlock notifications
  final bool socialNotifications; // Social activity notifications
  final bool petCareReminders; // Automatic pet care event reminders
  final bool emailDigest; // Weekly email digest
  final String reminderTime; // Preferred reminder time (HH:MM format)

  // App Appearance
  final String theme; // 'light', 'dark', 'system', 'custom'
  final String primaryColor; // Hex color code for primary theme
  final String fontFamily; // Preferred font family
  final double fontSize; // Font size multiplier (0.8 - 2.0)
  final bool animations; // Enable UI animations
  final bool soundEffects; // Enable sound effects

  // Advanced Settings
  final String language; // App language code (e.g., 'en', 'es', 'fr')
  final String timezone; // User's timezone
  final bool offline; // Enable offline study mode
  final bool autoSync; // Auto-sync data when online
  final int dataRetentionDays; // Days to keep study history

  /// Constructor for UserPreferences with sensible defaults
  UserPreferences({
    // Study Schedule Defaults
    this.studyStartHour = 9,
    this.studyEndHour = 21,
    this.maxCardsPerDay = 50,
    this.maxMinutesPerDay = 120,
    this.studyDaysOfWeek = const [1, 2, 3, 4, 5], // Monday-Friday
    this.breakInterval = 25, // Pomodoro technique
    this.breakDuration = 5,

    // Learning Preferences Defaults
    this.learningStyle = 'adaptive',
    this.difficultyPreference = 'adaptive',
    this.showHints = true,
    this.autoPlayAudio = false,
    this.cardReviewDelay = 1000, // 1 second

    // Notification Defaults
    this.studyReminders = true,
    this.achievementNotifications = true,
    this.socialNotifications = true,
    this.petCareReminders = true, // Enable pet care reminders by default
    this.emailDigest = false,
    this.reminderTime = '09:00',

    // Appearance Defaults
    this.theme = 'Dark',
    this.primaryColor = '#6366F1', // Indigo
    this.fontFamily = 'system',
    this.fontSize = 1.0,
    this.animations = true,
    this.soundEffects = true,

    // Advanced Defaults
    this.language = 'en',
    this.timezone = 'UTC',
    this.offline = true,
    this.autoSync = true,
    this.dataRetentionDays = 365,
  });

  /// Converts UserPreferences to JSON map for storage
  Map<String, dynamic> toJson() => {
        // Study Schedule
        'studyStartHour': studyStartHour,
        'studyEndHour': studyEndHour,
        'maxCardsPerDay': maxCardsPerDay,
        'maxMinutesPerDay': maxMinutesPerDay,
        'studyDaysOfWeek': studyDaysOfWeek,
        'breakInterval': breakInterval,
        'breakDuration': breakDuration,

        // Learning Preferences
        'learningStyle': learningStyle,
        'difficultyPreference': difficultyPreference,
        'showHints': showHints,
        'autoPlayAudio': autoPlayAudio,
        'cardReviewDelay': cardReviewDelay,

        // Notifications
        'studyReminders': studyReminders,
        'achievementNotifications': achievementNotifications,
        'socialNotifications': socialNotifications,
        'petCareReminders': petCareReminders,
        'emailDigest': emailDigest,
        'reminderTime': reminderTime,

        // Appearance
        'theme': theme,
        'primaryColor': primaryColor,
        'fontFamily': fontFamily,
        'fontSize': fontSize,
        'animations': animations,
        'soundEffects': soundEffects,

        // Advanced
        'language': language,
        'timezone': timezone,
        'offline': offline,
        'autoSync': autoSync,
        'dataRetentionDays': dataRetentionDays,
      };

  /// Creates UserPreferences from JSON map
  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        // Study Schedule
        studyStartHour: json['studyStartHour'] as int? ?? 9,
        studyEndHour: json['studyEndHour'] as int? ?? 21,
        maxCardsPerDay: json['maxCardsPerDay'] as int? ?? 50,
        maxMinutesPerDay: json['maxMinutesPerDay'] as int? ?? 120,
        studyDaysOfWeek:
            (json['studyDaysOfWeek'] as List<dynamic>?)?.cast<int>() ??
                [1, 2, 3, 4, 5],
        breakInterval: json['breakInterval'] as int? ?? 25,
        breakDuration: json['breakDuration'] as int? ?? 5,

        // Learning Preferences
        learningStyle: json['learningStyle'] as String? ?? 'adaptive',
        difficultyPreference:
            json['difficultyPreference'] as String? ?? 'adaptive',
        showHints: json['showHints'] as bool? ?? true,
        autoPlayAudio: json['autoPlayAudio'] as bool? ?? false,
        cardReviewDelay: json['cardReviewDelay'] as int? ?? 1000,

        // Notifications
        studyReminders: json['studyReminders'] as bool? ?? true,
        achievementNotifications:
            json['achievementNotifications'] as bool? ?? true,
        socialNotifications: json['socialNotifications'] as bool? ?? true,
        petCareReminders: json['petCareReminders'] as bool? ?? true,
        emailDigest: json['emailDigest'] as bool? ?? false,
        reminderTime: json['reminderTime'] as String? ?? '09:00',

        // Appearance
        theme: json['theme'] as String? ?? 'Dark',
        primaryColor: json['primaryColor'] as String? ?? '#6366F1',
        fontFamily: json['fontFamily'] as String? ?? 'system',
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 1.0,
        animations: json['animations'] as bool? ?? true,
        soundEffects: json['soundEffects'] as bool? ?? true,

        // Advanced
        language: json['language'] as String? ?? 'en',
        timezone: json['timezone'] as String? ?? 'UTC',
        offline: json['offline'] as bool? ?? true,
        autoSync: json['autoSync'] as bool? ?? true,
        dataRetentionDays: json['dataRetentionDays'] as int? ?? 365,
      );

  /// Create a copy with updated fields
  UserPreferences copyWith({
    int? studyStartHour,
    int? studyEndHour,
    int? maxCardsPerDay,
    int? maxMinutesPerDay,
    List<int>? studyDaysOfWeek,
    int? breakInterval,
    int? breakDuration,
    String? learningStyle,
    String? difficultyPreference,
    bool? showHints,
    bool? autoPlayAudio,
    int? cardReviewDelay,
    bool? studyReminders,
    bool? achievementNotifications,
    bool? socialNotifications,
    bool? petCareReminders,
    bool? emailDigest,
    String? reminderTime,
    String? theme,
    String? primaryColor,
    String? fontFamily,
    double? fontSize,
    bool? animations,
    bool? soundEffects,
    String? language,
    String? timezone,
    bool? offline,
    bool? autoSync,
    int? dataRetentionDays,
  }) {
    return UserPreferences(
      studyStartHour: studyStartHour ?? this.studyStartHour,
      studyEndHour: studyEndHour ?? this.studyEndHour,
      maxCardsPerDay: maxCardsPerDay ?? this.maxCardsPerDay,
      maxMinutesPerDay: maxMinutesPerDay ?? this.maxMinutesPerDay,
      studyDaysOfWeek: studyDaysOfWeek ?? this.studyDaysOfWeek,
      breakInterval: breakInterval ?? this.breakInterval,
      breakDuration: breakDuration ?? this.breakDuration,
      learningStyle: learningStyle ?? this.learningStyle,
      difficultyPreference: difficultyPreference ?? this.difficultyPreference,
      showHints: showHints ?? this.showHints,
      autoPlayAudio: autoPlayAudio ?? this.autoPlayAudio,
      cardReviewDelay: cardReviewDelay ?? this.cardReviewDelay,
      studyReminders: studyReminders ?? this.studyReminders,
      achievementNotifications:
          achievementNotifications ?? this.achievementNotifications,
      socialNotifications: socialNotifications ?? this.socialNotifications,
      petCareReminders: petCareReminders ?? this.petCareReminders,
      emailDigest: emailDigest ?? this.emailDigest,
      reminderTime: reminderTime ?? this.reminderTime,
      theme: theme ?? this.theme,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      animations: animations ?? this.animations,
      soundEffects: soundEffects ?? this.soundEffects,
      language: language ?? this.language,
      timezone: timezone ?? this.timezone,
      offline: offline ?? this.offline,
      autoSync: autoSync ?? this.autoSync,
      dataRetentionDays: dataRetentionDays ?? this.dataRetentionDays,
    );
  }

  /// Get study days as human-readable names
  List<String> get studyDaysNames {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return studyDaysOfWeek.map((day) => days[day - 1]).toList();
  }

  /// Check if today is a study day
  bool get isStudyDay {
    final today = DateTime.now().weekday;
    return studyDaysOfWeek.contains(today);
  }

  /// Get next study day
  DateTime get nextStudyDay {
    final now = DateTime.now();
    final today = now.weekday;

    for (int i = 1; i <= 7; i++) {
      final nextDay = (today + i - 1) % 7 + 1;
      if (studyDaysOfWeek.contains(nextDay)) {
        return now.add(Duration(days: i));
      }
    }

    return now; // Fallback to today if no study days configured
  }
}
