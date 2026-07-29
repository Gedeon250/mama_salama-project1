import 'package:flutter/material.dart';
import '../models/models.dart';

/// In-memory mock data for what's not yet in Firestore (medications only —
/// see the PRD's 10-phase migration guide, which never schedules these for
/// backend storage). Everything else (appointments, pregnancy
/// profile/vitals, medical records/labs/vaccines, education content,
/// community feed) has moved to Firestore — see FirestoreService.
class AppData extends ChangeNotifier {
  AppData() {
    _seed();
  }

  late MotherProfile profile;
  final List<MedicationDose> todaysMedications = [];

  bool sosActive = false;
  String sosStatusText = '';

  void _seed() {
    profile = MotherProfile(name: 'Sarah');

    todaysMedications.addAll([
      MedicationDose(name: 'Prenatal Vitamin', dosage: '1 tablet', time: '8:00 AM'),
      MedicationDose(name: 'Iron Supplement', dosage: '65mg', time: '1:00 PM'),
      MedicationDose(name: 'Calcium', dosage: '500mg', time: '8:00 PM'),
    ]);
  }

  // ----- Actions -----

  void toggleMedicationTaken(MedicationDose dose) {
    dose.taken = !dose.taken;
    notifyListeners();
  }

  void startSos() {
    sosActive = true;
    sosStatusText = 'Sending your location to the nearest hospital...';
    notifyListeners();
  }

  void updateSosStatus(String text) {
    sosStatusText = text;
    notifyListeners();
  }

  void cancelSos() {
    sosActive = false;
    sosStatusText = '';
    notifyListeners();
  }
}
