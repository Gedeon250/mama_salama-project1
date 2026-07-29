import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_data.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SupportGroupScreen extends StatefulWidget {
  const SupportGroupScreen({super.key});

  @override
  State<SupportGroupScreen> createState() => _SupportGroupScreenState();
}

class _SupportGroupScreenState extends State<SupportGroupScreen> {
  String _filter = 'All Posts';
  final _composeController = TextEditingController();

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<AppData>();
    final posts = data.supportGroupPosts.where((p) {
      if (_filter == 'All Posts') return true;
      if (_filter == 'Expert Answers') return p.isExpertAnswer;
      return p.tag == _filter;
    }).toList();

    return Scaffold(
      appBar: const MamaAppBar(title: 'Trimester 2 Support', showBack: true),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.sm),
            decoration: const BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(bottom: BorderSide(color: AppColors.outlineVariant)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Row(children: [
                            Icon(Icons.groups, color: AppColors.primary, size: 16),
                            SizedBox(width: 4),
                            Text('Community Group', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                          ]),
                          SizedBox(height: 2),
                          Text('A nurturing space for mamas navigating weeks 13-26.',
                              style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: const Column(
                        children: [
                          Text('1.2k', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          Text('Members', style: TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All Posts', 'Expert Answers', 'Morning Sickness', 'Vitamins']
                        .map((f) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: PillChip(label: f, selected: _filter == f, onTap: () => setState(() => _filter = f)),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.md),
              children: posts.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _PostCard(post: p),
                  )).toList(),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.edgeMargin),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composeController,
                      decoration: const InputDecoration(hintText: 'Share something with the group...'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      if (_composeController.text.trim().isEmpty) return;
                      data.supportGroupPosts.insert(
                        0,
                        CommunityPost(
                          author: data.profile.name,
                          content: _composeController.text.trim(),
                          tag: 'All Posts',
                          likes: 0,
                          comments: 0,
                          postedAt: DateTime.now(),
                        ),
                      );
                      _composeController.clear();
                      setState(() {});
                    },
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final CommunityPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: post.isExpertAnswer ? AppColors.primary : AppColors.secondaryContainer,
                child: Icon(post.isExpertAnswer ? Icons.verified : Icons.person, size: 16, color: post.isExpertAnswer ? Colors.white : AppColors.secondary),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(post.author, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
              PillChip(label: post.tag),
            ],
          ),
          const SizedBox(height: 8),
          Text(post.content, style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.favorite_border, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('${post.likes}', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(width: 16),
              const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('${post.comments}', style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
