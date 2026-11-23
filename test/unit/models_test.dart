import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/models/bus_model.dart';
import 'package:bus_tracking/models/bus_location_model.dart';
import 'package:bus_tracking/models/pickup_request_model.dart';
import 'package:bus_tracking/models/route_model.dart';
import 'package:bus_tracking/models/schedule_model.dart';
import 'package:bus_tracking/models/stop_model.dart';
import 'package:bus_tracking/models/user_model.dart';
import 'package:bus_tracking/core/constants/app_constants.dart';

void main() {
  group('Models Serialization and Logic Tests', () {
    test('AppUser serialization and backward compatibility', () {
      final user = const AppUser(
        id: 'usr-123',
        email: 'student@nwu.edu.bd',
        fullName: 'Student User',
        userId: 'CSE-22-0100',
        phone: '01700000000',
        role: UserRole.student,
      );

      final json = user.toJson();
      expect(json['id'], 'usr-123');
      expect(json['email'], 'student@nwu.edu.bd');
      expect(json['role'], 'student');

      final fromJson = AppUser.fromJson(json);
      expect(fromJson.id, user.id);
      expect(fromJson.studentId, 'CSE-22-0100');
      expect(fromJson.role, UserRole.student);
    });

    test('Bus and BusStatus serialization', () {
      final bus = const Bus(
        id: 'bus-101',
        busNumber: 'Bus 101',
        busName: 'Campus Express Sonadanga',
        licensePlate: 'KLN-METRO-BA-11-2041',
        capacity: 52,
        status: BusStatus.active,
      );

      final json = bus.toJson();
      final fromJson = Bus.fromJson(json);

      expect(fromJson.id, 'bus-101');
      expect(fromJson.busNumber, 'Bus 101');
      expect(fromJson.status, BusStatus.active);
      expect(fromJson.status.toFormattedString(), 'Active');
    });

    test('BusRoute and BusStop serialization', () {
      const stop = BusStop(
        id: 'stop-1',
        stopName: 'Campus Main Gate',
        latitude: 22.8200,
        longitude: 89.5400,
        sequenceOrder: 1,
      );

      final route = BusRoute(
        id: 'route-sonadanga',
        routeName: 'Campus ➔ Sonadanga',
        startPoint: 'Campus Main Gate',
        endPoint: 'Sonadanga',
        totalDistanceKm: 8.5,
        estimatedDurationMinutes: 25,
        stops: const [stop],
      );

      final json = route.toJson();
      final fromJson = BusRoute.fromJson(json, [stop]);

      expect(fromJson.id, 'route-sonadanga');
      expect(fromJson.stops.length, 1);
      expect(fromJson.stops.first.stopName, 'Campus Main Gate');
    });

    test('BusSchedule serialization', () {
      const schedule = BusSchedule(
        id: 'sch-1',
        busId: 'bus-101',
        busNumber: 'Bus 101',
        routeId: 'route-sonadanga',
        routeName: 'Campus ➔ Sonadanga',
        departureTime: '07:45 AM',
        expectedArrivalTime: '08:15 AM',
        dayOfWeek: 'Daily',
        status: 'On Time',
      );

      final json = schedule.toJson();
      final fromJson = BusSchedule.fromJson(json);

      expect(fromJson.id, 'sch-1');
      expect(fromJson.departureTime, '07:45 AM');
      expect(fromJson.status, 'On Time');
    });

    test('PickupRequest serialization and status transitions', () {
      final req = PickupRequest(
        id: 'req-001',
        studentId: 'CSE-22-0001',
        studentName: 'Test Student',
        busId: 'bus-101',
        busNumber: 'Bus 101',
        routeId: 'route-sonadanga',
        routeName: 'Campus ➔ Sonadanga',
        stopId: 'stop-1',
        stopName: 'Campus Main Gate',
        status: PickupRequestStatus.pending,
        createdAt: DateTime.now(),
      );

      final json = req.toJson();
      final fromJson = PickupRequest.fromJson(json);

      expect(fromJson.id, 'req-001');
      expect(fromJson.status, PickupRequestStatus.pending);
      expect(fromJson.status.toFormattedString(), 'Pending');
    });

    test('BusLocation serialization without demo fields', () {
      final loc = BusLocation(
        busId: 'bus-101',
        latitude: 22.8200,
        longitude: 89.5400,
        speedKmH: 24.5,
        heading: 180.0,
        updatedAt: DateTime(2026, 11, 17, 10, 0),
        lastKnownStopName: 'Campus Gate',
      );

      final json = loc.toJson();
      expect(json['bus_id'], 'bus-101');
      expect(json['speed_kmh'], 24.5);
      expect(json.containsKey('is_demo'), isFalse);

      final fromJson = BusLocation.fromJson(json);
      expect(fromJson.busId, 'bus-101');
      expect(fromJson.latitude, 22.8200);
      expect(fromJson.lastKnownStopName, 'Campus Gate');
    });

    test('AppConstants bus ID normalization', () {
      expect(AppConstants.toModelBusId('BUS_101'), 'bus-101');
      expect(AppConstants.toModelBusId('bus-101'), 'bus-101');
      expect(AppConstants.toRtdbBusId('bus-101'), 'BUS_101');
      expect(AppConstants.toRtdbBusId('BUS_101'), 'BUS_101');
    });
  });
}
