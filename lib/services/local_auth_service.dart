import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

class LocalAuthService {
  static const String _usersKey = 'registered_users';
  static const String _currentUserKey = 'current_user';
  static const String _isLoggedInKey = 'is_logged_in';

  // Development mode: Auto-create test account if none exists
  static const bool _devMode = true; // Set to false for production
  static const String _devEmail = 'test@studypals.com';
  static const String _devPassword = 'password123';
  static const String _devName = 'Test User';
  
  // Demo account for the new UI
  static const String _demoEmail = 'demo@studypals.com';
  static const String _demoPassword = 'password';
  static const String _demoName = 'Demo User';

  // Debug logging helper
  void _debugLog(String message) {
    if (kDebugMode) {
      debugPrint('LocalAuth: $message');
    }
  }

  // Initialize development account if needed
  Future<void> _initDevAccount() async {
    if (!_devMode || !kDebugMode) return;
    
    final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    // Create test account
    if (!users.containsKey(_devEmail)) {
      _debugLog('DEV MODE: Creating test account...');
      final devUser = User(
        id: 'dev_user_001',
        name: _devName,
        email: _devEmail,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
      
      await _saveUser(devUser, _devPassword);
      _debugLog('DEV MODE: Test account created - Email: $_devEmail, Password: $_devPassword');
    }
    
    // Create demo account
    if (!users.containsKey(_demoEmail)) {
      _debugLog('DEV MODE: Creating demo account...');
      final demoUser = User(
        id: 'demo_user_001',
        name: _demoName,
        email: _demoEmail,
        isEmailVerified: true,
        createdAt: DateTime.now(),
      );
      
      await _saveUser(demoUser, _demoPassword);
      _debugLog('DEV MODE: Demo account created - Email: $_demoEmail, Password: $_demoPassword');
    }
  }

  // Web-safe storage methods using SharedPreferences
  Future<void> _setWebSafeString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
    _debugLog('Saved to SharedPreferences: $key');
  }

