import '../exercise/exercise.dart';

class PostureAnalysis {
  final List<String> problems;
  final List<String> suggestions;
  final String colorHex;

  final List<Exercise> exerciseProgram;

  PostureAnalysis({
    required this.problems,
    required this.suggestions,
    required this.colorHex,
    this.exerciseProgram = const [],
  });

  factory PostureAnalysis.fromJson(Map<String, dynamic> json)
  {
    return PostureAnalysis(
      problems: List<String>.from(json['problems']),
      suggestions: List<String>.from(json['suggestions']),
      colorHex: json['color'],
    );
  }
}