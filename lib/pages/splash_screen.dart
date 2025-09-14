import 'package:flutter/material.dart';

import '../data/user_database.dart';
import '../services/ai_model_service.dart';
import '../services/pose_detection_service.dart';
import '../services/posture_analysis_service.dart';
import 'login/login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
{

  @override
  void initState() {
    super.initState();
    _initializeAppAndNavigate();
  }

  /// Fungsi ini akan menjalankan semua proses inisialisasi yang dibutuhkan
  /// sebelum aplikasi dapat digunakan.
  Future<void> _initializeAppAndNavigate() async
  {
    // 1. Inisialisasi model AI
    await PoseDetectionService.initialize();
    await AIModelService.I.loadModels();

    // 2. Inisialisasi database user
    await UserDatabase.instance.init();

    // Jeda sebentar untuk menampilkan splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Pastikan widget masih ada di tree sebelum melakukan navigasi
    if (!mounted) return;

    // Arahkan pengguna ke halaman yang sesuai.
    // Gunakan pushReplacement agar pengguna tidak bisa kembali ke splash screen.
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => LoginPage()
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    // UI yang Anda minta: Logo di tengah, loading indicator di bawahnya.
    return Scaffold(
      backgroundColor: Colors.white, // Latar belakang putih
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Pusatkan secara vertikal
          children: [
            // 1. Logo dari aset Anda
            Image.asset(
              'assets/img/logo_apps.png', // PENTING: Pastikan path ini benar!
              width: 150, // Atur ukuran logo sesuai keinginan Anda
            ),
            const SizedBox(height: 24), // Jarak antara logo dan loading

            // 2. Loading circular di bawah logo
            const CircularProgressIndicator(
              // Atur warna agar sesuai dengan tema aplikasi Anda
              color: Color(0xFF003366),
            ),
          ],
        ),
      ),
    );
  }
}