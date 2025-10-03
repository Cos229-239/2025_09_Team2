import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity.dart';
import 'firestore_service.dart';

/// Service for tracking and managing user activities
class ActivityService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log a new activity
  Future<void> logActivity({
    required ActivityType type,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final activity = Activity(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: user.uid,
        type: type,
        description: description,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      await _firestoreService.activitiesCollection.doc(activity.id).set(activity.toJson());
      print('✅ Activity logged: ${activity.description}');
    } catch (e) {
      print('❌ Error logging activity: $e');
    }
  }

  /// Get recent activities for the current user
  Future<List<Activity>> getRecentActivities({int limit = 10}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final querySnapshot = await _firestoreService.activitiesCollection
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Activity.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting recent activities: $e');
      return [];
    }
  }

  /// Get activities for a specific user (for viewing friend's profile)
  Future<List<Activity>> getUserActivities(String userId, {int limit = 10}) async {
    try {
      final querySnapshot = await _firestoreService.activitiesCollection
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => Activity.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error getting user activities: $e');
      return [];
    }
  }

  /// Stream of recent activities
  Stream<List<Activity>> watchRecentActivities({int limit = 10}) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestoreService.activitiesCollection
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Activity.fromJson(doc.data() as Map<String, dynamic>))
            .toList());
  }

  /// Clear old activities (cleanup)
  Future<void> clearOldActivities({int daysToKeep = 30}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      final querySnapshot = await _firestoreService.activitiesCollection
          .where('userId', isEqualTo: user.uid)
          .where('timestamp', isLessThan: cutoffDate.toIso8601String())
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (var doc in querySnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      print('✅ Cleared ${querySnapshot.docs.length} old activities');
    } catch (e) {
      print('❌ Error clearing old activities: $e');
    }
  }
}
