import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/nwu_default_data.dart';
import '../core/utils/app_logger.dart';
import '../models/bus_model.dart';
import '../models/bus_location_model.dart';
import '../models/route_model.dart';
import '../models/stop_model.dart';
import '../models/schedule_model.dart';
import '../models/pickup_request_model.dart';

/// Repository managing transportation data access via Cloud Firestore
class BusRepository {
  final FirebaseFirestore _firestore;

  BusRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // In-memory cache initialized with clean NWU defaults for offline resilience
  List<Bus> _cachedBuses = List.from(NWUDefaultData.defaultBuses);
  List<BusRoute> _cachedRoutes = List.from(NWUDefaultData.defaultRoutes);
  List<BusSchedule> _cachedSchedules = List.from(NWUDefaultData.defaultSchedules);

  /// Fetch all university buses from Cloud Firestore: 'buses'
  Future<List<Bus>> getBuses() async {
    try {
      final snapshot = await _firestore.collection('buses').get();
      if (snapshot.docs.isNotEmpty) {
        _cachedBuses = snapshot.docs
            .map((doc) => Bus.fromJson(doc.data()))
            .toList()
          ..sort((a, b) => a.busNumber.compareTo(b.busNumber));
        return _cachedBuses;
      } else {
        // Seed default NWU fleet if Firestore collection is empty
        await _seedDefaultBuses();
        return _cachedBuses;
      }
    } catch (e) {
      AppLogger.warning('Cloud Firestore buses fetch skipped/offline: $e');
      return _cachedBuses;
    }
  }

  /// Fetch all bus routes from Cloud Firestore: 'routes'
  Future<List<BusRoute>> getRoutes() async {
    try {
      final snapshot = await _firestore.collection('routes').get();
      if (snapshot.docs.isNotEmpty) {
        final routes = <BusRoute>[];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          List<BusStop> stops = [];
          if (data['stops'] is List) {
            stops = (data['stops'] as List<dynamic>)
                .map((s) => BusStop.fromJson(s as Map<String, dynamic>))
                .toList()
              ..sort((a, b) => a.sequenceOrder.compareTo(b.sequenceOrder));
          } else {
            // Check subcollection 'stops'
            try {
              final stopsSnap = await doc.reference
                  .collection('stops')
                  .orderBy('sequence_order')
                  .get();
              stops = stopsSnap.docs
                  .map((sDoc) => BusStop.fromJson(sDoc.data()))
                  .toList();
            } catch (_) {}
          }
          routes.add(BusRoute.fromJson(data, stops));
        }
        routes.sort((a, b) => a.routeName.compareTo(b.routeName));
        _cachedRoutes = routes;
        return _cachedRoutes;
      } else {
        await _seedDefaultRoutes();
        return _cachedRoutes;
      }
    } catch (e) {
      AppLogger.warning('Cloud Firestore routes fetch skipped/offline: $e');
      return _cachedRoutes;
    }
  }

  /// Fetch stops for a specific route
  Future<List<BusStop>> getStopsForRoute(String routeId) async {
    final route = _cachedRoutes.firstWhere(
      (r) => r.id == routeId,
      orElse: () => _cachedRoutes.isNotEmpty
          ? _cachedRoutes.first
          : NWUDefaultData.defaultRoutes.first,
    );
    return route.stops;
  }

  /// Fetch bus schedules from Cloud Firestore: 'schedules'
  Future<List<BusSchedule>> getSchedules() async {
    try {
      final snapshot = await _firestore.collection('schedules').get();
      if (snapshot.docs.isNotEmpty) {
        _cachedSchedules = snapshot.docs
            .map((doc) => BusSchedule.fromJson(doc.data()))
            .toList();
        return _cachedSchedules;
      } else {
        await _seedDefaultSchedules();
        return _cachedSchedules;
      }
    } catch (e) {
      AppLogger.warning('Cloud Firestore schedules fetch skipped/offline: $e');
      return _cachedSchedules;
    }
  }

  /// Fetch live bus locations from Cloud Firestore
  /// Note: Primary live GPS streaming is handled in real time via BusLocationService (Firebase RTDB).
  Future<Map<String, BusLocation>> getBusLocations() async {
    try {
      final snapshot = await _firestore.collection('bus_locations').get();
      final map = <String, BusLocation>{};
      for (final doc in snapshot.docs) {
        final loc = BusLocation.fromJson(doc.data());
        map[loc.busId] = loc;
      }
      return map;
    } catch (e) {
      AppLogger.warning('Cloud Firestore bus_locations fetch notice: $e');
      return {};
    }
  }

  /// Fetch pickup requests from Cloud Firestore: 'pickup_requests'
  Future<List<PickupRequest>> getPickupRequests({String? studentId}) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection('pickup_requests');
      if (studentId != null && studentId.isNotEmpty) {
        query = query.where('student_id', isEqualTo: studentId);
      }
      final snapshot = await query.get();
      final requests = snapshot.docs
          .map((doc) => PickupRequest.fromJson(doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return requests;
    } catch (e) {
      AppLogger.warning('Cloud Firestore pickup_requests fetch notice: $e');
      return [];
    }
  }

  /// Submit a new pickup request to Cloud Firestore: 'pickup_requests/{id}'
  Future<bool> submitPickupRequest(PickupRequest request) async {
    try {
      await _firestore
          .collection('pickup_requests')
          .doc(request.id)
          .set(request.toJson());
      AppLogger.info('Submitted pickup request to Cloud Firestore: ${request.id}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to submit pickup request to Cloud Firestore', e);
      return false;
    }
  }

  /// Update pickup request status in Cloud Firestore: 'pickup_requests/{id}'
  Future<bool> updatePickupRequestStatus(
    String requestId,
    PickupRequestStatus status,
  ) async {
    try {
      await _firestore.collection('pickup_requests').doc(requestId).update({
        'status': status.name,
        'updated_at': DateTime.now().toIso8601String(),
      });
      AppLogger.info('Updated request $requestId status to ${status.name}');
      return true;
    } catch (e) {
      AppLogger.error('Failed to update request status in Cloud Firestore', e);
      return false;
    }
  }

  // --- Automatic Seeding of Default NWU Fleet to Cloud Firestore ---

  Future<void> _seedDefaultBuses() async {
    try {
      final batch = _firestore.batch();
      for (final bus in NWUDefaultData.defaultBuses) {
        final docRef = _firestore.collection('buses').doc(bus.id);
        batch.set(docRef, bus.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.info('Seeded default NWU buses to Cloud Firestore');
    } catch (e) {
      AppLogger.warning('Could not seed default buses: $e');
    }
  }

  Future<void> _seedDefaultRoutes() async {
    try {
      final batch = _firestore.batch();
      for (final route in NWUDefaultData.defaultRoutes) {
        final docRef = _firestore.collection('routes').doc(route.id);
        final routeMap = route.toJson();
        routeMap['stops'] = route.stops.map((s) => s.toJson()).toList();
        batch.set(docRef, routeMap, SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.info('Seeded default NWU routes to Cloud Firestore');
    } catch (e) {
      AppLogger.warning('Could not seed default routes: $e');
    }
  }

  Future<void> _seedDefaultSchedules() async {
    try {
      final batch = _firestore.batch();
      for (final schedule in NWUDefaultData.defaultSchedules) {
        final docRef = _firestore.collection('schedules').doc(schedule.id);
        batch.set(docRef, schedule.toJson(), SetOptions(merge: true));
      }
      await batch.commit();
      AppLogger.info('Seeded default NWU schedules to Cloud Firestore');
    } catch (e) {
      AppLogger.warning('Could not seed default schedules: $e');
    }
  }
}
