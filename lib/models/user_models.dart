import 'package:cloud_firestore/cloud_firestore.dart';

/// The three account types the backend distinguishes. Hospital/clinic
/// accounts (role 3 in the PRD) are out of scope for this pass — only
/// Mother, CHW ("Health Worker"/volunteer), and Admin are wired up.
enum UserRole { mother, chw, admin }

UserRole roleFromString(String? value) {
  switch (value) {
    case 'chw':
      return UserRole.chw;
    case 'admin':
      return UserRole.admin;
    default:
      return UserRole.mother;
  }
}

String roleToString(UserRole role) => role.name;

class AppUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final String? assignedChwId; // set on mothers once a CHW is assigned
  final String? phone;

  AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.assignedChwId,
    this.phone,
  });

  factory AppUser.fromDoc(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? 'Unnamed',
      email: data['email'] ?? '',
      role: roleFromString(data['role'] as String?),
      assignedChwId: data['assignedChwId'] as String?,
      phone: data['phone'] as String?,
    );
  }

  Map<String, dynamic> toDoc() => {
        'name': name,
        'email': email,
        'role': roleToString(role),
        if (assignedChwId != null) 'assignedChwId': assignedChwId,
        if (phone != null) 'phone': phone,
      };
}

/// Stored as a `pregnancyProfile` map on the mother's own users/{uid} doc
/// (not a separate collection) — see FirestoreService.watchPregnancyProfile.
class PregnancyProfile {
  final int pregnancyWeek;
  final DateTime dueDate;
  final String bloodType;
  final List<String> allergies;
  final String babySizeComparison;

  PregnancyProfile({
    required this.pregnancyWeek,
    required this.dueDate,
    required this.bloodType,
    required this.allergies,
    required this.babySizeComparison,
  });

  int get trimester => pregnancyWeek <= 13 ? 1 : (pregnancyWeek <= 26 ? 2 : 3);
  int get daysToDueDate => dueDate.difference(DateTime.now()).inDays.clamp(0, 999);

  factory PregnancyProfile.defaults() => PregnancyProfile(
        pregnancyWeek: 4,
        dueDate: DateTime.now().add(const Duration(days: 259)),
        bloodType: 'Unknown',
        allergies: const [],
        babySizeComparison: 'Poppy seed',
      );

  factory PregnancyProfile.fromMap(Map<String, dynamic> map) {
    return PregnancyProfile(
      pregnancyWeek: (map['pregnancyWeek'] as num?)?.toInt() ?? 4,
      dueDate: (map['dueDate'] is Timestamp)
          ? (map['dueDate'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(days: 259)),
      bloodType: map['bloodType'] ?? 'Unknown',
      allergies: (map['allergies'] as List?)?.map((e) => e.toString()).toList() ?? [],
      babySizeComparison: map['babySizeComparison'] ?? 'Poppy seed',
    );
  }

  Map<String, dynamic> toMap() => {
        'pregnancyWeek': pregnancyWeek,
        'dueDate': Timestamp.fromDate(dueDate),
        'bloodType': bloodType,
        'allergies': allergies,
        'babySizeComparison': babySizeComparison,
      };
}

/// One doc per calendar day at users/{uid}/vitals/{yyyy-MM-dd}. Point
/// readings (weight/BP/blood sugar) are optional since there's no capture
/// UI for them yet; kicks/contractions/water/mood are written immediately
/// as they're logged during that day.
class DailyVitals {
  final String id;
  final double? weightKg;
  final int? systolicBp;
  final int? diastolicBp;
  final int? bloodSugar;
  final int waterCupsToday;
  final int waterGoalCups;
  final int kickCountToday;
  final List<int> contractionsTodaySeconds;
  final String moodToday;

  DailyVitals({
    required this.id,
    this.weightKg,
    this.systolicBp,
    this.diastolicBp,
    this.bloodSugar,
    this.waterCupsToday = 0,
    this.waterGoalCups = 8,
    this.kickCountToday = 0,
    this.contractionsTodaySeconds = const [],
    this.moodToday = 'Good',
  });

  factory DailyVitals.empty(String id) => DailyVitals(id: id);

