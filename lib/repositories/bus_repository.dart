import '../core/constants/demo_data.dart';
import '../core/services/supabase_service.dart';
import '../core/utils/app_logger.dart';
import '../models/bus_model.dart';
import '../models/bus_location_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/schedule_model.dart';
import '../models/pickup_request_model.dart';

/// Repository managing transportation data access (Supabase with Demo fallback)
class BusRepository {
  final SupabaseService _supabaseService;

  BusRepository({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService.instance;

  bool get _isSupabaseActive => _supabaseService.isInitialized;

  // Local state for demo updates during testing
  final List<Bus> _inMemoryBuses = List.from(DemoData.demoBuses);
  final List<BusRoute> _inMemoryRoutes = List.from(DemoData.demoRoutes);
  final List<BusSchedule> _inMemorySchedules = List.from(DemoData.demoSchedules);
  final Map<String, BusLocation> _inMemoryLocations = Map.from(DemoData.initialBusLocations);
  final List<PickupRequest> _inMemoryRequests = List.from(DemoData.demoPickupRequests);

  /// Fetch all university buses
  Future<List<Bus>> getBuses() async {
    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!
            .from('buses')
            .select()
            .order('bus_number');
        final data = response as List<dynamic>;
        return data.map((json) => Bus.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        AppLogger.error('Failed to fetch buses from Supabase, falling back to local data', e);
      }
    }
    return _inMemoryBuses;
  }

  /// Fetch all bus routes
  Future<List<BusRoute>> getRoutes() async {
    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!
            .from('routes')
            .select('*, stops(*)')
            .order('route_name');
        final data = response as List<dynamic>;
        return data.map((json) {
          final stopsData = (json['stops'] as List<dynamic>?) ?? [];
          final stops = stopsData
              .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
          return BusRoute.fromJson(json as Map<String, dynamic>, stops);
        }).toList();
      } catch (e) {
        AppLogger.error('Failed to fetch routes from Supabase', e);
      }
    }
    return _inMemoryRoutes;
  }

  /// Fetch stops for a specific route
  Future<List<BusStop>> getStopsForRoute(String routeId) async {
    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!
            .from('stops')
            .select()
            .eq('route_id', routeId)
            .order('sequence_order');
        final data = response as List<dynamic>;
        return data.map((json) => BusStop.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        AppLogger.error('Failed to fetch stops from Supabase', e);
      }
    }
    final route = _inMemoryRoutes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => _inMemoryRoutes.first,
    );
    return route.stops;
  }

  /// Fetch bus schedules
  Future<List<BusSchedule>> getSchedules() async {
    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!
            .from('schedules')
            .select()
            .order('departure_time');
        final data = response as List<dynamic>;
        return data.map((json) => BusSchedule.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        AppLogger.error('Failed to fetch schedules from Supabase', e);
      }
    }
    return _inMemorySchedules;
  }

  /// Fetch live bus locations
  Future<Map<String, BusLocation>> getBusLocations() async {
    if (_isSupabaseActive) {
      try {
        final response = await _supabaseService.client!
            .from('bus_locations')
            .select();
        final data = response as List<dynamic>;
        final map = <String, BusLocation>{};
        for (final item in data) {
          final loc = BusLocation.fromJson(item as Map<String, dynamic>);
          map[loc.busId] = loc;
        }
        return map;
      } catch (e) {
        AppLogger.error('Failed to fetch bus locations from Supabase', e);
      }
    }
    return _inMemoryLocations;
  }

  /// Fetch pickup requests (for student or all for admin/conductor)
  Future<List<PickupRequest>> getPickupRequests({String? studentId}) async {
    if (_isSupabaseActive) {
      try {
        var query = _supabaseService.client!.from('pickup_requests').select();
        if (studentId != null) {
          query = query.eq('student_id', studentId);
        }
        final response = await query.order('created_at', ascending: false);
        final data = response as List<dynamic>;
        return data.map((json) => PickupRequest.fromJson(json as Map<String, dynamic>)).toList();
      } catch (e) {
        AppLogger.error('Failed to fetch pickup requests from Supabase', e);
      }
    }
    if (studentId != null) {
      return _inMemoryRequests.where((r) => r.studentId == studentId).toList();
    }
    return _inMemoryRequests;
  }

  /// Submit a new pickup request
  Future<bool> submitPickupRequest(PickupRequest request) async {
    if (_isSupabaseActive) {
      try {
        await _supabaseService.client!.from('pickup_requests').insert(request.toJson());
        return true;
      } catch (e) {
        AppLogger.error('Failed to submit pickup request to Supabase', e);
        return false;
      }
    }
    _inMemoryRequests.insert(0, request);
    return true;
  }

  /// Update pickup request status (Admin / Conductor action)
  Future<bool> updatePickupRequestStatus(String requestId, PickupRequestStatus status) async {
    if (_isSupabaseActive) {
      try {
        await _supabaseService.client!
            .from('pickup_requests')
            .update({'status': status.name})
            .eq('id', requestId);
        return true;
      } catch (e) {
        AppLogger.error('Failed to update request status in Supabase', e);
        return false;
      }
    }
    final index = _inMemoryRequests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final old = _inMemoryRequests[index];
      _inMemoryRequests[index] = PickupRequest(
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
      return true;
    }
    return false;
  }

  /// Updates simulated location for a bus during demo mode
  void updateDemoLocation(String busId, double lat, double lng, {String? stopName}) {
    _inMemoryLocations[busId] = BusLocation(
      busId: busId,
      latitude: lat,
      longitude: lng,
      speedKmH: 28.0,
      heading: 0.0,
      updatedAt: DateTime.now(),
      isDemo: true,
      lastKnownStopName: stopName,
    );
  }
}
