import 'package:flutter/material.dart';

import 'lupa_password_page2.dart';

class LupaPassword extends StatefulWidget {
  const LupaPassword({super.key});

  @override
  State<LupaPassword> createState() => _LupaPasswordState();
}

class _LupaPasswordState extends State<LupaPassword> {
  @override
  Widget build(BuildContext context) {
    // Tentukan tinggi area putih di atas form
    // const double whiteAreaHeight = 60 + 60 + 30; // SizedBox + Image + SizedBox

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Membuat AppBar menjadi transparan
        backgroundColor: Colors.transparent,
        // Menghilangkan bayangan di bawah AppBar
        elevation: 0,
        // Mengatur warna ikon kembali menjadi hitam agar terlihat di background putih
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      extendBodyBehindAppBar: true,
      // FIX: Gunakan Stack untuk menumpuk avatar di atas layout utama
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        child: Stack(
          alignment: Alignment.topCenter, // Pusatkan item stack di atas
          children: [
            // WIDGET 1: Layout utama Anda (tetap menggunakan Column)
            // Ini akan berada di lapisan paling bawah stack.
            Column(
              children: [
                // Bagian atas dengan background putih
                const SizedBox(height: 100),
                const Image(
                  image: AssetImage('assets/img/logo_apps.png'), // Pastikan path asset ini benar
                  height: 60,
                ),
                const SizedBox(height: 70),

                // Container kuning untuk membungkus form
                Expanded( // Gunakan Expanded agar container kuning mengisi sisa ruang
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFECC38), // Warna kuning
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView( // Tambahkan SingleChildScrollView untuk menghindari overflow
                      child: Column(
                        children: [
                          // FIX: Beri ruang kosong untuk Avatar yang menumpuk dari atas
                          // Jarak ini adalah (setengah tinggi avatar) + (jarak ke teks di bawahnya)
                          const SizedBox(height: 20),

                          const Text(
                            "Lupa Password",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 15),
                          const Text(
                            textAlign: TextAlign.center,
                            "Masukkan Email yang anda gunakan",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                          const Text(
                            textAlign: TextAlign.center,
                            "untuk membuat akun",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 30),

                          // Username field
                          TextField(
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.email_outlined, color: Color(0xFF6C757D)),
                              ),
                              hintText: "Email",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          // Lupa password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                              ),
                              child: const Text("Coba metode lain?", style: TextStyle(fontWeight: FontWeight.w400, decoration: TextDecoration.underline,),),
                            ),
                          ),

                          const SizedBox(height: 200),

                          // Tombol Masuk
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const LupaPassword2(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366), // Warna biru tua
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("KIRIM"),
                          ),
                          const SizedBox(height: 30),

                          // TTS button
                          Column(
                            children: [
                              const CircleAvatar(
                                radius: 15,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.volume_up, size: 20, color: Colors.black),
                              ),
                              const SizedBox(height: 10),
                              Text("TTS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // WIDGET 2: Avatar (gambar profil)
            // Ini akan berada di lapisan ATAS, menumpuk di atas Column.
            // Kita gunakan Positioned untuk menempatkannya secara presisi.
            Positioned(
              // Posisikan dari atas sejauh tinggi area putih, lalu kurangi setengah tinggi avatar
              // agar posisinya tepat di tengah garis.
              top: 190, // 150 - 32 = 118
              child: const CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white,
                child: Icon(Icons.lock_outline, size: 35, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}