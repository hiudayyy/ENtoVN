class TenseQuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String tenseName;

  TenseQuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.tenseName,
  });

  factory TenseQuizQuestion.fromJson(Map<String, dynamic> json) {
    return TenseQuizQuestion(
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctIndex: json['correctIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
      tenseName: json['tenseName'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      'tenseName': tenseName,
    };
  }
}
