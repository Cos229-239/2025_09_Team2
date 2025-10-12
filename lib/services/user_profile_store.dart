// user_profile_store.dart
// Persistent user profile storage service with privacy controls

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile_data.dart';
import 'dart:developer' as developer;

/// Service for managing persistent user profiles (opt-in only)
class UserProfileStore {
  final FirebaseFirestore _firestore;
  static const String _collectionName = 'user_profiles';

  UserProfileStore({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get user profile by ID
  /// Returns null if profile doesn't exist or user hasn't opted in
  Future<UserProfileData?> getProfile(String userId) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (!doc.exists) {
        developer.log('No profile found for user: $userId',
            name: 'UserProfileStore');
        return null;
      }

      final profile = UserProfileData.fromJson(doc.data()!);

      // Respect privacy - only return if user has opted in
      if (!profile.optInFlags.profileStorage) {
        developer.log('User has not opted in to profile storage: $userId',
            name: 'UserProfileStore');
        return null;
      }

      return profile;
    } catch (e) {
      developer.log('Error getting profile for $userId: $e',
          name: 'UserProfileStore', error: e);
      return null;
    }
  }

  /// Set complete user profile
  /// Only works if user has opted in
  Future<bool> setProfile(String userId, UserProfileData profile) async {
    try {
      // Verify opt-in before storing
      if (!profile.optInFlags.profileStorage) {
        developer.log('Cannot store profile - user has not opted in: $userId',
            name: 'UserProfileStore');
        return false;
      }

      await _firestore
          .collection(_collectionName)
          .doc(userId)
          .set(profile.toJson());

      developer.log('Profile set successfully for user: $userId',
          name: 'UserProfileStore');
      return true;
    } catch (e) {
      developer.log('Error setting profile for $userId: $e',
          name: 'UserProfileStore', error: e);
      return false;
    }
  }

  /// Merge partial updates into existing profile
  /// Creates new profile if none exists (with opt-in)
  Future<bool> mergeProfile(String userId, Map<String, dynamic> patch) async {
    try {
      final existing = await getProfile(userId);

      if (existing == null) {
        // Check if patch includes opt-in
        final optInData = patch['optInFlags'] as Map<String, dynamic>?;
        if (optInData == null ||
            !(optInData['profileStorage'] as bool? ?? false)) {
          developer.log('Cannot create profile - no opt-in in patch: $userId',
              name: 'UserProfileStore');
          return false;
        }

        // Create new profile with patch data
        final newProfile = UserProfileData(
          userId: userId,
          displayName: patch['displayName'] as String?,
          learningPreferences: patch['learningPreferences'] != null
              ? LearningStylePreferences.fromJson(
                  patch['learningPreferences'] as Map<String, dynamic>)
              : null,
          skillScores: patch['skillScores'] != null
              ? SkillScores.fromJson(
                  patch['skillScores'] as Map<String, dynamic>)
              : null,
          optInFlags: OptInFlags.fromJson(optInData),
          metadata: patch['metadata'] as Map<String, dynamic>?,
        );

        return await setProfile(userId, newProfile);
      }

      // Merge with existing profile
      await _firestore.collection(_collectionName).doc(userId).update({
        ...patch,
        'lastSeen': Timestamp.now(),
      });

      developer.log('Profile merged successfully for user: $userId',
          name: 'UserProfileStore');
      return true;
    } catch (e) {
      developer.log('Error merging profile for $userId: $e',
          name: 'UserProfileStore', error: e);
      return false;
    }
  }

  /// Update opt-in flags for user
  Future<bool> updateOptInFlags(String userId, OptInFlags flags) async {
    try {
      final doc =
          await _firestore.collection(_collectionName).doc(userId).get();

      if (!doc.exists) {
        // Create minimal profile with opt-in flags
        final profile = UserProfileData(
          userId: userId,
          optInFlags: flags,
        );
        return await setProfile(userId, profile);
      }

      await _firestore.collection(_collectionName).doc(userId).update({
        'optInFlags': flags.toJson(),
        'lastSeen': Timestamp.now(),
      });

      developer.log('Opt-in flags updated for user: $userId',
          name: 'UserProfileStore');
      return true;
    } catch (e) {
      developer.log('Error updating opt-in flags for $userId: $e',
          name: 'UserProfileStore', error: e);
      return false;
    }
  }

  /// Update learning style preferences
  Future<bool> updateLearningPreferences(
      String userId, LearningStylePreferences preferences) async {
    return await mergeProfile(userId, {
      'learningPreferences': preferences.toJson(),
    });
  }

  /// Update skill scores
  Future<bool> updateSkillScores(String userId, SkillScores skillScores) async {
    return await mergeProfile(userId, {
      'skillScores': skillScores.toJson(),
    });
  }

  /// Delete user profile (for privacy compliance)
  Future<bool> deleteProfile(String userId) async {
    try {
      await _firestore.collection(_collectionName).doc(userId).delete();

      developer.log('Profile deleted for user: $userId',
          name: 'UserProfileStore');
      return true;
    } catch (e) {
      developer.log('Error deleting profile for $userId: $e',
          name: 'UserProfileStore', error: e);
      return false;
    }
  }

  /// Check if user has a profile and has opted in
  Future<bool> hasOptedIn(String userId) async {
    final profile = await getProfile(userId);
    return profile?.optInFlags.profileStorage ?? false;
  }

  /// Get privacy notice text for UI
  static String getPrivacyNotice() {
    return '''
By enabling profile storage, you allow StudyPals to:
• Remember your learning preferences and style
• Track your progress across subjects
• Personalize your tutoring experience
• Store conversation history for better context

You can opt out at any time, and all stored data will be deleted.
Your data is encrypted and never shared with third parties.
    ''';
  }
}
