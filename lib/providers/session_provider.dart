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

  SessionProvider(this._authService) {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  SessionStatus status = SessionStatus.loading;
  AppUser? currentUser;
  String? error;

  void _onAuthChanged(fbUser) {
    _userSub?.cancel();
    if (fbUser == null) {
      currentUser = null;
      status = SessionStatus.signedOut;
      notifyListeners();
      return;
    }
    _userSub = _authService.watchAppUser(fbUser.uid).listen((appUser) {
      currentUser = appUser;
      status = appUser == null ? SessionStatus.loading : SessionStatus.signedIn;
      notifyListeners();
    });
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
    try {
      await _authService.registerAccount(name: name, email: email, password: password, role: role, phone: phone);
      return true;
    } catch (e) {
      error = _friendlyError(e);
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() => _authService.signOut();

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
    final msg = e.toString();
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
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
