// models/workout_model.dart;

class Movement {
  final String name;
  final String description;
  final String repetition;

  Movement({
    required this.name,
    required this.description,
    required this.repetition,
  });
}

class Workout {
  final String title;
  final String description;
  final String imagePath;
  final List<Movement> movements;

  Workout({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.movements,
  });
}