import 'dart:ui' as ui;
import 'pose_detection_result.dart';

class PoseRealtimeData {
  final ui.Image image;
  final PoseDetectionResult result;

  PoseRealtimeData({required this.image, required this.result});
}