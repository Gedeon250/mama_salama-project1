import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_rw.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
    Locale('rw'),
    Locale('sw')
  ];

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String helloName(Object name);

  /// No description provided for @healthSnapshotSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re doing great. Here\'s your health snapshot.'**
  String get healthSnapshotSubtitle;

  /// No description provided for @quickActionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActionsTitle;

  /// No description provided for @sosLabel.
  ///
  /// In en, this message translates to:
  /// **'SOS'**
  String get sosLabel;

  /// No description provided for @recordsLabel.
  ///
  /// In en, this message translates to:
  /// **'Records'**
  String get recordsLabel;

  /// No description provided for @learnLabel.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnLabel;

  /// No description provided for @askAiLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get askAiLabel;

  /// No description provided for @yourCareTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Care Team'**
  String get yourCareTeamTitle;

  /// No description provided for @yourAssignedHealthWorker.
  ///
  /// In en, this message translates to:
  /// **'Your assigned health worker'**
  String get yourAssignedHealthWorker;

  /// No description provided for @healthWorkerFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Health Worker'**
  String get healthWorkerFallbackName;

  /// No description provided for @messageButton.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageButton;

  /// No description provided for @noHealthWorkerAssigned.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have a health worker assigned yet. Send a request below and an admin will connect you with one.'**
  String get noHealthWorkerAssigned;

  /// No description provided for @describeHelpHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you need help with...'**
  String get describeHelpHint;

  /// No description provided for @requestHelpButton.
  ///
  /// In en, this message translates to:
  /// **'Request Help'**
  String get requestHelpButton;

  /// No description provided for @helpRequestSentSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Sent to the admin dashboard — a health worker will follow up.'**
  String get helpRequestSentSnackbar;

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @currentProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Progress'**
  String get currentProgressLabel;

  /// No description provided for @weekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {week}'**
  String weekLabel(Object week);

  /// No description provided for @trimesterLabel.
  ///
  /// In en, this message translates to:
  /// **'Trimester {trimester}'**
  String trimesterLabel(Object trimester);

  /// No description provided for @babySizeIntro.
  ///
  /// In en, this message translates to:
  /// **'Baby is the size of a'**
  String get babySizeIntro;

  /// No description provided for @conceptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Conception'**
  String get conceptionLabel;

  /// No description provided for @daysToDueDate.
  ///
  /// In en, this message translates to:
  /// **'{days} days to due date'**
  String daysToDueDate(Object days);

  /// No description provided for @upcomingAppointmentTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming Appointment'**
  String get upcomingAppointmentTitle;

  /// No description provided for @noUpcomingAppointments.
  ///
  /// In en, this message translates to:
  /// **'No upcoming appointments booked.'**
  String get noUpcomingAppointments;

  /// No description provided for @todaysMedicationTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Medication'**
  String get todaysMedicationTitle;

  /// No description provided for @waterIntakeTitle.
  ///
  /// In en, this message translates to:
  /// **'Water Intake'**
  String get waterIntakeTitle;

  /// No description provided for @cupsFormat.
  ///
  /// In en, this message translates to:
  /// **'{current} / {total} cups'**
  String cupsFormat(Object current, Object total);

  /// No description provided for @todaysHealthTipTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Health Tip'**
  String get todaysHealthTipTitle;

  /// No description provided for @healthTipText.
  ///
  /// In en, this message translates to:
  /// **'Eating iron-rich foods like beans and leafy greens alongside vitamin C can help your body absorb more iron.'**
  String get healthTipText;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'MamaSalama AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantBody.
  ///
  /// In en, this message translates to:
  /// **'This is a placeholder for the AI health assistant described in the PRD (pregnancy Q&A, symptom triage, nutrition advice, and Kinyarwanda / English / Swahili / French translation). Wire this up to your chosen LLM provider when the backend is ready.'**
  String get aiAssistantBody;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @couldNotLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load: {error}'**
  String couldNotLoad(Object error);

  /// No description provided for @yourJourneyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Journey'**
  String get yourJourneyTitle;

  /// No description provided for @weekTrimesterFormat.
  ///
  /// In en, this message translates to:
  /// **'Week {week} · Trimester {trimester}'**
  String weekTrimesterFormat(Object week, Object trimester);

  /// No description provided for @daysToDueDateBadge.
  ///
  /// In en, this message translates to:
  /// **'{days} Days to Due Date'**
  String daysToDueDateBadge(Object days);

  /// No description provided for @trimesterShort1.
  ///
  /// In en, this message translates to:
  /// **'T1'**
  String get trimesterShort1;

  /// No description provided for @trimesterShort2.
  ///
  /// In en, this message translates to:
  /// **'T2'**
  String get trimesterShort2;

  /// No description provided for @trimesterShort3.
  ///
  /// In en, this message translates to:
  /// **'T3'**
  String get trimesterShort3;

  /// No description provided for @babysSizeTitle.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s Size'**
  String get babysSizeTitle;

  /// No description provided for @weightTitle.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get weightTitle;

  /// No description provided for @noDataYet.
  ///
  /// In en, this message translates to:
  /// **'No data yet'**
  String get noDataYet;

  /// No description provided for @bloodPressureTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Pressure'**
  String get bloodPressureTitle;

  /// No description provided for @mmHgUnit.
  ///
  /// In en, this message translates to:
  /// **'mmHg'**
  String get mmHgUnit;

  /// No description provided for @bloodSugarTitle.
  ///
  /// In en, this message translates to:
  /// **'Blood Sugar'**
  String get bloodSugarTitle;

  /// No description provided for @quickTrackingTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Tracking'**
  String get quickTrackingTitle;

  /// No description provided for @babyKickCounterTitle.
  ///
  /// In en, this message translates to:
  /// **'Baby Kick Counter'**
  String get babyKickCounterTitle;

  /// No description provided for @kicksLoggedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} kicks logged today'**
  String kicksLoggedToday(Object count);

  /// No description provided for @kickButton.
  ///
  /// In en, this message translates to:
  /// **'Kick'**
  String get kickButton;

  /// No description provided for @contractionTimerTitle.
  ///
  /// In en, this message translates to:
  /// **'Contraction Timer'**
  String get contractionTimerTitle;

  /// No description provided for @moodTrackerTitle.
  ///
  /// In en, this message translates to:
  /// **'Mood Tracker'**
  String get moodTrackerTitle;

  /// No description provided for @recordsAndCareTitle.
  ///
  /// In en, this message translates to:
  /// **'Records & Care'**
  String get recordsAndCareTitle;

  /// No description provided for @medicalRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Medical Records'**
  String get medicalRecordsTitle;

  /// No description provided for @medicalRecordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Visit notes, ultrasounds, delivery history'**
  String get medicalRecordsSubtitle;

  /// No description provided for @labResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'Lab Results'**
  String get labResultsTitle;

  /// No description provided for @labResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Blood work, glucose, and screening results'**
  String get labResultsSubtitle;

  /// No description provided for @vaccinationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Vaccinations'**
  String get vaccinationsTitle;

  /// No description provided for @vaccinationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Mother & baby immunization schedule'**
  String get vaccinationsSubtitle;

  /// No description provided for @editPregnancyInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Pregnancy Info'**
  String get editPregnancyInfoTitle;

  /// No description provided for @pregnancyWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Pregnancy week'**
  String get pregnancyWeekLabel;

  /// No description provided for @dueDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Due date: {date}'**
  String dueDateLabel(Object date);

  /// No description provided for @bloodTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Blood type'**
  String get bloodTypeLabel;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies (comma-separated)'**
  String get allergiesLabel;

  /// No description provided for @babySizeComparisonLabel.
  ///
  /// In en, this message translates to:
  /// **'Baby\'s size comparison'**
  String get babySizeComparisonLabel;

  /// No description provided for @saveButton.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveButton;

  /// No description provided for @healthAppBarTitle.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthAppBarTitle;

  /// No description provided for @resetTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get resetTooltip;

  /// No description provided for @stopButton.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stopButton;

  /// No description provided for @startButton.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startButton;

  /// No description provided for @moodGreat.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get moodGreat;

  /// No description provided for @moodGood.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get moodGood;

  /// No description provided for @moodTired.
  ///
  /// In en, this message translates to:
  /// **'Tired'**
  String get moodTired;

  /// No description provided for @moodAnxious.
  ///
  /// In en, this message translates to:
  /// **'Anxious'**
  String get moodAnxious;

  /// No description provided for @moodLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get moodLow;

  /// No description provided for @elapsedFormat.
  ///
  /// In en, this message translates to:
  /// **'{minutes}:{seconds} elapsed'**
  String elapsedFormat(Object minutes, Object seconds);

  /// No description provided for @loggedTodayFormat.
  ///
  /// In en, this message translates to:
  /// **'{count} logged today'**
  String loggedTodayFormat(Object count);

  /// No description provided for @emergencySosTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency SOS'**
  String get emergencySosTitle;

  /// No description provided for @dispatchInProgress.
  ///
  /// In en, this message translates to:
  /// **'DISPATCH IN PROGRESS'**
  String get dispatchInProgress;

  /// No description provided for @tapToCallAmbulance.
  ///
  /// In en, this message translates to:
  /// **'TAP TO CALL AMBULANCE'**
  String get tapToCallAmbulance;

  /// No description provided for @connectingToDispatch.
  ///
  /// In en, this message translates to:
  /// **'Connecting to Emergency Dispatch'**
  String get connectingToDispatch;

  /// No description provided for @liveStatusTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Status'**
  String get liveStatusTitle;

  /// No description provided for @cancelEmergencyAlert.
  ///
  /// In en, this message translates to:
  /// **'Cancel Emergency Alert'**
  String get cancelEmergencyAlert;

  /// No description provided for @nearbyFacilitiesTitle.
  ///
  /// In en, this message translates to:
  /// **'Nearby Facilities'**
  String get nearbyFacilitiesTitle;

  /// No description provided for @emergencyContactsTitle.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContactsTitle;

  /// No description provided for @emergencyContactsNotice.
  ///
  /// In en, this message translates to:
  /// **'{count} contacts will be notified automatically when SOS is triggered. Manage them from your Profile.'**
  String emergencyContactsNotice(Object count);

  /// No description provided for @sosStep1.
  ///
  /// In en, this message translates to:
  /// **'Sending your location to the nearest hospital...'**
  String get sosStep1;

  /// No description provided for @sosStep2.
  ///
  /// In en, this message translates to:
  /// **'Notifying your assigned Community Health Worker...'**
  String get sosStep2;

  /// No description provided for @sosStep3.
  ///
  /// In en, this message translates to:
  /// **'Alerting your emergency contacts...'**
  String get sosStep3;

  /// No description provided for @sosStep4.
  ///
  /// In en, this message translates to:
  /// **'Ambulance dispatched — estimated arrival 12 minutes.'**
  String get sosStep4;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'fr', 'rw', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'fr': return AppLocalizationsFr();
    case 'rw': return AppLocalizationsRw();
    case 'sw': return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
