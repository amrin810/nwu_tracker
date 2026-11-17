import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import '../core/utils/app_logger.dart';
import '../models/live_bus_location.dart';

/// Service managing real-time GPS telemetry from Firebase Realtime Database:
/// Path: bus_locations/{busId} = { latitude, longitude, speed, lastUpdated, isActive }
class BusLocationService {
  BusLocationService._();
  static final BusLocationService instance = BusLocationService._();
  factory BusLocationService() => instance;

  FirebaseDatabase? _databaseInstance;

  FirebaseDatabase get _database {
    _databaseInstance ??= FirebaseDatabase.instance;
    return _databaseInstance!;
  }

  DatabaseReference get _locationsRef => _database.ref('bus_locations');
  DatabaseReference get _connectedRef => _database.ref('.info/connected');

  /// Stream exposing connection status via Firebase RTDB system node: .info/connected
  Stream<bool> get isConnectedStream {
    try {
      return _connectedRef.onValue.map((event) {
        final val = event.snapshot.value;
        return val is bool ? val : false;
      }).handleError((error) {
        AppLogger.error('RTDB .info/connected stream error', error);
        return false;
      });
    } catch (e) {
      AppLogger.warning('Could not attach to .info/connected: $e');
      return Stream.value(false);
    }
  }

  /// Real-time stream of all active bus locations mapped by busId ('BUS_101', etc.).
  /// Validates each entry, skips and logs corrupt entries, and never crashes.
  Stream<Map<String, LiveBusLocation>> get allBusLocationsStream {
    try {
      return _locationsRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          return <String, LiveBusLocation>{};
        }

        final locations = <String, LiveBusLocation>{};
        data.forEach((key, value) {
          final busId = key.toString();
          if (value is Map) {
            try {
              final loc = LiveBusLocation.fromMap(busId, value);
              locations[busId] = loc;
            } catch (e) {
              AppLogger.warning('Skipped invalid telemetry payload for $busId: $e');
            }
          } else {
            AppLogger.warning('Skipped non-map payload under bus_locations/$busId');
          }
        });

        return locations;
      }).handleError((error) {
        AppLogger.error('Error listening to bus_locations stream', error);
        return <String, LiveBusLocation>{};
      });
    } catch (e) {
      AppLogger.error('Failed to initialize bus_locations onValue stream: $e');
      return Stream.value(<String, LiveBusLocation>{});
    }
  }

  /// Stream of live location updates for a single bus by ID (e.g. 'BUS_101')
  Stream<LiveBusLocation?> streamBusLocation(String busId) {
    try {
      return _locationsRef.child(busId).onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null || data is! Map) {
          return null;
        }

        try {
          return LiveBusLocation.fromMap(busId, data);
        } catch (e) {
          AppLogger.warning('Skipped corrupt telemetry for bus $busId: $e');
          return null;
        }
      }).handleError((error) {
        AppLogger.error('Error listening to bus $busId stream', error);
        return null;
      });
    } catch (e) {
      AppLogger.error('Failed to create stream for bus $busId: $e');
      return Stream.value(null);
    }
  }

  /// One-time fetch of all current bus locations
  Future<Map<String, LiveBusLocation>> fetchAllBusLocations() async {
    try {
      final snapshot = await _locationsRef.get();
      final data = snapshot.value;
      if (data == null || data is! Map) {
        return <String, LiveBusLocation>{};
      }

      final locations = <String, LiveBusLocation>{};
      data.forEach((key, value) {
        final busId = key.toString();
        if (value is Map) {
          final loc = LiveBusLocation.tryFromMap(busId, value);
          if (loc != null) {
            locations[busId] = loc;
          }
        }
      });
      return locations;
    } catch (e) {
      AppLogger.error('Failed to fetch bus locations snapshot: $e');
      return <String, LiveBusLocation>{};
    }
  }
}

