// Model data untuk pose landmarks
class PoseLandmark {
  final double x;
  final double y;
  final double z;
  final double visibility;

  PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'visibility': visibility,
    };
  }
}