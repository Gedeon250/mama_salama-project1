import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:fl_chart/fl_chart.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/chat_alert_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/chat_view.dart';
import '../../widgets/user_avatar.dart';
import '../messages_inbox_screen.dart';
import '../video_lesson_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _firestore = FirestoreService();
  ChatAlertService? _chatAlerts;

  @override
  void initState() {
    super.initState();
    final me = context.read<SessionProvider>().currentUser!;
    _chatAlerts = ChatAlertService(firestore: _firestore, myUid: me.uid)..start();
  }

  @override
  void dispose() {
    _chatAlerts?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MessagesInboxScreen()),
            ),
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Messages',
          ),
          IconButton(onPressed: session.signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: [
                _DashboardTab(firestore: _firestore),
                _HealthWorkersTab(firestore: _firestore, admin: session.currentUser!),
                _MothersTab(firestore: _firestore),
                _LearnTab(firestore: _firestore),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Health Workers'),
          NavigationDestination(icon: Icon(Icons.pregnant_woman_outlined), selectedIcon: Icon(Icons.pregnant_woman), label: 'Mothers'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), selectedIcon: Icon(Icons.menu_book), label: 'Learn'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  final FirestoreService firestore;
  const _DashboardTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HelpRequest>>(
      stream: firestore.watchAllRequests(),
      builder: (context, requestSnap) {
        if (requestSnap.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load requests: ${requestSnap.error}')));
        }
        if (!requestSnap.hasData) return const Center(child: CircularProgressIndicator());
        final requests = requestSnap.data!;
        final pending = requests.where((r) => r.status == RequestStatus.pending).length;
        final assigned = requests.where((r) => r.status == RequestStatus.assigned).length;
        final resolved = requests.where((r) => r.status == RequestStatus.resolved).length;
        final sosActive = requests.where((r) => r.type == RequestType.sos && r.status != RequestStatus.resolved).length;

        return StreamBuilder<List<AppUser>>(
          stream: firestore.watchUsersByRole(UserRole.chw),
          builder: (context, chwSnap) {
            final chws = chwSnap.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
              children: [
                Row(
                  children: [
                    _StatCard(label: 'Pending', value: '$pending', color: AppColors.error),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Assigned', value: '$assigned', color: AppColors.tertiary),
                    const SizedBox(width: 10),
                    _StatCard(label: 'Resolved', value: '$resolved', color: AppColors.primary),
                  ],
                ),
                if (sosActive > 0) ...[
                  const SizedBox(height: 12),
                  BentoCard(
                    color: AppColors.errorContainer,
                    child: Row(
                      children: [
                        Icon(Icons.emergency, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('$sosActive active SOS alert${sosActive == 1 ? '' : 's'} need attention',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _AnalyticsSection(firestore: firestore, requests: requests),
                const SectionHeader(title: 'Live Requests Feed'),
                const SizedBox(height: 12),
                if (requests.isEmpty)
                  const BentoCard(child: EmptyHint(text: 'No requests yet — this fills up as mothers use SOS or Request Help.'))
                else
                  ...requests.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _AdminRequestCard(request: r, chws: chws, firestore: firestore),
                      )),
              ],
            );
          },
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: BentoCard(
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsSection extends StatelessWidget {
  final FirestoreService firestore;
  final List<HelpRequest> requests;
  const _AnalyticsSection({required this.firestore, required this.requests});

  String _formatDuration(Duration d) {
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSos = requests
        .where((r) => r.type == RequestType.sos && r.status == RequestStatus.resolved && r.resolvedAt != null)
        .toList();
    Duration? avgResponse;
    if (resolvedSos.isNotEmpty) {
      final totalSeconds = resolvedSos.fold<int>(0, (sum, r) => sum + r.resolvedAt!.difference(r.createdAt).inSeconds);
      avgResponse = Duration(seconds: totalSeconds ~/ resolvedSos.length);
    }

    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchUsersByRole(UserRole.mother),
      builder: (context, motherSnap) {
        final totalMothers = motherSnap.data?.length ?? 0;
        return StreamBuilder<int>(
          stream: firestore.watchHighRiskMotherCount(),
          builder: (context, riskSnap) {
            final highRisk = riskSnap.data ?? 0;
            return StreamBuilder<List<Appointment>>(
              stream: firestore.watchAllAppointments(),
              builder: (context, apptSnap) {
                final appts = apptSnap.data ?? [];
                final completed = appts.where((a) => a.status == AppointmentStatus.completed).length;
                final finished = appts.where((a) => a.status != AppointmentStatus.upcoming).length;
                final completionRate = finished == 0 ? null : completed / finished;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(title: 'Analytics'),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _StatCard(label: 'Pregnancies', value: '$totalMothers', color: AppColors.primary),
                          const SizedBox(width: 10),
                          _StatCard(label: 'High-Risk', value: '$highRisk', color: AppColors.error),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StatCard(
                            label: 'Appt. Completion',
                            value: completionRate == null ? '—' : '${(completionRate * 100).round()}%',
                            color: AppColors.tertiary,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'Avg SOS Response',
                            value: avgResponse == null ? '—' : _formatDuration(avgResponse),
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Requests by Status', style: TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),
                            SizedBox(height: 140, child: _RequestStatusChart(requests: requests)),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _RequestStatusChart extends StatelessWidget {
  final List<HelpRequest> requests;
  const _RequestStatusChart({required this.requests});

  @override
  Widget build(BuildContext context) {
    final pending = requests.where((r) => r.status == RequestStatus.pending).length.toDouble();
    final assigned = requests.where((r) => r.status == RequestStatus.assigned).length.toDouble();
    final resolved = requests.where((r) => r.status == RequestStatus.resolved).length.toDouble();
    final maxY = [pending, assigned, resolved, 1.0].reduce((a, b) => a > b ? a : b);
    const labels = ['Pending', 'Assigned', 'Resolved'];

    return BarChart(
      BarChartData(
        maxY: maxY + 1,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(labels[i], style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                );
              },
            ),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: pending, color: AppColors.error, width: 28, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: assigned, color: AppColors.tertiary, width: 28, borderRadius: BorderRadius.circular(4))]),
          BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: resolved, color: AppColors.primary, width: 28, borderRadius: BorderRadius.circular(4))]),
        ],
      ),
    );
  }
}

class _AdminRequestCard extends StatelessWidget {
  final HelpRequest request;
  final List<AppUser> chws;
  final FirestoreService firestore;

  const _AdminRequestCard({required this.request, required this.chws, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final isSos = request.type == RequestType.sos;
    return BentoCard(
      color: isSos && request.status != RequestStatus.resolved ? AppColors.errorContainer : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isSos ? Icons.emergency : Icons.help_outline, color: isSos ? AppColors.error : AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text(request.motherName, style: const TextStyle(fontWeight: FontWeight.w700))),
              Text(intl.DateFormat('MMM d, h:mm a').format(request.createdAt), style: TextStyle(fontSize: 11, color: AppColors.secondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(request.message, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              PillChip(label: request.status.name),
              const SizedBox(width: 8),
              if (request.assignedChwName != null)
                Expanded(
                  child: Text('→ ${request.assignedChwName}', style: TextStyle(fontSize: 12, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
                )
              else
                const Spacer(),
            ],
          ),
          if (request.status != RequestStatus.resolved) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: request.assignedChwId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Assign Health Worker', isDense: true),
                    items: chws
                        .map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name, overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (chwId) {
                      if (chwId == null) return;
                      final chw = chws.firstWhere((c) => c.uid == chwId);
                      firestore.assignRequest(
                        requestId: request.id,
                        motherId: request.motherId,
                        chwId: chw.uid,
                        chwName: chw.name,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => firestore.resolveRequest(request.id), child: const Text('Resolve')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HealthWorkersTab extends StatelessWidget {
  final FirestoreService firestore;
  final AppUser admin;
  const _HealthWorkersTab({required this.firestore, required this.admin});

  Future<void> _promptNote({
    required BuildContext context,
    required String title,
    required String confirmLabel,
    required Future<void> Function(String note) onConfirm,
  }) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Note to applicant'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (note == null) return;
    try {
      await onConfirm(note);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$confirmLabel done.')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  Future<void> _approve(BuildContext context, AppUser applicant) async {
    try {
      await firestore.approveChwApplication(applicant.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${applicant.name} is now a Health Worker.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchChwApplications(),
      builder: (context, appSnap) {
        return StreamBuilder<List<AppUser>>(
          stream: firestore.watchUsersByRole(UserRole.chw),
          builder: (context, chwSnap) {
            if (appSnap.hasError || chwSnap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: EmptyHint(
                    icon: Icons.error_outline,
                    text: 'Could not load health workers: ${appSnap.error ?? chwSnap.error}',
                  ),
                ),
              );
            }
            if (!chwSnap.hasData) return const Center(child: CircularProgressIndicator());

            final applicants = (appSnap.data ?? [])
                .where((u) => u.chwApplication != null && u.chwApplication!.status != ChwApplicationStatus.rejected)
                .toList()
              ..sort((a, b) {
                final aAt = a.chwApplication?.submittedAt ?? DateTime(0);
                final bAt = b.chwApplication?.submittedAt ?? DateTime(0);
                return bAt.compareTo(aAt);
              });
            final awaitingForm = (appSnap.data ?? []).where((u) => u.chwApplication == null).toList();
            final chws = chwSnap.data!;

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
              children: [
                SectionHeader(
                  title: 'Applications',
                  subtitle: applicants.isEmpty && awaitingForm.isEmpty
                      ? 'No pending applications'
                      : '${applicants.length} to review${awaitingForm.isEmpty ? '' : ', ${awaitingForm.length} still filling the form'}',
                ),
                const SizedBox(height: 12),
                if (applicants.isEmpty && awaitingForm.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: EmptyHint(text: 'New Health Worker sign-ups will show up here for approval.'),
                  ),
                ...applicants.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ApplicationCard(
                        applicant: a,
                        onApprove: () => _approve(context, a),
                        onNeedsInfo: () => _promptNote(
                          context: context,
                          title: 'Request more information',
                          confirmLabel: 'Send',
                          onConfirm: (note) => firestore.requestMoreChwInfo(a.uid, note),
                        ),
                        onReject: () => _promptNote(
                          context: context,
                          title: 'Reject application',
                          confirmLabel: 'Reject',
                          onConfirm: (note) => firestore.rejectChwApplication(a.uid, note.isEmpty ? null : note),
                        ),
                      ),
                    )),
                ...awaitingForm.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        child: Row(
                          children: [
                            UserAvatar(
                              photoUrl: a.photoUrl,
                              backgroundColor: AppColors.secondaryContainer,
                              icon: Icons.hourglass_empty,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(a.email, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                                  Text('Has not submitted an application yet', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                const SizedBox(height: 16),
                SectionHeader(title: 'Active Health Workers', subtitle: '${chws.length} approved'),
                const SizedBox(height: 12),
                if (chws.isEmpty)
                  const EmptyHint(text: 'No approved health workers yet.')
                else
                  ...chws.map((c) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: BentoCard(
                          child: Row(
                            children: [
                              UserAvatar(
                                photoUrl: c.photoUrl,
                                backgroundColor: AppColors.onTertiaryContainer,
                                icon: Icons.volunteer_activism,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text(c.phone ?? c.email, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                                  ],
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatView(
                                      currentUserId: admin.uid,
                                      currentUserName: admin.name,
                                      currentUserPhotoUrl: admin.photoUrl,
                                      otherUserId: c.uid,
                                      otherUserName: c.name,
                                      otherUserPhotoUrl: c.photoUrl,
                                      appBarTitle: 'Chat with ${c.name}',
                                    ),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_bubble_outline, size: 16),
                                label: const Text('Message'),
                              ),
                            ],
                          ),
                        ),
                      )),
              ],
            );
          },
        );
      },
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  final AppUser applicant;
  final VoidCallback onApprove;
  final VoidCallback onNeedsInfo;
  final VoidCallback onReject;

  const _ApplicationCard({
    required this.applicant,
    required this.onApprove,
    required this.onNeedsInfo,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final app = applicant.chwApplication!;
    final needsInfo = app.status == ChwApplicationStatus.needsMoreInfo;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              UserAvatar(
                photoUrl: applicant.photoUrl,
                backgroundColor: AppColors.onTertiaryContainer,
                icon: Icons.volunteer_activism,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(applicant.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text(applicant.email, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: needsInfo ? AppColors.tertiaryContainer : AppColors.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  needsInfo ? 'Needs info' : 'Pending',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Expertise: ${app.fieldOfExpertise}', style: const TextStyle(fontSize: 13)),
          Text('Experience: ${app.yearsOfExperience} years', style: const TextStyle(fontSize: 13)),
          if (app.currentEmployment != null && app.currentEmployment!.isNotEmpty)
            Text('Employment: ${app.currentEmployment}', style: const TextStyle(fontSize: 13)),
          if (app.adminNote != null && app.adminNote!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Note: ${app.adminNote}', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openUrl(context, app.cvUrl),
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text('CV'),
              ),
              OutlinedButton.icon(
                onPressed: () => _openUrl(context, app.proofOfExpertiseUrl),
                icon: const Icon(Icons.verified_outlined, size: 16),
                label: const Text('Proof'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onNeedsInfo,
                  child: const Text('More info'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid document link.')));
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open document.')));
    }
  }
}

class _MothersTab extends StatelessWidget {
  final FirestoreService firestore;
  const _MothersTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchUsersByRole(UserRole.mother),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load mothers: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final mothers = snapshot.data!;
        if (mothers.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: EmptyHint(text: 'No mothers registered yet.')));
        }
        return StreamBuilder<List<AppUser>>(
          stream: firestore.watchUsersByRole(UserRole.chw),
          builder: (context, chwSnap) {
            final chws = chwSnap.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
              children: mothers
                  .map((m) {
                    final assigned = chws.where((c) => c.uid == m.assignedChwId).toList();
                    final chwName = assigned.isEmpty ? null : assigned.first.name;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                UserAvatar(photoUrl: m.photoUrl, backgroundColor: AppColors.secondaryContainer, icon: Icons.pregnant_woman),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(m.phone ?? m.email, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                                      if (chwName != null)
                                        Text('CHW: $chwName', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                Text(
                                  m.assignedChwId == null ? 'Unassigned' : 'Assigned',
                                  style: TextStyle(fontSize: 11, color: m.assignedChwId == null ? AppColors.error : AppColors.primary, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                            if (chws.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              DropdownButtonFormField<String?>(
                                value: chws.any((c) => c.uid == m.assignedChwId) ? m.assignedChwId : null,
                                isExpanded: true,
                                decoration: const InputDecoration(labelText: 'Assign Health Worker', isDense: true),
                                items: [
                                  const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                                  ...chws.map((c) => DropdownMenuItem<String?>(value: c.uid, child: Text(c.name, overflow: TextOverflow.ellipsis))),
                                ],
                                onChanged: (chwId) {
                                  if (chwId == null) {
                                    firestore.unassignChwFromMother(m.uid);
                                  } else {
                                    firestore.assignChwToMother(motherId: m.uid, chwId: chwId);
                                  }
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  })
                  .toList(),
            );
          },
        );
      },
    );
  }
}

class _LearnTab extends StatelessWidget {
  final FirestoreService firestore;
  const _LearnTab({required this.firestore});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLessonSheet(context, firestore),
        icon: const Icon(Icons.add),
        label: const Text('Add Lesson'),
      ),
      body: StreamBuilder<List<EducationContent>>(
        stream: firestore.watchEducationContent(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) {
            return const Center(child: Padding(padding: EdgeInsets.all(24), child: EmptyHint(text: 'No lessons yet — tap "Add Lesson" to create one.')));
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoLessonScreen(item: item))),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: Icon(
                                item.format == EducationFormat.video
                                    ? Icons.play_circle_outline
                                    : item.format == EducationFormat.audio
                                        ? Icons.headphones_outlined
                                        : Icons.article_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text(item.description, style: TextStyle(fontSize: 12, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      PillChip(label: item.category),
                                      const SizedBox(width: 6),
                                      Text(item.durationOrLength, style: TextStyle(fontSize: 11, color: AppColors.outline)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  void _showAddLessonSheet(BuildContext context, FirestoreService firestore) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => _AddLessonSheet(firestore: firestore),
    );
  }
}

class _AddLessonSheet extends StatefulWidget {
  final FirestoreService firestore;
  const _AddLessonSheet({required this.firestore});

  @override
  State<_AddLessonSheet> createState() => _AddLessonSheetState();
}

class _AddLessonSheetState extends State<_AddLessonSheet> {
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mediaUrlController = TextEditingController();
  EducationFormat _format = EducationFormat.article;

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    _mediaUrlController.dispose();
    super.dispose();
  }

  // Don't await the write future — it only resolves after a server
  // round-trip, which would leave this stuck on "Saving..." forever while
  // offline. The write queues locally and syncs once reconnected.
  void _save() {
    widget.firestore.addEducationContent(EducationContent(
      id: '',
      title: _titleController.text.trim(),
      category: _categoryController.text.trim(),
      format: _format,
      durationOrLength: _durationController.text.trim(),
      description: _descriptionController.text.trim(),
      mediaUrl: _mediaUrlController.text.trim().isEmpty ? null : _mediaUrlController.text.trim(),
    ));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.edgeMargin,
        right: AppSpacing.edgeMargin,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Lesson', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category (e.g. Nutrition, Danger Signs)')),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: EducationFormat.values
                  .map((f) => PillChip(label: f.name, selected: _format == f, onTap: () => setState(() => _format = f)))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: _durationController, decoration: const InputDecoration(labelText: 'Duration (e.g. 6 min, 4 min read)')),
            const SizedBox(height: 12),
            TextField(controller: _descriptionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 12),
            TextField(controller: _mediaUrlController, decoration: const InputDecoration(labelText: 'Media URL (optional)')),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Lesson'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
