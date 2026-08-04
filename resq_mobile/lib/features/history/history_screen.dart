import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

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
    _reportsFuture = _apiService.myReports();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident History')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return const Center(child: Text('No reports yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              final severity = (r['severity'] ?? 'low').toString();
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.severityColor(severity),
                    child: const Icon(Icons.report, color: Colors.white, size: 18),
                  ),
                  title: Text((r['category'] ?? 'other').toString().toUpperCase()),
                  subtitle: Text(r['aiSummary'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text((r['status'] ?? '').toString()),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
