/// Types of social study sessions
enum SessionType {
  quiz('Quiz Session'),
  study('Study Session'),
  challenge('Challenge'),
  group('Group Study');

  const SessionType(this.displayName);
  final String displayName;
}

/// Current status of a social session
enum SessionStatus {
  scheduled('Scheduled'),
  live('Live'),
  completed('Completed'),
  cancelled('Cancelled');

  const SessionStatus(this.displayName);
  final String displayName;
}

/// Status of session invitations
enum InvitationStatus {
  pending('Pending'),
  accepted('Accepted'),
  declined('Declined'),
  expired('Expired');

  const InvitationStatus(this.displayName);
  final String displayName;
}

/// Represents a social study session
class SocialSession {
  final String id;
  final String hostId;
  final String hostName;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final Duration duration;
  final List<String> deckIds;
  final SessionType type;
  final SessionStatus status;
  final List<String> participantIds;
  final Map<String, String> participantNames; // userId -> userName
  final int maxParticipants;
  final DateTime? actualStartTime;
  final DateTime? endTime;
  final DateTime createdAt;
  final bool isPublic;
  final Map<String, dynamic>? sessionData; // For storing quiz results, etc.

  const SocialSession({
    required this.id,
    required this.hostId,
    required this.hostName,
    required this.title,
    required this.description,
    required this.scheduledTime,
    required this.duration,
    required this.deckIds,
    required this.type,
    required this.status,
    required this.participantIds,
    required this.participantNames,
    required this.maxParticipants,
    required this.createdAt,
    this.actualStartTime,
    this.endTime,
    this.isPublic = false,
    this.sessionData,
  });

  SocialSession copyWith({
    String? id,
    String? hostId,
    String? hostName,
    String? title,
    String? description,
    DateTime? scheduledTime,
    Duration? duration,
    List<String>? deckIds,
    SessionType? type,
    SessionStatus? status,
    List<String>? participantIds,
    Map<String, String>? participantNames,
    int? maxParticipants,
    DateTime? actualStartTime,
    DateTime? endTime,
    DateTime? createdAt,
    bool? isPublic,
    Map<String, dynamic>? sessionData,
  }) {
    return SocialSession(
      id: id ?? this.id,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      duration: duration ?? this.duration,
      deckIds: deckIds ?? this.deckIds,
      type: type ?? this.type,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      participantNames: participantNames ?? this.participantNames,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      actualStartTime: actualStartTime ?? this.actualStartTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      sessionData: sessionData ?? this.sessionData,
    );
  }

  /// Check if the session can be joined
  bool get canJoin =>
      status == SessionStatus.scheduled && 
      participantIds.length < maxParticipants;

  /// Check if the session is currently live
  bool get isLive => status == SessionStatus.live;

  /// Check if the session is completed
  bool get isCompleted => status == SessionStatus.completed;

  /// Get the number of current participants
  int get participantCount => participantIds.length;

  /// Check if session is starting soon (within 15 minutes)
  bool get isStartingSoon {
    final now = DateTime.now();
    final timeDiff = scheduledTime.difference(now);
    return timeDiff.inMinutes <= 15 && timeDiff.inMinutes >= 0;
  }

  /// Get session duration in minutes
  int get durationInMinutes => duration.inMinutes;

  /// Get estimated end time
  DateTime get estimatedEndTime => (actualStartTime ?? scheduledTime).add(duration);

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hostId': hostId,
      'hostName': hostName,
      'title': title,
      'description': description,
      'scheduledTime': scheduledTime.toIso8601String(),
      'duration': duration.inMinutes,
      'deckIds': deckIds,
      'type': type.name,
      'status': status.name,
      'participantIds': participantIds,
      'participantNames': participantNames,
      'maxParticipants': maxParticipants,
      'actualStartTime': actualStartTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isPublic': isPublic,
      'sessionData': sessionData,
    };
  }

  /// Create from JSON
  factory SocialSession.fromJson(Map<String, dynamic> json) {
    return SocialSession(
      id: json['id'],
      hostId: json['hostId'],
      hostName: json['hostName'],
      title: json['title'],
      description: json['description'],
      scheduledTime: DateTime.parse(json['scheduledTime']),
      duration: Duration(minutes: json['duration']),
      deckIds: List<String>.from(json['deckIds']),
      type: SessionType.values.firstWhere((e) => e.name == json['type']),
      status: SessionStatus.values.firstWhere((e) => e.name == json['status']),
      participantIds: List<String>.from(json['participantIds']),
      participantNames: Map<String, String>.from(json['participantNames']),
      maxParticipants: json['maxParticipants'],
      actualStartTime: json['actualStartTime'] != null 
          ? DateTime.parse(json['actualStartTime']) 
          : null,
      endTime: json['endTime'] != null 
          ? DateTime.parse(json['endTime']) 
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      isPublic: json['isPublic'] ?? false,
      sessionData: json['sessionData'],
    );
  }

  @override
  String toString() => 'SocialSession(id: $id, title: $title, status: $status)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents an invitation to join a social session
