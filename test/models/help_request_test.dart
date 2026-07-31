import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/models/user_models.dart';

void main() {
  group('HelpRequest GPS + transport fields', () {
    test('toDoc serialises location and transport', () {
      final req = HelpRequest(
        id: 'r1',
        motherId: 'm1',
        motherName: 'Diane',
        type: RequestType.sos,
        message: 'SOS',
        createdAt: DateTime(2026, 7, 30),
        lat: -1.9536,
        lng: 30.0606,
        accuracy: 12.5,
        transportStatus: TransportStatus.arranged,
        driverName: 'Jean',
        driverPhone: '+250700000000',
      );

      final doc = req.toDoc();

      expect(doc['lat'], -1.9536);
      expect(doc['lng'], 30.0606);
      expect(doc['accuracy'], 12.5);
      expect(doc['transportStatus'], 'arranged');
      expect(doc['driverName'], 'Jean');
      expect(doc['driverPhone'], '+250700000000');
    });

    test('fromDoc parses location (int or double) and transport', () {
      final req = HelpRequest.fromDoc('r2', {
        'motherId': 'm1',
        'motherName': 'Diane',
        'type': 'sos',
        'message': 'SOS',
        'status': 'assigned',
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 30)),
        'lat': -1, // stored as int — must widen to double
        'lng': 30.0606,
        'accuracy': 12.5,
        'transportStatus': 'arranged',
        'driverName': 'Jean',
        'driverPhone': '+250700000000',
      });

      expect(req.lat, -1.0);
      expect(req.lng, 30.0606);
      expect(req.accuracy, 12.5);
      expect(req.hasLocation, isTrue);
      expect(req.transportStatus, TransportStatus.arranged);
      expect(req.driverName, 'Jean');
      expect(req.driverPhone, '+250700000000');
    });

    test('fromDoc is backward-compatible with old docs (no new fields)', () {
      final req = HelpRequest.fromDoc('r3', {
        'motherId': 'm1',
        'motherName': 'Diane',
        'type': 'general',
        'message': 'help',
        'status': 'pending',
        'createdAt': Timestamp.fromDate(DateTime(2026, 7, 30)),
      });

      expect(req.lat, isNull);
      expect(req.lng, isNull);
      expect(req.hasLocation, isFalse);
      expect(req.transportStatus, TransportStatus.none);
      expect(req.driverName, isNull);
    });

    test('transportStatusFromString maps unknown/null to none', () {
      expect(transportStatusFromString('arranged'), TransportStatus.arranged);
      expect(transportStatusFromString('none'), TransportStatus.none);
      expect(transportStatusFromString(null), TransportStatus.none);
      expect(transportStatusFromString('garbage'), TransportStatus.none);
    });
  });
}
