import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

enum RunMode { IMAGE, VIDEO, LIVE_STREAM }

/// Service untuk komunikasi Flutter ↔ Native (Kotlin)
class PoseDetectionService
{
  static const MethodChannel _methodChannel = MethodChannel("com.example.fitamora/method");
  static const EventChannel _eventChannel = EventChannel("com.example.fitamora/event");

  static StreamSubscription? _subscription;
  static final StreamController<PoseDetectionResult> _poseStreamController = StreamController.broadcast();
  static RunMode _runngingMode = RunMode.IMAGE;

  /// Stream hasil deteksi pose realtime
  static Stream<PoseDetectionResult> get poseStream => _poseStreamController.stream;

  /// Mode operasi (IMAGE/VIDEO/LIVE_STREAM)
  static RunMode get runningMode => _runngingMode;

  /// Start camera di native
  static Future<void> initialize({RunMode runningMode = RunMode.IMAGE}) async
  {
    _runngingMode = runningMode;
    await _methodChannel.invokeMethod("initialize", { "runningMode": runningMode.name } );
  }

  /// Deteksi dari image file (path lokal)
  static Future<PoseDetectionResult> detectImage(String path) async
  {
    final result = await _methodChannel
        .invokeMethod<Map<dynamic, dynamic>>("detectImage", {"path": path} );

    if (result == null) { return PoseDetectionResult.empty(0); }
    return _parseResult(result.cast<String, dynamic>());
  }

  static Future<void> detectImageStream(CameraImage image) async
  {
    try {
      // Konversi YUV_420 dari CameraImage ke byte array JPEG
      final jpegBytes = await _convertYUV420toJPEG(image);
      if (jpegBytes.isNotEmpty)
      {
        // Kirim byte array ke native
        await _methodChannel.invokeMethod('detectImageStream', {'imageBytes': jpegBytes});
      }
    } catch (e) {
      print("Gagal mengirim frame ke native: $e");
    }
  }

  /// Mulai listen event stream (realtime camera)
  static void startListening()
  {
    _subscription ??= _eventChannel
        .receiveBroadcastStream()
        .listen((event)
      {
        if (event is Map) {
          final parsed = _parseResult(event.cast<String, dynamic>());
          _poseStreamController.add(parsed);
        }
      },
      onError: (e) { print("Pose stream error: $e"); },
    );
  }

  static void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  // Konversi YUV_420 ke JPEG
  static Future<Uint8List> _convertYUV420toJPEG(CameraImage image) async
  {
    final yuvImage = img.Image(
        width: image.width,
        height: image.height,
        numChannels: 4 // Anggap sebagai RGBA untuk sementara
    );

    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    final uRowStride = image.planes[1].bytesPerRow;
    final vRowStride = image.planes[2].bytesPerRow;
    final yRowStride = image.planes[0].bytesPerRow;

    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final yIndex = y * yRowStride + x;
        final uvIndex = (y ~/ 2) * uRowStride + (x ~/ 2);

        final yValue = yPlane[yIndex];
        final uValue = uPlane[uvIndex];
        final vValue = vPlane[uvIndex];

        // Konversi YUV ke RGB (rumus standar)
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        yuvImage.setPixelRgba(x, y, r, g, b, 255);
      }
    }

    // Encode gambar yang sudah dikonversi ke format JPEG
    return Uint8List.fromList(img.encodeJpg(yuvImage, quality: 75));
  }

  static PoseDetectionResult _parseResult(Map<String, dynamic> map)
  {
    final List<dynamic> rawLandmarks = map["landmarks"] ?? [];
    final landmarks = <PoseLandmarkType, PoseLandmark>{};

    for (int i = 0; i < rawLandmarks.length; i++)
    {
      final lm = rawLandmarks[i];
      final type = PoseLandmarkType.values[i];

      landmarks[type] = PoseLandmark(
        x: (lm["x"] as num).toDouble(),
        y: (lm["y"] as num).toDouble(),
        z: (lm["z"] as num).toDouble(),
        visibility: (lm["visibility"] as num).toDouble(),
      );
    }

    return PoseDetectionResult(
      isPoseDetected: landmarks.isNotEmpty,
      inferenceTimeMs: (map["inferenceTimeMs"] as num?)?.toInt() ?? 0,
      landmarks: landmarks,
      imageSize: Size(
        (map["imageWidth"] as num?)?.toDouble() ?? 0,
        (map["imageHeight"] as num?)?.toDouble() ?? 0,
      ),
    );
  }
}
