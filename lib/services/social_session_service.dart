import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

import '../models/social_session.dart';

// TODO: FIRESTORE INTEGRATION NEEDED - Social sessions using SharedPreferences instead of Firestore
// import 'package:firebase_auth/firebase_auth.dart';
// import 'firestore_service.dart';

/// Service for managing social study sessions
class SocialSessionService extends ChangeNotifier {
  static const String _sessionsKey = 'social_sessions';
  static const String _invitationsKey = 'session_invitations';
  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';

  // Cache for sessions
  final Map<String, SocialSession> _sessions = {};
  final Map<String, SessionInvitation> _invitations = {};

  // Current user info (in a real app, this would come from auth service)
  String _currentUserId = 'user_123';
  String _currentUserName = 'Current User';

  // Mock friends data (in a real app, this would come from a friends service)
  final Map<String, String> _mockFriends = {
    'friend_1': 'Alice Johnson',
    'friend_2': 'Bob Smith',
    'friend_3': 'Carol Davis',
    'friend_4': 'David Wilson',
    'friend_5': 'Emma Brown',
  };

  /// Initialize the service
  Future<void> initialize() async {
    await _loadUserInfo();
    await _loadSessions();
    await _loadInvitations();
    _cleanupExpiredSessions();
    debugPrint('SocialSessionService initialized');
  }

  /// Get current user ID
  String get currentUserId => _currentUserId;

  /// Get current user name
  String get currentUserName => _currentUserName;

  /// Get all sessions
  List<SocialSession> get allSessions => _sessions.values.toList();

  /// Get sessions hosted by current user
  List<SocialSession> get hostedSessions =>
      _sessions.values.where((s) => s.hostId == _currentUserId).toList();

  /// Get sessions where current user is a participant
  List<SocialSession> get joinedSessions => _sessions.values
      .where((s) =>
          s.participantIds.contains(_currentUserId) &&
          s.hostId != _currentUserId)
      .toList();

