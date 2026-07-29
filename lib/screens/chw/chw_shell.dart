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
import '../community_hub_screen.dart';

class ChwShell extends StatefulWidget {
  const ChwShell({super.key});

  @override
  State<ChwShell> createState() => _ChwShellState();
}

class _ChwShellState extends State<ChwShell> {
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
    final me = session.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Worker'),
        actions: [
          IconButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CommunityHubScreen())),
            icon: const Icon(Icons.groups_outlined),
            tooltip: 'Community',
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
                _RequestsTab(me: me, firestore: _firestore),
                _MyMothersTab(me: me, firestore: _firestore),
              ],
            ),
          ),
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
        return StreamBuilder<List<ChatThreadSummary>>(
          stream: firestore.watchMyThreads(me.uid),
          builder: (context, threadsSnap) {
            final threads = threadsSnap.data ?? [];
            ChatThreadSummary? threadFor(String motherUid) {
              for (final t in threads) {
                if (t.otherUid == motherUid) return t;
              }
              return null;
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
              children: mothers
                  .map((m) {
                    final thread = threadFor(m.uid);
                    final unread = thread != null && thread.lastSenderId != me.uid;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        color: unread ? AppColors.errorContainer : null,
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
                                  Row(
                                    children: [
                                      Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      if (unread) ...[
                                        const SizedBox(width: 6),
                                        const Icon(Icons.circle, size: 8, color: AppColors.error),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    thread != null && thread.lastMessage.isNotEmpty ? thread.lastMessage : (m.phone ?? m.email),
                                    style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: unread ? FontWeight.w700 : FontWeight.w400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _showAddRecordSheet(context, firestore, m),
                              icon: const Icon(Icons.note_add_outlined, color: AppColors.primary),
                              tooltip: 'Add record',
                            ),
                            const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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

  void _showAddRecordSheet(BuildContext context, FirestoreService firestore, AppUser forMother) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => _AddRecordSheet(firestore: firestore, forMother: forMother),
    );
  }
}

enum _RecordType { visitNote, labResult, vaccine }

class _AddRecordSheet extends StatefulWidget {
  final FirestoreService firestore;
  final AppUser forMother;
  const _AddRecordSheet({required this.firestore, required this.forMother});

  @override
  State<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends State<_AddRecordSheet> {
  _RecordType _type = _RecordType.visitNote;

  // Visit note fields
  final _titleController = TextEditingController();
  final _categoryController = TextEditingController(text: 'Visit note');
  final _summaryController = TextEditingController();

  // Lab result fields
  final _testNameController = TextEditingController();
  final _valueController = TextEditingController();
  final _referenceRangeController = TextEditingController();
  bool _isNormal = true;

  // Vaccine fields
  final _vaccineNameController = TextEditingController();
  String _forWhom = 'Mother';
  bool _vaccineCompleted = false;

  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _categoryController.dispose();
    _summaryController.dispose();
    _testNameController.dispose();
    _valueController.dispose();
    _referenceRangeController.dispose();
    _vaccineNameController.dispose();
    super.dispose();
  }

  // Don't await the write futures — they only resolve after a server
  // round-trip, which would leave this sheet stuck on "Saving..." forever
  // while offline. The local cache updates immediately (so the mother's
  // screen and this CHW's own view both reflect it right away) and the
  // write queues until back online.
  void _save() {
    switch (_type) {
      case _RecordType.visitNote:
        widget.firestore.addMedicalRecord(MedicalRecord(
          id: '',
          motherId: widget.forMother.uid,
          title: _titleController.text.trim().isEmpty ? 'Visit note' : _titleController.text.trim(),
          category: _categoryController.text.trim().isEmpty ? 'Visit note' : _categoryController.text.trim(),
          date: _date,
          summary: _summaryController.text.trim(),
        ));
        break;
      case _RecordType.labResult:
        widget.firestore.addLabResult(LabResult(
          id: '',
          motherId: widget.forMother.uid,
          testName: _testNameController.text.trim(),
          value: _valueController.text.trim(),
          referenceRange: _referenceRangeController.text.trim(),
          isNormal: _isNormal,
          date: _date,
        ));
        break;
      case _RecordType.vaccine:
        widget.firestore.addVaccineRecord(VaccineRecord(
          id: '',
          motherId: widget.forMother.uid,
          name: _vaccineNameController.text.trim(),
          forWhom: _forWhom,
          dueOrGivenDate: _date,
          completed: _vaccineCompleted,
        ));
        break;
    }
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
            Text('Add Record for ${widget.forMother.name}', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                PillChip(label: 'Visit Note', selected: _type == _RecordType.visitNote, onTap: () => setState(() => _type = _RecordType.visitNote)),
                PillChip(label: 'Lab Result', selected: _type == _RecordType.labResult, onTap: () => setState(() => _type = _RecordType.labResult)),
                PillChip(label: 'Vaccine', selected: _type == _RecordType.vaccine, onTap: () => setState(() => _type = _RecordType.vaccine)),
              ],
            ),
            const SizedBox(height: 16),
            if (_type == _RecordType.visitNote) ...[
              TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
              const SizedBox(height: 12),
              TextField(controller: _categoryController, decoration: const InputDecoration(labelText: 'Category (e.g. Visit note, Ultrasound, Delivery)')),
              const SizedBox(height: 12),
              TextField(controller: _summaryController, maxLines: 3, decoration: const InputDecoration(labelText: 'Summary')),
            ] else if (_type == _RecordType.labResult) ...[
              TextField(controller: _testNameController, decoration: const InputDecoration(labelText: 'Test name')),
              const SizedBox(height: 12),
              TextField(controller: _valueController, decoration: const InputDecoration(labelText: 'Value')),
              const SizedBox(height: 12),
              TextField(controller: _referenceRangeController, decoration: const InputDecoration(labelText: 'Reference range')),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isNormal,
                onChanged: (v) => setState(() => _isNormal = v),
                title: const Text('Within normal range'),
              ),
            ] else ...[
              TextField(controller: _vaccineNameController, decoration: const InputDecoration(labelText: 'Vaccine name')),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('For: '),
                  const SizedBox(width: 8),
                  PillChip(label: 'Mother', selected: _forWhom == 'Mother', onTap: () => setState(() => _forWhom = 'Mother')),
                  const SizedBox(width: 8),
                  PillChip(label: 'Baby', selected: _forWhom == 'Baby', onTap: () => setState(() => _forWhom = 'Baby')),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _vaccineCompleted,
                onChanged: (v) => setState(() => _vaccineCompleted = v),
                title: const Text('Already given'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text(intl.DateFormat('MMM d, yyyy').format(_date)),
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 300)),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('Save Record'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
