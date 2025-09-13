import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../models/exercise/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../services/pose_rigging_painter.dart';
import '../services/realtime_exercise_service.dart';

class RealtimeExerciseDemoPage extends StatefulWidget {
  const RealtimeExerciseDemoPage({super.key});

  @override
  State<RealtimeExerciseDemoPage> createState() => _RealtimeExerciseDemoPageState();
}

class _RealtimeExerciseDemoPageState extends State<RealtimeExerciseDemoPage> {
  CameraController? _camera;
  List<CameraDescription> _cameras = const [];
  CameraLensDirection _preferredLens = CameraLensDirection.front;

  StreamSubscription<ProcessedExerciseFrame>? _sub;
  ProcessedExerciseFrame? _frame;

  bool _busy = false;
  String? _error;

  final _exerciseTypes = ExerciseType.values;

  // FPS tracking
  int _frames = 0;
  DateTime _fpsStart = DateTime.now();
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await PoseDetectionService.initialize(runningMode: RunMode.LIVE_STREAM);
      PoseDetectionService.startListening();

      // Mulai dengan exercise default (misal: Jumping Jacks)
      await RealtimeExerciseService.I.start(exerciseType: ExerciseType.jumpingJacks);
      _sub = RealtimeExerciseService.I.stream.listen((f) {
        if (mounted) setState(() { _frame = f; });
      });

      _cameras = await availableCameras();
      await _initCamera(_preferredLens);

    } catch (e) {
      if(mounted) setState(() => _error = 'Init error: $e');
    }
  }

  Future<void> _initCamera(CameraLensDirection lens) async {
    try {
      if (_camera != null) {
        await _camera!.stopImageStream();
        await _camera!.dispose();
        _camera = null;
      }

      final cam = _cameras.firstWhere(
            (c) => c.lensDirection == lens,
        orElse: () => _cameras.isNotEmpty ? _cameras.first : throw 'No camera found',
      );

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await ctrl.initialize();
      if (!mounted) return;

      await ctrl.startImageStream(_process);
      setState(() {
        _camera = ctrl;
        _preferredLens = lens;
      });
    } catch (e) {
      if(mounted) setState(() => _error = 'Camera init error: $e');
    }
  }

  void _process(CameraImage image) {
    if (_busy) return;
    _busy = true;

    _frames++;
    final now = DateTime.now();
    final dt = now.difference(_fpsStart).inMilliseconds;
    if (dt >= 1000) {
      _fps = (_frames * 1000) / dt;
      _frames = 0;
      _fpsStart = now;
    }

    PoseDetectionService.detectImageStream(image).whenComplete(() => _busy = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    RealtimeExerciseService.I.stop();
    _camera?.dispose();
    PoseDetectionService.stopListening();
    super.dispose();
  }

  void _switchExercise(ExerciseType type) => RealtimeExerciseService.I.switchExercise(type);
  void _resetExercise() => RealtimeExerciseService.I.resetExercise();
  Future<void> _toggleLens() async {
    final next = _preferredLens == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back;
    await _initCamera(next);
  }

  @override
  Widget build(BuildContext context) {
    if (_camera == null || !_camera!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Realtime Exercise Demo')),
        body: Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator()),
      );
    }

    final pose = _frame?.pose;
    final ex = _frame?.exercise ?? RealtimeExerciseService.I.current;

    return Scaffold(
      // Latar belakang netral untuk seluruh halaman
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        bottom: false, // Biarkan panel bawah menutupi area aman
        child: Column(
          children: [
            // Header kuning (gaya lama dipertahankan)
            _buildHeader(ex),

            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CameraPreview(_camera!),
                  if (pose != null && pose.isPoseDetected)
                    CustomPaint(
                      painter: PoseRiggingPainter(
                        poseResult: pose,
                        imageSize: pose.imageSize ?? Size.zero,
                        rotationDegrees: _camera!.description.sensorOrientation,
                        mirror: _camera!.description.lensDirection == CameraLensDirection.front,
                      ),
                    ),
                  _buildFormOverlay(ex),
                ],
              ),
            ),

            // Panel bawah dengan warna netral/gelap (sesuai permintaan)
            _buildStatsPanel(ex),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Exercise exercise) {
    return Container(
      color: Colors.amber,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: DropdownButton<ExerciseType>(
              value: exercise.type,
              isExpanded: true,
              dropdownColor: Colors.amber.shade600,
              underline: const SizedBox.shrink(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              items: _exerciseTypes.map((type) => DropdownMenuItem(
                value: type,
                child: Text(
                  Exercise.create(type).name,
                  style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (newType) => newType != null ? _switchExercise(newType) : null,
            ),
          ),
          IconButton(
            icon: Icon(_preferredLens == CameraLensDirection.back ? Icons.camera_front : Icons.camera_rear),
            onPressed: _toggleLens, tooltip: 'Switch camera', color: Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetExercise, tooltip: 'Reset', color: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildFormOverlay(Exercise exercise) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: exercise.isCorrect ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(exercise.isCorrect ? Icons.check : Icons.close, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(exercise.isCorrect ? 'BENAR' : 'SALAH', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsPanel(Exercise exercise) {
    // Menggunakan warna gelap yang konsisten, bukan amber
    return Container(
      color: const Color(0xFF212121), // Warna abu-abu gelap
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32), // Padding bawah lebih besar untuk area aman
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.isTimed
                          ? 'Waktu: ${exercise.elapsedSec.toStringAsFixed(1)}s / ${exercise.targetTimeSec}s'
                          : 'Repetisi: ${exercise.count} / ${exercise.targetReps}',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: exercise.progress,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(exercise.isCorrect ? Colors.green : Colors.orange),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Feedback AI section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  exercise.feedback,
                  style: TextStyle(
                    color: exercise.isCorrect ? Colors.greenAccent.shade100 : Colors.orangeAccent.shade100,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Tampilkan detail AI hanya untuk Plank
                if (exercise.type == ExerciseType.plank && exercise.aiFormStatus != "Unknown")
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'AI Form: ${exercise.aiFormStatus} (Confidence: ${exercise.aiConfidence.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: exercise.aiFormStatus == "Correct" ? Colors.cyanAccent : Colors.yellowAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (exercise.completed)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Text(
                '🎉 LATIHAN SELESAI! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.greenAccent.shade400, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }
}