  /// Get upcoming sessions
  List<SocialSession> get upcomingSessions {
    final now = DateTime.now();
    return _sessions.values
        .where((s) =>
            s.status == SessionStatus.scheduled && s.scheduledTime.isAfter(now))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get live sessions
  List<SocialSession> get liveSessions =>
      _sessions.values.where((s) => s.status == SessionStatus.live).toList();

  /// Get completed sessions
  List<SocialSession> get completedSessions => _sessions.values
      .where((s) => s.status == SessionStatus.completed)
      .toList();

  /// Get sessions that can be joined
  List<SocialSession> get joinableSessions => _sessions.values
      .where((s) =>
          s.canJoin &&
          s.hostId != _currentUserId &&
          !s.participantIds.contains(_currentUserId))
      .toList();

  /// Get pending invitations for current user
  List<SessionInvitation> get pendingInvitations => _invitations.values
      .where((i) =>
          i.toUserId == _currentUserId && i.status == InvitationStatus.pending)
      .toList();

  /// Get sent invitations from current user
  List<SessionInvitation> get sentInvitations =>
      _invitations.values.where((i) => i.fromUserId == _currentUserId).toList();

  /// Get mock friends list
  Map<String, String> get friends => Map.unmodifiable(_mockFriends);

  /// Schedule a new study session
  Future<SocialSession> scheduleSession({
    required String title,
    required String description,
    required DateTime scheduledTime,
    required Duration duration,
    required List<String> deckIds,
    required SessionType type,
    required List<String> invitedFriendIds,
    int maxParticipants = 10,
    bool isPublic = false,
  }) async {
    final sessionId = _generateSessionId();

    final session = SocialSession(
      id: sessionId,
      hostId: _currentUserId,
      hostName: _currentUserName,
      title: title,
      description: description,
      scheduledTime: scheduledTime,
      duration: duration,
      deckIds: deckIds,
      type: type,
      status: SessionStatus.scheduled,
      participantIds: [_currentUserId], // Host auto-joins
      participantNames: {_currentUserId: _currentUserName},
      maxParticipants: maxParticipants,
      createdAt: DateTime.now(),
      isPublic: isPublic,
    );

    // Save session
    _sessions[sessionId] = session;
    await _saveSessions();

    // Send invitations
    await _sendInvitations(session, invitedFriendIds);

    notifyListeners();
    debugPrint(
        'Session scheduled: ${session.title} for ${session.scheduledTime}');
    return session;
  }

  /// Send invitations to friends
  Future<void> _sendInvitations(
      SocialSession session, List<String> friendIds) async {
    for (final friendId in friendIds) {
      final friendName = _mockFriends[friendId] ?? 'Unknown Friend';

      final invitation = SessionInvitation(
        id: _generateInvitationId(),
        sessionId: session.id,
        fromUserId: _currentUserId,
        fromUserName: _currentUserName,
        toUserId: friendId,
        toUserName: friendName,
        sentAt: DateTime.now(),
        status: InvitationStatus.pending,
        message: 'Join me for a study session: ${session.title}',
      );

      _invitations[invitation.id] = invitation;
    }

    await _saveInvitations();
    debugPrint(
        'Sent ${friendIds.length} invitations for session ${session.title}');
  }

  /// Respond to a session invitation
  Future<bool> respondToInvitation(String invitationId, bool accept) async {
    final invitation = _invitations[invitationId];
    if (invitation == null || invitation.toUserId != _currentUserId) {
      return false;
    }

    final newStatus =
        accept ? InvitationStatus.accepted : InvitationStatus.declined;
    final updatedInvitation = invitation.copyWith(
      status: newStatus,
      respondedAt: DateTime.now(),
    );

    _invitations[invitationId] = updatedInvitation;

    // If accepted, add user to session
    if (accept) {
      final success = await joinSession(invitation.sessionId, _currentUserId);
      if (!success) {
        debugPrint('Failed to join session after accepting invitation');
        return false;
      }
    }

    await _saveInvitations();
    notifyListeners();

    debugPrint(
        'Invitation ${accept ? "accepted" : "declined"} for session ${invitation.sessionId}');
    return true;
  }

  /// Join a session
  Future<bool> joinSession(String sessionId, String userId) async {
    final session = _sessions[sessionId];
    if (session == null || !session.canJoin) {
      return false;
    }

    if (session.participantIds.contains(userId)) {
      return true; // Already joined
    }

    final userName = userId == _currentUserId
        ? _currentUserName
        : (_mockFriends[userId] ?? 'Unknown User');

    final updatedParticipants = List<String>.from(session.participantIds)
      ..add(userId);
    final updatedParticipantNames =
        Map<String, String>.from(session.participantNames);
    updatedParticipantNames[userId] = userName;

    final updatedSession = session.copyWith(
      participantIds: updatedParticipants,
      participantNames: updatedParticipantNames,
    );

    _sessions[sessionId] = updatedSession;
    await _saveSessions();
    notifyListeners();

    debugPrint('User $userName joined session ${session.title}');
    return true;
  }

  /// Leave a session
  Future<bool> leaveSession(String sessionId, String userId) async {
    final session = _sessions[sessionId];
    if (session == null || !session.participantIds.contains(userId)) {
      return false;
    }

    // Host cannot leave their own session
    if (session.hostId == userId) {
      return false;
    }

    final updatedParticipants = List<String>.from(session.participantIds)
      ..remove(userId);
    final updatedParticipantNames =
        Map<String, String>.from(session.participantNames);
    updatedParticipantNames.remove(userId);

    final updatedSession = session.copyWith(
      participantIds: updatedParticipants,
      participantNames: updatedParticipantNames,
    );

    _sessions[sessionId] = updatedSession;
    await _saveSessions();
    notifyListeners();

    debugPrint(
        'User ${session.participantNames[userId]} left session ${session.title}');
    return true;
  }

  /// Start a session (host only)
  Future<SocialSession?> startSession(String sessionId) async {
    final session = _sessions[sessionId];
    if (session == null ||
        session.hostId != _currentUserId ||
        session.status != SessionStatus.scheduled) {
      return null;
    }

    final liveSession = session.copyWith(
      status: SessionStatus.live,
      actualStartTime: DateTime.now(),
    );

    _sessions[sessionId] = liveSession;
    await _saveSessions();
    notifyListeners();

    debugPrint('Session ${session.title} started live');
    return liveSession;
  }

  /// End a session (host only)
  Future<SocialSession?> endSession(String sessionId,
      {Map<String, dynamic>? finalData}) async {
    final session = _sessions[sessionId];
    if (session == null ||
        session.hostId != _currentUserId ||
        session.status != SessionStatus.live) {
      return null;
    }

    final completedSession = session.copyWith(
      status: SessionStatus.completed,
      endTime: DateTime.now(),
      sessionData: finalData,
    );

    _sessions[sessionId] = completedSession;
    await _saveSessions();
    notifyListeners();

    debugPrint('Session ${session.title} completed');
    return completedSession;
  }

  /// Cancel a session (host only)
  Future<bool> cancelSession(String sessionId, String reason) async {
    final session = _sessions[sessionId];
    if (session == null ||
        session.hostId != _currentUserId ||
        session.status != SessionStatus.scheduled) {
      return false;
    }

    final cancelledSession = session.copyWith(
      status: SessionStatus.cancelled,
      sessionData: {
        'cancellationReason': reason,
        'cancelledAt': DateTime.now().toIso8601String()
      },
    );

    _sessions[sessionId] = cancelledSession;
    await _saveSessions();
    notifyListeners();

    debugPrint('Session ${session.title} cancelled: $reason');
    return true;
  }

  /// Get a session by ID
  SocialSession? getSession(String sessionId) {
    return _sessions[sessionId];
  }

  /// Check if user can join a specific session
  bool canJoinSession(String sessionId, String userId) {
    final session = _sessions[sessionId];
    if (session == null) return false;

    return session.canJoin &&
        !session.participantIds.contains(userId) &&
        session.hostId != userId;
  }

  /// Get sessions happening today
  List<SocialSession> getTodaysSessions() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _sessions.values
        .where((s) =>
            s.scheduledTime.isAfter(startOfDay) &&
            s.scheduledTime.isBefore(endOfDay))
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
  }

  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    final hosted = hostedSessions.length;
    final joined = joinedSessions.length;
    final completed = completedSessions
        .where((s) => s.participantIds.contains(_currentUserId))
        .length;
    final totalParticipants = _sessions.values
        .where((s) => s.participantIds.contains(_currentUserId))
        .map((s) => s.participantCount)
        .fold(0, (sum, count) => sum + count);

