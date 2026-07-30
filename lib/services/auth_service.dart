import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_models.dart';

/// Thin wrapper around FirebaseAuth + the `users` Firestore collection.
/// Every account (mother, CHW, admin) is a normal Firebase Auth user; the
/// `role` field on their `users/{uid}` doc decides what shell they land in
/// (see `screens/auth/auth_gate.dart`).
class AuthService {
  AuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();
  fb.User? get currentUser => _auth.currentUser;

  Future<AppUser?> fetchAppUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(uid, doc.data()!);
  }

  Stream<AppUser?> watchAppUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map(
          (doc) => doc.exists ? AppUser.fromDoc(uid, doc.data()!) : null,
        );
  }

  /// Mothers self-register. CHW applicants also self-register but are
  /// created with role `chw`; in production you'd gate that behind an
  /// admin-approval step rather than trusting the signup form — see the
  /// TODO in signup_screen.dart.
  Future<void> registerAccount({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final uid = credential.user!.uid;
    await _db.collection('users').doc(uid).set(
          AppUser(uid: uid, name: name, email: email, role: role, phone: phone).toDoc(),
        );
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  /// Firebase requires a recent sign-in before allowing a password change,
  /// so we reauthenticate with the current password first rather than
  /// asking the user to sign out and back in.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser!;
    final credential = fb.EmailAuthProvider.credential(email: user.email!, password: currentPassword);
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
  }
}
