// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String helloName(Object name) {
    return 'Habari, $name!';
  }

  @override
  String get healthSnapshotSubtitle => 'Unaendelea vizuri. Hii hapa muhtasari wa afya yako.';

  @override
  String get quickActionsTitle => 'Vitendo vya Haraka';

  @override
  String get sosLabel => 'SOS';

  @override
  String get recordsLabel => 'Rekodi';

  @override
  String get learnLabel => 'Jifunze';

  @override
  String get askAiLabel => 'Uliza AI';

  @override
  String get yourCareTeamTitle => 'Timu Yako ya Huduma';

  @override
  String get yourAssignedHealthWorker => 'Mfanyakazi wako wa afya aliyeteuliwa';

  @override
  String get healthWorkerFallbackName => 'Mfanyakazi wa Afya';

  @override
  String get messageButton => 'Tuma Ujumbe';

  @override
  String get noHealthWorkerAssigned => 'Bado hujapangiwa mfanyakazi wa afya. Tuma ombi hapa chini na msimamizi atakuunganisha na mmoja.';

  @override
  String get describeHelpHint => 'Eleza msaada unaohitaji...';

  @override
  String get requestHelpButton => 'Omba Msaada';

  @override
  String get helpRequestSentSnackbar => 'Imetumwa kwa dashibodi ya msimamizi — mfanyakazi wa afya atafuatilia.';

  @override
  String get messagesTitle => 'Ujumbe';

  @override
  String get currentProgressLabel => 'Maendeleo ya Sasa';

  @override
  String weekLabel(Object week) {
    return 'Wiki $week';
  }

  @override
  String trimesterLabel(Object trimester) {
    return 'Trimester $trimester';
  }

  @override
  String get babySizeIntro => 'Mtoto ana ukubwa wa';

  @override
  String get conceptionLabel => 'Mimba Kuanza';

  @override
  String daysToDueDate(Object days) {
    return 'Siku $days kabla ya tarehe ya kujifungua';
  }

  @override
  String get upcomingAppointmentTitle => 'Miadi Ijayo';

  @override
  String get noUpcomingAppointments => 'Hakuna miadi iliyopangwa.';

  @override
  String get todaysMedicationTitle => 'Dawa za Leo';

  @override
  String get waterIntakeTitle => 'Unywaji wa Maji';

  @override
  String cupsFormat(Object current, Object total) {
    return 'Vikombe $current / $total';
  }

  @override
  String get todaysHealthTipTitle => 'Kidokezo cha Afya cha Leo';

  @override
  String get healthTipText => 'Kula vyakula vyenye madini ya chuma kama maharage na mboga za majani pamoja na vitamini C husaidia mwili kunyonya chuma zaidi.';

  @override
  String get aiAssistantTitle => 'Msaidizi wa AI wa MamaSalama';

  @override
  String get aiAssistantBody => 'Hii ni nafasi ya muda ya msaidizi wa afya wa AI ulioelezwa katika PRD (maswali ya ujauzito, uchunguzi wa dalili, ushauri wa lishe, na tafsiri ya Kinyarwanda / Kiingereza / Kiswahili / Kifaransa). Unganisha na mtoa huduma wa LLM utakayemchagua backend itakapokuwa tayari.';

  @override
  String get gotIt => 'Nimeelewa';

  @override
  String couldNotLoad(Object error) {
    return 'Imeshindwa kupakia: $error';
  }

  @override
  String get yourJourneyTitle => 'Safari Yako';

  @override
  String weekTrimesterFormat(Object week, Object trimester) {
    return 'Wiki $week · Trimester $trimester';
  }

  @override
  String daysToDueDateBadge(Object days) {
    return 'Siku $days Kabla ya Tarehe';
  }

  @override
  String get trimesterShort1 => 'T1';

  @override
  String get trimesterShort2 => 'T2';

  @override
  String get trimesterShort3 => 'T3';

  @override
  String get babysSizeTitle => 'Ukubwa wa Mtoto';

  @override
  String get weightTitle => 'Uzito';

  @override
  String get noDataYet => 'Hakuna data bado';

  @override
  String get bloodPressureTitle => 'Shinikizo la Damu';

  @override
  String get mmHgUnit => 'mmHg';

  @override
  String get bloodSugarTitle => 'Sukari ya Damu';

  @override
  String get quickTrackingTitle => 'Ufuatiliaji wa Haraka';

  @override
  String get babyKickCounterTitle => 'Kihesabu Mateke ya Mtoto';

  @override
  String kicksLoggedToday(Object count) {
    return 'Mateke $count yamerekodiwa leo';
  }

  @override
  String get kickButton => 'Teke';

  @override
  String get contractionTimerTitle => 'Kipima Muda cha Mikazo';

  @override
  String get moodTrackerTitle => 'Kifuatilia Hisia';

  @override
  String get recordsAndCareTitle => 'Rekodi na Huduma';

  @override
  String get medicalRecordsTitle => 'Rekodi za Matibabu';

  @override
  String get medicalRecordsSubtitle => 'Maelezo ya ziara, ultrasound, historia ya kujifungua';

  @override
  String get labResultsTitle => 'Matokeo ya Maabara';

  @override
  String get labResultsSubtitle => 'Uchunguzi wa damu, sukari, na vipimo vingine';

  @override
  String get vaccinationsTitle => 'Chanjo';

  @override
  String get vaccinationsSubtitle => 'Ratiba ya chanjo za mama na mtoto';

  @override
  String get editPregnancyInfoTitle => 'Hariri Taarifa za Ujauzito';

  @override
  String get pregnancyWeekLabel => 'Wiki ya ujauzito';

  @override
  String dueDateLabel(Object date) {
    return 'Tarehe ya kujifungua: $date';
  }

  @override
  String get bloodTypeLabel => 'Aina ya damu';

  @override
  String get allergiesLabel => 'Mzio (tenganisha kwa koma)';

  @override
  String get babySizeComparisonLabel => 'Ulinganifu wa ukubwa wa mtoto';

  @override
  String get saveButton => 'Hifadhi';

  @override
  String get healthAppBarTitle => 'Afya';

  @override
  String get resetTooltip => 'Weka Upya';

  @override
  String get stopButton => 'Simamisha';

  @override
  String get startButton => 'Anza';

  @override
  String get moodGreat => 'Nzuri Sana';

  @override
  String get moodGood => 'Nzuri';

  @override
  String get moodTired => 'Nimechoka';

  @override
  String get moodAnxious => 'Wasiwasi';

  @override
  String get moodLow => 'Hali Mbaya';

  @override
  String elapsedFormat(Object minutes, Object seconds) {
    return '$minutes:$seconds imepita';
  }

  @override
  String loggedTodayFormat(Object count) {
    return '$count zimerekodiwa leo';
  }

  @override
  String get emergencySosTitle => 'SOS ya Dharura';

  @override
  String get dispatchInProgress => 'USAFIRISHAJI UNAENDELEA';

  @override
  String get tapToCallAmbulance => 'GUSA KUPIGA AMBULANSI';

  @override
  String get connectingToDispatch => 'Inaunganisha na Dharura';

  @override
  String get liveStatusTitle => 'Hali ya Sasa';

  @override
  String get cancelEmergencyAlert => 'Ghairi Tahadhari ya Dharura';

  @override
  String get nearbyFacilitiesTitle => 'Vituo vya Karibu';

  @override
  String get emergencyContactsTitle => 'Anwani za Dharura';

  @override
  String emergencyContactsNotice(Object count) {
    return 'Watu $count watajulishwa kiotomatiki SOS inapoanzishwa. Wasimamie kutoka kwenye Wasifu wako.';
  }

  @override
  String get sosStep1 => 'Inatuma eneo lako kwa hospitali iliyo karibu...';

  @override
  String get sosStep2 => 'Inamjulisha Mfanyakazi wako wa Afya wa Jamii...';

  @override
  String get sosStep3 => 'Inawajulisha anwani zako za dharura...';

  @override
  String get sosStep4 => 'Ambulansi imetumwa — inakadiriwa kufika dakika 12.';
}
