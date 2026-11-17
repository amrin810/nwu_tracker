import 'package:geolocator/geolocator.dart';
import '../constants/app_constants.dart';
import '../errors/app_exception.dart';
import '../utils/app_logger.dart';

/// Service responsible for GPS positioning, permissions, distance & walking time calculations
class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  /// Check whether GPS location service is enabled on the device
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check the current Android location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request Android location permissions
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Get the user's current GPS position with error handling
  Future<Position?> getCurrentPosition() async {
    final serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        'GPS location services are disabled. Please enable GPS on your Android device.',
      );
    }

    var permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException(
          'Location permission was denied. Distance calculation requires location access.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        'Location permission is permanently denied. Please grant permission in App Settings.',
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to get current GPS position', e);
      return null;
    }
  }

  /// Calculates geodesic distance between two GPS coordinates in meters
  /// Uses Haversine / WGS84 ellipsoidal distance provided by Geolocator
  double calculateDistanceMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  /// Estimates walking time in minutes based on distance (meters) and walking speed (km/h)
  /// Formula: Time (minutes) = Distance (m) / (Speed (km/h) * 1000 m/km / 60 min/h)
  /// At 5.0 km/h: Speed = 83.33 m/min.
  int calculateWalkingTimeMinutes(
    double distanceMeters, {
    double speedKmH = AppConstants.defaultWalkingSpeedKmH,
  }) {
    if (distanceMeters <= 0) return 0;
    final metersPerMinute = (speedKmH * 1000.0) / 60.0;
    final minutes = (distanceMeters / metersPerMinute).ceil();
    return minutes;
  }
}
