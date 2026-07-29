import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/user_models.dart';
import 'firestore_service.dart';

/// Best-effort in-app alert for new chat messages: pops a local
/// notification when a message arrives in one of the current user's
/// threads while the app process is alive.
///
/// This is NOT push messaging — there's no FCM/Cloud Functions wiring
/// (that needs the Blaze plan, see Phase 5 of the migration guide) — so it
/// only fires while the app is running, not when fully closed. It's a
/// stopgap until that's set up.
class ChatAlertService {
  final FirestoreService firestore;
  final String myUid;
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  StreamSubscription<List<ChatThreadSummary>>? _sub;
  final Map<String, DateTime> _lastSeen = {};
  bool _first = true;

  ChatAlertService({required this.firestore, required this.myUid});

  Future<void> start() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _sub = firestore.watchMyThreads(myUid).listen((threads) async {
      for (final t in threads) {
        final seen = _lastSeen[t.threadId];
        final isNewer = seen == null || t.updatedAt.isAfter(seen);
        _lastSeen[t.threadId] = t.updatedAt;
        // Skip the very first snapshot per thread so we don't re-notify for
        // messages that already existed before this listener started.
        if (_first || !isNewer || t.lastSenderId == myUid) continue;

        final sender = await firestore.getUserById(t.lastSenderId);
        await _plugin.show(
          t.threadId.hashCode,
          sender?.name ?? 'New message',
          t.lastMessage,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'chat_messages',
              'Chat messages',
              channelDescription: 'New messages from your care team',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
        );
      }
      _first = false;
    });
  }

  void dispose() {
    _sub?.cancel();
  }
}
