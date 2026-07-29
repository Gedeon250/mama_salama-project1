import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/app_data.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MamaSalamaApp());
}

class MamaSalamaApp extends StatelessWidget {
  const MamaSalamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Mother-side mock data (pregnancy tracking, appointments, etc.) --
        // still local/offline until that part of the backend is built.
        ChangeNotifierProvider(create: (_) => AppData()),
        // Real Firebase-backed session: auth + role + live requests/chat.
        ChangeNotifierProvider(create: (_) => SessionProvider(AuthService())),
      ],
      child: MaterialApp(
        title: 'MamaSalama',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const AuthGate(),
      ),
    );
  }
}
