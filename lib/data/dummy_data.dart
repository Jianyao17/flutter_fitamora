// data/dummy_data.dart

import '../models/exercise/workout_model.dart';

// --- DATA DUMMY ---

final List<Workout> singleWorkouts = [
  Workout(
    title: 'Latihan Perut',
    description: 'Kencangkan otot perut dan perkuat inti tubuh Anda dengan rangkaian latihan klasik ini.',
    imagePath: 'assets/build/a1.png',
    movements: [
      Movement(
        name: 'Jumping Jacks',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, lompat sambil membuka kaki dan mengangkat tangan ke atas. Kembali ke posisi awal dengan cepat.',
        repetition: 'Repetisi: 20 Detik',
      ),
      Movement(
        name: 'Plank',
        // DESKRIPSI GERAKAN:
        description: 'Posisikan tubuh lurus seperti papan dengan tumpuan pada lengan bawah dan ujung jari kaki. Tahan perut.',
        repetition: 'Repetisi: 20 Detik',
      ),
      Movement(
        name: 'Leg Raises',
        // DESKRIPSI GERAKAN:
        description: 'Berbaring telentang, angkat kedua kaki lurus ke atas hingga 90 derajat, lalu turunkan perlahan tanpa menyentuh lantai.',
        repetition: 'Repetisi: 12-14 kali x 2 set',
      ),
      Movement(
        name: 'Cobra Stretch',
        // DESKRIPSI GERAKAN:
        description: 'Berbaring telungkup, letakkan tangan di bawah bahu. Angkat dada dari lantai sambil menjaga pinggul tetap menempel.',
        repetition: '30 Detik',
      ),
    ],
  ),

  Workout(
    title: 'Latihan Lengan',
    description: 'Bentuk lengan yang kencang dan definisikan otot bahu dengan latihan yang menantang ini.',
    imagePath: 'assets/build/latihan_tangan.jpg',
    movements: [
      Movement(
        name: 'Arm Raises',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, angkat kedua lengan lurus ke depan hingga sejajar bahu, lalu turunkan kembali secara perlahan.',
        repetition: 'Repetisi: 30 Detik',
      ),
      Movement(
        name: 'Side Arm Raises',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, angkat kedua lengan lurus ke samping hingga sejajar bahu. Jaga agar tubuh tetap stabil.',
        repetition: 'Repetisi: 30 Detik',
      ),
      Movement(
        name: 'Push-up',
        // DESKRIPSI GERAKAN:
        description: 'Mulai dari posisi high plank, turunkan tubuh hingga dada mendekati lantai, lalu dorong kembali ke posisi awal.',
        repetition: 'Repetisi: 5-6 kali x 2 set',
      ),
      Movement(
        name: 'Jumping Jacks',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, lompat sambil membuka kaki dan mengangkat tangan ke atas. Kembali ke posisi awal dengan cepat.',
        repetition: '30 Detik',
      ),
    ],
  ),
  Workout(
    title: 'Latihan Dada',
    description: 'Bangun kekuatan dan daya tahan otot dada dengan fokus pada gerakan push-up yang efektif.',
    imagePath: 'assets/build/latihan_dada.png',
    movements: [
      Movement(
        name: 'Jumping Jacks',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, lompat sambil membuka kaki dan mengangkat tangan ke atas. Kembali ke posisi awal dengan cepat.',
        repetition: '30 Detik',
      ),
      Movement(
        name: 'Knee Push-up',
        // DESKRIPSI GERAKAN:
        description: 'Sama seperti push-up biasa, namun dengan tumpuan pada lutut untuk membuatnya lebih ringan. Jaga punggung tetap lurus.',
        repetition: 'Repetisi: 4-5 kali x 3 set',
      ),
      Movement(
        name: 'Cobra Stretch',
        // DESKRIPSI GERAKAN:
        description: 'Berbaring telungkup, letakkan tangan di bawah bahu. Angkat dada dari lantai sambil menjaga pinggul tetap menempel.',
        repetition: 'Repetisi: 20 Detik',
      ),
    ],
  ),
  Workout(
    title: 'Latihan Kaki',
    description: 'Perkuat fondasi tubuh Anda dengan melatih otot kaki, paha, dan glutes secara menyeluruh.',
    imagePath: 'assets/build/latihan_kaki.jpg',
    movements: [
      Movement(
        name: 'Squats',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri dengan kaki selebar bahu. Turunkan pinggul ke belakang seperti akan duduk, jaga dada tetap tegap.',
        repetition: 'Repetisi: 12-15 kali x 2 set',
      ),
      Movement(
        name: 'Push-up',
        // DESKRIPSI GERAKAN:
        description: 'Mulai dari posisi high plank, turunkan tubuh hingga dada mendekati lantai, lalu dorong kembali ke posisi awal.',
        repetition: 'Repetisi: 14 kali x 2 set',
      ),
      Movement(
        name: 'Donkey Kicks Left',
        // DESKRIPSI GERAKAN:
        description: 'Mulai dari posisi merangkak. Angkat kaki kiri ke belakang dengan lutut tetap tertekuk, dorong tumit ke arah langit-langit.',
        repetition: 'Repetisi: 16 kali x 2 set',
      ),
      Movement(
        name: 'Donkey Kicks Right',
        // DESKRIPSI GERAKAN:
        description: 'Lakukan gerakan yang sama seperti Donkey Kicks Left, namun kali ini gunakan kaki kanan.',
        repetition: 'Repetisi: 16 kali x 2 set',
      ),
    ],
  ),
  Workout(
    title: 'Shoulder and Back',
    description: 'Tingkatkan kekuatan bahu dan punggung bagian atas, penting untuk postur tubuh yang tegap.',
    imagePath: 'assets/build/latihan_shoulder.png',
    movements: [
      Movement(
        name: 'Jumping Jacks',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, lompat sambil membuka kaki dan mengangkat tangan ke atas. Kembali ke posisi awal dengan cepat.',
        repetition: 'Repetisi: 30 Detik',
      ),
      Movement(
        name: 'Arm Raises',
        // DESKRIPSI GERAKAN:
        description: 'Berdiri tegak, angkat kedua lengan lurus ke depan hingga sejajar bahu, lalu turunkan kembali secara perlahan.',
        repetition: 'Repetisi: 16 Detik x 2 set',
      ),
      Movement(
        name: 'Rhomboid Pulls',
        // DESKRIPSI GERAKAN:
        description: 'Ulurkan tangan ke depan, lalu tarik siku ke belakang sambil merapatkan tulang belikat sekuat mungkin.',
        repetition: 'Repetisi: x14 kali x 2 set',
      ),
      Movement(
        name: 'Knee Push Up',
        // DESKRIPSI GERAKAN:
        description: 'Sama seperti push-up biasa, namun dengan tumpuan pada lutut untuk membuatnya lebih ringan. Jaga punggung tetap lurus.',
        repetition: 'Repetisi: 14 kali x 2 set',
      ),
    ],
  ),
];

final List<Workout> mixedWorkouts = [
  Workout(
    title: 'Latihan Perut dan Dada',
    description: 'Kombinasi untuk melatih otot dan kekuatan perut sekaligus Dada.',
    imagePath: 'assets/build/a1.png',
    movements: [

    ],
  ),
];