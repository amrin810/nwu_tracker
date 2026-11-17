import '../constants/app_constants.dart';
import '../../models/reachability_model.dart';

/// Service implementing the Rule-Based Bus Reachability Algorithm
///
/// VIVA EXPLANATION:
/// This algorithm compares two estimated values:
/// 1. Student Walking Time: (Distance to bus or stop / average walking speed of 5 km/h)
/// 2. Bus Remaining Time: Expected arrival time of the bus at the target stop.
///
/// Depending on the difference (Time Margin), a deterministic reachability status is produced:
/// - Bus Already Passed: If telemetry indicates the bus has already left the stop.
/// - Likely to Catch: Student arrives earlier than the bus with a safe margin (>= 3 minutes).
/// - Hurry - Bus is Nearby: Student arrives just in time or within the margin (0 to 3 minutes).
/// - May Miss the Bus: Student arrives later than the bus (time margin < 0).
class ReachabilityService {
  static final ReachabilityService instance = ReachabilityService._internal();
  ReachabilityService._internal();

  /// Calculates reachability status based on student distance and bus ETA
  ReachabilityResult calculate({
    required String busId,
    required String busNumber,
    required double distanceMeters,
    required int walkingTimeMinutes,
    required int busArrivalMinutes,
    bool busHasPassedStop = false,
    int safeMarginMinutes = AppConstants.reachabilitySafeMarginMinutes,
  }) {
    // Case 1: The bus has already cleared the chosen stop
    if (busHasPassedStop) {
      return ReachabilityResult(
        busId: busId,
        busNumber: busNumber,
        distanceMeters: distanceMeters,
        walkingTimeMinutes: walkingTimeMinutes,
        busArrivalMinutes: busArrivalMinutes,
        timeMarginMinutes: 0,
        status: ReachabilityStatus.busAlreadyPassed,
        hasBusPassed: true,
        explanation:
            'The bus has already passed your target stop. Please check the schedule for the next available bus.',
      );
    }

    // Time Margin = Time remaining for the bus - Time required for the student to walk
    final timeMargin = busArrivalMinutes - walkingTimeMinutes;

    ReachabilityStatus status;
    String explanation;

    // Case 2: Student has ample time (Student travel time < Bus arrival time - safe margin)
    if (timeMargin >= safeMarginMinutes) {
      status = ReachabilityStatus.likelyToCatch;
      explanation =
          'You have a comfortable buffer of $timeMargin min. Walking at normal pace (5 km/h), you will reach the stop before the bus arrives.';
    }
    // Case 3: Student will arrive right around the same time as the bus
    else if (timeMargin >= 0) {
      status = ReachabilityStatus.hurryBusNearby;
      explanation =
          'The bus is arriving in $busArrivalMinutes min and your walking time is $walkingTimeMinutes min. Start walking immediately to avoid missing it.';
    }
    // Case 4: Student walking time exceeds expected bus arrival
    else {
      status = ReachabilityStatus.mayMissBus;
      final deficit = timeMargin.abs();
      explanation =
          'The bus is expected to arrive $deficit min before you can reach the stop at normal walking pace. Consider an earlier stop or next bus.';
    }

    return ReachabilityResult(
      busId: busId,
      busNumber: busNumber,
      distanceMeters: distanceMeters,
      walkingTimeMinutes: walkingTimeMinutes,
      busArrivalMinutes: busArrivalMinutes,
      timeMarginMinutes: timeMargin,
      status: status,
      explanation: explanation,
      hasBusPassed: false,
    );
  }
}
