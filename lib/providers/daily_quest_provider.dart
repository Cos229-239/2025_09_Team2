import 'package:flutter/foundation.dart';
import '../models/daily_quest.dart';
import '../services/daily_quest_service.dart';

/// Provider for managing daily quest state and interactions
class DailyQuestProvider with ChangeNotifier {
  final DailyQuestService _questService = DailyQuestService();
  
  List<DailyQuest> _quests = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _questStats = {};
  
  // Callback for quest completion notifications
  Function(DailyQuest)? _onQuestCompleted;

  // Getters
  List<DailyQuest> get quests => _quests;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get questStats => _questStats;

  // Computed properties
  List<DailyQuest> get completedQuests => 
      _quests.where((quest) => quest.isCompleted).toList();
  
  List<DailyQuest> get pendingQuests => 
      _quests.where((quest) => !quest.isCompleted && !quest.isExpired).toList();
  
  int get totalExpToday => completedQuests.fold(0, (sum, quest) => sum + quest.expReward);
  
  double get completionRate => 
      _quests.isEmpty ? 0.0 : completedQuests.length / _quests.length;

  /// Initialize and load today's quests
  Future<void> loadTodaysQuests() async {
    _setLoading(true);
    _clearError();
    
    try {
      _quests = await _questService.getTodaysQuests();
      _questStats = await _questService.getQuestStats();
      debugPrint('Loaded ${_quests.length} daily quests');
    } catch (e) {
      _setError('Failed to load daily quests: $e');
      debugPrint('Error loading daily quests: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update quest progress
  Future<void> updateQuestProgress(String questId, int progress) async {
    try {
      await _questService.updateQuestProgress(questId, progress);
      
      // Update local state
      final questIndex = _quests.indexWhere((q) => q.id == questId);
      if (questIndex != -1) {
        final quest = _quests[questIndex];
        final wasCompleted = quest.isCompleted;
        
        _quests[questIndex] = quest.copyWith(
          currentProgress: progress,
          isCompleted: progress >= quest.targetCount,
        );
        
        // If quest was just completed, update stats and notify
        if (!wasCompleted && _quests[questIndex].isCompleted) {
          _questStats = await _questService.getQuestStats();
          
          // Generate achievement notification
          try {
            // Note: In a real implementation, we'd inject NotificationProvider
            // For now, we'll add a callback mechanism
            _onQuestCompleted?.call(_quests[questIndex]);
          } catch (e) {
            debugPrint('Error generating quest completion notification: $e');
          }
          
          // Notify completion
          debugPrint('Quest completed: ${quest.title} (+${quest.expReward} EXP)');
        }
        
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update quest progress: $e');
      debugPrint('Error updating quest progress: $e');
    }
  }

  /// Increment quest progress by 1 for a specific type
  Future<void> incrementQuestProgress(QuestType type) async {
    try {
      await _questService.incrementQuestProgress(type);
      
      // Update local state for all quests of this type
      bool anyUpdated = false;
      for (int i = 0; i < _quests.length; i++) {
        final quest = _quests[i];
        if (quest.type == type && !quest.isCompleted) {
          final newProgress = quest.currentProgress + 1;
          final wasCompleted = quest.isCompleted;
          
          _quests[i] = quest.copyWith(
            currentProgress: newProgress,
            isCompleted: newProgress >= quest.targetCount,
          );
          
          // If quest was just completed, update stats
          if (!wasCompleted && _quests[i].isCompleted) {
            _questStats = await _questService.getQuestStats();
            debugPrint('Quest auto-completed: ${quest.title} (+${quest.expReward} EXP)');
          }
          
          anyUpdated = true;
        }
      }
      
      if (anyUpdated) {
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error incrementing quest progress: $e');
    }
  }

  /// Complete a quest immediately (for achievement-style quests)
  Future<void> completeQuest(String questId) async {
    try {
      await _questService.completeQuest(questId);
      
      // Update local state
      final questIndex = _quests.indexWhere((q) => q.id == questId);
      if (questIndex != -1) {
        final quest = _quests[questIndex];
        if (!quest.isCompleted) {
          _quests[questIndex] = quest.copyWith(
            currentProgress: quest.targetCount,
            isCompleted: true,
          );
          
          _questStats = await _questService.getQuestStats();
          notifyListeners();
          
          debugPrint('Quest manually completed: ${quest.title} (+${quest.expReward} EXP)');
        }
      }
    } catch (e) {
      _setError('Failed to complete quest: $e');
      debugPrint('Error completing quest: $e');
    }
  }

  /// Get today's quest summary
  Future<Map<String, dynamic>> getTodaysSummary() async {
    try {
      return await _questService.getTodaysSummary();
    } catch (e) {
      debugPrint('Error getting today\'s summary: $e');
      return {
        'completed': 0,
        'total': 0,
        'expEarned': 0,
        'completionRate': 0.0,
      };
    }
  }

  /// Check if user has completed any quests today
  Future<bool> hasCompletedQuestsToday() async {
    try {
      return await _questService.hasCompletedQuestsToday();
    } catch (e) {
      debugPrint('Error checking quest completion: $e');
      return false;
    }
  }

  /// Refresh quests (useful for manual refresh)
  Future<void> refreshQuests() async {
    await loadTodaysQuests();
  }

  /// Reset quest data (for testing)
  Future<void> resetQuestData() async {
    try {
      await _questService.resetQuestData();
      _quests.clear();
      _questStats.clear();
      notifyListeners();
      debugPrint('Quest data reset');
    } catch (e) {
      _setError('Failed to reset quest data: $e');
      debugPrint('Error resetting quest data: $e');
    }
  }

  // Convenience methods for common quest types
  
  /// Called when user studies a card
  Future<void> onCardStudied() async {
    await incrementQuestProgress(QuestType.study);
  }

  /// Called when user takes a quiz
  Future<void> onQuizTaken() async {
    await incrementQuestProgress(QuestType.quiz);
  }

  /// Called when user gets perfect score on quiz
  Future<void> onPerfectScore() async {
    await incrementQuestProgress(QuestType.perfectScore);
  }

  /// Called when user maintains study streak
  Future<void> onStreakMaintained() async {
    await incrementQuestProgress(QuestType.streak);
  }

  // Private helper methods
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
  
  /// Set callback for quest completion notifications
  void setQuestCompletionCallback(Function(DailyQuest)? callback) {
    _onQuestCompleted = callback;
  }
}