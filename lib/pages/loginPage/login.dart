import 'package:flutter/material.dart';

import '../registerPage/register.dart';
import 'lupaPassword.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    // Tentukan tinggi area putih di atas form
   // const double whiteAreaHeight = 60 + 60 + 30; // SizedBox + Image + SizedBox

    return Scaffold(
      backgroundColor: Colors.white,
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
                            "Masuk ke akunmu",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),

                          // Button Google
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Image(
                              image: NetworkImage(
                                  'https://cdn-icons-png.flaticon.com/512/300/300221.png'),
                              height: 20,
                            ),
                            label: const Text("Masuk dengan Google"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Button Apple
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.apple, color: Colors.black),
                            label: const Text("Masuk dengan Apple"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider "atau"
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey.shade600)),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text("atau"),
                              ),
                              Expanded(child: Divider(color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Username field
                          TextField(
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.person_outline),
                              ),
                              hintText: "Username",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.vpn_key_outlined),
                              ),
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          // Lupa password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) => const LupaPassword(),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.black87,
                              ),
                              child: const Text("Lupa Password?", style: TextStyle(fontWeight: FontWeight.w400, decoration: TextDecoration.underline,),),
                            ),
                          ),

                          // Tombol Masuk
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366), // Warna biru tua
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Masuk"),
                          ),
                          const SizedBox(height: 10),

                          // Buat akun baru
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => Register(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text(
                              "Buat Akun Baru",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),

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
                child: Icon(Icons.person, size: 40, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}