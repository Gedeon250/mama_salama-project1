// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String helloName(Object name) {
    return 'Hello, $name!';
  }

  @override
  String get healthSnapshotSubtitle => 'You\'re doing great. Here\'s your health snapshot.';

  @override
  String get quickActionsTitle => 'Quick Actions';

  @override
  String get sosLabel => 'SOS';

  @override
  String get recordsLabel => 'Records';

  @override
  String get learnLabel => 'Learn';

  @override
  String get askAiLabel => 'Ask AI';

  @override
  String get yourCareTeamTitle => 'Your Care Team';

  @override
  String get yourAssignedHealthWorker => 'Your assigned health worker';

  @override
  String get healthWorkerFallbackName => 'Health Worker';

  @override
  String get messageButton => 'Message';

  @override
  String get noHealthWorkerAssigned => 'You don\'t have a health worker assigned yet. Send a request below and an admin will connect you with one.';

  @override
  String get describeHelpHint => 'Describe what you need help with...';

  @override
  String get requestHelpButton => 'Request Help';

  @override
  String get helpRequestSentSnackbar => 'Sent to the admin dashboard — a health worker will follow up.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get currentProgressLabel => 'Current Progress';

  @override
  String weekLabel(Object week) {
    return 'Week $week';
  }

  @override
  String trimesterLabel(Object trimester) {
    return 'Trimester $trimester';
  }

  @override
  String get babySizeIntro => 'Baby is the size of a';

  @override
  String get conceptionLabel => 'Conception';

  @override
  String daysToDueDate(Object days) {
    return '$days days to due date';
  }

  @override
  String get upcomingAppointmentTitle => 'Upcoming Appointment';

  @override
  String get noUpcomingAppointments => 'No upcoming appointments booked.';

  @override
  String get todaysMedicationTitle => 'Today\'s Medication';

  @override
  String get waterIntakeTitle => 'Water Intake';

  @override
  String cupsFormat(Object current, Object total) {
    return '$current / $total cups';
  }

  @override
  String get todaysHealthTipTitle => 'Today\'s Health Tip';

  @override
  String get healthTipText => 'Eating iron-rich foods like beans and leafy greens alongside vitamin C can help your body absorb more iron.';

  @override
  String get aiAssistantTitle => 'MamaSalama AI Assistant';

  @override
  String get aiAssistantBody => 'This is a placeholder for the AI health assistant described in the PRD (pregnancy Q&A, symptom triage, nutrition advice, and Kinyarwanda / English / Swahili / French translation). Wire this up to your chosen LLM provider when the backend is ready.';

  @override
  String get gotIt => 'Got it';

  @override
  String couldNotLoad(Object error) {
    return 'Could not load: $error';
  }

  @override
  String get yourJourneyTitle => 'Your Journey';

  @override
  String weekTrimesterFormat(Object week, Object trimester) {
    return 'Week $week · Trimester $trimester';
  }

  @override
  String daysToDueDateBadge(Object days) {
    return '$days Days to Due Date';
  }

  @override
  String get trimesterShort1 => 'T1';

  @override
  String get trimesterShort2 => 'T2';

  @override
  String get trimesterShort3 => 'T3';

  @override
  String get babysSizeTitle => 'Baby\'s Size';

  @override
  String get weightTitle => 'Weight';

  @override
  String get noDataYet => 'No data yet';

  @override
  String get bloodPressureTitle => 'Blood Pressure';

  @override
  String get mmHgUnit => 'mmHg';

  @override
  String get bloodSugarTitle => 'Blood Sugar';

  @override
  String get quickTrackingTitle => 'Quick Tracking';

  @override
  String get babyKickCounterTitle => 'Baby Kick Counter';

  @override
  String kicksLoggedToday(Object count) {
    return '$count kicks logged today';
  }

  @override
  String get kickButton => 'Kick';

  @override
  String get contractionTimerTitle => 'Contraction Timer';

  @override
  String get moodTrackerTitle => 'Mood Tracker';

  @override
  String get recordsAndCareTitle => 'Records & Care';

  @override
  String get medicalRecordsTitle => 'Medical Records';

  @override
  String get medicalRecordsSubtitle => 'Visit notes, ultrasounds, delivery history';

  @override
  String get labResultsTitle => 'Lab Results';

  @override
  String get labResultsSubtitle => 'Blood work, glucose, and screening results';

  @override
  String get vaccinationsTitle => 'Vaccinations';

  @override
  String get vaccinationsSubtitle => 'Mother & baby immunization schedule';

  @override
  String get editPregnancyInfoTitle => 'Edit Pregnancy Info';

  @override
  String get pregnancyWeekLabel => 'Pregnancy week';

  @override
  String dueDateLabel(Object date) {
    return 'Due date: $date';
  }

  @override
  String get bloodTypeLabel => 'Blood type';

  @override
  String get allergiesLabel => 'Allergies (comma-separated)';

  @override
  String get babySizeComparisonLabel => 'Baby\'s size comparison';

  @override
  String get saveButton => 'Save';

  @override
  String get healthAppBarTitle => 'Health';

  @override
  String get resetTooltip => 'Reset';

  @override
  String get stopButton => 'Stop';

  @override
  String get startButton => 'Start';

  @override
  String get moodGreat => 'Great';

  @override
  String get moodGood => 'Good';

  @override
  String get moodTired => 'Tired';

  @override
  String get moodAnxious => 'Anxious';

  @override
  String get moodLow => 'Low';

  @override
  String elapsedFormat(Object minutes, Object seconds) {
    return '$minutes:$seconds elapsed';
  }

  @override
  String loggedTodayFormat(Object count) {
    return '$count logged today';
  }

  @override
  String get emergencySosTitle => 'Emergency SOS';

  @override
  String get dispatchInProgress => 'DISPATCH IN PROGRESS';

  @override
  String get tapToCallAmbulance => 'TAP TO CALL AMBULANCE';

  @override
  String get connectingToDispatch => 'Connecting to Emergency Dispatch';

  @override
  String get liveStatusTitle => 'Live Status';

  @override
  String get cancelEmergencyAlert => 'Cancel Emergency Alert';

  @override
  String get nearbyFacilitiesTitle => 'Nearby Facilities';

  @override
  String get emergencyContactsTitle => 'Emergency Contacts';

  @override
  String emergencyContactsNotice(Object count) {
    return '$count contacts will be notified automatically when SOS is triggered. Manage them from your Profile.';
  }

  @override
  String get sosStep1 => 'Sending your location to the nearest hospital...';

  @override
  String get sosStep2 => 'Notifying your assigned Community Health Worker...';

  @override
  String get sosStep3 => 'Alerting your emergency contacts...';

  @override
  String get sosStep4 => 'Ambulance dispatched — estimated arrival 12 minutes.';
}
