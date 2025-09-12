import 'dart:async';
import 'dart:math';

import '../models/exercise_type.dart';
import '../models/pose_detection_result.dart';
import '../models/pose_landmark.dart';
import '../models/pose_landmark_type.dart';
import 'pose_detection_service.dart';

class RealtimeExerciseService {
  RealtimeExerciseService._();
  static final RealtimeExerciseService I = RealtimeExerciseService._();

  final _out = StreamController<ProcessedExerciseFrame>.broadcast();
  StreamSubscription<PoseDetectionResult>? _sub;
  Exercise _exercise = Exercise.create(ExerciseType.legRaises);

  Stream<ProcessedExerciseFrame> get stream => _out.stream;
  Exercise get current => _exercise;

  Future<void> start({ExerciseType exerciseType = ExerciseType.legRaises}) async {
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
    // Process exercise
    _exercise = _processExercise(pose, _exercise);

    _out.add(ProcessedExerciseFrame(
      pose: pose,
      exercise: _exercise,
      fps: 0.0, // FPS akan dihitung di demo page
      inferenceMs: pose.inferenceTimeMs,
      isPoseDetected: pose.isPoseDetected,
    ));
  }

  // ===== Exercise Detection Logic =====
  static const double _minConfidence = 0.3;
  static const double _poseQualityThreshold = 0.5;

  /// Validasi keypoint dengan confidence threshold
  static bool _validateKeypoints(
    PoseDetectionResult pose, 
    List<PoseLandmarkType> requiredPoints, 
    {double minConf = _minConfidence}
  ) {
    if (!pose.isPoseDetected) return false;
    
    int validCount = 0;
    for (final point in requiredPoints) {
      final landmark = pose.landmarks[point];
      if (landmark != null && landmark.visibility >= minConf) {
        validCount++;
      }
    }
    
    final requiredValid = max(1, (requiredPoints.length * 0.7).floor());
    return validCount >= requiredValid;
  }

  /// Deteksi orientasi tubuh (front/side)
  static String _detectBodyOrientation(PoseDetectionResult pose) {
    if (!pose.isPoseDetected) return 'unknown';
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    
    final availableLandmarks = [
      leftShoulder, rightShoulder, leftHip, rightHip
    ].where((lm) => lm != null && lm.visibility > 0.3).toList();
    
    if (availableLandmarks.length < 2) return 'unknown';
    
    double shoulderDistance = 0.1;
    if (leftShoulder != null && rightShoulder != null && 
        leftShoulder.visibility > 0.3 && rightShoulder.visibility > 0.3) {
      shoulderDistance = (leftShoulder.x - rightShoulder.x).abs();
    }
    
    double hipDistance = shoulderDistance;
    if (leftHip != null && rightHip != null && 
        leftHip.visibility > 0.3 && rightHip.visibility > 0.3) {
      hipDistance = (leftHip.x - rightHip.x).abs();
    }
    
    final avgDistance = (shoulderDistance + hipDistance) / 2.0;
    return avgDistance < 0.08 ? 'side' : 'front';
  }

  /// Hitung sudut antara 3 titik
  static double _calculateAngle(
    PoseLandmark? a,
    PoseLandmark? b, 
    PoseLandmark? c
  ) {
    if (a == null || b == null || c == null) return 180.0;
    
    try {
      final radians = atan2(c.y - b.y, c.x - b.x) - atan2(a.y - b.y, a.x - b.x);
      double angle = (radians * 180.0 / pi).abs();
      
      if (angle > 180.0) {
        angle = 360 - angle;
      }
      
      return angle;
    } catch (e) {
      return 180.0;
    }
  }

