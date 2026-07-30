import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:mamasalama_app/services/auth_service.dart';

/// AuthService's methods aren't final, so subclassing here overrides the
/// real FirebaseAuth-backed behavior without ever touching Firebase — no
/// Firebase.initializeApp() needed in these widget tests. The super
/// constructor still runs, though, so it needs fakes for `auth`/`firestore`
/// rather than the real singletons (which throw without Firebase.initializeApp()).
class FakeAuthService extends AuthService {
  final bool Function(String email, String password)? onSignIn;

  FakeAuthService({this.onSignIn}) : super(auth: MockFirebaseAuth(), firestore: FakeFirebaseFirestore());

  @override
  Stream<fb.User?> get authStateChanges => const Stream.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {
    final ok = onSignIn?.call(email, password) ?? true;
    if (!ok) throw Exception('invalid-credential');
  }
}
