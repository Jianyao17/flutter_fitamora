import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../models/exercise_type.dart';
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
  CameraLensDirection _preferredLens = CameraLensDirection.back;

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

      await RealtimeExerciseService.I.start(exerciseType: ExerciseType.legRaises);
      _sub = RealtimeExerciseService.I.stream.listen((f) {
        _frame = f;
        if (mounted) setState(() {});
      });

      _cameras = await availableCameras();
      await _initCamera(_preferredLens);

      setState(() {});
    } catch (e) {
      setState(() => _error = 'Init error: $e');
    }
  }

  Future<void> _initCamera(CameraLensDirection lens) async {
    try {
      // hentikan kamera lama bila ada
      if (_camera != null) {
        try { await _camera!.stopImageStream(); } catch (_) {}
        try { await _camera!.dispose(); } catch (_) {}
        _camera = null;
      }

      // pilih kamera sesuai arah lensa
      final cam = _cameras.firstWhere(
            (c) => c.lensDirection == lens,
        orElse: () => _cameras.isNotEmpty ? _cameras.first : throw 'No camera found',
      );

      final ctrl = CameraController(
        cam,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
        fps: 24,
      );
      await ctrl.initialize();

      if (!mounted) return;

      await ctrl.startImageStream(_process);
      setState(() {
        _camera = ctrl;
        _preferredLens = lens;
      });
    } catch (e) {
      setState(() => _error = 'Camera init error: $e');
    }
  }

  void _process(CameraImage image) {
    if (_busy) return;
    _busy = true;
    
    // Update FPS
    _frames++;
    final now = DateTime.now();
    final dt = now.difference(_fpsStart).inMilliseconds;
    if (dt >= 1000) {
      _fps = (_frames * 1000) / dt;
      _frames = 0;
      _fpsStart = now;
    }
    
    PoseDetectionService.detectImageStream(image).whenComplete(() {
      _busy = false;
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    RealtimeExerciseService.I.stop();
    _camera?.stopImageStream();
    _camera?.dispose();
    PoseDetectionService.stopListening();
    super.dispose();
  }

  void _switchExercise(ExerciseType type) {
    RealtimeExerciseService.I.switchExercise(type);
    setState(() {});
  }

  void _resetExercise() {
    RealtimeExerciseService.I.resetExercise();
    setState(() {});
  }

  Future<void> _toggleLens() async {
    final next = _preferredLens == CameraLensDirection.back
        ? CameraLensDirection.front
        : CameraLensDirection.back;
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
      body: Column(
        children: [
          // Header kuning
          _buildHeader(ex),
          
          // Area kamera dengan overlay pose
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
                // Overlay untuk form feedback
                _buildFormOverlay(ex),
              ],
            ),
          ),
          
          // Stats panel di bawah dengan tema kuning
          _buildStatsPanel(ex),
        ],
      ),
    );
  }

  Widget _buildHeader(Exercise exercise) {
    return Container(
      color: Colors.amber,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown untuk memilih exercise
                    DropdownButton<ExerciseType>(
                      value: exercise.type,
                      isExpanded: true,
                      underline: const SizedBox.shrink(),
                      items: _exerciseTypes
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(
                          Exercise.create(type).name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ))
                          .toList(),
                      onChanged: (ExerciseType? newType) {
                        if (newType != null) _switchExercise(newType);
                      },
                    ),
                    Text(
                      '${exercise.count} / ${exercise.targetReps} Repetisi',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_preferredLens == CameraLensDirection.back ? Icons.camera_front : Icons.camera_rear),
                onPressed: _toggleLens,
                tooltip: 'Switch camera',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _resetExercise,
                tooltip: 'Reset',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.shade700),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: exercise.targetReps > 0 ? (exercise.count / exercise.targetReps).clamp(0.0, 1.0) : 0.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${exercise.count} / ${exercise.targetReps} Repetisi',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                ),
              ),
            ],
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
            // Form indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: exercise.isCorrect ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                exercise.isCorrect ? Icons.check : Icons.close,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              exercise.isCorrect ? 'BENAR' : 'SALAH',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildStatsPanel(Exercise exercise) {
    return Container(
      color: Colors.amber,
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header dengan stats
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _chip('FPS', _fps.toStringAsFixed(1), isDark: false),
                    _chip('Inference', '${_frame?.inferenceMs ?? 0} ms', isDark: false),
                    _chip('Pose', _frame?.isPoseDetected == true ? 'Detected' : 'Not detected', 
                          color: _frame?.isPoseDetected == true ? Colors.green : Colors.red, isDark: false),
                    _chip('Exercise', exercise.name, isDark: false),
                  ],
                ),
              ),
              // State indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStateColor(exercise),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _getStateText(exercise),
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          
          // Progress section
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (exercise.isTimed) ...[
                      Text(
                        'Time: ${exercise.elapsedSec.toStringAsFixed(1)} / ${exercise.targetTimeSec.toStringAsFixed(0)}s',
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: exercise.progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ] else ...[
                      Text(
                        'Reps: ${exercise.count} / ${exercise.targetReps}',
                        style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: exercise.progress,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Feedback AI section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: exercise.isCorrect ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Feedback AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  exercise.feedback,
                  style: TextStyle(
                    color: exercise.isCorrect ? Colors.green.shade800 : Colors.orange.shade800,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (exercise.aiFormStatus != null && exercise.aiFormStatus != "Unknown") ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        exercise.aiFormStatus == "Correct" ? Icons.check_circle : Icons.warning,
                        color: exercise.aiFormStatus == "Correct" ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        exercise.aiFeedback ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: exercise.aiFormStatus == "Correct" ? Colors.green.shade800 : Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Completion message
          if (exercise.completed) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Text(
                '🎉 EXERCISE COMPLETED! 🎉',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, String value, {Color color = Colors.black, bool isDark = true}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ', 
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54, 
              fontSize: 12,
            ),
          ),
          Text(
            value, 
            style: TextStyle(
              color: color, 
              fontWeight: FontWeight.w600, 
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStateColor(Exercise exercise) {
    if (exercise.completed) return Colors.green;
    if (exercise.isCorrect) return Colors.blue;
    return Colors.orange;
  }

  String _getStateText(Exercise exercise) {
    if (exercise.completed) return 'DONE';
    if (exercise.isCorrect) return 'GOOD';
    return 'FIX';
  }
}