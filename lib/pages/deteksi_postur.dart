// file: pages/detection_page.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/posture_model.dart';
import '../services/pose_image_service.dart';

class DeteksiPosturPage extends StatefulWidget {
  const DeteksiPosturPage({Key? key}) : super(key: key);

  @override
  State<DeteksiPosturPage> createState() => _DeteksiPosturPageState();
}

class _DeteksiPosturPageState extends State<DeteksiPosturPage> {
  final ImagePicker _picker = ImagePicker();

  // State HANYA untuk foto samping
  XFile? _sideImage;

  // State untuk manajemen UI
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
    // Memastikan foto samping sudah dipilih
    if (_sideImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih foto samping terlebih dahulu.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _result = null;
    });

    try {
      // Panggil service dengan file foto samping
      final result = await PoseImageService.detectPosture(File(_sideImage!.path));
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
        title: const Text('Deteksi Postur Tubuh'),
        centerTitle: true,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kontainer untuk pemilihan gambar (hanya satu)
            _buildImageCard('Foto Samping', _sideImage),
            const SizedBox(height: 24),

            // Menampilkan pesan error jika ada
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),

            // Menampilkan hasil deteksi jika sudah ada
            if (_result != null)
              _buildResultCard(_result!),
          ],
        ),
      ),
      // Tombol deteksi di bagian bawah
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _startDetection,
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
      ),
    );
  }

  /// Widget untuk kartu pemilihan gambar (disederhanakan)
  Widget _buildImageCard(String title, XFile? imageFile) {
    return Column(
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: 3 / 4,
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: _showImageSourceDialog, // Panggil dialog
              child: imageFile != null
                  ? Image.file(
                File(imageFile.path),
                fit: BoxFit.cover,
                width: double.infinity,
              )
                  : Container(
                color: Colors.grey.shade100,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          size: 50, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      const Text('Ketuk untuk memilih gambar', style: TextStyle(color: Colors.grey),)
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

  /// Menampilkan dialog untuk memilih sumber gambar (Kamera/Galeri)
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

  /// Widget untuk menampilkan kartu hasil deteksi (Sama seperti sebelumnya)
  Widget _buildResultCard(PostureResult result) {
    final color = Color(int.parse(result.analysis.colorHex.replaceFirst('#', '0xFF')));
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Analisis',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            ListTile(
              leading: Icon(Icons.check_circle_outline, color: color),
              title: Text(result.prediction.status, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18)),
              subtitle: Text(
                '${result.prediction.className.replaceAll('_', ' ')} (Akurasi: ${result.prediction.confidence.toStringAsFixed(1)}%)',
              ),
            ),
            const SizedBox(height: 16),

            if(result.analysis.problems.isNotEmpty) ...[
              _buildSectionTitle('Masalah Terdeteksi'),
              ...result.analysis.problems.map((problem) => _buildListItem(problem, Icons.warning_amber_rounded)),
              const SizedBox(height: 16),
            ],

            _buildSectionTitle('Saran Perbaikan'),
            ...result.analysis.suggestions.map((suggestion) => _buildListItem(suggestion, Icons.lightbulb_outline)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildListItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}