import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Optimized login service with performance improvements
class OptimizedLoginService {
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();

  /// Sign in user with optimized performance
  Future<LoginResult> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Authenticate with Firebase (critical path)
      final authResult = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!authResult.success || authResult.user == null) {
        return LoginResult.failure(authResult.message);
      }

      final user = authResult.user!;

      // Step 2: Refresh user data and check email verification (critical for security)
      try {
        await user.reload(); // Refresh user data from Firebase
        final refreshedUser = _authService.currentUser;
        
        if (refreshedUser == null || !refreshedUser.emailVerified) {
          return LoginResult.unverified(
            'Please verify your email before logging in. If you just verified it, please try logging in again.',
            refreshedUser ?? user,
          );
        }
        
        if (kDebugMode) {
          print('User email verification status: ${refreshedUser.emailVerified}');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error refreshing user data: $e');
        }
        // Fall back to original user object
        if (!user.emailVerified) {
          return LoginResult.unverified(
            'Please verify your email before logging in.',
            user,
          );
        }
      }

      // Step 3: Schedule background tasks (non-blocking)
      _scheduleBackgroundTasks(user);

      return LoginResult.success(
        message: 'Welcome back, ${user.displayName ?? 'User'}!',
        user: user,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Login error: $e');
      }
      return LoginResult.failure('Login failed: ${e.toString()}');
    }
  }

  /// Schedule background tasks that don't block user login
  void _scheduleBackgroundTasks(User user) {
    // Use Future.microtask to schedule work after current event loop
    Future.microtask(() async {
      try {
        // Update last active timestamp (non-critical)
        await _updateLastActiveOptimized(user.uid);

        // Log login analytics (non-critical)
        await _logLoginAnalytics(user.uid);

        // Update login count (non-critical)
        await _updateLoginCount(user.uid);
      } catch (e) {
        if (kDebugMode) {
          print('Background login task error: $e');
        }
        // Don't throw - these are non-critical operations
      }
    });
  }

  /// Optimized last active update with minimal data
  Future<void> _updateLastActiveOptimized(String uid) async {
    try {
      // Only update essential timestamp, don't read current data
      await _firestoreService.usersCollection.doc(uid).update({
        'lastActiveAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last active: $e');
      }
    }
  }

  /// Log login analytics in background
  Future<void> _logLoginAnalytics(String uid) async {
    try {
      await _firestoreService.analyticsCollection.add({
        'uid': uid,
        'eventName': 'user_login',
        'eventData': {
          'loginMethod': 'email',
          'timestamp': FieldValue.serverTimestamp(),
        },
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Login analytics error: $e');
      }
    }
  }

  /// Update login count in background
  Future<void> _updateLoginCount(String uid) async {
    try {
      await _firestoreService.usersCollection.doc(uid).update({
        'loginCount': FieldValue.increment(1),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error updating login count: $e');
      }
    }
  }

  /// Check if the current user's email is verified
  /// Useful after email verification to confirm status before login
  Future<bool> checkEmailVerificationStatus() async {
    return await _authService.checkEmailVerified();
  }
}

/// Login result wrapper
class LoginResult {
  final bool success;
  final String message;
  final User? user;
  final bool requiresEmailVerification;

  LoginResult._({
    required this.success,
    required this.message,
    this.user,
    this.requiresEmailVerification = false,
  });

  factory LoginResult.success({
    required String message,
    required User user,
  }) {
    return LoginResult._(
      success: true,
      message: message,
      user: user,
    );
  }

  factory LoginResult.failure(String message) {
    return LoginResult._(
      success: false,
      message: message,
    );
  }

  factory LoginResult.unverified(String message, User user) {
    return LoginResult._(
      success: false,
      message: message,
      user: user,
      requiresEmailVerification: true,
    );
  }
}