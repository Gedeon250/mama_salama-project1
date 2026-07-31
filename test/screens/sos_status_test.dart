import 'package:flutter_test/flutter_test.dart';
import 'package:mamasalama_app/models/user_models.dart';
import 'package:mamasalama_app/screens/sos_status.dart';

HelpRequest _req({
  RequestStatus status = RequestStatus.pending,
  String? chwName,
  TransportStatus transport = TransportStatus.none,
}) {
  return HelpRequest(
    id: 'r1',
    motherId: 'm1',
    motherName: 'Diane',
    type: RequestType.sos,
    message: 'SOS',
    status: status,
    assignedChwName: chwName,
    transportStatus: transport,
    createdAt: DateTime(2026, 7, 30),
  );
}

void main() {
  group('sosViewFor', () {
    test('no request yet, locating', () {
      final v = sosViewFor(null, locating: true);
      expect(v.label, contains('location'));
      expect(v.progress, 0.15);
    });

    test('no request yet, sending', () {
      final v = sosViewFor(null, locating: false);
      expect(v.label, contains('Sending'));
    });

    test('pending', () {
      final v = sosViewFor(_req(status: RequestStatus.pending), locating: false);
      expect(v.label, contains('Finding'));
      expect(v.progress, 0.35);
    });

    test('assigned names the CHW', () {
      final v = sosViewFor(
        _req(status: RequestStatus.assigned, chwName: 'Jean'),
        locating: false,
      );
      expect(v.label, contains('Jean'));
      expect(v.progress, 0.65);
    });

    test('assigned falls back when CHW name missing', () {
      final v = sosViewFor(_req(status: RequestStatus.assigned), locating: false);
      expect(v.label, contains('health worker'));
    });

    test('transport arranged outranks plain assigned', () {
      final v = sosViewFor(
        _req(
          status: RequestStatus.assigned,
          chwName: 'Jean',
          transport: TransportStatus.arranged,
        ),
        locating: false,
      );
      expect(v.label, contains('Transport'));
      expect(v.progress, 0.85);
    });

    test('resolved', () {
      final v = sosViewFor(_req(status: RequestStatus.resolved), locating: false);
      expect(v.label, contains('resolved'));
      expect(v.progress, 1.0);
    });
  });
}
