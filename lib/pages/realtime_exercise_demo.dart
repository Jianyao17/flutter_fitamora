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

  bool _busy = false;
  String? _error;

  final _exerciseTypes = ExerciseType.values;

  // FPS tracking
  int _frames = 0;
  DateTime _fpsStart = DateTime.now();
  double _fps = 0.0;

  // Frame skipping
  int _frameCounter = 0;
  final int _detectionInterval = 3;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await PoseDetectionService.initialize(runningMode: RunMode.LIVE_STREAM);
      PoseDetectionService.startListening();

      // Mulai service, StreamBuilder akan menangani sisanya.
      await RealtimeExerciseService.I.start(exerciseType: ExerciseType.jumpingJacks);

      _cameras = await availableCameras();
      await _initCamera(_preferredLens);

    } catch (e) {
      if(mounted) setState(() => _error = 'Init error: $e');
    }
  }

  Future<void> _initCamera(CameraLensDirection lens) async
  {
    try {
      if (_camera != null)
      {
        await _camera!.stopImageStream();
        await _camera!.dispose();
        _camera = null;
      }

      final cam = _cameras.firstWhere(
          (c) => c.lensDirection == lens,
          orElse: () => _cameras.first);

      final ctrl = CameraController(cam,
          ResolutionPreset.low,
          imageFormatGroup: ImageFormatGroup.yuv420,
          enableAudio: false);

      await ctrl.initialize();

      if (!mounted) return;
      await ctrl.startImageStream(_process);

      // Panggil setState sekali di sini untuk membangun ulang UI setelah kamera siap.
      setState(() {
        _camera = ctrl;
        _preferredLens = lens;
      });
    } catch (e) {
      if(mounted) setState(() => _error = 'Camera init error: $e');
    }
  }

  void _process(CameraImage image)
  {
    _frameCounter++;
    if (_frameCounter % _detectionInterval != 0) return;
    if (_busy) return;
    _busy = true;

    // Perhitungan FPS tetap di sini
    _frames++;
    final now = DateTime.now();
    final dt = now.difference(_fpsStart).inMilliseconds;
    if (dt >= 1000)
    {
      final newFps = (_frames * 1000 * _detectionInterval) / dt;
      _frames = 0;
      _fpsStart = now;

      // Perbarui state FPS di sini agar widget chip bisa di-rebuild
      if (mounted) setState(() => _fps = newFps);
    }

    PoseDetectionService.detectImageStream(image).whenComplete(() => _busy = false);
  }

  @override
  void dispose()
  {
    RealtimeExerciseService.I.stop();
    _camera?.dispose();
    PoseDetectionService.stopListening();
    super.dispose();
  }

  void _switchExercise(ExerciseType type)
  {
    RealtimeExerciseService.I.switchExercise(type);
    // Panggil setState agar DropdownButton diperbarui nilainya
    setState(() {});
  }

  void _resetExercise() => RealtimeExerciseService.I.resetExercise();
  Future<void> _toggleLens() async => await _initCamera(_preferredLens == CameraLensDirection.back ? CameraLensDirection.front : CameraLensDirection.back);

  @override
  Widget build(BuildContext context)
  {
    if (_camera == null || !_camera!.value.isInitialized)
    {
      return Scaffold(
        appBar: AppBar(title: const Text('Realtime Exercise Demo')),
        body: Center(child: _error != null ? Text(_error!) : const CircularProgressIndicator()),
      );
    }

    // Ambil exercise saat ini untuk header, yang tidak perlu di-rebuild terus-menerus
    final currentExercise = RealtimeExerciseService.I.current;

    // Ambil ukuran layar untuk perhitungan rasio aspek
    final size = MediaQuery.of(context).size;

    // Hitung rasio aspek kamera
    // Hindari pembagian dengan nol jika aspectRatio tidak valid
    final cameraAspectRatio = _camera!.value.aspectRatio;

    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(currentExercise),
            Expanded(
              child: StreamBuilder<ProcessedExerciseFrame>(
                stream: RealtimeExerciseService.I.stream,
                builder: (context, snapshot)
                {
                  final frame = snapshot.data;
                  final pose = frame?.pose;
                  final ex = frame?.exercise ?? currentExercise;

                  return Column(
                    children: [
                      // --- BAGIAN 1: Blok Kamera dengan ukuran pasti ---
                      Container(
                        width: size.width,
                        height: size.width * cameraAspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Kamera Preview dengan rasio aspek yang benar
                            ClipRect(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: size.width,
                                  height: size.width * cameraAspectRatio,
                                  child: CameraPreview(_camera!),
                                ),
                              ),
                            ),
                            // Painter untuk pose
                            CustomPaint(
                              painter: PoseRiggingPainter(
                                poseResult: pose,
                                imageSize: pose?.imageSize ?? Size.zero,
                                rotationDegrees: _camera!.description.sensorOrientation,
                                mirror: _camera!.description.lensDirection == CameraLensDirection.front,
                              ),
                            ),
                            // Overlay untuk status "BENAR/SALAH"
                            _buildFormOverlay(ex),

                            // Kartu feedback di bagian bawah tengah
                            if (ex.feedback.isNotEmpty || ex.completed)
                              Positioned(
                                bottom: 16, left: 16, right: 16,
                                child: _buildFeedbackCard(ex),
                              ),
                          ],
                        ),
                      ),

                      // --- BAGIAN 2: Panel Statistik yang mengisi sisa ruang ---
                      Expanded(
                        child: _buildStatsPanel(ex, frame),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Exercise exercise)
  {
    // Widget ini sekarang hanya akan di-rebuild saat _switchExercise dipanggil
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
          IconButton(icon: Icon(_preferredLens == CameraLensDirection.back ? Icons.camera_front : Icons.camera_rear), onPressed: _toggleLens, tooltip: 'Switch camera', color: Colors.black),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetExercise, tooltip: 'Reset', color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildFormOverlay(Exercise exercise)
  {
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
            Container(width: 40, height: 40, decoration: BoxDecoration(color: exercise.isCorrect ? Colors.green : Colors.red, shape: BoxShape.circle), child: Icon(exercise.isCorrect ? Icons.check : Icons.close, color: Colors.white, size: 24)),
            const SizedBox(height: 4),
            Text(exercise.isCorrect ? 'BENAR' : 'SALAH', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Ubah signature untuk menerima frame
  Widget _buildStatsPanel(Exercise exercise, ProcessedExerciseFrame? frame)
  {
    final poseDetected = frame?.isPoseDetected ?? false;
    return Container(
      color: const Color(0xFF212121).withOpacity(0.8), // Beri sedikit transparansi
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip('FPS', _fps.toStringAsFixed(1)),
              _chip('Inference', '${frame?.inferenceMs ?? 0} ms'),
              _chip('Pose', poseDetected ? 'Detected' : 'Not Detected', valueColor: poseDetected ? Colors.greenAccent : Colors.redAccent),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child:
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.isTimed ? 'Waktu: ${exercise.elapsedSec.toStringAsFixed(1)}s / ${exercise.targetTimeSec}s' : 'Repetisi: ${exercise.count} / ${exercise.targetReps}',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(value: exercise.progress, backgroundColor: Colors.grey.shade700, valueColor: AlwaysStoppedAnimation<Color>(exercise.isCorrect ? Colors.green : Colors.orange)),
                ]
              )),
          ]),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Exercise exercise)
  {
    // Gunakan Column untuk menumpuk kotak feedback dan teks "Latihan Selesai"
    // jika keduanya perlu ditampilkan.
    return Column(
      mainAxisSize: MainAxisSize.min, // Agar Column tidak mengambil ruang berlebih
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8)
          ),
          child: Column(
            children: [
              Text(
                exercise.feedback,
                style: TextStyle(
                  color: exercise.isCorrect ? Colors.greenAccent.shade100 : Colors.orangeAccent.shade100,
                  fontSize: 15,
                  fontWeight: FontWeight.w500
                ),
                textAlign: TextAlign.center
              ),
              if (exercise.type == ExerciseType.plank && exercise.aiFormStatus != "Unknown")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'AI Form: ${exercise.aiFormStatus} (Confidence: ${exercise.aiConfidence.toStringAsFixed(2)})',
                    style: TextStyle(
                        fontSize: 12,
                        color: exercise.aiFormStatus == "Correct" ? Colors.cyanAccent : Colors.yellowAccent,
                        fontWeight: FontWeight.w500
                    ),
                  ),
                ),
            ]
          )
        ),
        // Tampilkan pesan selesai di bawah kartu jika latihan telah selesai
        if (exercise.completed)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text(
                '🎉 LATIHAN SELESAI! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.greenAccent.shade400,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, String value, {Color valueColor = Colors.white})
  {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w600, fontSize: 12)),
      ]),
    );
  }
}


