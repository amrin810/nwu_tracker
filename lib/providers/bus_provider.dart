import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/bus_model.dart';
import '../models/bus_location_model.dart';
import '../models/live_bus_location.dart';
import '../models/route_model.dart';
import '../models/schedule_model.dart';
import '../models/pickup_request_model.dart';
import '../repositories/bus_repository.dart';
import '../services/bus_location_service.dart';

/// Provider managing transportation assets: buses, routes, schedules, locations & requests
class BusProvider extends ChangeNotifier {
  final BusRepository _busRepository;
  final BusLocationService _busLocationService;
  StreamSubscription<Map<String, LiveBusLocation>>? _liveLocationsSubscription;

  List<Bus> _buses = [];
  List<BusRoute> _routes = [];
  List<BusSchedule> _schedules = [];
  Map<String, BusLocation> _busLocations = {};
  Map<String, LiveBusLocation> _liveLocations = {};
  List<PickupRequest> _pickupRequests = [];

  Bus? _selectedBus;
  bool _isLoading = false;
  String? _errorMessage;

  BusProvider({
    BusRepository? busRepository,
    BusLocationService? busLocationService,
  })  : _busRepository = busRepository ?? BusRepository(),
        _busLocationService = busLocationService ?? BusLocationService.instance {
    _initLiveLocationStream();
  }

  void _initLiveLocationStream() {
    _liveLocationsSubscription =
        _busLocationService.allBusLocationsStream.listen((locations) {
      _liveLocations = locations;
      notifyListeners();
    }, onError: (e) {
      AppLogger.warning('BusProvider live GPS stream notice: $e');
    });
  }

  @override
  void dispose() {
    _liveLocationsSubscription?.cancel();
    super.dispose();
  }

  List<Bus> get buses => _buses;
  List<BusRoute> get routes => _routes;
  List<BusSchedule> get schedules => _schedules;
  Map<String, BusLocation> get busLocations => _busLocations;
  Map<String, LiveBusLocation> get liveLocations => _liveLocations;
  List<PickupRequest> get pickupRequests => _pickupRequests;
  Bus? get selectedBus => _selectedBus;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns only currently active buses
  List<Bus> get activeBuses =>
      _buses.where((b) => b.status == BusStatus.active).toList();

  /// Loads all foundational transportation data from Cloud Firestore
  Future<void> fetchAllData({String? studentId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _busRepository.getBuses(),
        _busRepository.getRoutes(),
        _busRepository.getSchedules(),
        _busRepository.getBusLocations(),
        _busRepository.getPickupRequests(studentId: studentId),
      ]);

      _buses = results[0] as List<Bus>;
      _routes = results[1] as List<BusRoute>;
      _schedules = results[2] as List<BusSchedule>;
      _busLocations = results[3] as Map<String, BusLocation>;
      _pickupRequests = results[4] as List<PickupRequest>;

      if ((_selectedBus == null || !_buses.any((b) => b.id == _selectedBus!.id)) &&
          _buses.isNotEmpty) {
        _selectedBus = _buses.first;
      }
    } catch (e) {
      _errorMessage = 'Failed to load transportation data: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the currently inspected bus
  void selectBus(Bus? bus) {
    _selectedBus = bus;
    notifyListeners();
  }

  /// Selects bus by ID
  void selectBusById(String busId) {
    final match = _buses.where((b) => b.id == busId).firstOrNull;
    if (match != null) {
      _selectedBus = match;
      notifyListeners();
    }
  }

  /// Returns valid, active, non-stale live GPS telemetry for a bus, or null if unavailable
  LiveBusLocation? getValidLiveLocation(String busId) {
    final rtdbId = AppConstants.toRtdbBusId(busId);
    final modelId = AppConstants.toModelBusId(busId);
    final loc = _liveLocations[rtdbId] ?? _liveLocations[modelId] ?? _liveLocations[busId];
    if (loc != null && loc.isLive) {
      return loc;
    }
    return null;
  }

  /// Retrieves live location for a specific bus.
  /// Rule: Buses with no valid live location return null so screens show "Location unavailable",
  /// never an old/mock position.
  BusLocation? getLocationForBus(String busId) {
    final live = getValidLiveLocation(busId);
    if (live != null) {
      return BusLocation(
        busId: AppConstants.toModelBusId(busId),
        latitude: live.latitude,
        longitude: live.longitude,
        speedKmH: live.speed,
        updatedAt: live.lastUpdated,
      );
    }
    return null;
  }

  /// Submits a student pickup request
  Future<bool> submitPickupRequest(PickupRequest request) async {
    _isLoading = true;
    notifyListeners();

    try {
      final success = await _busRepository.submitPickupRequest(request);
      if (success) {
        _pickupRequests.insert(0, request);
      }
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates status of a pickup request (Admin/Conductor)
  Future<bool> updateRequestStatus(String requestId, PickupRequestStatus status) async {
    final success = await _busRepository.updatePickupRequestStatus(requestId, status);
    if (success) {
      final idx = _pickupRequests.indexWhere((r) => r.id == requestId);
      if (idx != -1) {
        final old = _pickupRequests[idx];
        _pickupRequests[idx] = PickupRequest(
          id: old.id,
          studentId: old.studentId,
          studentName: old.studentName,
          studentPhone: old.studentPhone,
          busId: old.busId,
          busNumber: old.busNumber,
          routeId: old.routeId,
          routeName: old.routeName,
          stopId: old.stopId,
          stopName: old.stopName,
          status: status,
          message: old.message,
          createdAt: old.createdAt,
        );
        notifyListeners();
      }
    }
    return success;
  }
}
