import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_models.dart';
import '../../providers/session_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Shown by AuthGate while `role == chwApplicant`. Collects application
/// details + documents, then waits for an admin to promote the account to
/// a full `chw` (see AdminShell Applications section).
class ChwApplicationScreen extends StatefulWidget {
  const ChwApplicationScreen({super.key});

  @override
  State<ChwApplicationScreen> createState() => _ChwApplicationScreenState();
}

class _ChwApplicationScreenState extends State<ChwApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _expertiseController = TextEditingController();
  final _yearsController = TextEditingController();
  final _employmentController = TextEditingController();
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();

  File? _cvFile;
  File? _proofFile;
  bool _submitting = false;
  bool _prefilled = false;

  @override
  void dispose() {
    _expertiseController.dispose();
    _yearsController.dispose();
    _employmentController.dispose();
    super.dispose();
  }

  void _prefillIfNeeded(ChwApplication? application) {
    if (_prefilled || application == null) return;
    if (application.status != ChwApplicationStatus.needsMoreInfo) return;
    _expertiseController.text = application.fieldOfExpertise;
    _yearsController.text = '${application.yearsOfExperience}';
    _employmentController.text = application.currentEmployment ?? '';
    _prefilled = true;
  }

  Future<void> _pickFile({required bool cv}) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'png', 'jpg', 'jpeg', 'doc', 'docx'],
    );
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    setState(() {
      if (cv) {
        _cvFile = file;
      } else {
        _proofFile = file;
      }
    });
  }

  Future<void> _submit(AppUser user) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cvFile == null || _proofFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach both your CV and proof of expertise.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final cvUrl = await _cloudinary.uploadChwDocument(user.uid, _cvFile!, ChwDocumentKind.cv);
      final proofUrl = await _cloudinary.uploadChwDocument(user.uid, _proofFile!, ChwDocumentKind.proofOfExpertise);
      final application = ChwApplication(
        fieldOfExpertise: _expertiseController.text.trim(),
        yearsOfExperience: int.parse(_yearsController.text.trim()),
        currentEmployment: _employmentController.text.trim().isEmpty ? null : _employmentController.text.trim(),
        cvUrl: cvUrl,
        proofOfExpertiseUrl: proofUrl,
        status: ChwApplicationStatus.pending,
        submittedAt: DateTime.now(),
      );
      await _firestore.submitChwApplication(user.uid, application);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Application submitted — an admin will review it.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not submit application: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionProvider>().currentUser!;
    final application = user.chwApplication;
    _prefillIfNeeded(application);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Worker Application'),
        actions: [
          IconButton(
            onPressed: () => context.read<SessionProvider>().signOut(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: application == null || application.status == ChwApplicationStatus.needsMoreInfo
            ? _ApplicationForm(
                formKey: _formKey,
                expertiseController: _expertiseController,
                yearsController: _yearsController,
                employmentController: _employmentController,
                cvFile: _cvFile,
                proofFile: _proofFile,
                submitting: _submitting,
                adminNote: application?.adminNote,
                onPickCv: () => _pickFile(cv: true),
                onPickProof: () => _pickFile(cv: false),
                onSubmit: () => _submit(user),
              )
            : _StatusView(application: application),
      ),
    );
  }
}

class _ApplicationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController expertiseController;
  final TextEditingController yearsController;
  final TextEditingController employmentController;
  final File? cvFile;
  final File? proofFile;
  final bool submitting;
  final String? adminNote;
  final VoidCallback onPickCv;
  final VoidCallback onPickProof;
  final VoidCallback onSubmit;

  const _ApplicationForm({
    required this.formKey,
    required this.expertiseController,
    required this.yearsController,
    required this.employmentController,
    required this.cvFile,
    required this.proofFile,
    required this.submitting,
    required this.adminNote,
    required this.onPickCv,
    required this.onPickProof,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.edgeMargin),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about your experience so an admin can approve your Health Worker account.',
              style: TextStyle(color: AppColors.secondary),
            ),
            if (adminNote != null && adminNote!.isNotEmpty) ...[
              const SizedBox(height: 12),
              BentoCard(
                color: AppColors.tertiaryContainer,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.tertiary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Admin note: $adminNote',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: expertiseController,
              decoration: const InputDecoration(labelText: 'Field of expertise'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your field of expertise' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: yearsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Years of experience'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Enter years of experience';
                final n = int.tryParse(v.trim());
                if (n == null || n < 0) return 'Enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: employmentController,
              decoration: const InputDecoration(labelText: 'Current employment (optional)'),
            ),
            const SizedBox(height: 20),
            _FilePickerTile(
              label: 'CV / résumé',
              fileName: cvFile?.path.split(Platform.pathSeparator).last,
              onPick: submitting ? null : onPickCv,
            ),
            const SizedBox(height: 12),
            _FilePickerTile(
              label: 'Proof of expertise',
              fileName: proofFile?.path.split(Platform.pathSeparator).last,
              onPick: submitting ? null : onPickProof,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: submitting ? null : onSubmit,
              child: submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Submit application'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilePickerTile extends StatelessWidget {
  final String label;
  final String? fileName;
  final VoidCallback? onPick;

  const _FilePickerTile({
    required this.label,
    required this.fileName,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return BentoCard(
      child: Row(
        children: [
          Icon(Icons.attach_file, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  fileName ?? 'No file selected',
                  style: TextStyle(fontSize: 12, color: AppColors.secondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton(onPressed: onPick, child: Text(fileName == null ? 'Choose' : 'Change')),
        ],
      ),
    );
  }
}

class _StatusView extends StatelessWidget {
  final ChwApplication application;
  const _StatusView({required this.application});

  @override
  Widget build(BuildContext context) {
    final rejected = application.status == ChwApplicationStatus.rejected;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.edgeMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              rejected ? Icons.cancel_outlined : Icons.hourglass_top_outlined,
              size: 72,
              color: rejected ? AppColors.error : AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              rejected ? 'Application not approved' : 'Application under review',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              rejected
                  ? (application.adminNote?.isNotEmpty == true
                      ? application.adminNote!
                      : 'An admin declined this application. You can sign out or contact support.')
                  : 'Thanks — an admin will review your documents and unlock Health Worker access when approved.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.secondary),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => context.read<SessionProvider>().signOut(),
              child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
