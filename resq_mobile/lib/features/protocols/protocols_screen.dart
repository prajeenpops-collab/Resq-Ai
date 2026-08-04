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
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMERGENCY PROTOCOLS'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
              ? const Center(child: CircularProgressIndicator(color: AppTheme.emergencyRed))
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
                    color: AppTheme.cyberCyan.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cyberCyan, width: 1.5),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: AppTheme.cyberCyan, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Powered by Gemini AI Triage. Describe any unique emergency to generate real-time protocols.',
                          style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                const Text('Select Category & Severity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        items: ['medical', 'fire', 'accident', 'natural_disaster', 'crime', 'other']
                            .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase(), style: const TextStyle(color: Color(0xFF111827)))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCategory = v!),
                        decoration: const InputDecoration(labelText: 'Category'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedSeverity,
                        items: ['critical', 'high', 'medium', 'low']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase(), style: const TextStyle(color: Color(0xFF111827)))))
                            .toList(),
                        onChanged: (v) => setState(() => _selectedSeverity = v!),
                        decoration: const InputDecoration(labelText: 'Severity'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: _customPromptController,
                  maxLines: 4,
                  style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Describe Emergency Incident Parameters',
                    hintText: 'e.g., Structural collapse near highway bridge with chemical spill...',
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generatingAi ? null : _generateAiProtocol,
                    icon: _generatingAi
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(_generatingAi ? 'GEMINI AI GENERATING PROTOCOL...' : 'GENERATE AI EMERGENCY PROTOCOL'),
                  ),
                ),

                if (_aiGeneratedProtocol != null) ...[
                  const SizedBox(height: 24),
                  const Text('AI Generated Protocol Result', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF111827))),
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
    final sevColor = AppTheme.severityColor(p.severityTarget);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sevColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: ExpansionTile(
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
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.severityTarget.toUpperCase(),
                  style: TextStyle(color: sevColor, fontWeight: FontWeight.w900, fontSize: 10),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${p.automatedSteps.length} Automated Steps',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.bold),
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
                const Divider(color: Color(0xFFE2E8F0)),
                Text(p.summary, style: const TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.3)),
                const SizedBox(height: 14),

                const Text('Automated Workflow Sequence:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                ...p.automatedSteps.map((step) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.play_arrow_rounded, color: AppTheme.emergencyRed, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                children: [
                                  TextSpan(text: '${step.title}: ', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 12)),
                                  TextSpan(text: step.description, style: const TextStyle(color: Color(0xFF475569), fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                const SizedBox(height: 14),

                const Text('Citizen Safety Checklist:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111827))),
                const SizedBox(height: 8),
                ...p.safetyChecklist.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: AppTheme.safeGreen, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(item, style: const TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 12)),
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
                      backgroundColor: AppTheme.emergencyRed,
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
        backgroundColor: AppTheme.emergencyRed,
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
