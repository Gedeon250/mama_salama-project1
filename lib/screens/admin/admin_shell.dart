import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/chat_view.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [IconButton(onPressed: session.signOut, icon: const Icon(Icons.logout))],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _DashboardTab(firestore: _firestore),
          _HealthWorkersTab(firestore: _firestore, admin: session.currentUser!),
          _MothersTab(firestore: _firestore),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.volunteer_activism_outlined), selectedIcon: Icon(Icons.volunteer_activism), label: 'Health Workers'),
          NavigationDestination(icon: Icon(Icons.pregnant_woman_outlined), selectedIcon: Icon(Icons.pregnant_woman), label: 'Mothers'),
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
                        const Icon(Icons.emergency, color: AppColors.error),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text('$sosActive active SOS alert${sosActive == 1 ? '' : 's'} need attention',
                              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.onErrorContainer)),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
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
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
          ],
        ),
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
              Text(intl.DateFormat('MMM d, h:mm a').format(request.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
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
                  child: Text('→ ${request.assignedChwName}', style: const TextStyle(fontSize: 12, color: AppColors.secondary), overflow: TextOverflow.ellipsis),
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
                      firestore.assignRequest(requestId: request.id, chwId: chw.uid, chwName: chw.name);
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchUsersByRole(UserRole.chw),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load health workers: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final chws = snapshot.data!;
        if (chws.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: EmptyHint(text: 'No health workers registered yet.')));
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: chws
              .map((c) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      child: Row(
                        children: [
                          const CircleAvatar(backgroundColor: AppColors.onTertiaryContainer, child: Icon(Icons.volunteer_activism, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(c.phone ?? c.email, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChatView(
                                  currentUserId: admin.uid,
                                  currentUserName: admin.name,
                                  otherUserId: c.uid,
                                  otherUserName: c.name,
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
                  ))
              .toList(),
        );
      },
    );
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
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: mothers
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      child: Row(
                        children: [
                          const CircleAvatar(backgroundColor: AppColors.secondaryContainer, child: Icon(Icons.pregnant_woman, color: AppColors.primary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(m.phone ?? m.email, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                              ],
                            ),
                          ),
                          Text(
                            m.assignedChwId == null ? 'Unassigned' : 'Assigned',
                            style: TextStyle(fontSize: 11, color: m.assignedChwId == null ? AppColors.error : AppColors.primary, fontWeight: FontWeight.w700),
                          ),
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
