import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../data/user_database.dart';
import '../models/user_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
{
  final UserDatabase _userDatabase = UserDatabase.instance;
  late User _currentUser;
  bool _isEditing = false;

  // Controllers untuk mode edit
  late TextEditingController _fullNameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  String? _selectedGender;
  String? _selectedDisability;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    _currentUser = _userDatabase.activeUser;

    // Inisialisasi controller dengan data saat ini
    _fullNameController = TextEditingController(text: _currentUser.fullName);
    _heightController = TextEditingController(text: _currentUser.height?.toString() ?? '');
    _weightController = TextEditingController(text: _currentUser.weight?.toString() ?? '');
    _selectedGender = _currentUser.gender;
    _selectedDisability = _currentUser.disability;
  }

  void _toggleEditMode()
  {
    setState(() {
      _isEditing = !_isEditing;
      // Jika membatalkan edit, reset data ke data awal
      if (!_isEditing) {
        _loadUserData();
      }
    });
  }

  Future<void> _saveChanges() async
  {
    // Buat objek user baru dengan data yang diperbarui dari controller
    final updatedUser = _currentUser.copyWith(
      fullName: _fullNameController.text,
      height: int.tryParse(_heightController.text),
      weight: int.tryParse(_weightController.text),
      gender: _selectedGender,
      disability: _selectedDisability,
    );

    // Panggil updateUser untuk memperbarui state dan menyimpan ke lokal
    _userDatabase.updateUser(updatedUser);

    // Tampilkan pesan sukses dan keluar dari mode edit
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: Colors.green),
    );

    setState(() {
      _currentUser = updatedUser;
      _isEditing = false;
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Profil' : 'Profil Pengguna'),
        backgroundColor: const Color(0xFFFECC38),
        centerTitle: true,
        leading: _isEditing
            ? IconButton(icon: Icon(Icons.close), onPressed: _toggleEditMode)
            : null, // Sembunyikan tombol back default saat edit
        automaticallyImplyLeading: !_isEditing,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _toggleEditMode,
              tooltip: 'Edit Profil',
            )
        ],
      ),
      body: _isEditing ? _buildEditMode() : _buildViewMode(),
    );
  }

  // Tampilan untuk melihat profil
  Widget _buildViewMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Header
          CircleAvatar(radius: 50, backgroundColor: Color(0xFF003366), child: Icon(Icons.person, size: 60, color: Colors.white)),
          SizedBox(height: 15),
          Text(_currentUser.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          SizedBox(height: 5),
          Text('@${_currentUser.username}', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          SizedBox(height: 30),

          // Detail
          _buildInfoCard(
            title: 'Informasi Akun',
            children: [
              _buildInfoRow(Icons.email_outlined, 'Email', _currentUser.email),
              _buildInfoRow(Icons.person_outline, 'Nama Lengkap', _currentUser.fullName),
            ],
          ),
          SizedBox(height: 20),
          _buildInfoCard(
            title: 'Informasi Pribadi',
            children: [
              _buildInfoRow(Icons.calendar_today_outlined, 'Tanggal Lahir', _currentUser.dateOfBirth != null ? DateFormat('dd MMMM yyyy').format(_currentUser.dateOfBirth!) : '-'),
              _buildInfoRow(Icons.wc, 'Gender', _currentUser.gender ?? '-'),
              _buildInfoRow(Icons.height, 'Tinggi Badan', '${_currentUser.height ?? '-'} cm'),
              _buildInfoRow(Icons.monitor_weight_outlined, 'Berat Badan', '${_currentUser.weight ?? '-'} kg'),
              _buildInfoRow(Icons.accessible, 'Riwayat Disabilitas', _currentUser.disability ?? '-'),
            ],
          ),
        ],
      ),
    );
  }

  // Tampilan untuk mengedit profil
  Widget _buildEditMode()
  {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Edit Informasi Pribadi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          TextField(controller: _fullNameController, decoration: InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder())),
          SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedGender,
            items: ['Laki-laki', 'Perempuan'].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
            onChanged: (val) => setState(() => _selectedGender = val),
            decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
          ),
          SizedBox(height: 15),
          TextField(controller: _heightController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: 'Tinggi Badan (cm)', border: OutlineInputBorder())),
          SizedBox(height: 15),
          TextField(controller: _weightController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: 'Berat Badan (kg)', border: OutlineInputBorder())),
          SizedBox(height: 15),
          DropdownButtonFormField<String>(
            value: _selectedDisability,
            items: ['Tidak Ada', 'Tuna Daksa (Kaki)', 'Tuna Netra'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (val) => setState(() => _selectedDisability = val),
            decoration: InputDecoration(labelText: 'Riwayat Disabilitas', border: OutlineInputBorder()),
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _saveChanges,
            child: Text('Simpan Perubahan'),
            style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Color(0xFF003366),
                foregroundColor: Colors.white
            ),
          )
        ],
      ),
    );
  }

  // Helper Widget
  Widget _buildInfoCard({required String title, required List<Widget> children})
  {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF003366))),
            Divider(height: 20),
            ...children
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value)
  {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade600, size: 20),
          SizedBox(width: 15),
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}