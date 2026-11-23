import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bus_model.dart';
import '../../../models/pickup_request_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../widgets/dashboard_stat_card.dart';
import '../../../widgets/section_header.dart';
import '../../../widgets/status_badge.dart';

/// Admin & Transportation Management Portal
class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final busProvider = context.watch<BusProvider>();

    final buses = busProvider.buses;
    final activeBuses = busProvider.activeBuses;
    final requests = busProvider.pickupRequests;
    final pendingRequests = requests.where((r) => r.status == PickupRequestStatus.pending).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Transportation Portal'),
        actions: [
          IconButton(
            tooltip: 'Refresh Data',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              busProvider.fetchAllData();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Greeting Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.user?.fullName ?? 'Transport Admin',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Authorized: ${authProvider.currentRole.toFormattedString()} Access',
                          style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Transportation Statistics Grid
            const SectionHeader(
              title: 'System Telemetry & Assets',
              subtitle: 'University fleet overview',
            ),
            const SizedBox(height: 6),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                DashboardStatCard(
                  title: 'Total Buses',
                  value: '${buses.length}',
                  subtitle: 'Registered vehicles',
                  icon: Icons.directions_bus_rounded,
                  iconColor: AppColors.navyAccent,
                ),
                DashboardStatCard(
                  title: 'Active Fleet',
                  value: '${activeBuses.length}',
                  subtitle: 'Transmitting GPS',
                  icon: Icons.sensors_rounded,
                  iconColor: AppColors.success,
                ),
                DashboardStatCard(
                  title: 'Pending Pickups',
                  value: '${pendingRequests.length}',
                  subtitle: 'Awaiting dispatch approval',
                  icon: Icons.hail_rounded,
                  iconColor: AppColors.warning,
                ),
                DashboardStatCard(
                  title: 'Bus Routes',
                  value: '${busProvider.routes.length}',
                  subtitle: 'Active routes',
                  icon: Icons.alt_route_rounded,
                  iconColor: const Color(0xFF7C3AED),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active Fleet Overview Table
            const SectionHeader(
              title: 'Active Bus Overview',
              subtitle: 'Live fleet telemetry',
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: buses.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final bus = buses[index];
                  final loc = busProvider.getLocationForBus(bus.id);
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bus.status == BusStatus.active
                            ? AppColors.successLight
                            : AppColors.surfaceVariant,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_bus_rounded,
                        size: 20,
                        color: bus.status == BusStatus.active
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ),
                    title: Text(
                      bus.busNumber,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${bus.currentRouteName ?? "Standby"} • ${loc != null ? Formatters.formatRelativeTime(loc.updatedAt) : "No GPS"}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: StatusBadge.fromBusStatus(bus.status),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Pending Pickup Requests Review
            SectionHeader(
              title: 'Recent Pickup Requests',
              subtitle: 'Review or update student boarding requests',
              actionLabel: requests.isNotEmpty ? 'Count: ${requests.length}' : null,
            ),
            const SizedBox(height: 8),
            if (requests.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('No pickup requests submitted yet.', style: TextStyle(color: AppColors.textLight)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: requests.take(4).length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: AppColors.cardBorder),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${req.studentName} (${req.busNumber})',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                              StatusBadge.fromRequestStatus(req.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stop: ${req.stopName}',
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 8),
                          if (req.status == PickupRequestStatus.pending)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => busProvider.updateRequestStatus(
                                    req.id,
                                    PickupRequestStatus.rejected,
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.danger,
                                    side: const BorderSide(color: AppColors.danger),
                                    minimumSize: const Size(70, 30),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => busProvider.updateRequestStatus(
                                    req.id,
                                    PickupRequestStatus.accepted,
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.success,
                                    minimumSize: const Size(70, 30),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                  ),
                                  child: const Text('Accept', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
