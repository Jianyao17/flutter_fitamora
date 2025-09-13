import '../pose_mediapipe/pose_detection_result.dart';

enum ExerciseType {
  jumpingJacks,
  plank,
  cobraStretch,
}

enum ExerciseState {
  // Common states
  waiting,
  holding,

  // Jumping Jacks states (from Python: waiting, ready, open)
  jjReady, // Kaki rapat, tangan di samping
  jjOpen, // Kaki terbuka, tangan di atas

  // Cobra Stretch states
  readyToLift,
  stretching,
}

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

  // AI feedback properties
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

  factory Exercise.create(ExerciseType type) {
    switch (type) {
      case ExerciseType.jumpingJacks:
        return Exercise(
          type: type,
          name: 'Jumping Jacks',
          targetReps: 10,
        );
      case ExerciseType.plank:
        return Exercise(
          type: type,
          name: 'Plank',
          isTimed: true,
          targetTimeSec: 30.0,
        );
      case ExerciseType.cobraStretch:
        return Exercise(
          type: type,
          name: 'Cobra Stretch',
          isTimed: true,
          targetTimeSec: 30.0,
        );
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
    if (isTimed) {
      return (elapsedSec / targetTimeSec).clamp(0.0, 1.0);
    } else {
      return (count / targetReps).clamp(0.0, 1.0);
    }
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