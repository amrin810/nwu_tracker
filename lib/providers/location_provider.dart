import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants/app_constants.dart';
import '../core/services/location_service.dart';
import '../core/services/reachability_service.dart';
import '../models/bus_model.dart';
import '../models/bus_location_model.dart';
import '../models/reachability_model.dart';

/// Provider handling user GPS location, permissions, distance & reachability
class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final ReachabilityService _reachabilityService;

  Position? _currentPosition;
  LocationPermission _permissionStatus = LocationPermission.denied;
  bool _isGpsEnabled = false;
  bool _isLoading = false;
  String? _errorMessage;

  double _walkingSpeedKmH = AppConstants.defaultWalkingSpeedKmH;

  LocationProvider({
    LocationService? locationService,
    ReachabilityService? reachabilityService,
  })  : _locationService = locationService ?? LocationService.instance,
        _reachabilityService = reachabilityService ?? ReachabilityService.instance;

  Position? get currentPosition => _currentPosition;
  LocationPermission get permissionStatus => _permissionStatus;
  bool get isGpsEnabled => _isGpsEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get walkingSpeedKmH => _walkingSpeedKmH;

  /// True if valid location permission is granted
  bool get hasPermission =>
      _permissionStatus == LocationPermission.always ||
      _permissionStatus == LocationPermission.whileInUse;

  /// Effective user coordinates (falls back to userPosition for development/testing if GPS unavailable)
  double get latitude => _currentPosition?.latitude ?? AppConstants.defaultUserLatitude;
  double get longitude => _currentPosition?.longitude ?? AppConstants.defaultUserLongitude;
  bool get isUsingFallbackLocation => _currentPosition == null;

  /// Initialize and request GPS location
  Future<void> fetchUserLocation() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isGpsEnabled = await _locationService.isLocationServiceEnabled();
      _permissionStatus = await _locationService.checkPermission();

      if (_permissionStatus == LocationPermission.denied) {
        _permissionStatus = await _locationService.requestPermission();
      }

      if (hasPermission && _isGpsEnabled) {
        _currentPosition = await _locationService.getCurrentPosition();
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Calculates geodesic distance in meters from student to a given bus location
  double calculateDistanceToBus(BusLocation busLocation) {
    return _locationService.calculateDistanceMeters(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: busLocation.latitude,
      endLongitude: busLocation.longitude,
    );
  }

  /// Calculates geodesic distance in meters from student to given coordinates
  double calculateDistanceToCoords(double targetLat, double targetLng) {
    return _locationService.calculateDistanceMeters(
      startLatitude: latitude,
      startLongitude: longitude,
      endLatitude: targetLat,
      endLongitude: targetLng,
    );
  }

  /// Calculates estimated walking time in minutes from student to a given bus location
  int calculateWalkingTimeToBus(BusLocation busLocation) {
    final distanceMeters = calculateDistanceToBus(busLocation);
    return _locationService.calculateWalkingTimeMinutes(
      distanceMeters,
      speedKmH: _walkingSpeedKmH,
    );
  }

  /// Calculates estimated walking time in minutes for a given distance in meters
  int calculateWalkingTimeMinutes(double distanceMeters) {
    return _locationService.calculateWalkingTimeMinutes(
      distanceMeters,
      speedKmH: _walkingSpeedKmH,
    );
  }

  /// Configures walking speed (default 5.0 km/h)
  void setWalkingSpeed(double speed) {
    if (speed > 0) {
      _walkingSpeedKmH = speed;
      notifyListeners();
    }
  }

  /// Computes reachability result for a bus and expected arrival
  ReachabilityResult computeReachability({
    required Bus bus,
    required BusLocation? busLocation,
    int? expectedBusArrivalMinutes,
    bool busHasPassedStop = false,
  }) {
    final distance = busLocation != null ? calculateDistanceToBus(busLocation) : 850.0;
    final walkingMinutes = _locationService.calculateWalkingTimeMinutes(
      distance,
      speedKmH: _walkingSpeedKmH,
    );

    // If bus arrival is not explicitly passed, estimate standard route arrival (e.g. 14 mins)
    final arrivalMinutes = expectedBusArrivalMinutes ?? (walkingMinutes + 4);

    return _reachabilityService.calculate(
      busId: bus.id,
      busNumber: bus.busNumber,
      distanceMeters: distance,
      walkingTimeMinutes: walkingMinutes,
      busArrivalMinutes: arrivalMinutes,
      busHasPassedStop: busHasPassedStop,
    );
  }
}
