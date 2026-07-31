import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mamasalama_app/screens/auth/login_screen.dart';
import 'package:mamasalama_app/providers/session_provider.dart';

import 'test_helpers.dart';

Widget _wrap(SessionProvider session) {
  return ChangeNotifierProvider<SessionProvider>.value(
    value: session,
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('renders email/password fields and a Sign In button', (tester) async {
    await tester.pumpWidget(_wrap(SessionProvider(FakeAuthService())));

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Sign In'), findsOneWidget);
  });

  testWidgets('shows an error snack bar when sign-in fails', (tester) async {
    await tester.pumpWidget(_wrap(SessionProvider(FakeAuthService(onSignIn: (_, __) => false))));

    await tester.enterText(find.byType(TextField).at(0), 'mother@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'wrongpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Incorrect email or password.'), findsOneWidget);
  });

  testWidgets('does not show an error snack bar on successful sign-in', (tester) async {
    await tester.pumpWidget(_wrap(SessionProvider(FakeAuthService(onSignIn: (_, __) => true))));

    await tester.enterText(find.byType(TextField).at(0), 'mother@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'correctpass');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('navigates to the signup screen from "Register"', (tester) async {
    await tester.pumpWidget(_wrap(SessionProvider(FakeAuthService())));

    await tester.tap(find.text("Don't have an account? Register"));
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsNothing);
  });
}
