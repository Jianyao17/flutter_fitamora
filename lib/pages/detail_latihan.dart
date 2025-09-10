import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/exercise.dart';
import '../models/workout_plan.dart';
import 'persiapan_latihan.dart';

class DetailLatihan extends StatelessWidget
{
  final WorkoutPlan workoutPlan;
  const DetailLatihan({super.key, required this.workoutPlan});

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
      appBar: AppBar(
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
            _buildHeader(context),
            const SizedBox(height: 24),
            _buildExerciseList(context),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: ElevatedButton(
          onPressed: () => Navigator.of(context)
            .push(MaterialPageRoute(builder:
              (_) => PersiapanLatihan(workoutPlan: workoutPlan)),
          ),
          child: const Text('Mulai Latihan'),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context)
  {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      padding: const EdgeInsets.all(20.0),
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
            child: Image.network(
              workoutPlan.imagePath ?? 'https://via.placeholder.com/80',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(workoutPlan.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(workoutPlan.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context)
  {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'List Gerakan',
            style: theme.textTheme.headlineMedium, // Menggunakan textTheme
          ),
          const SizedBox(height: 16),
          ListView.builder(
            itemCount: workoutPlan.exercises.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final exercise = workoutPlan.exercises[index];
              return _buildExerciseItem(context, exercise: exercise);
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildExerciseItem(BuildContext context, {required Exercise exercise})
  {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 24,
            backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
            child: Icon(exercise.icon, color: theme.colorScheme.secondary, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name,
                  style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(exercise.description,
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    'Repetisi: ${exercise.reps}',
                    style: theme.textTheme.labelSmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}