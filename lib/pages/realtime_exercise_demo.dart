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

  final _exercises = <String>[
    'Jumping Jacks',
    'Russian Twist',
    'Leg Raises',
    'Mountain Climber',
    'Plank',
    'Cobra Stretch',
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await PoseDetectionService.initialize(runningMode: RunMode.LIVE_STREAM);
      PoseDetectionService.startListening();

      await RealtimeExerciseService.I.start(exerciseName: 'Leg Raises');
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

  void _switchExercise(String name) {
    RealtimeExerciseService.I.switchExercise(name);
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
      appBar: AppBar(
        title: const Text('Realtime Exercise Demo'),
        actions: [
          IconButton(
            icon: Icon(_preferredLens == CameraLensDirection.back ? Icons.camera_front : Icons.camera_rear),
            onPressed: _toggleLens,
            tooltip: 'Switch camera',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _resetExercise, tooltip: 'Reset'),
        ],
      ),
      body: Stack(
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
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _TopBar(
              current: ex.name,
              items: _exercises,
              onChange: _switchExercise,
              lens: _preferredLens,
              onToggleLens: _toggleLens,
            ),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: _StatsPanel(
              fps: _frame?.fps ?? 0.0,
              inferenceMs: _frame?.inferenceMs ?? 0,
              detected: _frame?.isPoseDetected ?? false,
              ex: ex,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final List<String> items;
  final String current;
  final ValueChanged<String> onChange;
  final CameraLensDirection lens;
  final Future<void> Function() onToggleLens;

  const _TopBar({
    required this.items,
    required this.current,
    required this.onChange,
    required this.lens,
    required this.onToggleLens,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Text('Exercise:', style: TextStyle(color: Colors.white)),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: current,
              dropdownColor: Colors.black87,
              iconEnabledColor: Colors.white,
              items: items
                  .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.white)),
              ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChange(v);
              },
              underline: const SizedBox.shrink(),
            ),
            const Spacer(),
            Text(
              lens == CameraLensDirection.back ? 'Back Cam' : 'Front Cam',
              style: const TextStyle(color: Colors.white70),
            ),
            IconButton(
              onPressed: onToggleLens,
              icon: Icon(lens == CameraLensDirection.back ? Icons.camera_front : Icons.camera_rear, color: Colors.white),
              tooltip: 'Switch camera',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsPanel extends StatelessWidget {
  final double fps;
  final int inferenceMs;
  final bool detected;
  final ExerciseType ex;
  const _StatsPanel({required this.fps, required this.inferenceMs, required this.detected, required this.ex});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.black.withOpacity(0.55),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _chip('FPS', fps.toStringAsFixed(1)),
                _chip('Inference', '$inferenceMs ms'),
                _chip('Pose', detected ? 'Detected' : 'Not detected', color: detected ? Colors.green : Colors.red),
                _chip('Exercise', ex.name),
              ],
            ),
            const SizedBox(height: 8),
            if (ex.isTimed)
              Text('Time: ${ex.elapsedSec.toStringAsFixed(1)} / ${ex.targetTimeSec.toStringAsFixed(0)} s',
                  style: const TextStyle(color: Colors.white, fontSize: 16))
            else
              Text('Reps: ${ex.count} / ${ex.targetReps}', style: const TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 6),
            Text(ex.feedback, style: TextStyle(color: ex.isCorrect ? Colors.greenAccent : Colors.orangeAccent, fontSize: 15)),
            if (ex.completed)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text('COMPLETED!', style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value, {Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('$label: ', style: const TextStyle(color: Colors.white70)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}