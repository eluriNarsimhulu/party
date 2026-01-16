// lib/models/answer_result.dart

class AnswerResult {
  final String title;
  final bool usedHint;
  final double score;

  const AnswerResult({
    required this.title,
    required this.usedHint,
    required this.score,
  });
}