import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/ai_service.dart';
import 'ai_provider.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final FirebaseAuthService _authService = FirebaseAuthService();
  final FirestoreService _firestoreService = FirestoreService();
  StudyPalsAIProvider? _aiProvider;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAuthenticated => _currentUser != null;

  AppState() {
    _initializeApp();
  }

  // Method to set AI provider reference
  void setAIProvider(StudyPalsAIProvider aiProvider) {
    _aiProvider = aiProvider;
  }

  Future<void> _initializeApp() async {
    // Listen to Firebase auth state changes
    firebase_auth.FirebaseAuth.instance
        .authStateChanges()
        .listen((firebase_auth.User? firebaseUser) {
      _handleAuthStateChange(firebaseUser);
    });

    await _checkAuthState();
  }

  Future<void> _handleAuthStateChange(firebase_auth.User? firebaseUser) async {
    if (firebaseUser != null && firebaseUser.emailVerified) {
      // User is signed in and email is verified
      try {
        final userProfile =
            await _firestoreService.getUserProfile(firebaseUser.uid);
        if (userProfile != null) {
          _currentUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: userProfile['displayName'] ??
                firebaseUser.displayName ??
                'User',
          );
        } else {
          // Create user profile if it doesn't exist
          await _firestoreService.createUserProfile(
            uid: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            displayName: firebaseUser.displayName ?? 'User',
          );
          _currentUser = User(
            id: firebaseUser.uid,
            email: firebaseUser.email ?? '',
            name: firebaseUser.displayName ?? 'User',
          );
        }

        // Auto-configure AI upon successful login
        await _configureAIOnLogin();

        // Update last active timestamp
        await _firestoreService.updateLastActive();
      } catch (e) {
        debugPrint('Error handling auth state change: $e');
        _setError('Failed to load user profile: ${e.toString()}');
      }
    } else {
      // User is signed out or email not verified
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> _checkAuthState() async {
    try {
      _setLoading(true);
      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      await _handleAuthStateChange(firebaseUser);
    } catch (e) {
      _setError('Failed to check authentication state: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        displayName: name,
      );

      if (result.success && result.user != null) {
        // Create user profile in Firestore
        await _firestoreService.createUserProfile(
          uid: result.user!.uid,
          email: email,
          displayName: name,
        );

        // Don't set current user - they need to verify email first
        notifyListeners();
        return User(
          id: result.user!.uid,
          email: email,
          name: name,
        );
      } else {
        _setError(result.message);
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<User?> signInUser({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final result = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (result.success && result.user != null) {
        if (!result.user!.emailVerified) {
          _setError('Please verify your email before signing in.');
          return null;
        }

        // Immediately set the current user to trigger navigation to dashboard
        final userObject = User(
          id: result.user!.uid,
          email: result.user!.email ?? email,
          name: result.user!.displayName ?? 'User',
        );
        
        _currentUser = userObject;
        notifyListeners(); // Notify AuthWrapper to rebuild and show dashboard
        
        // Auto-configure AI and update last active in background
        Future.microtask(() async {
          try {
            await _configureAIOnLogin();
            await _firestoreService.updateLastActive();
          } catch (e) {
            debugPrint('Background login tasks error: $e');
          }
        });
        
        return userObject;
      } else {
        _setError(result.message);
        return null;
      }
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Automatically configure Google AI upon login
  Future<void> _configureAIOnLogin() async {
    if (_aiProvider != null) {
      try {
        await _aiProvider!.configureAI(
          provider: AIProvider.google,
          apiKey: 'AIzaSyCqWTq-SFuam7FTMe2OVcAiriqleRrf30Q',
          //apiKey: 'AIzaSyAasLmobMCyBiDAm3x9PqT11WX5ck3OhMA',
        );
        debugPrint('Google AI automatically configured upon login');
      } catch (e) {
        debugPrint('Failed to auto-configure AI: $e');
      }
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.sendPasswordResetEmail(email);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authService.signOut();
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await signOut();
  }

  void login(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> updateUserProfile({
    required String name,
    String? email,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Update display name in Firebase Auth
        await firebaseUser.updateDisplayName(name);

        // Update profile in Firestore
        await _firestoreService.updateUserProfile(
          firebaseUser.uid,
          {
            'displayName': name,
            'lastActiveAt': FieldValue.serverTimestamp(),
          },
        );

        // Update local user object
        if (_currentUser != null) {
          _currentUser = User(
            id: _currentUser!.id,
            email: _currentUser!.email,
            name: name,
          );
          notifyListeners();
        }
      }
    } catch (e) {
      _setError('Profile update failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteAccount() async {
    try {
      _setLoading(true);
      if (_currentUser != null) {
        // Delete user data from Firestore
        await _firestoreService.deleteUserData(_currentUser!.id);

        // Delete Firebase Auth account
        await _authService.deleteAccount();

        _currentUser = null;
        notifyListeners();
      }
    } catch (e) {
      _setError('Account deletion failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshUser() async {
    await _checkAuthState();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Debug method to clear all stored data
  Future<void> clearAllData() async {
    try {
      await signOut();
    } catch (e) {
      debugPrint('Error clearing data: $e');
    }
  }

  // Add a method to clear all users and reset everything
  Future<void> resetAllUserData() async {
    await clearAllData();
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
