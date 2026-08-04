import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/location_service.dart';
import '../../services/api_service.dart';
import '../../services/protocol_service.dart';
import '../protocols/protocol_execution_screen.dart';
import '../protocols/protocols_screen.dart';
import '../report/report_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> with TickerProviderStateMixin {
  int _currentTab = 0;
  final _locationService = LocationService();
  final _apiService = ApiService();
  final _protocolService = ProtocolService();
  bool _sending = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _triggerSos({String category = 'medical', String? customText}) async {
    if (_sending) return;
    setState(() => _sending = true);

    try {
      final position = await _locationService.getCurrentLocation();
      final lat = position?.latitude ?? 37.7749;
      final lng = position?.longitude ?? -122.4194;

      final report = await _apiService.submitReport(
        type: 'text',
        rawText: customText ?? 'SOS Emergency triggered — urgent citizen assistance required for $category emergency.',
        lat: lat,
        lng: lng,
        category: category,
      );

      // Auto-trigger backend automated protocol execution
      final execution = await _protocolService.triggerProtocolExecution(
        reportId: report.reportId,
        category: category,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProtocolExecutionScreen(
            reportId: report.reportId,
            initialExecution: execution,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to trigger SOS: $e'),
            backgroundColor: AppTheme.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentTab,
        children: [
          _buildHomeDashboard(context),
          const ProtocolsScreen(),
          const HistoryScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() => _currentTab = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.emergency_rounded),
            selectedIcon: Icon(Icons.emergency_rounded, color: AppTheme.neonAlert),
            label: 'SOS Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.shield_rounded),
            selectedIcon: Icon(Icons.shield_rounded, color: AppTheme.neonAlert),
            label: 'Protocols',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_rounded),
            selectedIcon: Icon(Icons.history_rounded, color: AppTheme.neonAlert),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
            selectedIcon: Icon(Icons.person_rounded, color: AppTheme.neonAlert),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppTheme.emergencyRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('ResQ AI', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.safeGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.safeGreen, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.circle, color: AppTheme.safeGreen, size: 8),
                SizedBox(width: 6),
                Text('AI SYSTEM ACTIVE', style: TextStyle(color: AppTheme.safeGreen, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Guidance banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppTheme.cyberCyan, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap SOS for immediate help or select an emergency category to auto-trigger response protocols.',
                        style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Animated Pulsing SOS Hero Button
              ScaleTransition(
                scale: _pulseAnimation,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                  child: Container(
                    width: 210,
                    height: 210,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const RadialGradient(
                        colors: [
                          Color(0xFFFF5252),
                          Color(0xFFD32F2F),
                          Color(0xFF880E4F),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.criticalRed.withValues(alpha: 0.6),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: _sending
                          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 4)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.touch_app_rounded, color: Colors.white, size: 36),
                                SizedBox(height: 4),
                                Text(
                                  'SOS',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  'TAP FOR HELP',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Report Detailed Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ReportScreen()),
                  ),
                  icon: const Icon(Icons.record_voice_over_rounded, color: AppTheme.neonAlert),
                  label: const Text('REPORT WITH VOICE / PHOTO / TEXT'),
                ),
              ),
              const SizedBox(height: 32),

              // Quick Category Grid
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'QUICK EMERGENCY PROTOCOLS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _buildCategoryTile(context, 'Medical', Icons.medical_services_rounded, AppTheme.emergencyRed, 'medical'),
                  _buildCategoryTile(context, 'Fire', Icons.local_fire_department_rounded, AppTheme.warningAmber, 'fire'),
                  _buildCategoryTile(context, 'Crash', Icons.car_crash_rounded, AppTheme.cyberCyan, 'accident'),
                  _buildCategoryTile(context, 'Flood', Icons.flood_rounded, Colors.blueAccent, 'natural_disaster'),
                  _buildCategoryTile(context, 'Hazmat', Icons.science_rounded, Colors.purpleAccent, 'other'),
                  _buildCategoryTile(context, 'Security', Icons.security_rounded, AppTheme.safeGreen, 'crime'),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String categoryKey,
  ) {
    return InkWell(
      onTap: () => _triggerSos(category: categoryKey, customText: 'Quick Protocol Triggered for $label Emergency'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