  factory DailyVitals.fromDoc(String id, Map<String, dynamic> data) {
    return DailyVitals(
      id: id,
      weightKg: (data['weightKg'] as num?)?.toDouble(),
      systolicBp: (data['systolicBp'] as num?)?.toInt(),
      diastolicBp: (data['diastolicBp'] as num?)?.toInt(),
      bloodSugar: (data['bloodSugar'] as num?)?.toInt(),
      waterCupsToday: (data['waterCupsToday'] as num?)?.toInt() ?? 0,
      waterGoalCups: (data['waterGoalCups'] as num?)?.toInt() ?? 8,
      kickCountToday: (data['kickCountToday'] as num?)?.toInt() ?? 0,
      contractionsTodaySeconds: (data['contractionsTodaySeconds'] as List?)?.map((e) => (e as num).toInt()).toList() ?? [],
      moodToday: data['moodToday'] ?? 'Good',
    );
  }
}

/// Visit note, written by a CHW for one of their assigned mothers.
/// Mothers can only read their own — see firestore.rules.
class MedicalRecord {
  final String id;
  final String motherId;
  final String title;
  final String category; // e.g. "Visit note", "Ultrasound", "Delivery"
  final DateTime date;
  final String summary;

  MedicalRecord({
    required this.id,
    required this.motherId,
    required this.title,
    required this.category,
    required this.date,
    required this.summary,
  });

  factory MedicalRecord.fromDoc(String id, Map<String, dynamic> data) {
    return MedicalRecord(
      id: id,
      motherId: data['motherId'] ?? '',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      date: (data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.now(),
      summary: data['summary'] ?? '',
    );
  }

  Map<String, dynamic> toDoc() => {
        'motherId': motherId,
        'title': title,
        'category': category,
        'date': Timestamp.fromDate(date),
        'summary': summary,
      };
}

/// Lab result, written by a CHW for one of their assigned mothers.
class LabResult {
  final String id;
  final String motherId;
  final String testName;
  final String value;
  final String referenceRange;
  final bool isNormal;
  final DateTime date;

  LabResult({
    required this.id,
    required this.motherId,
    required this.testName,
    required this.value,
    required this.referenceRange,
    required this.isNormal,
    required this.date,
  });

