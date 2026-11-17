import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

/// Centralized service handling Supabase client initialization & connection status
class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();

  SupabaseService._internal();

  bool _isInitialized = false;

  /// True if Supabase was successfully initialized with real credentials
  bool get isInitialized => _isInitialized;

  /// Supabase Client instance (null-safe check)
  SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }

  /// Initialize Supabase Flutter SDK
  /// Gracefully catches invalid/placeholder configuration so demo mode still works.
  Future<void> initialize() async {
    final url = AppConstants.supabaseUrl;
    final anonKey = AppConstants.supabaseAnonKey;

    // Check if real credentials have been provided
    final isPlaceholder = url.contains('xyzcompany') || anonKey.contains('placeholder');

    if (isPlaceholder) {
      AppLogger.warning(
        'Supabase credentials are placeholders. Operating in local demo/fallback mode.',
        'SupabaseService',
      );
      _isInitialized = false;
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        // ignore: deprecated_member_use
        anonKey: anonKey,
        debug: false,
      );
      _isInitialized = true;
      AppLogger.info('Supabase initialized successfully.', 'SupabaseService');
    } catch (e, stack) {
      _isInitialized = false;
      AppLogger.error('Failed to initialize Supabase: $e', e, stack);
    }
  }
}
