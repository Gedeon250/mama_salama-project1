// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Kinyarwanda (`rw`).
class AppLocalizationsRw extends AppLocalizations {
  AppLocalizationsRw([String locale = 'rw']) : super(locale);

  @override
  String helloName(Object name) {
    return 'Muraho, $name!';
  }

  @override
  String get healthSnapshotSubtitle =>
      'Uragenda neza. Dore incamake y\'ubuzima bwawe.';

  @override
  String get quickActionsTitle => 'Ibikorwa byihuse';

  @override
  String get sosLabel => 'SOS';

  @override
  String get recordsLabel => 'Inyandiko';

  @override
  String get learnLabel => 'Kwiga';

  @override
  String get askAiLabel => 'Baza AI';

  @override
  String get yourCareTeamTitle => 'Itsinda ryawe rikuvuza';

  @override
  String get yourAssignedHealthWorker => 'Umujyanama wawe w\'ubuzima';

  @override
  String get healthWorkerFallbackName => 'Umujyanama w\'Ubuzima';

  @override
  String get messageButton => 'Ohereza ubutumwa';

  @override
  String get noHealthWorkerAssigned =>
      'Nta mujyanama w\'ubuzima wahawe. Ohereza ubusabe hepfo maze umuyobozi azaguhuza n\'umwe.';

  @override
  String get describeHelpHint => 'Sobanura ubufasha ukeneye...';

  @override
  String get requestHelpButton => 'Saba Ubufasha';

  @override
  String get helpRequestSentSnackbar =>
      'Byoherejwe ku muyobozi — umujyanama w\'ubuzima azagusubiza vuba.';

  @override
  String get messagesTitle => 'Ubutumwa';

  @override
  String get currentProgressLabel => 'Aho ugeze';

  @override
  String weekLabel(Object week) {
    return 'Icyumweru $week';
  }

  @override
  String trimesterLabel(Object trimester) {
    return 'Igihembwe $trimester';
  }

  @override
  String get babySizeIntro => 'Umwana afite ingano ya';

  @override
  String get conceptionLabel => 'Inda yatangiye';

  @override
  String daysToDueDate(Object days) {
    return 'Iminsi $days isigaye ngo ubyare';
  }

  @override
  String get upcomingAppointmentTitle => 'Gahunda Iri Imbere';

  @override
  String get noUpcomingAppointments => 'Nta gahunda ufite.';

  @override
  String get todaysMedicationTitle => 'Imiti y\'uyu munsi';

  @override
  String get waterIntakeTitle => 'Amazi wanyoye';

  @override
  String cupsFormat(Object current, Object total) {
    return 'Ibikombe $current / $total';
  }

  @override
  String get todaysHealthTipTitle => 'Inama y\'ubuzima y\'uyu munsi';

  @override
  String get healthTipText =>
      'Kurya ibiryo birimo icyuma nk\'ibishyimbo n\'imboga z\'icyatsi hamwe na vitamini C bifasha umubiri gukoresha icyuma neza.';

  @override
  String get aiAssistantTitle => 'Umufasha wa AI wa MamaSalama';

  @override
  String get aiAssistantBody =>
      'Iki ni ikimenyetso cy\'umufasha wa AI uzavugwa muri PRD (ibibazo ku mimerere y\'inda, gusuzuma ibimenyetso, inama ku mirire, n\'ubuhinduzi mu Kinyarwanda / Icyongereza / Gisiwahili / Igifaransa). Huza na LLM uzahitamo igihe backend izaba iteguye.';

  @override
  String get gotIt => 'Ndabyumvise';

  @override
  String couldNotLoad(Object error) {
    return 'Ntibyashobotse gutangira: $error';
  }

  @override
  String get yourJourneyTitle => 'Urugendo rwawe';

  @override
  String weekTrimesterFormat(Object week, Object trimester) {
    return 'Icyumweru $week · Igihembwe $trimester';
  }

  @override
  String daysToDueDateBadge(Object days) {
    return 'Iminsi $days Isigaye';
  }

  @override
  String get trimesterShort1 => 'T1';

  @override
  String get trimesterShort2 => 'T2';

  @override
  String get trimesterShort3 => 'T3';

  @override
  String get babysSizeTitle => 'Ingano y\'umwana';

  @override
  String get weightTitle => 'Uburemere';

  @override
  String get noDataYet => 'Nta makuru arahari';

