import 'dart:ui';
import 'pose_landmark.dart';
import 'pose_landmark_type.dart';

// Model hasil deteksi pose
class PoseDetectionResult {
  final bool isPoseDetected;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final int inferenceTimeMs;
  final Size? imageSize;

  PoseDetectionResult({
    required this.isPoseDetected,
    required this.landmarks,
    required this.inferenceTimeMs,
    this.imageSize,
  });

  Map<String, dynamic> toJson()
  {
    return {
      'isPoseDetected': isPoseDetected,
      'landmarks': landmarks.map((key, value) => MapEntry(key.name, value.toJson())),
      'inferenceTimeMs': inferenceTimeMs,
      'imageSize': imageSize != null
          ? {'width': imageSize!.width, 'height': imageSize!.height}
          : null,
    };
  }

  /// Factory constructor untuk membuat hasil 'kosong' saat tidak ada pose yang terdeteksi.
  factory PoseDetectionResult.empty(int inferenceTimeMs)
  {
    return PoseDetectionResult(
      isPoseDetected: false,
      landmarks: {},
      inferenceTimeMs: inferenceTimeMs,
      imageSize: null,
    );
  }

  /// Factory constructor untuk konversi dari Map (misal EventChannel) ke model Dart
  factory PoseDetectionResult.fromMap(Map<String, dynamic> map)
  {
    List<dynamic> landmarksList = map['landmarks'] ?? [];
    Map<PoseLandmarkType, PoseLandmark> landmarksMap = {};

    for (var i = 0; i < landmarksList.length && i < PoseLandmarkType.values.length; i++)
    {
      var lmMap = landmarksList[i] as Map<String, dynamic>;
      landmarksMap[PoseLandmarkType.values[i]] = PoseLandmark(
        x: (lmMap['x'] as num).toDouble(),
        y: (lmMap['y'] as num).toDouble(),
        z: (lmMap['z'] as num).toDouble(),
        visibility: (lmMap['visibility'] as num).toDouble(),
      );
    }

    Size? imageSize;
    if (map['imageWidth'] != null && map['imageHeight'] != null)
    {
      imageSize = Size(
        (map['imageWidth'] as num).toDouble(),
        (map['imageHeight'] as num).toDouble(),
      );
    }

    return PoseDetectionResult(
      isPoseDetected: landmarksList.isNotEmpty,
      landmarks: landmarksMap,
      inferenceTimeMs: map['inferenceTimeMs'] as int,
      imageSize: imageSize,
    );
  }
}