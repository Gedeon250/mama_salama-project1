import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Hospital/clinic account shell (PRD role 3). Appointments and Referrals
/// are scoped to this hospital's own uid via the `hospitalId` field on
/// each collection; Patient Records derives its mother list from those two
/// feeds (a hospital only "knows about" mothers routed to it).
class HospitalShell extends StatefulWidget {
  const HospitalShell({super.key});

  @override
  State<HospitalShell> createState() => _HospitalShellState();
}

class _HospitalShellState extends State<HospitalShell> {
  int _index = 0;
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final me = session.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hospital'),
        actions: [IconButton(onPressed: session.signOut, icon: const Icon(Icons.logout))],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                _HospitalAppointmentsTab(firestore: _firestore, hospitalId: me.uid),
                _ReferralsTab(firestore: _firestore, hospitalId: me.uid),
                _PatientRecordsTab(firestore: _firestore, hospitalId: me.uid),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Appointments'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Referrals'),
          NavigationDestination(icon: Icon(Icons.folder_shared_outlined), selectedIcon: Icon(Icons.folder_shared), label: 'Patients'),
        ],
      ),
    );
  }
}

class _HospitalAppointmentsTab extends StatelessWidget {
  final FirestoreService firestore;
  final String hospitalId;
  const _HospitalAppointmentsTab({required this.firestore, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Appointment>>(
      stream: firestore.watchAppointmentsForHospital(hospitalId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final appointments = snapshot.data!;
        if (appointments.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint(text: 'No appointments routed to this hospital yet.'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: appointments
              .map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                            child: Icon(a.isTelemedicine ? Icons.videocam_outlined : Icons.local_hospital_outlined, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text('${a.motherName} · ${intl.DateFormat('MMM d, h:mm a').format(a.dateTime)}',
                                    style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                              ],
                            ),
                          ),
                          PillChip(label: a.status.name),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _ReferralsTab extends StatelessWidget {
  final FirestoreService firestore;
  final String hospitalId;
  const _ReferralsTab({required this.firestore, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Referral>>(
      stream: firestore.watchReferralsForHospital(hospitalId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final referrals = snapshot.data!;
        if (referrals.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint(text: 'No referrals yet — CHWs can send one from their Mothers list.'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: referrals
              .map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.assignment_outlined, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.motherName, style: const TextStyle(fontWeight: FontWeight.w700))),
                              Text(intl.DateFormat('MMM d').format(r.createdAt), style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(r.reason, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 6),
                          Text('Referred by ${r.chwName}', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _PatientRecordsTab extends StatelessWidget {
  final FirestoreService firestore;
  final String hospitalId;
  const _PatientRecordsTab({required this.firestore, required this.hospitalId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Referral>>(
      stream: firestore.watchReferralsForHospital(hospitalId),
      builder: (context, referralSnap) {
        if (!referralSnap.hasData) return const Center(child: CircularProgressIndicator());
        final byMother = <String, String>{};
        for (final r in referralSnap.data!) {
          byMother[r.motherId] = r.motherName;
        }
        if (byMother.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint(text: 'No patients yet — they appear here once a CHW refers them to this hospital.'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: byMother.entries
              .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => _PatientDetailScreen(firestore: firestore, motherId: e.key, motherName: e.value)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: AppColors.secondaryContainer, child: Icon(Icons.pregnant_woman, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w700))),
                          Icon(Icons.chevron_right, color: AppColors.outline),
                        ],
                      ),
                    ),
                  ))
              .toList(),
        );
      },
    );
  }
}

class _PatientDetailScreen extends StatelessWidget {
  final FirestoreService firestore;
  final String motherId;
  final String motherName;
  const _PatientDetailScreen({required this.firestore, required this.motherId, required this.motherName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MamaAppBar(title: motherName, showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
        children: [
          const SectionHeader(title: 'Medical Records'),
          const SizedBox(height: 12),
          StreamBuilder<List<MedicalRecord>>(
            stream: firestore.watchMedicalRecordsForMother(motherId),
            builder: (context, snapshot) {
              final records = snapshot.data ?? [];
              if (records.isEmpty) return const BentoCard(child: EmptyHint(text: 'No visit notes yet.'));
              return Column(
                children: records
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BentoCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(r.summary, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Lab Results'),
          const SizedBox(height: 12),
          StreamBuilder<List<LabResult>>(
            stream: firestore.watchLabResultsForMother(motherId),
            builder: (context, snapshot) {
              final results = snapshot.data ?? [];
              if (results.isEmpty) return const BentoCard(child: EmptyHint(text: 'No lab results yet.'));
              return Column(
                children: results
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BentoCard(
                            child: Row(
                              children: [
                                Expanded(child: Text(r.testName, style: const TextStyle(fontWeight: FontWeight.w700))),
                                Text(r.value, style: TextStyle(color: r.isNormal ? AppColors.onSurface : AppColors.error, fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Vaccinations'),
          const SizedBox(height: 12),
          StreamBuilder<List<VaccineRecord>>(
            stream: firestore.watchVaccinesForMother(motherId),
            builder: (context, snapshot) {
              final vaccines = snapshot.data ?? [];
              if (vaccines.isEmpty) return const BentoCard(child: EmptyHint(text: 'No vaccination records yet.'));
              return Column(
                children: vaccines
                    .map((v) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: BentoCard(
                            child: Row(
                              children: [
                                Icon(v.completed ? Icons.check_circle : Icons.radio_button_unchecked, color: v.completed ? AppColors.primary : AppColors.outline),
                                const SizedBox(width: 8),
                                Expanded(child: Text(v.name)),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
