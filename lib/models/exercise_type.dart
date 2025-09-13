import 'pose_detection_result.dart';

enum ExerciseType {
  jumpingJacks,
  russianTwist,
  legRaises,
  mountainClimber,
  plank,
  cobraStretch,
}

enum ExerciseState {
  waiting,
  center,
  up,
  down,
  leftDeep,
  rightDeep,
  leftForward,
  rightForward,
  holding,
  readyToLift,
  stretching,
  plank,
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
  
  // AI feedback untuk plank
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
          isTimed: false,
        );
      case ExerciseType.russianTwist:
        return Exercise(
          type: type,
          name: 'Russian Twist',
          targetReps: 10,
          isTimed: false,
        );
      case ExerciseType.legRaises:
        return Exercise(
          type: type,
          name: 'Leg Raises',
          targetReps: 10,
          isTimed: false,
        );
      case ExerciseType.mountainClimber:
        return Exercise(
          type: type,
          name: 'Mountain Climber',
          targetReps: 10,
          isTimed: false,
        );
      case ExerciseType.plank:
        return Exercise(
          type: type,
          name: 'Plank',
          targetReps: 0,
          isTimed: true,
          targetTimeSec: 30.0,
        );
      case ExerciseType.cobraStretch:
        return Exercise(
          type: type,
          name: 'Cobra Stretch',
          targetReps: 0,
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