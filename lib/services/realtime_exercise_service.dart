import 'dart:async';
import 'dart:math';

import '../models/exercise_type.dart';
import '../models/pose_detection_result.dart';
import '../models/pose_landmark_type.dart';
import 'pose_detection_service.dart';

class RealtimeExerciseService {
  RealtimeExerciseService._();
  static final RealtimeExerciseService I = RealtimeExerciseService._();

  final _out = StreamController<ProcessedExerciseFrame>.broadcast();
  StreamSubscription<PoseDetectionResult>? _sub;
  ExerciseType _exercise = ExerciseType.forName('Leg Raises');

  // FPS
  int _frames = 0;
  DateTime _fpsStart = DateTime.now();
  double _fps = 0.0;

  Stream<ProcessedExerciseFrame> get stream => _out.stream;
  ExerciseType get current => _exercise;

  Future<void> start({String exerciseName = 'Leg Raises'}) async {
    _exercise = ExerciseType.forName(exerciseName);
    _resetFps();
    _sub ??= PoseDetectionService.poseStream.listen(_onPose);
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
    _resetFps();
  }

  void switchExercise(String name) {
    _exercise = ExerciseType.forName(name);
  }

  void resetExercise() {
    _exercise = ExerciseType.forName(_exercise.name);
  }

  void _onPose(PoseDetectionResult r) {
    // fps
    _frames++;
    final now = DateTime.now();
    final dt = now.difference(_fpsStart).inMilliseconds;
    if (dt >= 1000) {
      _fps = (_frames * 1000) / dt;
      _frames = 0;
      _fpsStart = now;
    }

    // process
    _exercise = _processExercise(r, _exercise);

    _out.add(ProcessedExerciseFrame(
      pose: r,
      exercise: _exercise,
      fps: _fps,
      inferenceMs: r.inferenceTimeMs,
      isPoseDetected: r.isPoseDetected,
    ));
  }

  void _resetFps() {
    _frames = 0;
    _fps = 0.0;
    _fpsStart = DateTime.now();
  }

  // ===== Utilities =====
  List<double>? _get(PoseDetectionResult r, PoseLandmarkType t) {
    final lm = r.landmarks[t];
    if (lm == null) return null;
    return [lm.x, lm.y, lm.visibility];
  }

  bool _validateKeypoints(PoseDetectionResult r, List<PoseLandmarkType> req, {double minConf = 0.4}) {
    if (!r.isPoseDetected) return false;
    int valid = 0;
    for (final p in req) {
      final v = r.landmarks[p]?.visibility ?? 0.0;
      if (v >= minConf) valid++;
    }
    final need = max(1, (req.length * 0.7).floor());
    return valid >= need;
  }

  String _orientation(PoseDetectionResult r) {
    if (!r.isPoseDetected) return 'unknown';
    final ls = _get(r, PoseLandmarkType.leftShoulder);
    final rs = _get(r, PoseLandmarkType.rightShoulder);
    final lh = _get(r, PoseLandmarkType.leftHip);
    final rh = _get(r, PoseLandmarkType.rightHip);
    final pts = [ls, rs, lh, rh].where((e) => e != null && e![2] > 0.3).toList();
    if (pts.length < 2) return 'unknown';

    double shoulderDist = (ls != null && rs != null && ls[2] > 0.3 && rs[2] > 0.3) ? (ls[0] - rs[0]).abs() : 0.1;
    double hipDist = (lh != null && rh != null && lh[2] > 0.3 && rh[2] > 0.3) ? (lh[0] - rh[0]).abs() : shoulderDist;
    final avg = (shoulderDist + hipDist) / 2.0;
    return avg < 0.08 ? 'side' : 'front';
  }

  String _poseQuality(PoseDetectionResult r) {
    if (!r.isPoseDetected) return "Posisi tidak terdeteksi - masuk ke dalam frame kamera";
    int vis = 0, tot = 0;
    for (final lm in r.landmarks.values) {
      if (lm.visibility > 0.5) vis++;
      tot++;
    }
    final p = tot > 0 ? vis / tot : 0.0;
    if (p < 0.3) return "Posisi sangat tidak jelas - pastikan seluruh tubuh terlihat";
    if (p < 0.5) return "Posisi kurang jelas - perbaiki pencahayaan atau posisi";
    if (p < 0.7) return "Posisi cukup jelas - bisa lebih baik";
    return "Posisi sangat jelas - siap untuk exercise!";
  }

