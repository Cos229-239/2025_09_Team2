import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/pet.dart';
import '../models/review.dart';
import '../models/quiz_session.dart';

/// Service for handling Firestore database operations
/// Manages user profiles, study data, and app data storage
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal() {
    _initializeFirestore();
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize Firestore with offline support
  void _initializeFirestore() {
    try {
      // Enable offline persistence for better connectivity
      if (!kIsWeb) {
        // Mobile platforms can use offline persistence
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      if (kDebugMode) {
        print('✅ Firestore configured with offline support');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Firestore offline configuration issue: $e');
      }
    }
  }

  // Collection references
  CollectionReference get usersCollection => _firestore.collection('users');
  CollectionReference get decksCollection => _firestore.collection('decks');
  CollectionReference get cardsCollection => _firestore.collection('cards');
  CollectionReference get tasksCollection => _firestore.collection('tasks');
  CollectionReference get notesCollection => _firestore.collection('notes');
  CollectionReference get activitiesCollection =>
      _firestore.collection('activities');
  CollectionReference get friendshipsCollection =>
      _firestore.collection('friendships');
  CollectionReference get studyGroupsCollection =>
      _firestore.collection('study_groups');

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

  /// Create a new deck with cards for user
  Future<String?> createDeckWithCards({
    required String uid,
    required String title,
    required String description,
    required List<Map<String, dynamic>> cards,
    String category = 'General',
    List<String> tags = const [],
  }) async {
    try {
      final deckData = {
        'uid': uid,
        'title': title,
        'description': description,
        'category': category,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'cardCount': cards.length,
        'studyCount': 0,
        'averageScore': 0.0,
        'isPublic': false,
        'tags': tags,
        'cards': cards, // Store the actual flashcards
      };

      final docRef = await decksCollection.add(deckData);
      if (kDebugMode) {
        print('✅ Created deck with ${cards.length} cards. ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating deck with cards: $e');
      }
      return null;
    }
  }

  /// Get user's decks
  Future<List<Map<String, dynamic>>> getUserDecks(String uid) async {
    try {
      debugPrint('🔍 FirestoreService: getUserDecks called for uid: $uid');

      // Try with orderBy first (requires composite index)
      try {
        final querySnapshot = await decksCollection
            .where('uid', isEqualTo: uid)
            .orderBy('updatedAt', descending: true)
            .get();

        debugPrint(
            '🔍 FirestoreService: Query with orderBy returned ${querySnapshot.docs.length} documents');

        final results = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          debugPrint(
              '🔍 FirestoreService: Deck doc ${doc.id}: ${data['title']}');
          return data;
        }).toList();

        debugPrint('🔍 FirestoreService: Returning ${results.length} decks');
        return results;
      } catch (indexError) {
        // If index error, fall back to query without orderBy
        debugPrint(
            '⚠️ FirestoreService: Index error, trying without orderBy: $indexError');

        final querySnapshot =
            await decksCollection.where('uid', isEqualTo: uid).get();

        debugPrint(
            '🔍 FirestoreService: Query without orderBy returned ${querySnapshot.docs.length} documents');

        final results = querySnapshot.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id;
          debugPrint(
              '🔍 FirestoreService: Deck doc ${doc.id}: ${data['title']}');
          return data;
        }).toList();

        // Sort in memory if needed
        results.sort((a, b) {
          final aTime = a['updatedAt']?.toDate() ?? DateTime.now();
          final bTime = b['updatedAt']?.toDate() ?? DateTime.now();
          return bTime.compareTo(aTime);
        });

        debugPrint(
            '🔍 FirestoreService: Returning ${results.length} decks (sorted in memory)');
        return results;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user decks: $e');
      }
      return [];
    }
  }

  /// Delete a deck from Firestore
  Future<bool> deleteDeck(String deckId, [String? userId]) async {
    try {
      final uid = userId ?? _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) {
          print('❌ Cannot delete deck: No user authenticated');
        }
        return false;
      }

      // Verify the deck belongs to the user before deleting
      final deckDoc = await decksCollection.doc(deckId).get();
      if (!deckDoc.exists) {
        if (kDebugMode) {
          print('❌ Deck not found: $deckId');
        }
        return false;
      }

      final deckData = deckDoc.data() as Map<String, dynamic>;
      if (deckData['uid'] != uid) {
        if (kDebugMode) {
          print('❌ Cannot delete deck: User does not own this deck');
        }
        return false;
      }

      // Delete the deck
      await decksCollection.doc(deckId).delete();

      // Also remove any deck cooldowns
      await removeDeckCooldown(deckId, uid);

      if (kDebugMode) {
        print('✅ Deleted deck: $deckId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting deck: $e');
      }
      return false;
    }
  }

  /// Update an existing deck in Firestore
  Future<bool> updateDeck({
    required String deckId,
    required String uid,
    required Map<String, dynamic> deckData,
  }) async {
    try {
      // Verify the deck belongs to the user
      final deckDoc = await decksCollection.doc(deckId).get();
      if (!deckDoc.exists) {
        if (kDebugMode) {
          print('❌ Deck not found: $deckId');
        }
        return false;
      }

      final existingData = deckDoc.data() as Map<String, dynamic>;
      if (existingData['uid'] != uid) {
        if (kDebugMode) {
          print('❌ Cannot update deck: User does not own this deck');
        }
        return false;
      }

      // Update the deck with new data
      deckData['updatedAt'] = FieldValue.serverTimestamp();
      await decksCollection.doc(deckId).update(deckData);

      if (kDebugMode) {
        print('✅ Updated deck: $deckId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating deck: $e');
      }
      return false;
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

  // ==================== ENHANCED TASK MANAGEMENT METHODS ====================

  /// Create a new task using the full Task model
  Future<String?> createFullTask(
      String uid, Map<String, dynamic> taskData) async {
    try {
      final taskWithMeta = {
        ...taskData,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isArchived': false,
      };

      final docRef = await tasksCollection.add(taskWithMeta);
      if (kDebugMode) {
        print('✅ Created full task: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating full task: $e');
      }
      return null;
    }
  }

  /// Get all tasks for a user using the full Task model
  Future<List<Map<String, dynamic>>> getUserFullTasks(String uid) async {
    try {
      final querySnapshot = await tasksCollection
          .where('uid', isEqualTo: uid)
          .where('isArchived', isEqualTo: false)
          .get();

      final tasks = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      
      // Sort by createdAt in memory instead of in the query
      tasks.sort((a, b) {
        final aCreated = a['createdAt'];
        final bCreated = b['createdAt'];
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        
        // Handle both Timestamp and String formats
        DateTime aDate;
        DateTime bDate;
        if (aCreated is String) {
          aDate = DateTime.parse(aCreated);
        } else {
          aDate = (aCreated as Timestamp).toDate();
        }
        if (bCreated is String) {
          bDate = DateTime.parse(bCreated);
        } else {
          bDate = (bCreated as Timestamp).toDate();
        }
        return bDate.compareTo(aDate); // Descending order
      });

      if (kDebugMode) {
        print('✅ Retrieved ${tasks.length} full tasks for user: $uid');
      }
      return tasks;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving full tasks: $e');
      }
      return [];
    }
  }

  /// Update an existing task using the full Task model
  Future<bool> updateFullTask(
      String taskId, Map<String, dynamic> updateData) async {
    try {
      await tasksCollection.doc(taskId).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Updated full task: $taskId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating full task: $e');
      }
      return false;
    }
  }

  /// Delete (archive) a task using the full Task model
  Future<bool> deleteFullTask(String taskId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Attempting to archive task: $taskId');
      }
      
      // First check if the document exists
      final docSnapshot = await tasksCollection.doc(taskId).get();
      
      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print('⚠️ Task does not exist in Firestore: $taskId');
          print('   This task may have been created locally and never saved to the database.');
        }
        // Return true since the task doesn't exist anyway (idempotent delete)
        return true;
      }
      
      // Archive the task by setting isArchived to true
      await tasksCollection.doc(taskId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Archived full task: $taskId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving full task $taskId: $e');
      }
      return false;
    }
  }

  /// Get real-time user tasks stream using the full Task model
  Stream<QuerySnapshot> getUserFullTasksStream(String uid) {
    return tasksCollection
        .where('uid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== NOTES MANAGEMENT METHODS ====================

  /// Create a new note for user
  Future<String?> createNote({
    required String uid,
    required String title,
    required String contentMd,
    List<String> tags = const [],
  }) async {
    try {
      final noteData = {
        'uid': uid,
        'title': title,
        'contentMd': contentMd,
        'tags': tags,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'wordCount': contentMd.split(' ').length,
        'isArchived': false,
      };

      final docRef = await notesCollection.add(noteData);
      if (kDebugMode) {
        print('✅ Created note with ID: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating note: $e');
      }
      return null;
    }
  }

  /// Get user's notes
  Future<List<Map<String, dynamic>>> getUserNotes(String uid) async {
    try {
      final querySnapshot = await notesCollection
          .where('uid', isEqualTo: uid)
          .where('isArchived', isEqualTo: false)
          .orderBy('updatedAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting user notes: $e');
      }
      return [];
    }
  }

  /// Update an existing note
  Future<bool> updateNote({
    required String noteId,
    required String uid,
    String? title,
    String? contentMd,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (title != null) updateData['title'] = title;
      if (contentMd != null) {
        updateData['contentMd'] = contentMd;
        updateData['wordCount'] = contentMd.split(' ').length;
      }
      if (tags != null) updateData['tags'] = tags;

      await notesCollection.doc(noteId).update(updateData);
      if (kDebugMode) {
        print('✅ Updated note: $noteId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating note: $e');
      }
      return false;
    }
  }

  /// Delete a note (soft delete by archiving)
  Future<bool> deleteNote(String noteId) async {
    try {
      await notesCollection.doc(noteId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Archived note: $noteId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving note: $e');
      }
      return false;
    }
  }

  /// Get real-time user notes stream
  Stream<QuerySnapshot> getUserNotesStream(String uid) {
    return notesCollection
        .where('uid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }

  // ==================== DAILY QUEST MANAGEMENT METHODS ====================

  /// Collection reference for daily quests
  CollectionReference get dailyQuestsCollection =>
      _firestore.collection('dailyQuests');

  /// Create a new daily quest for user
  Future<String?> createDailyQuest(
      String uid, Map<String, dynamic> questData) async {
    try {
      final questWithMeta = {
        ...questData,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isArchived': false,
      };

      final docRef = await dailyQuestsCollection.add(questWithMeta);
      if (kDebugMode) {
        print('✅ Created daily quest: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating daily quest: $e');
      }
      return null;
    }
  }

  /// Get all daily quests for a specific user
  Future<List<Map<String, dynamic>>> getUserDailyQuests(String uid) async {
    try {
      final querySnapshot = await dailyQuestsCollection
          .where('uid', isEqualTo: uid)
          .where('isArchived', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      final quests = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        print('✅ Retrieved ${quests.length} daily quests for user: $uid');
      }
      return quests;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving daily quests: $e');
      }
      return [];
    }
  }

  /// Update an existing daily quest
  Future<bool> updateDailyQuest(
      String questId, Map<String, dynamic> updateData) async {
    try {
      await dailyQuestsCollection.doc(questId).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Updated daily quest: $questId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating daily quest: $e');
      }
      return false;
    }
  }

  /// Delete (archive) a daily quest
  Future<bool> deleteDailyQuest(String questId) async {
    try {
      await dailyQuestsCollection.doc(questId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Archived daily quest: $questId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving daily quest: $e');
      }
      return false;
    }
  }

  /// Get real-time user daily quests stream
  Stream<QuerySnapshot> getUserDailyQuestsStream(String uid) {
    return dailyQuestsCollection
        .where('uid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== CALENDAR EVENT MANAGEMENT METHODS ====================

  /// Collection reference for calendar events
  CollectionReference get calendarEventsCollection =>
      _firestore.collection('calendarEvents');

  /// Create a new calendar event for user
  Future<String?> createCalendarEvent(
      String uid, Map<String, dynamic> eventData) async {
    try {
      final eventWithMeta = {
        ...eventData,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isArchived': false,
      };

      final docRef = await calendarEventsCollection.add(eventWithMeta);
      if (kDebugMode) {
        print('✅ Created calendar event: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating calendar event: $e');
      }
      return null;
    }
  }

  /// Get all calendar events for a specific user
  Future<List<Map<String, dynamic>>> getUserCalendarEvents(String uid) async {
    try {
      final querySnapshot = await calendarEventsCollection
          .where('uid', isEqualTo: uid)
          .where('isArchived', isEqualTo: false)
          .orderBy('startTime', descending: false)
          .get();

      final events = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        print('✅ Retrieved ${events.length} calendar events for user: $uid');
      }
      return events;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving calendar events: $e');
      }
      return [];
    }
  }

  /// Update an existing calendar event
  Future<bool> updateCalendarEvent(
      String eventId, Map<String, dynamic> updateData) async {
    try {
      await calendarEventsCollection.doc(eventId).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Updated calendar event: $eventId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating calendar event: $e');
      }
      return false;
    }
  }

  /// Delete (archive) a calendar event
  Future<bool> deleteCalendarEvent(String eventId) async {
    try {
      if (kDebugMode) {
        print('🗑️ Attempting to archive calendar event: $eventId');
      }
      
      // First check if the document exists
      final docSnapshot = await calendarEventsCollection.doc(eventId).get();
      
      if (!docSnapshot.exists) {
        if (kDebugMode) {
          print('⚠️ Calendar event does not exist in Firestore: $eventId');
          print('   This event may have been created locally and never saved to the database.');
        }
        // Return true since the event doesn't exist anyway (idempotent delete)
        return true;
      }
      
      // Archive the event
      await calendarEventsCollection.doc(eventId).update({
        'isArchived': true,
        'archivedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      if (kDebugMode) {
        print('✅ Archived calendar event: $eventId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error archiving calendar event $eventId: $e');
      }
      return false;
    }
  }

  /// Get real-time user calendar events stream
  Stream<QuerySnapshot> getUserCalendarEventsStream(String uid) {
    return calendarEventsCollection
        .where('uid', isEqualTo: uid)
        .where('isArchived', isEqualTo: false)
        .orderBy('startTime', descending: false)
        .snapshots();
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Use set with merge to create document if it doesn't exist
        await usersCollection.doc(user.uid).set({
          'lastActiveAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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

  // ==================== Pet CRUD Operations ====================

  /// Get user's pet data from Firestore
  /// @param userId - User ID to get pet for (optional, uses current user if null)
  /// @return Pet object or null if no pet exists
  Future<Pet?> getUserPet([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet retrieval');
        return null;
      }

      final doc = await usersCollection
          .doc(uid)
          .collection('pets')
          .doc('currentPet')
          .get();

      if (!doc.exists) {
        if (kDebugMode) print('ℹ️ No pet found for user: $uid');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      return Pet.fromJson(data);
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving pet: $e');
      return null;
    }
  }

  /// Save or update user's pet data in Firestore
  /// @param pet - Pet object to save
  /// @param userId - User ID to save pet for (optional, uses current user if null)
  /// @return Success status
  Future<bool> savePet(Pet pet, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet save');
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('pets')
          .doc('currentPet')
          .set(pet.toJson(), SetOptions(merge: true));

      if (kDebugMode) print('✅ Pet saved successfully for user: $uid');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving pet: $e');
      return false;
    }
  }

  /// Create a new pet for user (typically when they first start)
  /// @param species - Type of pet to create
  /// @param userId - User ID to create pet for (optional, uses current user if null)
  /// @return Created Pet object or null if failed
  Future<Pet?> createPet(PetSpecies species, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet creation');
        return null;
      }

      final newPet = Pet(
        userId: uid,
        species: species,
        level: 1,
        xp: 0,
        gear: [],
        mood: PetMood.happy,
      );

      final success = await savePet(newPet, uid);
      if (success) {
        if (kDebugMode) print('✅ New pet created for user: $uid');
        return newPet;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating pet: $e');
      return null;
    }
  }

  /// Add XP to user's pet and handle level-ups
  /// @param xpAmount - Amount of XP to add
  /// @param userId - User ID to add XP for (optional, uses current user if null)
  /// @return Updated Pet object or null if failed
  Future<Pet?> addPetXP(int xpAmount, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet XP update');
        return null;
      }

      final currentPet = await getUserPet(uid);
      if (currentPet == null) {
        if (kDebugMode) print('ℹ️ No pet found, creating default cat pet');
        final newPet = await createPet(PetSpecies.cat, uid);
        if (newPet != null) {
          return addPetXP(xpAmount, uid); // Recursively add XP to new pet
        }
        return null;
      }

      final updatedPet = currentPet.addXP(xpAmount);
      final success = await savePet(updatedPet, uid);

      if (success) {
        if (kDebugMode) {
          print(
              '✅ Added $xpAmount XP to pet. Level: ${updatedPet.level}, XP: ${updatedPet.xp}');
        }
        return updatedPet;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error adding pet XP: $e');
      return null;
    }
  }

  /// Get real-time stream of user's pet data
  /// @param userId - User ID to stream pet for (optional, uses current user if null)
  /// @return Stream of Pet objects
  Stream<Pet?> getPetStream([String? userId]) {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet stream');
        return Stream.value(null);
      }

      return usersCollection
          .doc(uid)
          .collection('pets')
          .doc('currentPet')
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        final data = doc.data() as Map<String, dynamic>;
        return Pet.fromJson(data);
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error creating pet stream: $e');
      return Stream.value(null);
    }
  }

  /// Delete user's pet data (use with caution)
  /// @param userId - User ID to delete pet for (optional, uses current user if null)
  /// @return Success status
  Future<bool> deletePet([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for pet deletion');
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('pets')
          .doc('currentPet')
          .delete();

      if (kDebugMode) print('✅ Pet deleted for user: $uid');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting pet: $e');
      return false;
    }
  }

  // ==================== Review CRUD Operations (SRS System) ====================

  /// Get all reviews for a specific user
  /// @param userId - User ID to get reviews for (optional, uses current user if null)
  /// @return List of Review objects
  Future<List<Review>> getUserReviews([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for reviews retrieval');
        return [];
      }

      final querySnapshot =
          await usersCollection.doc(uid).collection('reviews').get();

      final reviews =
          querySnapshot.docs.map((doc) => Review.fromJson(doc.data())).toList();

      if (kDebugMode) {
        print('✅ Retrieved ${reviews.length} reviews for user: $uid');
      }
      return reviews;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving reviews: $e');
      return [];
    }
  }

  /// Get review for a specific card
  /// @param cardId - Card ID to get review for
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Review object or null if not found
  Future<Review?> getCardReview(String cardId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for card review retrieval');
        }
        return null;
      }

      final doc = await usersCollection
          .doc(uid)
          .collection('reviews')
          .doc(cardId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return Review.fromJson(doc.data()!);
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving card review: $e');
      return null;
    }
  }

  /// Get reviews that are due for study
  /// @param userId - User ID (optional, uses current user if null)
  /// @return List of Review objects that are due now or overdue
  Future<List<Review>> getDueReviews([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for due reviews retrieval');
        }
        return [];
      }

      final now = DateTime.now();
      final querySnapshot = await usersCollection
          .doc(uid)
          .collection('reviews')
          .where('dueAt', isLessThanOrEqualTo: now.toIso8601String())
          .get();

      final dueReviews =
          querySnapshot.docs.map((doc) => Review.fromJson(doc.data())).toList();

      if (kDebugMode) {
        print('✅ Retrieved ${dueReviews.length} due reviews for user: $uid');
      }
      return dueReviews;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving due reviews: $e');
      return [];
    }
  }

  /// Save or update a review
  /// @param review - Review object to save
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> saveReview(Review review, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for review save');
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('reviews')
          .doc(review.cardId)
          .set(review.toJson(), SetOptions(merge: true));

      if (kDebugMode) print('✅ Review saved for card: ${review.cardId}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving review: $e');
      return false;
    }
  }

  /// Create a new review for a card (first time studying)
  /// @param cardId - ID of the card to create review for
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Created Review object or null if failed
  Future<Review?> createReview(String cardId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for review creation');
        return null;
      }

      final newReview = Review(
        cardId: cardId,
        userId: uid,
        dueAt: DateTime.now(), // Due immediately for first review
        ease: 2.5, // Default ease factor
        interval: 1, // Start with 1-day interval
        reps: 0, // No repetitions yet
      );

      final success = await saveReview(newReview, uid);
      if (success) {
        if (kDebugMode) print('✅ New review created for card: $cardId');
        return newReview;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error creating review: $e');
      return null;
    }
  }

  /// Update review after user completes a study session
  /// @param cardId - ID of the card that was studied
  /// @param grade - User's performance grade
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Updated Review object or null if failed
  Future<Review?> updateReviewWithGrade(String cardId, ReviewGrade grade,
      [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for review update');
        return null;
      }

      // Get current review or create if doesn't exist
      Review? currentReview = await getCardReview(cardId, uid);
      currentReview ??= await createReview(cardId, uid);

      if (currentReview == null) {
        if (kDebugMode) {
          print('❌ Failed to get or create review for card: $cardId');
        }
        return null;
      }

      // Update review with the grade using SM-2 algorithm
      final updatedReview = currentReview.updateWithGrade(grade);

      final success = await saveReview(updatedReview, uid);
      if (success) {
        if (kDebugMode) {
          print(
              '✅ Review updated for card: $cardId, Grade: $grade, Next due: ${updatedReview.dueAt}');
        }
        return updatedReview;
      }
      return null;
    } catch (e) {
      if (kDebugMode) print('❌ Error updating review with grade: $e');
      return null;
    }
  }

  /// Get real-time stream of due reviews
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Stream of due Review objects
  Stream<List<Review>> getDueReviewsStream([String? userId]) {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for due reviews stream');
        return Stream.value([]);
      }

      final now = DateTime.now();
      return usersCollection
          .doc(uid)
          .collection('reviews')
          .where('dueAt', isLessThanOrEqualTo: now.toIso8601String())
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => Review.fromJson(doc.data())).toList();
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error creating due reviews stream: $e');
      return Stream.value([]);
    }
  }

  /// Delete a review (use with caution)
  /// @param cardId - ID of the card review to delete
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> deleteReview(String cardId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for review deletion');
        return false;
      }

      await usersCollection.doc(uid).collection('reviews').doc(cardId).delete();

      if (kDebugMode) print('✅ Review deleted for card: $cardId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting review: $e');
      return false;
    }
  }

  /// Get review statistics for analytics
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Map with review statistics
  Future<Map<String, dynamic>> getReviewStats([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for review stats');
        return {};
      }

      final reviews = await getUserReviews(uid);
      final now = DateTime.now();

      final dueCount = reviews
          .where((r) => r.dueAt.isBefore(now) || r.dueAt.isAtSameMomentAs(now))
          .length;
      final totalCards = reviews.length;
      final averageEase = reviews.isEmpty
          ? 0.0
          : reviews.map((r) => r.ease).reduce((a, b) => a + b) / reviews.length;
      final totalReps = reviews.map((r) => r.reps).fold(0, (a, b) => a + b);

      final stats = {
        'totalCards': totalCards,
        'dueCards': dueCount,
        'averageEase': averageEase,
        'totalRepetitions': totalReps,
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (kDebugMode) print('✅ Review stats calculated: $stats');
      return stats;
    } catch (e) {
      if (kDebugMode) print('❌ Error calculating review stats: $e');
      return {};
    }
  }

  // ==================== Quiz Session CRUD Operations ====================

  /// Save a quiz session to Firestore
  /// @param session - QuizSession object to save
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> saveQuizSession(QuizSession session, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for quiz session save');
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('quizSessions')
          .doc(session.id)
          .set(session.toJson(), SetOptions(merge: true));

      if (kDebugMode) print('✅ Quiz session saved: ${session.id}');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving quiz session: $e');
      return false;
    }
  }

  /// Get a specific quiz session by ID
  /// @param sessionId - ID of the quiz session
  /// @param userId - User ID (optional, uses current user if null)
  /// @return QuizSession object or null if not found
  Future<QuizSession?> getQuizSession(String sessionId,
      [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for quiz session retrieval');
        }
        return null;
      }

      final doc = await usersCollection
          .doc(uid)
          .collection('quizSessions')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return QuizSession.fromJson(doc.data()!);
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving quiz session: $e');
      return null;
    }
  }

  /// Get all quiz sessions for a user
  /// @param userId - User ID (optional, uses current user if null)
  /// @return List of QuizSession objects
  Future<List<QuizSession>> getQuizSessions([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for quiz sessions retrieval');
        }
        return [];
      }

      final querySnapshot = await usersCollection
          .doc(uid)
          .collection('quizSessions')
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => QuizSession.fromJson(doc.data()))
          .toList();

      if (kDebugMode) {
        print('✅ Retrieved ${sessions.length} quiz sessions for user: $uid');
      }
      return sessions;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving quiz sessions: $e');
      return [];
    }
  }

  /// Get quiz sessions for a specific deck
  /// @param deckId - ID of the deck
  /// @param userId - User ID (optional, uses current user if null)
  /// @return List of QuizSession objects for the deck
  Future<List<QuizSession>> getQuizSessionsForDeck(String deckId,
      [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for deck quiz sessions retrieval');
        }
        return [];
      }

      final querySnapshot = await usersCollection
          .doc(uid)
          .collection('quizSessions')
          .where('deckId', isEqualTo: deckId)
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs
          .map((doc) => QuizSession.fromJson(doc.data()))
          .toList();

      if (kDebugMode) {
        print('✅ Retrieved ${sessions.length} quiz sessions for deck: $deckId');
      }
      return sessions;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving deck quiz sessions: $e');
      return [];
    }
  }

  /// Delete a quiz session
  /// @param sessionId - ID of the session to delete
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> deleteQuizSession(String sessionId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for quiz session deletion');
        }
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('quizSessions')
          .doc(sessionId)
          .delete();

      if (kDebugMode) print('✅ Quiz session deleted: $sessionId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error deleting quiz session: $e');
      return false;
    }
  }

  // ==================== Deck Cooldown CRUD Operations ====================

  /// Save deck cooldown data to Firestore
  /// @param deckId - ID of the deck
  /// @param cooldownEnd - When the cooldown ends
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> saveDeckCooldown(String deckId, DateTime cooldownEnd,
      [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for deck cooldown save');
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('deckCooldowns')
          .doc(deckId)
          .set({
        'deckId': deckId,
        'cooldownEnd': cooldownEnd.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (kDebugMode) {
        print('✅ Deck cooldown saved: $deckId until $cooldownEnd');
      }
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error saving deck cooldown: $e');
      return false;
    }
  }

  /// Get deck cooldown data
  /// @param deckId - ID of the deck
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Cooldown end time or null if no cooldown
  Future<DateTime?> getDeckCooldown(String deckId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for deck cooldown retrieval');
        }
        return null;
      }

      final doc = await usersCollection
          .doc(uid)
          .collection('deckCooldowns')
          .doc(deckId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      final cooldownEndString = data['cooldownEnd'] as String;
      final cooldownEnd = DateTime.parse(cooldownEndString);

      // Check if cooldown has expired
      if (cooldownEnd.isBefore(DateTime.now())) {
        // Cooldown expired, delete the document
        await doc.reference.delete();
        return null;
      }

      return cooldownEnd;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving deck cooldown: $e');
      return null;
    }
  }

  /// Get all active deck cooldowns
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Map of deckId to cooldown end time
  Future<Map<String, DateTime>> getAllDeckCooldowns([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for deck cooldowns retrieval');
        }
        return {};
      }

      final now = DateTime.now();
      final querySnapshot = await usersCollection
          .doc(uid)
          .collection('deckCooldowns')
          .where('cooldownEnd', isGreaterThan: now.toIso8601String())
          .get();

      final cooldowns = <String, DateTime>{};
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final deckId = data['deckId'] as String;
        final cooldownEnd = DateTime.parse(data['cooldownEnd'] as String);
        cooldowns[deckId] = cooldownEnd;
      }

      if (kDebugMode) {
        print('✅ Retrieved ${cooldowns.length} active deck cooldowns');
      }
      return cooldowns;
    } catch (e) {
      if (kDebugMode) print('❌ Error retrieving deck cooldowns: $e');
      return {};
    }
  }

  /// Remove deck cooldown (e.g., when cooldown expires)
  /// @param deckId - ID of the deck
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> removeDeckCooldown(String deckId, [String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) {
          print('❌ No user ID provided for deck cooldown removal');
        }
        return false;
      }

      await usersCollection
          .doc(uid)
          .collection('deckCooldowns')
          .doc(deckId)
          .delete();

      if (kDebugMode) print('✅ Deck cooldown removed: $deckId');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error removing deck cooldown: $e');
      return false;
    }
  }

  /// Clear all quiz data (sessions and cooldowns) for testing/reset
  /// @param userId - User ID (optional, uses current user if null)
  /// @return Success status
  Future<bool> clearAllQuizData([String? userId]) async {
    try {
      final String uid = userId ?? _auth.currentUser?.uid ?? '';
      if (uid.isEmpty) {
        if (kDebugMode) print('❌ No user ID provided for quiz data clearing');
        return false;
      }

      final batch = _firestore.batch();

      // Delete all quiz sessions
      final sessionsSnapshot =
          await usersCollection.doc(uid).collection('quizSessions').get();
      for (final doc in sessionsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete all deck cooldowns
      final cooldownsSnapshot =
          await usersCollection.doc(uid).collection('deckCooldowns').get();
      for (final doc in cooldownsSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (kDebugMode) print('✅ All quiz data cleared for user: $uid');
      return true;
    } catch (e) {
      if (kDebugMode) print('❌ Error clearing quiz data: $e');
      return false;
    }
  }

  // ==================== AI TUTOR CHAT MANAGEMENT METHODS ====================

  /// Collection reference for chat messages
  CollectionReference get chatMessagesCollection =>
      _firestore.collection('chatMessages');

  /// Create a new chat message
  Future<String?> createChatMessage(Map<String, dynamic> messageData) async {
    try {
      final messageWithMeta = {
        ...messageData,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // 🔥 FIX: Use the message's ID instead of auto-generating one
      final messageId = messageData['id'] as String?;
      if (messageId == null) {
        if (kDebugMode) {
          print('❌ Error: Message data missing "id" field');
        }
        return null;
      }

      await chatMessagesCollection.doc(messageId).set(messageWithMeta);
      if (kDebugMode) {
        print('✅ Created chat message: $messageId');
      }
      return messageId;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating chat message: $e');
      }
      return null;
    }
  }

  /// Get chat messages for a session
  Future<List<Map<String, dynamic>>> getSessionChatMessages(
      String sessionId) async {
    try {
      final querySnapshot = await chatMessagesCollection
          .where('metadata.sessionId', isEqualTo: sessionId)
          .orderBy('timestamp', descending: false)
          .get();

      final messages = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        print(
            '✅ Retrieved ${messages.length} chat messages for session: $sessionId');
      }
      return messages;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving chat messages: $e');
      }
      return [];
    }
  }

  // ==================== TUTOR SESSION MANAGEMENT METHODS ====================

  /// Collection reference for tutor sessions
  CollectionReference get tutorSessionsCollection =>
      _firestore.collection('tutorSessions');

  /// Create a new tutor session
  Future<String?> createTutorSession(Map<String, dynamic> sessionData) async {
    try {
      final sessionWithMeta = {
        ...sessionData,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await tutorSessionsCollection.add(sessionWithMeta);
      if (kDebugMode) {
        print('✅ Created tutor session: ${docRef.id}');
      }
      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error creating tutor session: $e');
      }
      return null;
    }
  }

  /// Update an existing tutor session
  Future<bool> updateTutorSession(
      String sessionId, Map<String, dynamic> updateData) async {
    try {
      await tutorSessionsCollection.doc(sessionId).update({
        ...updateData,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) {
        print('✅ Updated tutor session: $sessionId');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating tutor session: $e');
      }
      return false;
    }
  }

  /// Get all tutor sessions for a user
  Future<List<Map<String, dynamic>>> getUserTutorSessions(String uid) async {
    try {
      final querySnapshot = await tutorSessionsCollection
          .where('userId', isEqualTo: uid)
          .orderBy('startTime', descending: true)
          .get();

      final sessions = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();

      if (kDebugMode) {
        print('✅ Retrieved ${sessions.length} tutor sessions for user: $uid');
      }
      return sessions;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving tutor sessions: $e');
      }
      return [];
    }
  }

  /// Get real-time tutor sessions stream
  Stream<QuerySnapshot> getUserTutorSessionsStream(String uid) {
    return tutorSessionsCollection
        .where('userId', isEqualTo: uid)
        .orderBy('startTime', descending: true)
        .snapshots();
  }

  // ========================================
  // Timer Management Methods
  // ========================================

  /// Collection reference for saved timers
  CollectionReference get savedTimersCollection =>
      _firestore.collection('savedTimers');

  /// Save a custom timer to Firestore
  Future<String?> saveTimer({
    required String label,
    required int hours,
    required int minutes,
    required int seconds,
    required bool includeBreakTimer,
    required int breakMinutes,
    required int cycles,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return null;
      }

      final timerData = {
        'userId': uid,
        'label': label,
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
        'includeBreakTimer': includeBreakTimer,
        'breakMinutes': breakMinutes,
        'cycles': cycles,
        'savedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await savedTimersCollection.add(timerData);

      if (kDebugMode) {
        print('✅ Timer saved successfully: ${docRef.id}');
      }

      return docRef.id;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error saving timer: $e');
      }
      return null;
    }
  }

  /// Get all saved timers for the current user
  Future<List<Map<String, dynamic>>> getSavedTimers() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return [];
      }

      final snapshot =
          await savedTimersCollection.where('userId', isEqualTo: uid).get();

      final timers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add document ID
        return data;
      }).toList();

      // Sort by savedAt in the app (descending - newest first)
      timers.sort((a, b) {
        final aTime = (a['savedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final bTime = (b['savedAt'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return bTime.compareTo(aTime);
      });

      return timers;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error retrieving saved timers: $e');
      }
      return [];
    }
  }

  /// Get real-time stream of saved timers
  Stream<QuerySnapshot> getSavedTimersStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }

    return savedTimersCollection.where('userId', isEqualTo: uid).snapshots();
  }

  /// Update an existing saved timer
  Future<bool> updateTimer({
    required String timerId,
    required String label,
    required int hours,
    required int minutes,
    required int seconds,
    required bool includeBreakTimer,
    required int breakMinutes,
    required int cycles,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return false;
      }

      await savedTimersCollection.doc(timerId).update({
        'label': label,
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
        'includeBreakTimer': includeBreakTimer,
        'breakMinutes': breakMinutes,
        'cycles': cycles,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('✅ Timer updated successfully: $timerId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error updating timer: $e');
      }
      return false;
    }
  }

  /// Delete a saved timer
  Future<bool> deleteTimer(String timerId) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        if (kDebugMode) print('❌ No authenticated user');
        return false;
      }

      await savedTimersCollection.doc(timerId).delete();

      if (kDebugMode) {
        print('✅ Timer deleted successfully: $timerId');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error deleting timer: $e');
      }
      return false;
    }
  }
}
