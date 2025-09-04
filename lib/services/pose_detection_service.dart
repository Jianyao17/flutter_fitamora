import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/pose_detection_result.dart';
import '../models/pose_landmark.dart';
import '../models/pose_landmark_type.dart';
import '../models/pose_realtime_data.dart';

/// Service untuk deteksi pose menggunakan model TFLite MediaPipe
class PoseDetectionService {
  static const String _poseDetectorModelPath = 'assets/models/pose_detector.tflite';
  static const String _poseLandmarksModelPath = 'assets/models/pose_landmarks_detector.tflite';

  Interpreter? _poseDetectorInterpreter;
  Interpreter? _poseLandmarksInterpreter;

  bool _isInitialized = false;
  bool _isProcessing = false;

  // Dimensi input untuk model detektor pose.
  static const int _detectorInputWidth = 224;
  static const int _detectorInputHeight = 224;

  // Dimensi input untuk model detektor landmark.
  static const int _landmarksInputWidth = 256;
  static const int _landmarksInputHeight = 256;

  static const int _inputChannels = 3;

  // Ambang batas kepercayaan untuk deteksi.
  static const double _confidenceThreshold = 0.5;
  static const double _visibilityThreshold = 0.5;
  static const double _presenceThreshold = 0.5;

  // Stream controller untuk menyiarkan hasil deteksi secara real-time.
  StreamController<PoseRealtimeData>? _resultStreamController;
  Stream<PoseRealtimeData>? get resultStream => _resultStreamController?.stream;

  /// Menginisialisasi service dengan memuat model TFLite dari assets.
  /// Harus dipanggil sebelum metode deteksi lainnya.
  Future<bool> initialize() async
  {
    try {
      _poseDetectorInterpreter = await Interpreter.fromAsset(_poseDetectorModelPath);
      _poseLandmarksInterpreter = await Interpreter.fromAsset(_poseLandmarksModelPath);

      _resultStreamController = StreamController<PoseRealtimeData>.broadcast();
      _isInitialized = true;
      print('✅ PoseDetectionService initialized successfully');
      return true;
    } catch (e)
    {
      print('❌ Error initializing PoseDetectionService: $e');
      return false;
    }
  }

