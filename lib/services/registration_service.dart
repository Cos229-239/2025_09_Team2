import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import '../models/user.dart' as models;
import '../utils/registration_validator.dart';
import 'firestore_service.dart';

/// Comprehensive registration service that handles user registration with Firebase
/// Includes validation, security measures, and error handling
class RegistrationService {
  static final RegistrationService _instance = RegistrationService._internal();
  factory RegistrationService() => _instance;
  RegistrationService._internal();

  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // Rate limiting for registration attempts
  static const int _maxAttemptsPerHour = 5;
  final Map<String, List<DateTime>> _registrationAttempts = {};

  /// Comprehensive user registration with full validation and security
  Future<RegistrationResult> registerUser({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      // 1. Rate limiting check
      final rateLimitResult = _checkRateLimit(email);
      if (!rateLimitResult.allowed) {
        return RegistrationResult.failure(
          error: rateLimitResult.error ??
              'Too many registration attempts. Please try again later.',
          errorCode: 'rate-limit-exceeded',
        );
      }

      // 2. Comprehensive input validation
      final validationResult = await _validateRegistrationInput(
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        bio: bio,
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
      );

      if (!validationResult.isValid) {
        return RegistrationResult.failure(
          error: validationResult.allErrors.first,
          errorCode: 'validation-failed',
          fieldErrors: validationResult.fieldErrors,
          validationErrors: validationResult.allErrors,
        );
      }

      // 3. Check password confirmation
      if (password != confirmPassword) {
        return RegistrationResult.failure(
          error: 'Passwords do not match',
          errorCode: 'password-mismatch',
          fieldErrors: {'confirmPassword': 'Passwords do not match'},
        );
      }

      // 4. Additional security checks
      final securityResult = await _performSecurityChecks(email, password);
      if (!securityResult.passed) {
        return RegistrationResult.failure(
          error: securityResult.error ?? 'Security validation failed',
          errorCode: 'security-check-failed',
        );
      }

      // 5. Create Firebase Auth account
      final authResult =
          await _createFirebaseAuthAccount(email, password, fullName);
      if (!authResult.success || authResult.user == null) {
        _recordRegistrationAttempt(email);
        return RegistrationResult.failure(
          error: authResult.error ?? 'Failed to create account',
          errorCode: authResult.errorCode ?? 'auth-failed',
        );
      }

      // 6. Send email verification
      await _sendEmailVerification(authResult.user!);

      // 7. Create comprehensive user profile in Firestore
      final userProfile = await _createUserProfile(
        firebaseUser: authResult.user!,
        fullName: fullName,
        username: username,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        bio: bio,
        location: location,
        school: school,
        major: major,
        graduationYear: graduationYear,
        additionalMetadata: additionalMetadata,
      );

      if (userProfile == null) {
        // Rollback: Delete Firebase Auth account if profile creation fails
        await authResult.user!.delete();
        return RegistrationResult.failure(
          error: 'Failed to create user profile. Please try again.',
          errorCode: 'profile-creation-failed',
        );
      }

      // 8. Log analytics event
      await _logRegistrationEvent(userProfile, authResult.user!.uid);

      // 9. Return success result
      return RegistrationResult.success(
        user: userProfile,
        firebaseUser: authResult.user!,
        needsEmailVerification: true,
        message:
            'Account created successfully! Please check your email for verification.',
      );
    } catch (e) {
      debugPrint('Registration error: $e');
      _recordRegistrationAttempt(email);

      return RegistrationResult.failure(
        error:
            'An unexpected error occurred during registration. Please try again.',
        errorCode: 'unexpected-error',
        technicalError: e.toString(),
      );
    }
  }

