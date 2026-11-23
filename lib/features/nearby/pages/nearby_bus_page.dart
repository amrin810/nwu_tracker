import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/bus_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/bus_card.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';

/// Nearby Bus Page calculating distance from student GPS to active buses
class NearbyBusPage extends StatelessWidget {
  const NearbyBusPage({super.key});

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final locationProvider = context.watch<LocationProvider>();

    final buses = busProvider.activeBuses;

    // Compute distance for each bus using live telemetry (from live_locations)
    final busesWithDistance = buses.map((bus) {
      final liveLoc = busProvider.getValidLiveLocation(bus.id);
      final double? distance = liveLoc != null
          ? locationProvider.calculateDistanceToCoords(
              liveLoc.latitude, liveLoc.longitude)
          : null;
      final int? walkingMinutes = distance != null
          ? locationProvider.calculateWalkingTimeMinutes(distance)
          : null;
      return _BusDistanceItem(
        bus: bus,
        distanceMeters: distance,
        walkingMinutes: walkingMinutes,
      );
    }).toList()
      ..sort((a, b) {
        if (a.distanceMeters == null && b.distanceMeters == null) return 0;
        if (a.distanceMeters == null) return 1;
        if (b.distanceMeters == null) return -1;
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Buses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Update GPS Location',
            onPressed: () => locationProvider.fetchUserLocation(),
          ),
        ],
      ),
      body: Column(
        children: [
          // GPS Status Notice Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: locationProvider.isUsingFallbackLocation
                ? AppColors.warningLight
                : AppColors.successLight,
            child: Row(
              children: [
                Icon(
                  locationProvider.isUsingFallbackLocation
                      ? Icons.location_searching_rounded
                      : Icons.gps_fixed_rounded,
                  size: 18,
                  color: locationProvider.isUsingFallbackLocation
                      ? AppColors.warning
                      : AppColors.success,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locationProvider.isUsingFallbackLocation
                        ? 'Using Campus Coordinates (${AppStrings.defaultLocationNote})'
                        : 'Accurate GPS Active • Sorted by nearest distance',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: locationProvider.isUsingFallbackLocation
                          ? AppColors.warning
                          : AppColors.success,
                    ),
                  ),
                ),
                if (locationProvider.isUsingFallbackLocation)
                  TextButton(
                    onPressed: () => locationProvider.fetchUserLocation(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Enable GPS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Bus List
          Expanded(
            child: busProvider.isLoading
                ? const LoadingWidget(message: 'Calculating nearby buses...')
                : busesWithDistance.isEmpty
                    ? EmptyState(
                        icon: Icons.directions_bus_rounded,
                        title: 'No Active Buses Nearby',
                        message: AppStrings.noBusesAvailable,
                        actionText: 'Refresh Fleet',
                        onAction: () => busProvider.fetchAllData(),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await busProvider.fetchAllData();
                          await locationProvider.fetchUserLocation();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: busesWithDistance.length,
                          itemBuilder: (context, index) {
                            final item = busesWithDistance[index];
                            return BusCard(
                              bus: item.bus,
                              distanceMeters: item.distanceMeters,
                              walkingTimeMinutes: item.walkingMinutes,
                              locationUnavailableText: 'Location unavailable',
                              onTap: () {
                                busProvider.selectBus(item.bus);
                                Navigator.of(context).pushNamed(AppRoutes.reachability);
                              },
                              onTrack: () {
                                busProvider.selectBus(item.bus);
                                Navigator.of(context).pushNamed(AppRoutes.liveTracking);
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

class _BusDistanceItem {
  final Bus bus;
  final double? distanceMeters;
  final int? walkingMinutes;

  _BusDistanceItem({
    required this.bus,
    this.distanceMeters,
    this.walkingMinutes,
  });
}
