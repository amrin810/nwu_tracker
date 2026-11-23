import '../../models/bus_model.dart';
import '../../models/route_model.dart';
import '../../models/schedule_model.dart';
import '../../models/stop_model.dart';

/// Official North Western University (NWU) foundational transportation data
/// Used for initial seeding to Cloud Firestore and reliable offline cache.
class NWUDefaultData {
  NWUDefaultData._();

  // NWU Stops for Sonadanga Route
  static final List<BusStop> sonadangaStops = [
    const BusStop(
      id: 'stop-s-1',
      stopName: 'Campus Main Gate (Origin)',
      latitude: 22.8200,
      longitude: 89.5400,
      sequenceOrder: 1,
      estimatedMinutesFromStart: 0,
      routeId: 'route-sonadanga',
    ),
    const BusStop(
      id: 'stop-s-2',
      stopName: 'Fulbari Gate',
      latitude: 22.8230,
      longitude: 89.5440,
      sequenceOrder: 2,
      estimatedMinutesFromStart: 12,
      routeId: 'route-sonadanga',
    ),
    const BusStop(
      id: 'stop-s-3',
      stopName: 'Sonadanga',
      latitude: 22.8280,
      longitude: 89.5490,
      sequenceOrder: 3,
      estimatedMinutesFromStart: 25,
      routeId: 'route-sonadanga',
    ),
  ];

  // NWU Stops for Daulatpur Route
  static final List<BusStop> daulatpurStops = [
    const BusStop(
      id: 'stop-d-1',
      stopName: 'Campus Main Gate (Origin)',
      latitude: 22.8200,
      longitude: 89.5400,
      sequenceOrder: 1,
      estimatedMinutesFromStart: 0,
      routeId: 'route-daulatpur',
    ),
    const BusStop(
      id: 'stop-d-2',
      stopName: 'Khalishpur',
      latitude: 22.8270,
      longitude: 89.5380,
      sequenceOrder: 2,
      estimatedMinutesFromStart: 15,
      routeId: 'route-daulatpur',
    ),
    const BusStop(
      id: 'stop-d-3',
      stopName: 'Daulatpur',
      latitude: 22.8340,
      longitude: 89.5320,
      sequenceOrder: 3,
      estimatedMinutesFromStart: 30,
      routeId: 'route-daulatpur',
    ),
  ];

  // NWU Stops for Boyra Route
  static final List<BusStop> boyraStops = [
    const BusStop(
      id: 'stop-b-1',
      stopName: 'Campus Main Gate (Origin)',
      latitude: 22.8200,
      longitude: 89.5400,
      sequenceOrder: 1,
      estimatedMinutesFromStart: 0,
      routeId: 'route-boyra',
    ),
    const BusStop(
      id: 'stop-b-2',
      stopName: 'Gollamari',
      latitude: 22.8180,
      longitude: 89.5460,
      sequenceOrder: 2,
      estimatedMinutesFromStart: 10,
      routeId: 'route-boyra',
    ),
    const BusStop(
      id: 'stop-b-3',
      stopName: 'Boyra',
      latitude: 22.8120,
      longitude: 89.5510,
      sequenceOrder: 3,
      estimatedMinutesFromStart: 22,
      routeId: 'route-boyra',
    ),
  ];

  // NWU University Bus Routes
  static final List<BusRoute> defaultRoutes = [
    BusRoute(
      id: 'route-sonadanga',
      routeName: 'Campus ➔ Sonadanga',
      startPoint: 'Campus Main Gate',
      endPoint: 'Sonadanga',
      totalDistanceKm: 8.5,
      estimatedDurationMinutes: 25,
      stops: sonadangaStops,
    ),
    BusRoute(
      id: 'route-daulatpur',
      routeName: 'Campus ➔ Daulatpur',
      startPoint: 'Campus Main Gate',
      endPoint: 'Daulatpur',
      totalDistanceKm: 11.0,
      estimatedDurationMinutes: 30,
      stops: daulatpurStops,
    ),
    BusRoute(
      id: 'route-boyra',
      routeName: 'Campus ➔ Boyra',
      startPoint: 'Campus Main Gate',
      endPoint: 'Boyra',
      totalDistanceKm: 7.2,
      estimatedDurationMinutes: 22,
      stops: boyraStops,
    ),
  ];

