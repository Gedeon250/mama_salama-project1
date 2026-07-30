import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../l10n/generated/app_localizations.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/chat_view.dart';
import '../widgets/user_avatar.dart';
import 'appointments_screen.dart';
import 'emergency_sos_screen.dart';
import 'medical_records_screen.dart';
import 'education_center_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final mother = context.watch<SessionProvider>().currentUser!;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: const MamaAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.xs, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Text(l10n.helloName(mother.name), style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text(l10n.healthSnapshotSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.md),

          // Pregnancy progress card
          const _PregnancyProgressCard(),
          const SizedBox(height: AppSpacing.md),

          // Quick actions grid
          SectionHeader(title: l10n.quickActionsTitle),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _QuickAction(
                icon: Icons.emergency,
                label: l10n.sosLabel,
                color: AppColors.error,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.folder_shared_outlined,
                label: l10n.recordsLabel,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                label: l10n.learnLabel,
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EducationCenterScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                label: l10n.askAiLabel,
                color: AppColors.primary,
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => const _AiAssistantDialog(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Care team / help request — talks to the Firebase backend
          SectionHeader(title: l10n.yourCareTeamTitle),
          const SizedBox(height: 12),
          const _CareTeamCard(),
          const SizedBox(height: AppSpacing.md),

          // Any active conversation, whether or not an admin has formally
          // assigned a CHW yet — a CHW can message a mother just by
          // claiming her help request, so this is the only reliable place
          // she'll see that a message is waiting.
          const _MessagesSection(),

          // Upcoming appointment
          SectionHeader(title: l10n.upcomingAppointmentTitle),
          const SizedBox(height: 12),
          const _UpcomingAppointmentCard(),
          const SizedBox(height: AppSpacing.md),

          // Today's medication
          SectionHeader(title: l10n.todaysMedicationTitle),
          const SizedBox(height: 12),
          BentoCard(
            child: Column(
              children: data.todaysMedications.map((dose) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: dose.taken,
                  onChanged: (_) => data.toggleMedicationTaken(dose),
                  activeColor: AppColors.primary,
                  title: Text(dose.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${dose.dosage} · ${dose.time}'),
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Water intake
          SectionHeader(title: l10n.waterIntakeTitle),
          const SizedBox(height: 12),
          const _WaterIntakeCard(),
          const SizedBox(height: AppSpacing.md),

          // Daily health tip
          SectionHeader(title: l10n.todaysHealthTipTitle),
          const SizedBox(height: 12),
          BentoCard(
            color: AppColors.onTertiaryContainer,
            child: Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.healthTipText,
                    style: TextStyle(color: AppColors.onSurface),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _PregnancyProgressCard extends StatelessWidget {
  const _PregnancyProgressCard();

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<PregnancyProfile>(
      stream: firestore.watchPregnancyProfile(mother.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: EmptyHint(icon: Icons.error_outline, text: l10n.couldNotLoad('${snapshot.error}')),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            height: 180,
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: const Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }
        final profile = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.currentProgressLabel,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                        Text(l10n.weekLabel('${profile.pregnancyWeek}'),
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(l10n.trimesterLabel('${profile.trimester}'),
                        style: TextStyle(color: AppColors.primaryContainer, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_friendly, color: Colors.white, size: 30),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.babySizeIntro,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
                        Text(profile.babySizeComparison,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ProgressTrack(
                value: profile.pregnancyWeek / 40,
                trackColor: Colors.white.withValues(alpha: 0.2),
                fillColor: AppColors.primaryFixed,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.conceptionLabel, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(l10n.daysToDueDate('${profile.daysToDueDate}'),
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaterIntakeCard extends StatelessWidget {
  const _WaterIntakeCard();

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<DailyVitals>(
      stream: firestore.watchVitalsForDate(mother.uid, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BentoCard(child: EmptyHint(icon: Icons.error_outline, text: l10n.couldNotLoad('${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return const BentoCard(child: Center(child: CircularProgressIndicator()));
        }
        final vitals = snapshot.data!;
        final canAddMore = vitals.waterCupsToday < vitals.waterGoalCups + 4;

        return BentoCard(
          child: Row(
            children: [
              Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.cupsFormat('${vitals.waterCupsToday}', '${vitals.waterGoalCups}'),
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    ProgressTrack(value: vitals.waterCupsToday / vitals.waterGoalCups),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: canAddMore ? () => firestore.addWaterCup(mother.uid, goalCups: vitals.waterGoalCups) : null,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessagesSection extends StatelessWidget {
  const _MessagesSection();

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<ChatThreadSummary>>(
      stream: firestore.watchMyThreads(mother.uid),
      builder: (context, snapshot) {
        final threads = snapshot.data ?? [];
        if (threads.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(title: l10n.messagesTitle),
            const SizedBox(height: 12),
            ...threads.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: FutureBuilder<AppUser?>(
                    future: firestore.getUserById(t.otherUid),
                    builder: (context, userSnap) {
                      final other = userSnap.data;
                      final unread = t.lastSenderId != mother.uid;
                      return BentoCard(
                        color: unread ? AppColors.errorContainer : null,
                        onTap: other == null
                            ? null
                            : () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ChatView(
                                      currentUserId: mother.uid,
                                      currentUserName: mother.name,
                                      currentUserPhotoUrl: mother.photoUrl,
                                      otherUserId: other.uid,
                                      otherUserName: other.name,
                                      otherUserPhotoUrl: other.photoUrl,
                                      appBarTitle: 'Chat with ${other.name}',
                                    ),
                                  ),
                                ),
                        child: Row(
                          children: [
                            UserAvatar(photoUrl: other?.photoUrl, backgroundColor: AppColors.onTertiaryContainer, icon: Icons.volunteer_activism),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(other?.name ?? l10n.healthWorkerFallbackName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      if (unread) ...[
                                        const SizedBox(width: 6),
                                        Icon(Icons.circle, size: 8, color: AppColors.error),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    t.lastMessage,
                                    style: TextStyle(fontSize: 12, color: AppColors.secondary, fontWeight: unread ? FontWeight.w700 : FontWeight.w400),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }
}

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard();

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<Appointment>>(
      stream: firestore.watchAppointmentsForMother(mother.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BentoCard(child: EmptyHint(icon: Icons.error_outline, text: l10n.couldNotLoad('${snapshot.error}')));
        }
        if (!snapshot.hasData) {
          return const BentoCard(child: Center(child: CircularProgressIndicator()));
        }
        final upcoming = snapshot.data!.where((a) => a.status == AppointmentStatus.upcoming).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        if (upcoming.isEmpty) {
          return BentoCard(child: EmptyHint(text: l10n.noUpcomingAppointments));
        }
        final next = upcoming.first;
        return BentoCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AppointmentsScreen())),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.onTertiaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  next.isTelemedicine ? Icons.videocam_outlined : Icons.local_hospital_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(next.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('${next.provider} · ${intl.DateFormat('MMM d, h:mm a').format(next.dateTime)}',
                        style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CareTeamCard extends StatefulWidget {
  const _CareTeamCard();

  @override
  State<_CareTeamCard> createState() => _CareTeamCardState();
}

class _CareTeamCardState extends State<_CareTeamCard> {
  final _firestore = FirestoreService();
  final _messageController = TextEditingController();

  void _sendHelpRequest(AppUser mother) {
    if (_messageController.text.trim().isEmpty) return;
    // Don't await: the write future only resolves after a server
    // round-trip, which would leave this stuck on "Sending..." forever
    // while offline. The write queues locally and syncs once reconnected.
    _firestore.createHelpRequest(HelpRequest(
      id: '',
      motherId: mother.uid,
      motherName: mother.name,
      type: RequestType.generalHelp,
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
    ));
    _messageController.clear();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.helpRequestSentSnackbar)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final mother = session.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mother?.assignedChwId != null)
            FutureBuilder<AppUser?>(
              future: _firestore.getUserById(mother!.assignedChwId!),
              builder: (context, snapshot) {
                final chw = snapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        UserAvatar(photoUrl: chw?.photoUrl, backgroundColor: AppColors.onTertiaryContainer, icon: Icons.volunteer_activism),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(chw?.name ?? l10n.healthWorkerFallbackName, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(l10n.yourAssignedHealthWorker, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                            ],
                          ),
                        ),
                        if (chw != null)
                          OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).push(
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
                            ),
                            icon: const Icon(Icons.chat_bubble_outline, size: 16),
                            label: Text(l10n.messageButton),
                          ),
                      ],
                    ),
                    if (chw != null)
                      StreamBuilder<ChatThreadSummary?>(
                        stream: _firestore.watchThreadSummary(_firestore.threadIdFor(mother.uid, chw.uid), mother.uid),
                        builder: (context, threadSnap) {
                          final thread = threadSnap.data;
                          if (thread == null || thread.lastMessage.isEmpty) return const SizedBox.shrink();
                          final unread = thread.lastSenderId != mother.uid;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: unread ? AppColors.errorContainer : AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Row(
                                children: [
                                  if (unread) Icon(Icons.circle, size: 8, color: AppColors.error),
                                  if (unread) const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      unread ? '${chw.name}: ${thread.lastMessage}' : thread.lastMessage,
                                      style: TextStyle(fontSize: 12, fontWeight: unread ? FontWeight.w700 : FontWeight.w400, color: AppColors.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                );
              },
            )
          else
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noHealthWorkerAssigned,
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: InputDecoration(hintText: l10n.describeHelpHint),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: mother == null ? null : () => _sendHelpRequest(mother),
              icon: const Icon(Icons.send, size: 16),
              label: Text(l10n.requestHelpButton),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiAssistantDialog extends StatelessWidget {
  const _AiAssistantDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.aiAssistantTitle),
      content: Text(l10n.aiAssistantBody),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.gotIt)),
      ],
    );
  }
}
