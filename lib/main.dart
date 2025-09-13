import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';


import 'data/exercise_database.dart';
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
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context)
  {
    final WorkoutProgram workoutProgram = WorkoutProgram(
      title: 'Program Latihan Skoliosis',
      description: 'Program latihan selama 7 hari untuk membantu memperbaiki postur tubuh dan mengurangi ketegangan otot akibat skoliosis.',
      dailyPlans: ExerciseDatabase.singleWorkouts,
      totalDays: ExerciseDatabase.singleWorkouts.length,
      startDate: DateTime.now()
    );

    WorkoutDatabase.instance.setActiveProgram(workoutProgram);

    return MaterialApp(
      title: 'Flutter Demo',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}