  // ===== Exercise logic =====
  ExerciseType _russianTwist(PoseDetectionResult r, ExerciseType ex) {
    final req = [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, PoseLandmarkType.leftHip, PoseLandmarkType.rightHip];
    if (!_validateKeypoints(r, req, minConf: 0.25)) {
      ex.feedback = "Posisi lebih jelas";
      ex.isCorrect = false;
      return ex;
    }
    final ls = _get(r, PoseLandmarkType.leftShoulder)!;
    final rs = _get(r, PoseLandmarkType.rightShoulder)!;
    final lh = _get(r, PoseLandmarkType.leftHip)!;
    final rh = _get(r, PoseLandmarkType.rightHip)!;
    final le = _get(r, PoseLandmarkType.leftElbow);
    final re = _get(r, PoseLandmarkType.rightElbow);

    final avgS = (ls[1] + rs[1]) / 2;
    final avgH = (lh[1] + rh[1]) / 2;
    final sittingOk = avgH > avgS * 1.02;
    if (!sittingOk) {
      ex.feedback = "Duduk: lutut ditekuk, condong belakang sedikit";
      ex.isCorrect = false;
      return ex;
    }

    var shoulderAngle = atan2(rs[1] - ls[1], rs[0] - ls[0]) * 180 / pi;
    if (shoulderAngle > 90) shoulderAngle -= 180;
    if (shoulderAngle < -90) shoulderAngle += 180;

    bool leftElbowLow = true, rightElbowLow = true;
    if (le != null && le[2] > 0.2) leftElbowLow = le[1] > avgH * 1.05;
    if (re != null && re[2] > 0.2) rightElbowLow = re[1] > avgH * 1.05;

    const th = 12.0;
    switch (ex.state) {
      case 'waiting':
        if (shoulderAngle.abs() < th * 1.5) {
          ex.feedback = "Posisi tengah benar! Twist ke kiri dan kanan";
          ex.state = 'center';
        } else {
          ex.feedback = "Posisi duduk di tengah dulu";
        }
        break;
      case 'center':
        if (shoulderAngle > th && rightElbowLow) {
          ex.feedback = "Twist kanan baik! Sekarang ke kiri";
          ex.state = 'right_deep';
        } else if (shoulderAngle < -th && leftElbowLow) {
          ex.feedback = "Twist kiri baik! Sekarang ke kanan";
          ex.state = 'left_deep';
        } else {
          ex.feedback = "Putar tubuh ke kiri atau kanan";
        }
        break;
      case 'right_deep':
        if (shoulderAngle < -th && leftElbowLow) {
          ex.count++;
          ex.feedback = "Rep ${ex.count}! Twist kiri bagus";
          ex.state = 'left_deep';
          if (ex.count >= ex.targetReps) {
            ex.completed = true;
            ex.feedback = "Russian Twist selesai!";
          }
        } else if (shoulderAngle.abs() < th * 1.5) {
          ex.feedback = "Lanjutkan twist ke kiri";
          ex.state = 'center';
        } else {
          ex.feedback = "Twist ke kiri sekarang";
        }
        break;
      case 'left_deep':
        if (shoulderAngle > th && rightElbowLow) {
          ex.count++;
          ex.feedback = "Rep ${ex.count}! Twist kanan bagus";
          ex.state = 'right_deep';
          if (ex.count >= ex.targetReps) {
            ex.completed = true;
            ex.feedback = "Russian Twist selesai!";
          }
        } else if (shoulderAngle.abs() < th * 1.5) {
          ex.feedback = "Lanjutkan twist ke kanan";
          ex.state = 'center';
        } else {
          ex.feedback = "Twist ke kanan sekarang";
        }
        break;
    }
    ex.isCorrect = true;
    return ex;
  }

