import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a tutoring session with the AI tutor
class TutorSession {
  final String id;
  final String userId;
  final String subject;
  final String difficulty;
  final List<String> messageIds;
  final DateTime startTime;
  final DateTime? endTime;
  final Map<String, dynamic> sessionMetrics;
  final bool isActive;

  TutorSession({
    required this.id,
    required this.userId,
    required this.subject,
    required this.difficulty,
    List<String>? messageIds,
    DateTime? startTime,
    this.endTime,
    Map<String, dynamic>? sessionMetrics,
    this.isActive = true,
  }) : messageIds = messageIds ?? [],
       startTime = startTime ?? DateTime.now(),
       sessionMetrics = sessionMetrics ?? {};

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'subject': subject,
    'difficulty': difficulty,
    'messageIds': messageIds,
    'startTime': Timestamp.fromDate(startTime), // 🔥 FIX: Save as Timestamp, not String
    'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null, // 🔥 FIX: Save as Timestamp
    'sessionMetrics': sessionMetrics,
    'isActive': isActive,
  };

  /// Create from JSON from Firestore
  factory TutorSession.fromJson(Map<String, dynamic> json) {
    return TutorSession(
      id: json['id'] as String,
      userId: json['userId'] as String,
      subject: json['subject'] as String,
      difficulty: json['difficulty'] as String,
      messageIds: (json['messageIds'] as List?)?.cast<String>() ?? [],
      startTime: json['startTime'] is Timestamp 
        ? (json['startTime'] as Timestamp).toDate()
        : DateTime.parse(json['startTime'] as String), // Support both formats
      endTime: json['endTime'] != null 
        ? (json['endTime'] is Timestamp
            ? (json['endTime'] as Timestamp).toDate()
            : DateTime.parse(json['endTime'] as String))
        : null,
      sessionMetrics: json['sessionMetrics'] as Map<String, dynamic>? ?? {},
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Create a copy with modified fields
  TutorSession copyWith({
    String? id,
    String? userId,
    String? subject,
    String? difficulty,
    List<String>? messageIds,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? sessionMetrics,
    bool? isActive,
  }) {
    return TutorSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subject: subject ?? this.subject,
      difficulty: difficulty ?? this.difficulty,
      messageIds: messageIds ?? this.messageIds,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      sessionMetrics: sessionMetrics ?? this.sessionMetrics,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Get session duration in minutes
  int get durationMinutes {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime).inMinutes;
  }

  @override
  String toString() {
    return 'TutorSession(id: $id, subject: $subject, active: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TutorSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}