/// Model representing an approved university bus stop
class BusStop {
  final String id;
  final String stopName;
  final double latitude;
  final double longitude;
  final int sequenceOrder;
  final int estimatedMinutesFromStart;
  final String? routeId;

  const BusStop({
    required this.id,
    required this.stopName,
    required this.latitude,
    required this.longitude,
    required this.sequenceOrder,
    this.estimatedMinutesFromStart = 0,
    this.routeId,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      id: json['id'] as String,
      stopName: json['stop_name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      sequenceOrder: json['sequence_order'] as int? ?? 1,
      estimatedMinutesFromStart: json['estimated_minutes_from_start'] as int? ?? 0,
      routeId: json['route_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'stop_name': stopName,
      'latitude': latitude,
      'longitude': longitude,
      'sequence_order': sequenceOrder,
      'estimated_minutes_from_start': estimatedMinutesFromStart,
      'route_id': routeId,
    };
  }
}
