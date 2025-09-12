import 'package:flutter/material.dart';

import '../models/exercise.dart';
import '../models/exercise_guide.dart';
import '../models/posture_model.dart';

class HasilDeteksiPage extends StatelessWidget {
  final PostureResult result;

  const HasilDeteksiPage({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Memanggil fungsi getPlanFor yang sudah aman
    final List<DailyPlan> exercisePlan = ExerciseRepository.getPlanFor(result.prediction.className);
    final String problemName = result.prediction.className.replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSummaryCard(problemName),
          const SizedBox(height: 24),
          // Jika exercisePlan kosong, bagian ini tidak akan dirender, mencegah error.
          if (exercisePlan.isNotEmpty)
            _buildExerciseSection(context, exercisePlan)
          else
            _buildEmptyState(), // Menampilkan pesan jika tidak ada latihan
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String problemName) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deteksi Postur Berhasil!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Text(
            result.prediction.className == 'normal'
                ? 'Selamat, postur Anda dalam kategori Normal.'
                : 'Anda terdeteksi memiliki permasalahan "$problemName" pada postur Anda.',
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseSection(BuildContext context, List<DailyPlan> plan) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Rekomendasi Latihan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Set Latihan'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: plan.map((dailyPlan) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: _buildDayCard(dailyPlan),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCard(DailyPlan dailyPlan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Text(
              dailyPlan.day,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Column(
            children: dailyPlan.exercises.map((exercise) => _buildExerciseTile(exercise)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseTile(Exercise exercise) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(exercise.icon, color: Colors.black54, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 2),
                    Text('${exercise.totalSets} set x ${exercise.reps}', style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.description,
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87),
                ),
                if (exercise.guides != null && exercise.guides!.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text('Panduan Visual:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Column(
                    children: exercise.guides!.map((guide) => _buildGuideStep(guide)).toList(),
                  ),
                ]
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildGuideStep(ExerciseGuide guide) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8.0),
            child: Image.network(
              guide.imageUrl,
              height: 180,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 40)),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Text(
            guide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Text(
          'Tidak ada rekomendasi latihan yang tersedia saat ini.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }
}

// ====================================================================
// ============ KELAS DATA DENGAN FUNGSI YANG DIPERBAIKI ==============
// ====================================================================

class DailyPlan {
  final String day;
  final List<Exercise> exercises;
  DailyPlan({required this.day, required this.exercises});
}

class ExerciseRepository {
  static final Map<String, List<DailyPlan>> _plans = {
    'forward_head_kyphosis': [
      DailyPlan(day: 'Day 1: Fokus Leher & Punggung Atas', exercises: [
        Exercise(
          name: 'Chin Tucks',
          description: 'Latihan untuk memperkuat otot leher bagian dalam dan memperbaiki postur kepala.',
          totalSets: 3,
          reps: '15 repetisi',
          icon: Icons.accessibility_new,
        ),
        Exercise(
          name: 'Wall Angels',
          description: 'Membantu meningkatkan mobilitas bahu dan punggung atas.',
          totalSets: 3,
          reps: '10 repetisi',
          icon: Icons.person_outline,
        ),
      ]),
    ],
    'anterior_pelvic_tilt': [
      DailyPlan(day: 'Day 1: Penguatan Glutes & Core', exercises: [
        Exercise(
          name: 'Glute Bridges',
          description: 'Mengaktifkan dan memperkuat otot bokong (glutes) untuk membantu menstabilkan panggul.',
          totalSets: 3,
          reps: '15 repetisi',
          icon: Icons.arrow_upward,
        ),
        Exercise(
            name: 'Plank',
            description: 'Memperkuat seluruh otot inti (core) yang penting untuk postur.',
            totalSets: 3,
            reps: '45 detik'),
      ]),
    ],
    // Saya sengaja mengosongkan 'normal' di sini untuk membuktikan bahwa kodenya aman
    // Anda bisa mengisinya kembali nanti.
    'normal': [
      DailyPlan(day: 'Rencana Pemeliharaan Postur', exercises: [
        Exercise(
            name: 'Plank',
            description: 'Memperkuat seluruh otot inti (core) yang penting untuk postur.',
            totalSets: 3,
            reps: '45 detik'),
      ]),
    ]
  };

  // ====================== FUNGSI YANG DIPERBAIKI ======================
  static List<DailyPlan> getPlanFor(String className) {
    // 1. Coba dapatkan rencana spesifik.
    final specificPlan = _plans[className];
    if (specificPlan != null) {
      return specificPlan;
    }

    // 2. Jika tidak ada, coba dapatkan rencana 'normal' sebagai cadangan.
    final normalPlan = _plans['normal'];
    if (normalPlan != null) {
      return normalPlan;
    }

    // 3. Jika KEDUANYA GAGAL, kembalikan daftar kosong untuk mencegah crash.
    return [];
  }
// ====================================================================
}