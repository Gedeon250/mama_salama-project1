import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/session_provider.dart';
import '../../models/user_models.dart';
import '../root_shell.dart';
import '../chw/chw_shell.dart';
import '../admin/admin_shell.dart';
import 'login_screen.dart';

/// Top-level router: watches SessionProvider and shows the login flow,
/// a loading spinner, or the shell that matches the signed-in user's role.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();

    switch (session.status) {
      case SessionStatus.signedOut:
        return const LoginScreen();
      case SessionStatus.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case SessionStatus.signedIn:
        final user = session.currentUser!;
        switch (user.role) {
          case UserRole.mother:
            return const RootShell();
          case UserRole.chw:
            return const ChwShell();
          case UserRole.admin:
            return const AdminShell();
        }
    }
  }
}
