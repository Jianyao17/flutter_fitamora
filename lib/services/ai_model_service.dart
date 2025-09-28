import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';

// Kumpulan landmark untuk setiap model agar terorganisir
class AIModelLandmarks {
  static const plank = [
    PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee, PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle, PoseLandmarkType.leftHeel, PoseLandmarkType.rightHeel,
    PoseLandmarkType.leftFootIndex, PoseLandmarkType.rightFootIndex
  ];

  static const jumpingJacks = [
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
    PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
  ];

  static const cobraStretch = [
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
  ];

  static const seatedSideBends = [
    PoseLandmarkType.nose, PoseLandmarkType.leftEar, PoseLandmarkType.rightEar,
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip
  ];

  static const seatedTorsoTwist = [
    PoseLandmarkType.nose, PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow, PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip
  ];

  static const seatedForwardStretch = [
    PoseLandmarkType.nose, PoseLandmarkType.leftEar, PoseLandmarkType.rightEar,
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip
  ];

  // Landmark untuk Seated Row
  static const seatedRow = [
    PoseLandmarkType.nose, PoseLandmarkType.leftEar, PoseLandmarkType.rightEar,
    PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip, PoseLandmarkType.rightHip
  ];
}


class AIModelService {
  AIModelService._();
  static final AIModelService I = AIModelService._();
  bool _isInitialized = false;

  // Interpreter yang sudah ada
  Interpreter? _plankInterpreter;
  Interpreter? _jjInterpreter;
  Interpreter? _cobraInterpreter;
  Interpreter? _sideBendsInterpreter;
  Interpreter? _torsoTwistInterpreter;
  Interpreter? _forwardStretchInterpreter;

  // Interpreter untuk model baru
  Interpreter? _seatedRowInterpreter;

  List<double>? _plankScalerMean;
  List<double>? _plankScalerScale;

  Future<void> loadModels() async {
    if (_isInitialized) {
      print("AI Models already initialized.");
      return;
    }
    try {
      print("Loading AI models...");

      _plankInterpreter = await _loadModel('plank_model.tflite');
      _jjInterpreter = await _loadModel('jumpingjack.tflite');
      _cobraInterpreter = await _loadModel('cobrastretch.tflite');
      _sideBendsInterpreter = await _loadModel('seated_side_bends.tflite');
      _torsoTwistInterpreter = await _loadModel('seated_torso_twist.tflite');
      _forwardStretchInterpreter = await _loadModel('seated_forward_stretch.tflite');
      _seatedRowInterpreter = await _loadModel('seatedrow.tflite');

      await _loadPlankScalerParams();

      print("✅ All AI Models loaded successfully");
      _isInitialized = true;
    } catch (e) {
      print("❌ Error loading AI models: $e");
    }
  }

  Future<Interpreter?> _loadModel(String assetName) async {
    try {
      final interpreter = await Interpreter.fromAsset('assets/models/$assetName');
      print("✓ Model '$assetName' loaded.");
      return interpreter;
    } catch (e) {
      print("⚠ Failed to load model '$assetName': $e");
      return null;
    }
  }

  Future<void> _loadPlankScalerParams() async {
    final jsonString = await rootBundle.loadString('assets/models/plank_scaler_params.json');
    final params = json.decode(jsonString);
    _plankScalerMean = (params['mean'] as List?)?.map((e) => (e as num).toDouble()).toList();
    _plankScalerScale = (params['scale'] as List?)?.map((e) => (e as num).toDouble()).toList();
  }

  List<double> _extractKeypoints(PoseDetectionResult pose, List<PoseLandmarkType> landmarkTypes) {
    final keypoints = <double>[];
    for (final type in landmarkTypes) {
      final lm = pose.landmarks[type];
      keypoints.addAll(lm != null ? [lm.x, lm.y, lm.z, lm.visibility] : [0.0, 0.0, 0.0, 0.0]);
    }
    return keypoints;
  }

  Map<String, dynamic> _runInference(List<double> input, Interpreter? interpreter) {
    if (interpreter == null) {
      return {'label': null, 'confidence': 0.0, 'message': 'Model not loaded'};
    }
    try {
      final outputShape = interpreter.getOutputTensor(0).shape;
      final output = List.filled(outputShape.reduce((a, b) => a * b), 0.0).reshape(outputShape);

      interpreter.run([input], output);

      final probabilities = output[0].cast<double>();
      double confidence = 0.0;
      int label = 0;

      if (probabilities.length > 1) {
        confidence = probabilities.reduce((max, e) => e > max ? e : max);
        label = probabilities.indexOf(confidence);
      } else {
        final val = probabilities.isNotEmpty ? probabilities[0] : 0.0;
        label = val >= 0.5 ? 1 : 0;
        confidence = label == 1 ? val : 1.0 - val;
      }
      return {'label': label, 'confidence': confidence, 'message': 'Success'};
    } catch (e) {
      return {'label': null, 'confidence': 0.0, 'message': 'Prediction error: $e'};
    }
  }

