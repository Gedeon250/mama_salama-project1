import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mamasalama_app/l10n/app_strings.dart';
import 'package:mamasalama_app/providers/locale_provider.dart';

void main() {
  group('translate', () {
    test('returns English and Kinyarwanda variants', () {
      expect(translate(StrKey.navHome, AppLanguage.en), 'Home');
      expect(translate(StrKey.navHome, AppLanguage.rw), 'Ahabanza');
      expect(translate(StrKey.sosTapToCall, AppLanguage.en), 'TAP TO CALL AMBULANCE');
      expect(translate(StrKey.sosTapToCall, AppLanguage.rw), 'KANDA UHAMAGARE AMBULANSI');
    });

    test('every key has both language variants', () {
      for (final key in StrKey.values) {
        expect(translate(key, AppLanguage.en), isNotEmpty, reason: 'EN missing for $key');
        expect(translate(key, AppLanguage.rw), isNotEmpty, reason: 'RW missing for $key');
      }
    });
  });

  group('language codes', () {
    test('round-trip', () {
      expect(appLanguageFromCode('rw'), AppLanguage.rw);
      expect(appLanguageFromCode('en'), AppLanguage.en);
      expect(appLanguageFromCode(null), AppLanguage.en);
      expect(appLanguageFromCode('garbage'), AppLanguage.en);
      expect(appLanguageToCode(AppLanguage.rw), 'rw');
      expect(appLanguageToCode(AppLanguage.en), 'en');
    });
  });

  group('LocaleProvider', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('defaults to English then persists changes', () async {
      final p = LocaleProvider();
      expect(p.language, AppLanguage.en);

      await p.setLanguage(AppLanguage.rw);
      expect(p.language, AppLanguage.rw);
      expect(p.isKinyarwanda, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_language'), 'rw');
    });

    test('toggle flips the language', () async {
      final p = LocaleProvider();
      await p.toggle();
      expect(p.language, AppLanguage.rw);
      await p.toggle();
      expect(p.language, AppLanguage.en);
    });

    test('loads a persisted language on construction', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'rw'});
      final p = LocaleProvider();
      // _load() is async; give it a microtask turn to complete.
      await Future<void>.delayed(Duration.zero);
      expect(p.language, AppLanguage.rw);
    });
  });
}
