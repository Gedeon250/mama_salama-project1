import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Lab Results', showBack: true),
      body: StreamBuilder<List<LabResult>>(
        stream: firestore.watchLabResultsForMother(mother.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final results = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
              Text('Your most recent laboratory results, with reference ranges for context.',
                  style: TextStyle(color: AppColors.secondary)),
              const SizedBox(height: AppSpacing.md),
              if (results.isEmpty)
                const BentoCard(child: EmptyHint(text: 'No lab results yet — these are added by your health worker.'))
              else
                ...results.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: r.isNormal ? AppColors.onTertiaryContainer : AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              child: Icon(
                                r.isNormal ? Icons.check_circle_outline : Icons.priority_high,
                                color: r.isNormal ? AppColors.primary : AppColors.error,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.testName, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  Text('Reference: ${r.referenceRange}', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                                  Text(intl.DateFormat('MMM d, yyyy').format(r.date), style: TextStyle(fontSize: 11, color: AppColors.outline)),
                                ],
                              ),
                            ),
                            Text(
                              r.value,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: r.isNormal ? AppColors.onSurface : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              const SizedBox(height: AppSpacing.sm),
              BentoCard(
                color: AppColors.onTertiaryContainer,
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Flagged results are not a diagnosis by themselves — discuss any out-of-range value with your CHW or doctor at your next visit.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
