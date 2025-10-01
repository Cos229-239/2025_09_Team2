/// Knowledge node representing a concept in the learning graph
class KnowledgeNode {
  final String id;
  final String name;
  final String subject;
  final int difficulty; // 1-10 scale
  final List<String> prerequisites;
  final List<String> relatedConcepts;
  final Map<String, dynamic> metadata;

  KnowledgeNode({
    required this.id,
    required this.name,
    required this.subject,
    required this.difficulty,
    List<String>? prerequisites,
    List<String>? relatedConcepts,
    Map<String, dynamic>? metadata,
  })  : prerequisites = prerequisites ?? [],
        relatedConcepts = relatedConcepts ?? [],
        metadata = metadata ?? {};

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'subject': subject,
    'difficulty': difficulty,
    'prerequisites': prerequisites,
    'relatedConcepts': relatedConcepts,
    'metadata': metadata,
  };

  /// Create from JSON
  factory KnowledgeNode.fromJson(Map<String, dynamic> json) {
    return KnowledgeNode(
      id: json['id'] as String,
      name: json['name'] as String,
      subject: json['subject'] as String,
      difficulty: json['difficulty'] as int,
      prerequisites: (json['prerequisites'] as List?)?.cast<String>(),
      relatedConcepts: (json['relatedConcepts'] as List?)?.cast<String>(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}