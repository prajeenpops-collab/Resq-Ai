import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../protocols/protocol_execution_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  void _loadReports() {
    setState(() {
      _reportsFuture = _apiService.myReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INCIDENT HISTORY'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error loading history: ${snapshot.error}'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey[600]),
                  const SizedBox(height: 12),
                  const Text('No past incidents recorded.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _loadReports(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, i) {
                final r = reports[i];
                final severity = (r['severity'] ?? 'low').toString();
                final category = (r['category'] ?? 'other').toString();
                final status = (r['status'] ?? 'pending').toString();
                final reportId = (r['reportId'] ?? '').toString();
                final severityColor = AppTheme.severityColor(severity);

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: severityColor.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(AppTheme.categoryIcon(category), color: severityColor, size: 24),
                    ),
                    title: Row(
                      children: [
                        Text(
                          category.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: severityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            severity.toUpperCase(),
                            style: TextStyle(color: severityColor, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            r['aiSummary'] ?? r['rawText'] ?? 'Emergency Report',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.cyberCyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Status: ${status.toUpperCase()}',
                                  style: const TextStyle(color: AppTheme.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              const Text('View Protocol >', style: TextStyle(color: AppTheme.neonAlert, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    onTap: () {
                      if (reportId.isNotEmpty) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProtocolExecutionScreen(reportId: reportId),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
