import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_models.dart';
import '../services/auth_service.dart';

enum SessionStatus { loading, signedOut, signedIn }

/// Holds the current signed-in AppUser (with role) for the whole app.
/// AuthGate watches `status` to decide which shell to show; every
/// role-specific screen reads `currentUser` from here instead of touching
/// FirebaseAuth directly.
class SessionProvider extends ChangeNotifier {
  final AuthService _authService;
  StreamSubscription? _authSub;
  StreamSubscription? _userSub;
  Timer? _profileWaitTimer;

  /// True while [register] / [signUpWithGoogle] is creating the Auth user
  /// and then writing `users/{uid}`. During that window `watchAppUser` can
  /// briefly emit null; we must not treat that as a missing profile.
  bool _expectingNewProfile = false;

  SessionProvider(this._authService) {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  SessionStatus status = SessionStatus.loading;
  AppUser? currentUser;
  String? error;

  /// True for a brand-new account (any provider) that hasn't completed the
  /// post-signup verification step yet — see AppUser.emailConfirmed.
  /// AuthGate shows a "verify your email" screen instead of the normal role
  /// shell while this is true.
  bool get needsEmailVerification => status == SessionStatus.signedIn && currentUser?.emailConfirmed == false;

  void _onAuthChanged(fbUser) {
    _userSub?.cancel();
    _profileWaitTimer?.cancel();
    _profileWaitTimer = null;
    if (fbUser == null) {
      currentUser = null;
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    status = SessionStatus.loading;
    notifyListeners();
    _userSub = _authService.watchAppUser(fbUser.uid).listen(
      (appUser) {
        if (appUser == null) {
          currentUser = null;
          if (_expectingNewProfile) {
            // Signup is still writing the profile doc — keep loading, but
            // don't wait forever if the write never lands.
            _profileWaitTimer ??= Timer(const Duration(seconds: 15), () {
              unawaited(_failMissingProfile());
            });
            notifyListeners();
            return;
          }
          // Persisted Auth session (or deleted profile) with no Firestore
          // doc — previously left AuthGate on the loading spinner forever.
          unawaited(_failMissingProfile());
          return;
        }
        _profileWaitTimer?.cancel();
        _profileWaitTimer = null;
        _expectingNewProfile = false;
        currentUser = appUser;
        status = SessionStatus.signedIn;
        notifyListeners();
      },
      onError: (Object e, StackTrace _) {
        debugPrint('watchAppUser error: $e');
        unawaited(_failMissingProfile(cause: e));
      },
    );
  }

  /// Clears the stuck-loading path: surface a friendly error, flip to
  /// signedOut so AuthGate shows login, then sign out of Auth so the next
  /// launch doesn't restore an orphaned session.
  Future<void> _failMissingProfile({Object? cause}) async {
    _profileWaitTimer?.cancel();
    _profileWaitTimer = null;
    _userSub?.cancel();
    _userSub = null;
    _expectingNewProfile = false;
    currentUser = null;
    error = _friendlyError(cause ?? NoProfileFoundException());
    status = SessionStatus.signedOut;
    notifyListeners();
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('signOut after missing profile failed: $e');
    }
  }

  Future<bool> signIn(String email, String password) async {
    error = null;
    try {
      await _authService.signIn(email: email, password: password);
      return true;
    } catch (e) {
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    String? phone,
  }) async {
    error = null;
    _expectingNewProfile = true;
    try {
      await _authService.registerAccount(name: name, email: email, password: password, role: role, phone: phone);
      return true;
    } catch (e) {
      _expectingNewProfile = false;
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    error = null;
    try {
      await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUpWithGoogle(UserRole role) async {
    error = null;
    _expectingNewProfile = true;
    try {
      await _authService.signUpWithGoogle(role);
      return true;
    } catch (e) {
      _expectingNewProfile = false;
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() => _authService.signOut();

  Future<bool> resendVerificationEmail() => _authService.resendVerificationEmail();

  /// Call after the user says they've clicked the link in their inbox.
  /// For a password account this is a real check — it reloads the Firebase
  /// user and only marks them confirmed if `emailVerified` actually flipped
  /// true. For a Google account there's no equivalent real signal (Google
  /// marks `emailVerified` true itself, from the start), so this just
  /// records the user's self-reported confirmation. Returns false if a
  /// password account still hasn't verified.
  Future<bool> refreshEmailVerified() async {
    if (_authService.isPasswordProvider) {
      await _authService.reloadCurrentUser();
      if (!_authService.isEmailVerified) return false;
    }
    await _authService.markEmailConfirmed();
    return true;
  }

  Future<bool> changePassword({required String currentPassword, required String newPassword}) async {
    error = null;
    try {
      await _authService.changePassword(currentPassword: currentPassword, newPassword: newPassword);
      return true;
    } catch (e) {
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  String _friendlyError(Object e) {
    // Surfaced messages are deliberately generic; the raw error (with its
    // Firebase error code) is logged here so it's visible in `flutter run`
    // output / device logs when diagnosing a report like "login doesn't
    // work" that the friendly copy alone can't distinguish.
    debugPrint('Auth error: $e');
    if (e is NoAccountForGoogleUserException) {
      return 'No account found for that Google sign-in. Please use "Register" first.';
    }
    if (e is NoProfileFoundException) {
      return 'This account has no profile set up in the app. Please register, or contact support.';
    }
    final msg = e.toString();
    if (msg.contains('google-sign-in-cancelled')) return "Google sign-in was cancelled.";
    if (msg.contains('email-already-in-use')) return 'That email is already registered.';
    if (msg.contains('weak-password')) return 'Please choose a stronger password (6+ characters).';
    if (msg.contains('invalid-email')) return 'That email address looks invalid.';
    if (msg.contains('user-not-found') || msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect email or password.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _profileWaitTimer?.cancel();
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
