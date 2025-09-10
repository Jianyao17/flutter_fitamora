import 'package:flutter/material.dart';

class RestScreen extends StatefulWidget {
  const RestScreen({super.key});

  @override
  State<RestScreen> createState() => _RestScreenState();
}

class _RestScreenState extends State<RestScreen> {
  int seconds = 30;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFFFFCD39),
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.devices, color: Colors.white),
            label: "Perangkat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.record_voice_over, color: Colors.white),
            label: "Feedback Suara",
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFFCD39),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.black),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Istirahat",
                          style: TextStyle(
                            fontFamily: 'OneUI',
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          "30 detik",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'OneUI',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // Text instruksi
              Text(
                "Lemaskan seluruh tubuh anda",
                style: TextStyle(
                  fontSize: 20,
                  fontFamily: 'OneUI',
                  fontWeight: FontWeight.w900,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Timer bulat
              Container(
                padding: const EdgeInsets.all(64),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Color(0xFFFFCD39), width: 4),
                ),
                child: Text(
                  "0:${seconds.toString().padLeft(2, '0')}",
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFCD39),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Next
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Selanjutnya →",
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'OneUI',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Next exercise card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFFFFCD39),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Regular Push Up",
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: 'OneUI',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          "8 Repetisi (1/3)",
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'OneUI',
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Image pushup
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  "https://img.freepik.com/free-photo/athletic-man-doing-pushups-gym_1157-30046.jpg", // contoh gambar pushup
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 10),
              SizedBox(
                height: 70,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF003366),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: () {},
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle, size: 32, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "Mulai Langsung",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'OneUI',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
