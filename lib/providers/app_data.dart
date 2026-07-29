import 'package:flutter/material.dart';
import '../models/models.dart';

/// In-memory mock data for what's not yet in Firestore (medications,
/// education, community feed). Appointments, pregnancy profile/vitals, and
/// medical records/labs/vaccines have moved to Firestore — see
/// FirestoreService.
class AppData extends ChangeNotifier {
  AppData() {
    _seed();
  }

  late MotherProfile profile;
  final List<MedicationDose> todaysMedications = [];
  final List<EducationItem> educationItems = [];
  final List<CommunityGroup> communityGroups = [];
  final List<CommunityPost> supportGroupPosts = [];

  bool sosActive = false;
  String sosStatusText = '';

  void _seed() {
    profile = MotherProfile(name: 'Sarah');

    todaysMedications.addAll([
      MedicationDose(name: 'Prenatal Vitamin', dosage: '1 tablet', time: '8:00 AM'),
      MedicationDose(name: 'Iron Supplement', dosage: '65mg', time: '1:00 PM'),
      MedicationDose(name: 'Calcium', dosage: '500mg', time: '8:00 PM'),
    ]);

    final now = DateTime.now();
    educationItems.addAll([
      EducationItem(title: 'Nutrition in Your Second Trimester', category: 'Nutrition', format: EducationFormat.video, durationOrLength: '6 min', description: 'A nutritionist walks through balanced meals for weeks 13–26.'),
      EducationItem(title: 'Recognizing Danger Signs', category: 'Danger Signs', format: EducationFormat.article, durationOrLength: '4 min read', description: 'Warning signs that mean you should contact your CHW or hospital immediately.'),
      EducationItem(title: 'Breathing Through Contractions', category: 'Delivery', format: EducationFormat.audio, durationOrLength: '9 min', description: 'A calming audio lesson on breathing techniques for labor.'),
      EducationItem(title: 'Breastfeeding Basics', category: 'Breastfeeding', format: EducationFormat.video, durationOrLength: '8 min', description: 'Positioning and latch fundamentals for the first days.'),
      EducationItem(title: 'Family Planning After Delivery', category: 'Family Planning', format: EducationFormat.article, durationOrLength: '5 min read', description: 'Options to discuss with your provider at your postnatal visit.'),
    ]);

    communityGroups.addAll([
      CommunityGroup(name: 'Trimester 2 Support', trimesterTag: 'Trimester 2', memberCount: 1200, description: 'A nurturing space for mamas navigating weeks 13–26. Sharing joy, tips, and clinical advice.'),
      CommunityGroup(name: 'First-Time Mothers', trimesterTag: 'All Trimesters', memberCount: 860, description: 'For mothers on their very first pregnancy journey.'),
      CommunityGroup(name: 'Kigali Mamas', trimesterTag: 'Local', memberCount: 430, description: 'Connect with expectant mothers near you in Kigali.'),
    ]);

    supportGroupPosts.addAll([
      CommunityPost(
        author: 'Aline M.',
        content: "Anyone else dealing with heartburn at week 24? Looking for foods that actually help.",
        tag: 'Morning Sickness',
        likes: 14,
        comments: 6,
        postedAt: now.subtract(const Duration(hours: 3)),
      ),
      CommunityPost(
        author: 'Dr. Uwase (CHW)',
        content: 'Reminder: your TT3 vaccine window is opening soon for many of you in this group — check your Vaccinations tab and book with your local clinic.',
        tag: 'Expert Answers',
        likes: 41,
        comments: 9,
        isExpertAnswer: true,
        postedAt: now.subtract(const Duration(hours: 8)),
      ),
      CommunityPost(
        author: 'Divine K.',
        content: 'Finished my anatomy scan today — everything looks healthy! So relieved.',
        tag: 'Vitamins',
        likes: 27,
        comments: 4,
        postedAt: now.subtract(const Duration(days: 1)),
      ),
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
