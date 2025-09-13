import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import 'lupa_password_page3.dart';

class LupaPassword2 extends StatefulWidget {
  const LupaPassword2({super.key});

  @override
  State<LupaPassword2> createState() => _LupaPassword2State();
}

class _LupaPassword2State extends State<LupaPassword2> {
  final _pinController = TextEditingController();
  @override
  Widget build(BuildContext context) {
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
                            "Masukkan 6 digit kode yang telah",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                          const Text(
                            textAlign: TextAlign.center,
                            "kami kirimkan kedalam email anda",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 30),


                    Pinput(
                    controller: _pinController,
                    length: 6, // Jumlah digit kode
                    // Ini adalah bagian kunci untuk membagi 3-3
                    separatorBuilder: (index) => const SizedBox(width: 12.0), // Jarak antar kotak
                    // Atau jika ingin pemisah berupa strip "-"
                    // separatorBuilder: (index) {
                    //   // Tampilkan strip hanya setelah digit ke-3
                    //   return index == 2 ? const Text(' - ', style: TextStyle(fontSize: 24)) : const SizedBox(width: 8.0);
                    // },

                    // Fungsi yang akan dipanggil saat user selesai mengisi semua digit
                    onCompleted: (pin) {
                      print('Kode verifikasi yang dimasukkan: $pin');
                      // Anda bisa tambahkan logika validasi di sini
                    },

                    // Kustomisasi tampilan setiap kotak PIN
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 55,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                    ),
                    // Tampilan kotak saat sedang diisi (aktif)
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 55,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Theme.of(context).primaryColor), // Warna border berbeda
                      ),
                    ),
                    // Tampilan kotak setelah terisi
                    submittedPinTheme: PinTheme(
                      width: 50,
                      height: 55,
                      textStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.green), // Warna border sukses
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
                              child: const Text("Kirim Ulang?", style: TextStyle(fontWeight: FontWeight.w400, decoration: TextDecoration.underline,),),
                            ),
                          ),

                          const SizedBox(height: 200),

                          // Tombol Masuk
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (context) => const LupaPassword3(),
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