  /// Evaluasi kualitas pose
  static String _getPoseQuality(PoseDetectionResult pose) {
    if (!pose.isPoseDetected) {
      return "Posisi tidak terdeteksi - masuk ke dalam frame kamera";
    }
    
    int visibleLandmarks = 0;
    int totalLandmarks = 0;
    
    for (final landmark in pose.landmarks.values) {
      if (landmark.visibility > _poseQualityThreshold) {
        visibleLandmarks++;
      }
      totalLandmarks++;
    }
    
    final poseConfidence = totalLandmarks > 0 ? visibleLandmarks / totalLandmarks : 0.0;
    
    if (poseConfidence < 0.3) {
      return "Posisi sangat tidak jelas - pastikan seluruh tubuh terlihat";
    } else if (poseConfidence < 0.5) {
      return "Posisi kurang jelas - perbaiki pencahayaan atau posisi";
    } else if (poseConfidence < 0.7) {
      return "Posisi cukup jelas - bisa lebih baik";
    } else {
      return "Posisi sangat jelas - siap untuk exercise!";
    }
  }

  /// Proses exercise berdasarkan jenis
  static Exercise _processExercise(PoseDetectionResult pose, Exercise exercise) {
    // Update elapsed time untuk timed exercises
    exercise.updateElapsedTime();
    
    // Check completion
    if (exercise.isTargetReached && !exercise.completed) {
      exercise.completed = true;
      exercise.feedback = "${exercise.name} selesai!";
      return exercise;
    }
    
    // Process berdasarkan jenis exercise
    switch (exercise.type) {
      case ExerciseType.jumpingJacks:
        return _processJumpingJacks(pose, exercise);
      case ExerciseType.russianTwist:
        return _processRussianTwist(pose, exercise);
      case ExerciseType.legRaises:
        return _processLegRaises(pose, exercise);
      case ExerciseType.mountainClimber:
        return _processMountainClimber(pose, exercise);
      case ExerciseType.plank:
        return _processPlank(pose, exercise);
      case ExerciseType.cobraStretch:
        return _processCobraStretch(pose, exercise);
    }
  }

