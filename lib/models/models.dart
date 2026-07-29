class MedicationDose {
  final String name;
  final String dosage;
  final String time;
  bool taken;

  MedicationDose({
    required this.name,
    required this.dosage,
    required this.time,
    this.taken = false,
  });
}

/// What's left of the old mock profile after pregnancy week/due
/// date/blood type/allergies/baby size moved to Firestore's
/// `pregnancyProfile` (see PregnancyProfile in user_models.dart).
class MotherProfile {
  String name;
  int emergencyContactsCount;

  MotherProfile({
    required this.name,
    this.emergencyContactsCount = 2,
  });
}
