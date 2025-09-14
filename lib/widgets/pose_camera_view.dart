import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../models/pose_mediapipe/pose_detection_result.dart';
import '../services/pose_detection_service.dart';
import 'pose_rigging_painter.dart';

class PoseCameraView extends StatefulWidget {
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

// Tambahkan SingleTickerProviderStateMixin
class _PoseCameraViewState extends State<PoseCameraView>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin
{
  final String _overlayViewType = 'com.example.fitamora/overlay_view';
  bool _isInitialized = false;
  String? _error;

  int? _textureId;
  Size? _previewSize;

  late final Ticker _ticker;
  final Stopwatch _stopwatch = Stopwatch();

  int _frameCounter = 0;
  double _fps = 0.0;
  double _latencyMs = 0.0;


  @override
  void initState()
  {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inisialisasi ticker
    _ticker = createTicker(_onTick);

    _initializeCamera();
  }

  /// Callback yang dipanggil Ticker untuk setiap frame yang dirender Flutter.
  void _onTick(Duration elapsed)
  {
    _frameCounter++;
    // Update FPS setiap 500ms untuk tampilan yang stabil
    if (_stopwatch.elapsedMilliseconds >= 500)
    {
      final elapsedSeconds = _stopwatch.elapsedMilliseconds / 1000.0;
      setState(() {
        _fps = _frameCounter / elapsedSeconds;
        // Hitung latensi rata-rata per frame dalam interval ini
        _latencyMs = _stopwatch.elapsedMilliseconds / _frameCounter;
      });

      // Reset untuk interval berikutnya
      _frameCounter = 0;
      _stopwatch.reset();
    }
  }


  @override
  void dispose()
  {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _ticker.dispose(); // Jangan lupa dispose ticker
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state)
  {
    if (state == AppLifecycleState.resumed) {
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
      await PoseDetectionService.startCamera(
          useFrontCamera: widget.useFrontCamera);
      setState(() {
        _textureId = PoseDetectionService.textureId;
        _previewSize = PoseDetectionService.previewSize;
        _error = null;
      });

      // Mulai Ticker dan Stopwatch setelah kamera siap
      _frameCounter = 0;
      _stopwatch.reset();
      _stopwatch.start();
      _ticker.start();

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
      // Hentikan Ticker sebelum menghentikan kamera
      _ticker.stop();
      _stopwatch.stop();

      await PoseDetectionService.stopCamera();
      PoseDetectionService.stopListening();
      setState(() {
        _textureId = null;
        _previewSize = null;
        _fps = 0.0;
        _latencyMs = 0.0;
      });
    } catch (e) {
      print('Error stopping camera: $e');
    }
  }

  Future<void> switchCamera() async
  {
    if (_textureId == null) return;
    try {
      await _stopCamera();
      // Start kamera akan otomatis memulai lagi tickernya
      await _startCamera();
    } catch (e) {
      widget.onError?.call('Failed to switch camera: $e');
    }
  }

  @override
  Widget build(BuildContext context)
  {
    if (_error != null)
    { return _buildErrorWidget(); }

    if (!_isInitialized || _textureId == null || _previewSize == null)
    { return _buildLoadingWidget(); }

    return AspectRatio(
      aspectRatio: _previewSize!.width / _previewSize!.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Widget Texture untuk menampilkan preview kamera dari native
          Texture(textureId: _textureId!),

          // 2. GANTI StreamBuilder dan CustomPaint dengan AndroidView
          if (widget.showPoseOverlay)
            AndroidView(
              viewType: _overlayViewType,
              // Kita tidak perlu mengirim parameter saat pembuatan untuk kasus ini
              creationParams: const <String, dynamic>{},
              creationParamsCodec: StandardMessageCodec(),
            ),

          // 3. Widget untuk menampilkan FPS,
          _buildFpsCounter(),
        ],
      ),
    );
  }

  /// Widget untuk menampilkan FPS dan latency dalam Card semi-transparan.
  Widget _buildFpsCounter()
  {
    return Align(
      alignment: Alignment.topLeft,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Card(
          color: Colors.black.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('FPS: ${_fps.toStringAsFixed(1)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('${_latencyMs.toStringAsFixed(1)} ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
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
            Text(_error!,
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