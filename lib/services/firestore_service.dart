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
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests => _db.collection('helpRequests');
  CollectionReference<Map<String, dynamic>> get _appointments => _db.collection('appointments');
  CollectionReference<Map<String, dynamic>> get _reminders => _db.collection('reminders');

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

  Future<void> assignChwToMother({required String motherId, required String chwId}) {
    return _users.doc(motherId).set({'assignedChwId': chwId}, SetOptions(merge: true));
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

  // ----- Help requests (SOS + general "I need something") -----

  Future<String> createHelpRequest(HelpRequest request) async {
    final ref = await _requests.add(request.toDoc());
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

  Future<void> assignRequest({required String requestId, required String chwId, required String chwName}) {
    return _requests.doc(requestId).update({
      'assignedChwId': chwId,
      'assignedChwName': chwName,
      'status': RequestStatus.assigned.name,
    });
  }

  Future<void> resolveRequest(String requestId) {
    return _requests.doc(requestId).update({'status': RequestStatus.resolved.name});
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
    required String text,
  }) async {
    final threadRef = _db.collection('chatThreads').doc(threadId);
    await threadRef.set({
      'lastMessage': text,
      'lastSenderId': senderId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await threadRef.collection('messages').add(
          ChatMessage(id: '', senderId: senderId, senderName: senderName, text: text, sentAt: DateTime.now()).toDoc(),
        );
  }
}
