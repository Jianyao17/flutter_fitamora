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
}
