import 'package:flutter/material.dart';
import 'exercise_guide.dart';

class Exercise {
  final String name;
  final String description;
  final List<ExerciseGuide>? guides;
  final IconData? icon;

  final int? sets;
  final int? rep;
  final int? duration;
  final int? rest;

  Exercise({
    required this.name,
    this.description = '',
    this.icon = Icons.fitness_center,
    this.guides,

    this.sets,
    this.rep,
    this.duration,
    this.rest,
  });

  factory Exercise.fromJson(Map<String, dynamic> json)
  {
    return Exercise(
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] != null
          ? IconData(json['icon'], fontFamily: 'MaterialIcons')
          : Icons.fitness_center,
      guides: json['guides'] != null
          ? (json['guides'] as List).map((g) => ExerciseGuide.fromJson(g)).toList()
          : null,
      sets: json['sets'] as int?,
      rep: json['rep'] as int?,
      duration: json['duration'] as int?,
      rest: json['rest'] as int?,
    );
  }

  String get detailsString
  {
    final parts = <String>['$sets set'];

    // Menambahkan repetisi atau durasi
    if (rep != null) {
      parts.add('$rep repetisi');
    } else if (duration != null) {
      parts.add('$duration detik');
    }

    // Menggabungkan bagian utama dengan 'x'
    String mainDetails = parts.join(' x ');

    // Menambahkan informasi istirahat jika ada
    if (rest != null && rest! > 0) {
      mainDetails += ' (istirahat ${rest} dtk)';
    }

    return mainDetails;
  }
}