import 'posture_analysis.dart';
import 'posture_prediction.dart';

class PostureResult {
  final PosturePrediction prediction;
  final PostureAnalysis analysis;
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
      prediction: PosturePrediction.fromJson(json['prediction']),
      analysis: PostureAnalysis.fromJson(json['analysis']),
      classProbabilities: probabilities,
    );
  }
}