  /// Memproses `CameraImage` dari stream kamera untuk deteksi pose real-time.
  /// Hasilnya akan disiarkan melalui [resultStream].
  Future<void> detectPoseFromCamera(CameraImage cameraImage) async
  {
    if (!_isInitialized || _isProcessing) return;

    _isProcessing = true;
    final stopwatch = Stopwatch()..start();

    try
    {
      final ui.Image image = await _convertCameraImageToUiImage(cameraImage);
      final result = await _detectPoseInternal(image, stopwatch);
      _resultStreamController?.add(PoseRealtimeData(result: result, image: image));

    } catch (e) {
      print('❌ Error in camera pose detection: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Melakukan deteksi pose pada satu `ui.Image`.
  /// Berguna untuk deteksi pada gambar statis.
  Future<PoseDetectionResult> detectPose(ui.Image image) async
  {
    if (!_isInitialized) {
      throw Exception('PoseDetectionService not initialized. Call initialize() first.');
    }
    final stopwatch = Stopwatch()..start();
    return await _detectPoseInternal(image, stopwatch);
  }

  /// Logika inti untuk pipeline deteksi dua tahap.
  Future<PoseDetectionResult> _detectPoseInternal(ui.Image image, Stopwatch stopwatch) async
  {
    // Tahap 1: Deteksi keberadaan pose.
    final detectorInput = await _preprocessImage(image, _detectorInputWidth, _detectorInputHeight);
    final poseDetection = await _runPoseDetection(detectorInput);

    if (!poseDetection.isPoseDetected)
    {
      return PoseDetectionResult.empty(
        stopwatch.elapsedMilliseconds,
        confidence: poseDetection.confidence,
      );
    }

    // Tahap 2: Ekstraksi landmark dari pose yang terdeteksi.
    final landmarksInput = await _preprocessImage(image, _landmarksInputWidth, _landmarksInputHeight);
    final (landmarks, worldLandmarks) = await _runLandmarksDetection(
      landmarksInput,
      image.width,
      image.height,
    );

    return PoseDetectionResult(
      isPoseDetected: true,
      landmarks: landmarks,
      worldLandmarks: worldLandmarks,
      confidence: poseDetection.confidence,
      boundingBox: poseDetection.boundingBox,
      processingTimeMs: stopwatch.elapsedMilliseconds,
    );
  }

  /// Mengubah, me-resize, dan menormalisasi gambar agar sesuai dengan input model.
  Future<Float32List> _preprocessImage(ui.Image image, int targetWidth, int targetHeight) async
  {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    if (byteData == null) throw Exception('Failed to convert image to bytes');

    final originalImage = img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: byteData.buffer,
      numChannels: 4,
    );

    final resizedImage = img.copyResize(originalImage, width: targetWidth, height: targetHeight);

    // Normalisasi nilai piksel ke rentang [0.0, 1.0] sesuai kebutuhan model MediaPipe.
    final input = Float32List(1 * targetWidth * targetHeight * _inputChannels);
    int pixelIndex = 0;
    for (int y = 0; y < targetHeight; y++) {
      for (int x = 0; x < targetWidth; x++) {
        final pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }
    return input;
  }

  /// Menjalankan model detektor pose untuk menemukan bounding box dan skor keyakinan.
  Future<({
    bool isPoseDetected,
    double confidence,
    Rect? boundingBox})> _runPoseDetection(Float32List inputData) async
  {
    final input = inputData.reshape([1, _detectorInputHeight, _detectorInputWidth, _inputChannels]);

    // Model ini memiliki dua output: bounding box dan skor.
    final detectionTensor = _poseDetectorInterpreter!.getOutputTensor(0);
    final scoreTensor = _poseDetectorInterpreter!.getOutputTensor(1);

    final numDetections = detectionTensor.shape[1];
    final detections = List.filled(detectionTensor.shape.reduce((a, b) => a * b), 0.0)
        .reshape(detectionTensor.shape);
    final scores = List.filled(scoreTensor.shape.reduce((a, b) => a * b), 0.0)
        .reshape(scoreTensor.shape);

    _poseDetectorInterpreter!.runForMultipleInputs([input], {0: detections, 1: scores});

    double maxScore = 0.0;
    int bestIdx = -1;
    for (int i = 0; i < numDetections; i++) {
      final currentScore = scores[0][i][0];
      if (currentScore > maxScore) {
        maxScore = currentScore;
        bestIdx = i;
      }
    }

    final isPoseDetected = maxScore > _confidenceThreshold;
    if (!isPoseDetected) {
      return (isPoseDetected: false, confidence: maxScore, boundingBox: null);
    }

    // Ekstrak dan normalisasi bounding box.
    final detection = detections[0][bestIdx];
    final xCenter = detection[0] / _detectorInputWidth;
    final yCenter = detection[1] / _detectorInputHeight;
    final width = detection[2] / _detectorInputWidth;
    final height = detection[3] / _detectorInputHeight;

    final xMin = (xCenter - width / 2).clamp(0.0, 1.0);
    final yMin = (yCenter - height / 2).clamp(0.0, 1.0);
    final xMax = (xCenter + width / 2).clamp(0.0, 1.0);
    final yMax = (yCenter + height / 2).clamp(0.0, 1.0);

    return (
    isPoseDetected: true,
    confidence: maxScore,
    boundingBox: Rect.fromLTRB(xMin, yMin, xMax, yMax),
    );
  }

  /// Menjalankan model landmark untuk mengekstrak 33 titik pose.
  Future<(Map<PoseLandmarkType, PoseLandmark>, Map<PoseLandmarkType, PoseLandmark>)>
  _runLandmarksDetection(
      Float32List inputData,
      int originalWidth,
      int originalHeight,
      ) async {
    final input = inputData.reshape([1, _landmarksInputHeight, _landmarksInputWidth, _inputChannels]);

    // Siapkan buffer untuk semua output secara dinamis.
    final outputTensors = _poseLandmarksInterpreter!.getOutputTensors();
    final Map<int, Object> outputs = {};
    for (int i = 0; i < outputTensors.length; i++) {
      final tensor = outputTensors[i];
      outputs[i] = List.filled(tensor.shape.reduce((a, b) => a * b), 0.0).reshape(tensor.shape);
    }

    _poseLandmarksInterpreter!.runForMultipleInputs([input], outputs);

    // Cari output yang relevan berdasarkan bentuk (shape)-nya untuk menghindari hardcoding index.
    // Landmark 2D (di layar) biasanya memiliki shape [1, 195].
    // Landmark 3D (dunia nyata) biasanya memiliki shape [1, 117].
    List<double>? poseLandmarksData;
    List<double>? worldLandmarksData;

    for (final output in outputs.values)
    {
      if (output is List)
      {
        final shape = (output as List).shape;
        if (shape.length == 2 && shape[1] == 195)
        { poseLandmarksData = (output[0] as List).cast<double>(); }
        else if (shape.length == 2 && shape[1] == 117)
        { worldLandmarksData = (output[0] as List).cast<double>(); }
      }
    }

    if (poseLandmarksData == null)
    {
      print('❌ Error: Could not find pose landmarks output tensor.');
      return (<PoseLandmarkType, PoseLandmark>{}, <PoseLandmarkType, PoseLandmark>{});
    }

    // Parsing dan denormalisasi data landmark.
    final landmarks = <PoseLandmarkType, PoseLandmark>{};
    const numLandmarks = 33;
    const valuesPerLandmark = 5;

    for (int i = 0; i < numLandmarks; i++)
    {
      final baseIdx = i * valuesPerLandmark;
      final visibility = poseLandmarksData[baseIdx + 3];
      final presence = poseLandmarksData[baseIdx + 4];

      if (visibility > _visibilityThreshold && presence > _presenceThreshold)
      {
        final x = poseLandmarksData[baseIdx] / _landmarksInputWidth * originalWidth;
        final y = poseLandmarksData[baseIdx + 1] / _landmarksInputHeight * originalHeight;
        final z = poseLandmarksData[baseIdx + 2]; // z-depth relatif terhadap pinggul

        landmarks[PoseLandmarkType.values[i]] = PoseLandmark(
            x: x, y: y, z: z, visibility: visibility, presence: presence);
      }
    }

    final worldLandmarks = <PoseLandmarkType, PoseLandmark>{};
    if (worldLandmarksData != null)
    {
      const worldValuesPerLandmark = 3;
      for (int i = 0; i < numLandmarks; i++)
      {
        // Gunakan visibility dan presence dari landmark 2D untuk memfilter landmark 3D.
        if (landmarks.containsKey(PoseLandmarkType.values[i]))
        {
          final baseIdx = i * worldValuesPerLandmark;
          worldLandmarks[PoseLandmarkType.values[i]] = PoseLandmark(
            x: worldLandmarksData[baseIdx],
            y: worldLandmarksData[baseIdx + 1],
            z: worldLandmarksData[baseIdx + 2],
            visibility: landmarks[PoseLandmarkType.values[i]]!.visibility,
            presence: landmarks[PoseLandmarkType.values[i]]!.presence,
          );
        }
      }
    }
    return (landmarks, worldLandmarks);
  }

  /// Konversi CameraImage ke UI Image (dioptimalkan)
  Future<ui.Image> _convertCameraImageToUiImage(CameraImage cameraImage) async
  {
    try {
      final completer = Completer<ui.Image>();
      final plane = cameraImage.planes[0];
      final width = cameraImage.width;
      final height = cameraImage.height;

      // PERBAIKAN: Gunakan format yang sesuai dengan platform
      final format = ui.PixelFormat.rgba8888; // Ubah ke rgba8888

      ui.decodeImageFromPixels(
        plane.bytes, width, height,
        format, (ui.Image image) => completer.complete(image),
      );

      return await completer.future;
    } catch (e)
    {
      print('Error in convertCameraImageToUiImage: $e');
      // Fallback ke metode konversi lama jika diperlukan
      return await _fallbackImageConversion(cameraImage);
    }
  }

  /// Konversi CameraImage ke UI Image
  Future<ui.Image> _fallbackImageConversion(CameraImage cameraImage) async
  {
    late img.Image convertedImage;

    if (cameraImage.format.group == ImageFormatGroup.yuv420) {
      // Handle YUV420 format (most common on Android)
      convertedImage = _convertYUV420ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
      // Handle BGRA8888 format (common on iOS)
      convertedImage = _convertBGRA8888ToImage(cameraImage);
    } else if (cameraImage.format.group == ImageFormatGroup.nv21) {
      // Handle NV21 format
      convertedImage = _convertNV21ToImage(cameraImage);
    } else {
      throw UnsupportedError('Camera format ${cameraImage.format.group} not supported');
    }

    // Convert to UI Image
    final pngBytes = img.encodePng(convertedImage);
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Convert YUV420 to RGB Image
  img.Image _convertYUV420ToImage(CameraImage cameraImage)
  {
    final width = cameraImage.width;
    final height = cameraImage.height;

    final yPlane = cameraImage.planes[0];
    final uPlane = cameraImage.planes[1];
    final vPlane = cameraImage.planes[2];

    final convertedImage = img.Image(width: width, height: height);

    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * yPlane.bytesPerRow + x;
        final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uvPixelStride;

        final yValue = yPlane.bytes[yIndex];
        final uValue = uPlane.bytes[uvIndex];
        final vValue = vPlane.bytes[uvIndex];

        // YUV to RGB conversion
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return convertedImage;
  }

  /// Convert BGRA8888 to RGB Image
  img.Image _convertBGRA8888ToImage(CameraImage cameraImage)
  {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final pixels = cameraImage.planes[0].bytes;

    final convertedImage = img.Image(width: width, height: height);

    for (int i = 0; i < pixels.length; i += 4) {
      final b = pixels[i];
      final g = pixels[i + 1];
      final r = pixels[i + 2];
      final a = pixels[i + 3];

      final pixelIndex = i ~/ 4;
      final x = pixelIndex % width;
      final y = pixelIndex ~/ width;

      convertedImage.setPixelRgba(x, y, r, g, b, a);
    }

    return convertedImage;
  }

  /// Convert NV21 to RGB Image
  img.Image _convertNV21ToImage(CameraImage cameraImage)
  {
    final width = cameraImage.width;
    final height = cameraImage.height;
    final yPlane = cameraImage.planes[0].bytes;
    final uvPlane = cameraImage.planes[1].bytes;

    final convertedImage = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final yIndex = y * width + x;
        final uvIndex = (y ~/ 2) * width + (x ~/ 2) * 2;

        final yValue = yPlane[yIndex];
        final vValue = uvPlane[uvIndex];
        final uValue = uvPlane[uvIndex + 1];

        // YUV to RGB conversion
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344 * (uValue - 128) - 0.714 * (vValue - 128)).clamp(0, 255).toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        convertedImage.setPixelRgb(x, y, r, g, b);
      }
    }

    return convertedImage;
  }

  /// Mendapatkan landmark spesifik
  PoseLandmark? getLandmark(PoseDetectionResult result, PoseLandmarkType type)
  => result.landmarks[type];

  /// Mendapatkan world landmark spesifik
  PoseLandmark? getWorldLandmark(PoseDetectionResult result, PoseLandmarkType type)
  => result.worldLandmarks[type];

  /// Menghitung jarak antara dua landmarks
  double? getDistanceBetweenLandmarks(
      PoseDetectionResult result,
      PoseLandmarkType landmark1,
      PoseLandmarkType landmark2,
      {bool useWorldCoordinates = false}
      )
  {
    final landmarks = useWorldCoordinates ? result.worldLandmarks : result.landmarks;
    final l1 = landmarks[landmark1];
    final l2 = landmarks[landmark2];

    if (l1 == null || l2 == null) return null;

    return math.sqrt(
      (l1.x - l2.x) * (l1.x - l2.x) +
      (l1.y - l2.y) * (l1.y - l2.y) +
      (l1.z - l2.z) * (l1.z - l2.z)
    );
  }

  /// Menghitung sudut antara tiga landmarks
  double? getAngleBetweenLandmarks(
      PoseDetectionResult result,
      PoseLandmarkType point1,
      PoseLandmarkType vertex,
      PoseLandmarkType point2,
      {bool useWorldCoordinates = false}
      )
  {
    final landmarks = useWorldCoordinates ? result.worldLandmarks : result.landmarks;
    final p1 = landmarks[point1];
    final v = landmarks[vertex];
    final p2 = landmarks[point2];

    if (p1 == null || v == null || p2 == null) return null;

    final v1x = p1.x - v.x;
    final v1y = p1.y - v.y;
    final v1z = p1.z - v.z;

    final v2x = p2.x - v.x;
    final v2y = p2.y - v.y;
    final v2z = p2.z - v.z;

    final dot = v1x * v2x + v1y * v2y + v1z * v2z;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z);

    if (mag1 == 0 || mag2 == 0) return null;

    final cosAngle = dot / (mag1 * mag2);
    return math.acos(cosAngle.clamp(-1.0, 1.0)) * (180 / math.pi); // Konversi ke derajat
  }

  /// Cleanup resources
  void dispose() {
    _poseDetectorInterpreter?.close();
    _poseLandmarksInterpreter?.close();
    _resultStreamController?.close();
    _isInitialized = false;
  }
}