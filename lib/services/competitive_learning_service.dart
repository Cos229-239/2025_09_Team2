import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents different types of competitions
enum CompetitionType {
  daily,
  weekly,
  monthly,
  challenge,
  tournament,
}

/// Represents competition categories
enum CompetitionCategory {
  studyTime,
  accuracy,
  streaks,
  xpGained,
  sessionsCompleted,
  questionsAnswered,
  subjectMastery,
  overallProgress,
}

/// Represents leaderboard time periods
enum LeaderboardPeriod {
  daily,
  weekly,
  monthly,
  allTime,
}

/// Represents a user's ranking entry
class LeaderboardEntry {
  final String userId;
  final String username;
  final String displayName;
  final String? avatar;
  final double score;
  final int rank;
  final CompetitionCategory category;
  final LeaderboardPeriod period;
  final DateTime lastUpdated;
  final Map<String, dynamic> metadata;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatar,
    required this.score,
    required this.rank,
    required this.category,
    required this.period,
    required this.lastUpdated,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'username': username,
    'displayName': displayName,
    'avatar': avatar,
    'score': score,
    'rank': rank,
    'category': category.name,
    'period': period.name,
    'lastUpdated': lastUpdated.toIso8601String(),
    'metadata': metadata,
  };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    userId: json['userId'],
    username: json['username'],
    displayName: json['displayName'],
    avatar: json['avatar'],
    score: json['score'].toDouble(),
    rank: json['rank'],
    category: CompetitionCategory.values.firstWhere((e) => e.name == json['category']),
    period: LeaderboardPeriod.values.firstWhere((e) => e.name == json['period']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
    metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
  );
}

/// Represents a competition or challenge
class Competition {
  final String id;
  final String name;
  final String description;
  final CompetitionType type;
  final CompetitionCategory category;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> rules;
  final List<CompetitionReward> rewards;
  final int maxParticipants;
  final List<String> participants;
  final bool isActive;
  final bool requiresInvitation;
  final String? createdBy;

  Competition({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.category,
    required this.startDate,
    required this.endDate,
    Map<String, dynamic>? rules,
    List<CompetitionReward>? rewards,
    this.maxParticipants = 100,
    List<String>? participants,
    this.isActive = false,
    this.requiresInvitation = false,
    this.createdBy,
  }) : rules = rules ?? {},
       rewards = rewards ?? [],
       participants = participants ?? [];

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type.name,
    'category': category.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'rules': rules,
    'rewards': rewards.map((r) => r.toJson()).toList(),
    'maxParticipants': maxParticipants,
    'participants': participants,
    'isActive': isActive,
    'requiresInvitation': requiresInvitation,
    'createdBy': createdBy,
  };

  factory Competition.fromJson(Map<String, dynamic> json) => Competition(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    type: CompetitionType.values.firstWhere((e) => e.name == json['type']),
    category: CompetitionCategory.values.firstWhere((e) => e.name == json['category']),
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    rules: Map<String, dynamic>.from(json['rules'] ?? {}),
    rewards: (json['rewards'] as List?)?.map((r) => CompetitionReward.fromJson(r)).toList() ?? [],
    maxParticipants: json['maxParticipants'] ?? 100,
    participants: List<String>.from(json['participants'] ?? []),
    isActive: json['isActive'] ?? false,
    requiresInvitation: json['requiresInvitation'] ?? false,
    createdBy: json['createdBy'],
  );
}

/// Represents a reward for competition winners
class CompetitionReward {
  final String id;
  final String name;
  final String description;
  final String type; // xp, badge, title, etc.
  final dynamic value;
  final int minRank;
  final int maxRank;

  CompetitionReward({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    required this.minRank,
    required this.maxRank,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'type': type,
    'value': value,
    'minRank': minRank,
    'maxRank': maxRank,
  };

  factory CompetitionReward.fromJson(Map<String, dynamic> json) => CompetitionReward(
    id: json['id'],
    name: json['name'],
    description: json['description'],
    type: json['type'],
    value: json['value'],
    minRank: json['minRank'],
    maxRank: json['maxRank'],
  );
}

/// Represents a peer comparison
class PeerComparison {
  final String userId;
  final String friendId;
  final CompetitionCategory category;
  final double userScore;
  final double friendScore;
  final double difference;
  final bool userIsAhead;
  final LeaderboardPeriod period;
  final DateTime lastUpdated;

