import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Comprehensive validation utilities for user registration and security
/// Provides robust validation for all user inputs and prevents common vulnerabilities
class RegistrationValidator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Common password patterns and weak passwords
  static final List<String> _commonPasswords = [
    'password',
    'password123',
    '123456',
    '12345678',
    'qwerty',
    'abc123',
    'letmein',
    'welcome',
    'monkey',
    'dragon',
    'master',
    'admin',
    'guest',
    '111111',
    '000000',
    'password1',
    'iloveyou',
    'sunshine',
    'princess',
  ];

  /// Validates email address format and checks for suspicious patterns
  /// Returns null if valid, error message if invalid
  static String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email address is required';
    }

    // Basic format validation
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email)) {
      return 'Please enter a valid email address';
    }

    // Check length constraints
    if (email.length > 254) {
      return 'Email address is too long (maximum 254 characters)';
    }

    final parts = email.split('@');
    if (parts[0].length > 64) {
      return 'Email username part is too long (maximum 64 characters)';
    }

    // Check for suspicious patterns
    if (email.contains('..')) {
      return 'Email address contains invalid consecutive dots';
    }

    if (email.startsWith('.') ||
        email.endsWith('.') ||
        email.contains('@.') ||
        email.contains('.@')) {
      return 'Email address has invalid dot placement';
    }

    // Check for temporary/disposable email patterns
    final disposablePatterns = [
      '10minutemail',
      'tempmail',
      'guerrillamail',
      'mailinator',
      'throwaway',
      'temporary',
      'disposable',
      '0-mail',
      'fakeinbox'
    ];

    final lowercaseEmail = email.toLowerCase();
    for (final pattern in disposablePatterns) {
      if (lowercaseEmail.contains(pattern)) {
        return 'Temporary email addresses are not allowed';
      }
    }

    return null; // Valid email
  }

  /// Validates password strength and security requirements
  /// Returns null if valid, error message if invalid
  static String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }

    // Length requirements
    if (password.length < 8) {
      return 'Password must be at least 8 characters long';
    }

    if (password.length > 128) {
      return 'Password is too long (maximum 128 characters)';
    }

    // Check for common weak passwords
    final lowercasePassword = password.toLowerCase();
    if (_commonPasswords.contains(lowercasePassword)) {
      return 'This password is too common and easily guessed';
    }

    // Character variety requirements
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars =
        password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]'));

    List<String> missingRequirements = [];
    if (!hasUppercase) missingRequirements.add('uppercase letter');
    if (!hasLowercase) missingRequirements.add('lowercase letter');
    if (!hasDigits) missingRequirements.add('number');
    if (!hasSpecialChars) missingRequirements.add('special character');

    if (missingRequirements.length > 1) {
      return 'Password must contain at least: ${missingRequirements.join(', ')}';
    }

    // Check for repeated characters (more than 3 consecutive)
    for (int i = 0; i < password.length - 2; i++) {
      if (password[i] == password[i + 1] &&
          password[i + 1] == password[i + 2]) {
        return 'Password cannot contain more than 2 consecutive identical characters';
      }
    }

    // Check for keyboard patterns
    final keyboardPatterns = [
      'qwerty',
      'asdfgh',
      'zxcvbn',
      '123456',
      '098765',
      'qwertyuiop',
      'asdfghjkl',
      'zxcvbnm'
    ];

    for (final pattern in keyboardPatterns) {
      if (lowercasePassword.contains(pattern) ||
          lowercasePassword.contains(pattern.split('').reversed.join())) {
        return 'Password cannot contain common keyboard patterns';
      }
    }

    return null; // Valid password
  }

  /// Calculates password strength score (0-100)
  /// Higher scores indicate stronger passwords
  static PasswordStrength calculatePasswordStrength(String password) {
    if (password.isEmpty) {
      return PasswordStrength(
          score: 0, level: 'Very Weak', feedback: ['Password is required']);
    }

    int score = 0;
    List<String> feedback = [];

    // Length scoring
    if (password.length >= 8) {
      score += 25;
    } else {
      feedback.add('Use at least 8 characters');
    }

    if (password.length >= 12) {
      score += 10;
    }
    if (password.length >= 16) {
      score += 10;
    }

    // Character variety
    if (password.contains(RegExp(r'[a-z]'))) {
      score += 15;
    } else {
      feedback.add('Add lowercase letters');
    }

    if (password.contains(RegExp(r'[A-Z]'))) {
      score += 15;
    } else {
      feedback.add('Add uppercase letters');
    }

    if (password.contains(RegExp(r'[0-9]'))) {
      score += 15;
    } else {
      feedback.add('Add numbers');
    }

    if (password.contains(RegExp(r'[!@#$%^&*()_+\-=\[\]{};:"\\|,.<>\/?]'))) {
      score += 20;
    } else {
      feedback.add('Add special characters');
    }

    // Deduct points for common patterns
    final lowercasePassword = password.toLowerCase();
    if (_commonPasswords.contains(lowercasePassword)) {
      score -= 30;
      feedback.add('Avoid common passwords');
    }

    // Check for repeated patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) {
      score -= 10;
      feedback.add('Avoid repeated characters');
    }

    // Ensure score is within bounds
    score = score.clamp(0, 100);

    String level;
    if (score < 30) {
      level = 'Very Weak';
    } else if (score < 50) {
      level = 'Weak';
    } else if (score < 70) {
      level = 'Fair';
    } else if (score < 85) {
      level = 'Good';
    } else {
      level = 'Excellent';
    }

    return PasswordStrength(score: score, level: level, feedback: feedback);
  }

  /// Validates username for uniqueness and format
  /// Returns null if valid, error message if invalid
  static String? validateUsername(String username) {
    if (username.isEmpty) {
      return null; // Username is optional
    }

    // Length constraints
    if (username.length < 3) {
      return 'Username must be at least 3 characters long';
    }

    if (username.length > 20) {
      return 'Username must be no more than 20 characters long';
    }

    // Character restrictions (alphanumeric and underscore only)
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(username)) {
      return 'Username can only contain letters, numbers, and underscores';
    }

    // Cannot start or end with underscore
    if (username.startsWith('_') || username.endsWith('_')) {
      return 'Username cannot start or end with underscore';
    }

    // Cannot have consecutive underscores
    if (username.contains('__')) {
      return 'Username cannot contain consecutive underscores';
    }

    // Check for reserved usernames
    final reservedUsernames = [
      'admin',
      'administrator',
      'root',
      'system',
      'api',
      'www',
      'mail',
      'support',
      'help',
      'info',
      'contact',
      'about',
      'terms',
      'privacy',
      'studypals',
      'studypal',
      'moderator',
      'mod',
      'staff',
      'team'
    ];

    if (reservedUsernames.contains(username.toLowerCase())) {
      return 'This username is reserved and cannot be used';
    }

    return null; // Valid username format
  }

  /// Checks if username is already taken in Firestore
  /// Returns true if available, false if taken
  static Future<bool> isUsernameAvailable(String username) async {
    if (username.isEmpty) return true; // Username is optional

    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      // If query fails, assume username might be taken (safe fallback)
      return false;
    }
  }

  /// Checks if email is already registered in Firebase Auth
  /// Note: This should be used carefully to avoid user enumeration attacks
  static Future<bool> isEmailAvailable(String email) async {
    // This is typically handled by Firebase Auth during registration
    // We can't directly query Firebase Auth for email existence
    // So we check Firestore user profiles instead
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase())
          .limit(1)
          .get();

      return querySnapshot.docs.isEmpty;
    } catch (e) {
      return false; // Safe fallback
    }
  }

  /// Validates full name field
  /// Returns null if valid, error message if invalid
  static String? validateFullName(String name) {
    if (name.trim().isEmpty) {
      return 'Full name is required';
    }

    final trimmedName = name.trim();

    // Length constraints
    if (trimmedName.length < 2) {
      return 'Name must be at least 2 characters long';
    }

    if (trimmedName.length > 50) {
      return 'Name must be no more than 50 characters long';
    }

    // Character restrictions (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(trimmedName)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }

    // Check for suspicious patterns
    if (trimmedName.contains(RegExp(r'\s{2,}'))) {
      return 'Name cannot contain multiple consecutive spaces';
    }

    if (trimmedName.startsWith(' ') || trimmedName.endsWith(' ')) {
      return 'Name cannot start or end with spaces';
    }

    // Require at least one space (first and last name)
    if (!trimmedName.contains(' ')) {
      return 'Please enter your full name (first and last name)';
    }

    return null; // Valid name
  }

  /// Validates phone number format (optional field)
  /// Returns null if valid or empty, error message if invalid
  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      return null; // Phone number is optional
    }

    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

    // Basic phone number validation (international format)
    final phoneRegex = RegExp(r'^\+?[1-9]\d{9,14}$');
    if (!phoneRegex.hasMatch(cleanPhone)) {
      return 'Please enter a valid phone number';
    }

    return null; // Valid phone number
  }

  /// Validates date of birth (optional field)
  /// Returns null if valid or null, error message if invalid
  static String? validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return null; // Date of birth is optional
    }

    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;

    // Check if user is at least 13 years old (COPPA compliance)
    if (age < 13) {
      return 'You must be at least 13 years old to register';
    }

    // Check if date is not in the future
    if (dateOfBirth.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }

    // Check if date is reasonable (not too far in the past)
    if (age > 120) {
      return 'Please enter a valid date of birth';
    }

    return null; // Valid date of birth
  }

  /// Sanitizes user input to prevent XSS and injection attacks
  static String sanitizeInput(String input) {
    return input
        .trim()
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'[<>&"\x27`]'), '') // Remove dangerous characters
        .replaceAll(RegExp(r'\s+'), ' '); // Normalize whitespace
  }

  /// Generates a secure verification token
  static String generateVerificationToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values).replaceAll('=', '');
  }

  /// Validates terms and conditions acceptance
  static String? validateTermsAcceptance(bool accepted) {
    if (!accepted) {
      return 'You must accept the Terms and Conditions to register';
    }
    return null;
  }

  /// Validates privacy policy acceptance
  static String? validatePrivacyAcceptance(bool accepted) {
    if (!accepted) {
      return 'You must accept the Privacy Policy to register';
    }
    return null;
  }
}

