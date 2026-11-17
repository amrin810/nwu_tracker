import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/bus_model.dart';
import '../../../providers/bus_provider.dart';

/// Conductor and Driver authorized contact list
class ConductorContactPage extends StatelessWidget {
  const ConductorContactPage({super.key});

  Future<void> _makePhoneCall(BuildContext context, String? phoneNumber) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is not available for this contact.')),
      );
      return;
    }
    final uri = Uri.parse('tel:$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch dialer for $phoneNumber')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final buses = busProvider.buses;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver & Conductor Contacts'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: buses.length,
        itemBuilder: (context, index) {
          final bus = buses[index];
          return _buildBusContactCard(context, bus);
        },
      ),
    );
  }

  Widget _buildBusContactCard(BuildContext context, Bus bus) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.directions_bus_rounded, color: AppColors.navyAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      bus.busNumber,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  bus.currentRouteName ?? 'Campus Route',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const Divider(height: 20),

            // Conductor Contact Row
            _buildContactRow(
              context,
              role: 'Conductor',
              name: bus.conductorName ?? 'Assigned Conductor',
              phone: bus.conductorPhone ?? '01911000003',
              icon: Icons.support_agent_rounded,
            ),
            const SizedBox(height: 12),

            // Driver Contact Row
            _buildContactRow(
              context,
              role: 'Driver',
              name: bus.driverName ?? 'Assigned Driver',
              phone: bus.driverPhone ?? '01811000002',
              icon: Icons.airline_seat_recline_normal_rounded,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required String role,
    required String name,
    required String phone,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24, color: AppColors.navyAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyAccent,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.successLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Available',
                        style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  phone,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _makePhoneCall(context, phone),
            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.success),
            tooltip: 'Call $role',
          ),
        ],
      ),
    );
  }
}
