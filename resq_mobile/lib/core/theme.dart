import 'package:flutter/material.dart';

class AppTheme {
  // Bold Red & White Emergency Palette
  static const Color emergencyRed = Color(0xFFDC2626); // Vivid Red
  static const Color criticalRed = Color(0xFF991B1B);  // Deep Crimson Red
  static const Color neonAlert = Color(0xFFEF4444);    // Bright Alert Red
  static const Color warningAmber = Color(0xFFD97706); // Amber Accent
  static const Color safeGreen = Color(0xFF059669);    // Safe Emerald
  static const Color cyberCyan = Color(0xFF2563EB);    // Royal Blue Accent
  static const Color lightBackground = Color(0xFFF8FAFC); // Pure Crisp Light Slate
  static const Color lightCard = Color(0xFFFFFFFF);    // Pure White Card
  static const Color darkCard = Color(0xFFFFFFFF);     // Clean White Surface for Cards
  static const Color lightBorder = Color(0xFFFCA5A5);  // Soft Red Tinted Border
  static const Color darkBackground = Color(0xFF0F172A);

  static ThemeData light = ThemeData(
    brightness: Brightness.light,
    useMaterial3: true,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: emergencyRed,
      secondary: criticalRed,
      surface: lightCard,
      error: criticalRed,
      onPrimary: Colors.white,
      onSurface: Color(0xFF111827),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: emergencyRed,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      centerTitle: true,
      shadowColor: Colors.black26,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 4,
      shadowColor: emergencyRed.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: emergencyRed.withValues(alpha: 0.2), width: 1.2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: emergencyRed,
        foregroundColor: Colors.white,
        elevation: 4,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: emergencyRed,
        side: const BorderSide(color: emergencyRed, width: 2.0),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: emergencyRed.withValues(alpha: 0.18),
      elevation: 8,
      shadowColor: Colors.black12,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: emergencyRed, fontWeight: FontWeight.bold, fontSize: 12);
        }
        return const TextStyle(color: Color(0xFF6B7280), fontSize: 12);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: emergencyRed, size: 26);
        }
        return const IconThemeData(color: Color(0xFF6B7280), size: 24);
      }),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Color(0xFF111827)),
      bodyMedium: TextStyle(color: Color(0xFF1F2937)),
      titleMedium: TextStyle(color: Color(0xFF111827)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: emergencyRed, width: 2.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      labelStyle: const TextStyle(color: Color(0xFF374151)),
    ),
  );

  static ThemeData dark = light; // Standardize on Red & White Theme

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

  static IconData categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'medical':
        return Icons.medical_services_rounded;
      case 'fire':
        return Icons.local_fire_department_rounded;
      case 'accident':
        return Icons.car_crash_rounded;
      case 'natural_disaster':
        return Icons.flood_rounded;
      case 'crime':
        return Icons.security_rounded;
      default:
        return Icons.warning_rounded;
    }
  }
}