  // ==================== FUNGSI PREDIKSI PER LATIHAN ====================

  Map<String, dynamic> predictPlankForm(PoseDetectionResult pose) {
    if (_plankInterpreter == null || _plankScalerMean == null || _plankScalerScale == null) {
      return {'status': 'Unknown', 'confidence': 0.0, 'message': 'Plank model/scaler not loaded'};
    }
    final keypoints = _extractKeypoints(pose, AIModelLandmarks.plank);
    if (keypoints.length != _plankScalerMean!.length) {
      return {'status': 'Error', 'confidence': 0.0, 'message': 'Invalid keypoint count'};
    }
    final scaledInput = List<double>.generate(keypoints.length,
            (i) => (keypoints[i] - _plankScalerMean![i]) / _plankScalerScale![i]);
    final result = _runInference(scaledInput, _plankInterpreter);
    const statusMap = {0: 'Correct', 1: 'High back', 2: 'Low back'};
    return {
      'status': statusMap[result['label']] ?? 'Unknown',
      'confidence': result['confidence'],
      'message': result['message']
    };
  }

  Map<String, dynamic> predictJumpingJacks(PoseDetectionResult pose) {
    final input = _extractKeypoints(pose, AIModelLandmarks.jumpingJacks);
    return _runInference(input, _jjInterpreter);
  }

  Map<String, dynamic> predictCobraStretch(PoseDetectionResult pose) {
    final input = _extractKeypoints(pose, AIModelLandmarks.cobraStretch);
    return _runInference(input, _cobraInterpreter);
  }

  Map<String, dynamic> predictSeatedSideBends(PoseDetectionResult pose) {
    final input = _extractKeypoints(pose, AIModelLandmarks.seatedSideBends);
    return _runInference(input, _sideBendsInterpreter);
  }

  Map<String, dynamic> predictSeatedTorsoTwist(PoseDetectionResult pose) {
    final input = _extractKeypoints(pose, AIModelLandmarks.seatedTorsoTwist);
    return _runInference(input, _torsoTwistInterpreter);
  }

  Map<String, dynamic> predictSeatedForwardStretch(PoseDetectionResult pose) {
    final input = _extractKeypoints(pose, AIModelLandmarks.seatedForwardStretch);
    return _runInference(input, _forwardStretchInterpreter);
  }

  // Fungsi prediksi baru untuk Seated Row
  Map<String, dynamic> predictSeatedRow(PoseDetectionResult pose) {
    // Untuk Seated Row, AI memberikan feedback kualitatif, bukan hanya biner.
    // Kita akan memetakan output prediksi (misal: 0.0 - 1.0) ke pesan feedback.
    final result = _runInference(_extractKeypoints(pose, AIModelLandmarks.seatedRow), _seatedRowInterpreter);

    if (result['label'] == null) {
      return {'feedback': 'AI Coach sedang belajar gerakan Anda...', 'score': 0.0};
    }

    // Ambil confidence sebagai skor mentah (0.0 - 1.0)
    final score = result['confidence'] as double;
    String feedback;

    if (score > 0.9) {
      feedback = "🏆 Teknik sempurna! ROM dan postur excellent!";
    } else if (score > 0.8) {
      feedback = "✨ Gerakan sangat baik! Pertahankan konsistensi";
    } else if (score > 0.65) {
      feedback = "👍 Good form! Fokus pada full range of motion";
    } else if (score > 0.5) {
      feedback = "⚠️ Perlu perbaikan: Cek postur punggung dan ROM";
    } else {
      feedback = "📚 Teknik perlu diperbaiki: Pelan-pelan, fokus form";
    }

    return {'feedback': feedback, 'score': score};
  }
}

extension ReshapeList<T> on List<T> {
  List<dynamic> reshape(List<int> shape) {
    if (shape.isEmpty) return this;
    int size = shape.reduce((a, b) => a * b);
    if (length != size) throw Exception('List size must match shape size');

    List<dynamic> reshaped = this;
    for (int dim in shape.reversed.skip(1)) {
      reshaped = List.generate(reshaped.length ~/ dim,
              (i) => reshaped.sublist(i * dim, (i + 1) * dim));
    }
    return reshaped;
  }
}