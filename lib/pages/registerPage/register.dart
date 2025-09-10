import 'package:flutter/material.dart';

import '../loginPage/login.dart';
import 'formRegistrasiLanjutan1.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
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
                          const SizedBox(height: 5),
                          const Text(
                            "Buat Akun",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),

                          // Username field
                          TextField(
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.person_outline, color: Color(0xFF6C757D)),
                              ),
                              hintText: "Nama Lengkap",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

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
                              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Username field
                          TextField(
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.person_2_outlined, color: Color(0xFF6C757D)),
                              ),
                              hintText: "Username",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Username field
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.key_outlined, color: Color(0xFF6C757D)),
                              ),
                              hintText: "Password",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),

                          const SizedBox(height: 15),

                          // Username field
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                              // MODIFIKASI: Tambahkan padding kanan pada ikon untuk memberi jarak ke teks input.
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 20.0, right: 12.0),
                                child: Icon(Icons.key_outlined, color: Color(0xFF6C757D)),
                              ),
                              hintText: "Konfirmasi Password",
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Tombol Masuk
                          ElevatedButton(
                            onPressed: () {   Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (context) => const RegistrasiLanjutan1(),
                              ),
                            );
                              },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366), // Warna biru tua
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("REGISTER"),
                          ),
                          SizedBox(height: 15),
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
                          SizedBox(height: 15),

                          // Ganti bagian tombol Google dan Apple Anda dengan Row ini
                          Row(
                            children: [
                              // Tombol Google
                              Expanded( // Bungkus dengan Expanded agar lebarnya sama
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Image(
                                    image: NetworkImage(
                                        'https://cdn-icons-png.flaticon.com/512/300/300221.png'),
                                    height: 20,
                                  ),
                                  label: const Text("Google"), // Teks bisa dipersingkat
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(0, 45), // Tinggi dikecilkan
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10), // Jarak antara dua tombol

                              // Tombol Apple
                              Expanded( // Bungkus dengan Expanded agar lebarnya sama
                                child: ElevatedButton.icon(
                                  onPressed: () {},
                                  icon: const Icon(Icons.apple, color: Colors.black),
                                  label: const Text("Apple"), // Teks bisa dipersingkat
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.black,
                                    minimumSize: const Size(0, 45), // Tinggi dikecilkan
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          // Buat akun baru
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.black87,
                            ),
                            child: const Text(
                              "Sudah punya akun? Sign In",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}