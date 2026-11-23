import 'package:flutter/foundation.dart';

/// Lightweight logging utility for debugging and telemetry tracking
class AppLogger {
  AppLogger._();

  static void info(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[INFO]${tag != null ? ' [$tag]' : ''} $message');
    }
  }

  static void warning(String message, [String? tag]) {
    if (kDebugMode) {
      debugPrint('[WARN]${tag != null ? ' [$tag]' : ''} $message');
    }
  }

  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] $message');
      if (error != null) debugPrint('Exception: $error');
      if (stackTrace != null) debugPrint('StackTrace: $stackTrace');
    }
  }
}
