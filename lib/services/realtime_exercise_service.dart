import 'dart:async';
import 'dart:collection';
import 'dart:math';

import '../models/exercise/exercise_type.dart';
import '../models/pose_mediapipe/pose_detection_result.dart';
import '../models/pose_mediapipe/pose_landmark.dart';
import '../models/pose_mediapipe/pose_landmark_type.dart';
import 'ai_model_service.dart';
import 'pose_detection_service.dart';

class RealtimeExerciseService {
  RealtimeExerciseService._();
  static final RealtimeExerciseService I = RealtimeExerciseService._();

  final _out = StreamController<ProcessedExerciseFrame>.broadcast();
  StreamSubscription<PoseDetectionResult>? _sub;
  Exercise _exercise = Exercise.create(ExerciseType.jumpingJacks);

  Stream<ProcessedExerciseFrame> get stream => _out.stream;
  Exercise get current => _exercise;

  Future<void> start({ExerciseType exerciseType = ExerciseType.jumpingJacks}) async {
    await AIModelService.I.loadModels();
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

  // ==================== LOGIKA UTAMA & HELPERS ====================

  static Exercise _processExercise(PoseDetectionResult pose, Exercise exercise) {
    switch (exercise.type) {
      case ExerciseType.jumpingJacks:
        return _processJumpingJacks(pose, exercise);
      case ExerciseType.plank:
        return _processPlank(pose, exercise);
      case ExerciseType.cobraStretch:
        return _processCobraStretch(pose, exercise);
      case ExerciseType.seatedSideBends:
        return _processSeatedSideBends(pose, exercise);
      case ExerciseType.seatedTorsoTwist:
        return _processSeatedTorsoTwist(pose, exercise);
      case ExerciseType.seatedForwardStretch:
        return _processSeatedForwardStretch(pose, exercise);
      case ExerciseType.seatedRow:
        return _processSeatedRow(pose, exercise as SeatedRowExercise);
    }
  }

  static bool _validateKeypoints(PoseDetectionResult pose, List<PoseLandmarkType> req, {double minConf = 0.4}) {
    if (!pose.isPoseDetected) return false;
    int validCount = req.where((p) => pose.landmarks[p] != null && pose.landmarks[p]!.visibility >= minConf).length;
    final requiredValid = max(1, (req.length * 0.7).floor());
    return validCount >= requiredValid;
  }

  static double _calculateAngle(PoseLandmark? a, PoseLandmark? b, PoseLandmark? c) {
    if (a == null || b == null || c == null) return 180.0;
    final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / pi).abs();
    if (angle > 180.0) angle = 360 - angle;
    return angle;
  }

  static void _appendAIFeedback(Exercise exercise, Map<String, dynamic> prediction) {
    if (prediction['label'] != null) {
      final aiText = prediction['label'] == 1 ? "OK" : "Fix Form";
      final confidence = (prediction['confidence'] as double).toStringAsFixed(2);
      exercise.aiFeedback = "AI: $aiText ($confidence)";
      exercise.feedback = "${exercise.feedback} | ${exercise.aiFeedback}";
    }
  }

  // ==================== LOGIKA SEATED ROW (BARU) ====================

  static Map<String, PoseLandmark?> _getDominantSide(Map<PoseLandmarkType, PoseLandmark> lms) {
    final lVis = (lms[PoseLandmarkType.leftShoulder]?.visibility ?? 0) +
        (lms[PoseLandmarkType.leftElbow]?.visibility ?? 0) +
        (lms[PoseLandmarkType.leftWrist]?.visibility ?? 0);
    final rVis = (lms[PoseLandmarkType.rightShoulder]?.visibility ?? 0) +
        (lms[PoseLandmarkType.rightElbow]?.visibility ?? 0) +
        (lms[PoseLandmarkType.rightWrist]?.visibility ?? 0);

    if (lVis > rVis) {
      return {
        'shoulder': lms[PoseLandmarkType.leftShoulder],
        'elbow': lms[PoseLandmarkType.leftElbow],
        'wrist': lms[PoseLandmarkType.leftWrist],
        'hip': lms[PoseLandmarkType.leftHip],
        'ear': lms[PoseLandmarkType.leftEar],
      };
    }
    return {
      'shoulder': lms[PoseLandmarkType.rightShoulder],
      'elbow': lms[PoseLandmarkType.rightElbow],
      'wrist': lms[PoseLandmarkType.rightWrist],
      'hip': lms[PoseLandmarkType.rightHip],
      'ear': lms[PoseLandmarkType.rightEar],
    };
  }

