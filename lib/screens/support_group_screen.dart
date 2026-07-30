import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SupportGroupScreen extends StatefulWidget {
  final CommunityGroup group;
  const SupportGroupScreen({super.key, required this.group});

  @override
  State<SupportGroupScreen> createState() => _SupportGroupScreenState();
}

class _SupportGroupScreenState extends State<SupportGroupScreen> {
  String _filter = 'All Posts';
  final _composeController = TextEditingController();
  final _firestore = FirestoreService();

  @override
  void dispose() {
    _composeController.dispose();
    super.dispose();
  }

  void _post(AppUser me) {
    if (_composeController.text.trim().isEmpty) return;
    // Don't await: the write future only resolves after a server
    // round-trip, which would leave the compose box stuck forever while
    // offline. The write queues locally and syncs once reconnected.
    _firestore.addCommunityPost(
      widget.group.id,
      CommunityPost(
        id: '',
        author: me.name,
        authorId: me.uid,
        content: _composeController.text.trim(),
        tag: 'All Posts',
        isExpertAnswer: me.role == UserRole.chw,
        postedAt: DateTime.now(),
      ),
    );
    _composeController.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionProvider>().currentUser!;

    return Scaffold(
      appBar: MamaAppBar(title: widget.group.name, showBack: true),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.sm),
            decoration: BoxDecoration(
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
                        children: [
                          Row(children: [
                            Icon(Icons.groups, color: AppColors.primary, size: 16),
                            const SizedBox(width: 4),
                            Text('Community Group', style: TextStyle(fontSize: 11, color: AppColors.secondary)),
                          ]),
                          const SizedBox(height: 2),
                          Text(widget.group.description, style: TextStyle(fontSize: 12, color: AppColors.secondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primaryContainer, borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Column(
                        children: [
                          Text('${widget.group.memberCount}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          const Text('Members', style: TextStyle(color: Colors.white70, fontSize: 10)),
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
            child: StreamBuilder<List<CommunityPost>>(
              stream: _firestore.watchPostsForGroup(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(padding: const EdgeInsets.all(24), child: EmptyHint(icon: Icons.error_outline, text: 'Could not load posts: ${snapshot.error}')));
                }
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final posts = snapshot.data!.where((p) {
                  if (_filter == 'All Posts') return true;
                  if (_filter == 'Expert Answers') return p.isExpertAnswer;
                  return p.tag == _filter;
                }).toList();

                if (posts.isEmpty) {
                  return const Center(child: Padding(padding: EdgeInsets.all(24), child: EmptyHint(text: 'No posts yet — be the first to share something.')));
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.md),
                  children: posts.map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _PostCard(post: p),
                      )).toList(),
                );
              },
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
                    onPressed: () => _post(me),
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
              Icon(Icons.favorite_border, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('${post.likes}', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
              const SizedBox(width: 16),
              Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.secondary),
              const SizedBox(width: 4),
              Text('${post.comments}', style: TextStyle(fontSize: 12, color: AppColors.secondary)),
            ],
          ),
        ],
      ),
    );
  }
}
