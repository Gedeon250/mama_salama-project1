import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mamasalama_app/l10n/generated/app_localizations.dart';
import 'package:mamasalama_app/providers/app_data.dart';
import 'package:mamasalama_app/providers/session_provider.dart';
import 'package:mamasalama_app/screens/emergency_sos_screen.dart';
import 'package:mamasalama_app/services/firestore_service.dart';

import 'test_helpers.dart';

Widget _wrap() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppData()),
      ChangeNotifierProvider(create: (_) => SessionProvider(FakeAuthService())),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // A mother isn't signed in here (SessionProvider.currentUser stays
      // null), so _triggerSos's Firestore write is skipped entirely — but
      // the FirestoreService field is still constructed unconditionally, so
      // it must be backed by a fake, not the real Firebase singleton.
      home: EmergencySosScreen(firestoreOverride: FirestoreService(firestore: FakeFirebaseFirestore())),
    ),
  );
}

void main() {
  testWidgets('starts idle, showing the call-to-action', (tester) async {
    // Not pumpAndSettle(): the SOS circle's pulse AnimationController repeats
    // forever, so "settled" never happens. A few fixed pumps are enough to
    // flush the initial frame and localization loading.
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('TAP TO CALL AMBULANCE'), findsOneWidget);
    expect(find.text('Cancel Emergency Alert'), findsNothing);
  });

  testWidgets('tapping the SOS circle starts dispatch and shows Cancel', (tester) async {
    // Not pumpAndSettle(): the SOS circle's pulse AnimationController repeats
    // forever, so "settled" never happens. A few fixed pumps are enough to
    // flush the initial frame and localization loading.
    await tester.pumpWidget(_wrap());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('TAP TO CALL AMBULANCE'));
    await tester.pump();

    expect(find.text('DISPATCH IN PROGRESS'), findsOneWidget);
    expect(find.text('Cancel Emergency Alert'), findsOneWidget);

    await tester.tap(find.text('Cancel Emergency Alert'));
    await tester.pump();

    expect(find.text('TAP TO CALL AMBULANCE'), findsOneWidget);
    expect(find.text('Cancel Emergency Alert'), findsNothing);
  });
}
