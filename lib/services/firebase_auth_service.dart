import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firebase Authentication operations
/// Provides methods for user registration, login, email verification, and logout
class FirebaseAuthService extends ChangeNotifier {
  static final FirebaseAuthService _instance = FirebaseAuthService._internal();
  factory FirebaseAuthService() => _instance;
  FirebaseAuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Current user state
  User? get currentUser => _auth.currentUser;
  bool get isUserLoggedIn => _auth.currentUser != null;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;
  
  // Stream to listen to auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign up with email and password
  /// Automatically sends email verification
  Future<AuthResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create user account
      final UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);
        
        // Send email verification
        await sendEmailVerification();
        
        notifyListeners();
        return AuthResult(
          success: true,
          user: user,
          message: 'Account created successfully! Please check your email for verification.',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Failed to create account. Please try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Sign in with email and password
  /// Checks if email is verified before allowing login
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = credential.user;
      if (user != null) {
        // Check if email is verified
        await user.reload(); // Refresh user data
        final updatedUser = _auth.currentUser;
        
        if (updatedUser?.emailVerified == false) {
          // User exists but email not verified
          await signOut(); // Sign out immediately
          return AuthResult(
            success: false,
            message: 'Please verify your email before logging in. Check your inbox for the verification link.',
            needsEmailVerification: true,
          );
        }
        
        notifyListeners();
        return AuthResult(
          success: true,
          user: updatedUser,
          message: 'Successfully signed in!',
        );
      } else {
        return AuthResult(
          success: false,
          message: 'Login failed. Please try again.',
        );
      }
    } on FirebaseAuthException catch (e) {
      return AuthResult(
        success: false,
        message: _getAuthErrorMessage(e.code),
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }

  /// Send email verification to current user
  Future<bool> sendEmailVerification() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending email verification: $e');
      }
      return false;
    }
  }

  /// Check if current user's email is verified
  /// Refreshes user data from server
  Future<bool> checkEmailVerified() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = _auth.currentUser;
        notifyListeners();
        return refreshedUser?.emailVerified ?? false;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking email verification: $e');
      }
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending password reset email: $e');
      }
      return false;
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error signing out: $e');
      }
    }
  }

  /// Delete current user account
  Future<bool> deleteAccount() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        await user.delete();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting account: $e');
      }
      return false;
    }
  }

  /// Convert Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method.';
      default:
        return 'Authentication failed: $errorCode';
    }
  }
}

/// Result class for authentication operations
class AuthResult {
  final bool success;
  final User? user;
  final String message;
  final bool needsEmailVerification;

  AuthResult({
    required this.success,
    this.user,
    required this.message,
    this.needsEmailVerification = false,
  });
}