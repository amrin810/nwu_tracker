import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/core/constants/nwu_default_data.dart';
import 'package:bus_tracking/models/bus_model.dart';

void main() {
  group('NWU Default Data Integrity Tests', () {
    test('Default NWU buses are properly configured', () {
      final buses = NWUDefaultData.defaultBuses;
      expect(buses.length, greaterThanOrEqualTo(3));

      // At least 3 active buses
      final active = buses.where((b) => b.status == BusStatus.active).toList();
      expect(active.length, greaterThanOrEqualTo(3));

      // Check bus IDs
      final ids = buses.map((b) => b.id).toSet();
      expect(ids.contains('bus-101'), isTrue);
      expect(ids.contains('bus-102'), isTrue);
      expect(ids.contains('bus-103'), isTrue);
    });

    test('Default NWU routes have valid stops and coordinates', () {
      final routes = NWUDefaultData.defaultRoutes;
      expect(routes.length, 3);

      for (final route in routes) {
        expect(route.stops, isNotEmpty);
        expect(route.totalDistanceKm, greaterThan(0));
        expect(route.estimatedDurationMinutes, greaterThan(0));

        for (final stop in route.stops) {
          // NWU Khulna coordinates: Lat around 22.8, Lon around 89.5
          expect(stop.latitude, closeTo(22.82, 0.2));
          expect(stop.longitude, closeTo(89.54, 0.2));
          expect(stop.sequenceOrder, greaterThanOrEqualTo(1));
        }
      }
    });

    test('Default NWU schedules have valid times and statuses', () {
      final schedules = NWUDefaultData.defaultSchedules;
      expect(schedules, isNotEmpty);

      for (final schedule in schedules) {
        expect(schedule.departureTime, isNotEmpty);
        expect(schedule.expectedArrivalTime, isNotEmpty);
        expect(schedule.busId, isNotEmpty);
        expect(schedule.routeId, isNotEmpty);
      }
    });
  });
}
