import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'dart:io';

import '../services/pose_detection_service.dart';
import '../services/pose_rigging_painter.dart';
import '../models/pose_detection_result.dart';

class PoseDetectionDemo extends StatefulWidget {
  const PoseDetectionDemo({super.key});

  @override
  State<PoseDetectionDemo> createState() => _PoseDetectionDemoState();
}

class _PoseDetectionDemoState extends State<PoseDetectionDemo> {
  final PoseDetectionService _poseService = PoseDetectionService();
  final ImagePicker _picker = ImagePicker();

  File? _selectedImage;
  ui.Image? _processedImage;
  PoseDetectionResult? _poseResult;
  bool _isLoading = false;
  bool _isInitialized = false;
  String _statusMessage = 'Inisialisasi service...';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Memuat model deteksi pose...';
    });

    try {
      final success = await _poseService.initialize();
      if (success) {
        setState(() {
          _isInitialized = true;
          _statusMessage = 'Service siap. Pilih gambar untuk deteksi pose.';
        });
      } else {
        setState(() {
          _statusMessage = 'Gagal menginisialisasi service. Periksa model file.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    if (!_isInitialized) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 100,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error memilih gambar: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    if (!_isInitialized) return;

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        await _processImage(File(image.path));
      }
    } catch (e) {
      _showErrorSnackBar('Error mengambil foto: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _selectedImage = imageFile;
      _poseResult = null;
      _processedImage = null;
      _statusMessage = 'Memproses gambar...';
    });

    try {
      // Konversi File ke UI Image
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImage = frame.image;

      setState(() {
        _processedImage = uiImage;
        _statusMessage = 'Mendeteksi pose...';
      });

      // Deteksi pose
      final result = await _poseService.detectPose(uiImage);

      setState(() {
        _poseResult = result;
        if (result.isPoseDetected) {
          _statusMessage =
          'Pose terdeteksi! Confidence: ${(result.confidence * 100).toStringAsFixed(1)}% '
              '| Landmarks: ${result.landmarks.length} '
              '| Waktu: ${result.processingTimeMs}ms';
        } else {
          _statusMessage = 'Pose tidak terdeteksi. Coba dengan gambar lain.';
        }
      });

    } catch (e) {
      setState(() {
        _statusMessage = 'Error memproses gambar: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildImageDisplay() {
    if (_processedImage == null) {
      return Container(
        height: 400,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Pilih gambar untuk deteksi pose',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: _processedImage!.width / _processedImage!.height,
          child: CustomPaint(
            painter: PoseRiggingPainter(
              image: _processedImage!,
              poseResult: _poseResult,
            ),
            child: Container(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isInitialized && !_isLoading ? _pickImageFromGallery : null,
            icon: const Icon(Icons.photo_library),
            label: const Text('Galeri'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isInitialized && !_isLoading ? _pickImageFromCamera : null,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Kamera'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsInfo() {
    if (_poseResult == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Deteksi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildResultRow('Status', _poseResult!.isPoseDetected ? 'Terdeteksi' : 'Tidak Terdeteksi'),
            _buildResultRow('Confidence', '${(_poseResult!.confidence * 100).toStringAsFixed(1)}%'),
            _buildResultRow('Landmarks', '${_poseResult!.landmarks.length}'),
            _buildResultRow('World Landmarks', '${_poseResult!.worldLandmarks.length}'),
            _buildResultRow('Waktu Proses', '${_poseResult!.processingTimeMs}ms'),
            if (_poseResult!.boundingBox != null) ...[
              const SizedBox(height: 8),
              Text(
                'Bounding Box:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                'Left: ${_poseResult!.boundingBox!.left.toStringAsFixed(1)}, '
                    'Top: ${_poseResult!.boundingBox!.top.toStringAsFixed(1)}, '
                    'Right: ${_poseResult!.boundingBox!.right.toStringAsFixed(1)}, '
                    'Bottom: ${_poseResult!.boundingBox!.bottom.toStringAsFixed(1)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deteksi Pose'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isInitialized
                    ? (_poseResult?.isPoseDetected == true ? Colors.green[50] : Colors.blue[50])
                    : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isInitialized
                      ? (_poseResult?.isPoseDetected == true ? Colors.green[200]! : Colors.blue[200]!)
                      : Colors.orange[200]!,
                ),
              ),
              child: Row(
                children: [
                  if (_isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      _isInitialized
                          ? (_poseResult?.isPoseDetected == true ? Icons.check_circle : Icons.info)
                          : Icons.warning,
                      color: _isInitialized
                          ? (_poseResult?.isPoseDetected == true ? Colors.green[600] : Colors.blue[600])
                          : Colors.orange[600],
                      size: 20,
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _statusMessage,
                      style: TextStyle(
                        color: _isInitialized
                            ? (_poseResult?.isPoseDetected == true ? Colors.green[800] : Colors.blue[800])
                            : Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 20),

            // Image Display
            _buildImageDisplay(),

            const SizedBox(height: 20),

            // Results Info
            _buildResultsInfo(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _poseService.dispose();
    super.dispose();
  }
}