  PeerComparison({
    required this.userId,
    required this.friendId,
    required this.category,
    required this.userScore,
    required this.friendScore,
    required this.difference,
    required this.userIsAhead,
    required this.period,
    required this.lastUpdated,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'friendId': friendId,
    'category': category.name,
    'userScore': userScore,
    'friendScore': friendScore,
    'difference': difference,
    'userIsAhead': userIsAhead,
    'period': period.name,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory PeerComparison.fromJson(Map<String, dynamic> json) => PeerComparison(
    userId: json['userId'],
    friendId: json['friendId'],
    category: CompetitionCategory.values.firstWhere((e) => e.name == json['category']),
    userScore: json['userScore'].toDouble(),
    friendScore: json['friendScore'].toDouble(),
    difference: json['difference'].toDouble(),
    userIsAhead: json['userIsAhead'],
    period: LeaderboardPeriod.values.firstWhere((e) => e.name == json['period']),
    lastUpdated: DateTime.parse(json['lastUpdated']),
  );
}

/// Represents user's competitive statistics
class CompetitiveStats {
  final String userId;
  final Map<CompetitionCategory, double> categoryScores;
  final Map<LeaderboardPeriod, Map<CompetitionCategory, int>> rankings;
  final int competitionsWon;
  final int competitionsParticipated;
  final double winRate;
  final List<String> achievements;
  final DateTime lastUpdated;

  CompetitiveStats({
    required this.userId,
    Map<CompetitionCategory, double>? categoryScores,
    Map<LeaderboardPeriod, Map<CompetitionCategory, int>>? rankings,
    this.competitionsWon = 0,
    this.competitionsParticipated = 0,
    this.winRate = 0.0,
    List<String>? achievements,
    required this.lastUpdated,
  }) : categoryScores = categoryScores ?? {},
       rankings = rankings ?? {},
       achievements = achievements ?? [];

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'categoryScores': categoryScores.map((key, value) => MapEntry(key.name, value)),
    'rankings': rankings.map((periodKey, periodValue) => MapEntry(
      periodKey.name, 
      periodValue.map((catKey, catValue) => MapEntry(catKey.name, catValue))
    )),
    'competitionsWon': competitionsWon,
    'competitionsParticipated': competitionsParticipated,
    'winRate': winRate,
    'achievements': achievements,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory CompetitiveStats.fromJson(Map<String, dynamic> json) {
    final categoryScores = <CompetitionCategory, double>{};
    final categoryScoresJson = json['categoryScores'] as Map<String, dynamic>? ?? {};
    for (final entry in categoryScoresJson.entries) {
      try {
        final category = CompetitionCategory.values.firstWhere((e) => e.name == entry.key);
        categoryScores[category] = entry.value.toDouble();
      } catch (e) {
        // Skip invalid categories
      }
    }

    final rankings = <LeaderboardPeriod, Map<CompetitionCategory, int>>{};
    final rankingsJson = json['rankings'] as Map<String, dynamic>? ?? {};
    for (final periodEntry in rankingsJson.entries) {
      try {
        final period = LeaderboardPeriod.values.firstWhere((e) => e.name == periodEntry.key);
        final categoryRankings = <CompetitionCategory, int>{};
        final categoryRankingsJson = periodEntry.value as Map<String, dynamic>? ?? {};
        for (final catEntry in categoryRankingsJson.entries) {
          try {
            final category = CompetitionCategory.values.firstWhere((e) => e.name == catEntry.key);
            categoryRankings[category] = catEntry.value;
          } catch (e) {
            // Skip invalid categories
          }
        }
        rankings[period] = categoryRankings;
      } catch (e) {
        // Skip invalid periods
      }
    }

    return CompetitiveStats(
      userId: json['userId'],
      categoryScores: categoryScores,
      rankings: rankings,
      competitionsWon: json['competitionsWon'] ?? 0,
      competitionsParticipated: json['competitionsParticipated'] ?? 0,
      winRate: json['winRate']?.toDouble() ?? 0.0,
      achievements: List<String>.from(json['achievements'] ?? []),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }
}

/// Service for managing competitive learning features
class CompetitiveLearningService {
  static const String _leaderboardsKey = 'leaderboards';
  static const String _competitionsKey = 'competitions';
  static const String _competitiveStatsKey = 'competitive_stats';
  static const String _peerComparisonsKey = 'peer_comparisons';

  SharedPreferences? _prefs;
  Map<String, List<LeaderboardEntry>> _leaderboards = {};
  List<Competition> _competitions = [];
  CompetitiveStats? _userStats;
  List<PeerComparison> _peerComparisons = [];

  /// Initialize the service
  Future<void> initialize(String userId) async {
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    await _initializeDefaultData(userId);
  }

  /// Load data from storage
  Future<void> _loadData() async {
    try {
      // Load leaderboards
      final leaderboardsData = _prefs?.getString(_leaderboardsKey);
      if (leaderboardsData != null) {
        final Map<String, dynamic> leaderboardsMap = jsonDecode(leaderboardsData);
        _leaderboards = leaderboardsMap.map((key, value) => MapEntry(
          key,
          (value as List).map((e) => LeaderboardEntry.fromJson(e)).toList()
        ));
      }

      // Load competitions
      final competitionsData = _prefs?.getString(_competitionsKey);
      if (competitionsData != null) {
        final List<dynamic> competitionsList = jsonDecode(competitionsData);
        _competitions = competitionsList.map((c) => Competition.fromJson(c)).toList();
      }

      // Load competitive stats
      final statsData = _prefs?.getString(_competitiveStatsKey);
      if (statsData != null) {
        _userStats = CompetitiveStats.fromJson(jsonDecode(statsData));
      }

      // Load peer comparisons
      final comparisonsData = _prefs?.getString(_peerComparisonsKey);
      if (comparisonsData != null) {
        final List<dynamic> comparisonsList = jsonDecode(comparisonsData);
        _peerComparisons = comparisonsList.map((c) => PeerComparison.fromJson(c)).toList();
      }
    } catch (e) {
      debugPrint('Error loading competitive learning data: $e');
    }
  }

  /// Save data to storage
  Future<void> _saveData() async {
    try {
      // Save leaderboards
      final leaderboardsMap = _leaderboards.map((key, value) => MapEntry(
        key,
        value.map((e) => e.toJson()).toList()
      ));
      await _prefs?.setString(_leaderboardsKey, jsonEncode(leaderboardsMap));

      // Save competitions
      final competitionsList = _competitions.map((c) => c.toJson()).toList();
      await _prefs?.setString(_competitionsKey, jsonEncode(competitionsList));

      // Save competitive stats
      if (_userStats != null) {
        await _prefs?.setString(_competitiveStatsKey, jsonEncode(_userStats!.toJson()));
      }

      // Save peer comparisons
      final comparisonsList = _peerComparisons.map((c) => c.toJson()).toList();
      await _prefs?.setString(_peerComparisonsKey, jsonEncode(comparisonsList));
    } catch (e) {
      debugPrint('Error saving competitive learning data: $e');
    }
  }

  /// Initialize default data
  Future<void> _initializeDefaultData(String userId) async {
    // Initialize user stats if not exists
    _userStats ??= CompetitiveStats(
      userId: userId,
      lastUpdated: DateTime.now(),
    );

    // Initialize default leaderboards if empty
    if (_leaderboards.isEmpty) {
      await _initializeDefaultLeaderboards();
    }

    // Initialize default competitions if empty
    if (_competitions.isEmpty) {
      await _initializeDefaultCompetitions();
    }

    await _saveData();
  }

  /// Initialize default leaderboards with mock data
  Future<void> _initializeDefaultLeaderboards() async {
    const categories = CompetitionCategory.values;
    const periods = LeaderboardPeriod.values;

    for (final period in periods) {
      for (final category in categories) {
        final key = '${period.name}_${category.name}';
        _leaderboards[key] = _generateMockLeaderboard(category, period);
      }
    }
  }

  /// Generate mock leaderboard data
  List<LeaderboardEntry> _generateMockLeaderboard(
    CompetitionCategory category,
    LeaderboardPeriod period,
  ) {
    final random = Random();
    final entries = <LeaderboardEntry>[];

    for (int i = 0; i < 50; i++) {
      final score = _generateScoreForCategory(category, random);
      final userId = 'user_${i + 1}';
      
      entries.add(LeaderboardEntry(
        userId: userId,
        username: 'user$i',
        displayName: 'User ${i + 1}',
        score: score,
        rank: i + 1,
        category: category,
        period: period,
        lastUpdated: DateTime.now().subtract(Duration(hours: random.nextInt(24))),
        metadata: {
          'level': 5 + random.nextInt(45),
          'streak': random.nextInt(30),
        },
      ));
    }

    // Sort by score descending
    entries.sort((a, b) => b.score.compareTo(a.score));
    
    // Update ranks
    for (int i = 0; i < entries.length; i++) {
      entries[i] = LeaderboardEntry(
        userId: entries[i].userId,
        username: entries[i].username,
        displayName: entries[i].displayName,
        avatar: entries[i].avatar,
        score: entries[i].score,
        rank: i + 1,
        category: entries[i].category,
        period: entries[i].period,
        lastUpdated: entries[i].lastUpdated,
        metadata: entries[i].metadata,
      );
    }

    return entries;
  }

  /// Generate appropriate score for category
  double _generateScoreForCategory(CompetitionCategory category, Random random) {
    switch (category) {
      case CompetitionCategory.studyTime:
        return 60 + random.nextDouble() * 300; // 1-6 hours in minutes
      case CompetitionCategory.accuracy:
        return 0.5 + random.nextDouble() * 0.5; // 50-100%
      case CompetitionCategory.streaks:
        return random.nextInt(100).toDouble(); // 0-100 days
      case CompetitionCategory.xpGained:
        return 100 + random.nextInt(9900).toDouble(); // 100-10000 XP
      case CompetitionCategory.sessionsCompleted:
        return random.nextInt(50).toDouble(); // 0-50 sessions
      case CompetitionCategory.questionsAnswered:
        return random.nextInt(1000).toDouble(); // 0-1000 questions
      case CompetitionCategory.subjectMastery:
        return random.nextInt(10).toDouble(); // 0-10 subjects
      case CompetitionCategory.overallProgress:
        return random.nextDouble() * 100; // 0-100%
    }
  }

  /// Initialize default competitions
  Future<void> _initializeDefaultCompetitions() async {
    final now = DateTime.now();
    
    // Daily XP Challenge
    _competitions.add(Competition(
      id: 'daily_xp_${now.day}',
      name: 'Daily XP Challenge',
      description: 'Earn the most XP today!',
      type: CompetitionType.daily,
      category: CompetitionCategory.xpGained,
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
      isActive: true,
      rewards: [
        CompetitionReward(
          id: 'daily_xp_1st',
          name: 'XP Master Badge',
          description: 'Top XP earner of the day',
          type: 'badge',
          value: 'xp_master_daily',
          minRank: 1,
          maxRank: 1,
        ),
        CompetitionReward(
          id: 'daily_xp_top3',
          name: 'XP Bonus',
          description: 'Bonus XP for top 3',
          type: 'xp',
          value: 100,
          minRank: 1,
          maxRank: 3,
        ),
      ],
    ));

    // Weekly Study Time Challenge
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    _competitions.add(Competition(
      id: 'weekly_time_${weekStart.millisecondsSinceEpoch}',
      name: 'Weekly Study Marathon',
      description: 'Study the most minutes this week!',
      type: CompetitionType.weekly,
      category: CompetitionCategory.studyTime,
      startDate: weekStart,
      endDate: weekStart.add(const Duration(days: 7)),
      isActive: true,
      rewards: [
        CompetitionReward(
          id: 'weekly_time_1st',
          name: 'Study Champion',
          description: 'Weekly study time champion',
          type: 'title',
          value: 'Study Champion',
          minRank: 1,
          maxRank: 1,
        ),
      ],
    ));

    // Monthly Accuracy Challenge
    final monthStart = DateTime(now.year, now.month, 1);
    _competitions.add(Competition(
      id: 'monthly_accuracy_${now.month}_${now.year}',
      name: 'Monthly Precision Master',
      description: 'Achieve the highest accuracy this month!',
      type: CompetitionType.monthly,
      category: CompetitionCategory.accuracy,
      startDate: monthStart,
      endDate: DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1)),
      isActive: true,
      rewards: [
        CompetitionReward(
          id: 'monthly_accuracy_1st',
          name: 'Precision Master',
          description: 'Monthly accuracy champion',
          type: 'badge',
          value: 'precision_master',
          minRank: 1,
          maxRank: 1,
        ),
      ],
    ));
  }

  /// Update user performance and recalculate rankings
  Future<void> updateUserPerformance({
    required String userId,
    required String username,
    required String displayName,
    String? avatar,
    required Map<CompetitionCategory, double> categoryScores,
  }) async {
    final now = DateTime.now();

    // Update user stats
    _userStats = CompetitiveStats(
      userId: userId,
      categoryScores: categoryScores,
      rankings: _userStats?.rankings ?? {},
      competitionsWon: _userStats?.competitionsWon ?? 0,
      competitionsParticipated: _userStats?.competitionsParticipated ?? 0,
      winRate: _userStats?.winRate ?? 0.0,
      achievements: _userStats?.achievements ?? [],
      lastUpdated: now,
    );

    // Update leaderboards
    for (final period in LeaderboardPeriod.values) {
      for (final category in categoryScores.keys) {
        await _updateLeaderboard(
          userId: userId,
          username: username,
          displayName: displayName,
          avatar: avatar,
          category: category,
          period: period,
          score: categoryScores[category]!,
        );
      }
    }

    await _saveData();
  }

  /// Update specific leaderboard
  Future<void> _updateLeaderboard({
    required String userId,
    required String username,
    required String displayName,
    String? avatar,
    required CompetitionCategory category,
    required LeaderboardPeriod period,
    required double score,
  }) async {
    final key = '${period.name}_${category.name}';
    final leaderboard = _leaderboards[key] ?? [];

    // Remove existing entry for this user
    leaderboard.removeWhere((entry) => entry.userId == userId);

    // Add new entry
    leaderboard.add(LeaderboardEntry(
      userId: userId,
      username: username,
      displayName: displayName,
      avatar: avatar,
      score: score,
      rank: 0, // Will be calculated after sorting
      category: category,
      period: period,
      lastUpdated: DateTime.now(),
    ));

    // Sort by score descending
    leaderboard.sort((a, b) => b.score.compareTo(a.score));

    // Update ranks
    for (int i = 0; i < leaderboard.length; i++) {
      final entry = leaderboard[i];
      leaderboard[i] = LeaderboardEntry(
        userId: entry.userId,
        username: entry.username,
        displayName: entry.displayName,
        avatar: entry.avatar,
        score: entry.score,
        rank: i + 1,
        category: entry.category,
        period: entry.period,
        lastUpdated: entry.lastUpdated,
        metadata: entry.metadata,
      );
    }

    _leaderboards[key] = leaderboard;
  }

  /// Get leaderboard for category and period
  List<LeaderboardEntry> getLeaderboard({
    required CompetitionCategory category,
    required LeaderboardPeriod period,
    int limit = 100,
  }) {
    final key = '${period.name}_${category.name}';
    final leaderboard = _leaderboards[key] ?? [];
    return leaderboard.take(limit).toList();
  }

  /// Get user's rank in a specific category and period
  int? getUserRank({
    required String userId,
    required CompetitionCategory category,
    required LeaderboardPeriod period,
  }) {
    final key = '${period.name}_${category.name}';
    final leaderboard = _leaderboards[key] ?? [];
    final entry = leaderboard.firstWhere(
      (e) => e.userId == userId,
      orElse: () => LeaderboardEntry(
        userId: '',
        username: '',
        displayName: '',
        score: 0,
        rank: -1,
        category: category,
        period: period,
        lastUpdated: DateTime.now(),
      ),
    );
    return entry.rank > 0 ? entry.rank : null;
  }

  /// Get active competitions
  List<Competition> getActiveCompetitions() {
    final now = DateTime.now();
    return _competitions.where((comp) => 
      comp.isActive && 
      comp.startDate.isBefore(now) && 
      comp.endDate.isAfter(now)
    ).toList();
  }

  /// Get upcoming competitions
  List<Competition> getUpcomingCompetitions() {
    final now = DateTime.now();
    return _competitions.where((comp) => 
      comp.startDate.isAfter(now)
    ).toList();
  }

  /// Join competition
  Future<bool> joinCompetition(String competitionId, String userId) async {
    final compIndex = _competitions.indexWhere((c) => c.id == competitionId);
    if (compIndex == -1) return false;

    final comp = _competitions[compIndex];
    if (comp.participants.contains(userId)) return false; // Already joined
    if (comp.participants.length >= comp.maxParticipants) return false; // Full

    final updatedParticipants = [...comp.participants, userId];
    _competitions[compIndex] = Competition(
      id: comp.id,
      name: comp.name,
      description: comp.description,
      type: comp.type,
      category: comp.category,
      startDate: comp.startDate,
      endDate: comp.endDate,
      rules: comp.rules,
      rewards: comp.rewards,
      maxParticipants: comp.maxParticipants,
      participants: updatedParticipants,
      isActive: comp.isActive,
      requiresInvitation: comp.requiresInvitation,
      createdBy: comp.createdBy,
    );

    await _saveData();
    return true;
  }

  /// Generate peer comparisons with friends
  Future<void> generatePeerComparisons({
    required String userId,
    required List<String> friendIds,
    required Map<CompetitionCategory, double> userScores,
  }) async {
    _peerComparisons.clear();

    for (final friendId in friendIds) {
      // In a real app, you'd fetch friend's actual scores
      // For now, we'll generate mock scores
      final friendScores = _generateMockFriendScores();

      for (final category in CompetitionCategory.values) {
        final userScore = userScores[category] ?? 0.0;
        final friendScore = friendScores[category] ?? 0.0;
        final difference = (userScore - friendScore).abs();
        final userIsAhead = userScore > friendScore;

        _peerComparisons.add(PeerComparison(
          userId: userId,
          friendId: friendId,
          category: category,
          userScore: userScore,
          friendScore: friendScore,
          difference: difference,
          userIsAhead: userIsAhead,
          period: LeaderboardPeriod.weekly,
          lastUpdated: DateTime.now(),
        ));
      }
    }

    await _saveData();
  }

  /// Generate mock friend scores
  Map<CompetitionCategory, double> _generateMockFriendScores() {
    final random = Random();
    final scores = <CompetitionCategory, double>{};
    
    for (final category in CompetitionCategory.values) {
      scores[category] = _generateScoreForCategory(category, random);
    }
    
    return scores;
  }

  /// Get peer comparisons for user
  List<PeerComparison> getPeerComparisons(String userId) {
    return _peerComparisons.where((c) => c.userId == userId).toList();
  }

  /// Get competitive stats
  CompetitiveStats? get userCompetitiveStats => _userStats;

  /// Get all competitions
  List<Competition> get allCompetitions => List.from(_competitions);

  /// Get leaderboard summary for user
  Map<String, dynamic> getLeaderboardSummary(String userId) {
    final summary = <String, dynamic>{};
    
    for (final period in LeaderboardPeriod.values) {
      final periodData = <String, dynamic>{};
      
      for (final category in CompetitionCategory.values) {
        final rank = getUserRank(
          userId: userId,
          category: category,
          period: period,
        );
        periodData[category.name] = rank;
      }
      
      summary[period.name] = periodData;
    }
    
    return summary;
  }

  /// Get competitive overview
  Map<String, dynamic> getCompetitiveOverview(String userId) {
    final activeComps = getActiveCompetitions();
    final upcomingComps = getUpcomingCompetitions();
    final userComparisons = getPeerComparisons(userId);
    
    return {
      'activeCompetitions': activeComps.length,
      'upcomingCompetitions': upcomingComps.length,
      'peerComparisons': userComparisons.length,
      'competitionsWon': _userStats?.competitionsWon ?? 0,
      'competitionsParticipated': _userStats?.competitionsParticipated ?? 0,
      'winRate': _userStats?.winRate ?? 0.0,
      'bestRanks': _getBestRanks(userId),
    };
  }

  /// Get user's best ranks across all categories
  Map<String, int> _getBestRanks(String userId) {
    final bestRanks = <String, int>{};
    
    for (final category in CompetitionCategory.values) {
      int? bestRank;
      
      for (final period in LeaderboardPeriod.values) {
        final rank = getUserRank(
          userId: userId,
          category: category,
          period: period,
        );
        
        if (rank != null && (bestRank == null || rank < bestRank)) {
          bestRank = rank;
        }
      }
      
      if (bestRank != null) {
        bestRanks[category.name] = bestRank;
      }
    }
    
    return bestRanks;
  }
}