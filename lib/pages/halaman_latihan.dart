import 'package:flutter/material.dart';

class DailyPostureExerciseScreen extends StatelessWidget {
  final List<Map<String, String>> exercises = [
    {'name': 'Jumping Jacks', 'duration': '3x1 Menit'},
    {'name': 'Chest Stretch', 'duration': '3x1 Menit'},
    {'name': 'Cobra Pose', 'duration': '3x1 Menit'},
    {'name': 'Plank', 'duration': '1x1 Menit'},
  ];

  DailyPostureExerciseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black, size: 24),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Exercise Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.amber[400],
                borderRadius: BorderRadius.circular(16.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8.0,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20.0),
                    child: Text(
                      'Latihan Postur Hari Ini!',
                      style: TextStyle(
                        fontSize: 22.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  // Exercise List
                  Container(
                    margin: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      children:
                          exercises.map((exercise) {
                            int index = exercises.indexOf(exercise);
                            return Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      exercise['name']!,
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      exercise['duration']!,
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (index < exercises.length - 1)
                                  Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    height: 1.0,
                                    color: Colors.grey[300],
                                  ),
                              ],
                            );
                          }).toList(),
                    ),
                  ),

                  // Start Button
                  Container(
                    margin: EdgeInsets.fromLTRB(20.0, 0, 20.0, 20.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle start exercise
                          _showStartDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          elevation: 2.0,
                        ),
                        child: Text(
                          'Mulai',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rest of the screen remains empty like in the original
            Expanded(child: Container()),
          ],
        ),
      ),
    );
  }

  void _showStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mulai Latihan'),
          content: Text(
            'Apakah Anda siap untuk memulai latihan postur hari ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to exercise session
                _startExerciseSession(context);
              },
              child: Text('Mulai'),
            ),
          ],
        );
      },
    );
  }

  void _startExerciseSession(BuildContext context) {
    // This would typically navigate to an exercise session screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Memulai sesi latihan...'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