  factory LabResult.fromDoc(String id, Map<String, dynamic> data) {
    return LabResult(
      id: id,
      motherId: data['motherId'] ?? '',
      testName: data['testName'] ?? '',
      value: data['value'] ?? '',
      referenceRange: data['referenceRange'] ?? '',
      isNormal: data['isNormal'] ?? true,
      date: (data['date'] is Timestamp) ? (data['date'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toDoc() => {
        'motherId': motherId,
        'testName': testName,
        'value': value,
        'referenceRange': referenceRange,
        'isNormal': isNormal,
        'date': Timestamp.fromDate(date),
      };
}

/// Vaccination entry, written by a CHW for one of their assigned mothers.
class VaccineRecord {
  final String id;
  final String motherId;
  final String name;
  final String forWhom; // "Mother" or "Baby"
  final DateTime dueOrGivenDate;
  final bool completed;

  VaccineRecord({
    required this.id,
    required this.motherId,
    required this.name,
    required this.forWhom,
    required this.dueOrGivenDate,
    this.completed = false,
  });

  factory VaccineRecord.fromDoc(String id, Map<String, dynamic> data) {
    return VaccineRecord(
      id: id,
      motherId: data['motherId'] ?? '',
      name: data['name'] ?? '',
      forWhom: data['forWhom'] ?? 'Mother',
      dueOrGivenDate: (data['dueOrGivenDate'] is Timestamp) ? (data['dueOrGivenDate'] as Timestamp).toDate() : DateTime.now(),
      completed: data['completed'] ?? false,
    );
  }

  Map<String, dynamic> toDoc() => {
        'motherId': motherId,
        'name': name,
        'forWhom': forWhom,
        'dueOrGivenDate': Timestamp.fromDate(dueOrGivenDate),
        'completed': completed,
      };
}

enum AppointmentStatus { upcoming, completed, cancelled }

/// A booked visit, stored top-level in `appointments/{id}` so a future
/// Hospital/Admin view can stream all of them (see
/// FirestoreService.watchAllAppointments) while a mother only ever sees
/// her own.
class Appointment {
  final String id;
  final String motherId;
  final String motherName;
  final String title;
  final String provider;
  final String location;
  final DateTime dateTime;
  final bool isTelemedicine;
  final AppointmentStatus status;

  Appointment({
    required this.id,
    required this.motherId,
    required this.motherName,
    required this.title,
    required this.provider,
    required this.location,
    required this.dateTime,
    this.isTelemedicine = false,
    this.status = AppointmentStatus.upcoming,
  });

  factory Appointment.fromDoc(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      motherId: data['motherId'] ?? '',
      motherName: data['motherName'] ?? 'Mother',
      title: data['title'] ?? '',
      provider: data['provider'] ?? '',
      location: data['location'] ?? '',
      dateTime: (data['dateTime'] is Timestamp) ? (data['dateTime'] as Timestamp).toDate() : DateTime.now(),
      isTelemedicine: data['isTelemedicine'] ?? false,
      status: AppointmentStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'upcoming'),
        orElse: () => AppointmentStatus.upcoming,
      ),
    );
  }

  Map<String, dynamic> toDoc() => {
        'motherId': motherId,
        'motherName': motherName,
        'title': title,
        'provider': provider,
        'location': location,
        'dateTime': Timestamp.fromDate(dateTime),
        'isTelemedicine': isTelemedicine,
        'status': status.name,
      };
}

enum RequestType { sos, generalHelp }

enum RequestStatus { pending, assigned, resolved }

/// Created whenever a mother taps SOS or "Request Help". Admin sees every
/// one of these live on the Admin dashboard; assigning a CHW moves it from
/// `pending` to `assigned`.
class HelpRequest {
  final String id;
  final String motherId;
  final String motherName;
  final RequestType type;
  final String message;
  RequestStatus status;
  String? assignedChwId;
  String? assignedChwName;
  final DateTime createdAt;

  HelpRequest({
    required this.id,
    required this.motherId,
    required this.motherName,
    required this.type,
    required this.message,
    this.status = RequestStatus.pending,
    this.assignedChwId,
    this.assignedChwName,
    required this.createdAt,
  });

