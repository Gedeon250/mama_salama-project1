import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:mamasalama_app/models/user_models.dart';
import 'package:mamasalama_app/providers/session_provider.dart';
import 'package:mamasalama_app/screens/appointments_screen.dart';
import 'package:mamasalama_app/services/firestore_service.dart';

import 'test_helpers.dart';

Widget _wrap(FirestoreService firestore) {
  final session = SessionProvider(FakeAuthService())
    ..currentUser = AppUser(uid: 'mother-1', name: 'Sarah', email: 's@example.com', role: UserRole.mother)
    ..status = SessionStatus.signedIn;

  return ChangeNotifierProvider<SessionProvider>.value(
    value: session,
    child: MaterialApp(home: AppointmentsScreen(firestoreOverride: firestore)),
  );
}

void main() {
  // The default 800x600 test surface is too short for this screen's
  // ListView — the "History" section and its "Book New" button end up below
  // the fold, so plain find.text()/tap() can't see them. A tall surface
  // avoids needing to scroll to reach them.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.physicalSize = const Size(1080, 4000);
    binding.platformDispatcher.views.first.devicePixelRatio = 1.0;
    addTearDown(binding.platformDispatcher.views.first.resetPhysicalSize);
    addTearDown(binding.platformDispatcher.views.first.resetDevicePixelRatio);
  });

  testWidgets('shows empty state when there are no appointments yet', (tester) async {
    await tester.pumpWidget(_wrap(FirestoreService(firestore: FakeFirebaseFirestore())));
    await tester.pumpAndSettle();

    expect(find.text('No upcoming appointments.'), findsOneWidget);
    expect(find.text('No past appointments yet.'), findsOneWidget);
  });

  testWidgets('booking an appointment adds it to the Upcoming list', (tester) async {
    final fakeDb = FakeFirebaseFirestore();
    await tester.pumpWidget(_wrap(FirestoreService(firestore: fakeDb)));
    await tester.pumpAndSettle();

    // Tap the label directly rather than find.widgetWithText(ElevatedButton,
    // ...): ElevatedButton.icon() returns a private subclass, and
    // find.byType/widgetWithText match by exact runtime type, so they never
    // match it.
    await tester.tap(find.text('Book New'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Reason for visit'), 'Routine checkup');
    await tester.enterText(find.widgetWithText(TextField, 'Provider / hospital'), 'Kigali Hospital');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirm Booking'));
    await tester.pumpAndSettle();

    expect(find.text('Appointment booked!'), findsOneWidget);
    expect(find.text('Routine checkup'), findsOneWidget);
    expect(find.text('Kigali Hospital'), findsOneWidget);
    expect(find.text('No upcoming appointments.'), findsNothing);

    final stored = await fakeDb.collection('appointments').get();
    expect(stored.docs, hasLength(1));
    expect(stored.docs.first.data()['motherId'], 'mother-1');
  });
}
