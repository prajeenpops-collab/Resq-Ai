import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/emergency_report.dart';
import 'auth_service.dart';

class ApiService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<EmergencyReport> submitReport({
    required String type, // "voice" | "text" | "image"
    String? rawText,
    String? mediaUrl,
    required double lat,
    required double lng,
    String? address,
  }) async {
    final headers = await _headers();
    final response = await http.post(
      Uri.parse('${AppConstants.backendBaseUrl}/emergency/report'),
      headers: headers,
      body: jsonEncode({
        'type': type,
        'rawText': rawText,
        'mediaUrl': mediaUrl,
        'location': {'lat': lat, 'lng': lng},
        'address': address,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to submit report: ${response.body}');
    }

    return EmergencyReport.fromJson(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> myReports() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${AppConstants.backendBaseUrl}/emergency/reports/mine'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch reports');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }

  Future<List<Map<String, dynamic>>> myNotifications() async {
    final headers = await _headers();
    final response = await http.get(
      Uri.parse('${AppConstants.backendBaseUrl}/notifications/mine'),
      headers: headers,
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to fetch notifications');
    }
    return List<Map<String, dynamic>>.from(jsonDecode(response.body));
  }
}
