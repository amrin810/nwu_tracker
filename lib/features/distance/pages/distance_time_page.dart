import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bus_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/empty_state.dart';

/// Dedicated page for Distance and Walking Travel-Time Calculations
class DistanceTimePage extends StatefulWidget {
  const DistanceTimePage({super.key});

  @override
  State<DistanceTimePage> createState() => _DistanceTimePageState();
}

class _DistanceTimePageState extends State<DistanceTimePage> {
  Bus? _selectedBus;
  double _customSpeedKmH = AppConstants.defaultWalkingSpeedKmH;

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final locationProvider = context.watch<LocationProvider>();

    if (busProvider.buses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Distance & Travel Time')),
        body: const Center(
          child: EmptyState(
            icon: Icons.directions_bus_outlined,
            title: 'No Buses Available',
            message: 'There are currently no active buses available to estimate distance.',
          ),
        ),
      );
    }

    final bus =
        _selectedBus ??
        busProvider.selectedBus ??
        busProvider.buses.first;

    final busLoc = busProvider.getLocationForBus(bus.id);

    final double? distanceMeters = busLoc != null
        ? locationProvider.calculateDistanceToBus(busLoc)
        : null;

    // Formula: Travel Time = Distance / Walking Speed
    final metersPerMinute = (_customSpeedKmH * 1000.0) / 60.0;
    final int? walkingMinutes = distanceMeters != null
        ? (distanceMeters / metersPerMinute).ceil()
        : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Distance & Travel Time')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bus Selector
            const Text(
              'Select Target Bus',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<Bus>(
              key: ValueKey(bus.id),
              initialValue: busProvider.buses.contains(bus)
                  ? bus
                  : busProvider.buses.first,
              decoration: const InputDecoration(
                prefixIcon: Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.navyAccent,
                  size: 20,
                ),
              ),
              items: busProvider.buses.map((b) {
                return DropdownMenuItem(
                  value: b,
                  child: Text(
                    '${b.busNumber} • ${b.currentRouteName ?? "Campus Route"}',
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedBus = val);
              },
            ),
            const SizedBox(height: 20),

            // Estimation Metrics Highlight Card
            Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder, width: 1.2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _statColumn(
                            'Approx. Distance',
                            distanceMeters != null
                                ? Formatters.formatDistance(distanceMeters)
                                : 'Location unavailable',
                            Icons.straighten_rounded,
                            AppColors.navyAccent,
                          ),
                        ),
                        Container(
                          height: 50,
                          width: 1,
                          color: AppColors.cardBorder,
                        ),
                        Expanded(
                          child: _statColumn(
                            'Est. Walking Time',
                            walkingMinutes != null
                                ? Formatters.formatDurationMinutes(walkingMinutes)
                                : 'Location unavailable',
                            Icons.directions_walk_rounded,
                            AppColors.success,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),

                    // Label: "Estimated"
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Algorithmic Estimation (Not Guaranteed)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Speed Slider Card (Interactive Calculation)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Pace Adjustment',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.navyAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_customSpeedKmH.toStringAsFixed(1)} km/h',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navyAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Adjust your estimated walking pace to recalculate travel time:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: _customSpeedKmH,
                      min: 3.0,
                      max: 7.0,
                      divisions: 8,
                      label: '${_customSpeedKmH.toStringAsFixed(1)} km/h',
                      activeColor: AppColors.primaryLight,
                      onChanged: (val) {
                        setState(() => _customSpeedKmH = val);
                        locationProvider.setWalkingSpeed(val);
                      },
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Slow (3 km/h)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Standard (5 km/h)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          'Brisk (7 km/h)',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Actions
            AppButton(
              text: 'Track this Bus on Live Map',
              icon: Icons.map_rounded,
              onPressed: () {
                busProvider.selectBus(bus);
                Navigator.of(context).pushNamed(AppRoutes.liveTracking);
              },
            ),
            const SizedBox(height: 12),
            AppButton(
              text: 'Check Reachability Status',
              icon: Icons.timer_outlined,
              type: AppButtonType.outline,
              onPressed: () {
                busProvider.selectBus(bus);
                Navigator.of(context).pushNamed(AppRoutes.reachability);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(
    String label,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Column(
      children: [
        Icon(icon, color: accentColor, size: 24),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
