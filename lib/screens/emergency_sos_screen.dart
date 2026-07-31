import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_view.dart';
import '../widgets/common.dart';

class EmergencySosScreen extends StatefulWidget {
  // Test-only hook: lets widget tests inject a FirestoreService backed by a
  // fake FirebaseFirestore instead of the real one. Never set in app code.
  final FirestoreService? firestoreOverride;
  const EmergencySosScreen({super.key, this.firestoreOverride});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final _firestore = widget.firestoreOverride ?? FirestoreService();
  AppUser? _assignedChw;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _loadAssignedChw();
  }

  Future<void> _loadAssignedChw() async {
    final mother = context.read<SessionProvider>().currentUser;
    final chwId = mother?.assignedChwId;
    if (chwId == null) return;
    final chw = await _firestore.getUserById(chwId);
    if (mounted) setState(() => _assignedChw = chw);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _triggerSos(AppData data) {
    data.startSos();
    data.updateSosStatus('Help request sent to the care team queue.');

    final mother = context.read<SessionProvider>().currentUser;
    if (mother != null) {
      _firestore.createHelpRequest(HelpRequest(
        id: '',
        motherId: mother.uid,
        motherName: mother.name,
        type: RequestType.sos,
        message: 'Emergency SOS triggered from the app.',
        createdAt: DateTime.now(),
      ));
    }
    setState(() {});
  }

  void _cancelSos(AppData data) {
    data.cancelSos();
    setState(() {});
  }

  void _messageChw(AppUser mother) {
    final chw = _assignedChw;
    if (chw == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatView(
          currentUserId: mother.uid,
          currentUserName: mother.name,
          currentUserPhotoUrl: mother.photoUrl,
          otherUserId: chw.uid,
          otherUserName: chw.name,
          otherUserPhotoUrl: chw.photoUrl,
          appBarTitle: 'Chat with ${chw.name}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final l10n = AppLocalizations.of(context)!;
    final mother = context.watch<SessionProvider>().currentUser;

    return Scaffold(
      appBar: MamaAppBar(title: l10n.emergencySosTitle, showBack: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin, vertical: AppSpacing.md),
        children: [
          Center(
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (data.sosActive ? 0.05 * (1 - (_pulseController.value - 0.5).abs() * 2) : 0.0);
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: GestureDetector(
                    onTap: () => data.sosActive ? null : _triggerSos(data),
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.error,
                        boxShadow: [
                          BoxShadow(color: AppColors.error.withValues(alpha: 0.4), blurRadius: 30, spreadRadius: 4),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(data.sosActive ? Icons.local_hospital : Icons.emergency, color: Colors.white, size: 56),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              data.sosActive ? 'Alert sent' : l10n.tapToCallAmbulance,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (data.sosActive)
                  Text(
                    'Your SOS was added to the care team queue. A health worker can claim it and contact you.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (data.sosActive) ...[
            BentoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.liveStatusTitle, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                  const SizedBox(height: 4),
                  Text(data.sosStatusText, style: const TextStyle(fontSize: 13)),
                  if (_assignedChw != null) ...[
                    const SizedBox(height: 8),
                    Text('Assigned CHW: ${_assignedChw!.name}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'No CHW assigned yet — your request is in the open queue for available health workers.',
                      style: TextStyle(fontSize: 13, color: AppColors.secondary),
                    ),
                  ],
                ],
              ),
            ),
            if (mother != null && _assignedChw != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _messageChw(mother),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('Message ${_assignedChw!.name}'),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelSos(data),
                icon: Icon(Icons.close, color: AppColors.error),
                label: Text(l10n.cancelEmergencyAlert, style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          SectionHeader(title: l10n.nearbyFacilitiesTitle),
          const SizedBox(height: 12),
          _facilityTile('Kigali University Teaching Hospital', '1.2 km · 4 min', Icons.local_hospital_outlined),
          const SizedBox(height: 10),
          _facilityTile('King Faisal Hospital', '3.4 km · 9 min', Icons.local_hospital_outlined),
          const SizedBox(height: 10),
          _facilityTile('Kabuga Health Center (CHW)', '0.8 km · 3 min', Icons.medical_services_outlined),
          const SizedBox(height: AppSpacing.md),

          SectionHeader(title: l10n.emergencyContactsTitle),
          const SizedBox(height: 12),
          BentoCard(
            child: mother == null || mother.emergencyContacts.isEmpty
                ? Text(
                    'No emergency contacts saved yet. Add them in Profile.',
                    style: TextStyle(fontSize: 13, color: AppColors.secondary),
                  )
                : Column(
                    children: mother.emergencyContacts
                        .map((c) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.person_outline, color: AppColors.primary),
                              title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(c.phone),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _facilityTile(String name, String distance, IconData icon) {
    return BentoCard(
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(distance, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ),
          Icon(Icons.directions, color: AppColors.outline),
        ],
      ),
    );
  }
}
