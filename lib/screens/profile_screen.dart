import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/app_data.dart';
import '../providers/locale_provider.dart';
import '../providers/session_provider.dart';
import '../providers/theme_provider.dart';
import '../services/firestore_service.dart';
import '../services/notification_prefs.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

const _localeNames = {
  'en': 'English',
  'fr': 'Français',
  'rw': 'Kinyarwanda',
  'sw': 'Kiswahili',
};

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;

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
    final data = context.watch<AppData>();
    final profile = data.profile;
    final mother = context.watch<SessionProvider>().currentUser!;
    final firestore = FirestoreService();

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
                CircleAvatar(radius: 40, backgroundColor: AppColors.secondaryContainer, child: Icon(Icons.pregnant_woman, size: 40, color: AppColors.primary)),
                const SizedBox(height: 12),
                Text(mother.name, style: Theme.of(context).textTheme.headlineSmall),
                StreamBuilder<PregnancyProfile>(
                  stream: firestore.watchPregnancyProfile(mother.uid),
                  builder: (context, snapshot) {
                    final p = snapshot.data;
                    if (p == null) return const SizedBox.shrink();
                    return Text('Week ${p.pregnancyWeek} · Trimester ${p.trimester}', style: TextStyle(color: AppColors.secondary));
                  },
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
                _tile(Icons.emergency_outlined, 'Emergency Contacts', '${profile.emergencyContactsCount} contacts'),
                const Divider(height: 1),
                _tile(Icons.accessibility_new_outlined, 'Accessibility', 'Large text, screen reader'),
                const Divider(height: 1),
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
