import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import '../models/user_models.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

/// A self-contained chat screen for exactly two participants. Used for:
///  - Mother <-> assigned CHW
///  - Admin <-> a CHW
class ChatView extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String otherUserId;
  final String otherUserName;
  final String appBarTitle;

  const ChatView({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    required this.otherUserId,
    required this.otherUserName,
    required this.appBarTitle,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _firestore = FirestoreService();
  final _controller = TextEditingController();
  late final String _threadId;

  @override
  void initState() {
    super.initState();
    _threadId = _firestore.threadIdFor(widget.currentUserId, widget.otherUserId);
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _firestore.sendMessage(
      threadId: _threadId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      text: text,
    );
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.appBarTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestore.watchMessages(_threadId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Could not load messages: ${snapshot.error}', style: const TextStyle(color: AppColors.secondary)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet — say hello.', style: TextStyle(color: AppColors.secondary)),
                  );
                }
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.edgeMargin),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[messages.length - 1 - i];
                    final isMe = m.senderId == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary : AppColors.surfaceContainerLowest,
                          border: isMe ? null : Border.all(color: AppColors.outlineVariant),
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m.text, style: TextStyle(color: isMe ? Colors.white : AppColors.onSurface)),
                            const SizedBox(height: 2),
                            Text(
                              intl.DateFormat('h:mm a').format(m.sentAt),
                              style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.outline),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _send,
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
