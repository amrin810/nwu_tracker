import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/core/services/location_service.dart';

void main() {
  group('LocationService Math & Distance Calculations', () {
    final service = LocationService.instance;

    test('Distance between NWU campus and Fulbari Gate is positive', () {
      final distance = service.calculateDistanceMeters(
        startLatitude: 22.8200,
        startLongitude: 89.5400,
        endLatitude: 22.8230,
        endLongitude: 89.5440,
      );

      expect(distance, greaterThan(300));
      expect(distance, lessThan(800));
    });

    test('Walking time calculation with default 5.0 km/h speed', () {
      // 5 km/h = 83.33 m/min.
      // 500 meters should take ceil(500 / 83.33) = 6 minutes
      final minutes = service.calculateWalkingTimeMinutes(500.0);
      expect(minutes, 6);
    });

    test('Walking time with 0 or negative distance returns 0', () {
      expect(service.calculateWalkingTimeMinutes(0.0), 0);
      expect(service.calculateWalkingTimeMinutes(-100.0), 0);
    });

    test('Walking time scales proportionally with speed', () {
      // At 10 km/h (double speed), time should be halved
      final standard = service.calculateWalkingTimeMinutes(1000.0, speedKmH: 5.0);
      final fast = service.calculateWalkingTimeMinutes(1000.0, speedKmH: 10.0);
      expect(fast, lessThan(standard));
    });
  });
}
