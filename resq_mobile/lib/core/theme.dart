import 'package:flutter/material.dart';

class AppTheme {
  static const Color emergencyRed = Color(0xFFE53935);
  static const Color criticalRed = Color(0xFFB71C1C);
  static const Color safeGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFF9A825);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    colorSchemeSeed: emergencyRed,
    scaffoldBackgroundColor: const Color(0xFFF7F7F9),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static ThemeData dark = ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
    colorSchemeSeed: emergencyRed,
    scaffoldBackgroundColor: const Color(0xFF121214),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1C1E),
      elevation: 0,
      centerTitle: true,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );

  static Color severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return criticalRed;
      case 'high':
        return emergencyRed;
      case 'medium':
        return warningAmber;
      default:
        return safeGreen;
    }
  }
}
