import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../models/exercise/workout_program.dart';
import '../data/workout_database.dart';
import '../data/user_database.dart';

import 'latihan/list_latihan_page.dart';
import 'latihan/program_latihan_aktif.dart';
import 'latihan/realtime_latihan_page.dart';
import 'deteksi_postur_page.dart';
import 'profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
{
  // Method untuk navigasi yang sudah ada, ini bagus untuk me-refresh state
  Future<void> _navigateAndWaitChanges(BuildContext context, Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => page,
      ),
    );
    // Panggil setState untuk membangun ulang HomePage dan mendapatkan data terbaru
    setState(() {});
  }

  @override
  Widget build(BuildContext context)
  {
    // Ambil data user dan program latihan yang aktif
    final User activeUser = UserDatabase.instance.activeUser;
    final WorkoutProgram activeProgram = WorkoutDatabase.instance.activeWorkoutProgram;

    return Scaffold(
      // 1. TAMBAHKAN APPBAR
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        // Hapus tombol back otomatis jika halaman ini adalah root setelah login
        automaticallyImplyLeading: false,
        title: const Text('Fitamora',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // Tambahkan tombol aksi untuk navigasi ke halaman profil
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.black54, size: 28),
            tooltip: 'Profil Pengguna',
            onPressed: () {
              // Gunakan method navigasi yang sudah ada untuk membuka halaman profil
              _navigateAndWaitChanges(context, const ProfilePage());
            },
          ),
          const SizedBox(width: 8), // Beri sedikit jarak di kanan
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. TAMBAHKAN HEADER PENYAMBUT PENGGUNA
              _buildWelcomeHeader(
                // Jika nama kosong, tampilkan "Pengguna"
                name: activeUser.fullName.isNotEmpty ? activeUser.fullName : 'Pengguna',
              ),
              const SizedBox(height: 24),

              // Tampilkan kartu program aktif jika ada judulnya
              if (activeProgram.title.isNotEmpty)
                _buildActiveProgramCard(
                  title: activeProgram.title,
                  progress: activeProgram.progressPercent,
                  day: activeProgram.currentDay,
                  totalDays: activeProgram.totalDays,
                ),
              const SizedBox(height: 24),

              // Judul untuk bagian fitur
              const Text(
                'Jelajahi Fitur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                title: 'Deteksi Postur Tubuh',
                imagePath: 'assets/build/a1.png',
                onTap: () => _navigateAndWaitChanges(context, const DeteksiPosturPage()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Pilih Latihan',
                imagePath: 'assets/build/a2.png',
                onTap: () => _navigateAndWaitChanges(context, const ListLatihanPage()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Latihan Realtime',
                imagePath: 'assets/build/a3.png',
                onTap: () => _navigateAndWaitChanges(context, const RealtimeLatihanPage()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BARU: Header untuk menyambut pengguna
  Widget _buildWelcomeHeader({required String name}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selamat Datang,',
          style: TextStyle(
            fontSize: 22,
            color: Colors.grey[600],
          ),
        ),
        Text(
          name,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  // Widget untuk kartu program aktif (tidak ada perubahan)
  Widget _buildActiveProgramCard({
    required String title,
    required double progress,
    required int day,
    required int totalDays,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (c) => ProgramLatihanAktifPage(
                activeProgram: WorkoutDatabase.instance.activeWorkoutProgram),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PROGRAM LATIHAN AKTIF',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hari $day dari $totalDays',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  '${(progress * 100).toInt()}% Selesai',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[300],
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF2C94C)),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget reusable untuk kartu fitur (tidak ada perubahan)
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDEB71), Color(0xFFF8D800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Image.asset(
                  imagePath,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF2F80ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}