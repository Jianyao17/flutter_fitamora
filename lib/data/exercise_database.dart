import 'package:flutter/material.dart';

import '../models/exercise/exercise.dart';
import '../models/exercise/exercise_guide.dart';
import '../models/exercise/workout_plan.dart';


class ExerciseDatabase
{
  static List<WorkoutPlan> get singleWorkouts => List.unmodifiable(_singleWorkouts);
  static List<WorkoutPlan> get mixedWorkouts => List.unmodifiable(_mixedWorkouts);

  /// URL gambar panduan yang akan digunakan berulang kali
  static const String _guideImageUrl =
      'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?ixlib=rb-4.0.3&q=85&fm=jpg&crop=entropy&cs=srgb&w=600';

  /// Panduan latihan generik untuk semua exercise
  static final List<ExerciseGuide> _genericGuide = [
    ExerciseGuide(
        title: 'Panduan Gerakan', imageUrl: _guideImageUrl),
    ExerciseGuide(
        title: 'Tips & Teknik', imageUrl: _guideImageUrl),
  ];

  /// Data untuk single workout plans
  static final List<WorkoutPlan> _singleWorkouts = [
    WorkoutPlan(
      title: 'Kekuatan Tubuh Bagian Atas',
      description: 'Fokus membangun kekuatan dan massa otot pada lengan, bahu, dada, dan punggung.',
      imagePath: 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?q=80&w=869&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Push-up',
          description: 'Latihan klasik untuk membangun kekuatan dada, bahu, dan trisep.',
          icon: Icons.accessibility_new, // Ikon untuk latihan berat badan
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Dumbbell Bench Press',
          description: 'Variasi bench press menggunakan dumbbell untuk rentang gerak yang lebih bebas.',
          icon: Icons.fitness_center, // Ikon untuk angkat beban
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Overhead Press',
          description: 'Membangun kekuatan dan ukuran otot bahu secara keseluruhan.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Bicep Curls',
          description: 'Latihan isolasi untuk membentuk otot bisep.',
          icon: Icons.sports_gymnastics, // Ikon yang merepresentasikan gerakan lengan
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 45,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Kekuatan Kaki',
      description: 'Latihan intensif untuk membangun kekuatan dan daya tahan otot kaki.',
      imagePath: 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?q=80&w=869&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Squats',
          description: 'Raja dari semua latihan kaki, menargetkan paha depan, paha belakang, dan bokong.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 4,
          rep: 10,
          duration: null,
          rest: 90,
        ),
        Exercise(
          name: 'Lunges',
          description: 'Meningkatkan keseimbangan dan kekuatan unilateral pada setiap kaki.',
          icon: Icons.directions_walk, // Ikon untuk gerakan melangkah
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Leg Press',
          description: 'Alternatif squat untuk membangun massa otot kaki dengan dukungan punggung.',
          icon: Icons.airline_seat_legroom_normal, // Ikon yang menyerupai posisi leg press
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Calf Raises',
          description: 'Latihan isolasi untuk memperkuat dan membentuk otot betis.',
          icon: Icons.arrow_upward, // Ikon untuk gerakan ke atas
          guides: _genericGuide,
          sets: 4,
          rep: 15,
          duration: null,
          rest: 30,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Latihan Inti (Core)',
      description: 'Perkuat otot perut dan punggung bawah untuk postur dan stabilitas yang lebih baik.',
      imagePath: 'https://images.unsplash.com/photo-1598971457999-ca4ef48a9a71?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Plank',
          description: 'Membangun daya tahan otot inti, punggung, dan bahu.',
          icon: Icons.timer, // Ikon untuk latihan berbasis durasi
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 60,
          rest: 30,
        ),
        Exercise(
          name: 'Crunches',
          description: 'Latihan dasar untuk menargetkan otot perut bagian atas.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 20,
          duration: null,
          rest: 30,
        ),
        Exercise(
          name: 'Leg Raises',
          description: 'Fokus pada otot perut bagian bawah.',
          icon: Icons.arrow_upward,
          guides: _genericGuide,
          sets: 3,
          rep: 15,
          duration: null,
          rest: 45,
        ),
        Exercise(
          name: 'Russian Twists',
          description: 'Melatih otot oblique (perut samping) untuk pinggang yang lebih kuat.',
          icon: Icons.rotate_right, // Ikon untuk gerakan memutar
          guides: _genericGuide,
          sets: 3,
          rep: 20,
          duration: null,
          rest: 45,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Kardio Intensitas Tinggi',
      description: 'Bakar kalori secara maksimal dan tingkatkan kesehatan jantung dengan latihan cepat ini.',
      imagePath: 'https://images.unsplash.com/photo-1549060279-7e168fcee0c2?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Jumping Jacks',
          description: 'Pemanasan seluruh tubuh yang efektif untuk meningkatkan detak jantung.',
          icon: Icons.directions_run, // Ikon untuk gerakan kardio
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 60,
          rest: 30,
        ),
        Exercise(
          name: 'High Knees',
          description: 'Latihan kardio yang juga melatih fleksor pinggul dan otot inti.',
          icon: Icons.directions_run,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 45,
          rest: 30,
        ),
        Exercise(
          name: 'Burpees',
          description: 'Latihan seluruh tubuh yang sangat efektif untuk membakar kalori dan membangun daya tahan.',
          icon: Icons.repeat, // Ikon untuk gerakan berulang
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Mountain Climbers',
          description: 'Latihan dinamis yang menargetkan inti, bahu, dan meningkatkan detak jantung.',
          icon: Icons.directions_run,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 45,
          rest: 30,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Fungsional Seluruh Tubuh',
      description: 'Latihan efisien yang menargetkan semua kelompok otot utama dalam satu sesi.',
      imagePath: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Squat to Press',
          description: 'Gerakan gabungan yang melatih kaki, inti, dan bahu secara bersamaan.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Renegade Rows',
          description: 'Membangun kekuatan punggung dan stabilitas inti dalam posisi plank.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Kettlebell Swings',
          description: 'Latihan eksplosif untuk kekuatan pinggul, paha belakang, dan punggung bawah.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 4,
          rep: 15,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Plank',
          description: 'Gerakan isometrik untuk membangun daya tahan inti yang solid.',
          icon: Icons.timer,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 60,
          rest: 30,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Fleksibilitas dan Pendinginan',
      description: 'Sesi peregangan untuk meningkatkan fleksibilitas dan membantu pemulihan otot.',
      imagePath: 'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?q=80&w=920&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Cat-Cow Stretch',
          description: 'Peregangan dinamis untuk meningkatkan fleksibilitas tulang belakang.',
          icon: Icons.self_improvement, // Ikon untuk relaksasi/yoga
          guides: _genericGuide,
          sets: 2,
          rep: 10,
          duration: null,
          rest: 15,
        ),
        Exercise(
          name: 'Hamstring Stretch',
          description: 'Peregangan statis untuk otot paha belakang, penting setelah latihan kaki.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 2,
          rep: null,
          duration: 30,
          rest: 15,
        ),
        Exercise(
          name: 'Quad Stretch',
          description: 'Peregangan untuk otot paha depan, membantu mengurangi kekakuan.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 2,
          rep: null,
          duration: 30,
          rest: 15,
        ),
        Exercise(
          name: 'Child\'s Pose',
          description: 'Pose relaksasi untuk melepaskan ketegangan di punggung, bahu, dan pinggul.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 2,
          rep: null,
          duration: 60,
          rest: 30,
        ),
      ],
    ),
  ];

  /// Data untuk mixed workout plans
  static final List<WorkoutPlan> _mixedWorkouts = [
    WorkoutPlan(
      title: 'Kekuatan & Kardio',
      description: 'Kombinasi sempurna antara angkat beban dan kardio untuk hasil maksimal.',
      imagePath: 'https://images.unsplash.com/photo-1605296867304-46d5465a13f1?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Goblet Squat',
          description: 'Variasi squat yang bagus untuk pemula dan melatih inti.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 45,
        ),
        Exercise(
          name: 'Push-up',
          description: 'Latihan berat badan yang efektif untuk dada dan trisep.',
          icon: Icons.accessibility_new,
          guides: _genericGuide,
          sets: 3,
          rep: 15,
          duration: null,
          rest: 45,
        ),
        Exercise(
          name: 'Box Jumps',
          description: 'Latihan pliometrik untuk membangun kekuatan eksplosif pada kaki.',
          icon: Icons.upgrade, // Ikon untuk gerakan melompat ke atas
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Battle Ropes',
          description: 'Latihan intensitas tinggi untuk kardio dan kekuatan tubuh bagian atas.',
          icon: Icons.waves, // Ikon yang merepresentasikan gerakan tali
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 30,
          rest: 60,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'HIIT Challenge',
      description: 'Tantang batas Anda dengan latihan interval intensitas tinggi yang membakar lemak.',
      imagePath: 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Burpees',
          description: 'Gerakan seluruh tubuh yang menjadi andalan dalam sesi HIIT.',
          icon: Icons.repeat,
          guides: _genericGuide,
          sets: 4,
          rep: 12,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Jumping Lunges',
          description: 'Versi eksplosif dari lunge untuk meningkatkan detak jantung dan kekuatan kaki.',
          icon: Icons.directions_run,
          guides: _genericGuide,
          sets: 4,
          rep: 20,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Kettlebell Swings',
          description: 'Latihan balistik yang membakar banyak kalori dan membangun kekuatan.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 4,
          rep: 20,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Plank Jacks',
          description: 'Menggabungkan plank dengan gerakan kardio untuk melatih inti dan membakar kalori.',
          icon: Icons.star_border, // Ikon yang merepresentasikan gerakan "jack"
          guides: _genericGuide,
          sets: 4,
          rep: null,
          duration: 45,
          rest: 30,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Tubuh Atas & Inti',
      description: 'Bangun kekuatan fungsional dengan menggabungkan latihan tubuh atas dan inti.',
      imagePath: 'https://images.unsplash.com/photo-1526506118085-60ce8714f8c5?q=80&w=774&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Pull-ups',
          description: 'Latihan punggung yang superior untuk membangun lebar dan kekuatan punggung atas.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 8,
          duration: null,
          rest: 90,
        ),
        Exercise(
          name: 'Dumbbell Overhead Press',
          description: 'Membangun bahu yang kuat dan stabil menggunakan dumbbell.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Hanging Knee Raises',
          description: 'Latihan inti tingkat lanjut untuk menargetkan perut bagian bawah.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 15,
          duration: null,
          rest: 45,
        ),
        Exercise(
          name: 'Ab Rollout',
          description: 'Tantang seluruh otot inti Anda dengan alat ab roller.',
          icon: Icons.data_usage, // Ikon yang mirip gerakan rollout
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 45,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Kaki & Bakar Kalori',
      description: 'Gabungkan latihan kaki yang berat dengan gerakan yang membakar banyak kalori.',
      imagePath: 'https://images.unsplash.com/photo-1594737625785-a6a22d810d34?q=80&w=774&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Deadlifts',
          description: 'Latihan gabungan utama untuk membangun kekuatan di seluruh tubuh.',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 4,
          rep: 8,
          duration: null,
          rest: 90,
        ),
        Exercise(
          name: 'Jump Squats',
          description: 'Tambahkan elemen pliometrik pada squat untuk meningkatkan pembakaran kalori.',
          icon: Icons.upgrade,
          guides: _genericGuide,
          sets: 3,
          rep: 15,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Sled Push',
          description: 'Latihan fungsional yang membangun kekuatan kaki dan daya tahan kardiovaskular.',
          icon: Icons.arrow_forward, // Ikon untuk gerakan mendorong maju
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 45,
          rest: 90,
        ),
        Exercise(
          name: 'Leg Curls',
          description: 'Latihan isolasi untuk menargetkan otot hamstring (paha belakang).',
          icon: Icons.fitness_center,
          guides: _genericGuide,
          sets: 3,
          rep: 12,
          duration: null,
          rest: 45,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Kekuatan Fungsional',
      description: 'Tingkatkan kekuatan untuk aktivitas sehari-hari dengan latihan fungsional ini.',
      imagePath: 'https://images.unsplash.com/photo-1554344728-77cf90d922a2?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Farmer\'s Walk',
          description: 'Meningkatkan kekuatan cengkeraman, inti, dan daya tahan seluruh tubuh.',
          icon: Icons.luggage, // Ikon yang relevan dengan membawa beban
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 60,
          rest: 60,
        ),
        Exercise(
          name: 'Tire Flips',
          description: 'Latihan seluruh tubuh yang eksplosif dan membangun kekuatan mentah.',
          icon: Icons.donut_large, // Ikon yang menyerupai ban
          guides: _genericGuide,
          sets: 3,
          rep: 10,
          duration: null,
          rest: 90,
        ),
        Exercise(
          name: 'Medicine Ball Slams',
          description: 'Melepaskan tenaga dan melatih kekuatan inti serta kardio.',
          icon: Icons.sports_baseball, // Ikon bola
          guides: _genericGuide,
          sets: 3,
          rep: 15,
          duration: null,
          rest: 45,
        ),
        Exercise(
          name: 'Turkish Get-Up',
          description: 'Gerakan kompleks untuk stabilitas, mobilitas, dan kekuatan seluruh tubuh.',
          icon: Icons.accessibility_new,
          guides: _genericGuide,
          sets: 3,
          rep: 5,
          duration: null,
          rest: 90,
        ),
      ],
    ),
    WorkoutPlan(
      title: 'Keseimbangan Pikiran & Tubuh',
      description: 'Latihan yang menggabungkan elemen Yoga dan Pilates untuk kekuatan dan fleksibilitas.',
      imagePath: 'https://images.unsplash.com/photo-1575052814086-f385e2e2ad1b?q=80&w=870&auto=format&fit=crop',
      exercises: [
        Exercise(
          name: 'Downward-Facing Dog',
          description: 'Pose yoga untuk meregangkan seluruh bagian belakang tubuh.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 45,
          rest: 30,
        ),
        Exercise(
          name: 'Warrior II',
          description: 'Membangun kekuatan di kaki dan membuka pinggul serta dada.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 30,
          rest: 30,
        ),
        Exercise(
          name: 'Pilates - The Hundred',
          description: 'Latihan klasik Pilates untuk daya tahan otot perut dan pernapasan.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 1,
          rep: 100,
          duration: null,
          rest: 60,
        ),
        Exercise(
          name: 'Boat Pose',
          description: 'Pose untuk menyeimbangkan dan memperkuat otot perut serta fleksor pinggul.',
          icon: Icons.self_improvement,
          guides: _genericGuide,
          sets: 3,
          rep: null,
          duration: 30,
          rest: 45,
        ),
      ],
    ),
  ];
}
