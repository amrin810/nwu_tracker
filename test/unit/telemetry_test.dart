import 'package:flutter_test/flutter_test.dart';
import 'package:bus_tracking/models/live_bus_location.dart';

void main() {
  group('LiveBusLocation Telemetry Parsing & Validation', () {
    test('Valid RTDB telemetry payload parses correctly', () {
      final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final payload = {
        'latitude': 22.8235,
        'longitude': 89.5442,
        'speed': 32.5,
        'lastUpdated': nowSec,
        'isActive': true,
      };

      final loc = LiveBusLocation.fromMap('BUS_101', payload);

      expect(loc.busId, 'BUS_101');
      expect(loc.latitude, 22.8235);
      expect(loc.longitude, 89.5442);
      expect(loc.speed, 32.5);
      expect(loc.isActive, isTrue);
      expect(loc.isLive, isTrue);
      expect(loc.status, LiveBusStatus.live);
    });

    test('Rejects invalid (0, 0) coordinates (typical GPS fix failure)', () {
      final payload = {
        'latitude': 0.0,
        'longitude': 0.0,
        'speed': 0.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'isActive': true,
      };

      expect(
        () => LiveBusLocation.fromMap('BUS_101', payload),
        throwsA(isA<FormatException>()),
      );
      expect(LiveBusLocation.tryFromMap('BUS_101', payload), isNull);
    });

    test('Rejects out-of-range coordinates', () {
      final badLat = {
        'latitude': 95.0,
        'longitude': 89.5,
        'speed': 10.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'isActive': true,
      };

      expect(
        () => LiveBusLocation.fromMap('BUS_101', badLat),
        throwsA(isA<FormatException>()),
      );
    });

    test('Detects stale telemetry when older than threshold', () {
      final oldTimestamp = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch ~/ 1000;

      final payload = {
        'latitude': 22.8200,
        'longitude': 89.5400,
        'speed': 20.0,
        'lastUpdated': oldTimestamp,
        'isActive': true,
      };

      final loc = LiveBusLocation.fromMap('BUS_101', payload);

      expect(loc.isStale, isTrue);
      expect(loc.isLive, isFalse);
      expect(loc.status, LiveBusStatus.stale);
    });

    test('Marks bus as offline when isActive is false', () {
      final payload = {
        'latitude': 22.8200,
        'longitude': 89.5400,
        'speed': 0.0,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'isActive': false,
      };

      final loc = LiveBusLocation.fromMap('BUS_101', payload);

      expect(loc.status, LiveBusStatus.offline);
      expect(loc.isLive, isFalse);
    });
  });
}
