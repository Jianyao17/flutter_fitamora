// pages/workout_list_page.dart - Alternative dengan ListView.builder

import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../models/exercise/workout_model.dart';
import 'workout_detail_page.dart';

class WorkoutListPage extends StatelessWidget {
  const WorkoutListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Gabungkan semua workouts dengan divider
    final List<dynamic> allItems = [
      'Single Workout', // Header
      ...singleWorkouts,
      'divider',
      'Mixed Workout', // Header
      ...mixedWorkouts,
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        itemCount: allItems.length,
        itemBuilder: (context, index) {
          final item = allItems[index];

          if (item is String && item != 'divider') {
            // Section header
            return _buildSectionTitle(item);
          } else if (item == 'divider') {
            // Divider between sections
            return const SizedBox(height: 44);
          } else if (item is Workout) {
            // Workout card
            return _buildWorkoutCard(context, item);
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 25,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildWorkoutCard(BuildContext context, Workout workout) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Material(
        color: const Color(0xFFFBC93D),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => WorkoutDetailPage(workout: workout),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    workout.imagePath,
                    width: 100,
                    height: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fitness_center,
                          size: 40,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        workout.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D2D2D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        workout.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}