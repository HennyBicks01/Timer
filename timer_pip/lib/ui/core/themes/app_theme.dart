import 'package:flutter/material.dart';

class AppTheme
{
  // Define app-wide theming
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.light,
      // Add more theme configurations
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      // Add more theme configurations
    );
  }
}
