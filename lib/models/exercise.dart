import 'package:flutter/material.dart';
import 'exercise_guide.dart';

class Exercise {
  final String name;
  final String description;
  final String reps;
  final int totalSets;
  final IconData? icon;
  final List<ExerciseGuide>? guides;

  Exercise({
    required this.name,
    required this.description,
    required this.totalSets,
    required this.reps,
    this.icon = Icons.fitness_center,
    this.guides,
  });
}