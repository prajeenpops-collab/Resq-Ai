import 'package:flutter/material.dart';
import '../../core/theme.dart';

class AgencyDashboardsScreen extends StatefulWidget {
  final String initialAgency; // 'fire', 'hospital', 'ambulance', 'police'

  const AgencyDashboardsScreen({
    super.key,
    this.initialAgency = 'fire',
  });

  @override
  State<AgencyDashboardsScreen> createState() => _AgencyDashboardsScreenState();
}

class _AgencyDashboardsScreenState extends State<AgencyDashboardsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _mockComplaints = [
    {
      'id': 'CMP-FIRE-8021',
      'title': 'Structural Electrical Fire on 4th Floor',
      'category': 'fire',
      'severity': 'critical',
      'agency': 'Fire Department #4',
      'time': '3 mins ago',
      'rootCause': 'Electrical Circuit Malfunction & High Thermal Ignition',
      'summary': 'Heavy smoke rising from commercial complex. Occupants trapped near stairwell.',
      'dispatchedUnits': 'Engine #4 & Ladder #2 (Water pressure boosted)',
      'recipients': ['Fire Dept (Suppression)', 'Hospital ER (Burn Unit)'],
      'acknowledged': false,
    },
    {
      'id': 'CMP-MED-8022',
      'title': 'Cardiac Arrest at Central Transit Station',
      'category': 'medical',
      'severity': 'critical',
      'agency': 'Hospital ER & ALS Ambulance',
      'time': '6 mins ago',
      'rootCause': 'Sudden Acute Cardiac Event',
      'summary': 'Unresponsive citizen collapsed. CPR metronome guide streaming to bystander phone.',
      'dispatchedUnits': 'ALS Mobile ICU Ambulance #9 (O2 Trauma Bay 2 reserved)',
      'recipients': ['Hospital ER Bay 2', 'ALS Ambulance Squad'],
      'acknowledged': true,
    },
    {
      'id': 'CMP-CRASH-8023',
      'title': 'Multi-Vehicle Highway Collision',
      'category': 'accident',
      'severity': 'high',
      'agency': 'Ambulance & Fire Extrication',
      'time': '14 mins ago',
      'rootCause': 'High-Speed Kinetic Collision on Wet Asphalt',
      'summary': 'Two sedans collided near Exit 14. Driver trapped inside vehicle frame.',
      'dispatchedUnits': 'Hydraulic Extrication Team 3 & Paramedic Ambulance',
      'recipients': ['Fire Extrication', 'Paramedics', 'Traffic Police'],
      'acknowledged': false,
    },
    {
      'id': 'CMP-POL-8024',
      'title': 'Active Threat & Commercial Security Alarm',
      'category': 'crime',
      'severity': 'critical',
      'agency': 'Police Tactical SWAT',
      'time': '20 mins ago',
      'rootCause': 'Unlawful Security Breach',
      'summary': 'Silent priority alarm triggered. SWAT cruisers locked onto perimeter detours.',
      'dispatchedUnits': 'Police Tactical Cruisers 102 & 104',
      'recipients': ['Police SWAT', 'Trauma Paramedics'],
      'acknowledged': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    int initIdx = 0;
    if (widget.initialAgency == 'hospital') initIdx = 1;
    if (widget.initialAgency == 'ambulance') initIdx = 2;
    if (widget.initialAgency == 'police') initIdx = 3;
    _tabController = TabController(length: 4, vsync: this, initialIndex: initIdx);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredComplaints(int index) {
    switch (index) {
      case 0: // Fire
        return _mockComplaints.where((c) => c['category'] == 'fire' || c['category'] == 'other').toList();
      case 1: // Hospital ER
        return _mockComplaints.where((c) => c['category'] == 'medical' || c['category'] == 'fire').toList();
      case 2: // Ambulance
        return _mockComplaints.where((c) => c['category'] == 'medical' || c['category'] == 'accident').toList();
      case 3: // Police
        return _mockComplaints.where((c) => c['category'] == 'crime' || c['category'] == 'accident').toList();
      default:
        return _mockComplaints;
    }
  }

  void _acknowledgeComplaint(Map<String, dynamic> cmp) {
    setState(() {
      cmp['acknowledged'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${cmp['id']} Complaint Accepted & Dispatched by Agency!'),
        backgroundColor: AppTheme.safeGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DEPARTMENT TERMINALS'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.local_fire_department_rounded), text: 'FIRE DEPT'),
            Tab(icon: Icon(Icons.local_hospital_rounded), text: 'HOSPITAL ER'),
            Tab(icon: Icon(Icons.medical_services_rounded), text: 'AMBULANCE'),
            Tab(icon: Icon(Icons.security_rounded), text: 'POLICE STATION'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAgencyTerminalView(0, 'FIRE SERVICE COMPLAINTS', Icons.local_fire_department_rounded, AppTheme.emergencyRed),
          _buildAgencyTerminalView(1, 'HOSPITAL ER & TRAUMA BAYS', Icons.local_hospital_rounded, Colors.redAccent),
          _buildAgencyTerminalView(2, 'AMBULANCE DISPATCH FLEET', Icons.medical_services_rounded, AppTheme.warningAmber),
          _buildAgencyTerminalView(3, 'POLICE STATION TACTICAL FEED', Icons.security_rounded, AppTheme.cyberCyan),
        ],
      ),
    );
  }

  Widget _buildAgencyTerminalView(int index, String title, IconData icon, Color color) {
    final complaints = _getFilteredComplaints(index);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Terminal Banner Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Receiving live incident complaints & AI triage alerts (${complaints.length} active)',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Complaints List
          ...complaints.map((cmp) => _buildComplaintCard(cmp, color)),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> cmp, Color color) {
    final isAck = cmp['acknowledged'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isAck ? AppTheme.safeGreen : color.withValues(alpha: 0.5), width: 1.5),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Complaint ID & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.severityColor(cmp['severity']).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.severityColor(cmp['severity'])),
                  ),
                  child: Text(
                    '${cmp['severity'].toString().toUpperCase()} • ${cmp['category'].toString().toUpperCase()}',
                    style: TextStyle(
                      color: AppTheme.severityColor(cmp['severity']),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  cmp['time'].toString(),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              cmp['title'].toString(),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 6),

            // Root Cause & Summary
            Text(
              'Root Cause: ${cmp['rootCause']}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color),
            ),
            const SizedBox(height: 4),
            Text(
              cmp['summary'].toString(),
              style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.3),
            ),
            const SizedBox(height: 12),

            // Dispatched Units Tag
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: Color(0xFF64748B), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Dispatched: ${cmp['dispatchedUnits']}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isAck ? null : () => _acknowledgeComplaint(cmp),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isAck ? AppTheme.safeGreen : color,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                icon: Icon(isAck ? Icons.check_circle_rounded : Icons.mark_email_read_rounded, size: 18),
                label: Text(
                  isAck ? 'ACKNOWLEDGED & UNITS DISPATCHED ✓' : 'ACCEPT & ACKNOWLEDGE COMPLAINT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
