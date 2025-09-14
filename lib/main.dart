import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/user_database.dart';
import 'data/workout_database.dart';
import 'models/exercise/exercise.dart';
import 'models/exercise/exercise_guide.dart';
import 'models/exercise/workout_plan.dart';

import 'models/exercise/workout_program.dart';
import 'pages/splash_screen.dart';
import 'theme.dart';

Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await UserDatabase.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context)
  {
    // WorkoutDatabase.instance.setActiveProgram(workoutProgram);
    return MaterialApp(
      title: 'Fitamora',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}

// Definisikan panduan latihan sekali saja agar bisa digunakan kembali
final List<ExerciseGuide> jumpingJacksGuides = [
  ExerciseGuide(
    title: 'Posisi Awal',
    imageUrl: 'https://i.imgur.com/g9a3C5O.png', // URL gambar statis untuk posisi awal
  ),
  ExerciseGuide(
    title: 'Lompat dan Buka',
    imageUrl: 'https://media.tenor.com/XC-r8NVG4s4AAAAC/jumping-jacks.gif', // URL GIF untuk menunjukkan gerakan
  ),
];

final List<ExerciseGuide> plankGuides = [
  ExerciseGuide(
    title: 'Atur Posisi Lengan',
    imageUrl: 'https://i.imgur.com/0v51uL6.png', // URL gambar untuk posisi lengan
  ),
  ExerciseGuide(
    title: 'Jaga Punggung Tetap Lurus',
    imageUrl: 'https://hips.hearstapps.com/hmg-prod/images/workouts/2016/03/plank-1457047975.gif', // URL GIF untuk menunjukkan form yang benar
  ),
];

final List<ExerciseGuide> cobraStretchGuides = [
  ExerciseGuide(
    title: 'Posisi Tengkurap',
    imageUrl: 'https://i.imgur.com/z4n4r1j.png', // URL gambar untuk posisi awal
  ),
  ExerciseGuide(
    title: 'Angkat Dada Perlahan',
    imageUrl: 'https://i.pinimg.com/originals/38/b3/22/38b32242138a0f11900a293282a5c378.gif', // URL GIF untuk menunjukkan gerakan
  ),
];

// Inisialisasi WorkoutProgram
final WorkoutProgram workoutProgram = WorkoutProgram(
  title: 'Program Latihan Skoliosis',
  description: 'Program latihan selama 7 hari untuk membantu memperbaiki postur tubuh dan mengurangi ketegangan otot akibat skoliosis.',
  startDate: DateTime.now(),
  totalDays: 3,
  dailyPlans: [
    // HARI 1: Pengenalan dan Pemanasan
    WorkoutPlan(
      title: 'Peregangan Dasar',
      description: 'Mulai dengan peregangan lembut untuk meningkatkan fleksibilitas dan mempersiapkan tubuh.',
      imagePath: 'https://i.imgur.com/o3a2wT7.png', // Contoh gambar untuk hari 1
      exercises: [
        Exercise(
          name: 'Cobra Stretch',
          description: 'Peregangan untuk membuka dada dan meregangkan tulang belakang.',
          sets: 2,
          duration: 20, // detik
          rest: 20, // detik
          guides: cobraStretchGuides,
        ),
        Exercise(
          name: 'Plank',
          description: 'Memulai membangun kekuatan otot inti untuk stabilitas.',
          sets: 2,
          duration: 15, // detik
          rest: 25, // detik
          guides: plankGuides,
        ),
      ],
    ),
    // HARI 2: Aktivasi Otot
    WorkoutPlan(
      title: 'Aktivasi Otot',
      description: 'Fokus pada peningkatan kekuatan otot inti dan punggung.',
      imagePath: 'https://i.imgur.com/u7yZgYx.png', // Contoh gambar untuk hari 2
      exercises: [
        Exercise(
          name: 'Plank',
          description: 'Tahan lebih lama untuk meningkatkan daya tahan otot inti.',
          sets: 2,
          duration: 25, // detik
          rest: 20, // detik
          guides: plankGuides,
        ),
        Exercise(
          name: 'Jumping Jacks',
          description: 'Latihan kardio ringan untuk pemanasan seluruh tubuh.',
          sets: 1,
          rep: 20,
          rest: 20, // detik
          guides: jumpingJacksGuides,
        ),
      ],
    ),
    // HARI 3: Fleksibilitas dan Kekuatan
    WorkoutPlan(
      title: 'Fleksibilitas & Kekuatan',
      description: 'Kombinasi peregangan dan penguatan untuk keseimbangan tubuh.',
      imagePath: 'https://i.imgur.com/v8tZ4jN.png', // Contoh gambar untuk hari 3
      exercises: [
        Exercise(
          name: 'Cobra Stretch',
          description: 'Memperdalam peregangan untuk fleksibilitas tulang belakang.',
          sets: 2,
          duration: 30, // detik
          rest: 15, // detik
          guides: cobraStretchGuides,
        ),
        Exercise(
          name: 'Plank',
          description: 'Terus membangun kekuatan fondasi tubuh Anda.',
          sets: 2,
          duration: 30, // detik
          rest: 20, // detik
          guides: plankGuides,
        ),
      ],
    ),
  ],
);