  factory HelpRequest.fromDoc(String id, Map<String, dynamic> data) {
    return HelpRequest(
      id: id,
      motherId: data['motherId'] ?? '',
      motherName: data['motherName'] ?? 'Mother',
      type: (data['type'] == 'sos') ? RequestType.sos : RequestType.generalHelp,
      message: data['message'] ?? '',
      status: RequestStatus.values.firstWhere(
        (s) => s.name == (data['status'] ?? 'pending'),
        orElse: () => RequestStatus.pending,
      ),
      assignedChwId: data['assignedChwId'] as String?,
      assignedChwName: data['assignedChwName'] as String?,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toDoc() => {
        'motherId': motherId,
        'motherName': motherName,
        'type': type == RequestType.sos ? 'sos' : 'general',
        'message': message,
        'status': status.name,
        if (assignedChwId != null) 'assignedChwId': assignedChwId,
        if (assignedChwName != null) 'assignedChwName': assignedChwName,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

/// A chat message inside a thread. Threads are identified by a
/// deterministic id built from the two participant uids (see
/// FirestoreService.threadIdFor) so both sides always resolve the same
/// document.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime sentAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromDoc(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      text: data['text'] ?? '',
      sentAt: (data['sentAt'] is Timestamp) ? (data['sentAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toDoc() => {
        'senderId': senderId,
        'senderName': senderName,
        'text': text,
        'sentAt': FieldValue.serverTimestamp(),
      };
}

enum EducationFormat { video, article, audio }

EducationFormat _formatFromString(String? value) {
  return EducationFormat.values.firstWhere((f) => f.name == value, orElse: () => EducationFormat.article);
}

/// Lesson content, authored by Admins only — everyone else has read-only
/// access. See FirestoreService.watchEducationContent.
class EducationContent {
  final String id;
  final String title;
  final String category;
  final EducationFormat format;
  final String durationOrLength;
  final String description;
  final String? mediaUrl;

  EducationContent({
    required this.id,
    required this.title,
    required this.category,
    required this.format,
    required this.durationOrLength,
    required this.description,
    this.mediaUrl,
  });

  factory EducationContent.fromDoc(String id, Map<String, dynamic> data) {
    return EducationContent(
      id: id,
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      format: _formatFromString(data['format'] as String?),
      durationOrLength: data['durationOrLength'] ?? '',
      description: data['description'] ?? '',
      mediaUrl: data['mediaUrl'] as String?,
    );
  }

  Map<String, dynamic> toDoc() => {
        'title': title,
        'category': category,
        'format': format.name,
        'durationOrLength': durationOrLength,
        'description': description,
        'mediaUrl': mediaUrl,
      };
}

/// Top-level community group, e.g. "Trimester 2 Support". Posts live in
/// the `posts` subcollection — see CommunityPost.
class CommunityGroup {
  final String id;
  final String name;
  final String trimesterTag;
  final int memberCount;
  final String description;

  CommunityGroup({
    required this.id,
    required this.name,
    required this.trimesterTag,
    required this.memberCount,
    required this.description,
  });

  factory CommunityGroup.fromDoc(String id, Map<String, dynamic> data) {
    return CommunityGroup(
      id: id,
      name: data['name'] ?? '',
      trimesterTag: data['trimesterTag'] ?? '',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toDoc() => {
        'name': name,
        'trimesterTag': trimesterTag,
        'memberCount': memberCount,
        'description': description,
      };
}

/// A post in communityGroups/{groupId}/posts. Any signed-in mother or CHW
/// can create one; `isExpertAnswer` is enforced server-side (in
/// firestore.rules) to match the poster's real role, not just a value the
/// client claims.
class CommunityPost {
  final String id;
  final String author;
  final String authorId;
  final String content;
  final String tag;
  final int likes;
  final int comments;
  final bool isExpertAnswer;
  final DateTime postedAt;

  CommunityPost({
    required this.id,
    required this.author,
    required this.authorId,
    required this.content,
    required this.tag,
    this.likes = 0,
    this.comments = 0,
    this.isExpertAnswer = false,
    required this.postedAt,
  });

  factory CommunityPost.fromDoc(String id, Map<String, dynamic> data) {
    return CommunityPost(
      id: id,
      author: data['author'] ?? '',
      authorId: data['authorId'] ?? '',
      content: data['content'] ?? '',
      tag: data['tag'] ?? '',
      likes: (data['likes'] as num?)?.toInt() ?? 0,
      comments: (data['comments'] as num?)?.toInt() ?? 0,
      isExpertAnswer: data['isExpertAnswer'] ?? false,
      postedAt: (data['postedAt'] is Timestamp) ? (data['postedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }

  Map<String, dynamic> toDoc() => {
        'author': author,
        'authorId': authorId,
        'content': content,
        'tag': tag,
        'likes': likes,
        'comments': comments,
        'isExpertAnswer': isExpertAnswer,
        'postedAt': FieldValue.serverTimestamp(),
      };
}

/// Lightweight summary of a chatThreads/{threadId} doc — enough to show an
/// unread indicator and a last-message preview without loading the full
/// message history. See FirestoreService.watchMyThreads.
class ChatThreadSummary {
  final String threadId;
  final String otherUid;
  final String lastMessage;
  final String lastSenderId;
  final DateTime updatedAt;

  ChatThreadSummary({
    required this.threadId,
    required this.otherUid,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
  });

  factory ChatThreadSummary.fromDoc(String id, Map<String, dynamic> data, String myUid) {
    final parts = id.split('_');
    final otherUid = parts.firstWhere((p) => p != myUid, orElse: () => parts.first);
    return ChatThreadSummary(
      threadId: id,
      otherUid: otherUid,
      lastMessage: data['lastMessage'] ?? '',
      lastSenderId: data['lastSenderId'] ?? '',
      updatedAt: (data['updatedAt'] is Timestamp) ? (data['updatedAt'] as Timestamp).toDate() : DateTime.now(),
    );
  }
}
