import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../providers/session_provider.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'emergency_sos_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(),
      body: StreamBuilder<List<Appointment>>(
        stream: firestore.watchAppointmentsForMother(mother.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.edgeMargin),
                child: EmptyHint(icon: Icons.error_outline, text: 'Could not load appointments: ${snapshot.error}'),
              ),
            );
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final all = snapshot.data!;
          final upcoming = all.where((a) => a.status == AppointmentStatus.upcoming).toList()
            ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
          final past = all.where((a) => a.status != AppointmentStatus.upcoming).toList()
            ..sort((a, b) => b.dateTime.compareTo(a.dateTime));

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
              SectionHeader(
                title: 'Appointments',
                subtitle: 'Manage your maternal health visits',
                trailing: ElevatedButton.icon(
                  onPressed: () => _showBookingSheet(context, firestore, mother),
                  icon: const Icon(Icons.add_circle_outline, size: 18),
                  label: const Text('Book New'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick options: telemedicine + SOS
              Row(
                children: [
                  Expanded(
                    child: BentoCard(
                      color: AppColors.onTertiaryContainer,
                      onTap: () => _showBookingSheet(context, firestore, mother, telemedicine: true),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.videocam_outlined, color: AppColors.primary, size: 28),
                          const SizedBox(height: 8),
                          const Text('Telemedicine', style: TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          const Text('Instant video call with a specialist', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.full)),
                            child: const Text('Available Now', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BentoCard(
                      color: AppColors.error,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const EmergencySosScreen())),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.emergency_share, color: Colors.white, size: 32),
                          SizedBox(height: 8),
                          Text('Emergency SOS', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              const SectionHeader(title: 'Upcoming'),
              const SizedBox(height: 12),
              if (upcoming.isEmpty)
                const BentoCard(child: EmptyHint(text: 'No upcoming appointments.'))
              else
                ...upcoming.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppointmentTile(
                        appointment: a,
                        onCancel: () => firestore.cancelAppointment(a.id),
                      ),
                    )),

              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'History'),
              const SizedBox(height: 12),
              if (past.isEmpty)
                const BentoCard(child: EmptyHint(text: 'No past appointments yet.'))
              else
                ...past.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppointmentTile(appointment: a),
                    )),
            ],
          );
        },
      ),
    );
  }

  void _showBookingSheet(BuildContext context, FirestoreService firestore, AppUser mother, {bool telemedicine = false}) {
    final titleController = TextEditingController(text: telemedicine ? 'Telemedicine Follow-up' : '');
    final providerController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 2));
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.edgeMargin,
              right: AppSpacing.edgeMargin,
              top: AppSpacing.md,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Book Appointment', style: Theme.of(ctx).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Reason for visit'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(labelText: 'Provider / hospital'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(intl.DateFormat('MMM d, yyyy').format(selectedDate)),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 300)),
                          );
                          if (picked != null) setState(() => selectedDate = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.schedule_outlined, size: 16),
                        label: Text(selectedTime.format(ctx)),
                        onPressed: () async {
                          final picked = await showTimePicker(context: ctx, initialTime: selectedTime);
                          if (picked != null) setState(() => selectedTime = picked);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      final dt = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                      final navigator = Navigator.of(ctx);
                      final messenger = ScaffoldMessenger.of(context);
                      await firestore.bookAppointment(Appointment(
                        id: '',
                        motherId: mother.uid,
                        motherName: mother.name,
                        title: titleController.text.trim().isEmpty ? 'Prenatal Checkup' : titleController.text.trim(),
                        provider: providerController.text.trim().isEmpty ? 'To be assigned' : providerController.text.trim(),
                        location: telemedicine ? 'Video call' : 'In-person visit',
                        dateTime: dt,
                        isTelemedicine: telemedicine,
                      ));
                      navigator.pop();
                      messenger.showSnackBar(const SnackBar(content: Text('Appointment booked!')));
                    },
                    child: const Text('Confirm Booking'),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  final Appointment appointment;
  final VoidCallback? onCancel;

  const _AppointmentTile({required this.appointment, this.onCancel});

  Color _statusColor() {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return AppColors.primary;
      case AppointmentStatus.completed:
        return AppColors.secondary;
      case AppointmentStatus.cancelled:
        return AppColors.error;
    }
  }

  String _statusLabel() {
    switch (appointment.status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.onTertiaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              appointment.isTelemedicine ? Icons.videocam_outlined : Icons.local_hospital_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(appointment.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(appointment.provider, style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
                Text(appointment.location, style: const TextStyle(color: AppColors.secondary, fontSize: 13)),
                const SizedBox(height: 6),
                Text(intl.DateFormat('MMM d, yyyy · h:mm a').format(appointment.dateTime),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor().withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(_statusLabel(), style: TextStyle(color: _statusColor(), fontSize: 11, fontWeight: FontWeight.w700)),
              ),
              if (onCancel != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppColors.error)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
