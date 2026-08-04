class AppConstants {
  // CHANGE this to your deployed backend URL before the demo.
  // Use 10.0.2.2 instead of localhost when testing on Android emulator.
  static const String backendBaseUrl = 'http://10.0.2.2:8000/api/v1';

  static const List<String> emergencyCategories = [
    'medical', 'fire', 'accident', 'crime', 'natural_disaster', 'other'
  ];
}
