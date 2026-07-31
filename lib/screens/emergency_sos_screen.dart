import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/launchers.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_view.dart';
import '../widgets/common.dart';
import 'sos_status.dart';

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
  final _location = const LocationService();

  // Id of the request this SOS created, so we can follow it in the live
  // stream. Held in state (not just Firestore) so tracking survives offline.
  String? _activeRequestId;
  // True only in the brief window between tapping SOS and the request landing
  // in the stream (while we grab a GPS fix).
  bool _locating = false;
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

  Future<void> _triggerSos(AppData data) async {
    data.startSos();
    setState(() => _locating = true);
    data.updateSosStatus('Help request sent to the care team queue.');

    final mother = context.read<SessionProvider>().currentUser;
    if (mother == null) {
      // No signed-in mother (e.g. in tests) — nothing to persist to Firestore.
      setState(() => _locating = false);
      return;
    }

    // Best-effort GPS — never blocks the alert (returns null if unavailable).
    final fix = await _location.tryGetFix();
    if (!mounted) return;

    final id = _firestore.createHelpRequest(HelpRequest(
      id: '',
      motherId: mother.uid,
      motherName: mother.name,
      type: RequestType.sos,
      message: 'Emergency SOS triggered from the app.',
      createdAt: DateTime.now(),
      lat: fix?.lat,
      lng: fix?.lng,
      accuracy: fix?.accuracy,
    ));

    setState(() {
      _activeRequestId = id;
      _locating = false;
    });
  }

  Future<void> _cancelSos(AppData data) async {
    final id = _activeRequestId;
    data.cancelSos();
    setState(() {
      _activeRequestId = null;
      _locating = false;
    });
    if (id != null) await _firestore.resolveRequest(id);
  }

  void _dismiss(AppData data) {
    data.cancelSos();
    setState(() {
      _activeRequestId = null;
      _locating = false;
    });
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
    final mother = context.watch<SessionProvider>().currentUser;
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_protected_setup, size: 16, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(l10n.connectingToDispatch, style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (data.sosActive) ...[
            StreamBuilder<List<HelpRequest>>(
              stream: mother != null ? _firestore.watchRequestsForMother(mother.uid) : const Stream<List<HelpRequest>>.empty(),
              builder: (context, snapshot) {
                final active = _findActive(snapshot.data);
                return _LiveStatus(
                  view: sosViewFor(active, locating: _locating),
                  request: active,
                  onCancel: () => _cancelSos(data),
                  onDismiss: () => _dismiss(data),
                );
              },
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
              l10n.emergencyContactsNotice(data.profile.emergencyContactsCount),
              style: const TextStyle(fontSize: 13, color: AppColors.secondary),
            ),
          ),
        ],
      ),
    );
  }

  HelpRequest? _findActive(List<HelpRequest>? list) {
    if (list == null || _activeRequestId == null) return null;
    for (final r in list) {
      if (r.id == _activeRequestId) return r;
    }
    return null;
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
                Text(distance, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ),
          const Icon(Icons.directions, color: AppColors.outline),
        ],
      ),
    );
  }
}

/// The live-status section under the SOS button: real status text + progress,
/// the location-shared indicator, and (when available) tap-to-call buttons for
/// the responding CHW and the arranged transport driver.
class _LiveStatus extends StatelessWidget {
  const _LiveStatus({
    required this.view,
    required this.request,
    required this.onCancel,
    required this.onDismiss,
  });

  final SosView view;
  final HelpRequest? request;
  final VoidCallback onCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final resolved = request?.status == RequestStatus.resolved;
    final chwPhone = request?.assignedChwPhone;
    final chwName = request?.assignedChwName ?? 'Health worker';
    final hasLocation = request?.hasLocation ?? false;

    return Column(
      children: [
        BentoCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                child: const Icon(Icons.location_on_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Live Status', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    const SizedBox(height: 4),
                    Text(view.label, style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 8),
                    ProgressTrack(value: view.progress),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          hasLocation ? Icons.check_circle : Icons.location_off_outlined,
                          size: 14,
                          color: hasLocation ? AppColors.primary : AppColors.secondary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            hasLocation
                                ? 'Your location was shared with the health worker.'
                                : 'Location unavailable — describe where you are when they call.',
                            style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Responding CHW — tap to call.
        if (chwPhone != null) ...[
          const SizedBox(height: 12),
          BentoCard(
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.onTertiaryContainer, child: Icon(Icons.medical_services_outlined, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chwName, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Text('Responding health worker', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () => callNumber(chwPhone),
                  icon: const Icon(Icons.call),
                  tooltip: 'Call $chwName',
                ),
              ],
            ),
          ),
        ],

        // Arranged transport — tap to call the driver.
        if (request?.transportStatus == TransportStatus.arranged && request?.driverPhone != null) ...[
          const SizedBox(height: 12),
          BentoCard(
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.onTertiaryContainer, child: Icon(Icons.local_taxi_outlined, color: AppColors.primary)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(request?.driverName ?? 'Driver', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const Text('Transport arranged · call to confirm', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                    ],
                  ),
                ),
                IconButton.filled(
                  onPressed: () => callNumber(request!.driverPhone!),
                  icon: const Icon(Icons.call),
                  tooltip: 'Call driver',
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: resolved
              ? FilledButton.icon(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.check),
                  label: const Text('Done'),
                )
              : OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close, color: AppColors.error),
                  label: const Text('Cancel Emergency Alert', style: TextStyle(color: AppColors.error)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                ),
        ),
      ],
    );
  }
}
