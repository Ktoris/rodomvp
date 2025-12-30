import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryMint = Color(0xFF2AB090);
  static const Color backgroundGrey = Color(0xFFF8F9FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryMint,
        primary: primaryMint,
        surface: Colors.white,
      ),

      // FIX: Changed CardTheme to CardThemeData
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
        color: Colors.white,
      ),

      // Added ChipTheme to make your "Popular" tags look right
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
      ),

      // Clean AppBar style
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundGrey,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.black, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryMint,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
    );
  }
}