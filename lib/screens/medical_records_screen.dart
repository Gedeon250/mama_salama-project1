import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_models.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class MedicalRecordsScreen extends StatelessWidget {
  const MedicalRecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Medical Records', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Text('Medical Records', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 4),
          const Text('Access your clinical history and pregnancy milestones.',
              style: TextStyle(color: AppColors.secondary)),
          const SizedBox(height: AppSpacing.md),

          // Status summary
          StreamBuilder<PregnancyProfile>(
            stream: firestore.watchPregnancyProfile(mother.uid),
            builder: (context, snapshot) {
              final profile = snapshot.data;
              if (profile == null) {
                return Container(
                  height: 140,
                  decoration: BoxDecoration(color: AppColors.inverseSurface, borderRadius: BorderRadius.circular(AppRadius.xl)),
                  child: const Center(child: CircularProgressIndicator(color: Colors.white)),
                );
              }
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.inverseSurface,
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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.full)),
                                child: const Text('Active Journey', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                              ),
                              const SizedBox(height: 8),
                              const Text('Current Pregnancy Status', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('ESTIMATED DELIVERY', style: TextStyle(color: AppColors.primaryFixed, fontSize: 10, fontWeight: FontWeight.w700)),
                            Text(intl.DateFormat('MMM d, yyyy').format(profile.dueDate),
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _statTile('Blood Type', profile.bloodType),
                        const SizedBox(width: 8),
                        _statTile('Allergies', profile.allergies.isEmpty ? 'None' : profile.allergies.join(', ')),
                        const SizedBox(width: 8),
                        _statTile('Trimester', 'T${profile.trimester}'),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          const SectionHeader(title: 'History'),
          const SizedBox(height: 12),
          ...data.medicalRecords.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(r.icon, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                                Text(intl.DateFormat('MMM d').format(r.date), style: const TextStyle(color: AppColors.secondary, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(r.category, style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text(r.summary, style: const TextStyle(fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.surfaceVariant, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
