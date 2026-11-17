import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/bus_provider.dart';
import '../../../widgets/empty_state.dart';
import '../../../widgets/loading_widget.dart';
import '../../../widgets/schedule_card.dart';

/// Bus Schedule Page with day and route filtering
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  String _selectedFilter = 'All';

  final List<String> _filters = ['All', 'Morning (AM)', 'Afternoon (PM)', 'Daily'];

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final schedules = busProvider.schedules;

    final filteredSchedules = schedules.where((s) {
      if (_selectedFilter == 'Morning (AM)') return s.departureTime.contains('AM');
      if (_selectedFilter == 'Afternoon (PM)') return s.departureTime.contains('PM');
      if (_selectedFilter == 'Daily') return s.dayOfWeek.toLowerCase() == 'daily';
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Schedule'),
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  final isSelected = _selectedFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(filter),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedFilter = filter);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Schedule List
          Expanded(
            child: busProvider.isLoading
                ? const LoadingWidget(message: 'Loading schedules...')
                : filteredSchedules.isEmpty
                    ? const EmptyState(
                        icon: Icons.calendar_today_rounded,
                        title: 'No Schedules Found',
                        message: 'No published bus departures match the selected filter.',
                      )
                    : RefreshIndicator(
                        onRefresh: () => busProvider.fetchAllData(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          itemCount: filteredSchedules.length,
                          itemBuilder: (context, index) {
                            final item = filteredSchedules[index];
                            return ScheduleCard(schedule: item);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
