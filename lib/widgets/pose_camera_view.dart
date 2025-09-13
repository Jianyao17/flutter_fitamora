import 'package:flutter/material.dart';

import '../models/pose_mediapipe/pose_detection_result.dart';
import '../services/pose_detection_service.dart';
import 'pose_rigging_painter.dart';

class PoseCameraView extends StatefulWidget
{
  final bool useFrontCamera;
  final bool showPoseOverlay;
  final VoidCallback? onCameraError;
  final Function(String)? onError;

  const PoseCameraView({
    super.key,
    this.useFrontCamera = true,
    this.showPoseOverlay = true,
    this.onCameraError,
    this.onError,
  });

  @override
  State<PoseCameraView> createState() => _PoseCameraViewState();
}

class _PoseCameraViewState extends State<PoseCameraView> with WidgetsBindingObserver
{
  bool _isInitialized = false;
  String? _error;

  // Ganti state untuk menyimpan textureId dan previewSize
  int? _textureId;
  Size? _previewSize;
  PoseDetectionResult? _lastPoseResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    // Handle app lifecycle events
    if (state == AppLifecycleState.paused) {
      // Native side (MainActivity) akan otomatis stop kamera
    } else if (state == AppLifecycleState.resumed) {
      // Restart kamera jika sebelumnya sudah berjalan
      if (_isInitialized && _textureId == null) {
        _startCamera();
      }
    }
  }

  Future<void> _initializeCamera() async
  {
    try {
      setState(() { _error = null; });
      await PoseDetectionService.initialize(runningMode: RunMode.LIVE_STREAM);
      PoseDetectionService.startPoseListening();

      setState(() { _isInitialized = true; });

      await _startCamera();
    } catch (e) {
      final errorMsg = 'Failed to initialize camera: $e';
      setState(() { _error = errorMsg; });
      widget.onError?.call(errorMsg);
    }
  }

  Future<void> _startCamera() async
  {
    if (!_isInitialized) return;
    try {
      await PoseDetectionService.startCamera(useFrontCamera: widget.useFrontCamera);
      setState(() {
        _textureId = PoseDetectionService.textureId;
        _previewSize = PoseDetectionService.previewSize;
        _error = null;
      });
    } catch (e) {
      final errorMsg = 'Failed to start camera: $e';
      setState(() {
        _error = errorMsg;
        _textureId = null;
        _previewSize = null;
      });
      widget.onError?.call(errorMsg);
    }
  }

  Future<void> _stopCamera() async
  {
    try {
      await PoseDetectionService.stopCamera();
      PoseDetectionService.stopListening();
      setState(() {
        _textureId = null;
        _previewSize = null;
      });
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  Future<void> switchCamera() async
  {
    if (_textureId == null) return;
    try {
      // Untuk switch, kita stop kamera lama dan start lagi dengan setting baru
      await _stopCamera();
      await _startCamera(); // startCamera akan menggunakan nilai `useFrontCamera` yang baru
    } catch (e) {
      widget.onError?.call('Failed to switch camera: $e');
    }
  }

  @override
  Widget build(BuildContext context)
  {
    if (_error != null) {
      return _buildErrorWidget();
    }
    if (!_isInitialized || _textureId == null || _previewSize == null)
    { return _buildLoadingWidget(); }

    return AspectRatio(
      aspectRatio: _previewSize!.width / _previewSize!.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Gunakan Texture widget untuk menampilkan preview
          Texture(textureId: _textureId!),

          // Overlay pose detection
          if (widget.showPoseOverlay)
            StreamBuilder<PoseDetectionResult>(
              stream: PoseDetectionService.poseStream,
              builder: (context, poseSnapshot) {
                if (poseSnapshot.hasData) {
                  _lastPoseResult = poseSnapshot.data;
                }
                if (_lastPoseResult != null) {
                  return CustomPaint(
                    painter: PoseRiggingPainter(
                      poseResult: _lastPoseResult!,
                      imageSize: _lastPoseResult!.imageSize ?? Size.zero,
                      mirror: !widget.useFrontCamera,
                      rotationDegrees: 0,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget()
  {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeCamera,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget()
  {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}