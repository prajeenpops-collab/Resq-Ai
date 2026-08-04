import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';

class AgencyDispatchDemoScreen extends StatefulWidget {
  final String? initialCategory;
  final String? initialText;

  const AgencyDispatchDemoScreen({
    super.key,
    this.initialCategory,
    this.initialText,
  });

  @override
  State<AgencyDispatchDemoScreen> createState() => _AgencyDispatchDemoScreenState();
}

class _AgencyDispatchDemoScreenState extends State<AgencyDispatchDemoScreen> {
  final _inputController = TextEditingController();
  String _selectedCategory = 'fire';
  String _selectedInputMode = 'text'; // text, voice, video
  bool _isAnalyzing = false;
  List<Map<String, dynamic>> _dispatchedMessages = [];
  Map<String, dynamic>? _triageResult;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    if (widget.initialText != null) {
      _inputController.text = widget.initialText!;
    } else {
      _loadPresetScenario(_selectedCategory);
    }
  }

  void _loadPresetScenario(String category) {
    setState(() {
      _selectedCategory = category;
      switch (category) {
        case 'fire':
          _inputController.text =
              'Heavy structural fire reported on 4th floor commercial complex. Thick black smoke filling stairwell, 2 occupants suffering thermal burns and smoke inhalation.';
          break;
        case 'medical':
          _inputController.text =
              'Citizen collapsed at central station. Unresponsive, no pulse detected. Bystanders starting chest compressions.';
          break;
        case 'accident':
          _inputController.text =
              'Multi-vehicle highway collision near Exit 14. Two sedans impacted at high speed, driver trapped with neck strain.';
          break;
        case 'natural_disaster':
          _inputController.text =
              'Rapid flash flood rising in riverbank district. Water levels reached 3 feet, residents stranded on rooftops.';
          break;
        case 'crime':
          _inputController.text =
              'Active armed burglary reported in commercial bank vault. Muffled shouting heard inside.';
          break;
        default:
          _inputController.text =
              'Toxic chemical container spill near industrial park. Sharp acidic fumes moving downwind.';
          break;
      }
    });
  }

  Future<void> _runAiAnalysisAndDispatch() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _dispatchedMessages.clear();
      _triageResult = null;
    });

    final position = await LocationService().getCurrentLocation();
    final lat = position?.latitude ?? 37.7749;
    final lng = position?.longitude ?? -122.4194;

    try {
      final report = await ApiService().submitReport(
        type: _selectedInputMode == 'voice' ? 'voice' : (_selectedInputMode == 'video' ? 'image' : 'text'),
        rawText: text,
        lat: lat,
        lng: lng,
        category: _selectedCategory,
      );

      final now = DateTime.now();
      final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

      List<Map<String, dynamic>> messages = [];

      // Generate realistic agency SMS dispatches based on AI analysis
      if (report.category == 'fire' || _selectedCategory == 'fire') {
        messages.add({
          'agency': 'FIRE DEPARTMENT (ENGINE & LADDER UNIT)',
          'icon': Icons.local_fire_department_rounded,
          'color': AppTheme.emergencyRed,
          'recipient': '+1 (800) 555-FIRE / Station #4',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[CRITICAL FIRE DISPATCH ALERT]\nIncident ID: #${report.reportId.substring(0, 6)}\nLocation: Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}\nRoot Cause: ${report.rootCause ?? "Structural Thermal Ignition"}\nDispatch Order: Deploy Engine #4 & Ladder #2. Water pressure boost requested.\nSummary: ${report.aiSummary}',
        });

        messages.add({
          'agency': 'HOSPITAL TRAUMA ER & BURN UNIT',
          'icon': Icons.local_hospital_rounded,
          'color': Colors.redAccent,
          'recipient': '+1 (800) 555-HOSP / ER Bay 2',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[TRAUMA BURN & SMOKE ER ALERT]\nIncident ID: #${report.reportId.substring(0, 6)}\nPatient Status: Burn Injury & Smoke Inhalation Risk.\nDispatch Order: ALS Mobile ICU Ambulance #9 assigned. Prep ER Trauma Bay 2 with O2 mask & burn kit.\nGuidance: ${report.firstAidGuidance}',
        });

        messages.add({
          'agency': 'POLICE PATROL (PERIMETER CONTROL)',
          'icon': Icons.local_police_rounded,
          'color': AppTheme.cyberCyan,
          'recipient': '+1 (800) 555-POLICE / Unit 102',
          'status': 'READ BY DISPATCHER ✓✓',
          'time': timeStr,
          'smsBody':
              '[PERIMETER & HYDRANT LOCKOUT]\nIncident ID: #${report.reportId.substring(0, 6)}\nAction: Block traffic within 500m radius of fire hydrants.',
        });
      } else if (report.category == 'medical') {
        messages.add({
          'agency': 'HOSPITAL TRAUMA ER & AMBULANCE',
          'icon': Icons.medical_services_rounded,
          'color': AppTheme.emergencyRed,
          'recipient': '+1 (800) 555-MEDIC / Bay 1',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[CRITICAL CARDIAC / MEDICAL ALERT]\nIncident ID: #${report.reportId.substring(0, 6)}\nLocation: Lat ${lat.toStringAsFixed(4)}, Lng ${lng.toStringAsFixed(4)}\nAction: ALS Mobile ICU Ambulance RESQ-AMB-09 dispatched. ETA: 4 mins.\nCitizen Guidance Streamed: CPR 110 BPM Metronome Sync active.',
        });
      } else if (report.category == 'accident') {
        messages.add({
          'agency': 'FIRE RESCUE (EXTRICATION SQUAD)',
          'icon': Icons.car_crash_rounded,
          'color': AppTheme.warningAmber,
          'recipient': '+1 (800) 555-RESCUE / Team 3',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[HIGHWAY EXTRICATION DISPATCH]\nIncident ID: #${report.reportId.substring(0, 6)}\nAction: Hydraulic jaws of life unit dispatched to highway exit.',
        });
        messages.add({
          'agency': 'TRAFFIC POLICE & PARAMEDICS',
          'icon': Icons.local_police_rounded,
          'color': AppTheme.cyberCyan,
          'recipient': '+1 (800) 555-POLICE / Highway Division',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[TRAFFIC DETOUR ALERT]\nDeploy detour signs upstream of collision coordinate.',
        });
      } else {
        messages.add({
          'agency': 'EMERGENCY DISPATCH CENTER',
          'icon': Icons.warning_amber_rounded,
          'color': Colors.purpleAccent,
          'recipient': '+1 (800) 555-RESQ / Main Dispatch',
          'status': 'DELIVERED ✓✓',
          'time': timeStr,
          'smsBody':
              '[MULTI-AGENCY DISPATCH NOTICE]\nIncident ID: #${report.reportId.substring(0, 6)}\nRoot Cause: ${report.rootCause ?? "Hazard Incident"}\nSummary: ${report.aiSummary}',
        });
      }

      setState(() {
        _dispatchedMessages = messages;
        _triageResult = {
          'reportId': report.reportId,
          'category': report.category,
          'severity': report.severity,
          'rootCause': report.rootCause,
          'aiSummary': report.aiSummary,
          'firstAidGuidance': report.firstAidGuidance,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dispatch Simulation Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('DISPATCH SMS SIMULATOR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.mark_chat_read_rounded, color: AppTheme.warningAmber, size: 36),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI MULTI-MODAL DISPATCH DEMO',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Analyzes Voice, Text, or Video & auto-routes SMS messages to Fire Dept, Hospital ER & Police.',
                            style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Input Mode Selector
              const Text('1. Select Input Mode', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildModeChip('text', 'Typed Text', Icons.text_fields_rounded),
                  const SizedBox(width: 8),
                  _buildModeChip('voice', 'Voice Note', Icons.mic_rounded),
                  const SizedBox(width: 8),
                  _buildModeChip('video', 'Photo / Video', Icons.videocam_rounded),
                ],
              ),
              const SizedBox(height: 16),

              // Emergency Domain Selector
              const Text('2. Select Emergency Domain Scenario', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryFilter('fire', 'Fire Accident', Icons.local_fire_department_rounded, AppTheme.emergencyRed),
                    const SizedBox(width: 8),
                    _buildCategoryFilter('medical', 'Medical Emergency', Icons.medical_services_rounded, Colors.redAccent),
                    const SizedBox(width: 8),
                    _buildCategoryFilter('accident', 'Vehicle Crash', Icons.car_crash_rounded, AppTheme.warningAmber),
                    const SizedBox(width: 8),
                    _buildCategoryFilter('natural_disaster', 'Flash Flood', Icons.flood_rounded, Colors.blueAccent),
                    const SizedBox(width: 8),
                    _buildCategoryFilter('crime', 'Security Threat', Icons.security_rounded, AppTheme.safeGreen),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Scenario Text Input Box
              TextField(
                controller: _inputController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Emergency Report Input',
                  hintText: 'Describe the emergency in detail...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),

              // Submit & Dispatch Button
              ElevatedButton.icon(
                onPressed: _isAnalyzing ? null : _runAiAnalysisAndDispatch,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.emergencyRed,
                ),
                icon: _isAnalyzing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, size: 22),
                label: Text(
                  _isAnalyzing ? 'GEMINI AI ANALYZING & ROUTING...' : 'ANALYZE & DISPATCH SMS MESSAGES',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(height: 24),

              // AI Triage & Root Cause Banner
              if (_triageResult != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppTheme.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.severityColor(_triageResult!['severity']), width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(AppTheme.categoryIcon(_triageResult!['category']), color: AppTheme.severityColor(_triageResult!['severity'])),
                          const SizedBox(width: 8),
                          Text(
                            '${_triageResult!['severity'].toString().toUpperCase()} • ${_triageResult!['category'].toString().toUpperCase()}',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.severityColor(_triageResult!['severity'])),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Root Cause: ${_triageResult!['rootCause'] ?? "Analyzed by Gemini AI"}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(_triageResult!['aiSummary'] ?? '', style: const TextStyle(fontSize: 13, height: 1.3)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Dispatched Messages Feed Header
              if (_dispatchedMessages.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('3. Live Outgoing Agency SMS Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.safeGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_dispatchedMessages.length} SMS SENT',
                        style: const TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Cards for each dispatched SMS
                ..._dispatchedMessages.map((msg) => _buildSmsMessageCard(msg, isDark)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String mode, String label, IconData icon) {
    final selected = _selectedInputMode == mode;
    return Expanded(
      child: ChoiceChip(
        label: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? Colors.white : AppTheme.emergencyRed),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: selected ? Colors.white : null)),
          ],
        ),
        selected: selected,
        onSelected: (_) => setState(() => _selectedInputMode = mode),
        selectedColor: AppTheme.emergencyRed,
        padding: const EdgeInsets.symmetric(vertical: 8),
      ),
    );
  }

  Widget _buildCategoryFilter(String category, String label, IconData icon, Color color) {
    final selected = _selectedCategory == category;
    return ChoiceChip(
      avatar: Icon(icon, color: selected ? Colors.white : color, size: 18),
      label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : null, fontSize: 12)),
      selected: selected,
      onSelected: (_) => _loadPresetScenario(category),
      selectedColor: color,
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }

  Widget _buildSmsMessageCard(Map<String, dynamic> msg, bool isDark) {
    final Color color = msg['color'];
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agency Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(msg['icon'] as IconData, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    msg['agency'].toString(),
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
                Text(
                  msg['time'].toString(),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Recipient: ${msg['recipient']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    Text(msg['status'].toString(), style: const TextStyle(color: AppTheme.safeGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 10),

                // SMS Bubble
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    msg['smsBody'].toString(),
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
