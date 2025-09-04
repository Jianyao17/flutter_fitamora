import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../models/pose_realtime_data.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_rigging_painter.dart';


class PoseDetectionLiveDemo extends StatefulWidget {
  const PoseDetectionLiveDemo({super.key});

  @override
  State<PoseDetectionLiveDemo> createState() => _PoseDetectionLiveDemoState();
}

class _PoseDetectionLiveDemoState extends State<PoseDetectionLiveDemo> with WidgetsBindingObserver {
  // Service dan Controller
  final PoseDetectionService _poseService = PoseDetectionService();
  CameraController? _cameraController;

  // State untuk data yang akan digambar
  PoseRealtimeData? _painterData;

  // State untuk status inisialisasi
  bool _isInitializing = true;
  String _initializationMessage = 'Initializing service...';

  // State untuk pelacakan performa
  int _frameCounter = 0;
  double _fps = 0;
  Timer? _fpsTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializePage();

    // Timer untuk menghitung FPS setiap detik
    _fpsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _fps = _frameCounter.toDouble();
          _frameCounter = 0;
        });
      }
    });
  }

  /// Inisialisasi service dan kamera secara berurutan.
  Future<void> _initializePage() async {
    // 1. Inisialisasi service
    await _poseService.initialize();

    // 2. Inisialisasi kamera
    setState(() => _initializationMessage = 'Initializing camera...');
    final cameras = await availableCameras();
    // Prioritaskan kamera depan untuk demo yang lebih interaktif
    final camera = cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium, // OPTIMASI: Resolusi medium sudah cukup & lebih cepat
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420, // Format paling umum di Android
    );

    await _cameraController!.initialize();

    // 3. Mulai streaming data
    await _startStreaming();

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  /// Menghubungkan stream dari service ke UI dan memulai stream dari kamera.
  Future<void> _startStreaming() async {
    // Dengarkan hasil dari service. Setiap data baru akan memicu penggambaran ulang.
    _poseService.resultStream?.listen((data) {
      if (mounted) {
        setState(() => _painterData = data);
        _frameCounter++; // Hitung frame yang berhasil diproses
      }
    });

    // Mulai kirim frame dari kamera ke service.
    // Service memiliki guard `_isProcessing` untuk menangani frame-dropping secara otomatis.
    _cameraController!.startImageStream(
          (image) => _poseService.detectPoseFromCamera(image),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fpsTimer?.cancel();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    super.dispose();
  }

  /// Menangani siklus hidup aplikasi (misalnya, saat aplikasi di-minimize).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializePage(); // Inisialisasi ulang saat aplikasi kembali aktif
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isInitializing ? _buildLoadingUI() : _buildCameraUI(),
    );
  }

  Widget _buildLoadingUI() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            _initializationMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraUI() {
    final size = MediaQuery.of(context).size;
    final cameraPreview = _cameraController!.value;
    // Hitung aspect ratio untuk memastikan feed kamera tidak terdistorsi
    final scale = size.aspectRatio * cameraPreview.aspectRatio;
    final double scaleFactor = (scale < 1) ? 1 / scale : scale;

    return Stack(
      children: [
        // Widget untuk menampilkan hasil visualisasi
        if (_painterData != null)
          Transform.scale(
            scale: scaleFactor,
            child: Center(
              child: CustomPaint(
                painter: PoseRiggingPainter(
                  image: _painterData!.image,
                  poseResult: _painterData!.result,
                ),
              ),
            ),
          )
        else
        // Tampilkan CameraPreview jika belum ada data sama sekali
          Center(child: CameraPreview(_cameraController!)),

        // Tampilan FPS counter di pojok atas
        _buildFpsCounter(),
      ],
    );
  }

  Widget _buildFpsCounter() {
    return Positioned(
      top: 40,
      left: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'FPS: ${_fps.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.lightGreenAccent,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}