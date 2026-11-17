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

    final bus =
        _selectedBus ??
        busProvider.selectedBus ??
        (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);
    final busLoc = bus != null ? busProvider.getLocationForBus(bus.id) : null;

    final distanceMeters = busLoc != null
        ? locationProvider.calculateDistanceToBus(busLoc)
        : 850.0;

    // Formula: Travel Time = Distance / Walking Speed
    final metersPerMinute = (_customSpeedKmH * 1000.0) / 60.0;
    final walkingMinutes = (distanceMeters / metersPerMinute).ceil();

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
              initialValue: bus,
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
                            Formatters.formatDistance(distanceMeters),
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
                            Formatters.formatDurationMinutes(walkingMinutes),
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
            const SizedBox(height: 24),

            // Configurable Walking Speed Slider
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Average Walking Speed',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${_customSpeedKmH.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navyAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _customSpeedKmH,
                      min: 3.0,
                      max: 7.0,
                      divisions: 8,
                      label: '${_customSpeedKmH.toStringAsFixed(1)} km/h',
                      onChanged: (val) {
                        setState(() => _customSpeedKmH = val);
                        locationProvider.setWalkingSpeed(val);
                      },
                    ),
                    const Text(
                      'Default: 5.0 km/h (Standard human pace ~83.3 meters/min)',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Viva Formula & Explanation Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mathematical Formula',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textWhite,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Travel Time (minutes) = Distance (meters) ÷ [ (Walking Speed in km/h × 1000) ÷ 60 ]',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textWhite,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Check Reachability Button
            AppButton(
              text: 'Evaluate Reachability Status',
              icon: Icons.speed_rounded,
              onPressed: () {
                if (bus != null) busProvider.selectBus(bus);
                Navigator.of(context).pushNamed(AppRoutes.reachability);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
