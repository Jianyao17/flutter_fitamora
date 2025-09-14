// services/realtime_exercise_service.dart

import 'dart:async';
import 'dart:math';

import '../models/exercise/exercise_type.dart';
import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';
import 'ai_model_service.dart'; // Import service AI
import 'pose_detection_service.dart';

class RealtimeExerciseService {
  RealtimeExerciseService._();
  static final RealtimeExerciseService I = RealtimeExerciseService._();

  final _out = StreamController<ProcessedExerciseFrame>.broadcast();
  StreamSubscription<PoseDetectionResult>? _sub;
  Exercise _exercise = Exercise.create(ExerciseType.jumpingJacks);

  Stream<ProcessedExerciseFrame> get stream => _out.stream;
  Exercise get current => _exercise;

  Future<void> start({ExerciseType exerciseType = ExerciseType.jumpingJacks}) async
  {
    await AIModelService.I.loadModels(); // Pastikan model dimuat
    _exercise = Exercise.create(exerciseType);
    _sub ??= PoseDetectionService.poseStream.listen(_onPose);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }

  void switchExercise(ExerciseType type) {
    _exercise = Exercise.create(type);
  }

  void resetExercise() {
    _exercise.reset();
  }

  void _onPose(PoseDetectionResult pose) {
    _exercise.updateElapsedTime();
    if (_exercise.isTargetReached && !_exercise.completed) {
      _exercise.completed = true;
      _exercise.feedback = "${_exercise.name} selesai!";
    }

    if (!_exercise.completed) {
      _exercise = _processExercise(pose, _exercise);
    }

    _out.add(ProcessedExerciseFrame(
      pose: pose,
      exercise: _exercise,
      fps: 0.0,
      inferenceMs: pose.inferenceTimeMs,
      isPoseDetected: pose.isPoseDetected,
    ));
  }

  // ==================== LOGIKA DETEKSI ====================

  static bool _validateKeypoints(PoseDetectionResult pose, List<PoseLandmarkType> req, {double minConf = 0.4})
  {
    if (!pose.isPoseDetected) return false;
    int validCount = req.where((p) => pose.landmarks[p] != null && pose.landmarks[p]!.visibility >= minConf).length;
    final requiredValid = max(1, (req.length * 0.7).floor());
    return validCount >= requiredValid;
  }

