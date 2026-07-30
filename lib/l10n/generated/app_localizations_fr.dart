// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String helloName(Object name) {
    return 'Bonjour, $name !';
  }

  @override
  String get healthSnapshotSubtitle => 'Vous vous portez bien. Voici un aperçu de votre santé.';

  @override
  String get quickActionsTitle => 'Actions Rapides';

  @override
  String get sosLabel => 'SOS';

  @override
  String get recordsLabel => 'Dossiers';

  @override
  String get learnLabel => 'Apprendre';

  @override
  String get askAiLabel => 'Demander à l\'IA';

  @override
  String get yourCareTeamTitle => 'Votre Équipe Soignante';

  @override
  String get yourAssignedHealthWorker => 'Votre agent de santé assigné';

  @override
  String get healthWorkerFallbackName => 'Agent de Santé';

  @override
  String get messageButton => 'Message';

  @override
  String get noHealthWorkerAssigned => 'Vous n\'avez pas encore d\'agent de santé assigné. Envoyez une demande ci-dessous et un administrateur vous mettra en relation avec un agent.';

  @override
  String get describeHelpHint => 'Décrivez l\'aide dont vous avez besoin...';

  @override
  String get requestHelpButton => 'Demander de l\'Aide';

  @override
  String get helpRequestSentSnackbar => 'Envoyé au tableau de bord de l\'administrateur — un agent de santé vous contactera.';

  @override
  String get messagesTitle => 'Messages';

  @override
  String get currentProgressLabel => 'Progression Actuelle';

  @override
  String weekLabel(Object week) {
    return 'Semaine $week';
  }

  @override
  String trimesterLabel(Object trimester) {
    return 'Trimestre $trimester';
  }

  @override
  String get babySizeIntro => 'Le bébé a la taille d\'un';

  @override
  String get conceptionLabel => 'Conception';

  @override
  String daysToDueDate(Object days) {
    return '$days jours avant la date prévue';
  }

  @override
  String get upcomingAppointmentTitle => 'Prochain Rendez-vous';

  @override
  String get noUpcomingAppointments => 'Aucun rendez-vous prévu.';

  @override
  String get todaysMedicationTitle => 'Médicaments du Jour';

  @override
  String get waterIntakeTitle => 'Consommation d\'Eau';

  @override
  String cupsFormat(Object current, Object total) {
    return '$current / $total verres';
  }

  @override
  String get todaysHealthTipTitle => 'Conseil Santé du Jour';

  @override
  String get healthTipText => 'Manger des aliments riches en fer comme les haricots et les légumes verts avec de la vitamine C aide votre corps à mieux absorber le fer.';

  @override
  String get aiAssistantTitle => 'Assistant IA MamaSalama';

  @override
  String get aiAssistantBody => 'Ceci est un espace réservé pour l\'assistant de santé IA décrit dans le PRD (questions sur la grossesse, triage des symptômes, conseils nutritionnels, et traduction en kinyarwanda / anglais / swahili / français). Connectez-le au fournisseur LLM de votre choix lorsque le backend sera prêt.';

  @override
  String get gotIt => 'Compris';

  @override
  String couldNotLoad(Object error) {
    return 'Impossible de charger : $error';
  }

  @override
  String get yourJourneyTitle => 'Votre Parcours';

  @override
  String weekTrimesterFormat(Object week, Object trimester) {
    return 'Semaine $week · Trimestre $trimester';
  }

  @override
  String daysToDueDateBadge(Object days) {
    return '$days Jours avant la Date Prévue';
  }

  @override
  String get trimesterShort1 => 'T1';

  @override
  String get trimesterShort2 => 'T2';

  @override
  String get trimesterShort3 => 'T3';

  @override
  String get babysSizeTitle => 'Taille du Bébé';

  @override
  String get weightTitle => 'Poids';

  @override
  String get noDataYet => 'Aucune donnée pour l\'instant';

  @override
  String get bloodPressureTitle => 'Tension Artérielle';

  @override
  String get mmHgUnit => 'mmHg';

  @override
  String get bloodSugarTitle => 'Glycémie';

  @override
  String get quickTrackingTitle => 'Suivi Rapide';

  @override
  String get babyKickCounterTitle => 'Compteur de Coups de Bébé';

  @override
  String kicksLoggedToday(Object count) {
    return '$count coups enregistrés aujourd\'hui';
  }

  @override
  String get kickButton => 'Coup';

  @override
  String get contractionTimerTitle => 'Minuteur de Contractions';

  @override
  String get moodTrackerTitle => 'Suivi de l\'Humeur';

  @override
  String get recordsAndCareTitle => 'Dossiers et Soins';

  @override
  String get medicalRecordsTitle => 'Dossiers Médicaux';

  @override
  String get medicalRecordsSubtitle => 'Notes de visite, échographies, historique d\'accouchement';

  @override
  String get labResultsTitle => 'Résultats de Laboratoire';

  @override
  String get labResultsSubtitle => 'Analyses de sang, glycémie, et résultats de dépistage';

  @override
  String get vaccinationsTitle => 'Vaccinations';

  @override
  String get vaccinationsSubtitle => 'Calendrier de vaccination de la mère et du bébé';

  @override
  String get editPregnancyInfoTitle => 'Modifier les Infos de Grossesse';

  @override
  String get pregnancyWeekLabel => 'Semaine de grossesse';

  @override
  String dueDateLabel(Object date) {
    return 'Date prévue : $date';
  }

  @override
  String get bloodTypeLabel => 'Groupe sanguin';

  @override
  String get allergiesLabel => 'Allergies (séparées par des virgules)';

  @override
  String get babySizeComparisonLabel => 'Comparaison de taille du bébé';

  @override
  String get saveButton => 'Enregistrer';

  @override
  String get healthAppBarTitle => 'Santé';

  @override
  String get resetTooltip => 'Réinitialiser';

  @override
  String get stopButton => 'Arrêter';

  @override
  String get startButton => 'Démarrer';

  @override
  String get moodGreat => 'Excellent';

  @override
  String get moodGood => 'Bien';

  @override
  String get moodTired => 'Fatiguée';

  @override
  String get moodAnxious => 'Anxieuse';

  @override
  String get moodLow => 'Pas Bien';

  @override
  String elapsedFormat(Object minutes, Object seconds) {
    return '$minutes:$seconds écoulées';
  }

  @override
  String loggedTodayFormat(Object count) {
    return '$count enregistrées aujourd\'hui';
  }

  @override
  String get emergencySosTitle => 'SOS d\'Urgence';

  @override
  String get dispatchInProgress => 'ENVOI EN COURS';

  @override
  String get tapToCallAmbulance => 'APPUYEZ POUR APPELER UNE AMBULANCE';

  @override
  String get connectingToDispatch => 'Connexion aux Services d\'Urgence';

  @override
  String get liveStatusTitle => 'Statut en Direct';

  @override
  String get cancelEmergencyAlert => 'Annuler l\'Alerte d\'Urgence';

  @override
  String get nearbyFacilitiesTitle => 'Établissements à Proximité';

  @override
  String get emergencyContactsTitle => 'Contacts d\'Urgence';

  @override
  String emergencyContactsNotice(Object count) {
    return '$count contacts seront automatiquement notifiés lorsque le SOS est déclenché. Gérez-les depuis votre Profil.';
  }

  @override
  String get sosStep1 => 'Envoi de votre position à l\'hôpital le plus proche...';

  @override
  String get sosStep2 => 'Notification de votre agent de santé communautaire assigné...';

  @override
  String get sosStep3 => 'Alerte de vos contacts d\'urgence...';

  @override
  String get sosStep4 => 'Ambulance envoyée — arrivée estimée dans 12 minutes.';
}
