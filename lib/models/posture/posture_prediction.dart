class PosturePrediction {
  final String className;
  final double confidence;
  final String status;

  PosturePrediction({required this.className, required this.confidence, required this.status});

  factory PosturePrediction.fromJson(Map<String, dynamic> json)
  {
    return PosturePrediction(
      className: json['class'],
      confidence: (json['confidence'] as num).toDouble(),
      status: json['status'],
    );
  }
}