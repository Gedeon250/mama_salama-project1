import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';

/// All Firestore reads/writes for the multi-role interaction model:
///
///   Mother  --(HelpRequest: SOS / "I need something")-->  Admin dashboard
///   Admin   --(assigns a CHW, or messages the CHW directly)-->  CHW
///   CHW     --(chats directly)-->  Mother
///
/// Collections used:
///   users/{uid}                      - AppUser docs (see AuthService);
///                                       also holds a `pregnancyProfile` map
///   users/{uid}/vitals/{yyyy-MM-dd}  - DailyVitals docs, one per day
///   helpRequests/{id}                - HelpRequest docs
///   appointments/{id}                - Appointment docs, one per booked visit
///   reminders/{id}                   - one per booked appointment; not
///                                       consumed by anything yet, just a
///                                       hook for a future notification job
///   chatThreads/{threadId}/messages  - ChatMessage docs, one thread per
///                                       pair of participants
///   medicalRecords/{id}              - MedicalRecord docs, written by a CHW
///   labResults/{id}                  - LabResult docs, written by a CHW
///   vaccineRecords/{id}              - VaccineRecord docs, written by a CHW
///   educationContent/{id}            - EducationContent docs, written by an Admin
///   communityGroups/{id}             - CommunityGroup docs
///   communityGroups/{id}/posts/{id}  - CommunityPost docs, one per group
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore}) : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('helpRequests');
  CollectionReference<Map<String, dynamic>> get _appointments => _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _referrals => _db.collection('referrals');
  CollectionReference<Map<String, dynamic>> get _reminders => _db.collection('reminders');
  CollectionReference<Map<String, dynamic>> get _medicalRecords => _db.collection('medicalRecords');
  CollectionReference<Map<String, dynamic>> get _labResults => _db.collection('labResults');
  CollectionReference<Map<String, dynamic>> get _vaccineRecords => _db.collection('vaccineRecords');
  CollectionReference<Map<String, dynamic>> get _educationContent => _db.collection('educationContent');
  CollectionReference<Map<String, dynamic>> get _communityGroups => _db.collection('communityGroups');

  // ----- Users / roles -----

  Stream<List<AppUser>> watchUsersByRole(UserRole role) {
    return _users.where('role', isEqualTo: roleToString(role)).snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromDoc(d.id, d.data())).toList(),
        );
  }

  Future<AppUser?> getUserById(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc.id, doc.data()!);
  }

  Stream<AppUser?> watchUserById(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc.id, doc.data()!);
    });
  }

  Future<void> assignChwToMother({required String motherId, required String chwId}) {
    return _users.doc(motherId).set({'assignedChwId': chwId}, SetOptions(merge: true));
  }

  Future<void> updateUserProfile(String uid, {String? name, String? phone, String? photoUrl}) {
    return _users.doc(uid).set({
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (photoUrl != null) 'photoUrl': photoUrl,
    }, SetOptions(merge: true));
  }

  // ----- CHW applications (see UserRole.chwApplicant / ChwApplication) -----

  Stream<List<AppUser>> watchChwApplications() {
    return _users.where('role', isEqualTo: roleToString(UserRole.chwApplicant)).snapshots().map(
          (snap) => snap.docs.map((d) => AppUser.fromDoc(d.id, d.data())).toList(),
        );
  }

  Future<void> submitChwApplication(String uid, ChwApplication application) {
    return _users.doc(uid).set({'chwApplication': application.toMap()}, SetOptions(merge: true));
  }

  Future<void> approveChwApplication(String uid) {
    return _users.doc(uid).set({'role': roleToString(UserRole.chw)}, SetOptions(merge: true));
  }

  Future<void> requestMoreChwInfo(String uid, String note) {
    return _users.doc(uid).update({
      'chwApplication.status': ChwApplicationStatus.needsMoreInfo.name,
      'chwApplication.adminNote': note,
    });
  }

  Future<void> rejectChwApplication(String uid, String? note) {
    return _users.doc(uid).update({
      'chwApplication.status': ChwApplicationStatus.rejected.name,
      if (note != null) 'chwApplication.adminNote': note,
    });
  }

  /// Count of mothers currently flagged `pregnancyProfile.isHighRisk` — feeds
  /// the Admin analytics dashboard. Pure equality filters on two different
  /// fields use Firestore's automatic single-field indexes, no composite
  /// index needed.
  Stream<int> watchHighRiskMotherCount() {
    return _users
        .where('role', isEqualTo: roleToString(UserRole.mother))
        .where('pregnancyProfile.isHighRisk', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // ----- Pregnancy profile + daily vitals -----

  String _dateId(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  CollectionReference<Map<String, dynamic>> _vitals(String uid) => _users.doc(uid).collection('vitals');

  Stream<PregnancyProfile> watchPregnancyProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      final map = doc.data()?['pregnancyProfile'] as Map<String, dynamic>?;
      return map != null ? PregnancyProfile.fromMap(map) : PregnancyProfile.defaults();
    });
  }

  Future<void> updatePregnancyProfile(String uid, PregnancyProfile profile) {
    return _users.doc(uid).set({'pregnancyProfile': profile.toMap()}, SetOptions(merge: true));
  }

  /// Marked by a CHW or hospital worker, not the mother herself — feeds the
  /// Admin analytics "high-risk count".
  Future<void> setHighRisk(String uid, bool isHighRisk) {
    return _users.doc(uid).set({
      'pregnancyProfile': {'isHighRisk': isHighRisk},
    }, SetOptions(merge: true));
  }

  Stream<DailyVitals> watchVitalsForDate(String uid, DateTime date) {
    final id = _dateId(date);
    return _vitals(uid).doc(id).snapshots().map((doc) => DailyVitals.fromDoc(id, doc.data() ?? {}));
  }

  /// Most recent [limit] days of vitals, oldest first — used for the
  /// weight/BP/blood-sugar trend sparklines on the Health screen.
  ///
  /// Orders by a plain `date` field rather than the document ID: regular
  /// fields get automatic indexes in both directions, but `__name__`
  /// (document ID) only gets one for ascending — descending, or
  /// limitToLast (which Firestore runs as a descending query internally
  /// and reverses client-side), needs an explicit index override either way.
  Stream<List<DailyVitals>> watchRecentVitals(String uid, {int limit = 14}) {
    return _vitals(uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) => DailyVitals.fromDoc(d.id, d.data())).toList().reversed.toList());
  }

  Map<String, dynamic> _todayStamp() => {'date': Timestamp.fromDate(DateTime.now())};

  Future<void> logKick(String uid) {
    return _vitals(uid).doc(_dateId(DateTime.now())).set({'kickCountToday': FieldValue.increment(1), ..._todayStamp()}, SetOptions(merge: true));
  }

  Future<void> resetKickCounter(String uid) {
    return _vitals(uid).doc(_dateId(DateTime.now())).set({'kickCountToday': 0, ..._todayStamp()}, SetOptions(merge: true));
  }

  Future<void> logContraction(String uid, Duration length) {
    return _vitals(uid).doc(_dateId(DateTime.now())).set({
      'contractionsTodaySeconds': FieldValue.arrayUnion([length.inSeconds]),
      ..._todayStamp(),
    }, SetOptions(merge: true));
  }

  Future<void> addWaterCup(String uid, {int goalCups = 8}) {
    return _vitals(uid).doc(_dateId(DateTime.now())).set({
      'waterCupsToday': FieldValue.increment(1),
      'waterGoalCups': goalCups,
      ..._todayStamp(),
    }, SetOptions(merge: true));
  }

  Future<void> setMood(String uid, String mood) {
    return _vitals(uid).doc(_dateId(DateTime.now())).set({'moodToday': mood, ..._todayStamp()}, SetOptions(merge: true));
  }

  // ----- Medical records, lab results, vaccinations -----
  // Written only by a CHW for one of their assigned mothers (or an admin);
  // a mother can only ever read her own — see firestore.rules.

  Stream<List<MedicalRecord>> watchMedicalRecordsForMother(String motherId) {
    return _medicalRecords
        .where('motherId', isEqualTo: motherId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => MedicalRecord.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addMedicalRecord(MedicalRecord record) {
    return _medicalRecords.add(record.toDoc());
  }

  Stream<List<LabResult>> watchLabResultsForMother(String motherId) {
    return _labResults
        .where('motherId', isEqualTo: motherId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => LabResult.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addLabResult(LabResult result) {
    return _labResults.add(result.toDoc());
  }

  Stream<List<VaccineRecord>> watchVaccinesForMother(String motherId) {
    return _vaccineRecords
        .where('motherId', isEqualTo: motherId)
        .orderBy('dueOrGivenDate', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => VaccineRecord.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addVaccineRecord(VaccineRecord record) {
    return _vaccineRecords.add(record.toDoc());
  }

  // ----- Help requests (SOS + general "I need something") -----

  /// Creates the request and returns its id *immediately*, generated
  /// client-side, so the SOS screen can track it even with no connectivity.
  /// The write itself is fire-and-forget: Firestore's offline cache commits
  /// it locally (listeners fire at once via latency compensation) and syncs
  /// to the server when the network returns. Awaiting `set()` would instead
  /// hang until the server acknowledges — unacceptable for an emergency.
  String createHelpRequest(HelpRequest request) {
    final ref = _requests.doc();
    ref.set(request.toDoc());
    return ref.id;
  }

  /// Live feed for the Admin dashboard — every request, newest first.
  Stream<List<HelpRequest>> watchAllRequests() {
    return _requests.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map((d) => HelpRequest.fromDoc(d.id, d.data())).toList(),
        );
  }

  /// What a CHW sees: requests assigned to them, plus unassigned ones they
  /// could pick up.
  Stream<List<HelpRequest>> watchRequestsForChw(String chwId) {
    return _requests
        .where('assignedChwId', isEqualTo: chwId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HelpRequest.fromDoc(d.id, d.data())).toList());
  }

  Stream<List<HelpRequest>> watchRequestsForMother(String motherId) {
    return _requests
        .where('motherId', isEqualTo: motherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => HelpRequest.fromDoc(d.id, d.data())).toList());
  }

  Future<void> assignRequest({
    required String requestId,
    required String chwId,
    required String chwName,
    String? chwPhone,
  }) {
    return _requests.doc(requestId).update({
      'assignedChwId': chwId,
      'assignedChwName': chwName,
      if (chwPhone != null) 'assignedChwPhone': chwPhone,
      'status': RequestStatus.assigned.name,
      'assignedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> resolveRequest(String requestId) {
    return _requests.doc(requestId).update({
      'status': RequestStatus.resolved.name,
      'resolvedAt': FieldValue.serverTimestamp(),
    });
  }

  /// A CHW records that transport (a pre-registered driver) has been arranged
  /// for a request. The mother's SOS screen watches this and shows the driver
  /// with a tap-to-call button (Gap 4).
  Future<void> arrangeTransport({
    required String requestId,
    required String driverName,
    required String driverPhone,
  }) {
    return _requests.doc(requestId).update({
      'transportStatus': TransportStatus.arranged.name,
      'driverName': driverName,
      'driverPhone': driverPhone,
    });
  }

  // ----- Appointments -----

  Stream<List<Appointment>> watchAppointmentsForMother(String motherId) {
    return _appointments
        .where('motherId', isEqualTo: motherId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d.id, d.data())).toList());
  }

  /// Live feed for a future Hospital/Admin view — every appointment, not
  /// just one mother's.
  Stream<List<Appointment>> watchAllAppointments() {
    return _appointments.orderBy('dateTime', descending: false).snapshots().map(
          (snap) => snap.docs.map((d) => Appointment.fromDoc(d.id, d.data())).toList(),
        );
  }

  /// Books the appointment and files a matching `reminders` doc so a future
  /// notification job has something to query — no notification is sent yet.
  Future<String> bookAppointment(Appointment appointment) async {
    final ref = await _appointments.add(appointment.toDoc());
    await _reminders.add({
      'appointmentId': ref.id,
      'motherId': appointment.motherId,
      'title': appointment.title,
      'remindAt': Timestamp.fromDate(appointment.dateTime),
      'sent': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  Future<void> cancelAppointment(String id) {
    return _appointments.doc(id).update({'status': AppointmentStatus.cancelled.name});
  }

  Future<void> completeAppointment(String id) {
    return _appointments.doc(id).update({'status': AppointmentStatus.completed.name});
  }

  /// Appointments routed to a specific Hospital account — see the
  /// `hospitalId` field on Appointment.
  Stream<List<Appointment>> watchAppointmentsForHospital(String hospitalId) {
    return _appointments
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('dateTime', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Appointment.fromDoc(d.id, d.data())).toList());
  }

  // ----- Referrals (CHW -> Hospital) -----

  Future<void> createReferral(Referral referral) {
    return _referrals.add(referral.toDoc());
  }

  Stream<List<Referral>> watchReferralsForHospital(String hospitalId) {
    return _referrals
        .where('hospitalId', isEqualTo: hospitalId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => Referral.fromDoc(d.id, d.data())).toList());
  }

  // ----- Chat -----

  /// Deterministic thread id so both participants always resolve the same
  /// document regardless of who opens the chat first.
  String threadIdFor(String uidA, String uidB) {
    final ids = [uidA, uidB]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessage>> watchMessages(String threadId) {
    return _db
        .collection('chatThreads')
        .doc(threadId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatMessage.fromDoc(d.id, d.data())).toList());
  }

  Future<void> sendMessage({
    required String threadId,
    required String senderId,
    required String senderName,
    String text = '',
    String? attachmentUrl,
    ChatAttachmentType? attachmentType,
    String? attachmentName,
  }) async {
    final trimmed = text.trim();
    final hasAttachment = attachmentUrl != null && attachmentUrl.isNotEmpty;
    if (trimmed.isEmpty && !hasAttachment) return;

    String preview = trimmed;
    if (preview.isEmpty && hasAttachment) {
      preview = attachmentType == ChatAttachmentType.image
          ? '📷 Photo'
          : '📎 ${attachmentName ?? 'Attachment'}';
    }

    final threadRef = _db.collection('chatThreads').doc(threadId);
    await threadRef.set({
      'lastMessage': preview,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
      'participants': threadId.split('_'),
    }, SetOptions(merge: true));
    await threadRef.collection('messages').add(
          ChatMessage(
            id: '',
            senderId: senderId,
            senderName: senderName,
            text: trimmed,
            sentAt: DateTime.now(),
            attachmentUrl: attachmentUrl,
            attachmentType: attachmentType,
            attachmentName: attachmentName,
          ).toDoc(),
        );
  }

  /// A single thread's summary (last message + who sent it) — cheaper than
  /// watchMessages when a screen only needs to show an unread indicator.
  Stream<ChatThreadSummary?> watchThreadSummary(String threadId, String myUid) {
    return _db.collection('chatThreads').doc(threadId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ChatThreadSummary.fromDoc(doc.id, doc.data()!, myUid);
    });
  }

  /// Every chat thread [uid] is a participant in, newest first — used to
  /// show "you have a new message" indicators without opening each thread.
  Stream<List<ChatThreadSummary>> watchMyThreads(String uid) {
    return _db
        .collection('chatThreads')
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ChatThreadSummary.fromDoc(d.id, d.data(), uid)).toList());
  }

  // ----- Education content -----
  // Written only by Admins; read by everyone signed in.

  Stream<List<EducationContent>> watchEducationContent() {
    return _educationContent.snapshots().map((snap) => snap.docs.map((d) => EducationContent.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addEducationContent(EducationContent item) {
    return _educationContent.add(item.toDoc());
  }

  // ----- Community groups + posts -----
  // Groups are seeded once (console/admin script, not through the app UI);
  // posts can be created by any signed-in mother or CHW.

  Stream<List<CommunityGroup>> watchCommunityGroups() {
    return _communityGroups.snapshots().map((snap) => snap.docs.map((d) => CommunityGroup.fromDoc(d.id, d.data())).toList());
  }

  Stream<List<CommunityPost>> watchPostsForGroup(String groupId) {
    return _communityGroups
        .doc(groupId)
        .collection('posts')
        .orderBy('postedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => CommunityPost.fromDoc(d.id, d.data())).toList());
  }

  Future<void> addCommunityPost(String groupId, CommunityPost post) {
    return _communityGroups.doc(groupId).collection('posts').add(post.toDoc());
  }

  /// Only the post's author may call this — enforced by firestore.rules, not
  /// just the UI hiding the button.
  Future<void> deleteCommunityPost(String groupId, String postId) {
    return _communityGroups.doc(groupId).collection('posts').doc(postId).delete();
  }
}
