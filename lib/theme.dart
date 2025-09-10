import 'package:flutter/material.dart';

// Warna Dasar
const Color primaryColor = Color(0xFFFFCD39);
const Color secondaryColor = Color(0xFF003366);
const Color tertiaryColor = Color(0xFFF8F9FA);
const Color textColor = Color(0xFF333333);

// Buat ThemeData
final appTheme = ThemeData(
  colorScheme: const ColorScheme.light(
    primary: primaryColor,
    secondary: secondaryColor,
    surface: Colors.white,
    onPrimary: textColor,
    onSecondary: Colors.white,
    onSurface: textColor,
  ),

  scaffoldBackgroundColor: tertiaryColor,
  fontFamily: 'New SEC APP Hair',

  appBarTheme: const AppBarTheme(
    backgroundColor: tertiaryColor,
    iconTheme: IconThemeData(color: textColor),
    actionsIconTheme: IconThemeData(color: textColor, size: 28),
    elevation: 0,
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: secondaryColor,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
  ),

  textTheme: const TextTheme(
    headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
    titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
    bodyMedium: TextStyle(fontSize: 14, color: textColor),
    labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondaryColor),
  ),
);