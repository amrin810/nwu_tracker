import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'app.dart';
import 'core/services/supabase_service.dart';
import 'firebase_options.dart';

const kUniversityName = 'North Western University';
const campus = LatLng(22.8200, 89.5400);
const userPosition = LatLng(22.8207, 89.5406);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (gracefully falls back if placeholder credentials are used)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  // Initialize Supabase (gracefully falls back if placeholder credentials are used)
  await SupabaseService.instance.initialize();

  // Lock to portrait orientation for standard university mobile tracking experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const UniversityBusApp());
}
