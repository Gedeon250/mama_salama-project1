import 'package:url_launcher/url_launcher.dart';

/// Opens the phone dialer prefilled with [phone] (tap-to-call a CHW or driver).
Future<bool> callNumber(String phone) {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  return launchUrl(uri);
}

/// Opens the coordinates in the device's maps app so a CHW can navigate to
/// the mother's SOS location.
Future<bool> openInMaps(double lat, double lng) {
  final uri = Uri.parse(
    'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
