import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/services/firestore_service.dart';

void main() {
  late FirestoreService firestore;

  setUp(() {
    firestore = FirestoreService(firestore: FakeFirebaseFirestore());
  });

  group('threadIdFor', () {
    test('is stable regardless of argument order', () {
      final a = firestore.threadIdFor('uidA', 'uidB');
      final b = firestore.threadIdFor('uidB', 'uidA');
      expect(a, b);
    });

    test('joins both uids, sorted, with an underscore', () {
      expect(firestore.threadIdFor('zzz', 'aaa'), 'aaa_zzz');
    });
  });
}
