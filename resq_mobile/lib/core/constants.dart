import 'package:flutter/foundation.dart';

class AppConstants {
  static String get backendBaseUrl {
    const customUrl = String.fromEnvironment('BACKEND_URL');
    if (customUrl.isNotEmpty) return customUrl;

    if (kIsWeb ||
        defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'http://localhost:8000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  static const List<String> emergencyCategories = [
    'medical', 'fire', 'accident', 'crime', 'natural_disaster', 'other'
  ];
}
