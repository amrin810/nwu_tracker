import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../main.dart';
import '../../../models/bus_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/bus_card.dart';
import '../../../widgets/section_header.dart';

/// Student Home & Transportation Dashboard
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final locationProvider = context.watch<LocationProvider>();
    final currentUser = context.watch<AuthProvider>().user;

    final activeBuses = busProvider.activeBuses;

    // Resolve closest active bus using live telemetry (from live_locations)
    Bus? closestBus;
    double? closestDistance;
    int? closestWalkingMinutes;

    final busesWithLive =
        activeBuses
            .map((b) {
              final liveLoc = busProvider.getValidLiveLocation(b.id);
              if (liveLoc != null) {
                final d = locationProvider.calculateDistanceToCoords(
                  liveLoc.latitude,
                  liveLoc.longitude,
                );
                final w = locationProvider.calculateWalkingTimeMinutes(d);
                return (bus: b, distance: d, walking: w);
              }
              return null;
            })
            .whereType<({Bus bus, double distance, int walking})>()
            .toList()
          ..sort((a, b) => a.distance.compareTo(b.distance));

    if (busesWithLive.isNotEmpty) {
      closestBus = busesWithLive.first.bus;
      closestDistance = busesWithLive.first.distance;
      closestWalkingMinutes = busesWithLive.first.walking;
    } else if (activeBuses.isNotEmpty) {
      closestBus = activeBuses.first;
      closestDistance = null;
      closestWalkingMinutes = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          kUniversityName,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_outlined),
            tooltip: 'Admin / Role Portal',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.admin),
          ),
          IconButton(
            icon: currentUser?.profileImageBytes != null
                ? CircleAvatar(
                    radius: 13,
                    backgroundImage: MemoryImage(
                      currentUser!.profileImageBytes!,
                    ),
                  )
                : const Icon(Icons.account_circle_outlined),
            tooltip: 'Profile',
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.profile),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await busProvider.fetchAllData();
          await locationProvider.fetchUserLocation();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Actions Grid
              const SectionHeader(
                title: 'Quick Transportation Actions',
                subtitle: 'Essential student commuting services',
              ),
              const SizedBox(height: 8),
              _buildFeatureGrid(context),
              const SizedBox(height: 20),

              // Nearby Bus Highlight Preview
              if (closestBus != null) ...[
                SectionHeader(
                  title: 'Nearby Bus Preview',
                  subtitle: closestDistance != null
                      ? 'Closest active transport to your location'
                      : 'Live GPS location currently unavailable',
                  actionLabel: 'View All',
                  onAction: () =>
                      Navigator.of(context).pushNamed(AppRoutes.nearby),
                ),
                const SizedBox(height: 4),
                BusCard(
                  bus: closestBus,
                  distanceMeters: closestDistance,
                  walkingTimeMinutes: closestWalkingMinutes,
                  locationUnavailableText: 'Location unavailable',
                  onTap: () {
                    busProvider.selectBus(closestBus);
                    Navigator.of(context).pushNamed(AppRoutes.reachability);
                  },
                  onTrack: () {
                    busProvider.selectBus(closestBus);
                    Navigator.of(context).pushNamed(AppRoutes.liveTracking);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Map Preview Banner Card
              Card(
                elevation: 0,
                color: AppColors.surface,
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
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.map_rounded,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live GPS Bus Tracking',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  'View real-time bus locations & route stops',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: () =>
                            Navigator.of(context)
                                .pushNamed(AppRoutes.liveTracking),
                        icon: const Icon(Icons.explore_rounded, size: 18),
                        label: const Text('View Live Tracking Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    final actions = [
      _FeatureAction(
        title: 'Live Tracking',
        icon: Icons.share_location_rounded,
        color: AppColors.navyAccent,
        route: AppRoutes.liveTracking,
      ),
      _FeatureAction(
        title: 'Bus Schedule',
        icon: Icons.calendar_month_rounded,
        color: AppColors.secondary,
        route: AppRoutes.schedule,
      ),
      _FeatureAction(
        title: 'Nearby Bus',
        icon: Icons.near_me_rounded,
        color: AppColors.success,
        route: AppRoutes.nearby,
      ),
      _FeatureAction(
        title: 'Reachability',
        icon: Icons.speed_rounded,
        color: AppColors.warning,
        route: AppRoutes.reachability,
      ),
      _FeatureAction(
        title: 'Pickup Request',
        icon: Icons.hail_rounded,
        color: AppColors.info,
        route: AppRoutes.pickupRequest,
      ),
      _FeatureAction(
        title: 'Conductor Info',
        icon: Icons.contact_phone_rounded,
        color: const Color(0xFF7C3AED),
        route: AppRoutes.contact,
      ),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final a = actions[index];
            return Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed(a.route),
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: a.color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon, color: a.color, size: 21),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        a.title,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FeatureAction {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  _FeatureAction({
    required this.title,
    required this.icon,
    required this.color,
    required this.route,
  });
}
