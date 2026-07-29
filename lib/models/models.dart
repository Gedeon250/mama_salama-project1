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

enum EducationFormat { video, article, audio }

class EducationItem {
  final String title;
  final String category;
  final EducationFormat format;
  final String durationOrLength;
  final String description;

  EducationItem({
    required this.title,
    required this.category,
    required this.format,
    required this.durationOrLength,
    required this.description,
  });
}

class CommunityGroup {
  final String name;
  final String trimesterTag;
  final int memberCount;
  final String description;

  CommunityGroup({
    required this.name,
    required this.trimesterTag,
    required this.memberCount,
    required this.description,
  });
}

class CommunityPost {
  final String author;
  final String content;
  final String tag;
  final int likes;
  final int comments;
  final bool isExpertAnswer;
  final DateTime postedAt;

  CommunityPost({
    required this.author,
    required this.content,
    required this.tag,
    required this.likes,
    required this.comments,
    this.isExpertAnswer = false,
    required this.postedAt,
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
