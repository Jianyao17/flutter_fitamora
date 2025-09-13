import '../models/exercise.dart';
import '../models/posture/posture_item.dart';

/// Database singleton untuk menyimpan postur yang dianalisis.
class PostureDatabase
{
  static const defaultDesc = "Latihan untuk membantu memperbaiki postur tubuh Anda.";

  static List<PostureItem> get postures => List.unmodifiable(_postures);
  static final List<PostureItem> _postures = [
    PostureItem(
      name: "forward_head_kyphosis",
      status: 'Perlu Perbaikan',
      problems: [
        'Kepala terlalu maju (Forward Head Posture)',
        'Punggung atas membulat (Kyphosis)',
        'Dapat menyebabkan nyeri leher dan punggung',
      ],
      suggestions: [
        'Lakukan chin tucks exercise 10-15 kali, 3 set per hari',
        'Perbaiki posisi layar komputer sejajar mata',
        'Strengthening otot leher bagian belakang',
        'Wall angel exercise untuk membuka dada',
        'Konsultasi dengan fisioterapis jika nyeri berlanjut',
      ],
      exerciseProgram: [
        Exercise(name: 'Chin tucks', sets: 2, rep: 10, rest: 15, description: defaultDesc),
        Exercise(name: 'Neck retraction', sets: 2, rep: 8, rest: 15, description: defaultDesc),
        Exercise(name: 'Shoulder rolls', sets: 2, rep: 12, rest: 10, description: defaultDesc),
        Exercise(name: 'Deep breathing', sets: 1, duration: 60, description: "Latihan relaksasi dan pernapasan."),
      ],
      colorHex: '#FF9800', // Orange
    ),

    PostureItem(
      name: "anterior_pelvic_tilt",
      status: 'Perlu Perbaikan',
      problems: [
        'Panggul miring ke depan (Anterior Pelvic Tilt)',
        'Lordosis lumbal berlebihan',
        'Dapat menyebabkan nyeri punggung bawah',
      ],
      suggestions: [
        'Strengthening otot glutes dan hamstring',
        'Stretching otot hip flexor dan erector spinae',
        'Dead bug exercise untuk core stability',
        'Posterior pelvic tilt exercise',
        'Hindari duduk terlalu lama tanpa istirahat',
      ],
      exerciseProgram: [
        Exercise(name: 'Pelvic tilts', sets: 2, rep: 10, rest: 15, description: defaultDesc),
        Exercise(name: 'Knee hugs', sets: 1, duration: 30, rest: 10, description: defaultDesc),
        Exercise(name: 'Cat-cow Stretch', sets: 1, duration: 60, rest: 15, description: defaultDesc),
        Exercise(name: 'Deep breathing', sets: 1, duration: 60, description: "Latihan relaksasi dan pernapasan."),
      ],
      colorHex: '#F44336', // Red
    ),
    PostureItem.normal()
  ];

  static PostureItem getPostureItemAnalysis(String name)
    => _postures.firstWhere(
      (item) => item.name.toLowerCase() == name.toLowerCase(),
      orElse: () => PostureItem.empty(),
    );

  static void removePosture(PostureItem posture)
    => _postures.remove(posture);

  static void addPosture(PostureItem posture)
    => _postures.add(posture);

  static void clear()
    => _postures.clear();
}