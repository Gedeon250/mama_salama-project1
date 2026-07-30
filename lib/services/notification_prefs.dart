import 'package:shared_preferences/shared_preferences.dart';

/// Persists the Profile screen's "Notifications" toggle — read by
/// ChatAlertService before showing a local notification.
class NotificationPrefs {
  static const _key = 'chat_notifications_enabled';

  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? true;
  }

  static Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }
}
