/// Model representing the live coordinates and telemetry of a bus
class BusLocation {
  final String busId;
  final double latitude;
  final double longitude;
  final double speedKmH;
  final double heading;
  final DateTime updatedAt;
  final String? lastKnownStopName;

  const BusLocation({
    required this.busId,
    required this.latitude,
    required this.longitude,
    this.speedKmH = 0.0,
    this.heading = 0.0,
    required this.updatedAt,
    this.lastKnownStopName,
  });

  factory BusLocation.fromJson(Map<String, dynamic> json) {
    return BusLocation(
      busId: json['bus_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmH: (json['speed_kmh'] as num?)?.toDouble() ?? 0.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      lastKnownStopName: json['last_known_stop_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bus_id': busId,
      'latitude': latitude,
      'longitude': longitude,
      'speed_kmh': speedKmH,
      'heading': heading,
      'updated_at': updatedAt.toIso8601String(),
      'last_known_stop_name': lastKnownStopName,
    };
  }
}
