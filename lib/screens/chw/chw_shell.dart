import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/chat_view.dart';

class ChwShell extends StatefulWidget {
  const ChwShell({super.key});

  @override
  State<ChwShell> createState() => _ChwShellState();
}

class _ChwShellState extends State<ChwShell> {
  int _index = 0;
  final _firestore = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final me = session.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Worker'),
        actions: [
          IconButton(onPressed: session.signOut, icon: const Icon(Icons.logout)),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: [
          _RequestsTab(me: me, firestore: _firestore),
          _MyMothersTab(me: me, firestore: _firestore),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.campaign_outlined), selectedIcon: Icon(Icons.campaign), label: 'Requests'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'My Mothers'),
        ],
      ),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final AppUser me;
  final FirestoreService firestore;
  const _RequestsTab({required this.me, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HelpRequest>>(
      stream: firestore.watchAllRequests(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load requests: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final all = snapshot.data!;
        final mine = all.where((r) => r.assignedChwId == me.uid && r.status != RequestStatus.resolved).toList();
        final unassigned = all.where((r) => r.assignedChwId == null && r.status == RequestStatus.pending).toList();
        final resolved = all.where((r) => r.status == RequestStatus.resolved).toList();

        if (all.isEmpty) {
          return const Center(child: Padding(padding: EdgeInsets.all(24), child: EmptyHint(text: 'No help requests yet.')));
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: [
            SectionHeader(title: 'Assigned to You (${mine.length})'),
            const SizedBox(height: 12),
            if (mine.isEmpty)
              const BentoCard(child: EmptyHint(text: 'Nothing assigned to you right now.'))
            else
              ...mine.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(request: r, me: me, firestore: firestore, showClaim: false),
                  )),
            const SizedBox(height: AppSpacing.md),
            SectionHeader(title: 'Unassigned (${unassigned.length})'),
            const SizedBox(height: 12),
            if (unassigned.isEmpty)
              const BentoCard(child: EmptyHint(text: 'No unclaimed requests.'))
            else
              ...unassigned.map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(request: r, me: me, firestore: firestore, showClaim: true),
                  )),
            if (resolved.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SectionHeader(title: 'Resolved (${resolved.length})'),
              const SizedBox(height: 12),
              ...resolved.take(5).map((r) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _RequestCard(request: r, me: me, firestore: firestore, showClaim: false),
                  )),
            ],
          ],
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final HelpRequest request;
  final AppUser me;
  final FirestoreService firestore;
  final bool showClaim;

  const _RequestCard({required this.request, required this.me, required this.firestore, required this.showClaim});

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
              const Spacer(),
              if (showClaim)
                ElevatedButton(
                  onPressed: () => firestore.assignRequest(requestId: request.id, chwId: me.uid, chwName: me.name),
                  child: const Text('Claim'),
                )
              else if (request.status != RequestStatus.resolved) ...[
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChatView(
                        currentUserId: me.uid,
                        currentUserName: me.name,
                        otherUserId: request.motherId,
                        otherUserName: request.motherName,
                        appBarTitle: 'Chat with ${request.motherName}',
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: const Text('Message'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => firestore.resolveRequest(request.id),
                  child: const Text('Resolve'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MyMothersTab extends StatelessWidget {
  final AppUser me;
  final FirestoreService firestore;
  const _MyMothersTab({required this.me, required this.firestore});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: firestore.watchUsersByRole(UserRole.mother),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load mothers: ${snapshot.error}')));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final mothers = snapshot.data!.where((m) => m.assignedChwId == me.uid).toList();
        if (mothers.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint(text: 'No mothers assigned to you yet. Claim a request to get started.'),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          children: mothers
              .map((m) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: BentoCard(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ChatView(
                            currentUserId: me.uid,
                            currentUserName: me.name,
                            otherUserId: m.uid,
                            otherUserName: m.name,
                            appBarTitle: 'Chat with ${m.name}',
                          ),
                        ),
                      ),
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
                          const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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
