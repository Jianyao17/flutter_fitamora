import 'package:flutter/material.dart';

import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

class PoseRiggingPainter extends CustomPainter {
  final PoseDetectionResult? poseResult;
  final Size imageSize;          // ukuran asli frame dari native (width, height)
  final int rotationDegrees;     // 0/90/180/270 dari sensorOrientation
  final bool mirror;             // true jika kamera depan

  // Styling
  static const double _landmarkRadius = 4.0;
  static const double _connectionStrokeWidth = 2.0;
  static const double _jointRadius = 6.0;

  // Warna
  static const Color _faceColor = Colors.yellow;
  static const Color _torsoColor = Colors.blue;
  static const Color _leftArmColor = Colors.green;
  static const Color _rightArmColor = Colors.red;
  static const Color _leftLegColor = Colors.purple;
  static const Color _rightLegColor = Colors.orange;
  static const Color _connectionColor = Colors.white;

  PoseRiggingPainter({
    required this.poseResult,
    required this.imageSize,
    required this.rotationDegrees,
    required this.mirror,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (poseResult == null || !poseResult!.isPoseDetected || imageSize == Size.zero) {
      return;
    }

    // Gambar koneksi lebih dulu agar berada di belakang landmark
    _drawConnections(canvas, size);
    _drawLandmarks(canvas, size);
  }

  // Map 1 landmark (normalized) → posisi di canvas, dengan rotasi+mirror+letterbox
  Offset _mapPoint(double nx, double ny, Size canvasSize) {
    final double srcW = imageSize.width;
    final double srcH = imageSize.height;

    // 1) Normalized (0..1) → pixel source (origin: kiri-atas, Y ke bawah)
    double px = nx * srcW;
    double py = ny * srcH;

    // 2) Rotasi koordinat di ruang source (CW) ke ruang ter-rotasi
    // Hasil lebar/tinggi setelah rotasi
    final int rot = ((rotationDegrees % 360) + 360) % 360;
    final double srcRotW = (rot == 0 || rot == 180) ? srcW : srcH;
    final double srcRotH = (rot == 0 || rot == 180) ? srcH : srcW;

    double rx, ry;
    switch (rot) {
      case 90:  // rotate CW 90
        rx = srcH - py;
        ry = px;
        break;
      case 180: // rotate CW 180
        rx = srcW - px;
        ry = srcH - py;
        break;
      case 270: // rotate CW 270
        rx = py;
        ry = srcW - px;
        break;
      case 0:
      default:
        rx = px;
        ry = py;
        break;
    }

    // 3) Mirror horizontal untuk kamera depan (di ruang setelah rotasi)
    if (mirror) {
      rx = srcRotW - rx;
    }

    // 4) Letterbox fit: scale & center ke canvas
    final double sx = canvasSize.width / srcRotW;
    final double sy = canvasSize.height / srcRotH;
    final double scale = sx < sy ? sx : sy;

    final double dstW = srcRotW * scale;
    final double dstH = srcRotH * scale;
    final double dx = (canvasSize.width - dstW) / 2.0;
    final double dy = (canvasSize.height - dstH) / 2.0;

    final double fx = dx + rx * scale;
    final double fy = dy + ry * scale;
    return Offset(fx, fy);
  }

  void _drawConnections(Canvas canvas, Size canvasSize) {
    final connectionPaint = Paint()
      ..color = _connectionColor
      ..strokeWidth = _connectionStrokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..strokeWidth = _connectionStrokeWidth + 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    final connections = _getPoseConnections();
    final landmarks = poseResult!.landmarks;

    for (final connection in connections) {
      final a = landmarks[connection.start];
      final b = landmarks[connection.end];
      if (a == null || b == null) continue;

      final p1 = _mapPoint(a.x, a.y, canvasSize);
      final p2 = _mapPoint(b.x, b.y, canvasSize);

      canvas.drawLine(p1, p2, shadowPaint);
      canvas.drawLine(p1, p2, connectionPaint);
    }
  }

  void _drawLandmarks(Canvas canvas, Size canvasSize) {
    final landmarks = poseResult!.landmarks;

    for (final entry in landmarks.entries) {
      final type = entry.key;
      final lm = entry.value;

      final point = _mapPoint(lm.x, lm.y, canvasSize);
      final color = _getLandmarkColor(type);
      final radius = _isJointLandmark(type) ? _jointRadius : _landmarkRadius;

      final shadowPaint = Paint()..color = Colors.black.withOpacity(0.5);
      final landmarkPaint = Paint()..color = color;
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawCircle(Offset(point.dx + 1, point.dy + 1), radius, shadowPaint);
      canvas.drawCircle(point, radius, landmarkPaint);
      canvas.drawCircle(point, radius, borderPaint);
    }
  }

  Color _getLandmarkColor(PoseLandmarkType type) {
    switch (type) {
    // Face
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

    // Torso
      case PoseLandmarkType.leftShoulder:
      case PoseLandmarkType.rightShoulder:
      case PoseLandmarkType.leftHip:
      case PoseLandmarkType.rightHip:
        return _torsoColor;

    // Left arm
      case PoseLandmarkType.leftElbow:
      case PoseLandmarkType.leftWrist:
      case PoseLandmarkType.leftPinky:
      case PoseLandmarkType.leftIndex:
      case PoseLandmarkType.leftThumb:
        return _leftArmColor;

    // Right arm
      case PoseLandmarkType.rightElbow:
      case PoseLandmarkType.rightWrist:
      case PoseLandmarkType.rightPinky:
      case PoseLandmarkType.rightIndex:
      case PoseLandmarkType.rightThumb:
        return _rightArmColor;

    // Left leg
      case PoseLandmarkType.leftKnee:
      case PoseLandmarkType.leftAnkle:
      case PoseLandmarkType.leftHeel:
      case PoseLandmarkType.leftFootIndex:
        return _leftLegColor;

    // Right leg
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
      // Face
      PoseConnection(PoseLandmarkType.leftEye, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.rightEye, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.leftEar, PoseLandmarkType.leftEye),
      PoseConnection(PoseLandmarkType.rightEar, PoseLandmarkType.rightEye),
      PoseConnection(PoseLandmarkType.mouthLeft, PoseLandmarkType.nose),
      PoseConnection(PoseLandmarkType.mouthRight, PoseLandmarkType.nose),

      // Torso
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder),
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip),
      PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip),
      PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip),

      // Left arm
      PoseConnection(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow),
      PoseConnection(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftThumb),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftIndex),
      PoseConnection(PoseLandmarkType.leftWrist, PoseLandmarkType.leftPinky),

      // Right arm
      PoseConnection(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow),
      PoseConnection(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightThumb),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightIndex),
      PoseConnection(PoseLandmarkType.rightWrist, PoseLandmarkType.rightPinky),

      // Left leg
      PoseConnection(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee),
      PoseConnection(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle),
      PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel),
      PoseConnection(PoseLandmarkType.leftAnkle, PoseLandmarkType.leftFootIndex),

      // Right leg
      PoseConnection(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee),
      PoseConnection(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle),
      PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel),
      PoseConnection(PoseLandmarkType.rightAnkle, PoseLandmarkType.rightFootIndex),
    ];
  }

  @override
  bool shouldRepaint(covariant PoseRiggingPainter old) {
    return old.poseResult != poseResult ||
        old.imageSize != imageSize ||
        old.rotationDegrees != rotationDegrees ||
        old.mirror != mirror;
  }
}

class PoseConnection {
  final PoseLandmarkType start;
  final PoseLandmarkType end;
  PoseConnection(this.start, this.end);
}