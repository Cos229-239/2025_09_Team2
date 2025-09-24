import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/daily_quest.dart';
import 'firestore_service.dart';

/// Service for managing daily quests and gamification features
class DailyQuestService {
  static const String _questsKey = 'daily_quests';
  static const String _lastQuestGenerationKey = 'last_quest_generation';
  static const String _questStatsKey = 'quest_stats';

  // Firestore service instance for database operations
  final FirestoreService _firestoreService = FirestoreService();

  // Firebase Auth instance for user authentication
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all active daily quests for today
  Future<List<DailyQuest>> getTodaysQuests() async {
    final user = _auth.currentUser;
    if (user == null) {
      return []; // Return empty list if no user logged in
    }

    await _generateDailyQuestsIfNeeded();

    try {
      // Get quests from Firestore
      final questMaps = await _firestoreService.getUserDailyQuests(user.uid);
      final quests = questMaps
          .map((questMap) => _convertFirestoreToQuest(questMap))
          .where((quest) => !quest.isExpired)
          .toList();

      // Sort by priority (high to low) then by completion status
      quests.sort((a, b) {
        if (a.isCompleted != b.isCompleted) {
          return a.isCompleted ? 1 : -1; // Incomplete quests first
        }
        return b.priority.compareTo(a.priority); // Higher priority first
      });

      return quests;
    } catch (e) {
      debugPrint('Error getting today\'s quests: $e');
      return [];
    }
  }

  /// Helper method to convert Firestore document data to DailyQuest object
  DailyQuest _convertFirestoreToQuest(Map<String, dynamic> data) {
    return DailyQuest(
      id: data['id'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      type: QuestType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => QuestType.study,
      ),
      targetCount: data['targetCount'] as int,
      currentProgress: data['currentProgress'] as int? ?? 0,
      expReward: data['expReward'] as int,
      createdAt: (data['createdAt'] as dynamic).toDate() as DateTime,
      expiresAt: (data['expiresAt'] as dynamic).toDate() as DateTime,
      isCompleted: data['isCompleted'] as bool? ?? false,
      priority: data['priority'] as int? ?? 2,
    );
  }

  /// Update quest progress
  Future<void> updateQuestProgress(String questId, int progress) async {
    try {
      final quests = await getTodaysQuests();
      final quest = quests.firstWhere((q) => q.id == questId, orElse: () => throw Exception('Quest not found'));

      final wasCompleted = quest.isCompleted;
      final isNowCompleted = progress >= quest.targetCount;

      // Update quest in Firestore
      final updateData = {
        'currentProgress': progress,
        'isCompleted': isNowCompleted,
      };

      final success = await _firestoreService.updateDailyQuest(questId, updateData);
      if (!success) {
        throw Exception('Failed to update quest in Firestore');
      }

      // If quest was just completed, record stats
      if (isNowCompleted && !wasCompleted) {
        final updatedQuest = quest.copyWith(
          currentProgress: progress,
          isCompleted: isNowCompleted,
        );
        await _recordQuestCompletion(updatedQuest);
        debugPrint(
            'Daily quest completed: ${updatedQuest.title} (+${updatedQuest.expReward} EXP)');
      }
    } catch (e) {
      debugPrint('Error updating quest progress: $e');
    }
  }

  /// Increment quest progress by 1
  Future<void> incrementQuestProgress(QuestType type) async {
    final quests = await getTodaysQuests();

    for (final quest in quests) {
      if (quest.type == type && !quest.isCompleted) {
        await updateQuestProgress(quest.id, quest.currentProgress + 1);
      }
    }
  }

  /// Mark a quest as completed (for achievement-style quests)
  Future<void> completeQuest(String questId) async {
    try {
      final quests = await getTodaysQuests();
      final quest = quests.firstWhere((q) => q.id == questId, orElse: () => throw Exception('Quest not found'));

      if (quest.isCompleted) return;

      // Update quest in Firestore
      final updateData = {
        'currentProgress': quest.targetCount,
        'isCompleted': true,
      };

      final success = await _firestoreService.updateDailyQuest(questId, updateData);
      if (!success) {
        throw Exception('Failed to complete quest in Firestore');
      }

      final updatedQuest = quest.copyWith(
        currentProgress: quest.targetCount,
        isCompleted: true,
      );

      await _recordQuestCompletion(updatedQuest);

      debugPrint(
          'Daily quest completed: ${updatedQuest.title} (+${updatedQuest.expReward} EXP)');
    } catch (e) {
      debugPrint('Error completing quest: $e');
    }
  }

  /// Get total EXP earned from completed quests today
  Future<int> getTodaysQuestEXP() async {
    final quests = await getTodaysQuests();
    int totalExp = 0;
    for (final quest in quests) {
      if (quest.isCompleted) {
        totalExp += quest.expReward;
      }
    }
    return totalExp;
  }

  /// Get quest completion stats
  Future<Map<String, dynamic>> getQuestStats() async {
    final prefs = await SharedPreferences.getInstance();
    final statsJson = prefs.getString(_questStatsKey);

    if (statsJson == null) {
      return {
        'totalCompleted': 0,
        'totalEXPEarned': 0,
        'streakDays': 0,
        'lastCompletionDate': null,
      };
    }

    return jsonDecode(statsJson);
  }

