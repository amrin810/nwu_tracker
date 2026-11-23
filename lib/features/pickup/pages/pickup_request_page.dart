import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../models/bus_model.dart';
import '../../../models/pickup_request_model.dart';
import '../../../models/route_model.dart';
import '../../../models/stop_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/pickup_request_card.dart';

/// Pickup Request Submission & History Page for university students
class PickupRequestPage extends StatefulWidget {
  const PickupRequestPage({super.key});

  @override
  State<PickupRequestPage> createState() => _PickupRequestPageState();
}

class _PickupRequestPageState extends State<PickupRequestPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _messageController = TextEditingController();

  Bus? _selectedBus;
  BusRoute? _selectedRoute;
  BusStop? _selectedStop;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final busProvider = context.read<BusProvider>();
    final authProvider = context.read<AuthProvider>();

    final bus =
        _selectedBus ??
        (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);
    final route =
        _selectedRoute ??
        (busProvider.routes.isNotEmpty ? busProvider.routes.first : null);
    final stop =
        _selectedStop ??
        (route?.stops.isNotEmpty == true ? route!.stops.first : null);

    if (authProvider.user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to submit a pickup request.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (bus == null || route == null || stop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select bus, route, and pickup stop.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final user = authProvider.user!;
    final request = PickupRequest(
      id: 'req-${DateTime.now().millisecondsSinceEpoch}',
      studentId: user.studentId ?? user.userId ?? user.id,
      studentName: user.fullName,
      studentPhone: user.phone,
      busId: bus.id,
      busNumber: bus.busNumber,
      routeId: route.id,
      routeName: route.routeName,
      stopId: stop.id,
      stopName: stop.stopName,
      status: PickupRequestStatus.pending,
      message: _messageController.text.trim().isNotEmpty
          ? _messageController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    final success = await busProvider.submitPickupRequest(request);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        _messageController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pickup request submitted successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        _tabController.animateTo(1); // Switch to History tab
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to submit pickup request. Please try again.'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final myRequests = busProvider.pickupRequests;

    final effectiveBus = (busProvider.buses.contains(_selectedBus))
        ? _selectedBus
        : (busProvider.buses.isNotEmpty ? busProvider.buses.first : null);

    final effectiveRoute = (busProvider.routes.contains(_selectedRoute))
        ? _selectedRoute
        : (busProvider.routes.isNotEmpty ? busProvider.routes.first : null);

    final currentStops = effectiveRoute?.stops ?? [];
    final effectiveStop = (currentStops.contains(_selectedStop))
        ? _selectedStop
        : (currentStops.isNotEmpty ? currentStops.first : null);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pickup Request'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'New Request'),
            Tab(text: 'Request History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: New Request Form
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Safety Disclaimer Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          AppStrings.pickupDisclaimer,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textPrimary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Select Bus Dropdown
                const Text(
                  'Select University Bus',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<Bus>(
                  key: ValueKey(effectiveBus?.id),
                  initialValue: effectiveBus,
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
                      child: Text('${b.busNumber} (${b.busName})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBus = val),
                ),
                const SizedBox(height: 16),

                // Select Route Dropdown
                const Text(
                  'Select Route',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<BusRoute>(
                  key: ValueKey(effectiveRoute?.id),
                  initialValue: effectiveRoute,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.alt_route_rounded,
                      color: AppColors.navyAccent,
                      size: 20,
                    ),
                  ),
                  items: busProvider.routes.map((r) {
                    return DropdownMenuItem(value: r, child: Text(r.routeName));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedRoute = val;
                      _selectedStop = val?.stops.isNotEmpty == true
                          ? val!.stops.first
                          : null;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Select Pickup Stop Dropdown
                const Text(
                  'Select Your Pickup Stop',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<BusStop>(
                  key: ValueKey('${effectiveRoute?.id}_${effectiveStop?.id}'),
                  initialValue: effectiveStop,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(
                      Icons.location_on_rounded,
                      color: AppColors.navyAccent,
                      size: 20,
                    ),
                  ),
                  items: currentStops.map((s) {
                    return DropdownMenuItem(
                      value: s,
                      child: Text(
                        '${s.stopName} (Stop #${s.sequenceOrder})',
                      ),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedStop = val),
                ),
                const SizedBox(height: 16),

                // Message Field
                AppTextField(
                  controller: _messageController,
                  label: 'Optional Message / Landmark',
                  hint: 'e.g. Waiting beside the pedestrian bridge',
                  prefixIcon: Icons.chat_bubble_outline_rounded,
                  maxLines: 2,
                ),
                const SizedBox(height: 24),

                // Submit Button
                AppButton(
                  text: 'Send Pickup Request',
                  icon: Icons.send_rounded,
                  isLoading: _isSubmitting,
                  onPressed: _submitRequest,
                ),
              ],
            ),
          ),

          // Tab 2: Request History
          myRequests.isEmpty
              ? const EmptyState(
                  icon: Icons.hail_rounded,
                  title: 'No Pickup Requests Yet',
                  message: 'Submit a pickup request when you are waiting at an approved bus stop.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: myRequests.length,
                  itemBuilder: (context, index) {
                    return PickupRequestCard(request: myRequests[index]);
                  },
                ),
        ],
      ),
    );
  }
}
