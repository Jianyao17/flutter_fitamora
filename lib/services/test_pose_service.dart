import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class SimplePoseService {
  Interpreter? _poseLandmarkDetector;

  bool get isLoaded => _poseLandmarkDetector != null;

  Future<void> loadModel() async {
    try {
      _poseLandmarkDetector = await Interpreter.fromAsset('assets/models/pose_landmarks_detector.tflite');

      print("✅ Pose landmarks model loaded successfully");
    } catch (e) {
      print("❌ Error loading model: $e");
      rethrow;
    }
  }

  /// Preprocess image for MediaPipe models
  Float32List _preprocessImage(img.Image image, int targetSize) {
    final resized = img.copyResize(image, width: targetSize, height: targetSize);

    final Float32List input = Float32List(1 * targetSize * targetSize * 3);
    int index = 0;

    for (int y = 0; y < targetSize; y++) {
      for (int x = 0; x < targetSize; x++) {
        final pixel = resized.getPixel(x, y);
        // Normalisasi gambar ke rentang [0, 1] seperti kode asli.
        // Jika akurasi kurang baik, coba normalisasi [-1, 1]
        // (pixel.r - 127.5) / 127.5
        input[index++] = pixel.r / 255.0;
        input[index++] = pixel.g / 255.0;
        input[index++] = pixel.b / 255.0;
      }
    }

    return input;
  }

  /// Direct landmark detection without pose detection step
  Future<List<List<double>>> detectLandmarksDirect(img.Image image) async {
    // Pengecekan awal yang paling penting. Jika interpreter null, jangan lanjutkan.
    if (_poseLandmarkDetector == null) {
      print("❌ Error: Pose landmark detector is not initialized. Make sure loadModel() has completed successfully.");
      return [];
    }

    // Buat variabel lokal yang non-nullable untuk menghindari penggunaan `!` berulang kali.
    final interpreter = _poseLandmarkDetector!;

    try {
      print("🔍 Processing image: ${image.width}x${image.height}");

      final input = _preprocessImage(image, 256);
      final inputTensor = input.reshape([1, 256, 256, 3]);

      // 1. Dapatkan semua tensor output dari interpreter.
      final outputTensors = interpreter.getOutputTensors();
      final Map<int, Object> outputs = {};

      // 2. Siapkan buffer untuk setiap tensor output.
      for (int i = 0; i < outputTensors.length; i++) {
        final tensor = outputTensors[i];
        final shape = tensor.shape;
        // Membuat list bersarang yang cocok dengan dimensi tensor.
        if (shape.length == 2) { // Untuk shape seperti [1, 195]
          outputs[i] = List.generate(shape[0], (_) => List.filled(shape[1], 0.0));
        } else {
          // Fallback untuk bentuk lain jika ada, agar tidak crash.
          int totalSize = shape.reduce((a, b) => a * b);
          outputs[i] = List.filled(totalSize, 0.0).reshape(shape);
        }
      }

      // 3. Jalankan inferensi.
      interpreter.runForMultipleInputs([inputTensor], outputs);

      // 4. Cari output yang berisi data landmark ([1, 195]).
      dynamic landmarkOutput;
      for (final output in outputs.values) {
        if (output is List && output.isNotEmpty && output[0] is List && output[0].length == 195) {
          landmarkOutput = output;
          break;
        }
      }

      // 5. Lakukan parsing hanya jika output landmark ditemukan.
      if (landmarkOutput == null) {
        print("❌ Error: Could not find landmark output with shape [1, 195] in model outputs.");
        print("   Available output shapes: ${outputTensors.map((t) => t.shape).toList()}");
        print("   Actual outputs received: ${outputs.values}");
        return [];
      }

      final flatLandmarks = (landmarkOutput as List<List<double>>)[0];

      // Lanjutkan dengan logika parsing yang sudah benar.
      List<List<double>> landmarks = [];
      const int numLandmarks = 33;
      const int valuesPerLandmark = 5;

      for (int i = 0; i < numLandmarks; i++) {
        final baseIndex = i * valuesPerLandmark;
        if (baseIndex + (valuesPerLandmark - 1) < flatLandmarks.length) {
          landmarks.add([
            flatLandmarks[baseIndex],     // x
            flatLandmarks[baseIndex + 1], // y
            flatLandmarks[baseIndex + 2], // z
            flatLandmarks[baseIndex + 3], // visibility
            flatLandmarks[baseIndex + 4], // presence
          ]);
        }
      }

      print("✅ Parsed ${landmarks.length} landmarks");

      final visibleLandmarks = landmarks.where((landmark) =>
      landmark.length > 3 && landmark[3] > 0.3).toList();

      print("👁️ Visible landmarks: ${visibleLandmarks.length}");

      return landmarks;

    } catch (e, stackTrace) {
      print("❌ Error detecting landmarks: $e");
      print("Stack trace: $stackTrace"); // Mencetak stack trace akan sangat membantu
      return [];
    }
  }

  void dispose() {
    _poseLandmarkDetector?.close();
  }
}