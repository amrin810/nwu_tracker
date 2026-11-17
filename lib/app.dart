import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'main.dart';
import 'providers/auth_provider.dart';
import 'providers/bus_provider.dart';
import 'providers/location_provider.dart';
import 'routes/app_routes.dart';

/// Root Application Widget configuring Providers, Theme, and Route Navigation
class UniversityBusApp extends StatelessWidget {
  const UniversityBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BusProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
      ],
      child: MaterialApp(
        title: '$kUniversityName Bus',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
