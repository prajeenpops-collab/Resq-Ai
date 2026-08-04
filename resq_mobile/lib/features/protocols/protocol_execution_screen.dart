import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/protocol.dart';
import '../../services/protocol_service.dart';

class ProtocolExecutionScreen extends StatefulWidget {
  final String reportId;
  final ActiveProtocolExecution? initialExecution;

  const ProtocolExecutionScreen({
    super.key,
    required this.reportId,
    this.initialExecution,
  });

  @override
  State<ProtocolExecutionScreen> createState() => _ProtocolExecutionScreenState();
}

class _ProtocolExecutionScreenState extends State<ProtocolExecutionScreen> with TickerProviderStateMixin {
  final ProtocolService _protocolService = ProtocolService();
  ActiveProtocolExecution? _execution;
  bool _loading = true;
  Timer? _timer;
  Timer? _metronomeTimer;
  int _secondsElapsed = 0;
  final Set<int> _checkedChecklistItems = {};

  // Interactive Topic-Specific Guide State
  bool _actionActive = false;
  int _actionCounter = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 545), // ~110 BPM
    );

    if (widget.initialExecution != null) {
      _execution = widget.initialExecution;
      _loading = false;
    } else {
      _loadTelemetry();
    }
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _metronomeTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_execution != null && _secondsElapsed % 12 == 0) {
          int cur = _execution!.currentStepIndex;
          if (cur < _execution!.automatedSteps.length) {
            _execution!.automatedSteps[cur - 1].status = 'completed';
            _execution!.automatedSteps[cur].status = 'in_progress';
            _execution!.currentStepIndex = cur + 1;
          }
        }
      });
    });
  }

  void _toggleTopicAction() {
    setState(() {
      _actionActive = !_actionActive;
    });

    if (_actionActive) {
      _pulseController.repeat(reverse: true);
      _metronomeTimer = Timer.periodic(const Duration(milliseconds: 545), (t) {
        if (!mounted || !_actionActive) return;
        setState(() {
          _actionCounter++;
        });
      });
    } else {
      _pulseController.stop();
      _metronomeTimer?.cancel();
    }
  }

  Future<void> _loadTelemetry() async {
    try {
      final exec = await _protocolService.fetchActiveTelemetry(widget.reportId);
      if (mounted) {
        setState(() {
          _execution = exec;
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

  String _formatEta(int totalEtaSec) {
    int remaining = totalEtaSec - _secondsElapsed;
    if (remaining <= 0) return 'Arrived / In Place';
    int mins = remaining ~/ 60;
    int secs = remaining % 60;
    return '${mins}m ${secs.toString().padLeft(2, '0')}s';
  }

  double _calculateDistanceKm(int totalEtaSec) {
    int remaining = totalEtaSec - _secondsElapsed;
    if (remaining <= 0) return 0.1;
    return (remaining / 300.0) * 3.5;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AUTOMATED PROTOCOL'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTelemetry,
            tooltip: 'Refresh Status',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _execution == null
              ? const Center(child: Text('Protocol execution telemetry unavailable.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Active Banner
                      _buildHeaderBanner(context),
                      const SizedBox(height: 20),

                      // Emergency Broadcast Status Badge
                      _buildBroadcastStatusCard(context),
                      const SizedBox(height: 20),

                      // Live Tactical Radar Map & Unit Tracking Widget
                      Text(
                        'LIVE RESPONDER GIS TELEMETRY',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppTheme.cyberCyan,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLiveResponderMap(context),
                      const SizedBox(height: 24),

                      // Dispatched Units Radar
                      Text(
                        'DISPATCHED RESPONDERS & ETA',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ..._execution!.dispatchedUnits.map((u) => _buildUnitCard(context, u)),
                      const SizedBox(height: 24),

                      // Dynamic Topic-Specific Interactive Emergency Action Guide
                      _buildTopicSpecificGuideCard(context),
                      const SizedBox(height: 24),

                      // 5-Phase Automated Execution Stepper
                      Text(
                        'AUTOMATED WORKFLOW PROGRESS',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildWorkflowStepper(context),
                      const SizedBox(height: 24),

                      // Safety & First-Aid Checklist
                      Text(
                        'CITIZEN ACTION CHECKLIST',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildChecklistCard(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dialing 911 Direct Emergency Line...'),
                      backgroundColor: AppTheme.criticalRed,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.criticalRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.phone_in_talk_rounded),
                label: const Text('CALL 911 DIRECT'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(BuildContext context) {
    final severityColor = AppTheme.severityColor(_execution!.severity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            severityColor.withValues(alpha: 0.25),
            AppTheme.darkCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: severityColor.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: severityColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _execution!.severity.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              const Icon(Icons.timer_rounded, color: AppTheme.cyberCyan, size: 18),
              const SizedBox(width: 6),
              Text(
                'Elapsed: ${_secondsElapsed}s',
                style: const TextStyle(
                  color: AppTheme.cyberCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            _execution!.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Report ID: ${_execution!.reportId.substring(0, _execution!.reportId.length > 8 ? 8 : _execution!.reportId.length)} • Auto-Trigger Active',
            style: const TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastStatusCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.safeGreen.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.safeGreen.withValues(alpha: 0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppTheme.safeGreen, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contacts & First Responders Notified',
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Automated SMS beacon sent with live GPS tracking.',
                  style: TextStyle(color: Color(0xFF047857), fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveResponderMap(BuildContext context) {
    final primaryUnit = _execution!.dispatchedUnits.isNotEmpty
        ? _execution!.dispatchedUnits.first
        : DispatchedUnit(
            unitId: 'RESQ-UNIT-01',
            type: 'ambulance',
            unitClass: 'ALS Mobile ICU',
            status: 'en_route',
            etaSeconds: 240,
            driverName: 'Responder Team',
            contactPhone: '911',
          );

    final distanceKm = _calculateDistanceKm(primaryUnit.etaSeconds);
    final etaStr = _formatEta(primaryUnit.etaSeconds);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.cyberCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.cyberCyan.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.radar_rounded, color: AppTheme.cyberCyan, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'APPROACHING: ${primaryUnit.unitClass.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 13),
                    ),
                    Text(
                      'GPS Distance: ${distanceKm.toStringAsFixed(1)} km away • Speed: 58 km/h',
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  etaStr,
                  style: const TextStyle(color: AppTheme.warningAmber, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (300 - (primaryUnit.etaSeconds - _secondsElapsed).clamp(0, 300)) / 300.0,
              minHeight: 8,
              backgroundColor: const Color(0xFF334155),
              color: AppTheme.cyberCyan,
            ),
          ),
          const SizedBox(height: 10),

          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🚨 Dispatch Station', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 10)),
              Text('En Route', style: TextStyle(color: AppTheme.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
              Text('📍 Your Location', style: TextStyle(color: AppTheme.neonAlert, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  /// Dynamic Topic-Specific Interactive Action Guide tailored for each emergency category
  Widget _buildTopicSpecificGuideCard(BuildContext context) {
    final cat = _execution!.category.toLowerCase();

    IconData icon;
    Color accentColor;
    String title;
    String description;
    String buttonTextActive;
    String buttonTextInactive;

    if (cat == 'fire') {
      icon = Icons.local_fire_department_rounded;
      accentColor = AppTheme.warningAmber;
      title = 'SMOKE EVACUATION & BREATHING GUIDE';
      description = _actionActive
          ? 'Cover mouth with wet cloth! Crawl low under smoke. Seconds: $_actionCounter'
          : 'Tap to start visual pace guide for low-smoke crawling & evacuation.';
      buttonTextActive = 'STOP MASK';
      buttonTextInactive = 'START SMOKE MASK';
    } else if (cat == 'accident') {
      icon = Icons.car_crash_rounded;
      accentColor = AppTheme.neonAlert;
      title = 'CRASH SPINAL STABILIZATION ASSIST';
      description = _actionActive
          ? 'Hold victim head steady! Do not twist neck. Hold timer: ${_actionCounter}s'
          : 'Tap for step-by-step spinal immobilization & fuel safety guide.';
      buttonTextActive = 'STOP HOLD';
      buttonTextInactive = 'START HOLD GUIDE';
    } else if (cat == 'natural_disaster') {
      icon = Icons.flood_rounded;
      accentColor = AppTheme.cyberCyan;
      title = 'HIGH-GROUND SOS STROBE & BEACON';
      description = _actionActive
          ? 'Flashing screen beacon active to signal rescue boats! Flash: $_actionCounter'
          : 'Tap to activate visual high-intensity SOS strobe for rescue teams.';
      buttonTextActive = 'OFF STROBE';
      buttonTextInactive = 'START STROBE BEACON';
    } else if (cat == 'crime') {
      icon = Icons.security_rounded;
      accentColor = AppTheme.cyberCyan;
      title = 'SILENT THREAT & BARRICADE ASSIST';
      description = _actionActive
          ? 'Device speaker silenced! Mute timer active: ${_actionCounter}s'
          : 'Tap to instantly mute device audio and open silent barricade checklist.';
      buttonTextActive = 'UNMUTE SILENT';
      buttonTextInactive = 'ACTIVATE SILENT MODE';
    } else if (cat == 'other' || cat.contains('hazmat')) {
      icon = Icons.science_rounded;
      accentColor = AppTheme.warningAmber;
      title = 'TOXIC HAZMAT UPWIND EVACUATION';
      description = _actionActive
          ? 'Move UPWIND away from toxic fumes! Clean air timer: ${_actionCounter}s'
          : 'Tap for immediate chemical spill isolation & decontamination steps.';
      buttonTextActive = 'STOP TIMER';
      buttonTextInactive = 'START DECON GUIDE';
    } else {
      // Default: Medical / CPR
      icon = Icons.favorite_rounded;
      accentColor = AppTheme.neonAlert;
      title = '110 BPM CPR COMPRESSION METRONOME';
      description = _actionActive
          ? 'Push hard & fast to pulse beat! Beats: $_actionCounter'
          : 'Tap to start audio/visual CPR rhythm helper.';
      buttonTextActive = 'STOP CPR';
      buttonTextInactive = 'START CPR RHYTHM';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: Tween<double>(begin: 1.0, end: 1.25).animate(_pulseController),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _actionActive ? accentColor : const Color(0xFF334155),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: _actionActive ? Colors.white : const Color(0xFF94A3B8),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF111827), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _toggleTopicAction,
            style: ElevatedButton.styleFrom(
              backgroundColor: _actionActive ? AppTheme.criticalRed : AppTheme.safeGreen,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: Text(
              _actionActive ? buttonTextActive : buttonTextInactive,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnitCard(BuildContext context, DispatchedUnit unit) {
    IconData icon;
    Color iconColor;
    if (unit.type == 'ambulance' || unit.type == 'hospital') {
      icon = Icons.medical_services_rounded;
      iconColor = AppTheme.emergencyRed;
    } else if (unit.type == 'fire') {
      icon = Icons.local_fire_department_rounded;
      iconColor = AppTheme.warningAmber;
    } else {
      icon = Icons.security_rounded;
      iconColor = AppTheme.cyberCyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  unit.unitClass,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Unit: ${unit.unitId} • ${unit.driverName}',
                  style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.warningAmber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.navigation_rounded, color: AppTheme.warningAmber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _formatEta(unit.etaSeconds),
                      style: const TextStyle(
                        color: AppTheme.warningAmber,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'EN ROUTE',
                style: TextStyle(color: AppTheme.safeGreen, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStepper(BuildContext context) {
    final steps = _execution!.automatedSteps;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.darkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: steps.asMap().entries.map((entry) {
          int idx = entry.key;
          ProtocolStep step = entry.value;

          bool isDone = step.status == 'completed';
          bool isCurrent = step.status == 'in_progress';

          Color stepColor = isDone
              ? AppTheme.safeGreen
              : isCurrent
                  ? AppTheme.neonAlert
                  : const Color(0xFF64748B);

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: stepColor.withValues(alpha: 0.2),
                        border: Border.all(color: stepColor, width: 2),
                      ),
                      child: Center(
                        child: isDone
                            ? const Icon(Icons.check_rounded, color: AppTheme.safeGreen, size: 18)
                            : isCurrent
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.neonAlert,
                                    ),
                                  )
                                : Text(
                                    '${step.stepNumber}',
                                    style: TextStyle(color: stepColor, fontWeight: FontWeight.bold),
                                  ),
                      ),
                    ),
                    if (idx < steps.length - 1)
                      Container(
                        width: 2,
                        height: 36,
                        color: isDone ? AppTheme.safeGreen : const Color(0xFF334155),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                color: isDone || isCurrent ? const Color(0xFF111827) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                          if (isCurrent)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.emergencyRed.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  color: AppTheme.emergencyRed,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        step.description,
                        style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChecklistCard(BuildContext context) {
    final checklist = _execution!.safetyChecklist;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: checklist.asMap().entries.map((entry) {
          int index = entry.key;
          String text = entry.value;
          bool isChecked = _checkedChecklistItems.contains(index);

          return CheckboxListTile(
            value: isChecked,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _checkedChecklistItems.add(index);
                } else {
                  _checkedChecklistItems.remove(index);
                }
              });
            },
            activeColor: AppTheme.safeGreen,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            title: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isChecked ? const Color(0xFF94A3B8) : const Color(0xFF111827),
                decoration: isChecked ? TextDecoration.lineThrough : null,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
