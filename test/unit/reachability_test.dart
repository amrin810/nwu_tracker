import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/core/services/reachability_service.dart';
import 'package:bus_tracking/models/reachability_model.dart';
import 'package:bus_tracking/models/bus_model.dart';
import 'package:bus_tracking/providers/location_provider.dart';

void main() {
  group('ReachabilityService Algorithm Tests', () {
    final service = ReachabilityService.instance;

    test('Case 1: Bus already passed the stop', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 400.0,
        walkingTimeMinutes: 5,
        busArrivalMinutes: 10,
        busHasPassedStop: true,
      );

      expect(result.status, ReachabilityStatus.busAlreadyPassed);
      expect(result.hasBusPassed, isTrue);
    });

    test('Case 2: Likely to catch (ample time buffer >= safe margin)', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 500.0,
        walkingTimeMinutes: 6,
        busArrivalMinutes: 15, // time margin = 15 - 6 = 9 min >= 3 min
        busHasPassedStop: false,
      );

      expect(result.status, ReachabilityStatus.likelyToCatch);
      expect(result.timeMarginMinutes, 9);
      expect(result.hasBusPassed, isFalse);
    });

    test('Case 3: Hurry - Bus nearby (time margin between 0 and safe margin)', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 500.0,
        walkingTimeMinutes: 6,
        busArrivalMinutes: 7, // time margin = 7 - 6 = 1 min
        busHasPassedStop: false,
      );

      expect(result.status, ReachabilityStatus.hurryBusNearby);
      expect(result.timeMarginMinutes, 1);
    });

    test('Case 4: May miss the bus (walking time exceeds bus arrival)', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 1000.0,
        walkingTimeMinutes: 12,
        busArrivalMinutes: 5, // time margin = 5 - 12 = -7 min
        busHasPassedStop: false,
      );

      expect(result.status, ReachabilityStatus.mayMissBus);
      expect(result.timeMarginMinutes, -7);
    });

    test('Boundary: Exactly on the safe margin (3 minutes)', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 250.0,
        walkingTimeMinutes: 3,
        busArrivalMinutes: 6, // margin = 3 == safe margin
        safeMarginMinutes: 3,
      );

      expect(result.status, ReachabilityStatus.likelyToCatch);
    });

    test('Boundary: Exactly 0 margin', () {
      final result = service.calculate(
        busId: 'bus-101',
        busNumber: 'Bus 101',
        distanceMeters: 250.0,
        walkingTimeMinutes: 4,
        busArrivalMinutes: 4, // margin = 0
        safeMarginMinutes: 3,
      );

      expect(result.status, ReachabilityStatus.hurryBusNearby);
    });

    test('LocationProvider.computeReachability without busLocation does not use mock 850m', () {
      final provider = LocationProvider();
      const bus = Bus(
        id: 'bus-101',
        busNumber: 'Bus 101',
        busName: 'Campus Express',
        licensePlate: 'KLN-101',
        capacity: 50,
        status: BusStatus.active,
      );

      final result = provider.computeReachability(
        bus: bus,
        busLocation: null,
      );

      expect(result.distanceMeters, 0.0);
      expect(result.walkingTimeMinutes, 0);
    });
  });
}
