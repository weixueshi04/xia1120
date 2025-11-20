import 'package:flutter/material.dart';

class MiaoTheme {
  static const Color indigoDye = Color(0xFF1A4D7A);
  static const Color mapleRed = Color(0xFFD32F2F);
  static const Color waxWhite = Color(0xFFF5F5F5);
  static const Color scholarGold = Color(0xFFFFB300);
  static const Color silverThread = Color(0xFFBDBDBD);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: indigoDye,
        primary: indigoDye,
        secondary: mapleRed,
        surface: waxWhite,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: waxWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: indigoDye,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: indigoDye),
        titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: indigoDye),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.black87),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigoDye),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: indigoDye, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: indigoDye,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
  
  static BoxDecoration get batikBackground {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [waxWhite, indigoDye.withAlpha((0.05 * 255).round())],
      ),
    );
  }
}
