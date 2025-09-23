import 'package:flutter/material.dart';
import '../services/social_session_service.dart';
import '../models/social_session.dart';

/// Provider wrapper for SocialSessionService to integrate with widget tree
/// 
/// Provides access to social session functionality throughout the app
/// including session management, invitations, and real-time updates
class SocialSessionProvider extends ChangeNotifier {
  final SocialSessionService _service = SocialSessionService();
  
  /// Get the underlying service instance
  SocialSessionService get service => _service;
  
  /// Get all sessions
  List<SocialSession> get allSessions => _service.allSessions;
  
  /// Get hosted sessions
  List<SocialSession> get hostedSessions => _service.hostedSessions;
  
  /// Get joined sessions  
  List<SocialSession> get joinedSessions => _service.joinedSessions;
  
  /// Get upcoming sessions
  List<SocialSession> get upcomingSessions => _service.upcomingSessions;
  
  /// Get live sessions
  List<SocialSession> get liveSessions => _service.liveSessions;
  
  /// Get completed sessions
  List<SocialSession> get completedSessions => _service.completedSessions;
  
  /// Get joinable sessions
  List<SocialSession> get joinableSessions => _service.joinableSessions;
  
  /// Get pending invitations
  List<SessionInvitation> get pendingInvitations => _service.pendingInvitations;
  
  /// Get sent invitations
  List<SessionInvitation> get sentInvitations => _service.sentInvitations;
  
  /// Get mock friends map
  Map<String, String> get friends => _service.friends;
  
  /// Get friend names as list
  List<String> get friendNames => _service.friends.values.toList();
  
  /// Get current user ID
  String get currentUserId => _service.currentUserId;
  
  /// Get current user name
  String get currentUserName => _service.currentUserName;
  
  /// Initialize the provider and load data
  Future<void> initialize() async {
    await _service.initialize();
    notifyListeners();
  }
  
  /// Schedule a new session
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
    final session = await _service.scheduleSession(
      title: title,
      description: description,
      scheduledTime: scheduledTime,
      duration: duration,
      deckIds: deckIds,
      type: type,
      invitedFriendIds: invitedFriendIds,
      maxParticipants: maxParticipants,
      isPublic: isPublic,
    );
    notifyListeners();
    return session;
  }
  
  /// Respond to invitation
  Future<bool> respondToInvitation(String invitationId, bool accept) async {
    final result = await _service.respondToInvitation(invitationId, accept);
    notifyListeners();
    return result;
  }
  
  /// Join a session
  Future<bool> joinSession(String sessionId, String userId) async {
    final result = await _service.joinSession(sessionId, userId);
    notifyListeners();
    return result;
  }
  
  /// Leave a session
  Future<bool> leaveSession(String sessionId, String userId) async {
    final result = await _service.leaveSession(sessionId, userId);
    notifyListeners();
    return result;
  }
  
  /// Start a session (for hosts)
  Future<SocialSession?> startSession(String sessionId) async {
    final result = await _service.startSession(sessionId);
    notifyListeners();
    return result;
  }
  
  /// End a session
  Future<SocialSession?> endSession(String sessionId, {Map<String, dynamic>? finalData}) async {
    final result = await _service.endSession(sessionId, finalData: finalData);
    notifyListeners();
    return result;
  }
  
  /// Cancel a session
  Future<bool> cancelSession(String sessionId, String reason) async {
    final result = await _service.cancelSession(sessionId, reason);
    notifyListeners();
    return result;
  }
  
  /// Get a session by ID
  SocialSession? getSession(String sessionId) {
    return _service.getSession(sessionId);
  }
  
  /// Check if user can join a session
  bool canJoinSession(String sessionId, String userId) {
    return _service.canJoinSession(sessionId, userId);
  }
  
  /// Get today's sessions
  List<SocialSession> getTodaysSessions() {
    return _service.getTodaysSessions();
  }
  
  /// Get session statistics
  Map<String, dynamic> getSessionStats() {
    return _service.getSessionStats();
  }
  
  /// Clear all data
  Future<void> clearAllData() async {
    await _service.clearAllData();
    notifyListeners();
  }
}