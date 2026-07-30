import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_models.dart';

/// Thrown by [AuthService.signInWithGoogle] when the Google account has no
/// matching `users/{uid}` doc yet — the login screen uses this to tell the
/// user to register (pick a role) instead of silently creating an account.
class NoAccountForGoogleUserException implements Exception {}

/// Thin wrapper around FirebaseAuth + the `users` Firestore collection.
/// Every account (mother, CHW, admin) is a normal Firebase Auth user; the
/// `role` field on their `users/{uid}` doc decides what shell they land in
/// (see `screens/auth/auth_gate.dart`).
class AuthService {
  AuthService({fb.FirebaseAuth? auth, FirebaseFirestore? firestore, GoogleSignIn? googleSignIn})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final GoogleSignIn _googleSignIn;

  Stream<fb.User?> get authStateChanges => _auth.authStateChanges();
  fb.User? get currentUser => _auth.currentUser;
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Google accounts arrive with `emailVerified` already true (Google did
  /// that verification, not us), so that flag can't gate a Google sign-up —
  /// only a password account's `emailVerified` reflects a real click on our
  /// emailed link. See SessionProvider.refreshEmailVerified.
  bool get isPasswordProvider =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ?? false;

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
          AppUser(uid: uid, name: name, email: email, role: role, phone: phone, emailConfirmed: false).toDoc(),
        );
    await credential.user!.sendEmailVerification();
  }

  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<fb.UserCredential> _signInToGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw fb.FirebaseAuthException(code: 'google-sign-in-cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return _auth.signInWithCredential(credential);
  }

  /// Login-screen entry point: Google sign-in for an *existing* account
  /// only. Throws [NoAccountForGoogleUserException] (after signing the user
  /// back out) if this Google identity has never registered — the login
  /// screen doesn't know what role to give a brand-new account.
  Future<void> signInWithGoogle() async {
    final userCredential = await _signInToGoogle();
    final uid = userCredential.user!.uid;
    final existing = await fetchAppUser(uid);
    if (existing == null) {
      await _auth.signOut();
      await _googleSignIn.signOut();
      throw NoAccountForGoogleUserException();
    }
  }

  /// Signup-screen entry point: Google sign-in that creates the
  /// `users/{uid}` doc with [role] if this Google identity is new. If the
  /// identity already has an account, this is just a normal sign-in (the
  /// existing role is left untouched).
  ///
  /// Google marks the account as email-verified itself, but this app still
  /// requires its own confirmation step (see `emailConfirmed` on AppUser) —
  /// so a brand-new Google sign-up gets a verification email too, purely as
  /// an app-level formality since Firebase's own flag can't be used as the
  /// signal here (it's already true).
  Future<void> signUpWithGoogle(UserRole role) async {
    final userCredential = await _signInToGoogle();
    final user = userCredential.user!;
    final existing = await fetchAppUser(user.uid);
    if (existing == null) {
      await _db.collection('users').doc(user.uid).set(
            AppUser(
              uid: user.uid,
              name: user.displayName ?? 'Unnamed',
              email: user.email ?? '',
              role: role,
              emailConfirmed: false,
            ).toDoc(),
          );
      await user.sendEmailVerification();
    }
  }

  /// Marks the signed-in user's `emailConfirmed` field true — called once
  /// the post-signup verification gate is satisfied (see
  /// SessionProvider.refreshEmailVerified).
  Future<void> markEmailConfirmed() async {
    await _db.collection('users').doc(_auth.currentUser!.uid).update({'emailConfirmed': true});
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  Future<void> resendVerificationEmail() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Firebase caches the user's `emailVerified` flag on the client; reload
  /// pulls the latest value after the user has clicked the link in their
  /// inbox, so the verify-email screen can detect it without a full re-login.
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

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
