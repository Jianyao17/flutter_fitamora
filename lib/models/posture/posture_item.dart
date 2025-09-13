import '../exercise/exercise.dart';

class PostureItem {
  final String name;
  final String status;
  final List<String> problems;
  final List<String> suggestions;
  final List<Exercise> exerciseProgram;
  final String colorHex;

  PostureItem({
    required this.name,
    required this.status,
    required this.problems,
    required this.suggestions,
    required this.exerciseProgram,
    required this.colorHex,
  });

  factory PostureItem.fromJson(Map<String, dynamic> json)
  {
    return PostureItem(
      name: json['name'] as String,
      status: json['status'] as String,
      problems: List<String>.from(json['problems'] as List),
      suggestions: List<String>.from(json['suggestions'] as List),
      exerciseProgram: json['exerciseProgram'] != null
          ? (json['exerciseProgram'] as List)
              .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      colorHex: json['colorHex'] as String,
    );
  }

  factory PostureItem.empty()
  {
    return PostureItem(
      name: 'Unknown',
      status: 'Unknown',
      problems: [],
      suggestions: [],
      exerciseProgram: [],
      colorHex: '#FFFFFF',
    );
  }

  factory PostureItem.normal()
  {
    return PostureItem(
      name: 'normal',
      status: 'Baik',
      problems: [],
      suggestions: [
        'Postur tubuh Anda sudah baik!',
        'Pertahankan posisi duduk dan berdiri yang benar',
        'Lakukan stretching ringan secara rutin',
      ],
      exerciseProgram: [
        Exercise(name: 'Full body stretch', sets: 1, duration: 120, description: "Latihan peregangan untuk menjaga fleksibilitas."),
        Exercise(name: 'Shoulder circles', sets: 2, rep: 12, rest: 10, description: "Meningkatkan mobilitas sendi bahu."),
        Exercise(name: 'Deep breathing', sets: 1, duration: 120, description: "Latihan relaksasi dan pernapasan."),
      ],
      colorHex: '#4CAF50', // Green
    );
  }
}