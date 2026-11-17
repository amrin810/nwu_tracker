import '../../main.dart';

/// Application-wide configuration and algorithmic constants
class AppConstants {
  AppConstants._();

  // Project Info
  static const String appName = '$kUniversityName Bus';
  static const String appVersion = '1.0.0';
  static const String universityName = kUniversityName;
  static const String departmentName = 'Computer Science & Engineering';

  // Supabase Configuration
  // Note: These can be overridden via --dart-define=SUPABASE_URL=... during build
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://xyzcompany.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'public-anon-key-placeholder',
  );

  // Transportation & Algorithm Constants
  // Average human walking speed: 5.0 km/h = ~83.3 meters per minute
  static const double defaultWalkingSpeedKmH = 5.0;

  // Safe margin buffer (minutes) to comfortably board the bus
  static const int reachabilitySafeMarginMinutes = 3;

  // Realtime Polling & Refresh Durations
  static const Duration locationUpdateInterval = Duration(seconds: 10);
  static const Duration busLocationFetchInterval = Duration(seconds: 15);
  static const Duration connectionTimeout = Duration(seconds: 12);

  // Stale Location Threshold (Realtime Database telemetry)
  static const int staleLocationThresholdSeconds = 60;

  // OpenStreetMap Tile Configuration (Configurable for Phase 3 map)
  static const String osmTileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String osmUserAgent = 'com.nwu.bus_tracking';

  // Bus ID Mappings (Realtime Database BUS_101 <-> Model bus-101)
  static const Map<String, String> rtdbToModelBusIdMap = {
    'BUS_101': 'bus-101',
    'BUS_102': 'bus-102',
    'BUS_103': 'bus-103',
  };

  static const Map<String, String> modelToRtdbBusIdMap = {
    'bus-101': 'BUS_101',
    'bus-102': 'BUS_102',
    'bus-103': 'BUS_103',
  };

  /// Normalizes any bus ID format to the internal model ID ('bus-101')
  static String toModelBusId(String id) {
    final upper = id.toUpperCase().replaceAll('-', '_');
    return rtdbToModelBusIdMap[upper] ?? id.toLowerCase().replaceAll('_', '-');
  }

  /// Converts any bus ID to the Realtime Database key ('BUS_101')
  static String toRtdbBusId(String id) {
    final lower = id.toLowerCase().replaceAll('_', '-');
    return modelToRtdbBusIdMap[lower] ?? id.toUpperCase().replaceAll('-', '_');
  }

  // Default Central University Campus Coordinates (North Western University, Khulna)
  static const double defaultLatitude = 22.8200;
  static const double defaultLongitude = 89.5400;
  static const double defaultUserLatitude = 22.8207;
  static const double defaultUserLongitude = 89.5406;
  static const double defaultMapZoom = 15.0;
}