  /// Generate daily quests if needed (once per day)
  Future<void> _generateDailyQuestsIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    final lastGeneration = prefs.getString(_lastQuestGenerationKey);
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastGeneration == todayString) {
      return; // Already generated today
    }

    // Clear expired quests and generate new ones
    await _clearExpiredQuests();
    await _generateNewQuests();
    await prefs.setString(_lastQuestGenerationKey, todayString);

    debugPrint('Generated new daily quests for $todayString');
  }

  /// Generate new daily quests for today
  Future<void> _generateNewQuests() async {
    final random = Random();
    final now = DateTime.now();
    final baseId = now.millisecondsSinceEpoch.toString();

    final newQuests = <DailyQuest>[
      // Always include a study quest
      DailyQuest.studyCards(
        id: '${baseId}_study',
        targetCards: 5 + random.nextInt(11), // 5-15 cards
        expReward: 50 + random.nextInt(51), // 50-100 EXP
      ),

      // Always include a quiz quest
      DailyQuest.takeQuizzes(
        id: '${baseId}_quiz',
        targetQuizzes: 2 + random.nextInt(3), // 2-4 quizzes
        expReward: 75 + random.nextInt(76), // 75-150 EXP
      ),

      // Always include a streak quest
      DailyQuest.maintainStreak(
        id: '${baseId}_streak',
        expReward: 100,
      ),
    ];

    // Randomly add bonus quests
    final bonusQuests = [
      () => DailyQuest.perfectScore(
            id: '${baseId}_perfect',
            expReward: 150 + random.nextInt(101), // 150-250 EXP
          ),
    ];

    // 60% chance to add a bonus quest
    if (random.nextDouble() < 0.6 && bonusQuests.isNotEmpty) {
      final bonusQuest = bonusQuests[random.nextInt(bonusQuests.length)]();
      newQuests.add(bonusQuest);
    }

    // Save each quest to Firestore
    final user = _auth.currentUser;
    if (user != null) {
      for (final quest in newQuests) {
        final questData = quest.toJson();
        questData.remove('id'); // Remove ID as Firestore will generate it
        await _firestoreService.createDailyQuest(user.uid, questData);
      }
    }
  }

  /// Clear expired quests
  Future<void> _clearExpiredQuests() async {
    final prefs = await SharedPreferences.getInstance();
    final questsJson = prefs.getStringList(_questsKey) ?? [];

    final activeQuests = questsJson
        .map((json) => DailyQuest.fromJson(jsonDecode(json)))
        .where((quest) => !quest.isExpired)
        .toList();

    await _saveQuests(activeQuests);
  }

  /// Save quests to storage
  Future<void> _saveQuests(List<DailyQuest> quests) async {
    final prefs = await SharedPreferences.getInstance();
    final questsJson =
        quests.map((quest) => jsonEncode(quest.toJson())).toList();

    await prefs.setStringList(_questsKey, questsJson);
  }

  /// Record quest completion for stats
  Future<void> _recordQuestCompletion(DailyQuest quest) async {
    final stats = await getQuestStats();
    final prefs = await SharedPreferences.getInstance();

    stats['totalCompleted'] = (stats['totalCompleted'] ?? 0) + 1;
    stats['totalEXPEarned'] = (stats['totalEXPEarned'] ?? 0) + quest.expReward;

    // Update streak
    final lastCompletionDate = stats['lastCompletionDate'];
    final today = DateTime.now();
    final todayString = '${today.year}-${today.month}-${today.day}';

    if (lastCompletionDate == null) {
      stats['streakDays'] = 1;
    } else {
      final lastDate = DateTime.parse(lastCompletionDate);
      final daysDifference = today.difference(lastDate).inDays;

      if (daysDifference == 1) {
        // Consecutive day
        stats['streakDays'] = (stats['streakDays'] ?? 0) + 1;
      } else if (daysDifference > 1) {
        // Streak broken
        stats['streakDays'] = 1;
      }
      // Same day doesn't change streak
    }

    stats['lastCompletionDate'] = todayString;

    await prefs.setString(_questStatsKey, jsonEncode(stats));
  }

  /// Reset all quest data (for testing purposes)
  Future<void> resetQuestData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_questsKey);
    await prefs.remove(_lastQuestGenerationKey);
    await prefs.remove(_questStatsKey);
    debugPrint('Quest data reset');
  }

  /// Check if user has completed any quests today
  Future<bool> hasCompletedQuestsToday() async {
    final quests = await getTodaysQuests();
    return quests.any((quest) => quest.isCompleted);
  }

  /// Get completion summary for today
  Future<Map<String, dynamic>> getTodaysSummary() async {
    final quests = await getTodaysQuests();
    final completed = quests.where((q) => q.isCompleted).length;
    final total = quests.length;
    final expEarned = await getTodaysQuestEXP();

    return {
      'completed': completed,
      'total': total,
      'expEarned': expEarned,
      'completionRate': total > 0 ? completed / total : 0.0,
    };
  }
}
