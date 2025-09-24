import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service for handling Firestore database operations
/// Manages user profiles, study data, and app data storage
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get decksCollection => _firestore.collection('decks');
  CollectionReference get cardsCollection => _firestore.collection('cards');
  CollectionReference get tasksCollection => _firestore.collection('tasks');
  CollectionReference get notesCollection => _firestore.collection('notes');

  /// Create or update user profile in Firestore with comprehensive data
  Future<bool> createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final userData = {
        'uid': uid,
        'email': email,
        'displayName': displayName,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'emailVerified': false, // Will be updated when email is verified
        'profilePicture': null,
        'bio': additionalData?['bio'] ?? '',
        'username': additionalData?['username'],
        'phoneNumber': additionalData?['phoneNumber'],
        'dateOfBirth': additionalData?['dateOfBirth'],
        'location': additionalData?['location'],
        'school': additionalData?['school'],
        'major': additionalData?['major'],
        'graduationYear': additionalData?['graduationYear'],
        'isPhoneVerified': false,
        'isProfileComplete': false,
        'isActive': true,
        'lastLoginAt': null,
        'loginCount': 0,
        'studyStats': {
          'totalStudyTime': 0,
          'cardsStudied': 0,
          'tasksCompleted': 0,
          'currentStreak': 0,
          'longestStreak': 0,
          'achievementsUnlocked': 0,
        },
        'preferences': {
          'theme': 'Dark',
          'notifications': true,
          'studyReminders': true,
          'dailyGoal': 120, // minutes
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
        'achievements': [],
        'dailyQuests': [],
        'pet': {
          'species': 'cat',
          'level': 1,
          'xp': 0,
          'mood': 'happy',
          'gear': [],
        },
        'metadata': additionalData?['registrationMetadata'] ?? {},
      };

      await usersCollection.doc(uid).set(userData);

      // Log initial analytics event for user registration
      await _logUserAnalyticsEvent(uid, 'user_registered', {
        'registrationMethod': 'email',
        'hasProfilePicture': userData['profilePicture'] != null,
        'hasPhone': userData['phoneNumber'] != null,
        'hasDateOfBirth': userData['dateOfBirth'] != null,
        'hasLocation': userData['location'] != null,
        'hasSchool': userData['school'] != null,
        'hasMajor': userData['major'] != null,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating user profile: $e');
      }
      return false;
    }
  }

  /// Get user profile by UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await usersCollection.doc(uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user profile: $e');
      }
      return null;
    }
  }

  /// Update user profile data
  Future<bool> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await usersCollection.doc(uid).update({
        ...data,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user profile: $e');
      }
      return false;
    }
  }

  /// Mark user email as verified
  Future<bool> markEmailAsVerified(String uid) async {
    try {
      await usersCollection.doc(uid).update({
        'emailVerified': true,
        'emailVerifiedAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error marking email as verified: $e');
      }
      return false;
    }
  }

  /// Update user study statistics
  Future<bool> updateStudyStats(String uid, Map<String, dynamic> stats) async {
    try {
      await usersCollection.doc(uid).update({
        'studyStats': stats,
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error updating study stats: $e');
      }
      return false;
    }
  }

  /// Add achievement to user profile
  Future<bool> addAchievement(
      String uid, Map<String, dynamic> achievement) async {
    try {
      await usersCollection.doc(uid).update({
        'achievements': FieldValue.arrayUnion([achievement]),
        'studyStats.achievementsUnlocked': FieldValue.increment(1),
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error adding achievement: $e');
      }
      return false;
    }
  }

  /// Create a new deck for user
  Future<String?> createDeck({
    required String uid,
    required String title,
    required String description,
    String category = 'General',
  }) async {
    try {
      final deckData = {
        'uid': uid,
        'title': title,
        'description': description,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'cardCount': 0,
        'studyCount': 0,
        'averageScore': 0.0,
        'isPublic': false,
        'tags': [],
      };

      final docRef = await decksCollection.add(deckData);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating deck: $e');
      }
      return null;
    }
  }

  /// Get user's decks
  Future<List<Map<String, dynamic>>> getUserDecks(String uid) async {
    try {
      final querySnapshot = await decksCollection
          .where('uid', isEqualTo: uid)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user decks: $e');
      }
      return [];
    }
  }

  /// Create a new task for user
  Future<String?> createTask({
    required String uid,
    required String title,
    required String description,
    required DateTime dueDate,
    String priority = 'medium',
    String category = 'study',
  }) async {
    try {
      final taskData = {
        'uid': uid,
        'title': title,
        'description': description,
        'dueDate': Timestamp.fromDate(dueDate),
        'priority': priority,
        'category': category,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await tasksCollection.add(taskData);
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('Error creating task: $e');
      }
      return null;
    }
  }

  /// Get user's tasks
  Future<List<Map<String, dynamic>>> getUserTasks(String uid) async {
    try {
      final querySnapshot = await tasksCollection
          .where('uid', isEqualTo: uid)
          .orderBy('dueDate', descending: false)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting user tasks: $e');
      }
      return [];
    }
  }

  /// Delete user data (for account deletion)
  Future<bool> deleteUserData(String uid) async {
    try {
      // Delete user profile
      await usersCollection.doc(uid).delete();

      // Delete user's decks
      final decks = await decksCollection.where('uid', isEqualTo: uid).get();
      for (final doc in decks.docs) {
        await doc.reference.delete();
      }

      // Delete user's tasks
      final tasks = await tasksCollection.where('uid', isEqualTo: uid).get();
      for (final doc in tasks.docs) {
        await doc.reference.delete();
      }

      // Delete user's notes
      final notes = await notesCollection.where('uid', isEqualTo: uid).get();
      for (final doc in notes.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
      return false;
    }
  }

  /// Get real-time user profile stream
  Stream<DocumentSnapshot> getUserProfileStream(String uid) {
    return usersCollection.doc(uid).snapshots();
  }

  /// Get real-time user decks stream
  Stream<QuerySnapshot> getUserDecksStream(String uid) {
    return decksCollection
        .where('uid', isEqualTo: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  /// Get real-time user tasks stream
  Stream<QuerySnapshot> getUserTasksStream(String uid) {
    return tasksCollection
        .where('uid', isEqualTo: uid)
        .orderBy('dueDate', descending: false)
        .snapshots();
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await usersCollection.doc(user.uid).update({
          'lastActiveAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating last active: $e');
      }
    }
  }

  // ==================== ANALYTICS & TRACKING METHODS ====================

  /// Collection reference for user analytics
  CollectionReference get analyticsCollection =>
      _firestore.collection('userAnalytics');
  CollectionReference get registrationMetricsCollection =>
      _firestore.collection('registrationMetrics');

  /// Log user analytics event
  Future<void> _logUserAnalyticsEvent(
      String uid, String eventName, Map<String, dynamic> eventData) async {
    try {
      await analyticsCollection.add({
        'uid': uid,
        'eventName': eventName,
        'eventData': eventData,
        'timestamp': FieldValue.serverTimestamp(),
        'sessionId': _generateSessionId(),
        'platform': 'flutter',
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error logging analytics event: $e');
      }
    }
  }

  /// Track registration attempt for analytics
  Future<void> trackRegistrationAttempt({
    required String email,
    required String outcome, // 'success', 'failure', 'validation_error'
    String? errorType,
    String? errorMessage,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final data = {
        'email': email.toLowerCase(),
        'outcome': outcome,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': 'flutter',
        'userAgent': 'StudyPals Mobile App',
      };

      if (errorType != null) data['errorType'] = errorType;
      if (errorMessage != null) data['errorMessage'] = errorMessage;
      if (additionalData != null) {
        for (final entry in additionalData.entries) {
          data[entry.key] = entry.value;
        }
      }

      await registrationMetricsCollection.add(data);
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking registration attempt: $e');
      }
    }
  }

  /// Track user onboarding progress
  Future<void> trackOnboardingStep(
    String uid,
    String stepName, {
    bool completed = false,
    int stepNumber = 0,
    Map<String, dynamic>? stepData,
  }) async {
    try {
      await _logUserAnalyticsEvent(uid, 'onboarding_step', {
        'stepName': stepName,
        'stepNumber': stepNumber,
        'completed': completed,
        'stepData': stepData ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking onboarding step: $e');
      }
    }
  }

  /// Track user engagement metrics
  Future<void> trackUserEngagement(
    String uid, {
    required String action,
    String? feature,
    int? duration,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      await _logUserAnalyticsEvent(uid, 'user_engagement', {
        'action': action,
        'feature': feature,
        'duration': duration,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking user engagement: $e');
      }
    }
  }

  /// Get user registration analytics (for admin dashboard)
  Future<Map<String, dynamic>> getRegistrationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = registrationMetricsCollection;

      if (startDate != null) {
        query = query.where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('timestamp',
            isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();

      int totalAttempts = snapshot.docs.length;
      int successfulRegistrations = 0;
      int validationErrors = 0;
      int systemErrors = 0;
      Map<String, int> errorTypes = {};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final outcome = data['outcome'] as String?;

        switch (outcome) {
          case 'success':
            successfulRegistrations++;
            break;
          case 'validation_error':
            validationErrors++;
            break;
          case 'failure':
            systemErrors++;
            break;
        }

        final errorType = data['errorType'] as String?;
        if (errorType != null) {
          errorTypes[errorType] = (errorTypes[errorType] ?? 0) + 1;
        }
      }

      return {
        'totalAttempts': totalAttempts,
        'successfulRegistrations': successfulRegistrations,
        'validationErrors': validationErrors,
        'systemErrors': systemErrors,
        'successRate': totalAttempts > 0
            ? (successfulRegistrations / totalAttempts * 100).toStringAsFixed(2)
            : '0.00',
        'errorTypes': errorTypes,
      };
    } catch (e) {
      if (kDebugMode) {
        print('Error getting registration analytics: $e');
      }
      return {};
    }
  }

  /// Update user study statistics
  Future<void> updateUserStudyStats(
    String uid, {
    int? cardsStudied,
    int? studyTimeMinutes,
    int? tasksCompleted,
    bool? streakIncrement,
  }) async {
    try {
      Map<String, dynamic> updates = {};

      if (cardsStudied != null) {
        updates['studyStats.cardsStudied'] = FieldValue.increment(cardsStudied);
      }
      if (studyTimeMinutes != null) {
        updates['studyStats.totalStudyTime'] =
            FieldValue.increment(studyTimeMinutes);
      }
      if (tasksCompleted != null) {
        updates['studyStats.tasksCompleted'] =
            FieldValue.increment(tasksCompleted);
      }
      if (streakIncrement == true) {
        updates['studyStats.currentStreak'] = FieldValue.increment(1);
      }

      if (updates.isNotEmpty) {
        updates['lastActiveAt'] = FieldValue.serverTimestamp();
        await usersCollection.doc(uid).update(updates);

        // Log study session for analytics
        await _logUserAnalyticsEvent(uid, 'study_session', {
          'cardsStudied': cardsStudied ?? 0,
          'studyTimeMinutes': studyTimeMinutes ?? 0,
          'tasksCompleted': tasksCompleted ?? 0,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating user study stats: $e');
      }
    }
  }

  /// Track user preference changes
  Future<void> trackPreferenceChange(String uid, String preferenceName,
      dynamic oldValue, dynamic newValue) async {
    try {
      await _logUserAnalyticsEvent(uid, 'preference_changed', {
        'preferenceName': preferenceName,
        'oldValue': oldValue,
        'newValue': newValue,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error tracking preference change: $e');
      }
    }
  }

  /// Delete user data comprehensively (for account deletion with analytics anonymization)
  Future<bool> deleteAllUserDataAndAnalytics(String uid) async {
    try {
      // Delete user profile
      await usersCollection.doc(uid).delete();

      // Delete user's study data
      final userDecks =
          await decksCollection.where('uid', isEqualTo: uid).get();
      for (final doc in userDecks.docs) {
        await doc.reference.delete();
      }

      final userTasks =
          await tasksCollection.where('uid', isEqualTo: uid).get();
      for (final doc in userTasks.docs) {
        await doc.reference.delete();
      }

      final userNotes =
          await notesCollection.where('uid', isEqualTo: uid).get();
      for (final doc in userNotes.docs) {
        await doc.reference.delete();
      }

      // Note: Analytics data is kept for business intelligence but anonymized
      final userAnalytics =
          await analyticsCollection.where('uid', isEqualTo: uid).get();
      for (final doc in userAnalytics.docs) {
        await doc.reference.update({
          'uid': 'deleted_user',
          'anonymized': true,
          'deletionDate': FieldValue.serverTimestamp(),
        });
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting user data: $e');
      }
      return false;
    }
  }

  /// Generate session ID for analytics
  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Batch update multiple user fields efficiently
  Future<bool> batchUpdateUserProfile(
      String uid, Map<String, dynamic> updates) async {
    try {
      final batch = _firestore.batch();
      final userRef = usersCollection.doc(uid);

      updates['lastActiveAt'] = FieldValue.serverTimestamp();
      batch.update(userRef, updates);

      await batch.commit();

      // Track significant profile updates
      await _logUserAnalyticsEvent(uid, 'profile_updated', {
        'fieldsUpdated': updates.keys.toList(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error batch updating user profile: $e');
      }
      return false;
    }
  }
}
