// services/ai_model_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

class AIModelService {
  AIModelService._();
  static final AIModelService I = AIModelService._();
  bool _isInitialized = false;

  Interpreter? _plankInterpreter;
  Interpreter? _jjInterpreter;
  Interpreter? _cobraInterpreter;

  List<double>? _plankScalerMean;
  List<double>? _plankScalerScale;

  Future<void> loadModels() async
  {
    if (_isInitialized)
    {
      print("AI Models already initialized.");
      return;
    }
    try {
      print(" Loading AI models...");

      // Load models dengan error handling
      _plankInterpreter = await Interpreter.fromAsset('assets/models/plank_model.tflite');
      _jjInterpreter = await Interpreter.fromAsset('assets/models/jumpingjack.tflite');
      _cobraInterpreter = await Interpreter.fromAsset('assets/models/cobrastretch.tflite');

      // Load scaler parameters
      await _loadPlankScalerParams();

      print("✅ AI Models loaded successfully");
      _isInitialized = true;
    } catch (e) {
      print("❌ Error loading AI models: $e");
      // Jangan throw error, biarkan app tetap jalan
    }
  }

  Future<void> _loadPlankScalerParams() async
  {
    final jsonString = await rootBundle.loadString('assets/models/plank_scaler_params.json');
    final params = json.decode(jsonString);
    _plankScalerMean = (params['mean'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList() ?? <double>[];
    _plankScalerScale = (params['scale'] as List?)
        ?.map((e) => (e as num).toDouble())
        .toList() ?? <double>[];
  }

  // Generic keypoint extractor
  List<double> _extractKeypoints(PoseDetectionResult pose, List<PoseLandmarkType> landmarkTypes) {
    final keypoints = <double>[];
    for (final type in landmarkTypes) {
      final lm = pose.landmarks[type];
      keypoints.addAll(lm != null ? [lm.x, lm.y, lm.z, lm.visibility] : [0.0, 0.0, 0.0, 0.0]);
    }
    return keypoints;
  }

  // Generic prediction function
  Map<String, dynamic> _runInference(List<double> input, Interpreter? interpreter) {
    if (interpreter == null) {
      return {'label': null, 'confidence': 0.0, 'message': 'Model not loaded'};
    }

    try {
      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;

      // Perbaiki input formatting
      final inputArray = [input];
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0);

      interpreter.run(inputArray, output);

      // Perbaiki output processing
      final probabilities = output.cast<double>();
      double confidence = 0.0;
      int label = 0;

      if (probabilities.length > 1) {
        for (int i = 0; i < probabilities.length; i++) {
          if (probabilities[i] > confidence) {
            confidence = probabilities[i];
            label = i;
          }
        }
      } else {
        final val = probabilities[0];
        label = val >= 0.5 ? 1 : 0;
        confidence = label == 1 ? val : 1.0 - val;
      }

      return {'label': label, 'confidence': confidence, 'message': 'Success'};
    } catch (e) {
      return {'label': null, 'confidence': 0.0, 'message': 'Prediction error: $e'};
    }
  }

  // Implementasi scaling yang lebih akurat
  Map<String, dynamic> _runInferenceWithScaling(List<double> input, Interpreter? interpreter) {
    if (interpreter == null || _plankScalerMean == null || _plankScalerScale == null) {
      return {'label': null, 'confidence': 0.0, 'message': 'Model/scaler not loaded'};
    }

    // Pastikan input length sesuai dengan scaler
    if (input.length != _plankScalerMean!.length) {
      return {'label': null, 'confidence': 0.0, 'message': 'Input size mismatch'};
    }

    // Apply scaling (StandardScaler formula: (x - mean) / scale)
    final scaledInput = <double>[];
    for (int i = 0; i < input.length; i++) {
      scaledInput.add((input[i] - _plankScalerMean![i]) / _plankScalerScale![i]);
    }

    // Run inference
    return _runInference(scaledInput, interpreter);
  }

  // ==================== PLANK ====================
  Map<String, dynamic> predictPlankForm(PoseDetectionResult pose) {
    if (_plankInterpreter == null || _plankScalerMean == null) {
      return {'status': 'Unknown', 'confidence': 0.0, 'message': 'Plank model/scaler not loaded'};
    }

    final landmarkTypes = [
      PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle, PoseLandmarkType.leftHeel, PoseLandmarkType.rightHeel,
      PoseLandmarkType.leftFootIndex, PoseLandmarkType.rightFootIndex
    ];

    try {
      // Validasi input
      if (!pose.isPoseDetected) {
        return {'status': 'Unknown', 'confidence': 0.0, 'message': 'No pose detected'};
      }

      // Extract keypoints dengan validasi
      final keypoints = _extractKeypoints(pose, landmarkTypes);
      if (keypoints.length != _plankScalerMean!.length) {
        return {'status': 'Error', 'confidence': 0.0, 'message': 'Invalid keypoint count'};
      }

      // Run prediction dengan error handling
      final result = _runInferenceWithScaling(keypoints, _plankInterpreter);

      // Validasi hasil
      if (result['label'] == null) {
        return {'status': 'Error', 'confidence': 0.0, 'message': result['message']};
      }

      return result;
    } catch (e) {
      return {'status': 'Error', 'confidence': 0.0, 'message': 'Prediction failed: $e'};
    }
  }

  // ==================== JUMPING JACKS ====================
  Map<String, dynamic> predictJumpingJacks(PoseDetectionResult pose) {
    final landmarkTypes = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
    ];
    final input = _extractKeypoints(pose, landmarkTypes);
    return _runInference(input, _jjInterpreter);
  }

  // ==================== COBRA STRETCH ====================
  Map<String, dynamic> predictCobraStretch(PoseDetectionResult pose) {
    final landmarkTypes = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
    ];
    final input = _extractKeypoints(pose, landmarkTypes);
    return _runInference(input, _cobraInterpreter);
  }
}

extension ListExtension<T> on List<T> {
  List<List<T>> reshape(List<int> shape) {
    if (shape.length != 2) throw ArgumentError('Only 2D reshape supported');
    final rows = shape[0];
    final cols = shape[1];
    final result = <List<T>>[];
    for (int i = 0; i < rows; i++) {
      result.add(sublist(i * cols, (i + 1) * cols));
    }
    return result;
  }
}