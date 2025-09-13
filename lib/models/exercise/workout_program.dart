import 'workout_plan.dart';

class WorkoutProgram {
  final String title;
  final String description;
  final DateTime? startDate;
  int totalDays;

  // Daftar rencana latihan harian
  List<WorkoutPlan> dailyPlans;

  WorkoutProgram({
    required this.title,
    required this.description,
    required this.totalDays,
    required this.dailyPlans,
    this.startDate,
  }) : assert(
      dailyPlans.length == totalDays,
      "Jumlah dailyPlans harus sama dengan totalDays");


  /// Hitung hari saat ini secara dinamis berdasarkan tanggal mulai.
  int get currentDay
  {
    if (startDate == null || totalDays == 0)
      return 0; // Belum ada program/belum mulai

    final now = DateTime.now();
    // Normalisasi tanggal untuk perbandingan yang akurat (mengabaikan jam/menit)
    final start = DateTime(startDate!.year, startDate!.month, startDate!.day);
    final today = DateTime(now.year, now.month, now.day);

    int difference = today.difference(start).inDays + 1;

    // Memastikan currentDay berada dalam rentang program
    return difference.clamp(1, totalDays);
  }

  /// Hitung persentase progres program
  double get progressPercent => (currentDay / totalDays).clamp(0, 1);

  /// Ambil plan untuk hari tertentu
  WorkoutPlan get todayPlan => dailyPlans[currentDay - 1];

  void addWorkoutPlan(WorkoutPlan plan)
  {
    dailyPlans.add(plan);
    totalDays++;
  }

  void addWorkoutPlans(List<WorkoutPlan> plans)
  {
    dailyPlans.addAll(plans);
    totalDays = dailyPlans.length;
  }

  void removeWorkoutPlan(WorkoutPlan plan)
  {
    dailyPlans.remove(plan);
    totalDays = dailyPlans.length;
  }

  void removeWorkoutPlans(List<WorkoutPlan> plans)
  {
    dailyPlans.removeWhere((plan) => plans.contains(plan));
    totalDays = dailyPlans.length;
  }

  void clearPlans()
  {
    dailyPlans.clear();
    totalDays = 0;
  }

  factory WorkoutProgram.fromJson(Map<String, dynamic> json)
  {
    return WorkoutProgram(
      title: json['title'],
      description: json['description'],
      totalDays: json['totalDays'],
      dailyPlans: (json['dailyPlans'] as List)
          .map((e) => WorkoutPlan.fromJson(e))
          .toList(),
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : null,
    );
  }

  factory WorkoutProgram.empty()
  {
    return WorkoutProgram(
      title: 'Tidak ada program aktif',
      description: 'Mulai program latihan untuk memperbaiki postur tubuh Anda.',
      totalDays: 0,
      dailyPlans: List<WorkoutPlan>.empty(growable: true),
      startDate: DateTime.now()
    );
  }
}
