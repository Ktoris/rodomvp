import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class AppTheme {
  static const Color darkBlue = Color(0xFF003366);
  static const Color teal = Color(0xFF008080);
  static const Color accentOrange = Color(0xFFFF8C00);
  static const Color backgroundGrey = Color(0xFFF9F9FE);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundGrey,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkBlue,
        primary: darkBlue,
        secondary: teal,
        tertiary: accentOrange,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(),

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
          backgroundColor: darkBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: darkBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        labelStyle: const TextStyle(color: Colors.black54),
        hintStyle: const TextStyle(color: Colors.black26),
      ),
    );
  }
}