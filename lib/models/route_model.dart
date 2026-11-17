import 'stop_model.dart';

/// Model representing a university bus route
class BusRoute {
  final String id;
  final String routeName;
  final String startPoint;
  final String endPoint;
  final double totalDistanceKm;
  final int estimatedDurationMinutes;
  final List<BusStop> stops;

  const BusRoute({
    required this.id,
    required this.routeName,
    required this.startPoint,
    required this.endPoint,
    required this.totalDistanceKm,
    required this.estimatedDurationMinutes,
    this.stops = const [],
  });

  factory BusRoute.fromJson(Map<String, dynamic> json, [List<BusStop>? stops]) {
    return BusRoute(
      id: json['id'] as String,
      routeName: json['route_name'] as String,
      startPoint: json['start_point'] as String? ?? 'Campus Terminal',
      endPoint: json['end_point'] as String? ?? '',
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      estimatedDurationMinutes: json['estimated_duration_minutes'] as int? ?? 0,
      stops: stops ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'route_name': routeName,
      'start_point': startPoint,
      'end_point': endPoint,
      'total_distance_km': totalDistanceKm,
      'estimated_duration_minutes': estimatedDurationMinutes,
    };
  }
}
