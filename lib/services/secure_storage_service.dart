import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Service for securely storing and retrieving sensitive data like credentials
/// Uses platform-specific secure storage (Keychain on iOS, KeyStore on Android)
class SecureStorageService {
  // Singleton pattern for global access
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  // Flutter Secure Storage instance with encryption
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Storage keys for different credentials
  static const String _keyRememberMe = 'remember_me';
  static const String _keyEmail = 'saved_email';
  static const String _keyPassword = 'saved_password';
  static const String _keyLastLoginDate = 'last_login_date';

  /// Check if "Remember Me" is enabled
  Future<bool> isRememberMeEnabled() async {
    try {
      final value = await _storage.read(key: _keyRememberMe);
      return value == 'true';
    } catch (e) {
      debugPrint('❌ Error checking remember me status: $e');
      return false;
    }
  }

  /// Save login credentials securely
  /// Only saves if rememberMe is true
  Future<bool> saveCredentials({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    try {
      if (rememberMe) {
        // Save all credentials
        await Future.wait([
          _storage.write(key: _keyRememberMe, value: 'true'),
          _storage.write(key: _keyEmail, value: email),
          _storage.write(key: _keyPassword, value: password),
          _storage.write(
            key: _keyLastLoginDate,
            value: DateTime.now().toIso8601String(),
          ),
        ]);
        debugPrint('✅ Credentials saved securely');
        return true;
      } else {
        // Clear all saved credentials if remember me is disabled
        await clearCredentials();
        return true;
      }
    } catch (e) {
      debugPrint('❌ Error saving credentials: $e');
      return false;
    }
  }

  /// Retrieve saved credentials
  /// Returns null if no credentials are saved or remember me is disabled
  Future<SavedCredentials?> getSavedCredentials() async {
    try {
      final rememberMe = await isRememberMeEnabled();
      
      if (!rememberMe) {
        return null;
      }

      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      final lastLoginDateStr = await _storage.read(key: _keyLastLoginDate);

      if (email == null || password == null) {
        debugPrint('⚠️ Incomplete credentials found, clearing storage');
        await clearCredentials();
        return null;
      }

      DateTime? lastLoginDate;
      if (lastLoginDateStr != null) {
        try {
          lastLoginDate = DateTime.parse(lastLoginDateStr);
        } catch (e) {
          debugPrint('⚠️ Invalid last login date: $e');
        }
      }

      debugPrint('✅ Retrieved saved credentials for: $email');
      return SavedCredentials(
        email: email,
        password: password,
        lastLoginDate: lastLoginDate,
      );
    } catch (e) {
      debugPrint('❌ Error retrieving credentials: $e');
      return null;
    }
  }

  /// Clear all saved credentials
  Future<bool> clearCredentials() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyRememberMe),
        _storage.delete(key: _keyEmail),
        _storage.delete(key: _keyPassword),
        _storage.delete(key: _keyLastLoginDate),
      ]);
      debugPrint('✅ All credentials cleared');
      return true;
    } catch (e) {
      debugPrint('❌ Error clearing credentials: $e');
      return false;
    }
  }

  /// Update only the remember me preference without affecting credentials
  Future<bool> updateRememberMePreference(bool rememberMe) async {
    try {
      if (rememberMe) {
        await _storage.write(key: _keyRememberMe, value: 'true');
      } else {
        // If disabling, clear all credentials
        await clearCredentials();
      }
      return true;
    } catch (e) {
      debugPrint('❌ Error updating remember me preference: $e');
      return false;
    }
  }

  /// Check if credentials exist (without retrieving them)
  Future<bool> hasStoredCredentials() async {
    try {
      final email = await _storage.read(key: _keyEmail);
      final password = await _storage.read(key: _keyPassword);
      return email != null && password != null;
    } catch (e) {
      debugPrint('❌ Error checking stored credentials: $e');
      return false;
    }
  }

  /// Clear all storage (for testing or reset purposes)
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all storage: $e');
    }
  }

  /// Validate credentials are not expired (optional, can set expiry policy)
  /// Returns true if credentials are valid (less than 30 days old)
  Future<bool> areCredentialsValid() async {
    try {
      final lastLoginDateStr = await _storage.read(key: _keyLastLoginDate);
      if (lastLoginDateStr == null) return false;

      final lastLoginDate = DateTime.parse(lastLoginDateStr);
      final daysSinceLogin = DateTime.now().difference(lastLoginDate).inDays;

      // Credentials expire after 30 days for security
      if (daysSinceLogin > 30) {
        debugPrint('⚠️ Credentials expired ($daysSinceLogin days old)');
        await clearCredentials();
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error validating credentials: $e');
      return false;
    }
  }
}

/// Data class for saved credentials
class SavedCredentials {
  final String email;
  final String password;
  final DateTime? lastLoginDate;

  SavedCredentials({
    required this.email,
    required this.password,
    this.lastLoginDate,
  });

  @override
  String toString() {
    return 'SavedCredentials(email: $email, lastLogin: $lastLoginDate)';
  }
}
