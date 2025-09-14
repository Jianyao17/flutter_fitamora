import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/user_database.dart';
import 'data/workout_database.dart';
import 'models/exercise/exercise.dart';
import 'models/exercise/exercise_guide.dart';
import 'models/exercise/workout_plan.dart';

import 'models/exercise/workout_program.dart';
import 'pages/login/login_page.dart';
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
    WorkoutDatabase.instance.setActiveProgram(workoutProgram);
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
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
  totalDays: 7,
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
    // HARI 4: Istirahat Aktif
    WorkoutPlan(
      title: 'Istirahat Aktif',
      description: 'Fokus pada peregangan ringan untuk pemulihan otot.',
      imagePath: 'https://i.imgur.com/pYqF8zM.png', // Contoh gambar untuk hari 4
      exercises: [
        Exercise(
          name: 'Cobra Stretch',
          description: 'Peregangan santai untuk menjaga kelenturan.',
          sets: 3,
          duration: 25, // detik
          rest: 20, // detik
          guides: cobraStretchGuides,
        ),
      ],
    ),
    // HARI 5: Peningkatan Intensitas
    WorkoutPlan(
      title: 'Peningkatan Intensitas',
      description: 'Meningkatkan tantangan untuk membangun kekuatan lebih lanjut.',
      imagePath: 'https://i.imgur.com/L3gHw8f.png', // Contoh gambar untuk hari 5
      exercises: [
        Exercise(
          name: 'Jumping Jacks',
          description: 'Meningkatkan detak jantung dan membakar kalori.',
          sets: 2,
          rep: 25,
          rest: 15, // detik
          guides: jumpingJacksGuides,
        ),
        Exercise(
          name: 'Plank',
          description: 'Tantang otot inti Anda dengan durasi yang lebih lama.',
          sets: 3,
          duration: 35, // detik
          rest: 20, // detik
          guides: plankGuides,
        ),
        Exercise(
          name: 'Cobra Stretch',
          description: 'Pendinginan dengan peregangan yang menenangkan.',
          sets: 2,
          duration: 30, // detik
          rest: 15, // detik
          guides: cobraStretchGuides,
        ),
      ],
    ),
    // HARI 6: Daya Tahan Inti
    WorkoutPlan(
      title: 'Daya Tahan Inti',
      description: 'Fokus penuh pada penguatan otot inti untuk postur maksimal.',
      imagePath: 'https://i.imgur.com/8xJjR9t.png', // Contoh gambar untuk hari 6
      exercises: [
        Exercise(
          name: 'Plank',
          description: 'Dorong batas Anda untuk daya tahan otot inti terbaik.',
          sets: 3,
          duration: 45, // detik
          rest: 20, // detik
          guides: plankGuides,
        ),
        Exercise(
          name: 'Jumping Jacks',
          description: 'Sesi kardio singkat untuk menjaga energi.',
          sets: 2,
          rep: 20,
          rest: 20, // detik
          guides: jumpingJacksGuides,
        ),
      ],
    ),
    // HARI 7: Fleksibilitas Maksimal
    WorkoutPlan(
      title: 'Hari 7: Fleksibilitas Maksimal',
      description: 'Mengakhiri minggu dengan peregangan mendalam untuk relaksasi.',
      imagePath: 'https://i.imgur.com/C4uWz7k.png', // Contoh gambar untuk hari 7
      exercises: [
        Exercise(
          name: 'Cobra Stretch',
          description: 'Tahan peregangan untuk memaksimalkan fleksibilitas.',
          sets: 3,
          duration: 40, // detik
          rest: 15, // detik
          guides: cobraStretchGuides,
        ),
        Exercise(
          name: 'Plank',
          description: 'Satu set terakhir untuk menjaga kekuatan inti.',
          sets: 1,
          duration: 60, // detik
          rest: 0,
          guides: plankGuides,
        ),
      ],
    ),
  ],
);
