import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class NutritionResourcesScreen extends StatefulWidget {
  const NutritionResourcesScreen({super.key});

  @override
  State<NutritionResourcesScreen> createState() => _NutritionResourcesScreenState();
}

class _NutritionResourcesScreenState extends State<NutritionResourcesScreen> {
  String _filter = 'All Resources';
  final _filters = const ['All Resources', 'Videos', 'Articles', 'Audio', 'Recipes'];

  final _resources = const [
    {'title': 'Foods to Avoid During Pregnancy', 'type': 'Article', 'icon': Icons.article_outlined},
    {'title': 'Iron-Rich Bean Stew Recipe', 'type': 'Recipe', 'icon': Icons.restaurant_outlined},
    {'title': 'How Much Water Should You Drink?', 'type': 'Article', 'icon': Icons.article_outlined},
    {'title': 'Calculating Your BMI', 'type': 'Article', 'icon': Icons.calculate_outlined},
    {'title': 'Morning Sickness Meal Tips', 'type': 'Audio', 'icon': Icons.headphones_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MamaAppBar(title: 'Nutrition & Diet', showBack: true),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin),
              children: _filters
                  .map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PillChip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.edgeMargin),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'Hero Resource'),
                const SizedBox(height: 12),
                BentoCard(
                  padding: EdgeInsets.zero,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: AppColors.onTertiaryContainer,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    child: const Center(
                      child: Text('Weekly Meal Planner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const SectionHeader(title: 'All Resources'),
                const SizedBox(height: 12),
                ..._resources.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: BentoCard(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: AppColors.surfaceContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                              child: Icon(r['icon'] as IconData, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Text(r['title'] as String, style: const TextStyle(fontWeight: FontWeight.w600))),
                            Text(r['type'] as String, style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
