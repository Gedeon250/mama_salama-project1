import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_models.dart';
import '../../providers/session_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/form_validators.dart';
import '../../widgets/pregnancy_attachments_editor.dart';

/// One-time gate after email verify for mothers who have never saved a
/// pregnancyProfile. Phone is collected here when missing (e.g. Google signup).
class PregnancyOnboardingScreen extends StatefulWidget {
  const PregnancyOnboardingScreen({super.key});

  @override
  State<PregnancyOnboardingScreen> createState() => _PregnancyOnboardingScreenState();
}

class _PregnancyOnboardingScreenState extends State<PregnancyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _weekController = TextEditingController(text: '4');
  final _bloodTypeController = TextEditingController(text: 'Unknown');
  final _allergiesController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 259));
  bool _saving = false;
  bool _shareWithChw = true;
  List<PendingPregnancyFile> _pendingFiles = [];
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();

  static const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final phone = context.read<SessionProvider>().currentUser?.phone;
      if (phone != null && phone.isNotEmpty) {
        _phoneController.text = phone;
      }
    });
  }

  @override
  void dispose() {
    _weekController.dispose();
    _bloodTypeController.dispose();
    _allergiesController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final user = context.read<SessionProvider>().currentUser!;
    setState(() => _saving = true);

    try {
      final week = int.tryParse(_weekController.text.trim()) ?? 4;
      final blood = _bloodTypeController.text.trim().isEmpty ? 'Unknown' : _bloodTypeController.text.trim();
      final allergies = _allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      final attachments = <PregnancyAttachment>[];
      for (final pending in _pendingFiles) {
        final url = await _cloudinary.uploadPregnancyAttachment(user.uid, pending.file);
        final lower = pending.fileName.toLowerCase();
        attachments.add(PregnancyAttachment(
          url: url,
          fileName: pending.fileName,
          contentType: lower.endsWith('.pdf') ? 'application/pdf' : 'image/jpeg',
          uploadedAt: DateTime.now(),
        ));
      }

      await _firestore.updatePregnancyProfile(
        user.uid,
        PregnancyProfile(
          pregnancyWeek: week.clamp(1, 42),
          dueDate: _dueDate,
          bloodType: blood,
          allergies: allergies,
          babySizeComparison: 'Poppy seed',
          isHighRisk: false,
          attachments: attachments,
          shareAttachmentsWithChw: _shareWithChw,
        ),
      );

      final phone = FormValidators.sanitizePhone(_phoneController.text);
      if (phone.isNotEmpty) {
        await _firestore.updateUserProfile(user.uid, phone: phone);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      setState(() => _saving = false);
      return;
    }

    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.edgeMargin),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.favorite_outline, color: AppColors.primary, size: 48),
                  const SizedBox(height: 12),
                  Text('Tell us about your pregnancy', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'This helps your care team support you. You can update these details anytime in Health.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondary),
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _weekController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Pregnancy week'),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1 || n > 42) return 'Enter a week between 1 and 42';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined, size: 16),
                    label: Text('Due date: ${_dueDate.year}-${_dueDate.month.toString().padLeft(2, '0')}-${_dueDate.day.toString().padLeft(2, '0')}'),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dueDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 280)),
                        lastDate: DateTime.now().add(const Duration(days: 300)),
                      );
                      if (picked != null) setState(() => _dueDate = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _bloodTypes.contains(_bloodTypeController.text) ? _bloodTypeController.text : 'Unknown',
                    decoration: const InputDecoration(labelText: 'Blood type'),
                    items: _bloodTypes.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) {
                      if (v != null) _bloodTypeController.text = v;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _allergiesController,
                    decoration: const InputDecoration(labelText: 'Allergies (optional, comma-separated)'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Phone (recommended, 10 digits)'),
                    validator: (v) => FormValidators.validatePhone(v, required: false),
                  ),
                  const SizedBox(height: 16),
                  PregnancyAttachmentsEditor(
                    existing: const [],
                    pending: _pendingFiles,
                    shareWithChw: _shareWithChw,
                    onShareChanged: (v) => setState(() => _shareWithChw = v),
                    onExistingChanged: (_) {},
                    onPendingChanged: (v) => setState(() => _pendingFiles = v),
                    onError: (msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
