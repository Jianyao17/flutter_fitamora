import 'dart:collection';
import '../pose_mediapipe/pose_detection_result.dart';

enum ExerciseType {
  // Latihan yang sudah ada
  jumpingJacks,
  plank,
  cobraStretch,
  seatedSideBends,
  seatedTorsoTwist,
  seatedForwardStretch,
  // Latihan baru
  seatedRow,
}

// Menambahkan state baru yang spesifik untuk setiap latihan
enum ExerciseState {
  // State umum
  waiting,
  holding,

  // State untuk Jumping Jacks
  jjReady,
  jjOpen,

  // State untuk Cobra Stretch
  readyToLift,
  stretching,

  // State untuk Seated Side Bends
  ssbLeftBend,
  ssbRightWaiting,
  ssbRightBend,

  // State untuk Seated Torso Twist
  sttLeftTwist,
  sttRightWaiting,
  sttRightTwist,

  // State untuk Seated Forward Stretch
  sfsForward,

  // State untuk Seated Row (baru)
  srPulling,      // Fase menarik
  srReturning,    // Fase kembali
  srTransitioning,// Gerakan di antara fase
}

// Kelas dasar Exercise
class Exercise {
  final ExerciseType type;
  final String name;
  final int targetReps;
  final bool isTimed;
  final double targetTimeSec;

  int count = 0;
  ExerciseState state = ExerciseState.waiting;
  bool isCorrect = true;
  String feedback = '';
  bool completed = false;

  DateTime? startTime;
  double elapsedSec = 0;
  bool isHolding = false;

  String aiFormStatus = 'Unknown';
  double aiConfidence = 0.0;
  String aiFeedback = '';

  Exercise({
    required this.type,
    required this.name,
    this.targetReps = 10,
    this.isTimed = false,
    this.targetTimeSec = 30.0,
  });

  // Factory constructor diperbarui untuk menangani semua jenis latihan
  factory Exercise.create(ExerciseType type) {
    switch (type) {
      case ExerciseType.jumpingJacks:
        return Exercise(type: type, name: 'Jumping Jacks', targetReps: 10);
      case ExerciseType.plank:
        return Exercise(type: type, name: 'Plank', isTimed: true, targetTimeSec: 30.0);
      case ExerciseType.cobraStretch:
        return Exercise(type: type, name: 'Cobra Stretch', isTimed: true, targetTimeSec: 30.0);
      case ExerciseType.seatedSideBends:
        return Exercise(type: type, name: 'Seated Side Bends', targetReps: 10);
      case ExerciseType.seatedTorsoTwist:
        return Exercise(type: type, name: 'Seated Torso Twist', targetReps: 10);
      case ExerciseType.seatedForwardStretch:
        return Exercise(type: type, name: 'Seated Forward Stretch', targetReps: 10);
      case ExerciseType.seatedRow:
      // Menggunakan kelas turunan khusus untuk Seated Row
        return SeatedRowExercise();
    }
  }

  void reset() {
    count = 0;
    state = ExerciseState.waiting;
    isCorrect = true;
    feedback = '';
    completed = false;
    startTime = null;
    elapsedSec = 0;
    isHolding = false;
    aiFormStatus = 'Unknown';
    aiConfidence = 0.0;
    aiFeedback = '';
  }

  void updateElapsedTime() {
    if (startTime != null && isHolding) {
      elapsedSec = DateTime.now().difference(startTime!).inMilliseconds / 1000.0;
    }
  }

  bool get isTargetReached {
    if (isTimed) {
      return elapsedSec >= targetTimeSec;
    } else {
      return count >= targetReps;
    }
  }

  double get progress {
    if (completed) return 1.0;
    if (isTimed) {
      return (elapsedSec / targetTimeSec).clamp(0.0, 1.0);
    } else {
      return (count / targetReps).clamp(0.0, 1.0);
    }
  }
}

// Kelas turunan khusus untuk menyimpan state Seated Row yang kompleks
class SeatedRowExercise extends Exercise {
  // State internal yang diperlukan untuk logika Seated Row
  bool pullDetected = false;
  bool returnDetected = false;
  bool repInProgress = false;
  DateTime? lastRepTime;
  DateTime? lastStateChange;
  String movementDirection = 'none'; // none, pulling, returning

  // Buffer untuk analisis gerakan (mirip Deque di Python)
  final Queue<double> angleHistory = Queue<double>();
  final int angleHistoryMaxSize = 100;

  SeatedRowExercise()
      : super(
    type: ExerciseType.seatedRow,
    name: 'Seated Row',
    targetReps: 10,
  );

  void addAngleToHistory(double angle) {
    angleHistory.addLast(angle);
    if (angleHistory.length > angleHistoryMaxSize) {
      angleHistory.removeFirst();
    }
  }

  @override
  void reset() {
    super.reset();
    pullDetected = false;
    returnDetected = false;
    repInProgress = false;
    lastRepTime = null;
    lastStateChange = null;
    movementDirection = 'none';
    angleHistory.clear();
  }
}


class ProcessedExerciseFrame {
  final PoseDetectionResult pose;
  final Exercise exercise;
  final double fps;
  final int inferenceMs;
  final bool isPoseDetected;

  ProcessedExerciseFrame({
    required this.pose,
    required this.exercise,
    required this.fps,
    required this.inferenceMs,
    required this.isPoseDetected,
  });
}