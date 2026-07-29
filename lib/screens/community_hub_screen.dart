import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'support_group_screen.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Community'),
      body: StreamBuilder<List<CommunityGroup>>(
        stream: firestore.watchCommunityGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final groups = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
              const TextField(
                decoration: InputDecoration(hintText: 'Search for groups or topics...', prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(height: AppSpacing.md),
              const SectionHeader(title: 'Your Groups'),
              const SizedBox(height: 12),
              if (groups.isEmpty)
                const BentoCard(child: EmptyHint(text: 'No community groups yet.'))
              else
                ...groups.map((g) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SupportGroupScreen(group: g))),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: const Icon(Icons.groups, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                                      PillChip(label: g.trimesterTag),
                                    ],
                                  ),
                                  Text('${g.memberCount} Active Members', style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.outline),
                          ],
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
