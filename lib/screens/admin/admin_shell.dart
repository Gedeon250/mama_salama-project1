import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/chat_alert_service.dart';
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
        actions: [IconButton(onPressed: session.signOut, icon: const Icon(Icons.logout))],
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
                                  Text(item.description, style: const TextStyle(fontSize: 12, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      PillChip(label: item.category),
                                      const SizedBox(width: 6),
                                      Text(item.durationOrLength, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
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
