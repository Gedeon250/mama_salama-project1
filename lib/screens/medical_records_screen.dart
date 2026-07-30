import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../services/report_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class MedicalRecordsScreen extends StatefulWidget {
  const MedicalRecordsScreen({super.key});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen> {
  bool _generating = false;

  Future<void> _downloadReport(FirestoreService firestore, AppUser mother) async {
    setState(() => _generating = true);
    try {
      final profile = await firestore.watchPregnancyProfile(mother.uid).first;
      final records = await firestore.watchMedicalRecordsForMother(mother.uid).first;
      await ReportService.generateMedicalSummaryPdf(mother: mother, profile: profile, records: records);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate report: $e')));
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Medical Records', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Medical Records', style: Theme.of(context).textTheme.headlineLarge),
                    const SizedBox(height: 4),
                    Text('Access your clinical history and pregnancy milestones.',
                        style: TextStyle(color: AppColors.secondary)),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _generating ? null : () => _downloadReport(firestore, mother),
                icon: _generating
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined, size: 16),
                label: Text(_generating ? 'Generating...' : 'Report'),
              ),
            ],
          ),
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
                            Text('ESTIMATED DELIVERY', style: TextStyle(color: AppColors.primaryFixed, fontSize: 10, fontWeight: FontWeight.w700)),
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
          StreamBuilder<List<MedicalRecord>>(
            stream: firestore.watchMedicalRecordsForMother(mother.uid),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return EmptyHint(icon: Icons.error_outline, text: 'Could not load records: ${snapshot.error}');
              }
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final records = snapshot.data!;
              if (records.isEmpty) {
                return const EmptyHint(text: 'No visit notes yet — these are added by your health worker.');
              }
              return Column(
                children: records
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BentoCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                                  child: Icon(_iconForCategory(r.category), color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(child: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                                          Text(intl.DateFormat('MMM d').format(r.date), style: TextStyle(color: AppColors.secondary, fontSize: 12)),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(r.category, style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 6),
                                      Text(r.summary, style: const TextStyle(fontSize: 13)),
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
        ],
      ),
    );
  }

  IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'ultrasound':
        return Icons.monitor_heart_outlined;
      case 'lab':
        return Icons.science_outlined;
      case 'delivery':
        return Icons.child_friendly_outlined;
      default:
        return Icons.medical_information_outlined;
    }
  }

  Widget _statTile(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.surfaceVariant, fontSize: 10)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