  /// Validates all registration input fields
  Future<RegistrationValidationResult> _validateRegistrationInput({
    required String email,
    required String password,
    required String confirmPassword,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    required bool acceptedTerms,
    required bool acceptedPrivacy,
  }) async {
    Map<String, String> fieldErrors = {};
    List<String> generalErrors = [];
    List<String> warnings = [];

    // Sanitize inputs
    final sanitizedEmail =
        RegistrationValidator.sanitizeInput(email).toLowerCase();
    final sanitizedName = RegistrationValidator.sanitizeInput(fullName);
    final sanitizedUsername = username != null
        ? RegistrationValidator.sanitizeInput(username).toLowerCase()
        : null;
    final sanitizedBio =
        bio != null ? RegistrationValidator.sanitizeInput(bio) : null;

    // Validate email
    final emailError = RegistrationValidator.validateEmail(sanitizedEmail);
    if (emailError != null) {
      fieldErrors['email'] = emailError;
    } else {
      // Check email availability
      final emailAvailable =
          await RegistrationValidator.isEmailAvailable(sanitizedEmail);
      if (!emailAvailable) {
        fieldErrors['email'] = 'An account with this email already exists';
      }
    }

    // Validate password
    final passwordError = RegistrationValidator.validatePassword(password);
    if (passwordError != null) {
      fieldErrors['password'] = passwordError;
    } else {
      // Check password strength
      final strength =
          RegistrationValidator.calculatePasswordStrength(password);
      if (!strength.isAcceptable) {
        fieldErrors['password'] =
            'Password is too weak. ${strength.feedback.join(', ')}';
      } else if (strength.score < 70) {
        warnings.add('Consider using a stronger password for better security');
      }
    }

    // Validate full name
    final nameError = RegistrationValidator.validateFullName(sanitizedName);
    if (nameError != null) {
      fieldErrors['fullName'] = nameError;
    }

    // Validate username (optional)
    if (sanitizedUsername != null && sanitizedUsername.isNotEmpty) {
      final usernameError =
          RegistrationValidator.validateUsername(sanitizedUsername);
      if (usernameError != null) {
        fieldErrors['username'] = usernameError;
      } else {
        // Check username availability
        final usernameAvailable =
            await RegistrationValidator.isUsernameAvailable(sanitizedUsername);
        if (!usernameAvailable) {
          fieldErrors['username'] = 'This username is already taken';
        }
      }
    }

    // Validate phone number (optional)
    final phoneError = RegistrationValidator.validatePhoneNumber(phoneNumber);
    if (phoneError != null) {
      fieldErrors['phoneNumber'] = phoneError;
    }

    // Validate date of birth (optional)
    final dobError = RegistrationValidator.validateDateOfBirth(dateOfBirth);
    if (dobError != null) {
      fieldErrors['dateOfBirth'] = dobError;
    }

    // Validate bio length (optional)
    if (sanitizedBio != null && sanitizedBio.length > 500) {
      fieldErrors['bio'] = 'Bio must be no more than 500 characters';
    }

    // Validate terms acceptance
    final termsError =
        RegistrationValidator.validateTermsAcceptance(acceptedTerms);
    if (termsError != null) {
      fieldErrors['acceptedTerms'] = termsError;
    }

    // Validate privacy acceptance
    final privacyError =
        RegistrationValidator.validatePrivacyAcceptance(acceptedPrivacy);
    if (privacyError != null) {
      fieldErrors['acceptedPrivacy'] = privacyError;
    }

    return RegistrationValidationResult(
      isValid: fieldErrors.isEmpty && generalErrors.isEmpty,
      fieldErrors: fieldErrors,
      generalErrors: generalErrors,
      warnings: warnings,
    );
  }

  /// Performs additional security checks
  Future<SecurityCheckResult> _performSecurityChecks(
      String email, String password) async {
    try {
      // Check for suspicious patterns
      final lowercaseEmail = email.toLowerCase();

      // Check for test/spam email patterns
      final suspiciousPatterns = ['test', 'spam', 'fake', 'dummy', 'example'];
      for (final pattern in suspiciousPatterns) {
        if (lowercaseEmail.contains(pattern) &&
            (lowercaseEmail.contains('test.com') ||
                lowercaseEmail.contains('example.com'))) {
          return SecurityCheckResult(
            passed: false,
            error: 'Please use a valid email address',
          );
        }
      }

      // Additional password entropy check
      final uniqueChars = password.split('').toSet().length;
      if (uniqueChars < 6) {
        return SecurityCheckResult(
          passed: false,
          error: 'Password must contain more variety in characters',
        );
      }

      return SecurityCheckResult(passed: true);
    } catch (e) {
      debugPrint('Security check error: $e');
      return SecurityCheckResult(passed: true); // Fail open for security checks
    }
  }

  /// Creates Firebase Auth account
  Future<AuthCreationResult> _createFirebaseAuthAccount(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      if (kDebugMode) {
        print('🔄 Attempting to create Firebase Auth account for: ${email.trim().toLowerCase()}');
      }
      
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      if (kDebugMode) {
        print('✅ Firebase Auth account created successfully');
      }
      final user = credential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName.trim());

