/// Custom application exceptions for structured error handling
class AppException implements Exception {
  final String message;
  final String? code;

  const AppException(this.message, {this.code});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Network connection error'])
      : super(code: 'NETWORK_ERROR');
}

class LocationException extends AppException {
  const LocationException([super.message = 'Location service error'])
      : super(code: 'LOCATION_ERROR');
}

class AuthException extends AppException {
  const AuthException([super.message = 'Authentication failed'])
      : super(code: 'AUTH_ERROR');
}

class NotFoundException extends AppException {
  const NotFoundException([super.message = 'Resource not found'])
      : super(code: 'NOT_FOUND');
}
