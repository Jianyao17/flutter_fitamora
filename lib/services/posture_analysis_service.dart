import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../models/exercise.dart';
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
      _labels = labelsData
          .split('\n')
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

    // 4. Dapatkan analisis detail (logika dari backend Python)
    final analysis = _getPostureAnalysis(predictedClass);

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

  /// Menyediakan analisis dan saran berdasarkan kelas prediksi.
  /// Logika ini dipindahkan langsung dari backend Python.
  ({String status,
    List<String> problems,
    List<String> suggestions,
    List<Exercise> exerciseProgram,
    String colorHex}) _getPostureAnalysis(String predictedClass)
  {
    const defaultDesc = "Latihan untuk membantu memperbaiki postur tubuh Anda.";
    switch (predictedClass)
    {
      case 'forward_head_kyphosis':
        return (
        status: 'Perlu Perbaikan',
        problems: [
          'Kepala terlalu maju (Forward Head Posture)',
          'Punggung atas membulat (Kyphosis)',
          'Dapat menyebabkan nyeri leher dan punggung'
        ],
        suggestions: [
          'Lakukan chin tucks exercise 10-15 kali, 3 set per hari',
          'Perbaiki posisi layar komputer sejajar mata',
          'Strengthening otot leher bagian belakang',
          'Wall angel exercise untuk membuka dada',
          'Konsultasi dengan fisioterapis jika nyeri berlanjut'
        ],
        exerciseProgram: [ // Gunakan constructor Exercise yang baru
          Exercise(name: 'Chin tucks', sets: 2, rep: 10, rest: 15, description: defaultDesc),
          Exercise(name: 'Neck retraction', sets: 2, rep: 8, rest: 15, description: defaultDesc),
          Exercise(name: 'Shoulder rolls', sets: 2, rep: 12, rest: 10, description: defaultDesc),
          Exercise(name: 'Deep breathing', sets: 1, duration: 60, description: "Latihan relaksasi dan pernapasan."),
        ],
        colorHex: '#FF9800' // Orange
        );
      case 'anterior_pelvic_tilt':
        return (
        status: 'Perlu Perbaikan',
        problems: [
          'Panggul miring ke depan (Anterior Pelvic Tilt)',
          'Lordosis lumbal berlebihan',
          'Dapat menyebabkan nyeri punggung bawah'
        ],
        suggestions: [
          'Strengthening otot glutes dan hamstring',
          'Stretching otot hip flexor dan erector spinae',
          'Dead bug exercise untuk core stability',
          'Posterior pelvic tilt exercise',
          'Hindari duduk terlalu lama tanpa istirahat'
        ],
        exerciseProgram: [ // Gunakan constructor Exercise yang baru
          Exercise(name: 'Pelvic tilts', sets: 2, rep: 10, rest: 15, description: defaultDesc),
          Exercise(name: 'Knee hugs', sets: 1, duration: 30, rest: 10, description: defaultDesc),
          Exercise(name: 'Cat-cow Stretch', sets: 1, duration: 60, rest: 15, description: defaultDesc),
          Exercise(name: 'Deep breathing', sets: 1, duration: 60, description: "Latihan relaksasi dan pernapasan."),
        ],
        colorHex: '#F44336' // Red
        );
      case 'normal':
      default:
        return (
        status: 'Baik',
        problems: [],
        suggestions: [
          'Postur tubuh Anda sudah baik!',
          'Pertahankan posisi duduk dan berdiri yang benar',
          'Lakukan stretching ringan secara rutin'
        ],
        exerciseProgram: [ // Gunakan constructor Exercise yang baru
          Exercise(name: 'Full body stretch', sets: 1, duration: 120, description: "Latihan peregangan untuk menjaga fleksibilitas."),
          Exercise(name: 'Shoulder circles', sets: 2, rep: 12, rest: 10, description: "Meningkatkan mobilitas sendi bahu."),
          Exercise(name: 'Deep breathing', sets: 1, duration: 120, description: "Latihan relaksasi dan pernapasan."),
        ],
        colorHex: '#4CAF50' // Green
        );
    }
  }
}