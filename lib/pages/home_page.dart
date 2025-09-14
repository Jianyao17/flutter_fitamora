import 'package:flutter/material.dart';

import '../data/user_database.dart';
import '../data/workout_database.dart';
import '../models/user_model.dart';
import '../models/exercise/workout_program.dart';

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

class _HomePageState extends State<HomePage> {
  Future<void> _navigateAndWaitChanges(BuildContext context, Widget page) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (c) => page,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context)
  {
    final User activeUser = UserDatabase.instance.activeUser;
    final WorkoutProgram activeProgram = WorkoutDatabase.instance.activeWorkoutProgram;

    // PERUBAHAN UTAMA: Variabel boolean untuk memeriksa apakah ada program aktif
    final bool hasActiveProgram = activeProgram.totalDays > 0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Fitamora',
          textAlign: TextAlign.start,
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: Colors.black54, size: 28),
            tooltip: 'Profil Pengguna',
            onPressed: () {
              _navigateAndWaitChanges(context, const ProfilePage());
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeHeader(
                name: activeUser.fullName.isNotEmpty ? activeUser.fullName : 'Pengguna',
              ),
              const SizedBox(height: 24),

              // --- LOGIKA TAMPILAN KARTU UTAMA ---
              // Jika ADA program aktif, tampilkan kartu program.
              // Jika TIDAK ADA, tampilkan kartu instruksi.
              if (hasActiveProgram)
                _buildActiveProgramCard(
                  title: activeProgram.title,
                  progress: activeProgram.progressPercent,
                  day: activeProgram.currentDay,
                  totalDays: activeProgram.totalDays,
                )
              else
                _buildInstructionCard(), // Memanggil widget baru
              // ------------------------------------

              const SizedBox(height: 24),

              const Text(
                'Jelajahi Fitur',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              _buildFeatureCard(
                context: context,
                title: 'Deteksi Postur Tubuh',
                imagePath: 'assets/build/a1.png', // Pastikan path benar
                onTap: () => _navigateAndWaitChanges(context, const DeteksiPosturPage()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Pilih Latihan',
                imagePath: 'assets/build/a2.png', // Pastikan path benar
                onTap: () => _navigateAndWaitChanges(context, const ListLatihanPage()),
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Live Community',
                imagePath: 'assets/build/a3.png', // Pastikan path benar
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BARU: Kartu instruksi saat tidak ada program aktif
  Widget _buildInstructionCard()
  {
    return GestureDetector(
      // Arahkan ke halaman Deteksi Postur saat diklik
      onTap: () => _navigateAndWaitChanges(context, const DeteksiPosturPage()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          // Gunakan warna yang menarik perhatian
          color: const Color(0xFF003366), // Biru tua sesuai tema
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 40),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Tidak Ada Program Aktif',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text('Mulai deteksi postur untuk mendapatkan program latihan yang dipersonalisasi.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      height: 1.4, // Atur jarak antar baris
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }


  Widget _buildWelcomeHeader({required String name})
  {
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

  Widget _buildActiveProgramCard({
    required String title,
    required double progress,
    required int day,
    required int totalDays,
  }) {
    return Card(
      elevation: 4.0, // Memberi efek bayangan agar terangkat
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell( // Menggunakan InkWell untuk efek ripple saat ditekan
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (c) => ProgramLatihanAktifPage(
                  activeProgram: WorkoutDatabase.instance.activeWorkoutProgram),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row( // Menggunakan Row untuk menempatkan ikon di kanan
            children: [
              // Konten utama (teks dan progress bar)
              Expanded(
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
                          '${(progress * 100).toInt()}%',
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
              // Ikon panah di sebelah kanan
              const SizedBox(width: 16),
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

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