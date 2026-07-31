import 'package:geolocator/geolocator.dart';

/// A single GPS reading attached to an SOS.
class LocationFix {
  final double lat;
  final double lng;
  final double accuracy; // metres
  const LocationFix(this.lat, this.lng, this.accuracy);
}

/// Best-effort location for an emergency SOS (Gap 3).
///
/// The guiding rule: an SOS must NEVER be blocked or delayed by location.
/// Every failure path — services off, permission denied, timeout, plugin
/// error — resolves to `null` so the caller can send the alert without a fix
/// and simply mark the location "unavailable".
class LocationService {
  const LocationService();

  Future<LocationFix?> tryGetFix({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return LocationFix(pos.latitude, pos.longitude, pos.accuracy);
    } catch (_) {
      // Timeout, plugin/platform error, permanently denied — never surface to
      // the SOS flow; a missing fix is handled gracefully upstream.
      return null;
    }
  }
}
