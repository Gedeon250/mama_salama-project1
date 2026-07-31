import '../models/user_models.dart';

/// What the mother's SOS "Live Status" card shows for a given request state.
/// Pure and UI-free so it can be unit-tested; the widget just renders it.
class SosView {
  final String label;
  final double progress; // 0..1 for the ProgressTrack
  const SosView(this.label, this.progress);
}

/// Maps the real [HelpRequest] lifecycle (from Firestore) to the mother's
/// live status. [locating] is true only in the brief window between tapping
/// SOS and the request appearing in the stream.
SosView sosViewFor(HelpRequest? request, {required bool locating}) {
  if (request == null) {
    return SosView(
      locating ? 'Getting your location…' : 'Sending your alert…',
      0.15,
    );
  }
  switch (request.status) {
    case RequestStatus.pending:
      return const SosView('Alert sent. Finding a nearby health worker…', 0.35);
    case RequestStatus.assigned:
      if (request.transportStatus == TransportStatus.arranged) {
        return const SosView('Transport arranged — help is on the way.', 0.85);
      }
      final name = request.assignedChwName ?? 'A health worker';
      return SosView('$name is responding and will reach you soon.', 0.65);
    case RequestStatus.resolved:
      return const SosView('Marked resolved. Stay safe. 💚', 1.0);
  }
}
