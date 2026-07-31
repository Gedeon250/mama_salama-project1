import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_models.dart';
import '../theme/app_theme.dart';
import '../utils/form_validators.dart';

/// Pending local file chosen for upload (not yet on Cloudinary).
class PendingPregnancyFile {
  final File file;
  final String fileName;

  PendingPregnancyFile({required this.file, required this.fileName});
}

/// Lists existing + pending pregnancy attachments with add/remove and share switch.
class PregnancyAttachmentsEditor extends StatelessWidget {
  final List<PregnancyAttachment> existing;
  final List<PendingPregnancyFile> pending;
  final bool shareWithChw;
  final ValueChanged<bool> onShareChanged;
  final ValueChanged<List<PregnancyAttachment>> onExistingChanged;
  final ValueChanged<List<PendingPregnancyFile>> onPendingChanged;
  final void Function(String message) onError;

  const PregnancyAttachmentsEditor({
    super.key,
    required this.existing,
    required this.pending,
    required this.shareWithChw,
    required this.onShareChanged,
    required this.onExistingChanged,
    required this.onPendingChanged,
    required this.onError,
  });

  int get _totalCount => existing.length + pending.length;

  Future<void> _pick(BuildContext context) async {
    if (_totalCount >= FormValidators.maxPregnancyAttachments) {
      onError('You can attach up to ${FormValidators.maxPregnancyAttachments} files.');
      return;
    }
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: FormValidators.attachmentExtensions,
      allowMultiple: true,
    );
    if (result == null) return;

    final next = List<PendingPregnancyFile>.from(pending);
    for (final f in result.files) {
      if (existing.length + next.length >= FormValidators.maxPregnancyAttachments) {
        onError('You can attach up to ${FormValidators.maxPregnancyAttachments} files.');
        break;
      }
      if (f.path == null) continue;
      final file = File(f.path!);
      final error = FormValidators.validateAttachment(file);
      if (error != null) {
        onError('${f.name}: $error');
        continue;
      }
      next.add(PendingPregnancyFile(file: file, fileName: f.name));
    }
    onPendingChanged(next);
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      onError('Could not open file.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Documents (PDF or images, max 5 MB each)', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        ...existing.asMap().entries.map((e) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.attach_file, color: AppColors.primary),
            title: Text(e.value.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                final next = List<PregnancyAttachment>.from(existing)..removeAt(e.key);
                onExistingChanged(next);
              },
            ),
            onTap: () => _openUrl(context, e.value.url),
          );
        }),
        ...pending.asMap().entries.map((e) {
          return ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: Icon(Icons.upload_file, color: AppColors.secondary),
            title: Text(e.value.fileName, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text('Will upload on save'),
            trailing: IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.error),
              onPressed: () {
                final next = List<PendingPregnancyFile>.from(pending)..removeAt(e.key);
                onPendingChanged(next);
              },
            ),
          );
        }),
        TextButton.icon(
          onPressed: _totalCount >= FormValidators.maxPregnancyAttachments ? null : () => _pick(context),
          icon: const Icon(Icons.add),
          label: Text('Add document (${_totalCount}/${FormValidators.maxPregnancyAttachments})'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Share documents with my health worker'),
          subtitle: const Text('Your assigned CHW can open these files when enabled'),
          value: shareWithChw,
          activeThumbColor: AppColors.primary,
          onChanged: onShareChanged,
        ),
      ],
    );
  }
}