  ExerciseType _legRaises(PoseDetectionResult r, ExerciseType ex) {
    final ori = _orientation(r);
    if (ori != 'front') {
      ex.feedback = "Hadap ke kamera (posisi frontal) untuk leg raises";
      ex.isCorrect = false;
      return ex;
    }
    final req = [
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
      PoseLandmarkType.leftAnkle, PoseLandmarkType.rightAnkle,
    ];
    if (!_validateKeypoints(r, req, minConf: 0.35)) {
      ex.feedback = "Posisi lebih jelas - pastikan kedua kaki terlihat jelas";
      ex.isCorrect = false;
      return ex;
    }

    final lh = _get(r, PoseLandmarkType.leftHip)!;
    final rh = _get(r, PoseLandmarkType.rightHip)!;
    final lk = _get(r, PoseLandmarkType.leftKnee)!;
    final rk = _get(r, PoseLandmarkType.rightKnee)!;
    final la = _get(r, PoseLandmarkType.leftAnkle)!;
    final ra = _get(r, PoseLandmarkType.rightAnkle)!;

    final ls = _get(r, PoseLandmarkType.leftShoulder);
    final rs = _get(r, PoseLandmarkType.rightShoulder);
    bool isLying;
    if (ls != null && rs != null) {
      final avgS = (ls[1] + rs[1]) / 2;
      final avgH = (lh[1] + rh[1]) / 2;
      isLying = avgS < avgH * 1.1;
    } else {
      isLying = true;
    }
    if (!isLying) {
      ex.feedback = "Berbaring dulu, hadap kamera, angkat KEDUA kaki bersamaan";
      ex.isCorrect = false;
      return ex;
    }

    final avgHipY = (lh[1] + rh[1]) / 2;
    final leftRef = (la[2] > 0.4) ? la : lk;
    final rightRef = (ra[2] > 0.4) ? ra : rk;

    final leftUp = leftRef[1] <= avgHipY * 0.92;
    final rightUp = rightRef[1] <= avgHipY * 0.92;
    final bothUp = leftUp && rightUp;

    final leftDown = leftRef[1] > avgHipY * 1.2;
    final rightDown = rightRef[1] > avgHipY * 1.2;
    final bothDown = leftDown && rightDown;

    final singleUp = (leftUp && !rightUp) || (rightUp && !leftUp);
    final singleMove = singleUp || ((leftDown && !rightDown) || (rightDown && !leftDown));

    switch (ex.state) {
      case 'waiting':
        if (bothDown) {
          ex.feedback = "Posisi awal benar! Angkat KEDUA kaki bersamaan";
          ex.state = 'down';
          ex.isCorrect = true;
        } else if (singleMove) {
          ex.feedback = "SALAH! Angkat KEDUA kaki bersamaan, bukan satu per satu!";
          ex.isCorrect = false;
        } else {
          ex.feedback = "Berbaring, turunkan kedua kaki, hadap kamera";
          ex.isCorrect = false;
        }
        break;
      case 'down':
        if (bothUp) {
          ex.feedback = "BENAR! Kedua kaki terangkat bersamaan! Turunkan bersamaan";
          ex.state = 'up';
          ex.isCorrect = true;
        } else if (singleMove) {
          ex.feedback = "SALAH! Angkat KEDUA kaki bersamaan, jangan satu per satu!";
          ex.isCorrect = false;
        } else {
          ex.feedback = "Angkat kedua kaki lurus ke atas bersamaan";
          ex.isCorrect = false;
        }
        break;
      case 'up':
        if (bothDown) {
          ex.count++;
          ex.feedback = "Rep ${ex.count}! BENAR - kedua kaki bersamaan!";
          if (ex.count >= ex.targetReps) {
            ex.completed = true;
            ex.feedback = "Leg Raises selesai!";
          } else {
            ex.state = 'down';
          }
          ex.isCorrect = true;
        } else if (singleMove) {
          ex.feedback = "SALAH! Turunkan KEDUA kaki bersamaan!";
          ex.isCorrect = false;
        } else {
          ex.feedback = "Turunkan kedua kaki bersamaan ke posisi awal";
          ex.isCorrect = false;
        }
        break;
    }
    return ex;
  }

