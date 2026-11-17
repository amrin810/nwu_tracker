import '../core/constants/app_constants.dart';

/// Operational status of a live-tracked bus
enum LiveBusStatus {
  live,
  stale,
  offline;

  String toFormattedString() {
    switch (this) {
      case LiveBusStatus.live:
        return 'Live';
      case LiveBusStatus.stale:
        return 'Stale';
      case LiveBusStatus.offline:
        return 'Offline';
    }
  }
}

/// Represents real-time GPS telemetry from Firebase Realtime Database:
/// bus_locations/BUS_101 = { latitude, longitude, speed, lastUpdated, isActive }
class LiveBusLocation {
  final String busId;
  final double latitude;
  final double longitude;
  final double speed; // km/h
  final DateTime lastUpdated;
  final bool isActive;

  const LiveBusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.lastUpdated,
    required this.isActive,
  });

  /// Factory constructor that strictly validates RTDB payload.
  /// Throws [FormatException] if any required value is missing or invalid.
  factory LiveBusLocation.fromMap(String busId, Map<dynamic, dynamic> map) {
    if (busId.trim().isEmpty) {
      throw const FormatException('busId cannot be empty');
    }

    // 1. Latitude validation
    final rawLat = map['latitude'];
    if (rawLat == null || rawLat is! num) {
      throw FormatException('Missing or non-numeric latitude for bus: $busId');
    }
    final lat = rawLat.toDouble();
    if (lat < -90.0 || lat > 90.0) {
      throw FormatException('Latitude out of range (-90..90): $lat');
    }

    // 2. Longitude validation
    final rawLng = map['longitude'];
    if (rawLng == null || rawLng is! num) {
      throw FormatException('Missing or non-numeric longitude for bus: $busId');
    }
    final lng = rawLng.toDouble();
    if (lng < -180.0 || lng > 180.0) {
      throw FormatException('Longitude out of range (-180..180): $lng');
    }

    // 3. Reject (0, 0) coordinates (typical GPS module fix failure)
    if (lat == 0.0 && lng == 0.0) {
      throw FormatException('Coordinates (0, 0) are invalid for bus: $busId');
    }

    // 4. Speed validation (km/h)
    final rawSpeed = map['speed'];
    final speed = (rawSpeed is num) ? rawSpeed.toDouble() : 0.0;
    if (speed < 0) {
      throw FormatException('Speed cannot be negative: $speed');
    }

    // 5. lastUpdated validation (Unix seconds or ms)
    final rawUpdated = map['lastUpdated'];
    if (rawUpdated == null) {
      throw FormatException('Missing lastUpdated for bus: $busId');
    }

    DateTime parsedUpdated;
    if (rawUpdated is num) {
      final intVal = rawUpdated.toInt();
      // If timestamp is in seconds (< 100 billion), convert to milliseconds
      if (intVal < 100000000000) {
        parsedUpdated = DateTime.fromMillisecondsSinceEpoch(intVal * 1000);
      } else {
        parsedUpdated = DateTime.fromMillisecondsSinceEpoch(intVal);
      }
    } else if (rawUpdated is String) {
      final parsedDate = DateTime.tryParse(rawUpdated);
      if (parsedDate != null) {
        parsedUpdated = parsedDate;
      } else {
        final parsedInt = int.tryParse(rawUpdated);
        if (parsedInt != null) {
          parsedUpdated = DateTime.fromMillisecondsSinceEpoch(
            parsedInt < 100000000000 ? parsedInt * 1000 : parsedInt,
          );
        } else {
          throw FormatException('Unparseable lastUpdated: $rawUpdated');
        }
      }
    } else {
      throw FormatException('Invalid lastUpdated type: ${rawUpdated.runtimeType}');
    }

    // 6. isActive validation
    final rawActive = map['isActive'];
    final isActive = rawActive is bool
        ? rawActive
        : (rawActive == 1 || rawActive == 'true' || rawActive == 'TRUE');

    return LiveBusLocation(
      busId: busId,
      latitude: lat,
      longitude: lng,
      speed: speed,
      lastUpdated: parsedUpdated,
      isActive: isActive,
    );
  }

  /// Safe parser that returns null on invalid data instead of throwing
  static LiveBusLocation? tryFromMap(String busId, dynamic data) {
    if (data == null || data is! Map) return null;
    try {
      return LiveBusLocation.fromMap(busId, data);
    } catch (_) {
      return null;
    }
  }

  /// True if last telemetry update was received more than the configured threshold (60s) ago
  bool get isStale {
    final difference = DateTime.now().difference(lastUpdated);
    return difference.inSeconds > AppConstants.staleLocationThresholdSeconds;
  }

  /// Computes status: Live, Stale, or Offline.
  /// Rule: A bus whose data is stale or isActive=false must NEVER be shown as live.
  LiveBusStatus get status {
    if (!isActive) {
      return LiveBusStatus.offline;
    }
    if (isStale) {
      return LiveBusStatus.stale;
    }
    return LiveBusStatus.live;
  }

  /// True only if active and telemetry is fresh
  bool get isLive => status == LiveBusStatus.live;

  /// Human-readable "last updated x seconds ago"
  String get lastUpdatedText {
    final diff = DateTime.now().difference(lastUpdated);
    if (diff.isNegative || diff.inSeconds < 5) {
      return 'Just now';
    }
    if (diff.inSeconds < 60) {
      return '${diff.inSeconds} seconds ago';
    }
    final mins = diff.inMinutes;
    if (mins < 60) {
      return '$mins minute${mins == 1 ? '' : 's'} ago';
    }
    final hours = diff.inHours;
    if (hours < 24) {
      return '$hours hour${hours == 1 ? '' : 's'} ago';
    }
    final days = diff.inDays;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch ~/ 1000,
      'isActive': isActive,
    };
  }

  LiveBusLocation copyWith({
    String? busId,
    double? latitude,
    double? longitude,
    double? speed,
    DateTime? lastUpdated,
    bool? isActive,
  }) {
    return LiveBusLocation(
      busId: busId ?? this.busId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
    );
  }
}