        return AuthCreationResult(
          success: true,
          user: user,
        );
      } else {
        return AuthCreationResult(
          success: false,
          error: 'Failed to create account',
          errorCode: 'user-null',
        );
      }
    } on auth.FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('❌ Firebase Auth Exception: ${e.code} - ${e.message}');
      }
      return AuthCreationResult(
        success: false,
        error: _getAuthErrorMessage(e.code),
        errorCode: e.code,
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ Unexpected error during account creation: $e');
      }
      return AuthCreationResult(
        success: false,
        error: 'An unexpected error occurred during account creation',
        errorCode: 'unexpected-error',
      );
    }
  }

  /// Sends email verification
  Future<void> _sendEmailVerification(auth.User user) async {
    try {
      await user.sendEmailVerification();
    } catch (e) {
      debugPrint('Error sending email verification: $e');
      // Don't fail registration if email verification fails
    }
  }

  /// Creates comprehensive user profile in Firestore
  Future<models.User?> _createUserProfile({
    required auth.User firebaseUser,
    required String fullName,
    String? username,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? bio,
    String? location,
    String? school,
    String? major,
    int? graduationYear,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    try {
      final now = DateTime.now();

      // Create user model
      final user = models.User(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: fullName.trim(),
        username: username?.trim().toLowerCase(),
        phoneNumber: phoneNumber?.trim(),
        dateOfBirth: dateOfBirth,
        bio: bio?.trim(),
        location: location?.trim(),
        school: school?.trim(),
        major: major?.trim(),
        graduationYear: graduationYear,
        isEmailVerified: false, // Will be updated when email is verified
        createdAt: now,
        lastActiveAt: now,
        loginCount: 0, // Will be incremented on first login
        metadata: {
          'registrationMethod': 'email',
          'registrationTimestamp': now.toIso8601String(),
          'initialEmailVerificationSent': true,
          'registrationIP': 'unknown', // Would be populated from request
          ...?additionalMetadata,
        },
      );

      // Save to Firestore using FirestoreService
      final success = await _firestoreService.createUserProfile(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: fullName.trim(),
        additionalData: {
          'username': username?.trim().toLowerCase(),
          'phoneNumber': phoneNumber?.trim(),
          'dateOfBirth': dateOfBirth?.toIso8601String(),
          'bio': bio?.trim(),
          'location': location?.trim(),
          'school': school?.trim(),
          'major': major?.trim(),
          'graduationYear': graduationYear,
          'registrationMetadata': user.metadata,
        },
      );

      return success ? user : null;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return null;
    }
  }

  /// Logs registration analytics event
  Future<void> _logRegistrationEvent(models.User user, String uid) async {
    try {
      // Here you would typically log to your analytics service
      // For now, we'll just log to debug console
      debugPrint('User registered: ${user.email} ($uid)');

      // Could integrate with Firebase Analytics, Mixpanel, etc.
      // Example:
      // await FirebaseAnalytics.instance.logSignUp(signUpMethod: 'email');
    } catch (e) {
      debugPrint('Error logging registration event: $e');
    }
  }

  /// Rate limiting check
  RateLimitResult _checkRateLimit(String email) {
    final now = DateTime.now();
    final attempts = _registrationAttempts[email] ?? [];

    // Remove attempts older than 1 hour
    attempts.removeWhere((attempt) => now.difference(attempt).inHours >= 1);

    if (attempts.length >= _maxAttemptsPerHour) {
      return RateLimitResult(
        allowed: false,
        error: 'Too many registration attempts. Please try again in an hour.',
      );
    }

    return RateLimitResult(allowed: true);
  }

  /// Records a registration attempt for rate limiting
  void _recordRegistrationAttempt(String email) {
    final attempts = _registrationAttempts[email] ?? [];
    attempts.add(DateTime.now());
    _registrationAttempts[email] = attempts;
  }

  /// Converts Firebase Auth error codes to user-friendly messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please enable it in Firebase Console > Authentication > Sign-in method.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-api-key':
      case 'api-key-not-valid':
        return 'Authentication configuration error. Please check Firebase setup.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'app-not-authorized':
        return 'App not authorized. Please contact support.';
      default:
        debugPrint('Unknown auth error: $errorCode');
        return 'Authentication failed: $errorCode. Please check if Email/Password authentication is enabled in Firebase Console.';
    }
  }

  /// Cleanup method for rate limiting
  void cleanup() {
    final now = DateTime.now();
    _registrationAttempts.removeWhere((email, attempts) {
      attempts.removeWhere((attempt) => now.difference(attempt).inHours >= 1);
      return attempts.isEmpty;
    });
  }
}

/// Result classes for registration operations

class RegistrationResult {
  final bool success;
  final models.User? user;
  final auth.User? firebaseUser;
  final String? error;
  final String? errorCode;
  final String? message;
  final bool needsEmailVerification;
  final Map<String, String>? fieldErrors;
  final List<String>? validationErrors;
  final String? technicalError;

  RegistrationResult._({
    required this.success,
    this.user,
    this.firebaseUser,
    this.error,
    this.errorCode,
    this.message,
    this.needsEmailVerification = false,
    this.fieldErrors,
    this.validationErrors,
    this.technicalError,
  });

  factory RegistrationResult.success({
    required models.User user,
    required auth.User firebaseUser,
    String? message,
    bool needsEmailVerification = false,
  }) {
    return RegistrationResult._(
      success: true,
      user: user,
      firebaseUser: firebaseUser,
      message: message,
      needsEmailVerification: needsEmailVerification,
    );
  }

  factory RegistrationResult.failure({
    required String error,
    String? errorCode,
    Map<String, String>? fieldErrors,
    List<String>? validationErrors,
    String? technicalError,
  }) {
    return RegistrationResult._(
      success: false,
      error: error,
      errorCode: errorCode,
      fieldErrors: fieldErrors,
      validationErrors: validationErrors,
      technicalError: technicalError,
    );
  }
}

class AuthCreationResult {
  final bool success;
  final auth.User? user;
  final String? error;
  final String? errorCode;

  AuthCreationResult({
    required this.success,
    this.user,
    this.error,
    this.errorCode,
  });
}

class SecurityCheckResult {
  final bool passed;
  final String? error;

  SecurityCheckResult({
    required this.passed,
    this.error,
  });
}

class RateLimitResult {
  final bool allowed;
  final String? error;

  RateLimitResult({
    required this.allowed,
    this.error,
  });
}
