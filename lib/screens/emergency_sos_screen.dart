import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
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
  Timer? _statusTimer;
  double _dispatchProgress = 0;

  List<String> _steps(AppLocalizations l10n) => [
        l10n.sosStep1,
        l10n.sosStep2,
        l10n.sosStep3,
        l10n.sosStep4,
      ];
  int _stepIndex = 0;
  late final _firestore = widget.firestoreOverride ?? FirestoreService();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _triggerSos(AppData data, AppLocalizations l10n) {
    final steps = _steps(l10n);
    data.startSos();
    _stepIndex = 0;
    _dispatchProgress = 0.15;
    data.updateSosStatus(steps[_stepIndex]);

    // Real backend hook: this is what the Admin dashboard's "Live Requests
    // Feed" and active-SOS counter are watching in real time.
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

    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (_stepIndex < steps.length - 1) {
        _stepIndex++;
        _dispatchProgress = (_stepIndex + 1) / steps.length;
        data.updateSosStatus(steps[_stepIndex]);
        setState(() {});
      } else {
        t.cancel();
      }
    });
    setState(() {});
  }

  void _cancelSos(AppData data) {
    _statusTimer?.cancel();
    data.cancelSos();
    setState(() => _dispatchProgress = 0);
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final l10n = AppLocalizations.of(context)!;

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
                    onTap: () => data.sosActive ? null : _triggerSos(data, l10n),
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
                              data.sosActive ? l10n.dispatchInProgress : l10n.tapToCallAmbulance,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_protected_setup, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(l10n.connectingToDispatch, style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (data.sosActive) ...[
            BentoCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                    child: Icon(Icons.location_on_outlined, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.liveStatusTitle, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                        const SizedBox(height: 4),
                        Text(data.sosStatusText, style: const TextStyle(fontSize: 13)),
                        const SizedBox(height: 8),
                        ProgressTrack(value: _dispatchProgress),
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
            child: Text(
              l10n.emergencyContactsNotice('${data.profile.emergencyContactsCount}'),
              style: TextStyle(fontSize: 13, color: AppColors.secondary),
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
