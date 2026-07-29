import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'video_lesson_screen.dart';
import 'nutrition_resources_screen.dart';

class EducationCenterScreen extends StatefulWidget {
  const EducationCenterScreen({super.key});

  @override
  State<EducationCenterScreen> createState() => _EducationCenterScreenState();
}

class _EducationCenterScreenState extends State<EducationCenterScreen> {
  String _query = '';
  String _language = 'EN';

  IconData _formatIcon(EducationFormat f) {
    switch (f) {
      case EducationFormat.video:
        return Icons.play_circle_outline;
      case EducationFormat.article:
        return Icons.article_outlined;
      case EducationFormat.audio:
        return Icons.headphones_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final items = data.educationItems
        .where((e) => _query.isEmpty || e.title.toLowerCase().contains(_query.toLowerCase()) || e.category.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Education Center', showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.language, size: 18, color: AppColors.secondary),
              const SizedBox(width: 6),
              Text('EN | RW | SW | FR', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _language = _language == 'EN' ? 'RW' : 'EN'),
                child: Text('Change ($_language)'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: const InputDecoration(
              hintText: 'Search health topics, videos...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          const SectionHeader(title: 'Featured Lesson'),
          const SizedBox(height: 12),
          BentoCard(
            padding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoLessonScreen())),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.onTertiaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                ),
                Positioned(
                  left: 16,
                  bottom: 12,
                  child: Text('Nutrition in Your Second Trimester',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: _shortcutCard(
                  context,
                  icon: Icons.restaurant_outlined,
                  label: 'Nutrition & Diet',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NutritionResourcesScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _shortcutCard(context, icon: Icons.warning_amber_outlined, label: 'Danger Signs', onTap: () {}),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          const SectionHeader(title: 'All Topics'),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  onTap: item.format == EducationFormat.video
                      ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoLessonScreen()))
                      : null,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                        child: Icon(_formatIcon(item.format), color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(item.description, style: const TextStyle(fontSize: 12, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                PillChip(label: item.category),
                                const SizedBox(width: 6),
                                Text(item.durationOrLength, style: const TextStyle(fontSize: 11, color: AppColors.outline)),
                              ],
                            ),
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

  Widget _shortcutCard(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return BentoCard(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
