import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- 1. Light Theme ---
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D3A99),
        secondary: Color(0xFF9B59B6),
        surface: Colors.white,
      ),
      // Setting Gayathri as the default TextTheme for Light Mode
      textTheme: GoogleFonts.gayathriTextTheme(
        ThemeData.light().textTheme,
      ),
    );
  }

  // --- 2. Dark Theme ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFF121212),
      cardColor: const Color(0xFF1E1E1E),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9B59B6), 
        secondary: Color(0xFF5D3A99),
        surface: Color(0xFF1E1E1E),
      ),
      textTheme: GoogleFonts.gayathriTextTheme(
        ThemeData.dark().textTheme,
      ),
    );
  }
}