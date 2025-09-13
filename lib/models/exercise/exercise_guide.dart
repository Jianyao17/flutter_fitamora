class ExerciseGuide {
  final String title;
  final String imageUrl;

  ExerciseGuide({
    required this.title,
    required this.imageUrl,
  });

  factory ExerciseGuide.fromJson(Map<String, dynamic> json)
  {
    return ExerciseGuide(
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }
}