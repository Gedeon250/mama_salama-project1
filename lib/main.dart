import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'providers/app_data.dart';
import 'providers/session_provider.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';
import 'screens/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Explicit even though persistence defaults to on for mobile — offline
  // reads/writes queue locally and sync once connectivity returns.
  FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
  runApp(const MamaSalamaApp());
}

class MamaSalamaApp extends StatelessWidget {
  const MamaSalamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // What's left of the original mock data (medications, profile name) --
        // everything else has moved to Firestore, see FirestoreService.
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
