import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/workout_database.dart';
import '../models/exercise/workout_plan.dart';
import '../models/exercise/workout_program.dart';
import '../models/posture/posture_result.dart';
import '../services/posture_analysis_service.dart';
import 'latihan/program_latihan_aktif.dart';

// Helper function untuk mengubah string Hex menjadi Color
Color _hexToColor(String code) {
  return Color(int.parse(code.substring(1, 7), radix: 16) + 0xFF000000);
}

class DeteksiPosturPage extends StatefulWidget {
  const DeteksiPosturPage({Key? key}) : super(key: key);

  @override
  State<DeteksiPosturPage> createState() => _DeteksiPosturPageState();
}

class _DeteksiPosturPageState extends State<DeteksiPosturPage> {
  final ImagePicker _picker = ImagePicker();
  final PostureAnalysisService _analysisService = PostureAnalysisService();

  // State untuk manajemen UI
  XFile? _sideImage;
  bool _isLoading = false;
  PostureResult? _result;
  String? _errorMessage;

  /// Fungsi untuk memilih gambar dari galeri atau kamera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _sideImage = pickedFile;
          _result = null; // Reset hasil sebelumnya saat gambar baru dipilih
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal mengambil gambar: $e";
      });
    }
  }

  /// Fungsi untuk memulai proses deteksi
  Future<void> _startDetection() async {
    if (_sideImage == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null; // Hapus hasil lama sebelum memulai
    });

    try {
      final result = await _analysisService.analyzePosture(File(_sideImage!.path));
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Error: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text('Deteksi Postur Tubuh'),
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildImageCard('Foto Samping', _sideImage),

            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text("Menganalisis postur...", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              _buildResultsSection(_result!), // Menampilkan semua hasil
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButton(),
    );
  }

  /// Widget untuk membangun tombol bawah yang dinamis
  Widget _buildBottomButton()
  {
    if (_result != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: ()
          {
            setState(()
            {
              // Atur plan latihan berdasarkan hasil deteksi
              final exercises = _result!.analysis.exerciseProgram;
              final postureName = PostureAnalysisService.formatClassName(_result!.prediction.className);

              WorkoutPlan dailyPlan = WorkoutPlan(
                title: "Perbaikan Postur $postureName",
                description: "Fokus pada penguatan otot inti dan peregangan untuk postur Anda.",
                exercises: exercises,
              );

              if (WorkoutDatabase.instance.activeWorkoutProgram.totalDays <= 0)
              {
                WorkoutProgram newProgram = WorkoutProgram(
                  title: "Program Perbaikan Postur $postureName",
                  description: "Program latihan 3 hari yang dirancang khusus berdasarkan hasil deteksi postur Anda.",
                  totalDays: 3,
                  dailyPlans: [dailyPlan, dailyPlan, dailyPlan],
                  startDate: DateTime.now(),
                );
                // Set sebagai program aktif
                WorkoutDatabase.instance.setActiveProgram(newProgram);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Program latihan "${newProgram.title}" telah dibuat dan diatur sebagai program aktif!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              } else {
                // Tambahkan plan ke program aktif
                WorkoutDatabase.instance.addWorkoutPlan(dailyPlan);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Rencana latihan hari ini telah ditambahkan ke program aktif "${WorkoutDatabase.instance.activeWorkoutProgram.title}"!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }

              // Ke Halaman program latihan
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (c) => ProgramLatihanAktifPage(
                      activeProgram: WorkoutDatabase.instance.activeWorkoutProgram),
                ),
              );
            });
          },
          icon: const Icon(Icons.fitness_center),
          label: const Text('Atur Latihan'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton.icon(
        onPressed: _isLoading || _sideImage == null ? null : _startDetection,
        icon: _isLoading
            ? Container(
          width: 24,
          height: 24,
          padding: const EdgeInsets.all(2.0),
          child: const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        )
            : const Icon(CupertinoIcons.sparkles),
        label: Text(_isLoading ? 'Mendeteksi...' : 'Mulai Deteksi'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// Widget untuk membangun seluruh bagian hasil analisis (KARTU + DETAIL)
  Widget _buildResultsSection(PostureResult result) 
  {
    final prediction = result.prediction;
    final analysis = result.analysis;
    final programLatihan = analysis.exerciseProgram;
    final resultColor = _hexToColor(analysis.colorHex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. KARTU STATUS (RINGKASAN)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: resultColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: resultColor, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Status Postur: ${prediction.status}",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: resultColor),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  children: [
                    const TextSpan(text: "Terdeteksi sebagai "),
                    TextSpan(
                      text: PostureAnalysisService.formatClassName(_result!.prediction.className),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " dengan akurasi ${prediction.confidence.toStringAsFixed(1)}%.",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 2. MASALAH TERDETEKSI (JIKA ADA)
        if (analysis.problems.isNotEmpty) ...[
          _buildSectionTitle('Masalah Terdeteksi'),
          const SizedBox(height: 8),
          ...analysis.problems.map((problem) => _buildInfoListItem(problem, Icons.warning_amber_rounded, Colors.orange)),
          const SizedBox(height: 24),
        ],

        // 3. SARAN PERBAIKAN
        if (analysis.suggestions.isNotEmpty) ...[
          _buildSectionTitle('Saran Perbaikan'),
          const SizedBox(height: 8),
          ...analysis.suggestions.map((suggestion) => _buildInfoListItem(suggestion, Icons.lightbulb_outline, Colors.blue)),
          const SizedBox(height: 24),
        ],

        // 4. REKOMENDASI LATIHAN (SPESIFIK)
        _buildSectionTitle('Rekomendasi Latihan'),
        const SizedBox(height: 16),
        ListView.builder(
          itemCount: programLatihan.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final exercise = programLatihan[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(exercise.icon, color: Theme.of(context).primaryColor),
                ),
                title: Text(exercise.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(exercise.detailsString),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
            );
          },
        ),
      ],
    );
  }

  /// Helper untuk membuat judul setiap bagian
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  /// Helper untuk membuat item list untuk masalah dan saran
  Widget _buildInfoListItem(String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15, height: 1.4))),
        ],
      ),
    );
  }

  /// Widget untuk kartu pemilihan gambar (tidak berubah)
  Widget _buildImageCard(String title, XFile? imageFile) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showImageSourceDialog,
              child: imageFile != null
                  ? Image.file(File(imageFile.path), fit: BoxFit.cover, width: double.infinity)
                  : Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, size: 50, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      const Text('Ketuk untuk memilih gambar', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Menampilkan dialog untuk memilih sumber gambar (tidak berubah)
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                _pickImage(ImageSource.gallery);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Ambil Foto'),
              onTap: () {
                _pickImage(ImageSource.camera);
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }
}