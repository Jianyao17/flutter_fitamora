import 'pose_detection_result.dart';

class ExerciseType {
  final String name;
  int count;
  String state;
  final int targetReps;
  final bool isTimed;
  final double targetTimeSec;

  bool isCorrect;
  String feedback;
  bool completed;

  DateTime? startTime;
  double elapsedSec;
  bool isHolding;

  String aiFormStatus;
  double aiConfidence;
  String aiFeedback;

  ExerciseType({
    required this.name,
    this.count = 0,
    this.state = 'waiting',
    this.targetReps = 10,
    this.isTimed = false,
    this.targetTimeSec = 20,
    this.isCorrect = true,
    this.feedback = '',
    this.completed = false,
    this.startTime,
    this.elapsedSec = 0,
    this.isHolding = false,
    this.aiFormStatus = 'Unknown',
    this.aiConfidence = 0.0,
    this.aiFeedback = '',
  });

  factory ExerciseType.forName(String name) {
    final n = name.toLowerCase();
    final isTimed = (n == 'plank' || n == 'cobra stretch');
    final tTime = n == 'plank'
        ? 30.0
        : n == 'cobra stretch'
        ? 30.0
        : 20.0;
    final tReps = isTimed ? 0 : 10;
    return ExerciseType(name: name, targetReps: tReps, isTimed: isTimed, targetTimeSec: tTime);
  }
}

class ProcessedExerciseFrame {
  final PoseDetectionResult pose;
  final ExerciseType exercise;
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