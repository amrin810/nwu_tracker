import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

/// The 4 approved Reachability Status outcomes
enum ReachabilityStatus {
  likelyToCatch,
  hurryBusNearby,
  mayMissBus,
  busAlreadyPassed;

  String get label {
    switch (this) {
      case ReachabilityStatus.likelyToCatch:
        return AppStrings.likelyToCatch;
      case ReachabilityStatus.hurryBusNearby:
        return AppStrings.hurryBusNearby;
      case ReachabilityStatus.mayMissBus:
        return AppStrings.mayMissBus;
      case ReachabilityStatus.busAlreadyPassed:
        return AppStrings.busAlreadyPassed;
    }
  }

  Color get color {
    switch (this) {
      case ReachabilityStatus.likelyToCatch:
        return AppColors.success;
      case ReachabilityStatus.hurryBusNearby:
        return AppColors.warning;
      case ReachabilityStatus.mayMissBus:
        return AppColors.danger;
      case ReachabilityStatus.busAlreadyPassed:
        return AppColors.textSecondary;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case ReachabilityStatus.likelyToCatch:
        return AppColors.successLight;
      case ReachabilityStatus.hurryBusNearby:
        return AppColors.warningLight;
      case ReachabilityStatus.mayMissBus:
        return AppColors.dangerLight;
      case ReachabilityStatus.busAlreadyPassed:
        return AppColors.surfaceVariant;
    }
  }

  IconData get icon {
    switch (this) {
      case ReachabilityStatus.likelyToCatch:
        return Icons.check_circle_rounded;
      case ReachabilityStatus.hurryBusNearby:
        return Icons.directions_run_rounded;
      case ReachabilityStatus.mayMissBus:
        return Icons.warning_amber_rounded;
      case ReachabilityStatus.busAlreadyPassed:
        return Icons.cancel_rounded;
    }
  }
}

/// Model encapsulating the full reachability calculation and student explanation
class ReachabilityResult {
  final String busId;
  final String busNumber;
  final double distanceMeters;
  final int walkingTimeMinutes;
  final int busArrivalMinutes;
  final int timeMarginMinutes;
  final ReachabilityStatus status;
  final String explanation;
  final bool hasBusPassed;

  const ReachabilityResult({
    required this.busId,
    required this.busNumber,
    required this.distanceMeters,
    required this.walkingTimeMinutes,
    required this.busArrivalMinutes,
    required this.timeMarginMinutes,
    required this.status,
    required this.explanation,
    this.hasBusPassed = false,
  });
}
