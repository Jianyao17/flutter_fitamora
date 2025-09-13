import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../data/posture_database.dart';
import '../models/posture/posture_analysis.dart';
import '../models/posture/posture_prediction.dart';
import '../models/posture/posture_result.dart';

/// Service class untuk menganalisis postur tubuh secara lokal menggunakan TFLite.
class PostureAnalysisService {
  // --- Konfigurasi Model ---
  static const String _modelPath = 'assets/models/posture_model.tflite';
  static const String _labelsPath = 'assets/models/posture_labels.txt';
  static const int _inputSize = 224; // Ukuran input sesuai model MobileNetV2

  // --- State TFLite ---
  Interpreter? _interpreter;
  List<String>? _labels;

  /// Private constructor for singleton pattern
  PostureAnalysisService._();
  static final PostureAnalysisService _instance = PostureAnalysisService._();
  factory PostureAnalysisService() => _instance;

  /// Memuat model TFLite dan label dari assets.
  /// Harus dipanggil sekali sebelum menjalankan analisis.
  Future<void> _loadModel() async
  {
    // Mencegah reload jika sudah ada
    if (_interpreter != null && _labels != null) {
      print("Model and labels already loaded.");
      return;
    }

    try {
      print("📦 Loading model and labels...");

      // Memuat model
      _interpreter = await Interpreter.fromAsset(_modelPath);

      // Memuat label
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData.split('\n')
          .map((label) => label.trim())
          .where((label) => label.isNotEmpty)
          .toList();

      print("✅ Model and labels loaded successfully!");
      print("   - Input tensor: ${_interpreter!.getInputTensor(0).shape}");
      print("   - Output tensor: ${_interpreter!.getOutputTensor(0).shape}");
      print("   - Labels: $_labels");

    } catch (e) {
      print("❌ Failed to load model or labels: $e");
      _interpreter = null;
      _labels = null;
      throw Exception("Could not initialize posture analysis service.");
    }
  }

  /// Memproses gambar input menjadi format yang sesuai untuk model TFLite.
  /// 1. Decode gambar
  /// 2. Resize ke 224x224
  /// 3. Normalisasi piksel (0-255 -> 0-1)
  /// 4. Ubah menjadi Float32List
  Future<Uint8List> _preprocessImage(File imageFile) async
  {
    print("🔍 Preprocessing image...");

    // 1. Baca dan decode gambar menggunakan package 'image'
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes);

    if (originalImage == null) {
      throw Exception("Failed to decode image.");
    }

    // 2. Resize gambar
    final resizedImage = img.copyResize(
      originalImage,
      width: _inputSize,
      height: _inputSize,
    );

    // 3. Konversi ke Float32List dan normalisasi
    // Model MobileNetV2 mengharapkan input [1, 224, 224, 3]
    // Nilai piksel dinormalisasi antara 0 dan 1
    final imageBytesAsFloat = Float32List(_inputSize * _inputSize * 3);
    int bufferIndex = 0;
    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        final pixel = resizedImage.getPixel(x, y);
        imageBytesAsFloat[bufferIndex++] = pixel.r / 255.0;
        imageBytesAsFloat[bufferIndex++] = pixel.g / 255.0;
        imageBytesAsFloat[bufferIndex++] = pixel.b / 255.0;
      }
    }

    // Reshape ke [1, 224, 224, 3]
    return imageBytesAsFloat.buffer.asUint8List();
  }


  /// Menganalisis gambar postur dan mengembalikan hasil lengkap.
  /// Ini adalah fungsi utama yang akan dipanggil dari UI.
  Future<PostureResult> analyzePosture(File imageFile) async
  {
    // Pastikan model sudah dimuat
    await _loadModel();

    if (_interpreter == null || _labels == null) {
      throw Exception("Service not initialized. Call _loadModel() first.");
    }

    // 1. Preprocess gambar
    final input = await _preprocessImage(imageFile);

    // Output model memiliki shape [1, 3] sesuai jumlah kelas
    final output = List.filled(1 * _labels!.length, 0.0).reshape([1, _labels!.length]);

    // 2. Jalankan inferensi
    print("🔮 Running model prediction...");
    _interpreter!.run(input.buffer.asFloat32List().reshape([1, _inputSize, _inputSize, 3]), output);

    // 3. Post-process hasil
    final List<double> scores = output[0] as List<double>;
    print("📊 Raw prediction scores: $scores");

    // Cari indeks dengan skor tertinggi
    double maxScore = 0;
    int maxIndex = -1;
    for (int i = 0; i < scores.length; i++) {
      if (scores[i] > maxScore) {
        maxScore = scores[i];
        maxIndex = i;
      }
    }

    if (maxIndex == -1) {
      throw Exception("Failed to get prediction from model.");
    }

    final predictedClass = _labels![maxIndex];
    final confidence = maxScore * 100;

    print("✅ Prediction successful!");
    print("   - Class: $predictedClass");
    print("   - Confidence: ${confidence.toStringAsFixed(2)}%");

    // 4. Dapatkan analisis detail berdasarkan kelas prediksi
    final analysis = PostureDatabase.getPostureItemAnalysis(predictedClass);
    print(analysis.name);

    // 5. Buat mapping probabilitas kelas
    final Map<String, double> classProbabilities = {};
    for (int i = 0; i < _labels!.length; i++) {
      classProbabilities[_labels![i]] = scores[i] * 100;
    }

    // 6. Gabungkan semua data menjadi satu objek PostureResult
    return PostureResult(
      prediction: PosturePrediction(
        className: predictedClass,
        confidence: confidence,
        status: analysis.status, // Ambil status dari analisis
      ),
      analysis: PostureAnalysis(
        problems: analysis.problems,
        suggestions: analysis.suggestions,
        colorHex: analysis.colorHex,
        exerciseProgram: analysis.exerciseProgram,
      ),
      classProbabilities: classProbabilities,
    );
  }

  // Helper function untuk memformat nama kelas
  static String formatClassName(String className)
  => className.split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}