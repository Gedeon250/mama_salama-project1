import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_models.dart';

class NoAccountForGoogleUserException implements Exception {}

/// Thrown by [AuthService.signIn] when Firebase Auth accepts the
/// credentials but there's no matching `users/{uid}` doc — e.g. an account
/// created directly in the Firebase console instead of through this app's
/// own signup flow. Without this check the user would silently get stuck
/// on AuthGate's `SessionStatus.loading` spinner forever, since
/// `watchAppUser` never emits a non-null user for a doc that doesn't
/// exist — see SessionProvider._onAuthChanged.
class NoProfileFoundException implements Exception {}

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
    // Don't let a verification-email hiccup (rate limit, transient error)
    // fail the whole signup — the account + doc already exist at this
    // point, so the user would otherwise get stuck unable to retry
    // ("email already in use") with no account to show for it. They can
    // hit "Resend" from the verify-email screen instead.
    try {
      await credential.user!.sendEmailVerification();
    } on fb.FirebaseAuthException {
      // Ignored — see comment above.
    }
  }

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final existing = await fetchAppUser(credential.user!.uid);
    if (existing == null) {
      await _auth.signOut();
      throw NoProfileFoundException();
    }
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
      try {
        await user.sendEmailVerification();
      } on fb.FirebaseAuthException {
        // See the equivalent try/catch in registerAccount — the account +
        // doc already exist, so a send failure shouldn't fail the sign-up.
      }
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

  /// Returns false (instead of throwing) on failure — e.g. Firebase's
  /// `auth/too-many-requests` if the user mashes "Resend" — so the caller
  /// can show a message instead of hanging with an uncaught exception.
  Future<bool> resendVerificationEmail() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      return true;
    } on fb.FirebaseAuthException {
      return false;
    }
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
