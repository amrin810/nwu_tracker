/// Model representing a published university bus schedule
class BusSchedule {
  final String id;
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final String departureTime;
  final String expectedArrivalTime;
  final String dayOfWeek;
  final String status; // "On Time", "Departed", "Delayed", "Cancelled"

  const BusSchedule({
    required this.id,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.departureTime,
    required this.expectedArrivalTime,
    required this.dayOfWeek,
    this.status = 'On Time',
  });

  factory BusSchedule.fromJson(Map<String, dynamic> json) {
    return BusSchedule(
      id: json['id'] as String,
      busId: json['bus_id'] as String,
      busNumber: json['bus_number'] as String? ?? 'Bus',
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String? ?? 'Main Route',
      departureTime: json['departure_time'] as String,
      expectedArrivalTime: json['expected_arrival_time'] as String,
      dayOfWeek: json['day_of_week'] as String? ?? 'Daily',
      status: json['status'] as String? ?? 'On Time',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_id': busId,
      'bus_number': busNumber,
      'route_id': routeId,
      'route_name': routeName,
      'departure_time': departureTime,
      'expected_arrival_time': expectedArrivalTime,
      'day_of_week': dayOfWeek,
      'status': status,
    };
  }
}
