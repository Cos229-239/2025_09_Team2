class CollaborativeSession {
  final String id;
  final String name;
  final String hostId;
  final String? groupId;
  final DateTime scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final List<String> participants;
  final String subject;
  final String? description;
  final Map<String, dynamic> sessionData;
  final bool isActive;
  final bool isRecorded;

  CollaborativeSession({
    required this.id,
    required this.name,
    required this.hostId,
    this.groupId,
    required this.scheduledTime,
    this.startTime,
    this.endTime,
    List<String>? participants,
    required this.subject,
    this.description,
    Map<String, dynamic>? sessionData,
    this.isActive = false,
    this.isRecorded = false,
  })  : participants = participants ?? [],
        sessionData = sessionData ?? {};

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hostId': hostId,
      'groupId': groupId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'participants': participants,
      'subject': subject,
      'description': description,
      'sessionData': sessionData,
      'isActive': isActive,
      'isRecorded': isRecorded,
    };
  }

  factory CollaborativeSession.fromMap(Map<String, dynamic> map) {
    return CollaborativeSession(
      id: map['id'] as String,
      name: map['name'] as String,
      hostId: map['hostId'] as String,
      groupId: map['groupId'] as String?,
      scheduledTime: DateTime.parse(map['scheduledTime'] as String),
      startTime: map['startTime'] != null
          ? DateTime.parse(map['startTime'] as String)
          : null,
      endTime: map['endTime'] != null
          ? DateTime.parse(map['endTime'] as String)
          : null,
      participants: List<String>.from(map['participants'] as List? ?? []),
      subject: map['subject'] as String,
      description: map['description'] as String?,
      sessionData: Map<String, dynamic>.from(map['sessionData'] as Map? ?? {}),
      isActive: map['isActive'] as bool? ?? false,
      isRecorded: map['isRecorded'] as bool? ?? false,
    );
  }
}
