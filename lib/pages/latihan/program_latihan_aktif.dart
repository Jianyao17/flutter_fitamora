import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/exercise/exercise.dart';
import '../../models/exercise/workout_plan.dart';
import '../../models/exercise/workout_program.dart';

class ProgramLatihanAktifPage extends StatelessWidget {
  final WorkoutProgram activeProgram;

  const ProgramLatihanAktifPage({super.key, required this.activeProgram});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(activeProgram.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          _buildProgramHeader(context, activeProgram),
          const SizedBox(height: 24),
          Text(
            "Rencana Harian",
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          // List workout harian yang selalu ditampilkan
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: activeProgram.dailyPlans.length,
            itemBuilder: (context, index)
            {
              final dailyPlan = activeProgram.dailyPlans[index];
              final dayNumber = index + 1;
              final bool isCurrentDay = dayNumber == activeProgram.currentDay;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDailyPlanHeader(context, dailyPlan, dayNumber, isCurrentDay),
                  // Daftar exercise di bawah header
                  if (dailyPlan.exercises.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                      child: Column(
                        children: dailyPlan.exercises.map((exercise) {
                          return _buildExerciseItem(context, exercise: exercise);
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 16), // Jarak antar daily plan
                ],
              );
            },
          )
        ],
      ),
    );
  }

  // Header untuk informasi program secara keseluruhan
  Widget _buildProgramHeader(BuildContext context, WorkoutProgram program)
  {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy', 'id_ID');
    final String startDateStr = program.startDate != null ? dateFormat.format(program.startDate!) : 'N/A';
    final String endDateStr = program.startDate?.add(Duration(days: program.totalDays - 1)) != null
        ? dateFormat.format(program.startDate!.add(Duration(days: program.totalDays - 1)))
        : 'N/A';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(program.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('$startDateStr - $endDateStr', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Progres", style: TextStyle(fontSize: 16)),
              Text("Hari ${program.currentDay} dari ${program.totalDays}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: program.progressPercent,
              minHeight: 12,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  // Header untuk setiap rencana harian (mengadopsi style dari DetailLatihan)
  Widget _buildDailyPlanHeader(BuildContext context, WorkoutPlan workoutPlan, int dayNumber, bool isCurrentDay)
  {
    final theme = Theme.of(context);
    final String imagePath = workoutPlan.imagePath ?? 'assets/build/a1.png';
    final Color headerColor = isCurrentDay ? theme.colorScheme.primary : theme.colorScheme.primary.withOpacity(0.8);
    final Color onHeaderColor = isCurrentDay ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: headerColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 2, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(15.0),
            child: Image.asset(imagePath, width: 64, height: 64, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 64, height: 64, color: Colors.grey.shade300, child: const Icon(Icons.broken_image))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hari $dayNumber', style: theme.textTheme.labelLarge?.copyWith(color: onHeaderColor.withOpacity(0.8))),
                Text(workoutPlan.title, style: theme.textTheme.titleMedium?.copyWith(color: onHeaderColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Item untuk setiap exercise (ukuran disesuaikan agar lebih kecil dari header)
  Widget _buildExerciseItem(BuildContext context, {required Exercise exercise})
  {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(15.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 20, // Ukuran lebih kecil
              backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
              child: Icon(exercise.icon, color: theme.colorScheme.secondary, size: 22)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: theme.textTheme.titleSmall), // Font lebih kecil
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: theme.scaffoldBackgroundColor, borderRadius: BorderRadius.circular(20)),
                  child: Text(exercise.detailsString, style: theme.textTheme.labelSmall),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}