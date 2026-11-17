import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bus_model.dart';
import '../../../models/bus_location_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/app_button.dart';

/// Core Special Feature: Reachability Status Evaluation Page
class ReachabilityPage extends StatefulWidget {
  const ReachabilityPage({super.key});

  @override
  State<ReachabilityPage> createState() => _ReachabilityPageState();
}

class _ReachabilityPageState extends State<ReachabilityPage> {
  Bus? _selectedBus;
  int _expectedArrivalMinutes = 14; // Default simulated ETA for viva demo
  bool _busHasPassed = false;

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final bus =
        _selectedBus ??
        busProvider.selectedBus ??
        (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);

    final liveLoc = bus != null
        ? busProvider.getValidLiveLocation(bus.id)
        : null;
    final bool hasValidLocation = liveLoc != null;

    final double? distanceMeters = hasValidLocation
        ? locationProvider.calculateDistanceToCoords(
            liveLoc.latitude,
            liveLoc.longitude,
          )
        : null;
    final int? walkingMinutes = distanceMeters != null
        ? locationProvider.calculateWalkingTimeMinutes(distanceMeters)
        : null;

    // Run the rule-based reachability algorithm
    final result = locationProvider.computeReachability(
      bus: bus ?? busProvider.buses.first,
      busLocation: hasValidLocation
          ? BusLocation(
              busId: bus?.id ?? 'bus-101',
              latitude: liveLoc.latitude,
              longitude: liveLoc.longitude,
              speedKmH: liveLoc.speed,
              updatedAt: liveLoc.lastUpdated,
            )
          : null,
      expectedBusArrivalMinutes: _expectedArrivalMinutes,
      busHasPassedStop: _busHasPassed,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Reachability Status')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Target Bus Selector
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
                if (val != null) {
                  setState(() => _selectedBus = val);
                  busProvider.selectBus(val);
                }
              },
            ),
            const SizedBox(height: 20),

            // Big Prominent Reachability Banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: hasValidLocation
                    ? result.status.backgroundColor
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: hasValidLocation
                      ? result.status.color.withValues(alpha: 0.4)
                      : AppColors.textSecondary.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasValidLocation
                        ? result.status.icon
                        : Icons.location_off_rounded,
                    size: 48,
                    color: hasValidLocation
                        ? result.status.color
                        : AppColors.textSecondary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasValidLocation
                        ? result.status.label.toUpperCase()
                        : 'LOCATION UNAVAILABLE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: hasValidLocation
                          ? result.status.color
                          : AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    hasValidLocation ? result.explanation : 'No live GPS telemetry is currently received for this bus. Reachability cannot be calculated until real-time data is available.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Comparative Factor Table
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
                    const Text(
                      'Algorithmic Comparison Factors',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Divider(height: 20),
                    _factorRow('Target Bus', bus?.busNumber ?? 'Bus 101'),
                    _factorRow(
                      'Distance to Bus/Stop',
                      distanceMeters != null
                          ? Formatters.formatDistance(distanceMeters)
                          : 'Location unavailable',
                    ),
                    _factorRow(
                      'Estimated Walking Time',
                      walkingMinutes != null
                          ? Formatters.formatDurationMinutes(walkingMinutes)
                          : 'Location unavailable',
                    ),
                    _factorRow(
                      'Expected Bus Arrival (ETA)',
                      hasValidLocation
                          ? '$_expectedArrivalMinutes min'
                          : 'Unavailable',
                    ),
                    _factorRow(
                      'Time Margin (Buffer)',
                      hasValidLocation
                          ? '${result.timeMarginMinutes} min'
                          : 'Unavailable',
                      isHighlight: hasValidLocation,
                      highlightColor: result.status.color,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Interactive Viva Simulation Sliders & Toggles
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
                    const Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.navyAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Simulate Scenarios for Viva Demonstration',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Simulate Expected Bus Arrival:'),
                        Text(
                          '$_expectedArrivalMinutes min',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.navyAccent,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _expectedArrivalMinutes.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$_expectedArrivalMinutes min',
                      onChanged: (val) =>
                          setState(() => _expectedArrivalMinutes = val.toInt()),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Simulate Bus Already Passed Target Stop',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: _busHasPassed,
                      activeThumbColor: AppColors.danger,
                      onChanged: (val) => setState(() => _busHasPassed = val),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Academic Viva Logic Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Viva Note: How this is evaluated',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '1. If Bus Passed Stop ➔ Bus Already Passed\n'
                    '2. If (Bus ETA - Walking Time) ≥ 3 min ➔ Likely to Catch\n'
                    '3. If (Bus ETA - Walking Time) ≥ 0 min ➔ Hurry — Bus is Nearby\n'
                    '4. If (Bus ETA - Walking Time) < 0 min ➔ May Miss the Bus',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Track on map button
            AppButton(
              text: 'View Bus on Live Tracking Map',
              icon: Icons.map_rounded,
              onPressed: () {
                if (bus != null) busProvider.selectBus(bus);
                Navigator.of(context).pushNamed(AppRoutes.liveTracking);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _factorRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: highlightColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
