import 'package:flutter/gestures.dart'; // <-- Jangan lupa import ini
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../loginPage/login.dart';

class RegistrasiLanjutan1 extends StatefulWidget {
  const RegistrasiLanjutan1({super.key});

  @override
  State<RegistrasiLanjutan1> createState() => _RegistrasiLanjutan1State();
}

class _RegistrasiLanjutan1State extends State<RegistrasiLanjutan1> {
  // === 1. DEKLARASI STATE UNTUK MENGONTROL INPUT ===
  final _tanggalLahirController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  String? _selectedDisability;
  final List<String> _disabilityOptions = ['Tidak Ada', 'Tuna Daksa (Kaki)', 'Tuna Netra'];

  // Fungsi untuk menampilkan Date Picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFECC38),
              onPrimary: Colors.black,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF003366),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _tanggalLahirController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

  // === WIDGET BARU UNTUK KEBIJAKAN PRIVASI ===
  Widget _buildPrivacyPolicyLink() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFECC38),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(Icons.info_outline, color: Colors.black, size: 24),
          const SizedBox(width: 5),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontFamily: 'Poppins', // Ganti 'Poppins' dengan nama font Anda jika berbeda
                  color: Colors.black,
                  fontSize: 12,
                ),
                children: <TextSpan>[
                  const TextSpan(text: 'Dengan ini saya menyetujui '),
                  TextSpan(
                    text: 'Kebijakan Privasi',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        print('Navigasi ke halaman Kebijakan Privasi...');
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Kebijakan Privasi'),
                            content: const Text('Isi dari kebijakan privasi akan ditampilkan di sini.'),
                            actions: [
                              TextButton(
                                child: const Text('Tutup'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                            ],
                          ),
                        );
                      },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  void dispose() {
    _tanggalLahirController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 15),
        child: Column(
          children: [
            const Spacer(),
            Container(
              height: screenHeight * 0.85,
              width: double.infinity,
              padding: const EdgeInsets.all(25),
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
                      "Form Registrasi Lanjutan",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 30),

                    // Field Tanggal Lahir
                    TextField(
                      controller: _tanggalLahirController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.calendar_today_outlined, color: Color(0xFF6C757D)),
                        ),
                        hintText: "Tanggal Lahir",
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

                    // Field Gender
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      items: _genderOptions.map((String gender) {
                        return DropdownMenuItem<String>(value: gender, child: Text(gender));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.wc, color: Color(0xFF6C757D)),
                        ),
                        hintText: "Gender",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Field Tinggi Badan
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.height, color: Color(0xFF6C757D)),
                        ),
                        hintText: "Tinggi Badan",
                        suffixText: "cm",
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

                    // Field Berat Badan
                    TextField(
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.monitor_weight_outlined, color: Color(0xFF6C757D)),
                        ),
                        hintText: "Berat Badan",
                        suffixText: "kg",
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

                    // Field Disabilitas
                    DropdownButtonFormField<String>(
                      value: _selectedDisability,
                      items: _disabilityOptions.map((String item) {
                        return DropdownMenuItem<String>(value: item, child: Text(item));
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDisability = newValue;
                        });
                      },
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 20.0, right: 12.0),
                          child: Icon(Icons.accessible, color: Color(0xFF6C757D)),
                        ),
                        hintText: "Riwayat Disabilitas",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 3, horizontal: 15),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    // === WIDGET KEBIJAKAN PRIVASI DITAMPILKAN DI SINI ===
                    _buildPrivacyPolicyLink(),

                    const SizedBox(height: 20),

                    // Tombol Register
                    ElevatedButton(
                      onPressed: () {
                        // Tambahkan logika untuk memproses data form di sini
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF003366),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text("REGISTER"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}