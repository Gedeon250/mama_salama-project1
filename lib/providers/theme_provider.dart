import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the app's current dark/light preference and persists the choice
/// across restarts, mirroring LocaleProvider's pattern.
///
/// Also exposes a static, synchronously-readable flag so AppColors (which
/// is used all over the app outside any BuildContext — static helpers,
/// PDF generation, etc.) can resolve the right palette without needing a
/// Provider lookup.
class ThemeModeProvider extends ChangeNotifier {
  static const _prefsKey = 'dark_mode_enabled';

  /// Defaults to light (false) until SharedPreferences loads, same as
  /// LocaleProvider defaulting to English until its own load completes.
  static bool _isDarkActive = false;
  static bool get isDarkModeActive => _isDarkActive;

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  ThemeModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefsKey);
    if (enabled != null) {
      _isDark = enabled;
      _isDarkActive = enabled;
      notifyListeners();
    }
  }

  Future<void> setDarkMode(bool value) async {
    if (_isDark == value) return;
    _isDark = value;
    _isDarkActive = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
