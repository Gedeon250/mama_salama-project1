import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current language and persists the choice across
/// restarts. Supported locales: English, Kinyarwanda, Swahili, French.
class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'locale_code';
  static const supportedLocales = [
    Locale('en'),
    Locale('rw'),
    Locale('sw'),
    Locale('fr'),
  ];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString(_prefsKey);
    if (code != null && supportedLocales.any((l) => l.languageCode == code)) {
      _locale = Locale(code);
      notifyListeners();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, locale.languageCode);
  }

  /// Cycles EN -> RW -> SW -> FR -> EN, matching the Education Center's
  /// "Change" button.
  void cycleLocale() {
    final i = supportedLocales.indexWhere((l) => l.languageCode == _locale.languageCode);
    setLocale(supportedLocales[(i + 1) % supportedLocales.length]);
  }
}
