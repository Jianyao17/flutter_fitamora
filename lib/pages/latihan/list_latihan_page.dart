import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/exercise_database.dart';
import '../../data/workout_database.dart';
import '../../models/exercise/workout_plan.dart';
import 'detail_latihan_page.dart';

class ListLatihanPage extends StatelessWidget {
  const ListLatihanPage({super.key});

  @override
  Widget build(BuildContext context) {
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
          title: Text("Pilih Latihan", // Judul lebih sesuai
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32), // Padding bawah
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Single Workout"),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ExerciseDatabase.singleWorkouts.length,
                itemBuilder: (context, index) {
                  final workout = ExerciseDatabase.singleWorkouts[index];
                  return _buildWorkoutCard(context, workout);
                },
              ),
              const SizedBox(height: 24),
              _buildSectionHeader("Mixed Workout"),
              ListView.builder(
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

  // Helper untuk membuat header seksi agar tidak duplikasi kode
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, WorkoutPlan workoutPlan)
  {
    final theme = Theme.of(context);
    final String imagePath = workoutPlan.imagePath ?? 'assets/build/a1.png';

    // Menggunakan Padding untuk margin, agar area sentuh Stack akurat
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Stack(
        children: [
          // LAPISAN 1: KARTU UTAMA (Bisa diketuk untuk detail)
          GestureDetector(
            onTap: () {
              Navigator.push(context,
                MaterialPageRoute(
                  builder: (context) => DetailLatihan(workoutPlan: workoutPlan),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15.0),
                    child: Image.asset(
                      imagePath,
                      width: 80, height: 80, fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                          width: 80, height: 80,
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.broken_image)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(workoutPlan.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(workoutPlan.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Beri ruang kosong di kanan untuk tombol
                ],
              ),
            ),
          ),

          // LAPISAN 2: TOMBOL TAMBAH (Mengambang di pojok kanan atas)
          Positioned(
            top: 8, bottom: 8, right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              // Material untuk efek splash saat tombol ditekan
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: const Icon(Icons.add),
                  iconSize: 24,
                  color: theme.colorScheme.onPrimary,
                  tooltip: "Tambahkan ke Program Aktif",
                  onPressed: () {
                    if (WorkoutDatabase.instance.activeWorkoutProgram.totalDays > 0)
                    {
                      WorkoutDatabase.instance.addWorkoutPlan(workoutPlan);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("'${workoutPlan.title}' telah ditambahkan."),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    } else
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Tidak ada program aktif untuk ditambahkan."),
                          backgroundColor: theme.colorScheme.error,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}