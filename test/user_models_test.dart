import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/models/user_models.dart';

void main() {
  group('roleFromString / roleToString', () {
    test('round-trips every known role', () {
      for (final role in UserRole.values) {
        expect(roleFromString(roleToString(role)), role);
      }
    });

    test('falls back to mother for an unknown or missing role', () {
      expect(roleFromString('not-a-real-role'), UserRole.mother);
      expect(roleFromString(null), UserRole.mother);
    });
  });

  group('AppUser', () {
    test('toDoc/fromDoc round-trip preserves every field', () {
      final user = AppUser(
        uid: 'uid-1',
        name: 'Sifa Mutoni',
        email: 'sifa@example.com',
        role: UserRole.chw,
        assignedChwId: null,
        phone: '+250700000000',
      );

      final restored = AppUser.fromDoc(user.uid, user.toDoc());

      expect(restored.uid, user.uid);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.role, user.role);
      expect(restored.phone, user.phone);
    });

    test('omits optional fields from the doc when null', () {
      final user = AppUser(uid: 'uid-2', name: 'Anna', email: 'a@example.com', role: UserRole.mother);
      final doc = user.toDoc();
      expect(doc.containsKey('assignedChwId'), isFalse);
      expect(doc.containsKey('phone'), isFalse);
    });
  });

  group('MedicalRecord', () {
    test('toDoc/fromDoc round-trip preserves every field', () {
      final date = DateTime(2026, 3, 14);
      final record = MedicalRecord(
        id: '',
        motherId: 'mother-1',
        title: 'Routine checkup',
        category: 'Visit note',
        date: date,
        summary: 'Blood pressure normal, baby heartbeat strong.',
      );

      final restored = MedicalRecord.fromDoc('record-1', record.toDoc());

      expect(restored.id, 'record-1');
      expect(restored.motherId, record.motherId);
      expect(restored.title, record.title);
      expect(restored.category, record.category);
      expect(restored.date, date);
      expect(restored.summary, record.summary);
    });

    test('fromDoc defaults missing string fields to empty rather than throwing', () {
      final restored = MedicalRecord.fromDoc('record-2', {'date': Timestamp.fromDate(DateTime(2026, 1, 1))});
      expect(restored.motherId, '');
      expect(restored.title, '');
      expect(restored.category, '');
      expect(restored.summary, '');
    });
  });
}
