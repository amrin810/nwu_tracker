import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/bus_model.dart';
import '../models/pickup_request_model.dart';
import '../models/reachability_model.dart';

/// Semantic status badge supporting Bus, Request, and Reachability status styles
class StatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.backgroundColor,
    this.icon,
  });

  /// Factory for BusStatus
  factory StatusBadge.fromBusStatus(BusStatus status) {
    Color text;
    Color bg;
    IconData ic;

    switch (status) {
      case BusStatus.active:
        text = AppColors.success;
        bg = AppColors.successLight;
        ic = Icons.fiber_manual_record;
        break;
      case BusStatus.delayed:
        text = AppColors.warning;
        bg = AppColors.warningLight;
        ic = Icons.access_time_rounded;
        break;
      case BusStatus.maintenance:
        text = AppColors.textSecondary;
        bg = AppColors.surfaceVariant;
        ic = Icons.build_circle_outlined;
        break;
      case BusStatus.inactive:
        text = AppColors.danger;
        bg = AppColors.dangerLight;
        ic = Icons.do_not_disturb_on_outlined;
        break;
    }

    return StatusBadge(
      label: status.toFormattedString(),
      textColor: text,
      backgroundColor: bg,
      icon: ic,
    );
  }

  /// Factory for PickupRequestStatus
  factory StatusBadge.fromRequestStatus(PickupRequestStatus status) {
    Color text;
    Color bg;

    switch (status) {
      case PickupRequestStatus.accepted:
        text = AppColors.success;
        bg = AppColors.successLight;
        break;
      case PickupRequestStatus.pending:
        text = AppColors.warning;
        bg = AppColors.warningLight;
        break;
      case PickupRequestStatus.rejected:
        text = AppColors.danger;
        bg = AppColors.dangerLight;
        break;
      case PickupRequestStatus.completed:
        text = AppColors.info;
        bg = AppColors.infoLight;
        break;
    }

    return StatusBadge(
      label: status.toFormattedString(),
      textColor: text,
      backgroundColor: bg,
    );
  }

  /// Factory for ReachabilityStatus
  factory StatusBadge.fromReachability(ReachabilityStatus status) {
    return StatusBadge(
      label: status.label,
      textColor: status.color,
      backgroundColor: status.backgroundColor,
      icon: status.icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
