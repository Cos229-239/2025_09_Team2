/// Quiz question for assessment
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String conceptId;
  final int difficulty;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.conceptId,
    required this.difficulty,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correctIndex': correctIndex,
        'explanation': explanation,
        'conceptId': conceptId,
        'difficulty': difficulty,
      };

  /// Create from JSON
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String,
      question: json['question'] as String,
      options: (json['options'] as List).cast<String>(),
      correctIndex: json['correctIndex'] as int,
      explanation: json['explanation'] as String,
      conceptId: json['conceptId'] as String,
      difficulty: json['difficulty'] as int,
    );
  }
}
