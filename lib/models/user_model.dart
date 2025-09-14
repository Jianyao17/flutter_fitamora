// lib/models/user_model.dart

import 'dart:convert';

class User {
  final String fullName;
  final String email;
  final String username;
  final String password;
  final DateTime? dateOfBirth;
  final String? gender;
  final int? height;
  final int? weight;
  final String? disability;

  User({
    required this.fullName,
    required this.email,
    required this.username,
    required this.password,
    this.dateOfBirth,
    this.gender,
    this.height,
    this.weight,
    this.disability,
  });

  User copyWith({
    String? fullName,
    String? email,
    String? username,
    String? password,
    DateTime? dateOfBirth,
    String? gender,
    int? height,
    int? weight,
    String? disability,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      username: username ?? this.username,
      password: password ?? this.password,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      disability: disability ?? this.disability,
    );
  }

  // --- FUNGSI INI WAJIB ADA LAGI ---
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'username': username,
      'password': password,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'height': height,
      'weight': weight,
      'disability': disability,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      disability: map['disability'],
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  factory User.empty()
    => User(fullName: '', email: '', username: '', password: '',);
}