class SessionInvitation {
  final String id;
  final String sessionId;
  final String fromUserId;
  final String fromUserName;
  final String toUserId;
  final String toUserName;
  final DateTime sentAt;
  final InvitationStatus status;
  final DateTime? respondedAt;
  final String? message;

  const SessionInvitation({
    required this.id,
    required this.sessionId,
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.sentAt,
    required this.status,
    this.respondedAt,
    this.message,
  });

  SessionInvitation copyWith({
    String? id,
    String? sessionId,
    String? fromUserId,
    String? fromUserName,
    String? toUserId,
    String? toUserName,
    DateTime? sentAt,
    InvitationStatus? status,
    DateTime? respondedAt,
    String? message,
  }) {
    return SessionInvitation(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserId: toUserId ?? this.toUserId,
      toUserName: toUserName ?? this.toUserName,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      respondedAt: respondedAt ?? this.respondedAt,
      message: message ?? this.message,
    );
  }

  /// Check if invitation is still pending
  bool get isPending => status == InvitationStatus.pending;

  /// Check if invitation was accepted
  bool get isAccepted => status == InvitationStatus.accepted;

  /// Check if invitation was declined
  bool get isDeclined => status == InvitationStatus.declined;

  /// Check if invitation has expired
  bool get isExpired => status == InvitationStatus.expired;

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'toUserId': toUserId,
      'toUserName': toUserName,
      'sentAt': sentAt.toIso8601String(),
      'status': status.name,
      'respondedAt': respondedAt?.toIso8601String(),
      'message': message,
    };
  }

  /// Create from JSON
  factory SessionInvitation.fromJson(Map<String, dynamic> json) {
    return SessionInvitation(
      id: json['id'],
      sessionId: json['sessionId'],
      fromUserId: json['fromUserId'],
      fromUserName: json['fromUserName'],
      toUserId: json['toUserId'],
      toUserName: json['toUserName'],
      sentAt: DateTime.parse(json['sentAt']),
      status: InvitationStatus.values.firstWhere((e) => e.name == json['status']),
      respondedAt: json['respondedAt'] != null 
          ? DateTime.parse(json['respondedAt']) 
          : null,
      message: json['message'],
    );
  }

  @override
  String toString() => 'SessionInvitation(id: $id, from: $fromUserName, to: $toUserName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SessionInvitation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// User participation in a session
class SessionParticipant {
  final String userId;
  final String userName;
  final DateTime joinedAt;
  final bool isHost;
  final bool isOnline;
  final Map<String, dynamic>? participantData; // For storing scores, progress, etc.

  const SessionParticipant({
    required this.userId,
    required this.userName,
    required this.joinedAt,
    this.isHost = false,
    this.isOnline = true,
    this.participantData,
  });

  SessionParticipant copyWith({
    String? userId,
    String? userName,
    DateTime? joinedAt,
    bool? isHost,
    bool? isOnline,
    Map<String, dynamic>? participantData,
  }) {
    return SessionParticipant(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      joinedAt: joinedAt ?? this.joinedAt,
      isHost: isHost ?? this.isHost,
      isOnline: isOnline ?? this.isOnline,
      participantData: participantData ?? this.participantData,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'joinedAt': joinedAt.toIso8601String(),
      'isHost': isHost,
      'isOnline': isOnline,
      'participantData': participantData,
    };
  }

  /// Create from JSON
  factory SessionParticipant.fromJson(Map<String, dynamic> json) {
    return SessionParticipant(
      userId: json['userId'],
      userName: json['userName'],
      joinedAt: DateTime.parse(json['joinedAt']),
      isHost: json['isHost'] ?? false,
      isOnline: json['isOnline'] ?? true,
      participantData: json['participantData'],
    );
  }
}