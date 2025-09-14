// lib/database/user_database.dart

import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart'; // Sesuaikan path jika perlu

class UserDatabase {
  // --- Singleton Setup ---
  static UserDatabase get instance => _instance;
  static final UserDatabase _instance = UserDatabase._internal();
  factory UserDatabase() => _instance;
  UserDatabase._internal();

  // --- Variabel ---
  static const String _userKey = 'registeredUser';
  SharedPreferences? _prefs;

  // Variabel in-memory yang akan digunakan oleh fungsi sinkron
  User? _registeredUser;
  User _activeUser = User.empty();

  // --- Getter Publik ---
  User get activeUser => _activeUser;

  // --- Inisialisasi (WAJIB DIPANGGIL DI main.dart) ---
  /// Memuat SharedPreferences dan data pengguna dari disk ke memori.
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    _loadUserFromPrefs();
  }

  // --- Metode Privat untuk Persistence ---
  /// Memuat data dari disk ke variabel _registeredUser.
  void _loadUserFromPrefs() {
    final String? userJson = _prefs?.getString(_userKey);
    if (userJson != null) {
      _registeredUser = User.fromJson(userJson);
    }
  }

  /// Menyimpan data dari memori ke disk. Ini adalah operasi async.
  Future<void> _saveUserToPrefs(User? user) async {
    if (user != null) {
      await _prefs?.setString(_userKey, user.toJson());
    } else {
      await _prefs?.remove(_userKey);
    }
  }

  // --- Metode Publik (NAMA FUNGSI TIDAK BERUBAH) ---

  /// Mengambil data user yang sudah terdaftar dari memori. (Sinkron)
  User? getRegisteredUser() {
    return _registeredUser;
  }

  /// Mendaftarkan user baru. (Sinkron)
  /// Menyimpan ke memori secara langsung, dan memicu penyimpanan ke disk.
  void registerUser(User user) {
    _registeredUser = user;
    _activeUser = user;
    _saveUserToPrefs(user); // "Fire and forget" async save
  }

  /// Mengatur user sebagai aktif (untuk proses login). (Sinkron)
  void login(User user) {
    _activeUser = user;
  }

  /// Memperbarui data pengguna. (Sinkron)
  /// Menyimpan ke memori secara langsung, dan memicu penyimpanan ke disk.
  void updateUser(User updatedUser) {
    _activeUser = updatedUser;
    _registeredUser = updatedUser;
    _saveUserToPrefs(updatedUser); // "Fire and forget" async save
  }

  /// Logout: Hanya membersihkan user aktif dari memori. (Sinkron)
  void clearActiveUser() {
    _activeUser = User.empty();
  }

  /// FUNGSI BARU: Menghapus semua data pengguna dari memori dan disk. (Sinkron)
  void reset() {
    _registeredUser = null;
    _activeUser = User.empty();
    _saveUserToPrefs(null); // "Fire and forget" async save untuk menghapus
  }
}