/// Password strength result class
class PasswordStrength {
  final int score; // 0-100 strength score
  final String level; // Descriptive strength level
  final List<String> feedback; // Improvement suggestions

  PasswordStrength({
    required this.score,
    required this.level,
    required this.feedback,
  });

  /// Get color for password strength indicator
  String get color {
    if (score < 30) return '#EF4444'; // Red
    if (score < 50) return '#F97316'; // Orange
    if (score < 70) return '#EAB308'; // Yellow
    if (score < 85) return '#22C55E'; // Green
    return '#059669'; // Dark green
  }

  /// Check if password is strong enough for registration
  bool get isAcceptable => score >= 50;
}

/// Registration result class for comprehensive error handling
class RegistrationValidationResult {
  final bool isValid;
  final Map<String, String> fieldErrors;
  final List<String> generalErrors;
  final List<String> warnings;

  RegistrationValidationResult({
    required this.isValid,
    this.fieldErrors = const {},
    this.generalErrors = const [],
    this.warnings = const [],
  });

  /// Check if specific field has error
  bool hasFieldError(String fieldName) => fieldErrors.containsKey(fieldName);

  /// Get error message for specific field
  String? getFieldError(String fieldName) => fieldErrors[fieldName];

  /// Get all error messages as a list
  List<String> get allErrors => [...generalErrors, ...fieldErrors.values];
}
