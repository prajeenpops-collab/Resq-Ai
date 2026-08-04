import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/protocol.dart';
import 'auth_service.dart';

class ProtocolService {
  final AuthService _authService = AuthService();

  Future<List<EmergencyProtocol>> fetchProtocols() async {
    try {
      final token = await _authService.getIdToken();
      final res = await http
          .get(
            Uri.parse('${AppConstants.backendBaseUrl}/protocols'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map((item) => EmergencyProtocol.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching protocols from API: $e');
    }
    return _getFallbackProtocols();
  }

  Future<ActiveProtocolExecution?> triggerProtocolExecution({
    required String reportId,
    String? protocolId,
  }) async {
    try {
      final token = await _authService.getIdToken();
      final res = await http
          .post(
            Uri.parse('${AppConstants.backendBaseUrl}/protocols/execute'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'reportId': reportId,
              if (protocolId != null) 'protocolId': protocolId,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ActiveProtocolExecution.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error triggering protocol execution: $e');
    }

    // Fallback simulation for offline execution
    return _generateFallbackExecution(reportId, protocolId ?? 'cardiac_arrest');
  }

  Future<ActiveProtocolExecution?> fetchActiveTelemetry(String reportId) async {
    try {
      final token = await _authService.getIdToken();
      final res = await http
          .get(
            Uri.parse('${AppConstants.backendBaseUrl}/protocols/active/$reportId'),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return ActiveProtocolExecution.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error fetching active telemetry: $e');
    }
    return _generateFallbackExecution(reportId, 'cardiac_arrest');
  }

  Future<EmergencyProtocol?> generateAiCustomProtocol({
    required String rawText,
    String category = 'other',
    String severity = 'high',
  }) async {
    try {
      final token = await _authService.getIdToken();
      final res = await http
          .post(
            Uri.parse('${AppConstants.backendBaseUrl}/protocols/ai-generate'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'rawText': rawText,
              'category': category,
              'severity': severity,
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return EmergencyProtocol.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error generating AI protocol: $e');
    }
    return null;
  }

  // Local fallback protocols for offline or dev fallback
  List<EmergencyProtocol> _getFallbackProtocols() {
    return [
      EmergencyProtocol(
        protocolId: 'cardiac_arrest',
        title: 'Cardiac & Critical Medical Response Protocol',
        category: 'medical',
        severityTarget: 'critical',
        icon: 'favorite',
        summary: 'Rapid 5-phase automated protocol for cardiac arrest, severe trauma, or respiratory failure.',
        automatedSteps: [
          ProtocolStep(stepNumber: 1, title: 'Immediate Critical Triage Alarm', description: 'Auto-flagged as Red Tier 1 incident.', actionType: 'auto_triage', etaSeconds: 15, status: 'completed'),
          ProtocolStep(stepNumber: 2, title: 'Automated ALS Ambulance Dispatch', description: 'Nearest Mobile ICU assigned with GPS lock.', actionType: 'auto_dispatch', etaSeconds: 60, status: 'in_progress'),
          ProtocolStep(stepNumber: 3, title: 'Emergency Contact & Beacon Broadcast', description: 'Alert SMS sent to emergency contacts.', actionType: 'broadcast_alert', etaSeconds: 120, status: 'pending'),
          ProtocolStep(stepNumber: 4, title: 'Interactive CPR Metronome Sync', description: 'Stream step-by-step CPR guide to mobile.', actionType: 'first_aid_prompt', etaSeconds: 180, status: 'pending'),
          ProtocolStep(stepNumber: 5, title: 'Trauma ER Pre-Arrival Notification', description: 'Victim profile transmitted to ER bay.', actionType: 'incident_command_sync', etaSeconds: 300, status: 'pending'),
        ],
        safetyChecklist: [
          'Tap shoulders and shout: "Are you okay?"',
          'Call for help & locate nearest AED.',
          'Place patient flat on back on hard surface.',
          'Push hard and fast in center of chest (100-120 bpm).',
          'Monitor breathing until paramedics arrive.',
        ],
      ),
      EmergencyProtocol(
        protocolId: 'structure_fire',
        title: 'Structural Fire & Evacuation Protocol',
        category: 'fire',
        severityTarget: 'critical',
        icon: 'local_fire_department',
        summary: 'Automated fire suppression, occupant evacuation alert, and multi-agency perimeter response.',
        automatedSteps: [
          ProtocolStep(stepNumber: 1, title: 'Fire Classification & Geofence Alarm', description: 'Evacuation boundary established.', actionType: 'auto_triage', etaSeconds: 20, status: 'completed'),
          ProtocolStep(stepNumber: 2, title: 'Heavy Fire Rescue Dispatch', description: 'Engine & Ladder team deployed.', actionType: 'auto_dispatch', etaSeconds: 90, status: 'in_progress'),
          ProtocolStep(stepNumber: 3, title: 'Evacuation Broadcast to Contacts', description: 'Emergency alert sent to contacts.', actionType: 'broadcast_alert', etaSeconds: 150, status: 'pending'),
          ProtocolStep(stepNumber: 4, title: 'Low-Smoke Escape Path Guide', description: 'Instructions displayed on mobile.', actionType: 'first_aid_prompt', etaSeconds: 210, status: 'pending'),
          ProtocolStep(stepNumber: 5, title: 'Municipal Hydrant Network Boost', description: 'Water pressure boosted in quadrant.', actionType: 'incident_command_sync', etaSeconds: 360, status: 'pending'),
        ],
        safetyChecklist: [
          'Crawl low under smoke — clean air is near floor.',
          'Feel doors before opening; if hot, do NOT open.',
          'Stop, Drop, and Roll if clothes catch fire.',
          'Once outside, stay out. Never re-enter.',
        ],
      ),
    ];
  }

  ActiveProtocolExecution _generateFallbackExecution(String reportId, String protoId) {
    final protos = _getFallbackProtocols();
    final p = protos.firstWhere((element) => element.protocolId == protoId, orElse: () => protos.first);

    return ActiveProtocolExecution(
      reportId: reportId,
      protocolId: p.protocolId,
      title: p.title,
      category: p.category,
      severity: p.severityTarget,
      status: 'executing',
      currentStepIndex: 2,
      totalSteps: p.automatedSteps.length,
      automatedSteps: p.automatedSteps,
      dispatchedUnits: [
        DispatchedUnit(
          unitId: 'RESQ-AMB-09',
          type: 'ambulance',
          unitClass: 'ALS Mobile ICU Unit #4',
          status: 'en_route',
          etaSeconds: 280,
          driverName: 'Captain J. Miller & Medic Squad',
          contactPhone: '+1-800-RESQ-MED',
        ),
        DispatchedUnit(
          unitId: 'RESQ-PATROL-12',
          type: 'police',
          unitClass: 'Traffic & Perimeter Control Unit',
          status: 'en_route',
          etaSeconds: 190,
          driverName: 'Officer R. Davis',
          contactPhone: '+1-800-RESQ-POL',
        ),
      ],
      safetyChecklist: p.safetyChecklist,
      contactsNotified: true,
      emergencyBroadcastSent: true,
      startedAt: DateTime.now(),
    );
  }
}
