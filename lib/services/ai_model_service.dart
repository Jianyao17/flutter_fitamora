// services/ai_model_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

class AIModelService {
  AIModelService._();
  static final AIModelService I = AIModelService._();

  Interpreter? _plankInterpreter;
  Interpreter? _jjInterpreter;
  Interpreter? _cobraInterpreter;

  List<double>? _plankScalerMean;
  List<double>? _plankScalerScale;

  Future<void> loadModels() async {
    try {
      _plankInterpreter = await Interpreter.fromAsset('assets/models/plank_model.tflite');
      _jjInterpreter = await Interpreter.fromAsset('assets/models/jumpingjack.tflite');
      _cobraInterpreter = await Interpreter.fromAsset('assets/models/cobrastretch.tflite');
      await _loadPlankScalerParams();
      print("✓ AI Models and Scaler loaded successfully");
    } catch (e) {
      print("❌ Error loading AI models: $e");
    }
  }

  Future<void> _loadPlankScalerParams() async {
    final jsonString = await rootBundle.loadString('assets/models/plank_scaler_params.json');
    final params = json.decode(jsonString);
    _plankScalerMean = (params['mean'] as List).map((e) => e as double).toList();
    _plankScalerScale = (params['scale'] as List).map((e) => e as double).toList();
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
      // Dapatkan bentuk input dan output dari model
      final inputShape = interpreter.getInputTensor(0).shape;
      final outputShape = interpreter.getOutputTensor(0).shape;

      final inputArray = [input];
      var output = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);

      interpreter.run(inputArray, output);

      final probabilities = output[0] as List<double>;
      double confidence = 0.0;
      int label = 0;

      if (probabilities.length > 1) { // Multi-class classification
        for (int i = 0; i < probabilities.length; i++) {
          if (probabilities[i] > confidence) {
            confidence = probabilities[i];
            label = i;
          }
        }
      } else { // Binary classification
        final val = probabilities[0];
        label = val >= 0.5 ? 1 : 0;
        confidence = label == 1 ? val : 1.0 - val;
      }

      return {'label': label, 'confidence': confidence, 'message': 'Success'};
    } catch (e) {
      return {'label': null, 'confidence': 0.0, 'message': 'Prediction error: $e'};
    }
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

    var input = _extractKeypoints(pose, landmarkTypes);

    if (input.length != _plankScalerMean!.length) return {'status': 'Error', 'confidence': 0.0, 'message': 'Input size mismatch'};

    for (int i = 0; i < input.length; i++) {
      input[i] = (input[i] - _plankScalerMean![i]) / _plankScalerScale![i];
    }

    final result = _runInference(input, _plankInterpreter);
    if(result['label'] == null) return {'status': 'Error', 'confidence': 0.0, 'message': result['message']};

    String status = "Unknown";
    switch (result['label']) {
      case 0: status = "Correct"; break; // C
      case 1: status = "High back"; break; // H
      case 2: status = "Low back"; break; // L
    }

    return {'status': status, 'confidence': result['confidence'], 'message': 'AI Confidence: ${result['confidence'].toStringAsFixed(2)}'};
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