    return {
      'sessionsHosted': hosted,
      'sessionsJoined': joined,
      'sessionsCompleted': completed,
      'totalParticipants': totalParticipants,
      'averageParticipants':
          completed > 0 ? (totalParticipants / completed).round() : 0,
    };
  }

  /// Clear all data (for testing/reset)
  Future<void> clearAllData() async {
    _sessions.clear();
    _invitations.clear();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionsKey);
    await prefs.remove(_invitationsKey);

    notifyListeners();
    debugPrint('All social session data cleared');
  }

  // Private helper methods

  String _generateSessionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return 'session_${timestamp}_$random';
  }

  String _generateInvitationId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(1000);
    return 'invite_${timestamp}_$random';
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserId =
        prefs.getString(_userIdKey) ?? 'user_${Random().nextInt(10000)}';
    _currentUserName = prefs.getString(_userNameKey) ?? 'Study Buddy';

    // Save if new
    await prefs.setString(_userIdKey, _currentUserId);
    await prefs.setString(_userNameKey, _currentUserName);
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsJson = prefs.getString(_sessionsKey);

    if (sessionsJson != null) {
      final sessionsMap = jsonDecode(sessionsJson) as Map<String, dynamic>;
      _sessions.clear();

      for (final entry in sessionsMap.entries) {
        try {
          _sessions[entry.key] = SocialSession.fromJson(entry.value);
        } catch (e) {
          debugPrint('Error loading session ${entry.key}: $e');
        }
      }
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionsMap =
        _sessions.map((key, session) => MapEntry(key, session.toJson()));
    await prefs.setString(_sessionsKey, jsonEncode(sessionsMap));
  }

  Future<void> _loadInvitations() async {
    final prefs = await SharedPreferences.getInstance();
    final invitationsJson = prefs.getString(_invitationsKey);

    if (invitationsJson != null) {
      final invitationsMap =
          jsonDecode(invitationsJson) as Map<String, dynamic>;
      _invitations.clear();

      for (final entry in invitationsMap.entries) {
        try {
          _invitations[entry.key] = SessionInvitation.fromJson(entry.value);
        } catch (e) {
          debugPrint('Error loading invitation ${entry.key}: $e');
        }
      }
    }
  }

  Future<void> _saveInvitations() async {
    final prefs = await SharedPreferences.getInstance();
    final invitationsMap =
        _invitations.map((key, inv) => MapEntry(key, inv.toJson()));
    await prefs.setString(_invitationsKey, jsonEncode(invitationsMap));
  }

  void _cleanupExpiredSessions() {
    final now = DateTime.now();
    final expiredSessions = <String>[];

    for (final entry in _sessions.entries) {
      final session = entry.value;
      // Mark sessions as expired if they were scheduled more than 24 hours ago and never started
      if (session.status == SessionStatus.scheduled &&
          now.difference(session.scheduledTime).inHours > 24) {
        expiredSessions.add(entry.key);
      }
    }

    for (final sessionId in expiredSessions) {
      final session = _sessions[sessionId]!;
      _sessions[sessionId] = session.copyWith(status: SessionStatus.cancelled);
    }

    if (expiredSessions.isNotEmpty) {
      _saveSessions();
      debugPrint('Cleaned up ${expiredSessions.length} expired sessions');
    }
  }

  /// Set current user info (for testing/demo purposes)
  Future<void> setCurrentUser(String userId, String userName) async {
    _currentUserId = userId;
    _currentUserName = userName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userNameKey, userName);

    notifyListeners();
  }
}
