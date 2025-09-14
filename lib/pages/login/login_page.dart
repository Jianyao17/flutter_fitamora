import 'package:flutter/material.dart';

import '../../data/user_database.dart';
import '../../models/user_model.dart';
import '../register/register_page.dart';
import 'lupa_password_page1.dart';
import '../home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- KODE FUNGSI DITAMBAHKAN ---
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // DIUBAH: Tidak lagi 'async'
  void _login() {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackbar("Username dan Password harus diisi.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // Ambil data user dari memori (bukan async)
    User? registeredUser = UserDatabase.instance.getRegisteredUser();

    // Tunda sebentar untuk UX
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() => _isLoading = false);

      if (registeredUser == null) {
        _showSnackbar("Akun tidak ditemukan. Silakan buat akun baru.", isError: true);
        return;
      }

      if (_usernameController.text == registeredUser.username &&
          _passwordController.text == registeredUser.password) {
        // Panggil metode login sinkron
        UserDatabase.instance.login(registeredUser);

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
        );
      } else {
        _showSnackbar("Username atau Password salah!", isError: true);
      }
    });
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                          const SizedBox(height: 20),
                          const Text(
                            "Masuk ke akunmu",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 30),

                          // -- Tombol login sosial (dinonaktifkan sementara)
                          // ElevatedButton.icon(
                          //   onPressed: () {},
                          //   icon: const Image(
                          //     image: NetworkImage(
                          //         'https://cdn-icons-png.flaticon.com/512/300/300221.png'),
                          //     height: 20,
                          //   ),
                          //   label: const Text("Masuk dengan Google"),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.white,
                          //     foregroundColor: Colors.black,
                          //     minimumSize: const Size(double.infinity, 50),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(30),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(height: 15),
                          // ElevatedButton.icon(
                          //   onPressed: () {},
                          //   icon: const Icon(Icons.apple, color: Colors.black),
                          //   label: const Text("Masuk dengan Apple"),
                          //   style: ElevatedButton.styleFrom(
                          //     backgroundColor: Colors.white,
                          //     foregroundColor: Colors.black,
                          //     minimumSize: const Size(double.infinity, 50),
                          //     shape: RoundedRectangleBorder(
                          //       borderRadius: BorderRadius.circular(30),
                          //     ),
                          //   ),
                          // ),
                          // const SizedBox(height: 20),
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
                          // const SizedBox(height: 20),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
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
                            controller: _passwordController,
                            obscureText: true,
                            decoration: InputDecoration(
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
                          _isLoading
                              ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            child: CircularProgressIndicator(color: Color(0xFF003366)),
                          )
                              : ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF003366),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text("Masuk"),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => RegisterPage(),
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
                          const SizedBox(height: 10),
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
            Positioned(
              top: 190,
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