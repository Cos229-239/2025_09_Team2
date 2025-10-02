import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/registration_validator.dart';
import 'firestore_service.dart';
import 'firebase_auth_service.dart';

/// Optimized registration service with performance improvements
///
/// TODO: OPTIMIZED REGISTRATION SERVICE IMPLEMENTATION GAPS
/// - Current implementation has good performance optimization but missing key features
/// - Debug mode email verification bypass is security risk for production
/// - Need to implement proper production-ready email verification workflow
/// - Missing integration with user onboarding and tutorial system
/// - Need to implement proper error analytics and registration funnel tracking
/// - Missing batch operations for user profile initialization
/// - Need to implement proper rollback mechanisms for failed registrations
/// - Missing integration with user preference initialization
/// - Need to implement proper duplicate account detection and merging
/// - Missing integration with referral and invitation system
/// - Need to implement proper user segmentation and cohort tracking
/// - Missing integration with push notification setup during registration
/// - Need to implement proper GDPR compliance and data retention setup
/// - Missing integration with user analytics and behavior tracking initialization
class OptimizedRegistrationService {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  // Development flag to allow immediate dashboard access without email verification
  static const bool _allowImmediateAccess = kDebugMode; // Only in debug mode

  /// Register user with optimized performance
  Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
  }) async {
    try {
      // Step 1: Fast validation checks first (client-side only)
      final emailError = RegistrationValidator.validateEmail(email);
      if (emailError != null) {
        return RegistrationResult.failure('Invalid email: $emailError');
      }

      final passwordError = RegistrationValidator.validatePassword(password);
      if (passwordError != null) {
        return RegistrationResult.failure('Invalid password: $passwordError');
      }

      final nameError = RegistrationValidator.validateFullName(fullName);
      if (nameError != null) {
        return RegistrationResult.failure('Invalid name: $nameError');
      }

      // Step 2: Create Firebase user (critical path)
      final authResult = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: fullName.trim(),
      );

      if (!authResult.success || authResult.user == null) {
        return RegistrationResult.failure(authResult.message);
      }

      final firebaseUser = authResult.user!;

      // Step 3: Update display name (lightweight operation)
      await firebaseUser.updateDisplayName(fullName.trim());

      // Step 3.5: In debug mode, automatically verify email for immediate access
      if (_allowImmediateAccess) {
        try {
          // Send verification email
          await _authService.sendEmailVerification();

          // In debug mode, we'll mark the user as email verified in Firestore
          // This allows immediate dashboard access while still maintaining the verification flow
          await _markEmailAsVerifiedForDebug(firebaseUser.uid);

          if (kDebugMode) {
            print(
                'Debug mode: Email verification sent and marked as verified for immediate access');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Debug mode: Failed to send/verify email: $e');
          }
        }
      }

      // Step 4: Create minimal user profile first (essential data only)
      final minimalProfileSuccess = await _createMinimalUserProfile(
        uid: firebaseUser.uid,
        email: email,
        displayName: fullName.trim(),
        username: username?.trim().toLowerCase(),
      );

      if (!minimalProfileSuccess) {
        // Rollback: delete Firebase user if Firestore creation fails
        await firebaseUser.delete();
        return RegistrationResult.failure(
          'Failed to create user profile. Please try again.',
        );
      }

      // Step 5: Schedule background tasks (non-blocking)
      _scheduleBackgroundTasks(
        uid: firebaseUser.uid,
        email: email,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        bio: bio,
        location: location,
        school: school,
        major: major,
        graduationYear: graduationYear,
      );

      return RegistrationResult.success(
        message: _allowImmediateAccess
            ? 'Registration successful! Welcome to StudyPals! (Debug: Email verification not required)'
            : 'Registration successful! Welcome to StudyPals!',
        user: firebaseUser,
        requiresEmailVerification: !_allowImmediateAccess,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Registration error: $e');
      }
      return RegistrationResult.failure(
        'Registration failed: ${e.toString()}',
      );
    }
  }

  /// Create minimal user profile for fast registration
  Future<bool> _createMinimalUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String? username,
  }) async {
    try {
      // Only essential data for immediate use
      final minimalData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'username': username,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'emailVerified': false,
        'isActive': true,
        'isProfileComplete': false,
        // Basic preferences for immediate app functionality
        'preferences': {
          'theme': 'Dark',
          'notifications': true,
          'language': 'en',
        },
        'privacySettings': {
          'profileVisible': true,
          'allowStudySessionInvites': true,
        },
      };

      await _firestoreService.usersCollection.doc(uid).set(minimalData);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating minimal user profile: $e');
      }
      return false;
    }
  }

  /// Schedule background tasks that don't block user registration
  void _scheduleBackgroundTasks({
    required String uid,
    required String email,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
  }) {
    // Use Future.microtask to schedule work after current event loop
    Future.microtask(() async {
      try {
        // Update user profile with complete data
        await _updateCompleteUserProfile(
          uid: uid,
          email: email,
          fullName: fullName,
          username: username,
          phoneNumber: phoneNumber,
          dateOfBirth: dateOfBirth,
          bio: bio,
          location: location,
          school: school,
          major: major,
          graduationYear: graduationYear,
        );

        // Log analytics event (non-critical)
        await _logRegistrationAnalytics(uid, email);

        // Send welcome email (non-critical)
        await _sendWelcomeEmail(email, fullName);
      } catch (e) {
        if (kDebugMode) {
          print('Background task error: $e');
        }
        // Don't throw - these are non-critical operations
      }
    });
  }

  /// Update user profile with complete data in background
  Future<void> _updateCompleteUserProfile({
    required String uid,
    required String email,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
  }) async {
    final completeData = {
      'phoneNumber': phoneNumber?.trim(),
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bio': bio?.trim(),
      'location': location?.trim(),
      'school': school?.trim(),
      'major': major?.trim(),
      'graduationYear': graduationYear,
      'isPhoneVerified': false,
      'profilePicture': null,
      'loginCount': 0,
      'lastLoginAt': null,
      // Complete study stats
      'studyStats': {
        'totalStudyTime': 0,
        'cardsStudied': 0,
        'tasksCompleted': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'achievementsUnlocked': 0,
      },
      // Complete preferences
      'preferences': {
        'theme': 'Dark',
        'notifications': true,
        'studyReminders': true,
        'dailyGoal': 120,
        'preferredStudyTime': 'morning',
        'studyStartHour': 9,
        'studyEndHour': 21,
        'maxCardsPerDay': 50,
        'maxMinutesPerDay': 120,
        'breakInterval': 25,
        'breakDuration': 5,
        'learningStyle': 'adaptive',
        'language': 'en',
        'fontSize': 1.0,
        'animations': true,
        'soundEffects': true,
      },
      // Complete privacy settings
      'privacySettings': {
        'profileVisible': true,
        'emailVisible': false,
        'phoneVisible': false,
        'locationVisible': false,
        'birthdateVisible': false,
        'allowStudySessionInvites': true,
        'allowDirectMessages': true,
        'showOnlineStatus': true,
        'shareStudyStats': true,
        'allowAnalytics': true,
        'marketingEmails': false,
        'studyReminders': true,
        'achievementNotifications': true,
      },
      // Initialize collections
      'achievements': [],
      'dailyQuests': [],
      'pet': {
        'species': 'cat',
        'level': 1,
        'xp': 0,
        'mood': 'happy',
        'gear': [],
      },
      'isProfileComplete': true,
      'lastActiveAt': FieldValue.serverTimestamp(),
    };

    await _firestoreService.usersCollection.doc(uid).update(completeData);
  }

  /// Log registration analytics in background
  Future<void> _logRegistrationAnalytics(String uid, String email) async {
    try {
      await _firestoreService.analyticsCollection.add({
        'uid': uid,
        'eventName': 'user_registered',
        'eventData': {
          'registrationMethod': 'email',
          'email': email,
          'timestamp': FieldValue.serverTimestamp(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': _generateSessionId(),
        'platform': 'flutter',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Analytics logging error: $e');
      }
    }
  }

  /// Send welcome email in background (placeholder)
  Future<void> _sendWelcomeEmail(String email, String name) async {
    // TODO: Implement welcome email service
    if (kDebugMode) {
      print('Welcome email would be sent to: $email for $name');
    }
  }

  /// Generate session ID for analytics
  String _generateSessionId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  /// Debug-only method to mark email as verified for immediate access
  Future<void> _markEmailAsVerifiedForDebug(String uid) async {
    if (!_allowImmediateAccess) return;

    try {
      // Mark as verified in Firestore
      await _firestoreService.usersCollection.doc(uid).update({
        'emailVerified': true,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });

      // Note: We cannot programmatically verify email in Firebase Auth
      // This is a security limitation. In debug mode, we simulate the verification
      // by updating Firestore, but actual Firebase Auth verification must be done
      // through the email link or manually by the developer in Firebase Console

      if (kDebugMode) {
        print('Debug: Marked email as verified in Firestore for user $uid');
        print(
            'Note: Firebase Auth email verification still requires actual email verification');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Debug: Failed to mark email as verified: $e');
      }
    }
  }
}

/// Registration result wrapper
class RegistrationResult {
  final bool success;
  final String message;
  final User? user;
  final bool requiresEmailVerification;

  RegistrationResult._({
    required this.success,
    required this.message,
    this.user,
    this.requiresEmailVerification = false,
  });

  factory RegistrationResult.success({
    required String message,
    User? user,
    bool requiresEmailVerification = false,
  }) {
    return RegistrationResult._(
      success: true,
      message: message,
      user: user,
      requiresEmailVerification: requiresEmailVerification,
    );
  }

  factory RegistrationResult.failure(String message) {
    return RegistrationResult._(
      success: false,
      message: message,
      requiresEmailVerification: false,
    );
  }
}
