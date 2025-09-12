import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import '../models/posture_model.dart';

/// Service class untuk berinteraksi dengan Posture Detection API.
class PoseImageService
{
  // PENTING: Ganti dengan alamat IP dan port dari server Flask Anda.
  // Jika menjalankan di emulator Android, gunakan 10.0.2.2.
  // Jika menjalankan di perangkat fisik, gunakan alamat IP lokal komputer Anda (misal: 192.168.1.10).
  static final String _baseUrl = 'http://192.168.43.101:5000';

  /// Mengirim gambar untuk dideteksi dan mengembalikan hasil analisis.
  ///
  /// [imageFile] adalah file gambar yang akan dikirim.
  /// Throws Exception jika terjadi error.
  static Future<PostureResult> detectPosture(File imageFile) async
  {
    final uri = Uri.parse('$_baseUrl/predict');

    // Membuat multipart request untuk mengirim file gambar.
    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image', // 'image' harus sesuai dengan key yang diharapkan di Flask API
        imageFile.path,
      ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          return PostureResult.fromJson(responseData);
        } else {
          throw Exception('API Error: ${responseData['error']}');
        }
      } else {
        // Error dari server (misal: 500, 404)
        throw Exception('Server error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Error jaringan atau koneksi
      throw Exception('Failed to connect to the server. Please check your connection and API address.');
    }
  }
}