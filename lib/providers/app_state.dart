import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/local_auth_service.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  final LocalAuthService _authService = LocalAuthService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null;
  bool get isAuthenticated => _currentUser != null;

  AppState() {
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    try {
      _setLoading(true);
      _currentUser = await _authService.getCurrentUser();
      notifyListeners();
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

      final user = await _authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );

      // Don't set current user - they need to verify email first
      notifyListeners();
      return user;
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

      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );

      _currentUser = user;
      notifyListeners();
      return user;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email: email);
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

      final updatedUser = await _authService.updateProfile(
        name: name,
        email: email,
      );

      if (updatedUser != null) {
        _currentUser = updatedUser;
        notifyListeners();
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
        await _authService.deleteAccount(_currentUser!.email);
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
    await _authService.clearAllData();
    _currentUser = null;
    notifyListeners();
  }

  // Add a method to clear all users and reset everything
  Future<void> resetAllUserData() async {
    await _authService.clearAllData();
    _currentUser = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }
}
