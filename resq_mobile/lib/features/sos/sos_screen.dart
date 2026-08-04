import 'package:flutter/material.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../report/report_result_screen.dart';
import '../report/report_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final _locationService = LocationService();
  final _apiService = ApiService();
  bool _sending = false;

  Future<void> _sendSos() async {
    setState(() => _sending = true);
    try {
      final position = await _locationService.getCurrentLocation();
      if (position == null) {
        _showError('Location permission required to send SOS.');
        return;
      }

      final report = await _apiService.submitReport(
        type: 'text',
        rawText: 'SOS triggered — citizen needs immediate emergency assistance.',
        lat: position.latitude,
        lng: position.longitude,
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReportResultScreen(report: report)),
      );
    } catch (e) {
      _showError('Failed to send SOS: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ResQ AI')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'Press SOS for immediate help,\nor report a detailed emergency below.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _sending ? null : _sendSos,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red,
                    boxShadow: [
                      BoxShadow(color: Colors.red.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 10),
                    ],
                  ),
                  child: Center(
                    child: _sending
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('SOS', style: TextStyle(
                            color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportScreen()),
                ),
                icon: const Icon(Icons.edit_note),
                label: const Text('Report Emergency (Voice / Text / Image)'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
          } else if (index == 2) {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
