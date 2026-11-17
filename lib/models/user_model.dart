import 'dart:convert';
import 'dart:typed_data';

/// User roles supported by the University Transportation System
enum UserRole {
  student,
  driver,
  conductor,
  admin;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'driver':
        return UserRole.driver;
      case 'conductor':
        return UserRole.conductor;
      case 'admin':
        return UserRole.admin;
      case 'student':
      default:
        return UserRole.student;
    }
  }

  String toFormattedString() {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.driver:
        return 'Driver';
      case UserRole.conductor:
        return 'Conductor';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Profile model representing an authenticated university transportation user
class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String? userId; // Unified ID across all roles (Student ID, Driver ID, Conductor ID)
  final String? phone;
  final UserRole role;
  final String? assignedBusId; // For driver or conductor
  final String? department;
  final String? university;
  final Uint8List? profileImageBytes;

  /// Backward-compatible alias for [userId]
  String? get studentId => userId;

  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    String? userId,
    String? studentId,
    this.phone,
    required this.role,
    this.assignedBusId,
    this.department,
    this.university,
    this.profileImageBytes,
  }) : userId = userId ?? studentId;

  AppUser copyWith({
    String? id,
    String? email,
    String? fullName,
    String? userId,
    String? studentId,
    String? phone,
    UserRole? role,
    String? assignedBusId,
    String? department,
    String? university,
    Uint8List? profileImageBytes,
    bool clearProfileImage = false,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      userId: userId ?? studentId ?? this.userId,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      assignedBusId: assignedBusId ?? this.assignedBusId,
      department: department ?? this.department,
      university: university ?? this.university,
      profileImageBytes: clearProfileImage ? null : (profileImageBytes ?? this.profileImageBytes),
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> json, {AppUser? fallback}) {
    Uint8List? imageBytes;
    final photoBase64 = json['photoBase64'] as String? ??
        json['profileImageBase64'] as String? ??
        json['photo_base64'] as String?;
    if (photoBase64 != null && photoBase64.isNotEmpty) {
      try {
        imageBytes = base64Decode(photoBase64);
      } catch (_) {
        imageBytes = fallback?.profileImageBytes;
      }
    } else if (json.containsKey('photoBase64') ||
        json.containsKey('profileImageBase64') ||
        json.containsKey('photo_base64')) {
      imageBytes = null; // Explicitly removed
    } else {
      imageBytes = fallback?.profileImageBytes;
    }

    return AppUser(
      id: json['id'] as String? ?? json['uid'] as String? ?? fallback?.id ?? '',
      email: json['email'] as String? ?? fallback?.email ?? '',
      fullName: json['fullName'] as String? ??
          json['full_name'] as String? ??
          fallback?.fullName ??
          'Campus User',
      userId: json['userId'] as String? ??
          json['user_id'] as String? ??
          json['student_id'] as String? ??
          fallback?.userId,
      phone: json['phone'] as String? ?? fallback?.phone,
      role: json['role'] != null
          ? UserRole.fromString(json['role'] as String)
          : (fallback?.role ?? UserRole.student),
      assignedBusId: json['assignedBusId'] as String? ??
          json['assigned_bus_id'] as String? ??
          fallback?.assignedBusId,
      department: json['department'] as String? ?? fallback?.department,
      university: json['university'] as String? ?? fallback?.university,
      profileImageBytes: imageBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'full_name': fullName,
      'userId': userId,
      'student_id': userId,
      'phone': phone,
      'role': role.name,
      'assignedBusId': assignedBusId,
      'assigned_bus_id': assignedBusId,
      'department': department,
      'university': university,
      'photoBase64': profileImageBytes != null ? base64Encode(profileImageBytes!) : null,
    };
  }

  /// Map serialized for Firebase Realtime Database
  Map<String, dynamic> toFirebaseMap() {
    return {
      'id': id,
      'userId': userId ?? '',
      'fullName': fullName,
      'email': email,
      'phone': phone ?? '',
      'role': role.name,
      'assignedBusId': assignedBusId ?? '',
      'department': department ?? '',
      'university': university ?? '',
    };
  }
}
