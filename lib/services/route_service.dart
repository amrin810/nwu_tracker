import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/app_logger.dart';
import '../models/stop_model.dart';

/// Service fetching true road geometry from the public OSRM (Open Source Routing Machine) API.
/// Caches polyline points in-memory per bus/route to prevent redundant network calls
/// when live GPS telemetry updates.
class RouteService {
  RouteService._();
  static final RouteService instance = RouteService._();
  factory RouteService() => instance;

  // In-memory cache: busId/routeId -> List of LatLng road points
  final Map<String, List<LatLng>> _cachedRoutes = {};

  /// Fetches road geometry points passing through the specified [stops].
  ///
  /// Rule: Does NOT draw straight lines between stops if routing fails.
  /// If the API times out or fails, returns empty list and logs error.
  Future<List<LatLng>> getRoutePointsForStops({
    required String cacheKey,
    required List<BusStop> stops,
  }) async {
    // 1. Return from in-memory cache immediately if already resolved
    if (_cachedRoutes.containsKey(cacheKey) &&
        _cachedRoutes[cacheKey]!.isNotEmpty) {
      AppLogger.info('Loaded cached road geometry for $cacheKey (${_cachedRoutes[cacheKey]!.length} points)');
      return _cachedRoutes[cacheKey]!;
    }

    if (stops.length < 2) {
      return [];
    }

    // 2. Format coordinate string: lon,lat;lon,lat;...
    final coordsParam = stops
        .map((s) =>
            '${s.longitude.toStringAsFixed(5)},${s.latitude.toStringAsFixed(5)}')
        .join(';');

    // 3. Query the public OSRM driving profile endpoint
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$coordsParam?overview=full&geometries=geojson',
    );

    try {
      AppLogger.info('Querying OSRM road geometry for $cacheKey: $uri');
      final response = await http
          .get(
            uri,
            headers: {'User-Agent': AppConstants.osmUserAgent},
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['code'] == 'Ok' &&
            data['routes'] is List &&
            (data['routes'] as List).isNotEmpty) {
          final firstRoute = data['routes'][0] as Map<String, dynamic>;
          final geometry = firstRoute['geometry'] as Map<String, dynamic>;
          final rawCoords = geometry['coordinates'] as List<dynamic>;

          // OSRM returns coordinates as [longitude, latitude]
          final points = rawCoords.map((coord) {
            final pair = coord as List<dynamic>;
            final lon = (pair[0] as num).toDouble();
            final lat = (pair[1] as num).toDouble();
            return LatLng(lat, lon);
          }).toList();

          if (points.isNotEmpty) {
            _cachedRoutes[cacheKey] = points;
            AppLogger.info(
                'Successfully cached ${points.length} road coordinates for $cacheKey');
            return points;
          }
        }
      }

      throw Exception(
          'OSRM routing failed with status ${response.statusCode}: ${response.body}');
    } catch (e) {
      AppLogger.warning(
          'OSRM routing error for $cacheKey: $e. No road route will be displayed.');
      rethrow;
    }
  }

  /// Clears in-memory cached road geometry
  void clearCache() {
    _cachedRoutes.clear();
  }
}

