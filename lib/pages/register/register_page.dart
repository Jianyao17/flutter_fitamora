import 'package:flutter/material.dart';

import '../../data/user_database.dart';
import '../login/login_page.dart';
import 'register_form1.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
{
  // --- KODE FUNGSI DITAMBAHKAN ---
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // DIUBAH: Tidak lagi 'async'
  void _navigateToNextForm() {
    final registeredUser = UserDatabase.instance.getRegisteredUser();
    if (registeredUser != null) {
      _showSnackbar("Hanya satu akun yang bisa didaftarkan. Silakan login.");
      return;
    }

    if (_fullNameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showSnackbar('Semua kolom wajib diisi!');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showSnackbar('Konfirmasi password tidak cocok!');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => RegisterForm1(
          fullName: _fullNameController.text,
          email: _emailController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        ),
      ),
    );
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  // --- AKHIR DARI KODE FUNGSI ---

  @override
  Widget build(BuildContext context) {
    // UI ASLI ANDA DIMULAI DI SINI (TIDAK ADA YANG DIUBAH)
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Column(
              children: [
                const SizedBox(height: 100),
                const Image(
                  image: AssetImage('assets/img/logo_apps.png'),
                  height: 60,
                ),
                const SizedBox(height: 70),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(25),
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFECC38),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 5),
                          const Text(
                            "Buat Akun",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),

                          TextField(
                            controller: _fullNameController,
                            decoration: buildInputDecoration(Icons.person_outline, "Nama Lengkap"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: buildInputDecoration(Icons.email_outlined, "Email"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _usernameController,
                            decoration: buildInputDecoration(Icons.person_2_outlined, "Username"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: buildInputDecoration(Icons.key_outlined, "Password"),
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: buildInputDecoration(Icons.key_outlined, "Konfirmasi Password"),
                          ),
                          const SizedBox(height: 30),
                          ElevatedButton(
                            onPressed: () {
                              _navigateToNextForm(); // PANGGIL FUNGSI NAVIGASI
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text("SELANJUTNYA"), // Teks diganti untuk kejelasan
                          ),
                          const SizedBox(height: 15),

                          // --- Sing Up dengan Google/Apple DITUTUP SEMENTARA ---
                          // Row(
                          //   children: [
                          //     Expanded(child: Divider(color: Colors.grey.shade600)),
                          //     const Padding(
                          //       padding: EdgeInsets.symmetric(horizontal: 8.0),
                          //       child: Text("atau"),
                          //     ),
                          //     Expanded(child: Divider(color: Colors.grey.shade600)),
                          //   ],
                          // ),
                          // const SizedBox(height: 15),
                          // Row(
                          //   children: [
                          //     Expanded(
                          //       child: ElevatedButton.icon(
                          //         onPressed: () {},
                          //         icon: const Image(
                          //           image: NetworkImage(
                          //               'https://cdn-icons-png.flaticon.com/512/300/300221.png'),
                          //           height: 20,
                          //         ),
                          //         label: const Text("Google"),
                          //         style: ElevatedButton.styleFrom(
                          //           backgroundColor: Colors.white,
                          //           foregroundColor: Colors.black,
                          //           minimumSize: const Size(0, 45),
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(30),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //     const SizedBox(width: 10),
                          //     Expanded(
                          //       child: ElevatedButton.icon(
                          //         onPressed: () {},
                          //         icon: const Icon(Icons.apple, color: Colors.black),
                          //         label: const Text("Apple"),
                          //         style: ElevatedButton.styleFrom(
                          //           backgroundColor: Colors.white,
                          //           foregroundColor: Colors.black,
                          //           minimumSize: const Size(0, 45),
                          //           shape: RoundedRectangleBorder(
                          //             borderRadius: BorderRadius.circular(30),
                          //           ),
                          //         ),
                          //       ),
                          //     ),
                          //   ],
                          // ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => LoginPage(),
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

  InputDecoration buildInputDecoration(IconData icon, String hintText) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 12.0),
        child: Icon(icon, color: const Color(0xFF6C757D)),
      ),
      hintText: hintText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 13, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }
}