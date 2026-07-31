import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../services/chat_alert_service.dart';
import '../services/firestore_service.dart';
import '../l10n/app_strings.dart';
import '../widgets/common.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'health_screen.dart';
import 'community_hub_screen.dart';
import 'messages_inbox_screen.dart';
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
    MessagesInboxScreen(useBrandAppBar: true),
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
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: context.tr(StrKey.navHome)),
          NavigationDestination(icon: const Icon(Icons.event_outlined), selectedIcon: const Icon(Icons.event), label: context.tr(StrKey.navAppointments)),
          NavigationDestination(icon: const Icon(Icons.favorite_border), selectedIcon: const Icon(Icons.favorite), label: context.tr(StrKey.navHealth)),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: context.tr(StrKey.navCommunity)),
          const NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Messages'),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: context.tr(StrKey.navProfile)),
        ],
      ),
    );
  }
}
