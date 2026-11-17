import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/utils/formatters.dart';
import '../models/bus_model.dart';
import 'status_badge.dart';

/// Reusable card displaying university bus overview, route, distance & ETA
class BusCard extends StatelessWidget {
  final Bus bus;
  final double? distanceMeters;
  final int? walkingTimeMinutes;
  final String? locationUnavailableText;
  final VoidCallback? onTap;
  final VoidCallback? onTrack;

  const BusCard({
    super.key,
    required this.bus,
    this.distanceMeters,
    this.walkingTimeMinutes,
    this.locationUnavailableText,
    this.onTap,
    this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Bus Name & Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: AppColors.textWhite,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bus.busNumber,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            bus.busName,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  StatusBadge.fromBusStatus(bus.status),
                ],
              ),
              const SizedBox(height: 12),

              // Route Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.alt_route_rounded,
                      size: 16,
                      color: AppColors.navyAccent,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        bus.currentRouteName ?? 'Campus Route',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Telemetry Row: Distance & Walking Time, or Location Unavailable
              const SizedBox(height: 12),
              if (distanceMeters != null || walkingTimeMinutes != null)
                Row(
                  children: [
                    if (distanceMeters != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.straighten_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatDistance(distanceMeters!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (walkingTimeMinutes != null)
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.directions_walk_rounded,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              Formatters.formatDurationMinutes(walkingTimeMinutes!),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (onTrack != null)
                      ElevatedButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.navyAccent),
                        label: const Text('Track'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                )
              else
                Row(
                  children: [
                    const Icon(
                      Icons.location_off_rounded,
                      size: 15,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      locationUnavailableText ?? 'Location unavailable',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    if (onTrack != null)
                      ElevatedButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.location_searching_rounded, size: 14, color: AppColors.navyAccent),
                        label: const Text('Track'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.textWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          minimumSize: const Size(0, 32),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
