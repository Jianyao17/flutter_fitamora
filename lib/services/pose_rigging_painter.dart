import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../models/pose_detection_result.dart';
import '../models/pose_landmark_type.dart';

class PoseRiggingPainter extends CustomPainter {
  final ui.Image image;
  final PoseDetectionResult? poseResult;

  // Styling untuk visualisasi
  static const double _landmarkRadius = 4.0;
  static const double _connectionStrokeWidth = 2.0;
  static const double _jointRadius = 6.0;

  // Warna untuk berbagai bagian tubuh
  static const Color _faceColor = Colors.yellow;
  static const Color _torsoColor = Colors.blue;
  static const Color _leftArmColor = Colors.green;
  static const Color _rightArmColor = Colors.red;
  static const Color _leftLegColor = Colors.purple;
  static const Color _rightLegColor = Colors.orange;
  static const Color _connectionColor = Colors.white;

  PoseRiggingPainter({
    required this.image,
    this.poseResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gambar background image
    _drawBackgroundImage(canvas, size);

    // Gambar pose rigging jika ada hasil deteksi
    if (poseResult != null && poseResult!.isPoseDetected) {
      _drawPoseRigging(canvas, size);
    }

    // Gambar bounding box jika ada
    if (poseResult?.boundingBox != null) {
      _drawBoundingBox(canvas, size);
    }
  }

  void _drawBackgroundImage(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.high
      ..isAntiAlias = true;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  void _drawPoseRigging(Canvas canvas, Size size) {
    if (poseResult?.landmarks.isEmpty == true) return;

    // Konversi koordinat dari image space ke canvas space
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    // Gambar koneksi terlebih dahulu (supaya berada di belakang landmarks)
    _drawConnections(canvas, scaleX, scaleY);

    // Gambar landmarks
    _drawLandmarks(canvas, scaleX, scaleY);
  }

  void _drawConnections(Canvas canvas, double scaleX, double scaleY) {
    final connectionPaint = Paint()
      ..color = _connectionColor
      ..strokeWidth = _connectionStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Shadow untuk connection lines
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..strokeWidth = _connectionStrokeWidth + 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Definisi koneksi pose MediaPipe
    final connections = _getPoseConnections();

    for (final connection in connections) {
      final startLandmark = poseResult!.landmarks[connection.start];
      final endLandmark = poseResult!.landmarks[connection.end];

      if (startLandmark != null && endLandmark != null) {
        final startPoint = Offset(
          startLandmark.x * scaleX,
          startLandmark.y * scaleY,
        );
        final endPoint = Offset(
          endLandmark.x * scaleX,
          endLandmark.y * scaleY,
        );

        // Gambar shadow
        canvas.drawLine(startPoint, endPoint, shadowPaint);
        // Gambar connection
        canvas.drawLine(startPoint, endPoint, connectionPaint);
      }
    }
  }

  void _drawLandmarks(Canvas canvas, double scaleX, double scaleY) {
    for (final entry in poseResult!.landmarks.entries) {
      final landmarkType = entry.key;
      final landmark = entry.value;

      final point = Offset(
        landmark.x * scaleX,
        landmark.y * scaleY,
      );

      final color = _getLandmarkColor(landmarkType);

      // Shadow untuk landmark
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.4)
        ..style = PaintingStyle.fill;

      // Main landmark paint
      final landmarkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;

      // Border untuk landmark
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final radius = _isJointLandmark(landmarkType) ? _jointRadius : _landmarkRadius;

      // Gambar shadow
      canvas.drawCircle(
        Offset(point.dx + 1, point.dy + 1),
        radius,
        shadowPaint,
      );

      // Gambar landmark
      canvas.drawCircle(point, radius, landmarkPaint);

      // Gambar border
      canvas.drawCircle(point, radius, borderPaint);

      // Gambar visibility indicator jika visibility rendah
      if (landmark.visibility < 0.8) {
        final visibilityPaint = Paint()
          ..color = Colors.red.withOpacity(0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        canvas.drawCircle(point, radius + 2, visibilityPaint);
      }
    }
  }

  void _drawBoundingBox(Canvas canvas, Size size) {
    if (poseResult?.boundingBox == null) return;

    final bbox = poseResult!.boundingBox!;
    final scaleX = size.width / image.width;
    final scaleY = size.height / image.height;

    final rect = Rect.fromLTRB(
      bbox.left * scaleX,
      bbox.top * scaleY,
      bbox.right * scaleX,
      bbox.bottom * scaleY,
    );

    final paint = Paint()
      ..color = Colors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRect(rect, paint);

    // Label confidence
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(poseResult!.confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(
          color: Colors.cyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(rect.left, rect.top - 16));
  }

  Color _getLandmarkColor(PoseLandmarkType type) {
    switch (type) {
    // Face landmarks
      case PoseLandmarkType.nose:
      case PoseLandmarkType.leftEyeInner:
      case PoseLandmarkType.leftEye:
      case PoseLandmarkType.leftEyeOuter:
      case PoseLandmarkType.rightEyeInner:
      case PoseLandmarkType.rightEye:
      case PoseLandmarkType.rightEyeOuter:
      case PoseLandmarkType.leftEar:
      case PoseLandmarkType.rightEar:
      case PoseLandmarkType.mouthLeft:
      case PoseLandmarkType.mouthRight:
        return _faceColor;

    // Torso landmarks
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return _torsoColor;

    // Left arm landmarks
      case PoseLandmarkType.leftElbow:
      case PoseLandmarkType.leftWrist:
      case PoseLandmarkType.leftPinky:
      case PoseLandmarkType.leftIndex:
      case PoseLandmarkType.leftThumb:
        return _leftArmColor;

    // Right arm landmarks
      case PoseLandmarkType.rightElbow:
      case PoseLandmarkType.rightWrist:
      case PoseLandmarkType.rightPinky:
      case PoseLandmarkType.rightIndex:
      case PoseLandmarkType.rightThumb:
        return _rightArmColor;

    // Left leg landmarks
      case PoseLandmarkType.leftKnee:
      case PoseLandmarkType.leftAnkle:
      case PoseLandmarkType.leftHeel:
      case PoseLandmarkType.leftFootIndex:
        return _leftLegColor;

    // Right leg landmarks
      case PoseLandmarkType.rightKnee:
      case PoseLandmarkType.rightAnkle:
      case PoseLandmarkType.rightHeel:
      case PoseLandmarkType.rightFootIndex:
        return _rightLegColor;

      default:
        return Colors.white;
    }
  }

  bool _isJointLandmark(PoseLandmarkType type) {
    return [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow,
      PoseLandmarkType.rightElbow,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ].contains(type);
  }

  List<PoseConnection> _getPoseConnections() {
    return [
      // Face connections
      PoseConnection(PoseLandmarkType.leftEye, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.rightEye, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.leftEar, PoseLandmarkType.leftEye),
      PoseConnection(PoseLandmarkType.rightEar, PoseLandmarkType.rightEye),
      PoseConnection(PoseLandmarkType.mouthLeft, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.mouthRight, PoseLandmarkType.nose),

      // Torso connections
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
      PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),

      // Left arm connections
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
      PoseConnection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky),

      // Right arm connections
      PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
      PoseConnection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky),

      // Left leg connections
      PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
      PoseConnection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel),
      PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex),

      // Right leg connections
      PoseConnection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      PoseConnection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
      PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel),
      PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex),
    ];
  }

  @override
  bool shouldRepaint(covariant PoseRiggingPainter oldDelegate) {
    return oldDelegate.image != image || oldDelegate.poseResult != poseResult;
  }
}

// Helper class untuk mendefinisikan koneksi antar landmarks
class PoseConnection {
  final PoseLandmarkType start;
  final PoseLandmarkType end;

  PoseConnection(this.start, this.end);
}