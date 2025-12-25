import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,

    scaffoldBackgroundColor: const Color(0xFFF5F5F5),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF4CAF50), // exemple
      surface: Colors.white,
      onSurface: Color(0xFF1A1A1A),
    ),

    textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFF1A1A1A))),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,

    scaffoldBackgroundColor: const Color(0xFF121212),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF4CAF50),
      surface: Color(0xFF1E1E1E),
      onSurface: Color(0xFFEAEAEA),
    ),

    textTheme: const TextTheme(bodyMedium: TextStyle(color: Color(0xFFEAEAEA))),
  );
}
