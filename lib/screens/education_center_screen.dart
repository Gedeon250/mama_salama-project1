import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/locale_provider.dart';
import '../services/firestore_service.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/audio_message_player.dart';
import 'video_lesson_screen.dart';
import 'nutrition_resources_screen.dart';

class EducationCenterScreen extends StatefulWidget {
  const EducationCenterScreen({super.key});

  @override
  State<EducationCenterScreen> createState() => _EducationCenterScreenState();
}

class _EducationCenterScreenState extends State<EducationCenterScreen> {
  String _query = '';

  // Bundled placeholder audio (Gap 2). Guarantees a working audio demo even
  // before any `audio`-format lesson is added in Firestore. Swap the .m4a
  // files under assets/audio/ for real Kinyarwanda recordings.
  static const _bundledAudio = <(String title, String asset)>[
    ('Danger signs in pregnancy', 'audio/danger_signs.m4a'),
    ('Nutrition during pregnancy', 'audio/nutrition.m4a'),
    ('Care after birth', 'audio/postpartum.m4a'),
  ];

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

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
            ),
            children: [
          Consumer<LocaleProvider>(
            builder: (context, locale, _) => Row(
              children: [
                const Icon(Icons.language, size: 18, color: AppColors.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${context.tr(StrKey.langEnglish)} | ${context.tr(StrKey.langKinyarwanda)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.secondary),
                  ),
                ),
                TextButton(
                  onPressed: locale.toggle,
                  child: Text('${context.tr(StrKey.eduChangeLanguage)} (${locale.isKinyarwanda ? 'RW' : 'EN'})'),
                ),
              ],
            ),
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

          const SectionHeader(title: 'Audio Health Messages'),
          const SizedBox(height: 12),
          ..._bundledAudio.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(child: AudioMessagePlayer(source: a.$2, title: a.$1)),
              )),
          const SizedBox(height: AppSpacing.md),

          const SectionHeader(title: 'All Topics'),
          const SizedBox(height: 12),
          if (items.isEmpty) const BentoCard(child: EmptyHint(text: 'No lessons yet — check back soon.')),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BentoCard(
                  onTap: item.format == EducationFormat.video
                      ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const VideoLessonScreen()))
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
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
                      // Audio lessons get an inline player (Gap 2). Falls back to
                      // a bundled clip if no media URL was set on the content.
                      if (item.format == EducationFormat.audio) ...[
                        const SizedBox(height: 8),
                        AudioMessagePlayer(
                          source: (item.mediaUrl == null || item.mediaUrl!.isEmpty)
                              ? 'audio/danger_signs.m4a'
                              : item.mediaUrl!,
                        ),
                      ],
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
