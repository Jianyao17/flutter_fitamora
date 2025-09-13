import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/exercise_database.dart';
import '../../models/exercise/workout_plan.dart';
import 'detail_latihan_page.dart';

class ListLatihanPage extends StatelessWidget {
  const ListLatihanPage({super.key});

  @override
  Widget build(BuildContext context)
  {
    final theme = Theme.of(context);
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text("Program Latihan",
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Text(
                "Single Workout",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              // Single Workout List
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ExerciseDatabase.singleWorkouts.length,
              itemBuilder: (context, index) {
                final workout = ExerciseDatabase.singleWorkouts[index];
                return _buildWorkoutCard(context, workout);
              },
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Mixed Workout",
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              // Mixed Workout List
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: ExerciseDatabase.mixedWorkouts.length,
              itemBuilder: (context, index) {
                final workout = ExerciseDatabase.mixedWorkouts[index];
                return _buildWorkoutCard(context, workout);
              },
            ),
          ],
        ),
      )
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutPlan workoutPlan)
  {
    final theme = Theme.of(context);
    final String imagePath = workoutPlan.imagePath ?? 'assets/build/a1.png';
    return GestureDetector(
      onTap: ()
      {
        Navigator.push(context,
          MaterialPageRoute(
            builder: (context) => DetailLatihan(workoutPlan: workoutPlan),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15.0),
              child: imagePath.startsWith('http')
              ? Image.network( // Jika path adalah URL
                imagePath,
                width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(width: 80, height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image)),
              )
              : Image.asset( // Jika path adalah Aset
                imagePath,
                width: 80, height: 80, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(width: 80, height: 80,
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.broken_image)),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workoutPlan.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(workoutPlan.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryFixedVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}