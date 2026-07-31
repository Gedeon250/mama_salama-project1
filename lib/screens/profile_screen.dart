import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/app_data.dart';
import '../providers/locale_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/firestore_service.dart';
import '../services/notification_prefs.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/user_avatar.dart';

const _localeNames = {
  'en': 'English',
  'fr': 'Français',
  'rw': 'Kinyarwanda',
  'sw': 'Kiswahili',
};

const _roleIcons = {
  UserRole.mother: Icons.pregnant_woman,
  UserRole.chw: Icons.volunteer_activism,
  UserRole.admin: Icons.admin_panel_settings,
  UserRole.hospital: Icons.local_hospital,
  UserRole.chwApplicant: Icons.volunteer_activism,
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _uploadingPhoto = false;
  final _firestore = FirestoreService();
  final _cloudinary = CloudinaryService();

  @override
  void initState() {
    super.initState();
    NotificationPrefs.isEnabled().then((v) {
      if (mounted) setState(() => _notifications = v);
    });
  }

  Future<void> _onNotificationsToggle(bool value) async {
    await NotificationPrefs.setEnabled(value);
    if (mounted) setState(() => _notifications = value);
  }

  Future<void> _changePhoto(AppUser user) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;

    final picked = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final url = await _cloudinary.uploadProfilePicture(user.uid, File(picked.path));
      await _firestore.updateUserProfile(user.uid, photoUrl: url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not upload photo: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _showEditProfileSheet(BuildContext context, AppUser user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.edgeMargin,
            right: AppSpacing.edgeMargin,
            top: AppSpacing.md,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Edit Profile', style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone (optional)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: user.email,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Email (can\'t be changed here)'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: saving
                        ? null
                        : () async {
                            if (!(formKey.currentState?.validate() ?? false)) return;
                            setSheetState(() => saving = true);
                            await _firestore.updateUserProfile(
                              user.uid,
                              name: nameController.text.trim(),
                              phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                            );
                            if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                          },
                    child: saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showEmergencyContactsSheet(BuildContext context, AppUser user) async {
    final contacts = List<EmergencyContact>.from(user.emergencyContacts);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.edgeMargin,
              right: AppSpacing.edgeMargin,
              top: AppSpacing.md,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.md,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Contacts', style: Theme.of(sheetContext).textTheme.headlineSmall),
                const SizedBox(height: 12),
                if (contacts.isEmpty)
                  Text('No contacts yet.', style: TextStyle(color: AppColors.secondary)),
                ...contacts.asMap().entries.map((e) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(e.value.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(e.value.phone),
                    trailing: IconButton(
                      icon: Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => setSheetState(() => contacts.removeAt(e.key)),
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () async {
                    final nameController = TextEditingController();
                    final phoneController = TextEditingController();
                    final added = await showDialog<EmergencyContact>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Add contact'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), autofocus: true),
                            const SizedBox(height: 12),
                            TextField(controller: phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () {
                              final name = nameController.text.trim();
                              final phone = phoneController.text.trim();
                              if (name.isEmpty || phone.isEmpty) return;
                              Navigator.pop(dialogContext, EmergencyContact(name: name, phone: phone));
                            },
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    );
                    if (added != null) setSheetState(() => contacts.add(added));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add contact'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await _firestore.updateUserProfile(user.uid, emergencyContacts: contacts);
                      if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLanguagePicker(BuildContext context) {
    final localeProvider = context.read<LocaleProvider>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(AppSpacing.sm),
              child: Text('Choose a language', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
            ...LocaleProvider.supportedLocales.map((locale) {
              final selected = locale.languageCode == localeProvider.locale.languageCode;
              return ListTile(
                title: Text(_localeNames[locale.languageCode] ?? locale.languageCode),
                trailing: selected ? Icon(Icons.check, color: AppColors.primary) : null,
                onTap: () {
                  localeProvider.setLocale(locale);
                  Navigator.of(sheetContext).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(BuildContext context) async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Change Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: currentController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Current password'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: newController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'New password'),
                  validator: (v) => (v == null || v.length < 6) ? 'At least 6 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Confirm new password'),
                  validator: (v) => v != newController.text ? 'Passwords do not match' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: submitting
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() => submitting = true);
                      final session = context.read<SessionProvider>();
                      final ok = await session.changePassword(
                        currentPassword: currentController.text,
                        newPassword: newController.text,
                      );
                      setDialogState(() => submitting = false);
                      if (ok) {
                        if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Password updated.')),
                          );
                        }
                      } else if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text(session.error ?? 'Could not update password.')),
                        );
                      }
                    },
              child: submitting
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final themeProvider = context.watch<ThemeModeProvider>();
    final user = context.watch<SessionProvider>().currentUser!;
    final isMother = user.role == UserRole.mother;

    return Scaffold(
      appBar: const MamaAppBar(title: 'Profile'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.edgeMargin, AppSpacing.sm, AppSpacing.edgeMargin, AppSpacing.xl,
        ),
        children: [
          Center(
            child: Column(
              children: [
                _uploadingPhoto
                    ? const SizedBox(height: 80, width: 80, child: CircularProgressIndicator())
                    : UserAvatar(
                        photoUrl: user.photoUrl,
                        radius: 40,
                        icon: _roleIcons[user.role] ?? Icons.person,
                        onTap: () => _changePhoto(user),
                      ),
                const SizedBox(height: 12),
                Text(user.name, style: Theme.of(context).textTheme.headlineSmall),
                Text(user.email, style: TextStyle(color: AppColors.secondary, fontSize: 13)),
                if (isMother)
                  Consumer<AppData>(
                    builder: (context, data, _) {
                      return StreamBuilder<PregnancyProfile>(
                        stream: FirestoreService().watchPregnancyProfile(user.uid),
                        builder: (context, snapshot) {
                          final p = snapshot.data;
                          if (p == null) return const SizedBox.shrink();
                          return Text('Week ${p.pregnancyWeek} · Trimester ${p.trimester}', style: TextStyle(color: AppColors.secondary));
                        },
                      );
                    },
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _showEditProfileSheet(context, user),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Settings'),
          const SizedBox(height: 12),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: themeProvider.isDark,
                  onChanged: (v) => themeProvider.setDarkMode(v),
                  activeColor: AppColors.primary,
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifications,
                  onChanged: _onNotificationsToggle,
                  activeColor: AppColors.primary,
                  title: const Text('Notifications'),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const SectionHeader(title: 'Account'),
          const SizedBox(height: 12),
          BentoCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _tile(
                  Icons.language_outlined,
                  'Language',
                  _localeNames[localeProvider.locale.languageCode] ?? localeProvider.locale.languageCode,
                  onTap: () => _showLanguagePicker(context),
                ),
                const Divider(height: 1),
                if (isMother) ...[
                  _tile(
                    Icons.emergency_outlined,
                    'Emergency Contacts',
                    user.emergencyContacts.isEmpty
                        ? 'None saved'
                        : '${user.emergencyContacts.length} contact${user.emergencyContacts.length == 1 ? '' : 's'}',
                    onTap: () => _showEmergencyContactsSheet(context, user),
                  ),
                  const Divider(height: 1),
                  _tile(Icons.accessibility_new_outlined, 'Accessibility', 'Large text, screen reader'),
                  const Divider(height: 1),
                ],
                _tile(Icons.lock_outline, 'Privacy & Password', '', onTap: () => _showChangePasswordDialog(context)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<SessionProvider>().signOut(),
              icon: Icon(Icons.logout, color: AppColors.error),
              label: Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: Icon(Icons.chevron_right, color: AppColors.outline),
      onTap: onTap,
    );
  }
}
