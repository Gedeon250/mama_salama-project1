import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/chat_alert_service.dart';
import '../services/firestore_service.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'health_screen.dart';
import 'community_hub_screen.dart';
import 'profile_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  ChatAlertService? _chatAlerts;

  final _tabs = const [
    DashboardScreen(),
    AppointmentsScreen(),
    HealthScreen(),
    CommunityHubScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    final me = context.read<SessionProvider>().currentUser!;
    _chatAlerts = ChatAlertService(firestore: FirestoreService(), myUid: me.uid)..start();
  }

  @override
  void dispose() {
    _chatAlerts?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(child: IndexedStack(index: _index, children: _tabs)),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Visits'),
          NavigationDestination(icon: Icon(Icons.favorite_border), selectedIcon: Icon(Icons.favorite), label: 'Health'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Community'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
