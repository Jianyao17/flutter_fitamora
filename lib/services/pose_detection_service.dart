import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image/image.dart' as img;

import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

enum RunMode { IMAGE, VIDEO, LIVE_STREAM }

class PoseDetectionService
{
  static const MethodChannel _methodChannel = MethodChannel("com.example.fitamora/method");
  static const EventChannel _poseEventChannel = EventChannel("com.example.fitamora/event");

  static RunMode _runningMode = RunMode.IMAGE;

  static StreamSubscription? _poseSubscription;
  static final StreamController<PoseDetectionResult> _poseStreamController = StreamController<PoseDetectionResult>.broadcast();

  /// ID Texture untuk widget Texture
  static int? _textureId;
  static Size? _previewSize;

  /// Stream hasil deteksi pose realtime
  static Stream<PoseDetectionResult> get poseStream => _poseStreamController.stream;

  /// Mode operasi (IMAGE/VIDEO/LIVE_STREAM)
  static RunMode get runningMode => _runningMode;

  /// ID Texture untuk widget Texture
  static int? get textureId => _textureId;

  /// Ukuran preview kamera dari native
  static Size? get previewSize => _previewSize;


  static Future<void> initialize({RunMode runningMode = RunMode.LIVE_STREAM}) async
  {
    try {
      if (await requestCameraPermission())
      {
        _runningMode = runningMode;
        await _methodChannel.invokeMethod("initialize",
            { "runningMode": runningMode.name, });
      } else {
        throw Exception("Camera permission denied");
      }
    } catch (e) {
      print("Failed to initialize: $e");
      rethrow;
    }
  }

  static Future<bool> requestCameraPermission() async
  {
    var status = await Permission.camera.status;
    if (!status.isGranted)
    { status = await Permission.camera.request(); }

    return status.isGranted;
  }

  /// Start native camera and get texture ID
  static Future<void> startCamera({bool useFrontCamera = true}) async
  {
    try {
      final result = await _methodChannel
          .invokeMethod<Map<dynamic, dynamic>>("startNativeCamera",
            { "useFrontCamera": useFrontCamera, });

      if (result != null) {
        _textureId = result["textureId"] as int?;
        final width = result["previewWidth"] as double?;
        final height = result["previewHeight"] as double?;

        if (width != null && height != null) {
          _previewSize = Size(width, height);
        }
      }

    } catch (e) {
      print("Failed to start native camera: $e");
      rethrow;
    }
  }

  /// Stop native camera
  static Future<void> stopCamera() async
  {
    try {
      await _methodChannel.invokeMethod("stopNativeCamera");
      _textureId = null;
      _previewSize = null;
    } catch (e) {
      print("Failed to stop native camera: $e");
      rethrow;
    }
  }

  /// Switch between front and back camera
  static Future<bool> switchCamera() async
  {
    try {
      final result = await _methodChannel.invokeMethod("switchCamera");
      return result["isFrontCamera"] as bool;
    } catch (e) {
      print("Failed to switch camera: $e");
      rethrow;
    }
  }

  /// Check if camera is running
  static Future<bool> isCameraRunning() async
  {
    try {
      return await _methodChannel.invokeMethod("isCameraRunning") as bool;
    } catch (e) {
      print("Failed to check camera status: $e");
      return false;
    }
  }

  /// Start listening to pose detection results
  static void startPoseListening()
  {
    _poseSubscription ??=
        _poseEventChannel
            .receiveBroadcastStream()
            .listen((event)
        {
          if (event is Map) {
            final parsed = _parseResult(event.cast<String, dynamic>());
            _poseStreamController.add(parsed);
          }
        },
          onError: (e) => print("Pose stream error: $e"),
        );
  }

  /// Stop listening to all streams
  static void stopListening()
  {
    _poseSubscription?.cancel();
    _poseSubscription = null;
  }

  /// Dispose all resources
  static void dispose()
  {
    stopListening();
    _poseStreamController.close();
  }

  /// Detect pose from image file
  static Future<PoseDetectionResult> detectImage(String path) async
  {
    try {
      final result = await _methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        "detectImage", { "path": path },
      );
      if (result == null) return PoseDetectionResult.empty(0);
      return _parseResult(result.cast<String, dynamic>());
    } catch (e) {
      print("Failed to detect image: $e");
      return PoseDetectionResult.empty(0);
    }
  }

  /// Detect pose from CameraImage stream
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

  /// Parse hasil deteksi pose dari native
  static PoseDetectionResult _parseResult(Map<String, dynamic> map)
  {
    final List<dynamic> rawLandmarks = map["landmarks"] ?? [];
    final landmarks = <PoseLandmarkType, PoseLandmark>{};

    for (int i = 0; i < rawLandmarks.length; i++) {
      if (i >= PoseLandmarkType.values.length) break;
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