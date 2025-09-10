// data/dummy_data.dart

import '../../models/workout_model.dart';

// --- DATA DUMMY ---

final List<Workout> singleWorkouts = [
  Workout(
    title: 'Latihan Kaki',
    description: 'Fokus pada kekuatan & daya tahan otot kaki.',
    imagePath: 'assets/build/a1.png',
    movements: [
      Movement(
        name: 'Squat',
        description: 'Tekuk lutut hingga paha sejajar lantai, lalu kembali berdiri.',
        repetition: 'Repetisi: 12-15 kali x 3 set',
      ),
      Movement(
        name: 'Jump Squat',
        description: 'Lakukan squat lalu meloncat eksplosif ke atas.',
        repetition: 'Repetisi: 10-12 kali x 3 set',
      ),
      Movement(
        name: 'Glute Bridge',
        description: 'Berbaring, tekuk lutut, lalu dorong pinggul ke atas hingga tubuh lurus.',
        repetition: 'Repetisi: 12-15 kali x 3 set',
      ),
    ],
  ),
  Workout(
    title: 'Latihan Tangan',
    description: 'Membangun otot lengan, bahu, dan dada.',
    imagePath: 'assets/build/a1.png',
    movements: [
      Movement(
        name: 'Push Up',
        description: 'Posisi plank, turunkan badan hingga dada hampir menyentuh lantai.',
        repetition: 'Repetisi: 10-15 kali x 3 set',
      ),
      Movement(
        name: 'Bicep Curl',
        description: 'Gunakan dumbbell, angkat beban dengan menekuk siku.',
        repetition: 'Repetisi: 12-15 kali x 3 set',
      ),
    ],
  ),
];

final List<Workout> mixedWorkouts = [
  Workout(
    title: 'Latihan Biceps & Kaki',
    description: 'Kombinasi untuk efisiensi waktu.',
    imagePath: 'assets/build/a1.png',
    movements: [
      Movement(
        name: 'Dumbbell Lunges',
        description: 'Langkahkan satu kaki ke depan sambil memegang dumbbell.',
        repetition: 'Repetisi: 10-12 kali per kaki x 3 set',
      ),
      Movement(
        name: 'Hammer Curl',
        description: 'Seperti bicep curl, tapi posisi telapak tangan saling berhadapan.',
        repetition: 'Repetisi: 12-15 kali x 3 set',
      ),
    ],
  ),
];