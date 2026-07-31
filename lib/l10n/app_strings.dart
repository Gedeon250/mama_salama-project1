import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/locale_provider.dart';

/// Keys for every translatable string on the critical path (Gap 1). Using an
/// enum instead of raw strings means a typo is a compile error, and adding a
/// key without a translation is caught by the assert in [tr].
enum StrKey {
  // Bottom navigation
  navHome,
  navAppointments,
  navHealth,
  navCommunity,
  navProfile,
  // Emergency / SOS
  emergencyTitle,
  sosTapToCall,
  sosInProgress,
  sosConnecting,
  // Common actions
  actionCancel,
  actionDone,
  actionCall,
  actionResolve,
  actionMessage,
  // Profile
  profileLanguage,
  langEnglish,
  langKinyarwanda,
  // Education
  eduChangeLanguage,
  eduListen,
  // Auth
  authSignIn,
  authSignUp,
  authEmail,
  authPassword,
  // Greetings
  greetingHello,
}

/// Best-effort Kinyarwanda translations. These were drafted by a non-native
/// speaker and MUST be reviewed by the team's Kinyarwanda speakers before
/// release; the mechanism is production-ready, the wording is not yet vetted.
const Map<StrKey, Map<AppLanguage, String>> _strings = {
  StrKey.navHome: {AppLanguage.en: 'Home', AppLanguage.rw: 'Ahabanza'},
  StrKey.navAppointments: {AppLanguage.en: 'Appointments', AppLanguage.rw: 'Gahunda'},
  StrKey.navHealth: {AppLanguage.en: 'Health', AppLanguage.rw: 'Ubuzima'},
  StrKey.navCommunity: {AppLanguage.en: 'Community', AppLanguage.rw: 'Umuryango'},
  StrKey.navProfile: {AppLanguage.en: 'Profile', AppLanguage.rw: 'Umwirondoro'},

  StrKey.emergencyTitle: {AppLanguage.en: 'Emergency SOS', AppLanguage.rw: "SOS y'Ihutirwa"},
  StrKey.sosTapToCall: {AppLanguage.en: 'TAP TO CALL AMBULANCE', AppLanguage.rw: 'KANDA UHAMAGARE AMBULANSI'},
  StrKey.sosInProgress: {AppLanguage.en: 'DISPATCH IN PROGRESS', AppLanguage.rw: 'IROHEREZWA'},
  StrKey.sosConnecting: {AppLanguage.en: 'Connecting to Emergency Dispatch', AppLanguage.rw: 'Kwihuza na serivisi yihutirwa'},

  StrKey.actionCancel: {AppLanguage.en: 'Cancel', AppLanguage.rw: 'Hagarika'},
  StrKey.actionDone: {AppLanguage.en: 'Done', AppLanguage.rw: 'Byarangiye'},
  StrKey.actionCall: {AppLanguage.en: 'Call', AppLanguage.rw: 'Hamagara'},
  StrKey.actionResolve: {AppLanguage.en: 'Resolve', AppLanguage.rw: 'Gukemura'},
  StrKey.actionMessage: {AppLanguage.en: 'Message', AppLanguage.rw: 'Ubutumwa'},

  StrKey.profileLanguage: {AppLanguage.en: 'Language', AppLanguage.rw: 'Ururimi'},
  StrKey.langEnglish: {AppLanguage.en: 'English', AppLanguage.rw: 'Icyongereza'},
  StrKey.langKinyarwanda: {AppLanguage.en: 'Kinyarwanda', AppLanguage.rw: 'Ikinyarwanda'},

  StrKey.eduChangeLanguage: {AppLanguage.en: 'Change', AppLanguage.rw: 'Hindura'},
  StrKey.eduListen: {AppLanguage.en: 'Listen', AppLanguage.rw: 'Umva'},

  StrKey.authSignIn: {AppLanguage.en: 'Sign In', AppLanguage.rw: 'Injira'},
  StrKey.authSignUp: {AppLanguage.en: 'Sign Up', AppLanguage.rw: 'Iyandikishe'},
  StrKey.authEmail: {AppLanguage.en: 'Email', AppLanguage.rw: 'Imeyili'},
  StrKey.authPassword: {AppLanguage.en: 'Password', AppLanguage.rw: 'Ijambobanga'},

  StrKey.greetingHello: {AppLanguage.en: 'Hello', AppLanguage.rw: 'Muraho'},
};

/// Look up [key] in [language], falling back to English if a translation is
/// missing (and asserting in debug so gaps surface during development).
String translate(StrKey key, AppLanguage language) {
  final entry = _strings[key];
  assert(entry != null, 'Missing translations for $key');
  final value = entry?[language] ?? entry?[AppLanguage.en];
  assert(value != null, 'Missing English fallback for $key');
  return value ?? key.name;
}

extension AppStringsX on BuildContext {
  /// Convenience: `context.tr(StrKey.navHome)` — reads the current language
  /// from [LocaleProvider] and rebuilds the caller when the language changes.
  String tr(StrKey key) =>
      translate(key, watch<LocaleProvider>().language);
}
