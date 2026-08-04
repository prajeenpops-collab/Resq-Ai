import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/emergency_report.dart';
import '../sos/sos_screen.dart';

class ReportResultScreen extends StatelessWidget {
  final EmergencyReport report;
  const ReportResultScreen({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    final severityColor = AppTheme.severityColor(report.severity);

    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Reported'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: severityColor, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: severityColor, size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${report.severity.toUpperCase()} · ${report.category.toUpperCase()}',
                              style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('Status: ${report.status}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('AI Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(report.aiSummary),
              const SizedBox(height: 20),
              Text('First-Aid Guidance', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(report.firstAidGuidance),
              ),
              const SizedBox(height: 28),
              Text(
                'Emergency services have been notified and dispatched based on this report.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SosScreen()),
                  (route) => false,
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
