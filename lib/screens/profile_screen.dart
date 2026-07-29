import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_models.dart';
import '../providers/app_data.dart';
import '../providers/session_provider.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _biometric = false;

  @override
  Widget build(BuildContext context) {
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
                const CircleAvatar(radius: 40, backgroundColor: AppColors.secondaryContainer, child: Icon(Icons.pregnant_woman, size: 40, color: AppColors.primary)),
                const SizedBox(height: 12),
                Text(mother.name, style: Theme.of(context).textTheme.headlineSmall),
                StreamBuilder<PregnancyProfile>(
                  stream: firestore.watchPregnancyProfile(mother.uid),
                  builder: (context, snapshot) {
                    final p = snapshot.data;
                    if (p == null) return const SizedBox.shrink();
                    return Text('Week ${p.pregnancyWeek} · Trimester ${p.trimester}', style: const TextStyle(color: AppColors.secondary));
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
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                  activeColor: AppColors.primary,
                  title: const Text('Dark Mode'),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _notifications,
                  onChanged: (v) => setState(() => _notifications = v),
                  activeColor: AppColors.primary,
                  title: const Text('Notifications'),
                  secondary: const Icon(Icons.notifications_outlined),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _biometric,
                  onChanged: (v) => setState(() => _biometric = v),
                  activeColor: AppColors.primary,
                  title: const Text('Biometric Login'),
                  secondary: const Icon(Icons.fingerprint),
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
                _tile(Icons.language_outlined, 'Language', 'English'),
                const Divider(height: 1),
                _tile(Icons.emergency_outlined, 'Emergency Contacts', '${profile.emergencyContactsCount} contacts'),
                const Divider(height: 1),
                _tile(Icons.accessibility_new_outlined, 'Accessibility', 'Large text, screen reader'),
                const Divider(height: 1),
                _tile(Icons.lock_outline, 'Privacy & Password', ''),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.read<SessionProvider>().signOut(),
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title),
      subtitle: subtitle.isEmpty ? null : Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: AppColors.outline),
    );
  }
}