  // NWU University Buses
  static final List<Bus> defaultBuses = [
    const Bus(
      id: 'bus-101',
      busNumber: 'Bus 101',
      busName: 'Campus Express Sonadanga',
      licensePlate: 'KLN-METRO-BA-11-2041',
      capacity: 52,
      currentRouteId: 'route-sonadanga',
      currentRouteName: 'Campus ➔ Sonadanga',
      status: BusStatus.active,
    ),
    const Bus(
      id: 'bus-102',
      busNumber: 'Bus 102',
      busName: 'Campus Express Daulatpur',
      licensePlate: 'KLN-METRO-BA-11-3098',
      capacity: 52,
      currentRouteId: 'route-daulatpur',
      currentRouteName: 'Campus ➔ Daulatpur',
      status: BusStatus.active,
    ),
    const Bus(
      id: 'bus-103',
      busNumber: 'Bus 103',
      busName: 'Campus Express Boyra',
      licensePlate: 'KLN-METRO-BA-11-4122',
      capacity: 40,
      currentRouteId: 'route-boyra',
      currentRouteName: 'Campus ➔ Boyra',
      status: BusStatus.active,
    ),
    const Bus(
      id: 'bus-104',
      busNumber: 'Bus 104',
      busName: 'Campus Reserve Shuttle',
      licensePlate: 'KLN-METRO-BA-11-5501',
      capacity: 35,
      status: BusStatus.maintenance,
    ),
  ];

  // NWU University Bus Schedules
  static final List<BusSchedule> defaultSchedules = [
    const BusSchedule(
      id: 'sch-1',
      busId: 'bus-101',
      busNumber: 'Bus 101',
      routeId: 'route-sonadanga',
      routeName: 'Campus ➔ Sonadanga',
      departureTime: '07:45 AM',
      expectedArrivalTime: '08:15 AM',
      dayOfWeek: 'Daily',
      status: 'On Time',
    ),
    const BusSchedule(
      id: 'sch-2',
      busId: 'bus-102',
      busNumber: 'Bus 102',
      routeId: 'route-daulatpur',
      routeName: 'Campus ➔ Daulatpur',
      departureTime: '08:00 AM',
      expectedArrivalTime: '08:30 AM',
      dayOfWeek: 'Daily',
      status: 'On Time',
    ),
    const BusSchedule(
      id: 'sch-3',
      busId: 'bus-103',
      busNumber: 'Bus 103',
      routeId: 'route-boyra',
      routeName: 'Campus ➔ Boyra',
      departureTime: '08:30 AM',
      expectedArrivalTime: '08:55 AM',
      dayOfWeek: 'Daily',
      status: 'On Time',
    ),
    const BusSchedule(
      id: 'sch-4',
      busId: 'bus-101',
      busNumber: 'Bus 101',
      routeId: 'route-sonadanga',
      routeName: 'Sonadanga to Campus (Return)',
      departureTime: '02:00 PM',
      expectedArrivalTime: '02:30 PM',
      dayOfWeek: 'Daily',
      status: 'Scheduled',
    ),
    const BusSchedule(
      id: 'sch-5',
      busId: 'bus-102',
      busNumber: 'Bus 102',
      routeId: 'route-daulatpur',
      routeName: 'Daulatpur to Campus (Return)',
      departureTime: '02:30 PM',
      expectedArrivalTime: '03:00 PM',
      dayOfWeek: 'Daily',
      status: 'Scheduled',
    ),
  ];
}
