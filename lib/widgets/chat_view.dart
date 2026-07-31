import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart' as intl;
import 'package:url_launcher/url_launcher.dart';

import '../models/user_models.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../utils/form_validators.dart';
import 'user_avatar.dart';

/// A self-contained chat screen for exactly two participants. Used for:
///  - Mother <-> assigned CHW
///  - Admin <-> a CHW
class ChatView extends StatefulWidget {
  final String currentUserId;
  final String currentUserName;
  final String? currentUserPhotoUrl;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final String appBarTitle;

  const ChatView({
    super.key,
    required this.currentUserId,
    required this.currentUserName,
    this.currentUserPhotoUrl,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.appBarTitle,
  });

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();
  final _controller = TextEditingController();
  late final String _threadId;
  String? _otherPhotoUrl;
  String _otherName = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _threadId = _firestore.threadIdFor(widget.currentUserId, widget.otherUserId);
    _otherPhotoUrl = widget.otherUserPhotoUrl;
    _otherName = widget.otherUserName;
    if (_otherPhotoUrl == null || _otherPhotoUrl!.isEmpty) {
      _firestore.getUserById(widget.otherUserId).then((user) {
        if (!mounted || user == null) return;
        setState(() {
          _otherPhotoUrl = user.photoUrl;
          if (_otherName.isEmpty || _otherName == 'User') _otherName = user.name;
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send({
    String? attachmentUrl,
    ChatAttachmentType? attachmentType,
    String? attachmentName,
  }) async {
    final text = _controller.text.trim();
    final hasAttachment = attachmentUrl != null;
    if (text.isEmpty && !hasAttachment) return;

    await _firestore.sendMessage(
      threadId: _threadId,
      senderId: widget.currentUserId,
      senderName: widget.currentUserName,
      text: text,
      attachmentUrl: attachmentUrl,
      attachmentType: attachmentType,
      attachmentName: attachmentName,
    );
    if (mounted) _controller.clear();
  }

  Future<void> _pickAttachment() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(sheetContext, 'photo'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(sheetContext, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('PDF document'),
              onTap: () => Navigator.pop(sheetContext, 'pdf'),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !mounted) return;

    try {
      setState(() => _uploading = true);
      if (choice == 'photo' || choice == 'camera') {
        final picker = ImagePicker();
        final picked = await picker.pickImage(
          source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
          imageQuality: 85,
        );
        if (picked == null) return;
        final file = File(picked.path);
        FormValidators.assertAttachmentAllowed(file, allowedExtensions: const ['png', 'jpg', 'jpeg']);
        final url = await _cloudinary.uploadChatAttachment(_threadId, file, isImage: true);
        await _send(
          attachmentUrl: url,
          attachmentType: ChatAttachmentType.image,
          attachmentName: picked.name,
        );
      } else {
        final result = await FilePicker.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['pdf'],
        );
        if (result == null || result.files.single.path == null) return;
        final file = File(result.files.single.path!);
        FormValidators.assertAttachmentAllowed(file, allowedExtensions: const ['pdf']);
        final name = result.files.single.name;
        final url = await _cloudinary.uploadChatAttachment(_threadId, file, isImage: false);
        await _send(
          attachmentUrl: url,
          attachmentType: ChatAttachmentType.pdf,
          attachmentName: name,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not send attachment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file.')));
    }
  }

  void _showFullImage(String url) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
          body: Center(child: InteractiveViewer(child: Image.network(url))),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            UserAvatar(photoUrl: _otherPhotoUrl, radius: 18, icon: Icons.person),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _otherName.isNotEmpty ? _otherName : widget.appBarTitle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _firestore.watchMessages(_threadId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Could not load messages: ${snapshot.error}', style: TextStyle(color: AppColors.secondary)),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                if (messages.isEmpty) {
                  return Center(
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
                    return _MessageBubble(
                      message: m,
                      isMe: isMe,
                      otherPhotoUrl: _otherPhotoUrl,
                      onOpenImage: _showFullImage,
                      onOpenFile: _openUrl,
                    );
                  },
                );
              },
            ),
          ),
          if (_uploading)
            const LinearProgressIndicator(minHeight: 2),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.sm, 8, AppSpacing.edgeMargin, AppSpacing.edgeMargin),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _uploading ? null : _pickAttachment,
                    icon: Icon(Icons.add_circle_outline, color: AppColors.primary),
                    tooltip: 'Attach',
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_uploading,
                      decoration: const InputDecoration(hintText: 'Type a message...'),
                      onSubmitted: (_) => _uploading ? null : _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: _uploading ? null : () => _send(),
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

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final String? otherPhotoUrl;
  final void Function(String url) onOpenImage;
  final void Function(String url) onOpenFile;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.otherPhotoUrl,
    required this.onOpenImage,
    required this.onOpenFile,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.surfaceContainerLowest,
        border: isMe ? null : Border.all(color: AppColors.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.attachmentUrl != null) ...[
            if (message.attachmentType == ChatAttachmentType.image)
              GestureDetector(
                onTap: () => onOpenImage(message.attachmentUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Image.network(
                    message.attachmentUrl!,
                    width: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(Icons.broken_image, color: isMe ? Colors.white70 : AppColors.outline),
                  ),
                ),
              )
            else
              InkWell(
                onTap: () => onOpenFile(message.attachmentUrl!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.picture_as_pdf, color: isMe ? Colors.white : AppColors.primary, size: 22),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        message.attachmentName ?? 'Document',
                        style: TextStyle(
                          color: isMe ? Colors.white : AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            if (message.text.isNotEmpty) const SizedBox(height: 8),
          ],
          if (message.text.isNotEmpty)
            Text(message.text, style: TextStyle(color: isMe ? Colors.white : AppColors.onSurface)),
          const SizedBox(height: 2),
          Text(
            intl.DateFormat('h:mm a').format(message.sentAt),
            style: TextStyle(fontSize: 10, color: isMe ? Colors.white70 : AppColors.outline),
          ),
        ],
      ),
    );

    if (isMe) {
      return Align(alignment: Alignment.centerRight, child: bubble);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          UserAvatar(photoUrl: otherPhotoUrl, radius: 14, icon: Icons.person),
          const SizedBox(width: 6),
          Flexible(child: Align(alignment: Alignment.centerLeft, child: bubble)),
        ],
      ),
    );
  }
}
