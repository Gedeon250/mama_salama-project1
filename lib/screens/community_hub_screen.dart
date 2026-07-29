import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'support_group_screen.dart';

class CommunityHubScreen extends StatelessWidget {
  const CommunityHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Community'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          TextField(
            decoration: const InputDecoration(hintText: 'Search for groups or topics...', prefixIcon: Icon(Icons.search)),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Your Groups'),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: data.communityGroups.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final g = data.communityGroups[i];
                return SizedBox(
                  width: 220,
                  child: BentoCard(
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportGroupScreen())),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 60,
                          width: double.infinity,
                          decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                          child: const Icon(Icons.groups, color: AppColors.primary),
                        ),
                        const SizedBox(height: 8),
                        PillChip(label: g.trimesterTag),
                        const SizedBox(height: 6),
                        Text(g.name, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('${g.memberCount} Active Members', style: const TextStyle(fontSize: 11, color: AppColors.secondary)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Discussion Feed'),
          const SizedBox(height: 12),
          ...data.supportGroupPosts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportGroupScreen())),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: p.isExpertAnswer ? AppColors.primary : AppColors.secondaryContainer,
                            child: Icon(p.isExpertAnswer ? Icons.verified : Icons.person, size: 16, color: p.isExpertAnswer ? Colors.white : AppColors.secondary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(p.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                          PillChip(label: p.tag),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.content, style: const TextStyle(fontSize: 13)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.favorite_border, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text('${p.likes}', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 4),
                          Text('${p.comments}', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
