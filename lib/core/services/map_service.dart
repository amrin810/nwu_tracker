import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../../main.dart';

export '../../main.dart' show campus, userPosition;

/// Helper service for Google Maps camera positioning, bounds calculation and markers
class MapService {
  MapService._();

  /// Default Camera position centered on university campus
  static CameraPosition get defaultCameraPosition => const CameraPosition(
        target: campus,
        zoom: AppConstants.defaultMapZoom,
      );

  /// Computes LatLngBounds to fit a list of coordinates into the viewport
  static LatLngBounds boundsFromLatLngList(List<LatLng> list) {
    assert(list.isNotEmpty, 'List of LatLng must not be empty');

    double minLat = list.first.latitude;
    double maxLat = list.first.latitude;
    double minLng = list.first.longitude;
    double maxLng = list.first.longitude;

    for (final latLng in list) {
      if (latLng.latitude < minLat) minLat = latLng.latitude;
      if (latLng.latitude > maxLat) maxLat = latLng.latitude;
      if (latLng.longitude < minLng) minLng = latLng.longitude;
      if (latLng.longitude > maxLng) maxLng = latLng.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }
}
