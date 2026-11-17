/// Lifecycle statuses for a student pickup request
enum PickupRequestStatus {
  pending,
  accepted,
  rejected,
  completed;

  static PickupRequestStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return PickupRequestStatus.accepted;
      case 'rejected':
        return PickupRequestStatus.rejected;
      case 'completed':
        return PickupRequestStatus.completed;
      case 'pending':
      default:
        return PickupRequestStatus.pending;
    }
  }

  String toFormattedString() {
    switch (this) {
      case PickupRequestStatus.pending:
        return 'Pending';
      case PickupRequestStatus.accepted:
        return 'Accepted';
      case PickupRequestStatus.rejected:
        return 'Rejected';
      case PickupRequestStatus.completed:
        return 'Completed';
    }
  }
}

/// Model representing a student pickup request
class PickupRequest {
  final String id;
  final String studentId;
  final String studentName;
  final String? studentPhone;
  final String busId;
  final String busNumber;
  final String routeId;
  final String routeName;
  final String stopId;
  final String stopName;
  final PickupRequestStatus status;
  final String? message;
  final DateTime createdAt;

  const PickupRequest({
    required this.id,
    required this.studentId,
    required this.studentName,
    this.studentPhone,
    required this.busId,
    required this.busNumber,
    required this.routeId,
    required this.routeName,
    required this.stopId,
    required this.stopName,
    required this.status,
    this.message,
    required this.createdAt,
  });

  factory PickupRequest.fromJson(Map<String, dynamic> json) {
    return PickupRequest(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      studentName: json['student_name'] as String? ?? 'Student',
      studentPhone: json['student_phone'] as String?,
      busId: json['bus_id'] as String,
      busNumber: json['bus_number'] as String? ?? 'Bus',
      routeId: json['route_id'] as String,
      routeName: json['route_name'] as String? ?? 'Route',
      stopId: json['stop_id'] as String,
      stopName: json['stop_name'] as String? ?? 'Stop',
      status: PickupRequestStatus.fromString(json['status'] as String? ?? 'pending'),
      message: json['message'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'student_name': studentName,
      'student_phone': studentPhone,
      'bus_id': busId,
      'bus_number': busNumber,
      'route_id': routeId,
      'route_name': routeName,
      'stop_id': stopId,
      'stop_name': stopName,
      'status': status.name,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
