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
      guides: json['guides'] != null
          ? (json['guides'] as List).map((g) => ExerciseGuide.fromJson(g)).toList()
          : null,
      sets: json['set'] as int?,
      rep: json['rep'] as int?,
      duration: json['duration'] as int?,
      rest: json['rest'] as int?,
    );
  }

  String get detailsString {
    // 1. Mulai dengan list kosong
    final parts = <String>[];

    // 2. Tambahkan setiap bagian HANYA JIKA nilainya tidak null (dan > 0)
    if (sets != null && sets! > 0) {
      parts.add('$sets set');
    }

    if (rep != null && rep! > 0) {
      parts.add('$rep repetisi');
    } else if (duration != null && duration! > 0) {
      parts.add('$duration detik');
    }

    // 3. Jika setelah semua pengecekan list masih kosong, berarti tidak ada detail
    if (parts.isEmpty) {
      // Mengembalikan string kosong jika tidak ada set, rep, atau durasi
      return '';
    }

    // 4. Gabungkan bagian-bagian yang valid
    String mainDetails = parts.join(' x ');

    // 5. Tambahkan informasi istirahat jika ada
    if (rest != null && rest! > 0) {
      mainDetails += ' (istirahat ${rest} dtk)';
    }

    return mainDetails;
  }
}