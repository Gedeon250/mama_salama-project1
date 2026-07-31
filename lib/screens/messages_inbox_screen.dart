import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_view.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';

/// Lists the signed-in user's existing chat threads (newest first).
class MessagesInboxScreen extends StatelessWidget {
  const MessagesInboxScreen({super.key, this.embedded = false, this.useBrandAppBar = false});

  /// When true (e.g. CHW shell tab), omit Scaffold/AppBar — the shell provides
  /// chrome. Mother tabs and admin routes use a full Scaffold.
  final bool embedded;

  /// Mother shell uses the branded MamaAppBar; admin push uses a plain AppBar.
  final bool useBrandAppBar;

  @override
  Widget build(BuildContext context) {
    final me = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

    final body = StreamBuilder<List<ChatThreadSummary>>(
      stream: firestore.watchMyThreads(me.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: EmptyHint(icon: Icons.error_outline, text: 'Could not load messages: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final threads = snapshot.data!;
        if (threads.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: EmptyHint(
                icon: Icons.chat_bubble_outline,
                text: 'No conversations yet — message someone from their profile or care card.',
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl),
          itemCount: threads.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final thread = threads[i];
            return _ThreadTile(me: me, thread: thread, firestore: firestore);
          },
        );
      },
    );

    if (embedded) return body;

    return Scaffold(
      appBar: useBrandAppBar
          ? const MamaAppBar(title: 'Messages', showBack: true, showMessages: false)
          : AppBar(title: const Text('Messages')),
      body: body,
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final AppUser me;
  final ChatThreadSummary thread;
  final FirestoreService firestore;

  const _ThreadTile({required this.me, required this.thread, required this.firestore});

  @override
  Widget build(BuildContext context) {
    final unread = thread.lastSenderId != me.uid;

    return StreamBuilder<AppUser?>(
      stream: firestore.watchUserById(thread.otherUid),
      builder: (context, snap) {
        final other = snap.data;
        final name = other?.name ?? 'User';
        final photoUrl = other?.photoUrl;

        return BentoCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatView(
                currentUserId: me.uid,
                currentUserName: me.name,
                currentUserPhotoUrl: me.photoUrl,
                otherUserId: thread.otherUid,
                otherUserName: name,
                otherUserPhotoUrl: photoUrl,
                appBarTitle: name,
              ),
            ),
          ),
          child: Row(
            children: [
              UserAvatar(photoUrl: photoUrl, icon: Icons.person, radius: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatTime(thread.updatedAt),
                          style: TextStyle(fontSize: 11, color: AppColors.secondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      thread.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.secondary,
                        fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              if (unread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dt.year, dt.month, dt.day);
    if (day == today) return intl.DateFormat('h:mm a').format(dt);
    if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
    if (now.difference(dt).inDays < 7) return intl.DateFormat('EEE').format(dt);
    return intl.DateFormat('MMM d').format(dt);
  }
}
