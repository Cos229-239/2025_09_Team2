import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_quest.dart';

/// Service for managing daily quests and gamification features
class DailyQuestService {
  static const String _questsKey = 'daily_quests';
  static const String _lastQuestGenerationKey = 'last_quest_generation';
  static const String _questStatsKey = 'quest_stats';

  /// Get all active daily quests for today
  Future<List<DailyQuest>> getTodaysQuests() async {
    await _generateDailyQuestsIfNeeded();
    
    final prefs = await SharedPreferences.getInstance();
    final questsJson = prefs.getStringList(_questsKey) ?? [];
    
    final quests = questsJson
        .map((json) => DailyQuest.fromJson(jsonDecode(json)))
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
  }

  /// Update quest progress
  Future<void> updateQuestProgress(String questId, int progress) async {
    final quests = await getTodaysQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex == -1) return;
    
    final quest = quests[questIndex];
    final updatedQuest = quest.copyWith(
      currentProgress: progress,
      isCompleted: progress >= quest.targetCount,
    );
    
    quests[questIndex] = updatedQuest;
    await _saveQuests(quests);
    
    // If quest was just completed, record stats
    if (updatedQuest.isCompleted && !quest.isCompleted) {
      await _recordQuestCompletion(updatedQuest);
      debugPrint('Daily quest completed: ${updatedQuest.title} (+${updatedQuest.expReward} EXP)');
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
    final quests = await getTodaysQuests();
    final questIndex = quests.indexWhere((q) => q.id == questId);
    
    if (questIndex == -1) return;
    
    final quest = quests[questIndex];
    if (quest.isCompleted) return;
    
    final updatedQuest = quest.copyWith(
      currentProgress: quest.targetCount,
      isCompleted: true,
    );
    
    quests[questIndex] = updatedQuest;
    await _saveQuests(quests);
    await _recordQuestCompletion(updatedQuest);
    
    debugPrint('Daily quest completed: ${updatedQuest.title} (+${updatedQuest.expReward} EXP)');
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
    
    await _saveQuests(newQuests);
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
    final questsJson = quests
        .map((quest) => jsonEncode(quest.toJson()))
        .toList();
    
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