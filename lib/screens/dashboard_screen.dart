import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/chat_view.dart';
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

    return Scaffold(
      appBar: const MamaAppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.xs, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Text('Hello, ${mother.name}!', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          Text("You're doing great. Here's your health snapshot.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.md),

          // Pregnancy progress card
          const _PregnancyProgressCard(),
          const SizedBox(height: AppSpacing.md),

          // Quick actions grid
          const SectionHeader(title: 'Quick Actions'),
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
                label: 'SOS',
                color: AppColors.error,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EmergencySosScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.folder_shared_outlined,
                label: 'Records',
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const MedicalRecordsScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.menu_book_outlined,
                label: 'Learn',
                color: AppColors.primary,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EducationCenterScreen()),
                ),
              ),
              _QuickAction(
                icon: Icons.chat_bubble_outline,
                label: 'Ask AI',
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
          const SectionHeader(title: 'Your Care Team'),
          const SizedBox(height: 12),
          const _CareTeamCard(),
          const SizedBox(height: AppSpacing.md),

          // Upcoming appointment
          const SectionHeader(title: 'Upcoming Appointment'),
          const SizedBox(height: 12),
          const _UpcomingAppointmentCard(),
          const SizedBox(height: AppSpacing.md),

          // Today's medication
          const SectionHeader(title: "Today's Medication"),
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
          const SectionHeader(title: 'Water Intake'),
          const SizedBox(height: 12),
          const _WaterIntakeCard(),
          const SizedBox(height: AppSpacing.md),

          // Daily health tip
          const SectionHeader(title: "Today's Health Tip"),
          const SizedBox(height: 12),
          BentoCard(
            color: AppColors.onTertiaryContainer,
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: AppColors.primary),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Eating iron-rich foods like beans and leafy greens alongside vitamin C can help your body absorb more iron.',
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
              color: color.withOpacity(0.12),
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

    return StreamBuilder<PregnancyProfile>(
      stream: firestore.watchPregnancyProfile(mother.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.xl)),
            child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}'),
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
                        Text('Current Progress',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('Week ${profile.pregnancyWeek}',
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
                    child: Text('Trimester ${profile.trimester}',
                        style: const TextStyle(color: AppColors.primaryContainer, fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.child_friendly, color: Colors.white, size: 30),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Baby is the size of a',
                            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
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
                trackColor: Colors.white.withOpacity(0.2),
                fillColor: AppColors.primaryFixed,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Conception', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  Text('${profile.daysToDueDate} days to due date',
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

    return StreamBuilder<DailyVitals>(
      stream: firestore.watchVitalsForDate(mother.uid, DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BentoCard(child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const BentoCard(child: Center(child: CircularProgressIndicator()));
        }
        final vitals = snapshot.data!;
        final canAddMore = vitals.waterCupsToday < vitals.waterGoalCups + 4;

        return BentoCard(
          child: Row(
            children: [
              const Icon(Icons.water_drop_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${vitals.waterCupsToday} / ${vitals.waterGoalCups} cups',
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

class _UpcomingAppointmentCard extends StatelessWidget {
  const _UpcomingAppointmentCard();

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return StreamBuilder<List<Appointment>>(
      stream: firestore.watchAppointmentsForMother(mother.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return BentoCard(child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const BentoCard(child: Center(child: CircularProgressIndicator()));
        }
        final upcoming = snapshot.data!.where((a) => a.status == AppointmentStatus.upcoming).toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
        if (upcoming.isEmpty) {
          return const BentoCard(child: EmptyHint(text: 'No upcoming appointments booked.'));
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
                        style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
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
  bool _sending = false;

  Future<void> _sendHelpRequest(AppUser mother) async {
    if (_messageController.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await _firestore.createHelpRequest(HelpRequest(
      id: '',
      motherId: mother.uid,
      motherName: mother.name,
      type: RequestType.generalHelp,
      message: _messageController.text.trim(),
      createdAt: DateTime.now(),
    ));
    _messageController.clear();
    setState(() => _sending = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sent to the admin dashboard — a health worker will follow up.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final mother = session.currentUser;

    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (mother?.assignedChwId != null)
            FutureBuilder<AppUser?>(
              future: _firestore.getUserById(mother!.assignedChwId!),
              builder: (context, snapshot) {
                final chw = snapshot.data;
                return Row(
                  children: [
                    const CircleAvatar(backgroundColor: AppColors.onTertiaryContainer, child: Icon(Icons.volunteer_activism, color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(chw?.name ?? 'Your Health Worker', style: const TextStyle(fontWeight: FontWeight.w700)),
                          const Text('Your assigned health worker', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
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
                              otherUserId: chw.uid,
                              otherUserName: chw.name,
                              appBarTitle: 'Chat with ${chw.name}',
                            ),
                          ),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Message'),
                      ),
                  ],
                );
              },
            )
          else
            const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "You don't have a health worker assigned yet. Send a request below and an admin will connect you with one.",
                    style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            decoration: const InputDecoration(hintText: 'Describe what you need help with...'),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_sending || mother == null) ? null : () => _sendHelpRequest(mother),
              icon: const Icon(Icons.send, size: 16),
              label: Text(_sending ? 'Sending...' : 'Request Help'),
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
    return AlertDialog(
      title: const Text('MamaSalama AI Assistant'),
      content: const Text(
        'This is a placeholder for the AI health assistant described in the PRD '
        '(pregnancy Q&A, symptom triage, nutrition advice, and Kinyarwanda / '
        'English / Swahili / French translation). Wire this up to your chosen '
        'LLM provider when the backend is ready.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
      ],
    );
  }
}
