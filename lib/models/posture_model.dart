class PostureResult {
  final Prediction prediction;
  final Analysis analysis;
  final Map<String, double> classProbabilities;

  PostureResult({
    required this.prediction,
    required this.analysis,
    required this.classProbabilities,
  });

  factory PostureResult.fromJson(Map<String, dynamic> json)
  {
    // Mengubah nilai probabilitas dari int/double menjadi double
    final probabilitiesRaw = json['class_probabilities'] as Map<String, dynamic>;
    final probabilities = probabilitiesRaw.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
    );

    return PostureResult(
      prediction: Prediction.fromJson(json['prediction']),
      analysis: Analysis.fromJson(json['analysis']),
      classProbabilities: probabilities,
    );
  }
}

class Prediction {
  final String className;
  final double confidence;
  final String status;

  Prediction({required this.className, required this.confidence, required this.status});

  factory Prediction.fromJson(Map<String, dynamic> json) {
    return Prediction(
      className: json['class'],
      confidence: (json['confidence'] as num).toDouble(),
      status: json['status'],
    );
  }
}

class Analysis {
  final List<String> problems;
  final List<String> suggestions;
  final String colorHex;

  Analysis({required this.problems, required this.suggestions, required this.colorHex});

  factory Analysis.fromJson(Map<String, dynamic> json) {
    return Analysis(
      problems: List<String>.from(json['problems']),
      suggestions: List<String>.from(json['suggestions']),
      colorHex: json['color'],
    );
  }
}