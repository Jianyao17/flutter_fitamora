import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../data/user_database.dart';
import '../../models/user_model.dart';
import '../home_page.dart';

class RegisterForm1 extends StatefulWidget {
  final String fullName;
  final String email;
  final String username;
  final String password;

  const RegisterForm1({
    super.key,
    required this.fullName,
    required this.email,
    required this.username,
    required this.password,
  });

  @override
  State<RegisterForm1> createState() => _RegisterForm1State();
}

class _RegisterForm1State extends State<RegisterForm1> {
  // --- STATE DARI UI ANDA ---
  final _tanggalLahirController = TextEditingController();
  String? _selectedGender;
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  String? _selectedDisability;
  final List<String> _disabilityOptions = ['Tidak Ada', 'Tuna Daksa (Kaki)', 'Tuna Netra'];

  // --- KODE FUNGSI DITAMBAHKAN ---
  final _tinggiBadanController = TextEditingController();
  final _beratBadanController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;

  // DIUBAH: Tidak lagi 'async'
  void _completeRegistration() {
    if (_tanggalLahirController.text.isEmpty ||
        _tinggiBadanController.text.isEmpty ||
        _beratBadanController.text.isEmpty ||
        _selectedGender == null ||
        _selectedDisability == null) {
      _showSnackbar('Harap lengkapi semua data!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final newUser = User(
      fullName: widget.fullName,
      email: widget.email,
      username: widget.username,
      password: widget.password,
      dateOfBirth: _selectedDate,
      gender: _selectedGender,
      height: int.tryParse(_tinggiBadanController.text),
      weight: int.tryParse(_beratBadanController.text),
      disability: _selectedDisability,
    );

    // Panggil metode registrasi sinkron
    UserDatabase.instance.registerUser(newUser);

    // Tunda sebentar untuk UX
    Future.delayed(const Duration(milliseconds: 500), ()
    {
      setState(() => _isLoading = false);
      _showSnackbar("Registrasi berhasil!", isError: false);

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
            (Route<dynamic> route) => false,
      );
    });
  }

  void _showSnackbar(String message, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }
  // --- AKHIR DARI KODE FUNGSI ---

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      // ... (kode builder theme Anda)
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat('dd MMMM yyyy').format(picked);
      });
    }
  }

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
                  fontFamily: 'Poppins',
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
                        // ... (logika dialog kebijakan privasi Anda)
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
    _tinggiBadanController.dispose();
    _beratBadanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // UI ASLI ANDA DIMULAI DI SINI (TIDAK ADA YANG DIUBAH)
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
                    TextField(
                      controller: _tanggalLahirController,
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      decoration: buildInputDecoration(Icons.calendar_today_outlined, "Tanggal Lahir"),
                    ),
                    const SizedBox(height: 15),
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
                      decoration: buildInputDecoration(Icons.wc, "Gender", isDropdown: true),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _tinggiBadanController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: buildInputDecoration(Icons.height, "Tinggi Badan", suffix: "cm"),
                    ),
                    const SizedBox(height: 15),
                    TextField(
                      controller: _beratBadanController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: buildInputDecoration(Icons.monitor_weight_outlined, "Berat Badan", suffix: "kg"),
                    ),
                    const SizedBox(height: 15),
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
                      decoration: buildInputDecoration(Icons.accessible, "Riwayat Disabilitas", isDropdown: true),
                    ),
                    const SizedBox(height: 20),
                    _buildPrivacyPolicyLink(),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 15.0),
                      child: CircularProgressIndicator(color: Color(0xFF003366)),
                    )
                        : ElevatedButton(
                      onPressed: _completeRegistration,
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

  InputDecoration buildInputDecoration(IconData icon, String hintText, {String? suffix, bool isDropdown = false}) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20.0, right: 12.0),
        child: Icon(icon, color: const Color(0xFF6C757D)),
      ),
      hintText: hintText,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(vertical: isDropdown ? 3 : 13, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }
}