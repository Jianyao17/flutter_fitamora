import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../models/pose_detection_result.dart';
import '../models/pose_landmark_type.dart';

class PoseRiggingPainter extends CustomPainter {
  final PoseDetectionResult? poseResult;
  final Size imageSize;

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
    required this.poseResult,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size)
  {
    if (poseResult == null ||
        !poseResult!.isPoseDetected ||
        imageSize == Size.zero)
    { return; }

    // Menghitung skala untuk menyesuaikan gambar kamera ke layar tanpa distorsi,
    // dengan mempertimbangkan rotasi 90 derajat.
    final double scaleX = size.width / imageSize.height;
    final double scaleY = size.height / imageSize.width;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Menghitung offset untuk memposisikan rigging di tengah layar.
    final double offsetX = (size.width - imageSize.height * scale) / 2;
    final double offsetY = (size.height - imageSize.width * scale) / 2;

    // Gambar koneksi terlebih dahulu agar berada di belakang titik landmark.
    _drawConnections(canvas, scale, offsetX, offsetY);
    _drawLandmarks(canvas, scale, offsetX, offsetY);
  }

  void _drawConnections(Canvas canvas, double scale, double offsetX, double offsetY)
  {
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
      final startLandmark = landmarks[connection.start];
      final endLandmark = landmarks[connection.end];

      if (startLandmark != null && endLandmark != null)
      {
        // Terapkan transformasi yang sama persis seperti pada _drawLandmarks
        final startPoint = Offset(
            (1.0 - startLandmark.y) * imageSize.height * scale + offsetX,
            startLandmark.x * imageSize.width * scale + offsetY);

        final endPoint = Offset(
            (1.0 - endLandmark.y) * imageSize.height * scale + offsetX,
            endLandmark.x * imageSize.width * scale + offsetY);

        // Gambar bayangan dan garis koneksi
        canvas.drawLine(startPoint, endPoint, shadowPaint);
        canvas.drawLine(startPoint, endPoint, connectionPaint);
      }
    }
  }

  void _drawLandmarks(Canvas canvas, double scale, double offsetX, double offsetY)
  {
    for (final entry in poseResult!.landmarks.entries)
    {
      final landmarkType = entry.key;
      final landmark = entry.value;

      // Transformasi koordinat dari image space ke canvas space
      // 1. Koordinat Y dari landmark menjadi sumbu X di layar (rotasi).
      // 2. Gunakan `(1.0 - landmark.y)` untuk efek cermin kamera depan.
      // 3. Koordinat X dari landmark menjadi sumbu Y di layar (rotasi).
      final point = Offset(
        (1.0 - landmark.y) * imageSize.height * scale + offsetX,
        landmark.x * imageSize.width * scale + offsetY,
      );

      final color = _getLandmarkColor(landmarkType);
      final radius = _isJointLandmark(landmarkType) ? _jointRadius : _landmarkRadius;

      // Styling (diambil dari kode Anda)
      final shadowPaint = Paint()..color = Colors.black.withOpacity(0.5);
      final landmarkPaint = Paint()..color = color;
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Gambar bayangan, titik landmark, dan border
      canvas.drawCircle(Offset(point.dx + 1, point.dy + 1), radius, shadowPaint);
      canvas.drawCircle(point, radius, landmarkPaint);
      canvas.drawCircle(point, radius, borderPaint);
    }
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
  bool shouldRepaint(covariant PoseRiggingPainter oldDelegate)
  {
    // Hanya repaint jika data berubah untuk efisiensi
    return oldDelegate.poseResult != poseResult || oldDelegate.imageSize != imageSize;
  }
}

// Helper class untuk mendefinisikan koneksi antar landmarks
class PoseConnection {
  final PoseLandmarkType start;
  final PoseLandmarkType end;

  PoseConnection(this.start, this.end);
}