  ExerciseType _mountainClimber(PoseDetectionResult r, ExerciseType ex) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftKnee, PoseLandmarkType.rightKnee,
    ];
    if (!_validateKeypoints(r, req, minConf: 0.3)) {
      ex.feedback = "Posisi lebih jelas - pastikan lutut terlihat";
      ex.isCorrect = false;
      return ex;
    }
    final ls = _get(r, PoseLandmarkType.leftShoulder)!;
    final rs = _get(r, PoseLandmarkType.rightShoulder)!;
    final lh = _get(r, PoseLandmarkType.leftHip)!;
    final rh = _get(r, PoseLandmarkType.rightHip)!;
    final lk = _get(r, PoseLandmarkType.leftKnee);
    final rk = _get(r, PoseLandmarkType.rightKnee);
    final lw = _get(r, PoseLandmarkType.leftWrist);
    final rw = _get(r, PoseLandmarkType.rightWrist);

    final avgS = (ls[1] + rs[1]) / 2;
    final avgH = (lh[1] + rh[1]) / 2;

    bool isPlank;
    if (lw != null && rw != null && lw[2] > 0.25 && rw[2] > 0.25) {
      final avgHandY = (lw[1] + rw[1]) / 2;
      isPlank = (avgHandY > avgS * 0.92) && ((avgS - avgH).abs() < 0.12);
    } else {
      isPlank = (avgS - avgH).abs() < 0.1;
    }

    switch (ex.state) {
      case 'waiting':
        if (isPlank) {
          ex.feedback = "Posisi plank benar! Tarik lutut ke perut bergantian";
          ex.state = 'plank';
          ex.isCorrect = true;
        } else {
          ex.feedback = "Posisi push-up: tangan selebar bahu, tubuh lurus";
          ex.isCorrect = false;
          return ex;
        }
        break;
      case 'plank':
      case 'left_forward':
      case 'right_forward':
        if (!isPlank) {
          ex.feedback = "Pertahankan posisi plank yang benar!";
          ex.isCorrect = false;
          ex.state = 'waiting';
          return ex;
        }
        final bellyLevel = avgS + (avgH - avgS) * 0.6;
        bool lkToBelly = lk != null && lk[2] > 0.25 && lk[1] < bellyLevel;
        bool rkToBelly = rk != null && rk[2] > 0.25 && rk[1] < bellyLevel;

        final avgSX = (ls[0] + rs[0]) / 2;
        bool lkForward = true, rkForward = true;
        if (lk != null && lk[2] > 0.25) lkForward = (lk[0] - avgSX).abs() < 0.18;
        if (rk != null && rk[2] > 0.25) rkForward = (rk[0] - avgSX).abs() < 0.18;

        final leftProper = lkToBelly && lkForward;
        final rightProper = rkToBelly && rkForward;

        final leftBack = lk == null || lk[2] < 0.25 || lk[1] > avgH * 0.92;
        final rightBack = rk == null || rk[2] < 0.25 || rk[1] > avgH * 0.92;

        if (ex.state == 'plank') {
          if (leftProper) {
            ex.state = 'left_forward';
            ex.feedback = "Lutut kiri ke perut bagus! Ganti kanan";
            ex.isCorrect = true;
          } else if (rightProper) {
            ex.state = 'right_forward';
            ex.feedback = "Lutut kanan ke perut bagus! Ganti kiri";
            ex.isCorrect = true;
          } else {
            ex.feedback = "Tarik satu lutut ke perut, bergantian";
            ex.isCorrect = true;
          }
        } else if (ex.state == 'left_forward') {
          if (rightProper && leftBack) {
            ex.count++;
            ex.feedback = "Rep ${ex.count}! Lutut kanan ke perut";
            ex.state = 'right_forward';
            ex.isCorrect = true;
            if (ex.count >= ex.targetReps) {
              ex.completed = true;
              ex.feedback = "Mountain Climber selesai!";
            }
          } else if (!leftProper && !rightProper) {
            ex.state = 'plank';
            ex.feedback = "Kembali ke plank, siap tarik lutut kanan";
            ex.isCorrect = true;
          } else {
            ex.feedback = "Tarik lutut kanan ke perut, kembalikan kiri";
            ex.isCorrect = true;
          }
        } else if (ex.state == 'right_forward') {
          if (leftProper && rightBack) {
            ex.count++;
            ex.feedback = "Rep ${ex.count}! Lutut kiri ke perut";
            ex.state = 'left_forward';
            ex.isCorrect = true;
            if (ex.count >= ex.targetReps) {
              ex.completed = true;
              ex.feedback = "Mountain Climber selesai!";
            }
          } else if (!rightProper && !leftProper) {
            ex.state = 'plank';
            ex.feedback = "Kembali ke plank, siap tarik lutut kiri";
            ex.isCorrect = true;
          } else {
            ex.feedback = "Tarik lutut kiri ke perut, kembalikan kanan";
            ex.isCorrect = true;
          }
        }
        break;
    }
    return ex;
  }

  ExerciseType _plank(PoseDetectionResult r, ExerciseType ex) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
    ];
    if (!_validateKeypoints(r, req, minConf: 0.25)) {
      ex.feedback = "Posisi lebih jelas - pastikan tangan dan tubuh terlihat";
      ex.isCorrect = false;
      ex.aiFormStatus = "Unknown";
      ex.aiConfidence = 0.0;
      ex.aiFeedback = "Pose tidak jelas untuk analisis AI";
      return ex;
    }

    final ls = _get(r, PoseLandmarkType.leftShoulder)!;
    final rs = _get(r, PoseLandmarkType.rightShoulder)!;
    final lh = _get(r, PoseLandmarkType.leftHip)!;
    final rh = _get(r, PoseLandmarkType.rightHip)!;
    final lw = _get(r, PoseLandmarkType.leftWrist);
    final rw = _get(r, PoseLandmarkType.rightWrist);
    final la = _get(r, PoseLandmarkType.leftAnkle);
    final ra = _get(r, PoseLandmarkType.rightAnkle);

    final avgS = (ls[1] + rs[1]) / 2;
    final avgH = (lh[1] + rh[1]) / 2;

    bool isPlank;
    if (lw != null && rw != null && lw[2] > 0.2 && rw[2] > 0.2) {
      final avgHandY = (lw[1] + rw[1]) / 2;
      isPlank = (avgHandY > avgS * 0.88) && ((avgS - avgH).abs() < 0.15);
    } else {
      isPlank = (avgS - avgH).abs() < 0.12;
    }

    bool isHorizontal;
    if (la != null && ra != null && la[2] > 0.2 && ra[2] > 0.2) {
      final avgAnk = (la[1] + ra[1]) / 2;
      isHorizontal = avgAnk > avgH * 1.05;
    } else {
      isHorizontal = true;
    }
    if (!isHorizontal) {
      ex.feedback = "Berbaring dulu dalam posisi plank";
      ex.isCorrect = false;
      return ex;
    }

    switch (ex.state) {
      case 'waiting':
        if (isPlank) {
          ex.feedback = "Posisi plank benar! Tahan posisi ini";
          ex.state = 'holding';
          ex.startTime = DateTime.now();
          ex.isHolding = true;
          ex.isCorrect = true;
          ex.aiFormStatus = "Unknown";
          ex.aiConfidence = 0.0;
          ex.aiFeedback = "Analisis AI belum diaktifkan";
        } else {
          ex.feedback = "Posisi push-up: tangan selebar bahu, tubuh lurus";
          ex.isCorrect = false;
          ex.aiFormStatus = "Unknown";
          ex.aiConfidence = 0.0;
          ex.aiFeedback = "Belum dalam posisi plank";
        }
        break;
      case 'holding':
        if (isPlank) {
          if (ex.startTime != null) {
            ex.elapsedSec = DateTime.now().difference(ex.startTime!).inMilliseconds / 1000.0;
          }
          final remain = (ex.targetTimeSec - ex.elapsedSec).clamp(0, ex.targetTimeSec);
          ex.feedback = "Tahan plank! ${remain.toStringAsFixed(1)}s tersisa";
          if (ex.elapsedSec >= ex.targetTimeSec) {
            ex.completed = true;
            ex.feedback = "Plank selesai! ${ex.elapsedSec.toStringAsFixed(1)}s";
            ex.isHolding = false;
          }
          ex.isCorrect = true;
        } else {
          ex.feedback = "Pertahankan posisi plank yang benar!";
          ex.isCorrect = false;
          ex.isHolding = false;
          ex.aiFormStatus = "Unknown";
          ex.aiConfidence = 0.0;
          ex.aiFeedback = "Form rusak - kembali ke posisi plank";
        }
        break;
    }
    return ex;
  }

  ExerciseType _cobraStretch(PoseDetectionResult r, ExerciseType ex) {
    final req = [
      PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip, PoseLandmarkType.rightHip,
      PoseLandmarkType.leftWrist, PoseLandmarkType.rightWrist,
    ];
    if (!_validateKeypoints(r, req, minConf: 0.25)) {
      ex.feedback = "Posisi lebih jelas - pastikan tangan dan tubuh terlihat";
      ex.isCorrect = false;
      return ex;
    }

    final ls = _get(r, PoseLandmarkType.leftShoulder)!;
    final rs = _get(r, PoseLandmarkType.rightShoulder)!;
    final lh = _get(r, PoseLandmarkType.leftHip)!;
    final rh = _get(r, PoseLandmarkType.rightHip)!;
    final lw = _get(r, PoseLandmarkType.leftWrist);
    final rw = _get(r, PoseLandmarkType.rightWrist);
    final le = _get(r, PoseLandmarkType.leftElbow);
    final re = _get(r, PoseLandmarkType.rightElbow);

    final avgS = (ls[1] + rs[1]) / 2;
    final avgH = (lh[1] + rh[1]) / 2;

    final isFaceDown = avgS < avgH * 1.05;
    if (!isFaceDown) {
      ex.feedback = "Berbaring tengkurap dulu, tangan di bawah bahu";
      ex.isCorrect = false;
      return ex;
    }

    bool handsBelowShoulders = true;
    if (lw != null && rw != null && lw[2] > 0.2 && rw[2] > 0.2) {
      final avgW = (lw[1] + rw[1]) / 2;
      handsBelowShoulders = avgW > avgS * 0.95;
    }
    final chestLifted = avgS < avgH * 0.85;

    bool elbowsBent = true;
    if (le != null && re != null && le[2] > 0.2 && re[2] > 0.2 && lw != null && rw != null) {
      final avgE = (le[1] + re[1]) / 2;
      final avgW = (lw![1] + rw![1]) / 2;
      elbowsBent = avgE < avgW * 1.1;
    }

    switch (ex.state) {
      case 'waiting':
        if (isFaceDown && handsBelowShoulders) {
          ex.feedback = "Posisi awal benar! Angkat dada dengan bantuan tangan";
          ex.state = 'ready_to_lift';
          ex.isCorrect = true;
        } else {
          ex.feedback = "Berbaring tengkurap, tangan di bawah bahu";
          ex.isCorrect = false;
        }
        break;
      case 'ready_to_lift':
        if (chestLifted && elbowsBent) {
          ex.feedback = "Cobra position bagus! Tahan posisi ini";
          ex.state = 'stretching';
          ex.startTime = DateTime.now();
          ex.isHolding = true;
          ex.isCorrect = true;
        } else if (isFaceDown && handsBelowShoulders) {
          ex.feedback = "Angkat dada perlahan dengan bantuan tangan";
          ex.isCorrect = true;
        } else {
          ex.feedback = "Pertahankan posisi tengkurap dengan tangan di bawah bahu";
          ex.isCorrect = false;
        }
        break;
      case 'stretching':
        if (chestLifted && elbowsBent) {
          if (ex.startTime != null) {
            ex.elapsedSec = DateTime.now().difference(ex.startTime!).inMilliseconds / 1000.0;
          }
          if (ex.elapsedSec >= ex.targetTimeSec) {
            ex.completed = true;
            ex.feedback = "Cobra Stretch selesai! ${ex.elapsedSec.toStringAsFixed(1)}s";
            ex.isHolding = false;
          } else {
            final remain = (ex.targetTimeSec - ex.elapsedSec).clamp(0, ex.targetTimeSec);
            ex.feedback = "Tahan cobra! ${remain.toStringAsFixed(1)}s tersisa";
          }
          ex.isCorrect = true;
        } else {
          ex.feedback = "Pertahankan posisi cobra yang benar!";
          ex.isCorrect = false;
          ex.isHolding = false;
        }
        break;
    }
    return ex;
  }

  ExerciseType _processExercise(PoseDetectionResult r, ExerciseType ex) {
    final poseQ = _poseQuality(r);
    switch (ex.name.toLowerCase()) {
      case 'jumping jacks':
        ex.feedback = (poseQ.contains("siap") || poseQ.contains("sangat jelas"))
            ? "Siap untuk jumping jacks"
            : "Perjelas posisi sebelum mulai";
        ex.isCorrect = r.isPoseDetected;
        return ex;
      case 'russian twist':
        return _russianTwist(r, ex);
      case 'leg raises':
        return _legRaises(r, ex);
      case 'mountain climber':
        return _mountainClimber(r, ex);
      case 'plank':
        return _plank(r, ex);
      case 'cobra stretch':
        return _cobraStretch(r, ex);
      default:
        ex.feedback = "Exercise tidak dikenali";
        ex.isCorrect = false;
        return ex;
    }
  }
}