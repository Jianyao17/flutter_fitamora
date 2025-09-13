import 'exercise.dart';

class WorkoutPlan {
  final String title;
  final String description;
  final String? imagePath;
  final List<Exercise> exercises;

  WorkoutPlan({
    required this.title,
    required this.description,
    required this.exercises,
    this.imagePath,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json)
  {
    return WorkoutPlan(
      title: json['title'],
      description: json['description'],
      imagePath: json['imagePath'],
      exercises: (json['exercises'] as List)
          .map((e) => Exercise.fromJson(e))
          .toList(),
    );
  }
}
