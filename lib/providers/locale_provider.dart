import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two languages MamaSalama ships (Gap 1). Kinyarwanda is the trust
/// signal called out repeatedly in the user research; English is the fallback.
enum AppLanguage { en, rw }

String appLanguageToCode(AppLanguage l) => l == AppLanguage.rw ? 'rw' : 'en';

AppLanguage appLanguageFromCode(String? code) =>
    code == 'rw' ? AppLanguage.rw : AppLanguage.en;

/// Holds the chosen language for the whole app and persists it across launches
/// via shared_preferences. Screens read this and rebuild when it changes.
class LocaleProvider extends ChangeNotifier {
  LocaleProvider() {
    _load();
  }

  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.en;
  AppLanguage get language => _language;

  bool get isKinyarwanda => _language == AppLanguage.rw;

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = appLanguageFromCode(prefs.getString(_prefsKey));
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (language == _language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, appLanguageToCode(language));
  }

  Future<void> toggle() =>
      setLanguage(isKinyarwanda ? AppLanguage.en : AppLanguage.rw);
}
