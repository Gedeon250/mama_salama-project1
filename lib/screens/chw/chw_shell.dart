import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../../services/chat_alert_service.dart';
import '../../services/firestore_service.dart';
import '../../services/launchers.dart';
import '../../services/report_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/chat_view.dart';
import '../../widgets/user_avatar.dart';
import '../community_hub_screen.dart';
import '../messages_inbox_screen.dart';

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
        title: Text(_index == 0
            ? 'Requests'
            : _index == 1
                ? 'My Mothers'
                : 'Messages'),
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
                const MessagesInboxScreen(embedded: true),
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
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
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

/// Pre-registered drivers a CHW can dispatch, matching the design's journey
/// map ("the app displays pre-registered drivers; a call is required to
/// verify"). Seeded locally for the demo; swap for a Firestore `drivers`
/// collection later without touching the card.
const _presetDrivers = <(String name, String phone)>[
  ('James Uwimana (moto)', '+250788111222'),
  ('Alice Mukamana (car)', '+250788333444'),
  ('Eric Habimana (moto)', '+250788555666'),
];

class _RequestCard extends StatelessWidget {
  final HelpRequest request;
  final AppUser me;
  final FirestoreService firestore;
  final bool showClaim;

  const _RequestCard({required this.request, required this.me, required this.firestore, required this.showClaim});

  Future<void> _arrangeTransport(BuildContext context) async {
    final picked = await showModalBottomSheet<(String, String)>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose a driver', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            for (final d in _presetDrivers)
              ListTile(
                leading: Icon(Icons.local_taxi_outlined, color: AppColors.primary),
                title: Text(d.$1),
                subtitle: Text(d.$2),
                onTap: () => Navigator.of(ctx).pop(d),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await firestore.arrangeTransport(requestId: request.id, driverName: picked.$1, driverPhone: picked.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSos = request.type == RequestType.sos;
    final active = request.status != RequestStatus.resolved;
    return BentoCard(
      color: isSos && active ? AppColors.errorContainer : null,
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

          // SOS location (Gap 3) — tap to navigate to the mother.
          if (request.hasLocation) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: AppColors.error),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${request.lat!.toStringAsFixed(5)}, ${request.lng!.toStringAsFixed(5)}',
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => openInMaps(request.lat!, request.lng!),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text('Open in Maps'),
                ),
              ],
            ),
          ] else if (isSos) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_off_outlined, size: 16, color: AppColors.secondary),
                const SizedBox(width: 4),
                Text('No location shared', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              ],
            ),
          ],

          // Arranged transport (Gap 4).
          if (request.transportStatus == TransportStatus.arranged) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_taxi, size: 16, color: AppColors.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Transport: ${request.driverName ?? 'driver'}',
                    style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                if (request.driverPhone != null)
                  TextButton.icon(
                    onPressed: () => callNumber(request.driverPhone!),
                    icon: const Icon(Icons.call, size: 16),
                    label: const Text('Call'),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),
          Row(
            children: [
              PillChip(label: request.status.name),
              const Spacer(),
              Flexible(
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (showClaim)
                      ElevatedButton(
                        onPressed: () => firestore.assignRequest(
                          requestId: request.id,
                          motherId: request.motherId,
                          chwId: me.uid,
                          chwName: me.name,
                          chwPhone: me.phone,
                        ),
                        child: const Text('Claim'),
                      )
                    else if (active) ...[
                      OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatView(
                              currentUserId: me.uid,
                              currentUserName: me.name,
                              currentUserPhotoUrl: me.photoUrl,
                              otherUserId: request.motherId,
                              otherUserName: request.motherName,
                              appBarTitle: 'Chat with ${request.motherName}',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message'),
                      ),
                      if (isSos && request.transportStatus != TransportStatus.arranged)
                        OutlinedButton.icon(
                          onPressed: () => _arrangeTransport(context),
                          icon: const Icon(Icons.local_taxi_outlined, size: 16),
                          label: const Text('Transport'),
                        ),
                      TextButton(
                        onPressed: () => firestore.resolveRequest(request.id),
                        child: const Text('Resolve'),
                      ),
                    ],
                  ],
                ),
              ),
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
              child: EmptyHint(text: 'No mothers assigned to you yet. Claim a help request or wait for an admin to assign you.'),
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
                              currentUserPhotoUrl: me.photoUrl,
                              otherUserId: m.uid,
                              otherUserName: m.name,
                              otherUserPhotoUrl: m.photoUrl,
                              appBarTitle: 'Chat with ${m.name}',
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            UserAvatar(photoUrl: m.photoUrl, backgroundColor: AppColors.secondaryContainer, icon: Icons.pregnant_woman),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          m.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (unread) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.circle, size: 8, color: AppColors.error),
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
                            StreamBuilder<PregnancyProfile>(
                              stream: firestore.watchPregnancyProfile(m.uid),
                              builder: (context, profileSnap) {
                                final isHighRisk = profileSnap.data?.isHighRisk ?? false;
                                return IconButton(
                                  onPressed: () => firestore.setHighRisk(m.uid, !isHighRisk),
                                  icon: Icon(Icons.warning_amber_rounded, color: isHighRisk ? AppColors.error : AppColors.outline),
                                  tooltip: isHighRisk ? 'Marked high-risk — tap to unmark' : 'Mark high-risk',
                                );
                              },
                            ),
                            IconButton(
                              onPressed: () => _showPregnancyDocsSheet(context, firestore, m),
                              icon: Icon(Icons.folder_shared_outlined, color: AppColors.primary),
                              tooltip: 'Pregnancy documents',
                            ),
                            IconButton(
                              onPressed: () => _showAddRecordSheet(context, firestore, m),
                              icon: Icon(Icons.note_add_outlined, color: AppColors.primary),
                              tooltip: 'Add record',
                            ),
                            IconButton(
                              onPressed: () => _showReferralSheet(context, firestore, me, m),
                              icon: Icon(Icons.local_hospital_outlined, color: AppColors.primary),
                              tooltip: 'Referral letter',
                            ),
                            Icon(Icons.chat_bubble_outline, color: AppColors.primary),
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

  void _showPregnancyDocsSheet(BuildContext context, FirestoreService firestore, AppUser forMother) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        return StreamBuilder<PregnancyProfile>(
          stream: firestore.watchPregnancyProfile(forMother.uid),
          builder: (context, snap) {
            final profile = snap.data;
            if (profile == null) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (!profile.shareAttachmentsWithChw) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: EmptyHint(
                  icon: Icons.lock_outline,
                  text: '${forMother.name} has not shared pregnancy documents with health workers.',
                ),
              );
            }
            if (profile.attachments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: EmptyHint(
                  icon: Icons.folder_off_outlined,
                  text: 'No pregnancy documents attached yet.',
                ),
              );
            }
            return ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.md, AppSpacing.edgeMargin, AppSpacing.xl),
              children: [
                Text('${forMother.name}\'s documents', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                ...profile.attachments.map((a) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.attach_file, color: AppColors.primary),
                      title: Text(a.fileName),
                      trailing: Icon(Icons.open_in_new, color: AppColors.outline),
                      onTap: () async {
                        final uri = Uri.tryParse(a.url);
                        if (uri == null) return;
                        final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
                        if (!ok && ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Could not open file.')));
                        }
                      },
                    )),
              ],
            );
          },
        );
      },
    );
  }

  void _showReferralSheet(BuildContext context, FirestoreService firestore, AppUser me, AppUser forMother) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) => _ReferralSheet(firestore: firestore, me: me, forMother: forMother),
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

