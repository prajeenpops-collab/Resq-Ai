import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/emergency_report.dart';
import '../protocols/protocol_execution_screen.dart';
import '../sos/sos_screen.dart';

class ReportResultScreen extends StatelessWidget {
  final EmergencyReport report;
  const ReportResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(report.severity);

    return Scaffold(
      appBar: AppBar(title: const Text('AI TRIAGE RESULT'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: severityColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(AppTheme.categoryIcon(report.category), color: severityColor, size: 36),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${report.severity.toUpperCase()} • ${report.category.toUpperCase()}',
                            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 2),
                          Text('Report ID: ${report.reportId}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('AI Situation Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(report.aiSummary, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14, height: 1.4)),
              ),
              const SizedBox(height: 20),

              const Text('Immediate Action & First-Aid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cyberCyan.withValues(alpha: 0.3)),
                ),
                child: Text(report.firstAidGuidance, style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4)),
              ),
              const SizedBox(height: 28),

              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ProtocolExecutionScreen(reportId: report.reportId),
                    ),
                  );
                },
                icon: const Icon(Icons.bolt_rounded),
                label: const Text('OPEN LIVE AUTOMATED PROTOCOL TRACKER'),
              ),
              const SizedBox(height: 12),

              OutlinedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                  (route) => false,
                ),
                child: const Text('RETURN TO SOS DASHBOARD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