  @override
  String get bloodPressureTitle => 'Umuvuduko w\'amaraso';

  @override
  String get mmHgUnit => 'mmHg';

  @override
  String get bloodSugarTitle => 'Isukari mu maraso';

  @override
  String get quickTrackingTitle => 'Gukurikirana byihuse';

  @override
  String get babyKickCounterTitle => 'Kubara uko umwana yinyeganyeza';

  @override
  String kicksLoggedToday(Object count) {
    return 'Inshuro $count zanditswe uyu munsi';
  }

  @override
  String get kickButton => 'Yinyeganyeza';

  @override
  String get contractionTimerTitle => 'Igihe cy\'ibise';

  @override
  String get moodTrackerTitle => 'Uko wiyumva';

  @override
  String get recordsAndCareTitle => 'Inyandiko n\'Ubuvuzi';

  @override
  String get medicalRecordsTitle => 'Inyandiko z\'Ubuvuzi';

  @override
  String get medicalRecordsSubtitle =>
      'Inyandiko z\'ibyavuye mu isuzuma, ultrasound, no kubyara';

  @override
  String get labResultsTitle => 'Ibisubizo bya Laboratwari';

  @override
  String get labResultsSubtitle =>
      'Isuzuma ry\'amaraso, isukari, n\'ibindi bipimo';

  @override
  String get vaccinationsTitle => 'Inkingo';

  @override
  String get vaccinationsSubtitle => 'Gahunda y\'inkingo z\'umubyeyi n\'umwana';

  @override
  String get editPregnancyInfoTitle => 'Hindura Amakuru y\'Inda';

  @override
  String get pregnancyWeekLabel => 'Icyumweru cy\'inda';

  @override
  String dueDateLabel(Object date) {
    return 'Itariki yo kubyara: $date';
  }

  @override
  String get bloodTypeLabel => 'Ubwoko bw\'amaraso';

  @override
  String get allergiesLabel => 'Ingaruka z\'ibiribwa (tandukanya n\'akitso)';

  @override
  String get babySizeComparisonLabel => 'Ingano y\'umwana bigereranyije';

  @override
  String get saveButton => 'Bika';

  @override
  String get healthAppBarTitle => 'Ubuzima';

  @override
  String get resetTooltip => 'Subiza kuri Zero';

  @override
  String get stopButton => 'Hagarika';

  @override
  String get startButton => 'Tangira';

  @override
  String get moodGreat => 'Byiza cyane';

  @override
  String get moodGood => 'Byiza';

  @override
  String get moodTired => 'Ndananiwe';

  @override
  String get moodAnxious => 'Ndaraye';

  @override
  String get moodLow => 'Ntabwo Meze Neza';

  @override
  String elapsedFormat(Object minutes, Object seconds) {
    return '$minutes:$seconds byarengeje';
  }

  @override
  String loggedTodayFormat(Object count) {
    return '$count byanditswe uyu munsi';
  }

  @override
  String get emergencySosTitle => 'SOS y\'Ibyihutirwa';

  @override
  String get dispatchInProgress => 'GUTUMA BIRI KUGENDA';

  @override
  String get tapToCallAmbulance => 'KANDA UHAMAGARE AMBULANCE';

  @override
  String get connectingToDispatch => 'Guhuza n\'Ibyihutirwa';

  @override
  String get liveStatusTitle => 'Uko Bimeze Ubu';

  @override
  String get cancelEmergencyAlert => 'Hagarika Iyi Menyesha ry\'Ibyihutirwa';

  @override
  String get nearbyFacilitiesTitle => 'Ibigo Biri Hafi';

  @override
  String get emergencyContactsTitle => 'Abo Guhamagara mu Byihutirwa';

  @override
  String emergencyContactsNotice(Object count) {
    return 'Abantu $count bazamenyeshwa buri gihe SOS itanzwe. Babugenzure uva kuri Porofili yawe.';
  }

  @override
  String get sosStep1 => 'Kohereza aho uherereye ku bitaro biri hafi...';

  @override
  String get sosStep2 => 'Kumenyesha Umujyanama wawe w\'Ubuzima...';

  @override
  String get sosStep3 => 'Kumenyesha abo guhamagara mu byihutirwa...';

  @override
  String get sosStep4 => 'Ambulance yatumwe — igera mu minota 12.';
}