  Future<String?> _getWebSafeString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(key);
    _debugLog('Read from SharedPreferences: $key = ${value != null ? "found" : "null"}');
    return value;
  }

  Future<void> _setWebSafeBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _debugLog('Saved bool to SharedPreferences: $key = $value');
  }

  Future<bool> _getWebSafeBool(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(key) ?? false;
    _debugLog('Read bool from SharedPreferences: $key = $value');
    return value;
  }

  Future<void> _removeWebSafeKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
    _debugLog('Removed from SharedPreferences: $key');
  }

  // Hash password for storage
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Save user to local storage
  Future<void> _saveUser(User user, String password) async {
    final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    users[user.email] = {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'password': _hashPassword(password),
      'isEmailVerified': user.isEmailVerified,
      'createdAt': user.createdAt.toIso8601String(),
    };
    
    await _setWebSafeString(_usersKey, json.encode(users));
  }

  // Get user from local storage
  Future<User?> _getUser(String email) async {
    final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (users.containsKey(email)) {
      final userData = users[email];
      return User(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        isEmailVerified: userData['isEmailVerified'] ?? false, // Default to false for safety
        createdAt: DateTime.parse(userData['createdAt']),
      );
    }
    return null;
  }

  // Register new user
  Future<User?> registerWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      _debugLog('Attempting to register user: $email');
      
      // Check if user already exists
      final existingUser = await _getUser(email);
      if (existingUser != null) {
        _debugLog('User already exists: $email');
        throw Exception('An account with this email already exists');
      }

      // Create new user (immediately verified for local development)
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        isEmailVerified: true, // Immediately verified for local development
        createdAt: DateTime.now(),
      );

      _debugLog('Created user object: ${user.email}, verified: ${user.isEmailVerified}');

      // Save user
      await _saveUser(user, password);
      
      // Debug: Verify the user was saved
      _debugLog('User saved, verifying...');
      await debugStorageState();
      final savedUsers = await getAllStoredUsers();
      _debugLog('User verified in storage: ${savedUsers.containsKey(email)}');
      
      // Send verification email (simulated) - but user is already verified
      _debugLog('Local development: Email verification skipped - user immediately verified');
      
      // DO NOT auto-login - but user is verified and can log in immediately
      
      _debugLog('Registration completed for: $email');
      return user;
    } catch (e) {
      _debugLog('Registration error: $e');
      throw Exception('Registration failed: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _debugLog('Attempting to sign in user: $email');
      
      // Initialize dev account if in debug mode
      await _initDevAccount();
      
      // Debug: Check what's in storage
      await debugStorageState();
      
      final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
      final users = Map<String, dynamic>.from(json.decode(usersJson));
      
      _debugLog('Found users: ${users.keys.toList()}');
      _debugLog('Total users count: ${users.length}');
      
      if (!users.containsKey(email)) {
        _debugLog('No account found for: $email');
        _debugLog('Available accounts: ${users.keys.join(", ")}');
        if (_devMode && kDebugMode) {
          _debugLog('DEV MODE: Try using Email: $_devEmail, Password: $_devPassword');
        }
        throw Exception('No account found with this email');
      }
      
      final userData = users[email];
      final hashedPassword = _hashPassword(password);
      
      _debugLog('Stored password hash: ${userData['password']}');
      _debugLog('Computed password hash: $hashedPassword');
      _debugLog('Hashes match: ${userData['password'] == hashedPassword}');
      
      if (userData['password'] != hashedPassword) {
        _debugLog('Invalid password for: $email');
        throw Exception('Invalid password');
      }
      
      final user = User(
        id: userData['id'],
        name: userData['name'],
        email: userData['email'],
        isEmailVerified: userData['isEmailVerified'] ?? true, // Default to verified for local development
        createdAt: DateTime.parse(userData['createdAt']),
      );
      
      _debugLog('User found: ${user.email}, verified: ${user.isEmailVerified}');
      
      // For local development, skip email verification check
      // In production with real email, uncomment the lines below:
      // if (!user.isEmailVerified) {
      //   _debugLog('Email not verified for: $email');
      //   throw Exception('Please verify your email address before logging in. Check your email for verification instructions.');
      // }
      
      _debugLog('Sign in successful for: $email');
      await _setCurrentUser(user);
      return user;
    } catch (e) {
      _debugLog('Sign in error: $e');
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  // Reset password (simulated)
  Future<void> resetPassword({required String email}) async {
    final user = await _getUser(email);
    if (user == null) {
      throw Exception('No account found with this email');
    }
    
    // In a real app, this would send an email
    // For demo purposes, we'll just show a success message
    _debugLog('Password reset email sent to $email (simulated)');
  }

  // Send verification email (simulated)
  Future<void> _sendVerificationEmail(String email) async {
    // In a real app, this would send an actual email
    // For demo purposes, we'll immediately verify the email
    _debugLog('Verification email sent to $email (simulated)');
    
    // For local development, immediately verify the email
    await verifyEmail(email);
    _debugLog('Email immediately verified for local development: $email');
  }

  // Verify email address
  Future<void> verifyEmail(String email) async {
    final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    if (users.containsKey(email)) {
      users[email]['isEmailVerified'] = true;
      await _setWebSafeString(_usersKey, json.encode(users));
      _debugLog('Email verified for $email');
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail(String email) async {
    final user = await _getUser(email);
    if (user == null) {
      throw Exception('No account found with this email');
    }
    
    if (user.isEmailVerified) {
      throw Exception('Email is already verified');
    }
    
    await _sendVerificationEmail(email);
  }

  // Set current user
  Future<void> _setCurrentUser(User user) async {
    await _setWebSafeString(_currentUserKey, json.encode(user.toJson()));
    await _setWebSafeBool(_isLoggedInKey, true);
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      final isLoggedIn = await _getWebSafeBool(_isLoggedInKey);
      
      if (!isLoggedIn) return null;
      
      final userJson = await _getWebSafeString(_currentUserKey);
      if (userJson == null) return null;
      
      final userData = json.decode(userJson);
      return User.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _removeWebSafeKey(_currentUserKey);
    await _setWebSafeBool(_isLoggedInKey, false);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _getWebSafeBool(_isLoggedInKey);
  }

  // Delete account
  Future<void> deleteAccount(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    
    users.remove(email);
    await prefs.setString(_usersKey, json.encode(users));
    await signOut();
  }

  // Update user profile
  Future<User?> updateProfile({
    required String name,
    String? email,
  }) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) return null;
    
    final updatedUser = User(
      id: currentUser.id,
      name: name,
      email: email ?? currentUser.email,
      isEmailVerified: currentUser.isEmailVerified,
      createdAt: currentUser.createdAt,
    );
    
    await _setCurrentUser(updatedUser);
    return updatedUser;
  }

  // Clear all stored data (for testing purposes)
  Future<void> clearAllData() async {
    await _removeWebSafeKey(_usersKey);
    await _removeWebSafeKey(_currentUserKey);
    await _removeWebSafeKey(_isLoggedInKey);
    _debugLog('All auth data cleared');
  }

  // Debug method: Get all stored users (for troubleshooting)
  Future<Map<String, dynamic>> getAllStoredUsers() async {
    final usersJson = await _getWebSafeString(_usersKey) ?? '{}';
    final users = Map<String, dynamic>.from(json.decode(usersJson));
    _debugLog('All stored users: ${users.keys.toList()}');
    return users;
  }

  // Debug method: Check SharedPreferences keys
  Future<void> debugStorageState() async {
    _debugLog('=== Debug Storage State ===');
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    _debugLog('SharedPreferences keys: $keys');
    _debugLog('Users: ${await _getWebSafeString(_usersKey)}');
    _debugLog('Current User: ${await _getWebSafeString(_currentUserKey)}');
    _debugLog('Is Logged In: ${await _getWebSafeBool(_isLoggedInKey)}');
    _debugLog('========================');
  }
}
