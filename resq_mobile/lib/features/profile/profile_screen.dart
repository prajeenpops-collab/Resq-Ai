import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/auth_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  bool _autoBroadcastContacts = true;
  bool _silentThreatMode = false;

  final List<Map<String, String>> _emergencyContacts = [
    {'name': 'Sarah Jenkins (Spouse)', 'phone': '+1 (555) 234-5678', 'relation': 'Primary Contact'},
    {'name': 'Dr. Robert Chen (Physician)', 'phone': '+1 (555) 876-5432', 'relation': 'Doctor'},
  ];

  void _addContactDialog() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name & Relation')),
            const SizedBox(height: 10),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isNotEmpty && phoneCtrl.text.isNotEmpty) {
                setState(() {
                  _emergencyContacts.add({
                    'name': nameCtrl.text.trim(),
                    'phone': phoneCtrl.text.trim(),
                    'relation': 'Emergency Contact',
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('CITIZEN MEDICAL ID & PROFILE')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [AppTheme.neonAlert, AppTheme.emergencyRed]),
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email?.split('@').first.toUpperCase() ?? 'CITIZEN USER',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'user@resq.ai',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Medical ID Card
            Text(
              'EMERGENCY MEDICAL ID BADGE',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppTheme.cyberCyan,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.criticalRed.withValues(alpha: 0.15), AppTheme.darkCard],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.criticalRed.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.badge_rounded, color: AppTheme.neonAlert, size: 22),
                      SizedBox(width: 10),
                      Text('FIRST RESPONDER VITAL INFO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                    ],
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMedicalBadge('BLOOD TYPE', 'O- Positive', AppTheme.neonAlert),
                      _buildMedicalBadge('ALLERGIES', 'Penicillin, Latex', AppTheme.warningAmber),
                      _buildMedicalBadge('ORGAN DONOR', 'YES', AppTheme.safeGreen),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Emergency Contacts Broadcast Manager
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AUTOMATED BROADCAST CONTACTS',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: const Color(0xFF94A3B8),
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline_rounded, color: AppTheme.neonAlert),
                  onPressed: _addContactDialog,
                  tooltip: 'Add Contact',
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._emergencyContacts.map((c) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF334155)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.contact_phone_rounded, color: AppTheme.safeGreen, size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                            Text('${c['phone']} • ${c['relation']}', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.notifications_active_rounded, color: AppTheme.safeGreen, size: 18),
                    ],
                  ),
                )),
            const SizedBox(height: 20),

            // Automation Toggles
            Text(
              'AUTOMATED RESPONSE PREFERENCES',
              style: theme.textTheme.labelMedium?.copyWith(
                color: const Color(0xFF94A3B8),
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.darkCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _autoBroadcastContacts,
                    onChanged: (val) => setState(() => _autoBroadcastContacts = val),
                    activeColor: AppTheme.safeGreen,
                    title: const Text('Auto-Broadcast SMS to Contacts', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Automatically alert emergency contacts on SOS trigger.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ),
                  const Divider(color: Color(0xFF334155), height: 1),
                  SwitchListTile(
                    value: _silentThreatMode,
                    onChanged: (val) => setState(() => _silentThreatMode = val),
                    activeColor: AppTheme.neonAlert,
                    title: const Text('Silent Active Threat Mode', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Mute device speaker & vibrations during security threats.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppTheme.criticalRed),
                label: const Text('SIGN OUT OF RESQ AI', style: TextStyle(color: AppTheme.criticalRed)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalBadge(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}