  /// Jumping Jacks Detection
  static Exercise _processJumpingJacks(PoseDetectionResult pose, Exercise exercise) {
    final requiredPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints)) {
      exercise.feedback = _getPoseQuality(pose);
      exercise.isCorrect = false;
      return exercise;
    }
    
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (pose.landmarks[PoseLandmarkType.leftHip]!.y + 
                    pose.landmarks[PoseLandmarkType.rightHip]!.y) / 2;
    
    // Deteksi gerakan tangan naik
    final handsUp = (leftWrist.y < avgShoulderY * 0.8) && (rightWrist.y < avgShoulderY * 0.8);
    final handsDown = (leftWrist.y > avgHipY * 1.1) && (rightWrist.y > avgHipY * 1.1);
    
    // Deteksi gerakan kaki terbuka
    final feetSpread = (leftAnkle.x - rightAnkle.x).abs() > 0.15;
    final feetTogether = (leftAnkle.x - rightAnkle.x).abs() < 0.05;
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (handsDown && feetTogether) {
          exercise.feedback = "Posisi awal benar! Mulai jumping jacks";
          exercise.state = ExerciseState.down;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Berdiri tegak, kaki rapat, tangan di samping";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.down:
        if (handsUp && feetSpread) {
          exercise.feedback = "Bagus! Tangan ke atas, kaki terbuka";
          exercise.state = ExerciseState.up;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Lompat: buka kaki dan angkat tangan ke atas";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.up:
        if (handsDown && feetTogether) {
          exercise.count++;
          exercise.feedback = "Rep ${exercise.count}! Kembali ke posisi awal";
          exercise.state = ExerciseState.down;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Kembali ke posisi awal: kaki rapat, tangan turun";
          exercise.isCorrect = false;
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    return exercise;
  }

  /// Russian Twist Detection
  static Exercise _processRussianTwist(PoseDetectionResult pose, Exercise exercise) {
    final requiredPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints, minConf: 0.25)) {
      exercise.feedback = "Posisi lebih jelas";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Check sitting position
    final isSittingCorrect = avgHipY > avgShoulderY * 1.02;
    if (!isSittingCorrect) {
      exercise.feedback = "Duduk: lutut ditekuk, condong belakang sedikit";
      exercise.isCorrect = false;
      return exercise;
    }
    
    // Calculate shoulder rotation angle
    double shoulderAngle = atan2(
      rightShoulder.y - leftShoulder.y,
      rightShoulder.x - leftShoulder.x
    ) * 180 / pi;
    
    if (shoulderAngle > 90) shoulderAngle -= 180;
    if (shoulderAngle < -90) shoulderAngle += 180;
    
    const twistThreshold = 12.0;
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (shoulderAngle.abs() < twistThreshold * 1.5) {
          exercise.feedback = "Posisi tengah benar! Twist ke kiri dan kanan";
          exercise.state = ExerciseState.center;
        } else {
          exercise.feedback = "Posisi duduk di tengah dulu";
        }
        break;
        
      case ExerciseState.center:
        if (shoulderAngle > twistThreshold) {
          exercise.feedback = "Twist kanan baik! Sekarang ke kiri";
          exercise.state = ExerciseState.rightDeep;
        } else if (shoulderAngle < -twistThreshold) {
          exercise.feedback = "Twist kiri baik! Sekarang ke kanan";
          exercise.state = ExerciseState.leftDeep;
        } else {
          exercise.feedback = "Putar tubuh ke kiri atau kanan";
        }
        break;
        
      case ExerciseState.rightDeep:
        if (shoulderAngle < -twistThreshold) {
          exercise.count++;
          exercise.feedback = "Rep ${exercise.count}! Twist kiri bagus";
          exercise.state = ExerciseState.leftDeep;
        } else if (shoulderAngle.abs() < twistThreshold * 1.5) {
          exercise.feedback = "Lanjutkan twist ke kiri";
          exercise.state = ExerciseState.center;
        } else {
          exercise.feedback = "Twist ke kiri sekarang";
        }
        break;
        
      case ExerciseState.leftDeep:
        if (shoulderAngle > twistThreshold) {
          exercise.count++;
          exercise.feedback = "Rep ${exercise.count}! Twist kanan bagus";
          exercise.state = ExerciseState.rightDeep;
        } else if (shoulderAngle.abs() < twistThreshold * 1.5) {
          exercise.feedback = "Lanjutkan twist ke kanan";
          exercise.state = ExerciseState.center;
        } else {
          exercise.feedback = "Twist ke kanan sekarang";
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    exercise.isCorrect = true;
    return exercise;
  }

  /// Leg Raises Detection
  static Exercise _processLegRaises(PoseDetectionResult pose, Exercise exercise) {
    final orientation = _detectBodyOrientation(pose);
    
    // Hanya izinkan orientasi frontal untuk leg raises
    if (orientation != 'front') {
      exercise.feedback = "Hadap ke kamera (posisi frontal) untuk leg raises";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final requiredPoints = [
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle,
      PoseLandmarkType.rightAnkle,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints, minConf: 0.35)) {
      exercise.feedback = "Posisi lebih jelas - pastikan kedua kaki terlihat jelas";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee]!;
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle]!;
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle]!;
    
    // Check lying position
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    
    bool isLyingDown = true;
    if (leftShoulder != null && rightShoulder != null) {
      final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
      final avgHipY = (leftHip.y + rightHip.y) / 2;
      isLyingDown = avgShoulderY < avgHipY * 1.1;
    }
    
    if (!isLyingDown) {
      exercise.feedback = "Berbaring dulu, hadap kamera, angkat KEDUA kaki bersamaan";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Gunakan ankle jika tersedia, jika tidak gunakan knee
    final leftLegRef = leftAnkle.visibility > 0.4 ? leftAnkle : leftKnee;
    final rightLegRef = rightAnkle.visibility > 0.4 ? rightAnkle : rightKnee;
    
    // Deteksi kedua kaki naik bersamaan
    final leftLegRaised = leftLegRef.y <= avgHipY * 0.92;
    final rightLegRaised = rightLegRef.y <= avgHipY * 0.92;
    final bothLegsRaised = leftLegRaised && rightLegRaised;
    
    final leftLegDown = leftLegRef.y > avgHipY * 1.2;
    final rightLegDown = rightLegRef.y > avgHipY * 1.2;
    final bothLegsDown = leftLegDown && rightLegDown;
    
    // Deteksi gerakan satu kaki (SALAH untuk leg raises)
    final singleLegUp = (leftLegRaised && !rightLegRaised) || (rightLegRaised && !leftLegRaised);
    final singleLegMovement = singleLegUp || ((leftLegDown && !rightLegDown) || (rightLegDown && !leftLegDown));
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (bothLegsDown) {
          exercise.feedback = "Posisi awal benar! Angkat KEDUA kaki bersamaan";
          exercise.state = ExerciseState.down;
          exercise.isCorrect = true;
        } else if (singleLegMovement) {
          exercise.feedback = "SALAH! Angkat KEDUA kaki bersamaan, bukan satu per satu!";
          exercise.isCorrect = false;
        } else {
          exercise.feedback = "Berbaring, turunkan kedua kaki, hadap kamera";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.down:
        if (bothLegsRaised) {
          exercise.feedback = "BENAR! Kedua kaki terangkat bersamaan! Turunkan bersamaan";
          exercise.state = ExerciseState.up;
          exercise.isCorrect = true;
        } else if (singleLegMovement) {
          exercise.feedback = "SALAH! Angkat KEDUA kaki bersamaan, jangan satu per satu!";
          exercise.isCorrect = false;
        } else {
          exercise.feedback = "Angkat kedua kaki lurus ke atas bersamaan";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.up:
        if (bothLegsDown) {
          exercise.count++;
          exercise.feedback = "Rep ${exercise.count}! BENAR - kedua kaki bersamaan!";
          exercise.state = ExerciseState.down;
          exercise.isCorrect = true;
        } else if (singleLegMovement) {
          exercise.feedback = "SALAH! Turunkan KEDUA kaki bersamaan!";
          exercise.isCorrect = false;
        } else {
          exercise.feedback = "Turunkan kedua kaki bersamaan ke posisi awal";
          exercise.isCorrect = false;
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    return exercise;
  }

  /// Mountain Climber Detection
  static Exercise _processMountainClimber(PoseDetectionResult pose, Exercise exercise) {
    final requiredPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee,
      PoseLandmarkType.rightKnee,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints, minConf: 0.3)) {
      exercise.feedback = "Posisi lebih jelas - pastikan lutut terlihat";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee]!;
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee]!;
    
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Check plank position
    final isPlankPosition = (avgShoulderY - avgHipY).abs() < 0.1;
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isPlankPosition) {
          exercise.feedback = "Posisi plank benar! Tarik lutut ke perut bergantian";
          exercise.state = ExerciseState.plank;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Posisi push-up: tangan selebar bahu, tubuh lurus";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.plank:
      case ExerciseState.leftForward:
      case ExerciseState.rightForward:
        if (!isPlankPosition) {
          exercise.feedback = "Pertahankan posisi plank yang benar!";
          exercise.isCorrect = false;
          exercise.state = ExerciseState.waiting;
          return exercise;
        }
        
        // Deteksi lutut ke perut
        final bellyLevel = avgShoulderY + (avgHipY - avgShoulderY) * 0.6;
        final leftKneeToBelly = leftKnee.y < bellyLevel;
        final rightKneeToBelly = rightKnee.y < bellyLevel;
        
        final avgShoulderX = (leftShoulder.x + rightShoulder.x) / 2;
        final leftKneeForward = (leftKnee.x - avgShoulderX).abs() < 0.18;
        final rightKneeForward = (rightKnee.x - avgShoulderX).abs() < 0.18;
        
        final leftKneeProper = leftKneeToBelly && leftKneeForward;
        final rightKneeProper = rightKneeToBelly && rightKneeForward;
        
        final leftKneeBack = leftKnee.y > avgHipY * 0.92;
        final rightKneeBack = rightKnee.y > avgHipY * 0.92;
        
        if (exercise.state == ExerciseState.plank) {
          if (leftKneeProper) {
            exercise.state = ExerciseState.leftForward;
            exercise.feedback = "Lutut kiri ke perut bagus! Ganti kanan";
            exercise.isCorrect = true;
          } else if (rightKneeProper) {
            exercise.state = ExerciseState.rightForward;
            exercise.feedback = "Lutut kanan ke perut bagus! Ganti kiri";
            exercise.isCorrect = true;
          } else {
            exercise.feedback = "Tarik satu lutut ke perut, bergantian";
            exercise.isCorrect = true;
          }
        } else if (exercise.state == ExerciseState.leftForward) {
          if (rightKneeProper && leftKneeBack) {
            exercise.count++;
            exercise.feedback = "Rep ${exercise.count}! Lutut kanan ke perut";
            exercise.state = ExerciseState.rightForward;
            exercise.isCorrect = true;
          } else {
            exercise.feedback = "Tarik lutut kanan ke perut, kembalikan kiri";
            exercise.isCorrect = true;
          }
        } else if (exercise.state == ExerciseState.rightForward) {
          if (leftKneeProper && rightKneeBack) {
            exercise.count++;
            exercise.feedback = "Rep ${exercise.count}! Lutut kiri ke perut";
            exercise.state = ExerciseState.leftForward;
            exercise.isCorrect = true;
          } else {
            exercise.feedback = "Tarik lutut kiri ke perut, kembalikan kanan";
            exercise.isCorrect = true;
          }
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    return exercise;
  }

  /// Plank Detection
  static Exercise _processPlank(PoseDetectionResult pose, Exercise exercise) {
    final requiredPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints, minConf: 0.25)) {
      exercise.feedback = "Posisi lebih jelas - pastikan tangan dan tubuh terlihat";
      exercise.isCorrect = false;
      exercise.aiFormStatus = "Unknown";
      exercise.aiConfidence = 0.0;
      exercise.aiFeedback = "Pose tidak jelas untuk analisis AI";
      return exercise;
    }
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;
    
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Check plank position
    final avgHandY = (leftWrist.y + rightWrist.y) / 2;
    final isPlankPosition = (avgHandY > avgShoulderY * 0.88) && 
                           ((avgShoulderY - avgHipY).abs() < 0.15);
    
    // Check horizontal position
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];
    bool isHorizontal = true;
    
    if (leftAnkle != null && rightAnkle != null && 
        leftAnkle.visibility > 0.2 && rightAnkle.visibility > 0.2) {
      final avgAnkleY = (leftAnkle.y + rightAnkle.y) / 2;
      isHorizontal = avgAnkleY > avgHipY * 1.05;
    }
    
    if (!isHorizontal) {
      exercise.feedback = "Berbaring dulu dalam posisi plank";
      exercise.isCorrect = false;
      return exercise;
    }
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isPlankPosition) {
          exercise.feedback = "Posisi plank benar! Tahan posisi ini";
          exercise.state = ExerciseState.holding;
          exercise.startTime = DateTime.now();
          exercise.isHolding = true;
          exercise.isCorrect = true;
          
          // Simulate AI feedback (in real implementation, this would call AI model)
          exercise.aiFormStatus = "Correct";
          exercise.aiConfidence = 0.85;
          exercise.aiFeedback = "Form plank sempurna!";
        } else {
          exercise.feedback = "Posisi push-up: tangan selebar bahu, tubuh lurus";
          exercise.isCorrect = false;
          exercise.aiFormStatus = "Unknown";
          exercise.aiConfidence = 0.0;
          exercise.aiFeedback = "Belum dalam posisi plank";
        }
        break;
        
      case ExerciseState.holding:
        if (isPlankPosition) {
          final remaining = (exercise.targetTimeSec - exercise.elapsedSec).clamp(0, exercise.targetTimeSec);
          exercise.feedback = "Tahan plank! ${remaining.toStringAsFixed(1)}s tersisa";
          
          // Simulate AI feedback based on form
          if (exercise.elapsedSec > 5) {
            exercise.aiFormStatus = "Correct";
            exercise.aiConfidence = 0.9;
            exercise.aiFeedback = "Form plank sempurna!";
          }
          
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Pertahankan posisi plank yang benar!";
          exercise.isCorrect = false;
          exercise.isHolding = false;
          exercise.aiFormStatus = "Unknown";
          exercise.aiConfidence = 0.0;
          exercise.aiFeedback = "Form rusak - kembali ke posisi plank";
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    return exercise;
  }

  /// Cobra Stretch Detection
  static Exercise _processCobraStretch(PoseDetectionResult pose, Exercise exercise) {
    final requiredPoints = [
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
      PoseLandmarkType.leftWrist,
      PoseLandmarkType.rightWrist,
    ];
    
    if (!_validateKeypoints(pose, requiredPoints, minConf: 0.25)) {
      exercise.feedback = "Posisi lebih jelas - pastikan tangan dan tubuh terlihat";
      exercise.isCorrect = false;
      return exercise;
    }
    
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder]!;
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder]!;
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip]!;
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip]!;
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist]!;
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist]!;
    
    final avgShoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    final avgHipY = (leftHip.y + rightHip.y) / 2;
    
    // Check face down position
    final isFaceDown = avgShoulderY < avgHipY * 1.05;
    if (!isFaceDown) {
      exercise.feedback = "Berbaring tengkurap dulu, tangan di bawah bahu";
      exercise.isCorrect = false;
      return exercise;
    }
    
    // Check hand position
    final avgWristY = (leftWrist.y + rightWrist.y) / 2;
    final handsBelowShoulders = avgWristY > avgShoulderY * 0.95;
    
    // Check chest lifted
    final chestLifted = avgShoulderY < avgHipY * 0.85;
    
    // Check elbow position
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final rightElbow = pose.landmarks[PoseLandmarkType.rightElbow];
    bool elbowsBent = true;
    
    if (leftElbow != null && rightElbow != null && 
        leftElbow.visibility > 0.2 && rightElbow.visibility > 0.2) {
      final avgElbowY = (leftElbow.y + rightElbow.y) / 2;
      elbowsBent = avgElbowY < avgWristY * 1.1;
    }
    
    switch (exercise.state) {
      case ExerciseState.waiting:
        if (isFaceDown && handsBelowShoulders) {
          exercise.feedback = "Posisi awal benar! Angkat dada dengan bantuan tangan";
          exercise.state = ExerciseState.readyToLift;
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Berbaring tengkurap, tangan di bawah bahu";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.readyToLift:
        if (chestLifted && elbowsBent) {
          exercise.feedback = "Cobra position bagus! Tahan posisi ini";
          exercise.state = ExerciseState.stretching;
          exercise.startTime = DateTime.now();
          exercise.isHolding = true;
          exercise.isCorrect = true;
        } else if (isFaceDown && handsBelowShoulders) {
          exercise.feedback = "Angkat dada perlahan dengan bantuan tangan";
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Pertahankan posisi tengkurap dengan tangan di bawah bahu";
          exercise.isCorrect = false;
        }
        break;
        
      case ExerciseState.stretching:
        if (chestLifted && elbowsBent) {
          final remaining = (exercise.targetTimeSec - exercise.elapsedSec).clamp(0, exercise.targetTimeSec);
          exercise.feedback = "Tahan cobra! ${remaining.toStringAsFixed(1)}s tersisa";
          exercise.isCorrect = true;
        } else {
          exercise.feedback = "Pertahankan posisi cobra yang benar!";
          exercise.isCorrect = false;
          exercise.isHolding = false;
        }
        break;
        
      default:
        exercise.state = ExerciseState.waiting;
    }
    
    return exercise;
  }
}