class _ReferralSheet extends StatefulWidget {
  final FirestoreService firestore;
  final AppUser me;
  final AppUser forMother;
  const _ReferralSheet({required this.firestore, required this.me, required this.forMother});

  @override
  State<_ReferralSheet> createState() => _ReferralSheetState();
}

class _ReferralSheetState extends State<_ReferralSheet> {
  final _hospitalNameController = TextEditingController();
  final _reasonController = TextEditingController();
  AppUser? _selectedHospital;
  bool _generating = false;

  @override
  void dispose() {
    _hospitalNameController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final hospitalName = _selectedHospital?.name ?? _hospitalNameController.text.trim();
    if (hospitalName.isEmpty || _reasonController.text.trim().isEmpty) return;
    setState(() => _generating = true);
    try {
      final profile = await widget.firestore.watchPregnancyProfile(widget.forMother.uid).first;
      await ReportService.generateReferralLetterPdf(
        mother: widget.forMother,
        profile: profile,
        referringChw: widget.me,
        hospitalName: hospitalName,
        reason: _reasonController.text.trim(),
      );
      // Only persisted (so the Hospital's own "Referrals" tab can see it)
      // when a registered Hospital account was actually selected — a
      // free-typed name has no account to route it to.
      if (_selectedHospital != null) {
        await widget.firestore.createReferral(Referral(
          id: '',
          motherId: widget.forMother.uid,
          motherName: widget.forMother.name,
          chwId: widget.me.uid,
          chwName: widget.me.name,
          hospitalId: _selectedHospital!.uid,
          hospitalName: _selectedHospital!.name,
          reason: _reasonController.text.trim(),
          createdAt: DateTime.now(),
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate letter: $e')));
      }
      if (mounted) setState(() => _generating = false);
    }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Referral Letter for ${widget.forMother.name}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          StreamBuilder<List<AppUser>>(
            stream: widget.firestore.watchUsersByRole(UserRole.hospital),
            builder: (context, snapshot) {
              final hospitals = snapshot.data ?? [];
              if (hospitals.isEmpty) {
                // No registered Hospital accounts yet — fall back to a
                // free-text name (PDF only, nothing to route to in-app).
                return TextField(controller: _hospitalNameController, decoration: const InputDecoration(labelText: 'Referring to (hospital/clinic name)'));
              }
              return DropdownButtonFormField<AppUser>(
                initialValue: _selectedHospital,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Referring to (registered hospital)'),
                items: hospitals.map((h) => DropdownMenuItem(value: h, child: Text(h.name, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (h) {
                  setState(() => _selectedHospital = h);
                },
              );
            },
          ),
          const SizedBox(height: 12),
          TextField(controller: _reasonController, maxLines: 3, decoration: const InputDecoration(labelText: 'Reason for referral')),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _generating ? null : _generate,
              child: Text(_generating ? 'Generating...' : 'Generate Letter'),
            ),
          ),
        ],
      ),
    );
  }
}
