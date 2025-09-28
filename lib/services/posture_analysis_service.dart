import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/exercise/exercise.dart';
import '../models/posture/posture_analysis.dart';
import '../models/posture/posture_prediction.dart';
import '../models/posture/posture_result.dart';

/// Service class untuk menganalisis postur tubuh dengan berkomunikasi ke API server.
class PostureAnalysisService {
  // --- Konfigurasi API ---
  // !!! GANTI DENGAN URL PUBLIK DARI PLATFORM HOSTING ANDA (misal: Railway, Heroku) !!!
  // Pastikan menggunakan https jika server Anda mengalihkannya.
  static const String _apiUrl = 'https://flutterfitamora-production.up.railway.app/predict';

  /// Private constructor for singleton pattern
  PostureAnalysisService._();
  static final PostureAnalysisService _instance = PostureAnalysisService._();
  factory PostureAnalysisService() => _instance;

  /// Helper function untuk mendapatkan subtype MIME dari path file.
  /// Ini memastikan Content-Type yang dikirim ke server akurat.
  String _getMimeType(String filePath) {
    // Ambil bagian terakhir setelah titik untuk mendapatkan ekstensi
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
        return 'png';
      case 'jpg':
      case 'jpeg':
      case 'jfif':
        return 'jpeg';
      case 'bmp':
        return 'bmp';
      case 'webp':
        return 'webp';
      default:
      // Default ke 'jpeg' jika ekstensi tidak dikenali,
      // karena ini adalah format yang paling umum.
        return 'jpeg';
    }
  }

  /// Menganalisis gambar postur dengan mengirimkannya ke server dan mengembalikan hasil lengkap.
  /// Ini adalah fungsi utama yang akan dipanggil dari UI.
  Future<PostureResult> analyzePosture(File imageFile) async {
    print("🚀 Sending image to posture analysis API...");

    try {
      // 1. Membuat permintaan multipart
      final request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      // 2. Melampirkan file gambar dengan Content-Type yang dinamis
      final mimeType = _getMimeType(imageFile.path);
      print("   - Detected image type: image/$mimeType");

      request.files.add(
        await http.MultipartFile.fromPath(
          'image', // field name harus 'image' sesuai dengan API Flask
          imageFile.path,
          // Menggunakan tipe MIME yang sudah dideteksi agar sesuai dengan file aslinya
          contentType: MediaType('image', mimeType),
        ),
      );

      // 3. Mengirim permintaan dan menunggu respons
      // Menambahkan timeout untuk mencegah aplikasi hang jika server tidak merespons
      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));

      // 4. Membaca dan decode respons
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        print("✅ API response received successfully!");
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Pastikan respons dari server sukses
        if (jsonResponse['success'] != true) {
          final error = jsonResponse['error'] ?? 'Unknown error from server';
          throw Exception('API Error: $error');
        }

        // 5. Memetakan (mapping) respons JSON ke model Dart yang ada
        return _mapResponseToPostureResult(jsonResponse);
      } else {
        // Menangani error dari server (misal: 400, 500)
        print("❌ API request failed with status: ${streamedResponse.statusCode}");
        print("   Error body: $responseBody");
        throw Exception(
            'Failed to analyze posture. Server returned status ${streamedResponse.statusCode}');
      }
    } catch (e) {
      // Menangani error jaringan, timeout, atau lainnya
      print("❌ An error occurred during posture analysis: $e");
      throw Exception(
          "Could not connect to the analysis service. Please check your network connection and try again.");
    }
  }

  /// Helper function untuk mengubah respons JSON dari server menjadi objek PostureResult.
  PostureResult _mapResponseToPostureResult(Map<String, dynamic> json)
  {
    // Ekstrak data utama dari JSON
    final predictionData = json['prediction'] as Map<String, dynamic>;
    final analysisData = json['analysis'] as Map<String, dynamic>;
    final detailedPredictions =
    json['detailed_predictions'] as Map<String, dynamic>;

    // Membuat objek PosturePrediction
    final posturePrediction = PosturePrediction(
      className: predictionData['primary_status'] as String,
      confidence: (predictionData['overall_confidence'] as num).toDouble() * 100.0,
      status: analysisData['status'] as String,
    );

    // Membuat objek PostureAnalysis
    final List<Exercise> exerciseProgram =
    (analysisData['exercise_program'] as List)
        .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
        .toList();

    final postureAnalysis = PostureAnalysis(
      problems: List<String>.from(analysisData['problems'] as List),
      suggestions: List<String>.from(analysisData['suggestions'] as List),
      colorHex: analysisData['color'] as String,
      exerciseProgram: exerciseProgram,
    );

    // Membuat map probabilitas kelas
    final Map<String, double> classProbabilities = {};
    detailedPredictions.forEach((key, value) {
      classProbabilities[key] =
          (value['probability'] as num).toDouble() * 100.0;
    });

    print("📊 Mapped data successfully!");
    print("   - Predicted Class: ${posturePrediction.className}");
    print("   - Confidence: ${posturePrediction.confidence.toStringAsFixed(2)}%");
    print("   - Status: ${analysisData['status']}");

    // Menggabungkan semua menjadi objek PostureResult
    return PostureResult(
      prediction: posturePrediction,
      analysis: postureAnalysis,
      classProbabilities: classProbabilities,
    );
  }

  // Helper function untuk memformat nama kelas (dapat dipertahankan jika masih berguna di UI)
  static String formatClassName(String className) => className
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1))
      .join(' ');
}