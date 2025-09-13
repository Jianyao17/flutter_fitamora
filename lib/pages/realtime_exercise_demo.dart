import 'dart:async';
import 'package:flutter/material.dart';

import '../models/exercise/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../services/realtime_exercise_service.dart';
import '../widgets/pose_camera_view.dart';

class RealtimeExerciseDemoPage extends StatefulWidget {
  const RealtimeExerciseDemoPage({super.key});

  @override
  State<RealtimeExerciseDemoPage> createState() => _RealtimeExerciseDemoPageState();
}

class _RealtimeExerciseDemoPageState extends State<RealtimeExerciseDemoPage>
{
  bool _useFrontCamera = true;
  bool _isInitialized = false;
  String? _error;

  final _exerciseTypes = ExerciseType.values;

  final Stopwatch _fpsStopwatch = Stopwatch();
  int _frameCounter = 0;
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async
  {
    try {
      setState(() {
        _error = null;
      });

      // Initialize native camera service
      await PoseDetectionService.initialize(runningMode: RunMode.LIVE_STREAM);

      // Start exercise service
      await RealtimeExerciseService.I.start(exerciseType: ExerciseType.jumpingJacks);

      // Mulai Stopwatch saat inisialisasi berhasil
      _fpsStopwatch.start();

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      setState(() {
        _error = 'Init error: $e';
      });
    }
  }

  @override
  void dispose()
  {
    // Hentikan stopwatch
    _fpsStopwatch.stop();
    RealtimeExerciseService.I.stop();

    // Panggil dispose setelah semua service dihentikan
    PoseDetectionService.dispose();
    super.dispose();
  }

  void _switchExercise(ExerciseType type)
  {
    RealtimeExerciseService.I.switchExercise(type);
    setState(() {});
  }

  void _resetExercise()
  => RealtimeExerciseService.I.resetExercise();

  Future<void> _toggleCamera() async
  {
    try {
      // Saat ganti kamera, PoseCameraView akan handle start/stop,
      // jadi kita tidak perlu reset stopwatch.
      final isFrontCamera = await PoseDetectionService.switchCamera();
      setState(() {
        _useFrontCamera = isFrontCamera;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to switch camera: $e';
      });
    }
  }

  void _onCameraError(String error) {
    setState(() {
      _error = error;
    });
  }


  @override
  Widget build(BuildContext context)
  {
    if (!_isInitialized)
    {
      return Scaffold(
        appBar: AppBar(title: const Text('Realtime Exercise Demo')),
        body: Center(
            child: _error != null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _init,
                  child: const Text('Retry'),
                ),
              ],
            )
                : const CircularProgressIndicator()
        ),
      );
    }


    final currentExercise = RealtimeExerciseService.I.current;
    final size = MediaQuery.of(context).size;

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
                  _frameCounter++;
                  if (_fpsStopwatch.elapsedMilliseconds >= 1000)
                  {
                    // Hitung FPS
                    _fps = (_frameCounter * 1000) / _fpsStopwatch.elapsedMilliseconds;
                    // Reset stopwatch dan counter
                    _fpsStopwatch.reset();
                    _frameCounter = 0;

                    // Panggil setState setelah build selesai untuk menghindari error
                    WidgetsBinding.instance
                      .addPostFrameCallback((_)
                      {
                          if (mounted) {
                            setState(() {});
                          }
                      });
                  }

                  final frame = snapshot.data;
                  final ex = frame?.exercise ?? currentExercise;

                  return Column(
                    children: [
                      SizedBox( // Gunakan SizedBox sebagai ganti Container
                        width: size.width,
                        height: size.width * (4 / 3), // Aspect ratio 4:3
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Native Camera Preview dengan Pose Overlay
                            PoseCameraView(
                              useFrontCamera: _useFrontCamera,
                              showPoseOverlay: true,
                              onError: _onCameraError,
                            ),

                            // Status overlay (BENAR/SALAH)
                            _buildFormOverlay(ex),

                            // Feedback card
                            if (ex.feedback.isNotEmpty || ex.completed)
                              Positioned(
                                bottom: 16, left: 16, right: 16,
                                child: _buildFeedbackCard(ex),
                              ),
                          ],
                        ),
                      ),

                      // Stats panel
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
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              )).toList(),
              onChanged: (newType) => newType != null ? _switchExercise(newType) : null,
            ),
          ),
          IconButton(
            icon: Icon(_useFrontCamera ? Icons.camera_rear : Icons.camera_front),
            onPressed: _toggleCamera,
            tooltip: 'Switch camera',
            color: Colors.black,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetExercise,
            tooltip: 'Reset',
            color: Colors.black,
          ),
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

  Widget _buildStatsPanel(Exercise exercise, ProcessedExerciseFrame? frame)
  {
    final poseDetected = frame?.isPoseDetected ?? false;
    return Container(
      color: const Color(0xFF212121).withOpacity(0.8),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _chip('FPS', _fps.toStringAsFixed(1)),
              _chip('Inference', '${frame?.inferenceMs ?? 0} ms'),
              _chip(
                'Pose',
                poseDetected ? 'Detected' : 'Not Detected',
                valueColor: poseDetected ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 16),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: exercise.progress,
                      backgroundColor: Colors.grey.shade700,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        exercise.isCorrect ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(Exercise exercise)
  {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Text(
                exercise.feedback,
                style: TextStyle(
                  color: exercise.isCorrect
                      ? Colors.greenAccent.shade100
                      : Colors.orangeAccent.shade100,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (exercise.type == ExerciseType.plank && exercise.aiFormStatus != "Unknown")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'AI Form: ${exercise.aiFormStatus} (Confidence: ${exercise.aiConfidence.toStringAsFixed(2)})',
                    style: TextStyle(
                      fontSize: 12,
                      color: exercise.aiFormStatus == "Correct"
                          ? Colors.cyanAccent
                          : Colors.yellowAccent,
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
              style: TextStyle(
                color: Colors.greenAccent.shade400,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}