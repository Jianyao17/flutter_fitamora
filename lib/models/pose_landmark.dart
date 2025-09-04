// Model data untuk pose landmarks
class PoseLandmark {
  final double x;
  final double y;
  final double z;
  final double visibility;
  final double presence;

  PoseLandmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
    required this.presence,
  });

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'z': z,
      'visibility': visibility,
      'presence': presence,
    };
  }
}