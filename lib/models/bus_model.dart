/// Status of a university bus
enum BusStatus {
  active,
  delayed,
  inactive,
  maintenance;

  static BusStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return BusStatus.active;
      case 'delayed':
        return BusStatus.delayed;
      case 'maintenance':
        return BusStatus.maintenance;
      case 'inactive':
      default:
        return BusStatus.inactive;
    }
  }

  String toFormattedString() {
    switch (this) {
      case BusStatus.active:
        return 'Active';
      case BusStatus.delayed:
        return 'Delayed';
      case BusStatus.inactive:
        return 'Inactive';
      case BusStatus.maintenance:
        return 'In Maintenance';
    }
  }
}

/// Model representing a university bus
class Bus {
  final String id;
  final String busNumber;
  final String busName;
  final String licensePlate;
  final int capacity;
  final String? currentRouteId;
  final String? currentRouteName;
  final BusStatus status;
  final String? driverName;
  final String? driverPhone;
  final String? conductorName;
  final String? conductorPhone;

  const Bus({
    required this.id,
    required this.busNumber,
    required this.busName,
    required this.licensePlate,
    required this.capacity,
    this.currentRouteId,
    this.currentRouteName,
    required this.status,
    this.driverName,
    this.driverPhone,
    this.conductorName,
    this.conductorPhone,
  });

  factory Bus.fromJson(Map<String, dynamic> json) {
    return Bus(
      id: json['id'] as String,
      busNumber: json['bus_number'] as String,
      busName: json['bus_name'] as String? ?? json['bus_number'] as String,
      licensePlate: json['license_plate'] as String? ?? '',
      capacity: json['capacity'] as int? ?? 50,
      currentRouteId: json['current_route_id'] as String?,
      currentRouteName: json['current_route_name'] as String?,
      status: BusStatus.fromString(json['status'] as String? ?? 'inactive'),
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      conductorName: json['conductor_name'] as String?,
      conductorPhone: json['conductor_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bus_number': busNumber,
      'bus_name': busName,
      'license_plate': licensePlate,
      'capacity': capacity,
      'current_route_id': currentRouteId,
      'current_route_name': currentRouteName,
      'status': status.name,
      'driver_name': driverName,
      'driver_phone': driverPhone,
      'conductor_name': conductorName,
      'conductor_phone': conductorPhone,
    };
  }
}
