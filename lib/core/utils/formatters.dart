import 'package:intl/intl.dart';

/// Formatting utilities for distances, walking times, and timestamps
class Formatters {
  Formatters._();

  /// Formats distance in meters into human-readable string (m or km)
  /// Example: 850 -> "850 m", 2400 -> "2.4 km"
  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000.0;
      return '${km.toStringAsFixed(1)} km';
    }
  }

  /// Formats walking/travel duration in minutes into a clean readable string
  /// Example: 10 -> "10 min", 75 -> "1 hr 15 min"
  static String formatDurationMinutes(int totalMinutes) {
    if (totalMinutes <= 0) return 'Arriving now';
    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (mins == 0) return '$hours hr';
    return '$hours hr $mins min';
  }

  /// Returns time string formatted as HH:mm a (e.g., 08:30 AM)
  static String formatTime(DateTime dateTime) {
    return DateFormat('hh:mm a').format(dateTime);
  }

  /// Returns relative update string (e.g. "Updated 1 min ago", "Updated just now")
  static String formatRelativeTime(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 45) {
      return 'Updated just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Updated $mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else {
      return 'Updated ${DateFormat('hh:mm a').format(dateTime)}';
    }
  }
}
