import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
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
    final firestore = FirestoreService();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Education Center', showBack: true),
      body: StreamBuilder<List<EducationContent>>(
        stream: firestore.watchEducationContent(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load: ${snapshot.error}')));
          }
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!
              .where((e) => _query.isEmpty || e.title.toLowerCase().contains(_query.toLowerCase()) || e.category.toLowerCase().contains(_query.toLowerCase()))
              .toList();
          final featured = items.isEmpty ? null : items.firstWhere((e) => e.format == EducationFormat.video, orElse: () => items.first);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
          Consumer<LocaleProvider>(
            builder: (context, localeProvider, _) {
              return Row(
                children: [
                  Icon(Icons.language, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 6),
                  Text('EN | RW | SW | FR', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                  const Spacer(),
                  TextButton(
                    onPressed: localeProvider.cycleLocale,
                    child: Text('Change (${localeProvider.locale.languageCode.toUpperCase()})'),
                  ),
                ],
              );
            },
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

          if (featured != null) ...[
            const SectionHeader(title: 'Featured Lesson'),
            const SizedBox(height: 12),
            BentoCard(
              padding: EdgeInsets.zero,
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoLessonScreen(item: featured))),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 160,
                      width: double.infinity,
                      child: featured.mediaUrl != null
                          ? Image.network(
                              featured.mediaUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: AppColors.onTertiaryContainer),
                            )
                          : Container(color: AppColors.onTertiaryContainer),
                    ),
                    Container(height: 160, color: Colors.black26),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                    Positioned(
                      left: 16,
                      bottom: 12,
                      right: 16,
                      child: Text(featured.title,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16, color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

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
          if (items.isEmpty) const BentoCard(child: EmptyHint(text: 'No lessons yet — check back soon.')),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => VideoLessonScreen(item: item))),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: item.mediaUrl != null
                            ? Image.network(
                                item.mediaUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 48,
                                  height: 48,
                                  color: AppColors.onTertiaryContainer,
                                  child: Icon(_formatIcon(item.format), color: AppColors.primary),
                                ),
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.onTertiaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                                child: Icon(_formatIcon(item.format), color: AppColors.primary),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                            Text(item.description, style: TextStyle(fontSize: 12, color: AppColors.secondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                PillChip(label: item.category),
                                const SizedBox(width: 6),
                                Text(item.durationOrLength, style: TextStyle(fontSize: 11, color: AppColors.outline)),
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
          );
        },
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
