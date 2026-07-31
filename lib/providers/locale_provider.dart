import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The two languages the hand-rolled `context.tr()` strings (see
/// lib/l10n/app_strings.dart) are translated into. The generated
/// flutter_localizations pipeline (see l10n.yaml) supports a wider set of
/// locales — [supportedLocales] — but only these two have entries in
/// app_strings.dart today.
enum AppLanguage { en, rw }

String appLanguageToCode(AppLanguage l) => l == AppLanguage.rw ? 'rw' : 'en';

AppLanguage appLanguageFromCode(String? code) =>
    code == 'rw' ? AppLanguage.rw : AppLanguage.en;

/// Holds the app's current language/locale and persists the choice across
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

  /// Backward-compatible view of [locale] for lib/l10n/app_strings.dart's
  /// two-language `context.tr()` lookup table.
  AppLanguage get language => appLanguageFromCode(_locale.languageCode);
  bool get isKinyarwanda => _locale.languageCode == 'rw';

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

  Future<void> setLanguage(AppLanguage language) => setLocale(Locale(appLanguageToCode(language)));

  Future<void> toggle() => setLanguage(isKinyarwanda ? AppLanguage.en : AppLanguage.rw);

  /// Cycles EN -> RW -> SW -> FR -> EN, matching the Education Center's
  /// "Change" button.
  void cycleLocale() {
    final i = supportedLocales.indexWhere((l) => l.languageCode == _locale.languageCode);
    setLocale(supportedLocales[(i + 1) % supportedLocales.length]);
  }
}
