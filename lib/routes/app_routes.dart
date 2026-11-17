import 'package:flutter/material.dart';
import '../features/splash/pages/splash_page.dart';
import '../features/auth/pages/login_page.dart';
import '../features/auth/pages/register_page.dart';
import '../features/main_shell/pages/main_shell_page.dart';
import '../features/tracking/pages/live_tracking_page.dart';
import '../features/schedule/pages/schedule_page.dart';
import '../features/nearby/pages/nearby_bus_page.dart';
import '../features/contact/pages/conductor_contact_page.dart';
import '../features/pickup/pages/pickup_request_page.dart';
import '../features/distance/pages/distance_time_page.dart';
import '../features/reachability/pages/reachability_page.dart';
import '../features/admin/pages/admin_dashboard_page.dart';
import '../features/profile/pages/profile_page.dart';
import '../features/profile/pages/edit_profile_page.dart';

/// Centralized route definitions and router for the application
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String mainShell = '/main';
  static const String home = '/home';
  static const String liveTracking = '/live-tracking';
  static const String schedule = '/schedule';
  static const String nearby = '/nearby';
  static const String contact = '/contact';
  static const String pickupRequest = '/pickup-request';
  static const String distanceTime = '/distance-time';
  static const String reachability = '/reachability';
  static const String admin = '/admin';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashPage());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case register:
        return MaterialPageRoute(builder: (_) => const RegisterPage());

      case mainShell:
        final initialIndex = settings.arguments as int? ?? 0;
        return MaterialPageRoute(builder: (_) => MainShellPage(initialIndex: initialIndex));

      case liveTracking:
        return MaterialPageRoute(builder: (_) => const LiveTrackingPage());

      case schedule:
        return MaterialPageRoute(builder: (_) => const SchedulePage());

      case nearby:
        return MaterialPageRoute(builder: (_) => const NearbyBusPage());

      case contact:
        return MaterialPageRoute(builder: (_) => const ConductorContactPage());

      case pickupRequest:
        return MaterialPageRoute(builder: (_) => const PickupRequestPage());

      case distanceTime:
        return MaterialPageRoute(builder: (_) => const DistanceTimePage());

      case reachability:
        return MaterialPageRoute(builder: (_) => const ReachabilityPage());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboardPage());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfilePage());

      case editProfile:
        return MaterialPageRoute(builder: (_) => const EditProfilePage());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Page Not Found')),
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
