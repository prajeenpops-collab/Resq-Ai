import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/protocol.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../services/protocol_service.dart';
import 'protocol_execution_screen.dart';

class ProtocolsScreen extends StatefulWidget {
  const ProtocolsScreen({super.key});

  @override
  State<ProtocolsScreen> createState() => _ProtocolsScreenState();
}

class _ProtocolsScreenState extends State<ProtocolsScreen> with SingleTickerProviderStateMixin {
  final ProtocolService _protocolService = ProtocolService();
  late TabController _tabController;

  List<EmergencyProtocol> _protocols = [];
  bool _loading = true;

  // AI Generator state
  final TextEditingController _customPromptController = TextEditingController();
  String _selectedCategory = 'medical';
  String _selectedSeverity = 'critical';
  bool _generatingAi = false;
  EmergencyProtocol? _aiGeneratedProtocol;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProtocols();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customPromptController.dispose();
    super.dispose();
  }

  Future<void> _loadProtocols() async {
    try {
      final list = await _protocolService.fetchProtocols();
      if (mounted) {
        setState(() {
          _protocols = list;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _generateAiProtocol() async {
    if (_customPromptController.text.trim().isEmpty) return;
    setState(() => _generatingAi = true);

    final proto = await _protocolService.generateAiCustomProtocol(
      rawText: _customPromptController.text.trim(),
      category: _selectedCategory,
      severity: _selectedSeverity,
    );

    if (mounted) {
      setState(() {
        _aiGeneratedProtocol = proto;
        _generatingAi = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY PROTOCOLS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.neonAlert,
          labelColor: AppTheme.neonAlert,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.shield_rounded), text: 'Standard Protocols'),
            Tab(icon: Icon(Icons.auto_awesome_rounded), text: 'AI Generator'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Standard Protocols Catalog
          _loading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _loadProtocols,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _protocols.length,
                    itemBuilder: (context, index) {
                      final p = _protocols[index];
                      return _buildProtocolCard(context, p);
                    },
                  ),
                ),

          // Tab 2: AI Protocol Customizer
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.cyberCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cyberCyan.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.cyberCyan, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Powered by Gemini AI Triage. Describe any unique emergency to generate real-time protocols.',
                          style: TextStyle(color: Colors.white, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Inputs
                const Text('Emergency Description', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextField(
                  controller: _customPromptController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Chemical smell in underground subway platform with multiple people coughing...',
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: ['medical', 'fire', 'accident', 'natural_disaster', 'crime', 'other']
                                .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase())))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedCategory = val!),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _selectedSeverity,
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: ['critical', 'high', 'medium', 'low']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                                .toList(),
                            onChanged: (val) => setState(() => _selectedSeverity = val!),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generatingAi ? null : _generateAiProtocol,
                    icon: _generatingAi
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(_generatingAi ? 'GENERATING PROTOCOL...' : 'GENERATE AI RESPONSE PROTOCOL'),
                  ),
                ),

                if (_aiGeneratedProtocol != null) ...[
                  const SizedBox(height: 28),
                  Text('GENERATED AI PROTOCOL', style: theme.textTheme.labelMedium?.copyWith(color: AppTheme.cyberCyan, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildProtocolCard(context, _aiGeneratedProtocol!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProtocolCard(BuildContext context, EmergencyProtocol p) {
    Color sevColor = AppTheme.severityColor(p.severityTarget);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: sevColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(AppTheme.categoryIcon(p.category), color: sevColor, size: 24),
        ),
        title: Text(
          p.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.severityTarget.toUpperCase(),
                  style: TextStyle(color: sevColor, fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.automatedSteps.length} Automated Steps',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(color: Color(0xFF334155)),
                Text(p.summary, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13)),
                const SizedBox(height: 14),

                const Text('Automated Workflow Sequence:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 8),
                ...p.automatedSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: AppTheme.neonAlert, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${step.title}: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                                  TextSpan(text: step.description, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),

                const Text('Citizen Safety Checklist:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                const SizedBox(height: 8),
                ...p.safetyChecklist.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.safeGreen, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(item, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _triggerProtocolNow(p),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.neonAlert,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.bolt_rounded, size: 20),
                    label: Text(
                      'EXECUTE ${p.title.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _triggerProtocolNow(EmergencyProtocol p) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Triggering ${p.title}...'),
        backgroundColor: AppTheme.neonAlert,
        duration: const Duration(seconds: 1),
      ),
    );

    final position = await LocationService().getCurrentLocation();
    final lat = position?.latitude ?? 37.7749;
    final lng = position?.longitude ?? -122.4194;

    final report = await ApiService().submitReport(
      type: 'text',
      rawText: 'Emergency Protocol Triggered: ${p.title}',
      lat: lat,
      lng: lng,
      category: p.category,
    );

    final execution = await ProtocolService().triggerProtocolExecution(
      reportId: report.reportId,
      protocolId: p.protocolId,
      category: p.category,
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
  }
}