  static String _detectMovementDirection(double currentAngle, Queue<double> angleHistory) {
    if (angleHistory.length < 5) return 'none';

    final recent = angleHistory.toList().sublist(angleHistory.length - 5);
    int decreasing = 0;
    int increasing = 0;

    for (int i = 1; i < recent.length; i++) {
      if (recent[i] < recent[i-1] - 2) decreasing++;
      else if (recent[i] > recent[i-1] + 2) increasing++;
    }

    if (decreasing >= 3) return 'pulling';
    if (increasing >= 3) return 'returning';
    return 'none';
  }

  static Exercise _processSeatedRow(PoseDetectionResult pose, SeatedRowExercise exercise) {
    final req = AIModelLandmarks.seatedRow;
    if (!_validateKeypoints(pose, req, minConf: 0.3)) {
      exercise.feedback = "Duduk menyamping & pastikan seluruh badan atas terlihat";
      exercise.isCorrect = false;
      return exercise;
    }

    final dominantSide = _getDominantSide(pose.landmarks);
    final shoulder = dominantSide['shoulder'];
    final elbow = dominantSide['elbow'];
    final wrist = dominantSide['wrist'];
    final hip = dominantSide['hip'];
    final ear = dominantSide['ear'];

    if (shoulder == null || elbow == null || wrist == null || hip == null || ear == null) {
      exercise.feedback = "Sisi tubuh tidak terdeteksi dengan jelas";
      exercise.isCorrect = false;
      return exercise;
    }

    // --- Analisis Biomekanik ---
    final elbowAngle = _calculateAngle(shoulder, elbow, wrist);
    final spineAngle = _calculateAngle(ear, shoulder, hip);
    exercise.addAngleToHistory(elbowAngle);

    // --- Analisis Postur ---
    String postureFeedback = '';
    if (spineAngle < 160) {
      postureFeedback = "Punggung terlalu bungkuk!";
      exercise.isCorrect = false;
    } else {
      postureFeedback = "Punggung lurus, bagus!";
      exercise.isCorrect = true;
    }

    // --- Analisis Gerakan (State Machine) ---
    const minElbowAngle = 75.0;
    const maxElbowAngle = 145.0;
    const requiredStableFrames = 3;
    final minRepDuration = Duration(milliseconds: 1500);

    exercise.movementDirection = _detectMovementDirection(elbowAngle, exercise.angleHistory);

    // Deteksi Fase Tarik (Pull)
    if (exercise.movementDirection == 'pulling' && elbowAngle <= minElbowAngle + 20) {
      if (!exercise.pullDetected && !exercise.repInProgress) {
        exercise.repInProgress = true;
        exercise.pullDetected = true;
        exercise.state = ExerciseState.srPulling;
        exercise.feedback = "Tarik! Kontraksikan punggung";
        exercise.lastStateChange = DateTime.now();
      }
    }

    // Deteksi Fase Kembali (Return)
    if (exercise.movementDirection == 'returning' && elbowAngle >= maxElbowAngle - 20) {
      if (exercise.pullDetected && !exercise.returnDetected) {
        exercise.state = ExerciseState.srReturning;
        exercise.returnDetected = true;
        exercise.feedback = "Kembali perlahan...";
      }
    }

    // Reset jika di antara fase
    if (elbowAngle > minElbowAngle + 20 && elbowAngle < maxElbowAngle - 20) {
      exercise.state = ExerciseState.srTransitioning;
    }

    // --- Penghitungan Repetisi ---
    final now = DateTime.now();
    if (exercise.lastRepTime != null && now.difference(exercise.lastRepTime!) < minRepDuration) {
      // Abaikan jika repetisi terlalu cepat
    } else if (exercise.pullDetected && exercise.returnDetected) {
      // Cek ROM
      final recentAngles = exercise.angleHistory.toList().sublist(max(0, exercise.angleHistory.length - 15));
      final rom = recentAngles.reduce(max) - recentAngles.reduce(min);

      if (rom >= 35) {
        exercise.count++;
        exercise.feedback = "Rep ${exercise.count}!";
        exercise.lastRepTime = now;

        // Reset state untuk repetisi berikutnya
        exercise.pullDetected = false;
        exercise.returnDetected = false;
        exercise.repInProgress = false;
        exercise.state = ExerciseState.waiting;
      } else {
        exercise.feedback = "Rentang gerak kurang! Tarik lebih dalam.";
        // Soft reset
        if (exercise.lastStateChange != null && now.difference(exercise.lastStateChange!) > Duration(seconds: 3)) {
          exercise.pullDetected = false;
          exercise.returnDetected = false;
          exercise.repInProgress = false;
        }
      }
    }

    // Gabungkan feedback postur jika relevan
    if (!exercise.isCorrect) {
      exercise.feedback = postureFeedback;
    }

    // AI Feedback (Opsional)
    final aiPrediction = AIModelService.I.predictSeatedRow(pose);
    exercise.aiFeedback = aiPrediction['feedback'];

    return exercise;
  }


