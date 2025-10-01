/// Message types for the AI tutor chat system
enum MessageType {
  user,
  assistant,
  system,
  error,
}

/// Message formats for different response types
enum MessageFormat {
  text,
  structured,
  multimodal,
  interactive,
}

/// Represents a chat message in the AI tutor system
class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final MessageFormat format;
  final DateTime timestamp;
  final String? userId;
  final Map<String, dynamic>? metadata;
  final List<String>? attachments;
  final bool isGenerating;
  
  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.format,
    DateTime? timestamp,
    this.userId,
    this.metadata,
    this.attachments,
    this.isGenerating = false,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Convert to JSON for Firestore storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'content': content,
    'type': type.name,
    'format': format.name,
    'timestamp': timestamp.toIso8601String(),
    'userId': userId,
    'metadata': metadata,
    'attachments': attachments,
    'isGenerating': isGenerating,
  };

  /// Create from JSON from Firestore
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      type: MessageType.values.byName(json['type'] as String),
      format: MessageFormat.values.byName(json['format'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      userId: json['userId'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      attachments: (json['attachments'] as List?)?.cast<String>(),
      isGenerating: json['isGenerating'] as bool? ?? false,
    );
  }

  /// Create a copy with modified fields
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageType? type,
    MessageFormat? format,
    DateTime? timestamp,
    String? userId,
    Map<String, dynamic>? metadata,
    List<String>? attachments,
    bool? isGenerating,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      type: type ?? this.type,
      format: format ?? this.format,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
      attachments: attachments ?? this.attachments,
      isGenerating: isGenerating ?? this.isGenerating,
    );
  }

  @override
  String toString() {
    return 'ChatMessage(id: $id, type: $type, content: ${content.substring(0, content.length < 50 ? content.length : 50)}...)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}