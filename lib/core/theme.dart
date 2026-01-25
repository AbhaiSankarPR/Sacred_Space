import 'package:flutter/material.dart';

class AppTheme {
  // Existing Light Theme
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light, // explicit brightness
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFFF5F7FA), // Soft grey looks better than pure white
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF5D3A99),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Colors.white,
      // Define a ColorScheme for better compatibility
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF5D3A99),
        secondary: Color(0xFF9B59B6),
      ),
    );
  }

  // --- ADD THIS: Dark Theme ---
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark, // This handles text colors automatically
      primarySwatch: Colors.deepPurple,
      scaffoldBackgroundColor: const Color(0xFF121212), // Standard Dark Mode background
      fontFamily: 'Roboto',
      cardColor: const Color(0xFF1E1E1E), // Slightly lighter grey for cards
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1F1F1F), // Dark Header
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      // Dark mode color scheme
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF9B59B6), // Lighter purple stands out better on black
        secondary: Color(0xFF5D3A99),
        surface: Color(0xFF1E1E1E),
      ),
    );
  }
}