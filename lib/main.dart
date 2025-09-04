import 'package:flutter/material.dart';

import 'models/exercise.dart';
import 'models/exercise_guide.dart';
import 'models/workout_plan.dart';

import 'pages/pose_detection_image.dart';
import 'theme.dart';

import 'dart:async';

Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget
{
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: PoseDetectionDemo(),
      // home: DetailLatihan(workoutPlan: workoutPlan),
    );
  }
}

// Data Dummy
final WorkoutPlan workoutPlan =
  WorkoutPlan(
    title: 'Latihan Kaki',
    description: 'Memperkuat otot paha, betis, dan glutes untuk fondasi tubuh yang kokoh.',
    imageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=600',
    exercises: [
      Exercise(
        name: 'Squat',
        description: 'Tekuk lutut hingga paha sejajar lantai, lalu kembali berdiri.',
        reps: '12-15 kali x 3 set',
        icon: Icons.fitness_center,
        totalSets: 3,
        guides: [
          ExerciseGuide(
            title: 'Form Benar',
            imageUrl: 'https://enarahealth.com/wp-content/uploads/2022/03/PngItem_2810409-e1647565708516.png',
          ),
          ExerciseGuide(
            title: 'Kesalahan: Lutut Ke Dalam',
            imageUrl: 'https://i.ytimg.com/vi/U3HlEF_E9fo/maxresdefault.jpg',
          ),
        ],
      ),
      Exercise(
        name: 'Jump Squat',
        description: 'Lakukan squat lalu meloncat eksplosif ke atas.',
        reps: '10-12 kali x 3 set',
        icon: Icons.keyboard_double_arrow_up,
        totalSets: 3,
        guides: [
          ExerciseGuide(
            title: 'Gerakan Eksplosif',
            imageUrl: 'https://liftmanual.com/wp-content/uploads/2023/04/prisoner-jump-squat.jpg',
          ),
        ],
      ),
      Exercise(
        name: 'Glute Bridge',
        description: 'Berbaring, tekuk lutut, lalu dorong pinggul ke atas hingga tubuh lurus.',
        reps: '12-15 kali x 3 set',
        icon: Icons.straighten,
        totalSets: 3,
        guides: [
          ExerciseGuide(
            title: 'Form Benar',
            imageUrl: 'https://liftmanual.com/wp-content/uploads/2023/04/barbell-glute-bridge.jpg',
          ),
          ExerciseGuide(
            title: 'Kesalahan: Punggung Terlalu Melengkung',
            imageUrl: 'https://i.ytimg.com/vi/bUjVlVtJOk0/maxresdefault.jpg',
          ),
        ],
      ),
      Exercise(
        name: 'Lunges',
        description: 'Langkahkan satu kaki ke depan dan tekuk kedua lutut hingga 90 derajat.',
        reps: '10-12 kali per kaki x 3 set',
        icon: Icons.directions_walk,
        totalSets: 3,
        guides: [
          ExerciseGuide(
            title: 'Form Benar',
            imageUrl: 'https://trainingstation.co.uk/cdn/shop/articles/Lunges-movment_d958998d-2a9f-430e-bdea-06f1e2bcc835_1400x.webp',
          ),
          ExerciseGuide(
            title: 'Kesalahan: Lutut Terlalu Maju',
            imageUrl: 'https://kajabi-storefronts-production.kajabi-cdn.com/kajabi-storefronts-production/blogs/30948/images/oeLzh7B7TOqL4pzqpZJa_Lunge_Mistakes_-_YouTube_1.png',
          ),
        ],
      ),
    ],
  );



