import 'package:flutter/material.dart';

import 'deteksi_postur.dart';
import 'realtime_exercise_demo.dart';
import 'workout_list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 1; // Index untuk 'Home'

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // SARAN 1: Placeholder diubah menjadi kartu program aktif yang informatif
              _buildActiveProgramCard(
                title: 'Program Perbaikan Skoliosis',
                progress: 1 / 7, // Hari 1 dari 7
                day: 1,
                totalDays: 7,
              ),
              const SizedBox(height: 24),
              _buildFeatureCard(
                context: context,
                title: 'Deteksi Postur Tubuh',
                imagePath: 'assets/build/a1.png',
                onTap: ()
                {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (c) => const DeteksiPosturPage(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Program Latihan',
                imagePath: 'assets/build/a2.png',
                onTap: () {
                  Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const WorkoutListPage(),
                  ),
                );},
              ),
              const SizedBox(height: 16),
              _buildFeatureCard(
                context: context,
                title: 'Latihan Realtime',
                imagePath: 'assets/build/a3.png',
                onTap: ()
                {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (c) => const RealtimeExerciseDemoPage(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            // SARAN 2: Gunakan ikon outline yang lebih modern
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        // SARAN 3: Warna yang lebih menarik
        selectedItemColor: const Color(0xFFF2C94C), // Kuning yang lebih lembut
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed, // Agar semua label terlihat
        onTap: _onItemTapped,
      ),
    );
  }

  // Widget untuk kartu program aktif (pengganti bar abu-abu)
  Widget _buildActiveProgramCard({
    required String title,
    required double progress,
    required int day,
    required int totalDays,
  }) {
    return Container(
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
    );
  }

  // Widget reusable untuk kartu fitur
  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        // SARAN 4: Warna gradien dan shadow untuk efek modern
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
                  // Loading builder untuk user experience yang lebih baik
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
                        color: Color(0xFF2F80ED), // Biru
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        // SARAN 5: Ikon yang lebih modern (chevron)
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