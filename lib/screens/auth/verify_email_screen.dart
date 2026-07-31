import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';

/// Shown by AuthGate for a signed-in account that hasn't confirmed email yet
/// (`AppUser.emailConfirmed == false`). Applies to email/password and Google
/// signups until the user completes verification (or taps continue after
/// Firebase already marks the email verified, e.g. Google).
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    final ok = await context.read<SessionProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Verification email sent — check your inbox.'
              : "Couldn't send it right now — please wait a bit before trying again.",
        ),
      ),
    );
  }

  Future<void> _checkVerified() async {
    setState(() => _busy = true);
    final session = context.read<SessionProvider>();
    final confirmed = await session.refreshEmailVerified();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!confirmed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Still not verified — check your inbox for the link.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = context.watch<SessionProvider>().currentUser?.email ?? 'your email';
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.edgeMargin),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mark_email_unread_outlined, size: 72, color: AppColors.primary),
                const SizedBox(height: 16),
                Text('Verify your email', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Confirm $email to continue. If you signed up with email, open the link we sent, then tap "I\'ve verified". Google accounts can usually continue after tapping the button below.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondary),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _busy ? null : _checkVerified,
                    child: _busy
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("I've verified — Continue"),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : _resend,
                  child: const Text('Resend verification email'),
                ),
                TextButton(
                  onPressed: () => context.read<SessionProvider>().signOut(),
                  child: Text('Sign Out', style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
