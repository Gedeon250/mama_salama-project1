import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/providers/session_provider.dart';

import 'test_helpers.dart';

void main() {
  group('SessionProvider.signIn', () {
    test('returns true and clears error on success', () async {
      final session = SessionProvider(FakeAuthService(onSignIn: (_, __) => true));

      final ok = await session.signIn('mother@example.com', 'password123');

      expect(ok, isTrue);
      expect(session.error, isNull);
    });

    test('returns false and sets a friendly message on failure', () async {
      final session = SessionProvider(FakeAuthService(onSignIn: (_, __) => false));

      final ok = await session.signIn('mother@example.com', 'wrong-password');

      expect(ok, isFalse);
      expect(session.error, 'Incorrect email or password.');
    });
  });
}
