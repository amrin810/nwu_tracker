/// Centralized user-facing strings and messages
class AppStrings {
  AppStrings._();

  // Navigation Titles
  static const String home = 'Home';
  static const String liveMap = 'Live Map';
  static const String schedule = 'Schedule';
  static const String nearby = 'Nearby Buses';
  static const String profile = 'Profile';
  static const String admin = 'Admin Portal';

  // Feature Titles
  static const String conductorContact = 'Conductor & Driver Contact';
  static const String pickupRequest = 'Pickup Request';
  static const String distanceTravelTime = 'Distance & Walking Time';
  static const String reachabilityStatus = 'Reachability Status';

  // Reachability Status Labels
  static const String likelyToCatch = 'Likely to Catch';
  static const String hurryBusNearby = 'Hurry — Bus is Nearby';
  static const String mayMissBus = 'May Miss the Bus';
  static const String busAlreadyPassed = 'Bus Already Passed';

  // Disclaimers & Limitations
  static const String reachabilityDisclaimer =
      'Reachability is an algorithmic estimation based on average walking speed (5 km/h) and expected bus arrival. It does not account for sudden road closures or unpredictable traffic.';

  static const String pickupDisclaimer =
      'Pickup requests are requests only and do not guarantee the bus will stop. Halts depend on approved safety zones, passenger density, and driver/conductor confirmation.';

  static const String simulatedDataNote = 'SIMULATED / DEMO DATA';

  // Permission & Error Messages
  static const String locationPermissionRequired =
      'Location permission is required to detect nearby buses and calculate reachability.';
  static const String gpsDisabled =
      'Device GPS is turned off. Please turn on Location services in your Android device settings.';
  static const String noInternet =
      'Unable to connect to the transportation server. Please check your internet connection.';
  static const String noBusesAvailable =
      'No active university buses are currently in service.';
}