  static double _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c)
  {
    if (a == null || b == null || c == null) return 180.0;
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360 - angle;
    return angle;
  }

  static String _getPoseQuality(PoseDetectionResult pose) {
    if (!pose.isPoseDetected) return "Posisi tidak terdeteksi - masuk ke dalam frame kamera";
    int visible = pose.landmarks.values.where((lm) => lm.visibility > 0.5).length;
    double confidence = pose.landmarks.isNotEmpty ? visible / pose.landmarks.length : 0.0;
    if (confidence < 0.3) return "Posisi sangat tidak jelas - pastikan seluruh tubuh terlihat";
    if (confidence < 0.5) return "Posisi kurang jelas - perbaiki pencahayaan atau posisi";
    return "Posisi jelas - siap untuk exercise!";
  }

  static Exercise _processExercise(PoseDetectionResult pose, Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.jumpingJacks:
        return _processJumpingJacks(pose, exercise);
      case ExerciseType.plank:
        return _processPlank(pose, exercise);
      case ExerciseType.cobraStretch:
        return _processCobraStretch(pose, exercise);
    }
  }

  // ==================== JUMPING JACKS (ENHANCED) ====================
  static Exercise _processJumpingJacks(PoseDetectionResult pose, Exercise exercise) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist, PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle
    ];
    if (!_validateKeypoints(pose, req)) {
      exercise.feedback = "Posisi lebih jelas";
      exercise.isCorrect = false;
      return exercise;
    }

    final landmarks = pose.landmarks;
    final feetDistance = (landmarks[PoseLandmarkType.leftAnkle]!.x - landmarks[PoseLandmarkType.rightAnkle]!.x).abs();
    final avgWristY = (landmarks[PoseLandmarkType.leftWrist]!.y + landmarks[PoseLandmarkType.rightWrist]!.y) / 2;
    final avgShoulderY = (landmarks[PoseLandmarkType.leftShoulder]!.y + landmarks[PoseLandmarkType.rightShoulder]!.y) / 2;

    final isStartingPosition = feetDistance < 0.08 && avgWristY > avgShoulderY * 1.1;
    final isOpenPosition = feetDistance > 0.15 && avgWristY < avgShoulderY * 0.85;

    // Integrasi AI
    final prediction = AIModelService.I.predictJumpingJacks(pose);
    if (prediction['label'] != null) {
      final aiText = prediction['label'] == 1 ? "Correct" : "Wrong";
      exercise.aiFeedback = "AI: $aiText (${prediction['confidence'].toStringAsFixed(2)})";
    }

    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isStartingPosition) {
          exercise.feedback = "Siap! Lompat buka kaki dan angkat tangan";
          exercise.state = ExerciseState.jjReady;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Berdiri tegak, kaki rapat, tangan di samping";
          exercise.isCorrect = false;
        }
        break;
      case ExerciseState.jjReady:
        if (isOpenPosition) {
          exercise.feedback = "Bagus! Kembali ke posisi awal";
          exercise.state = ExerciseState.jjOpen;
          exercise.isCorrect = true;
        } else if (!isStartingPosition) {
          exercise.feedback = "Lompat: kaki terbuka + tangan ke atas";
          exercise.isCorrect = false;
        }
        break;
      case ExerciseState.jjOpen:
        if (isStartingPosition) {
          exercise.count++;
          exercise.feedback = "Rep ${exercise.count}!";
          exercise.state = ExerciseState.jjReady;
          exercise.isCorrect = true;
        } else if (!isOpenPosition) {
          exercise.feedback = "Kembali ke posisi awal";
          exercise.isCorrect = false;
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }
    return exercise;
  }

  // ==================== PLANK (AI-POWERED) ====================
  static Exercise _processPlank(PoseDetectionResult pose, Exercise exercise) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip, PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftElbow, PoseLandmarkType.rightElbow
    ];
    if (!_validateKeypoints(pose, req, minConf: 0.4)) {
      exercise.feedback = "Posisi lebih jelas - pastikan tangan dan tubuh terlihat";
      exercise.isCorrect = false;
      exercise.aiFormStatus = "Unknown";
      exercise.aiFeedback = "Pose tidak jelas untuk analisis AI";
      if (exercise.isHolding) exercise.isHolding = false; // Jeda timer
      return exercise;
    }

    final lm = pose.landmarks;
    final avgShoulderY = (lm[PoseLandmarkType.leftShoulder]!.y + lm[PoseLandmarkType.rightShoulder]!.y) / 2;
    final avgHipY = (lm[PoseLandmarkType.leftHip]!.y + lm[PoseLandmarkType.rightHip]!.y) / 2;
    final avgWristY = (lm[PoseLandmarkType.leftWrist]!.y + lm[PoseLandmarkType.rightWrist]!.y) / 2;

    // Validasi posisi plank yang lebih ketat
    final shoulderHipAlignment = (avgShoulderY - avgHipY).abs() < 0.05; // Toleransi lebih kecil
    final handsBelowShoulders = avgWristY > avgShoulderY; // Tangan harus di bawah bahu
    final bodyHorizontal = avgHipY > avgShoulderY; // Pinggul harus di bawah bahu (posisi horizontal)

    // Validasi sudut lengan (harus lurus untuk plank)
    final leftArmAngle = _calculateAngle(lm[PoseLandmarkType.leftShoulder], lm[PoseLandmarkType.leftElbow], lm[PoseLandmarkType.leftWrist]);
    final rightArmAngle = _calculateAngle(lm[PoseLandmarkType.rightShoulder], lm[PoseLandmarkType.rightElbow], lm[PoseLandmarkType.rightWrist]);
    final armsStraight = leftArmAngle > 150 && rightArmAngle > 150; // Lengan harus hampir lurus

    // Validasi tambahan: pastikan tidak dalam posisi berdiri
    final leftKneeY = lm[PoseLandmarkType.leftKnee]?.y ?? 0.0;
    final rightKneeY = lm[PoseLandmarkType.rightKnee]?.y ?? 0.0;
    final avgKneeY = (leftKneeY + rightKneeY) / 2;
    final notStanding = avgKneeY > avgHipY; // Lutut harus di bawah pinggul (tidak berdiri)

    // Validasi jarak tangan-bahu yang wajar untuk plank
    final leftHandShoulderDistance = (lm[PoseLandmarkType.leftWrist]!.x - lm[PoseLandmarkType.leftShoulder]!.x).abs();
    final rightHandShoulderDistance = (lm[PoseLandmarkType.rightWrist]!.x - lm[PoseLandmarkType.rightShoulder]!.x).abs();
    final handsAtShoulderWidth = leftHandShoulderDistance < 0.3 && rightHandShoulderDistance < 0.3;

    final isPlankPosition = shoulderHipAlignment && handsBelowShoulders && bodyHorizontal &&
        armsStraight && notStanding && handsAtShoulderWidth;

    void updateAIFeedback() {
      final prediction = AIModelService.I.predictPlankForm(pose);
      exercise.aiFormStatus = prediction['status'];
      exercise.aiConfidence = prediction['confidence'];
      exercise.aiFeedback = prediction['message'];
    }

    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isPlankPosition) {
          exercise.feedback = "Siap! Tahan posisi plank";
          exercise.state = ExerciseState.holding;
          exercise.startTime = DateTime.now();
          exercise.isHolding = true;
          exercise.isCorrect = true;
          updateAIFeedback();
        } else {
          // Berikan feedback yang lebih spesifik berdasarkan kondisi yang tidak terpenuhi
          if (!notStanding) {
            exercise.feedback = "Posisi berdiri terdeteksi - masuk ke posisi plank";
          } else if (!shoulderHipAlignment) {
            exercise.feedback = "Badan harus lurus - bahu dan pinggul sejajar";
          } else if (!handsBelowShoulders) {
            exercise.feedback = "Tangan harus di bawah bahu - posisi push-up";
          } else if (!bodyHorizontal) {
            exercise.feedback = "Badan harus horizontal - pinggul di bawah bahu";
          } else if (!armsStraight) {
            exercise.feedback = "Lengan harus lurus - seperti posisi push-up";
          } else if (!handsAtShoulderWidth) {
            exercise.feedback = "Tangan selebar bahu - posisi plank yang benar";
          } else {
            exercise.feedback = "Posisi plank: tangan selebar bahu, tubuh lurus";
          }
          exercise.isCorrect = false;
        }
        break;
      case ExerciseState.holding:
        if (isPlankPosition) {
          exercise.isHolding = true;
          if (exercise.startTime == null) exercise.startTime = DateTime.now();
          updateAIFeedback();

          final remaining = (exercise.targetTimeSec - exercise.elapsedSec).clamp(0.0, exercise.targetTimeSec);
          switch (exercise.aiFormStatus) {
            case "High back":
              exercise.feedback = "Tahan! ${remaining.toStringAsFixed(1)}s - TURUNKAN PINGGUL!";
              break;
            case "Low back":
              exercise.feedback = "Tahan! ${remaining.toStringAsFixed(1)}s - ANGKAT PINGGUL!";
              break;
            case "Correct":
              exercise.feedback = "Tahan! ${remaining.toStringAsFixed(1)}s - FORM SEMPURNA!";
              break;
            default:
              exercise.feedback = "Tahan plank! ${remaining.toStringAsFixed(1)}s";
          }
          exercise.isCorrect = true;
        } else {
          // Berikan feedback spesifik saat form rusak
          if (!notStanding) {
            exercise.feedback = "Form rusak! Posisi berdiri terdeteksi - kembali ke plank";
          } else if (!shoulderHipAlignment) {
            exercise.feedback = "Form rusak! Badan harus lurus - bahu dan pinggul sejajar";
          } else if (!handsBelowShoulders) {
            exercise.feedback = "Form rusak! Tangan harus di bawah bahu";
          } else if (!bodyHorizontal) {
            exercise.feedback = "Form rusak! Badan harus horizontal";
          } else if (!armsStraight) {
            exercise.feedback = "Form rusak! Lengan harus lurus";
          } else if (!handsAtShoulderWidth) {
            exercise.feedback = "Form rusak! Tangan selebar bahu";
          } else {
            exercise.feedback = "Pertahankan posisi plank!";
          }
          exercise.isCorrect = false;
          exercise.isHolding = false;
          exercise.aiFormStatus = "Unknown";
          exercise.aiFeedback = "Form rusak - kembali ke posisi plank";
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }
    return exercise;
  }

  // ==================== COBRA STRETCH (ENHANCED) ====================
  static Exercise _processCobraStretch(PoseDetectionResult pose, Exercise exercise) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip
    ];
    if (!_validateKeypoints(pose, req, minConf: 0.4)) {
      exercise.feedback = "Posisi lebih jelas - tunjukkan tubuh bagian atas";
      exercise.isCorrect = false;
      if (exercise.isHolding) exercise.isHolding = false;
      return exercise;
    }

    final lm = pose.landmarks;
    final avgShoulderY = (lm[PoseLandmarkType.leftShoulder]!.y + lm[PoseLandmarkType.rightShoulder]!.y) / 2;
    final avgHipY = (lm[PoseLandmarkType.leftHip]!.y + lm[PoseLandmarkType.rightHip]!.y) / 2;

    final isLyingFlat = avgHipY > avgShoulderY * 1.05;
    final isStartingPosition = isLyingFlat && avgShoulderY > avgHipY * 0.95;

    final chestLifted = avgShoulderY < avgHipY * 0.85;
    final leftArmAngle = _calculateAngle(lm[PoseLandmarkType.leftShoulder], lm[PoseLandmarkType.leftElbow], lm[PoseLandmarkType.leftWrist]);
    final rightArmAngle = _calculateAngle(lm[PoseLandmarkType.rightShoulder], lm[PoseLandmarkType.rightElbow], lm[PoseLandmarkType.rightWrist]);
    final avgArmAngle = (leftArmAngle + rightArmAngle) / 2.0;
    final armsBentProperly = avgArmAngle > 120 && avgArmAngle < 160;
    final isPerfectCobra = chestLifted && armsBentProperly && isLyingFlat;

    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isStartingPosition) {
          exercise.feedback = "Siap! Angkat dada dengan tangan";
          exercise.state = ExerciseState.readyToLift;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Berbaring tengkurap dulu";
          exercise.isCorrect = false;
        }
        break;
      case ExerciseState.readyToLift:
        if (isPerfectCobra) {
          exercise.feedback = "Sempurna! Timer mulai";
          exercise.state = ExerciseState.stretching;
          exercise.isCorrect = true;
          if (!exercise.isHolding) {
            exercise.startTime = DateTime.now();
            exercise.isHolding = true;
          }
        } else if (!isStartingPosition) {
          exercise.feedback = "Angkat dada perlahan, jaga form";
          exercise.isCorrect = false;
        }
        break;
      case ExerciseState.stretching:
        if (isPerfectCobra) {
          exercise.isHolding = true;
          if(exercise.startTime == null) exercise.startTime = DateTime.now();
          final remaining = (exercise.targetTimeSec - exercise.elapsedSec).clamp(0.0, exercise.targetTimeSec);
          exercise.feedback = "Tahan cobra! ${remaining.toStringAsFixed(1)}s";
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Form berubah! Perbaiki posisi cobra";
          exercise.isCorrect = false;
          exercise.isHolding = false;
          exercise.state = ExerciseState.readyToLift;
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }
    return exercise;
  }
}