  // ==================== LATIHAN LAMA (TIDAK BERUBAH) ====================
  //<COLLAPSED_PREVIOUS_CODE>
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
          if (exercise.isTargetReached) {
            exercise.completed = true;
          } else {
            exercise.feedback = "Rep ${exercise.count}!";
            exercise.state = ExerciseState.jjReady;
          }
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
      if (exercise.isHolding) exercise.isHolding = false;
      return exercise;
    }

    final lm = pose.landmarks;
    final avgShoulderY = (lm[PoseLandmarkType.leftShoulder]!.y + lm[PoseLandmarkType.rightShoulder]!.y) / 2;
    final avgHipY = (lm[PoseLandmarkType.leftHip]!.y + lm[PoseLandmarkType.rightHip]!.y) / 2;
    final avgWristY = (lm[PoseLandmarkType.leftWrist]!.y + lm[PoseLandmarkType.rightWrist]!.y) / 2;

    final shoulderHipAlignment = (avgShoulderY - avgHipY).abs() < 0.05;
    final handsBelowShoulders = avgWristY > avgShoulderY;
    final bodyHorizontal = avgHipY > avgShoulderY;
    final leftArmAngle = _calculateAngle(lm[PoseLandmarkType.leftShoulder], lm[PoseLandmarkType.leftElbow], lm[PoseLandmarkType.leftWrist]);
    final rightArmAngle = _calculateAngle(lm[PoseLandmarkType.rightShoulder], lm[PoseLandmarkType.rightElbow], lm[PoseLandmarkType.rightWrist]);
    final armsStraight = leftArmAngle > 150 && rightArmAngle > 150;
    final leftKneeY = lm[PoseLandmarkType.leftKnee]?.y ?? 0.0;
    final rightKneeY = lm[PoseLandmarkType.rightKnee]?.y ?? 0.0;
    final avgKneeY = (leftKneeY + rightKneeY) / 2;
    final notStanding = avgKneeY > avgHipY;
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
          exercise.feedback = "Posisi plank: tangan selebar bahu, tubuh lurus";
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
          exercise.feedback = "Pertahankan posisi plank!";
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

  static Exercise _processSeatedSideBends(PoseDetectionResult pose, Exercise exercise) {
    final req = AIModelLandmarks.seatedSideBends;
    if (!_validateKeypoints(pose, req, minConf: 0.2)) {
      exercise.feedback = "Posisi lebih jelas - pastikan badan dan kepala terlihat";
      exercise.isCorrect = false;
      return exercise;
    }

    final lm = pose.landmarks;
    final lSh = lm[PoseLandmarkType.leftShoulder]!;
    final rSh = lm[PoseLandmarkType.rightShoulder]!;
    final lEar = lm[PoseLandmarkType.leftEar]!;
    final rEar = lm[PoseLandmarkType.rightEar]!;
    final shoulderHeightDiff = lSh.y - rSh.y;
    final earHeightDiff = lEar.y - rEar.y;
    const bendThreshold = 0.04;
    const uprightThreshold = 0.04;
    final leftBend = shoulderHeightDiff < -bendThreshold && earHeightDiff < -bendThreshold;
    final rightBend = shoulderHeightDiff > bendThreshold && earHeightDiff > bendThreshold;
    final upright = shoulderHeightDiff.abs() < uprightThreshold && earHeightDiff.abs() < uprightThreshold;

    switch (exercise.state) {
      case ExerciseState.waiting:
        exercise.feedback = "Condongkan kepala & bahu ke KIRI";
        if (leftBend) {
          exercise.state = ExerciseState.ssbLeftBend;
          exercise.feedback = "✓ Kiri bagus! Kembali TEGAK";
        }
        break;
      case ExerciseState.ssbLeftBend:
        exercise.feedback = "Kembali TEGAK dulu";
        if (upright) {
          exercise.state = ExerciseState.ssbRightWaiting;
          exercise.feedback = "✓ Tegak! Sekarang condong ke KANAN";
        }
        break;
      case ExerciseState.ssbRightWaiting:
        exercise.feedback = "Condongkan kepala & bahu ke KANAN";
        if (rightBend) {
          exercise.state = ExerciseState.ssbRightBend;
          exercise.feedback = "✓ Kanan bagus! Kembali TEGAK";
        }
        break;
      case ExerciseState.ssbRightBend:
        exercise.feedback = "Kembali TEGAK";
        if (upright) {
          exercise.count++;
          if (exercise.isTargetReached) {
            exercise.completed = true;
          } else {
            exercise.feedback = "✓ Rep ${exercise.count}! Condong KIRI lagi";
            exercise.state = ExerciseState.waiting;
          }
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }

    final prediction = AIModelService.I.predictSeatedSideBends(pose);
    _appendAIFeedback(exercise, prediction);

    return exercise;
  }

  static Exercise _processSeatedTorsoTwist(PoseDetectionResult pose, Exercise exercise) {
    final req = AIModelLandmarks.seatedTorsoTwist;
    if (!_validateKeypoints(pose, req, minConf: 0.2)) {
      exercise.feedback = "Posisi lebih jelas - bahu dan siku terlihat";
      exercise.isCorrect = false;
      return exercise;
    }

    final lm = pose.landmarks;
    final lSh = lm[PoseLandmarkType.leftShoulder]!;
    final rSh = lm[PoseLandmarkType.rightShoulder]!;
    final lHp = lm[PoseLandmarkType.leftHip]!;
    final rHp = lm[PoseLandmarkType.rightHip]!;

    final hipCenterX = (lHp.x + rHp.x) / 2;
    final shoulderCenterX = (lSh.x + rSh.x) / 2;
    final shoulderSeparation = (lSh.x - rSh.x).abs();
    const twistThreshold = 0.03;
    const separationThreshold = 0.08;
    const uprightThreshold = 0.015;
    final frontFacing = shoulderSeparation > separationThreshold;

    if (!frontFacing) {
      exercise.feedback = "Hadap DEPAN kamera (bahu terpisah)";
      exercise.isCorrect = false;
      return exercise;
    }

    final leftTwist = (shoulderCenterX - hipCenterX) < -twistThreshold;
    final rightTwist = (shoulderCenterX - hipCenterX) > twistThreshold;
    final upright = (shoulderCenterX - hipCenterX).abs() < uprightThreshold;

    switch (exercise.state) {
      case ExerciseState.waiting:
        exercise.feedback = "Putar bahu ke KIRI";
        if (leftTwist) {
          exercise.state = ExerciseState.sttLeftTwist;
          exercise.feedback = "✓ Twist kiri! Kembali TENGAH";
        }
        break;
      case ExerciseState.sttLeftTwist:
        exercise.feedback = "Kembali ke TENGAH";
        if (upright) {
          exercise.state = ExerciseState.sttRightWaiting;
          exercise.feedback = "✓ Tengah! Sekarang putar ke KANAN";
        }
        break;
      case ExerciseState.sttRightWaiting:
        exercise.feedback = "Putar bahu ke KANAN";
        if (rightTwist) {
          exercise.state = ExerciseState.sttRightTwist;
          exercise.feedback = "✓ Twist kanan! Kembali TENGAH";
        }
        break;
      case ExerciseState.sttRightTwist:
        exercise.feedback = "Kembali TENGAH";
        if (upright) {
          exercise.count++;
          if (exercise.isTargetReached) {
            exercise.completed = true;
          } else {
            exercise.feedback = "✓ Rep ${exercise.count}! Twist KIRI lagi";
            exercise.state = ExerciseState.waiting;
          }
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }

    final prediction = AIModelService.I.predictSeatedTorsoTwist(pose);
    _appendAIFeedback(exercise, prediction);

    return exercise;
  }

  static Exercise _processSeatedForwardStretch(PoseDetectionResult pose, Exercise exercise) {
    final req = AIModelLandmarks.seatedForwardStretch;
    if (!_validateKeypoints(pose, req, minConf: 0.2)) {
      exercise.feedback = "Posisi lebih jelas - kepala dan bahu terlihat";
      exercise.isCorrect = false;
      return exercise;
    }

    final lm = pose.landmarks;
    final nose = lm[PoseLandmarkType.nose]!;
    final lSh = lm[PoseLandmarkType.leftShoulder]!;
    final rSh = lm[PoseLandmarkType.rightShoulder]!;
    final lEar = lm[PoseLandmarkType.leftEar]!;
    final rEar = lm[PoseLandmarkType.rightEar]!;
    final shoulderAvgY = (lSh.y + rSh.y) / 2;
    final earAvgY = (lEar.y + rEar.y) / 2;
    final noseBelowShoulder = nose.y - shoulderAvgY;
    final earBelowShoulder = earAvgY - shoulderAvgY;
    const forwardThreshold = 0.05;
    const uprightThreshold = 0.02;
    final forwardStretch = noseBelowShoulder > forwardThreshold && earBelowShoulder > forwardThreshold;
    final upright = noseBelowShoulder < uprightThreshold && earBelowShoulder < uprightThreshold;

    switch (exercise.state) {
      case ExerciseState.waiting:
        exercise.feedback = "Condongkan KEPALA ke bawah/depan";
        if (forwardStretch) {
          exercise.state = ExerciseState.sfsForward;
          exercise.feedback = "✓ Condong bagus! Kembali TEGAK";
        }
        break;
      case ExerciseState.sfsForward:
        exercise.feedback = "Kembali TEGAK (kepala naik)";
        if (upright) {
          exercise.count++;
          if (exercise.isTargetReached) {
            exercise.completed = true;
          } else {
            exercise.feedback = "✓ Rep ${exercise.count}! Condong ke bawah lagi";
            exercise.state = ExerciseState.waiting;
          }
        }
        break;
      default:
        exercise.state = ExerciseState.waiting;
    }

    final prediction = AIModelService.I.predictSeatedForwardStretch(pose);
    _appendAIFeedback(exercise, prediction);

    return exercise;
  }
}