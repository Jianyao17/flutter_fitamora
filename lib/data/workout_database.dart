import '../models/exercise/workout_plan.dart';
import '../models/exercise/workout_program.dart';

class WorkoutDatabase
{
  static WorkoutDatabase get instance => _instance;
  static final WorkoutDatabase _instance = WorkoutDatabase._internal();
  factory WorkoutDatabase() => _instance;

  WorkoutProgram _activeWorkoutProgram = WorkoutProgram.empty();
  WorkoutProgram get activeWorkoutProgram => _activeWorkoutProgram;

  WorkoutDatabase._internal();

  void setActiveProgram(WorkoutProgram program)
  {
    // Pastikan dailyPlans growable
    _activeWorkoutProgram = WorkoutProgram(
      title: program.title,
      description: program.description,
      totalDays: program.totalDays,
      dailyPlans: List<WorkoutPlan>.from(program.dailyPlans, growable: true),
      startDate: program.startDate,
    );
  }

  void clearActiveProgram() {
    _activeWorkoutProgram = WorkoutProgram.empty();
  }

  void addWorkoutPlan(WorkoutPlan plan) {
    _activeWorkoutProgram.addWorkoutPlan(plan);
  }

  void addWorkoutPlans(List<WorkoutPlan> plans) {
    _activeWorkoutProgram.addWorkoutPlans(plans);
  }

  void removeWorkoutPlan(WorkoutPlan plan) {
    _activeWorkoutProgram.removeWorkoutPlan(plan);
  }

  void removeWorkoutPlans(List<WorkoutPlan> plans) {
    _activeWorkoutProgram.removeWorkoutPlans(plans);
  }
}
