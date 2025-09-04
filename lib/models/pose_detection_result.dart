import 'dart:ui';
import 'pose_landmark.dart';
import 'pose_landmark_type.dart';

// Model hasil deteksi pose
class PoseDetectionResult {
  final bool isPoseDetected;
  final Map<PoseLandmarkType, PoseLandmark> landmarks;
  final Map<PoseLandmarkType, PoseLandmark> worldLandmarks;
  late final double confidence;
  final Rect? boundingBox;
  final int processingTimeMs;

  PoseDetectionResult({
    required this.isPoseDetected,
    required this.landmarks,
    required this.worldLandmarks,
    required this.confidence,
    required this.processingTimeMs,
    this.boundingBox,
  });

  Map<String, dynamic> toJson()
  {
    return {
      'isPoseDetected': isPoseDetected,
      'landmarks': landmarks.map((key, value) => MapEntry(key.name, value.toJson())),
      'worldLandmarks': worldLandmarks.map((key, value) => MapEntry(key.name, value.toJson())),
      'confidence': confidence,
      'processingTimeMs': processingTimeMs,
      'boundingBox': boundingBox != null
        ? {
        'left': boundingBox!.left,
        'top': boundingBox!.top,
        'right': boundingBox!.right,
        'bottom': boundingBox!.bottom,
        } : null,
    };
  }

  /// Factory constructor untuk membuat hasil 'kosong' saat tidak ada pose yang terdeteksi.
  factory PoseDetectionResult.empty(int processingTimeMs, {double confidence = 0.0})
  {
    return PoseDetectionResult(
      isPoseDetected: false,
      landmarks: {},
      worldLandmarks: {},
      confidence: confidence,
      boundingBox: null,
      processingTimeMs: processingTimeMs,
    );
  }
}