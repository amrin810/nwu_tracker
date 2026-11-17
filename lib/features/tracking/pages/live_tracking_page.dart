import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/demo_data.dart';
import '../../../core/utils/app_logger.dart';
import '../../../models/bus_model.dart';
import '../../../models/live_bus_location.dart';
import '../../../models/stop_model.dart';
import '../../../providers/bus_provider.dart';
import '../../../services/bus_location_service.dart';
import '../../../services/route_service.dart';
import '../../../widgets/bus_marker.dart';

/// Full-screen Real-Time Bus Tracking Page powered by flutter_map and OpenStreetMap.
/// Displays live GPS telemetry from Firebase Realtime Database with smooth marker
/// animations, user location, bus selector, road geometry via OSRM, and live bus info panel.
class LiveTrackingPage extends StatefulWidget {
  const LiveTrackingPage({super.key});

  @override
  State<LiveTrackingPage> createState() => _LiveTrackingPageState();
}

class _LiveTrackingPageState extends State<LiveTrackingPage>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final BusLocationService _locationService = BusLocationService.instance;
  final RouteService _routeService = RouteService.instance;

  StreamSubscription<Map<String, LiveBusLocation>>? _locationSubscription;
  StreamSubscription<bool>? _connectionSubscription;
  Timer? _uiRefreshTimer;

  bool _isRtdbConnected = false;
  bool _hasTileError = false;
  bool _isLoadingLocations = true;
  String? _streamErrorMessage;

  // Selected Bus & Camera Follow Mode
  String? _selectedBusId; // model format e.g. 'bus-101'
  bool _isFollowingBus = false;

  // Route geometry & Stops
  List<LatLng> _currentRoutePoints = [];
  List<BusStop> _currentRouteStops = [];
  bool _isLoadingRoute = false;
  String? _routeErrorMessage;

  // Student GPS Position
  LatLng _userLocation = const LatLng(
    AppConstants.defaultUserLatitude,
    AppConstants.defaultUserLongitude,
  );
  bool _hasUserLocation = false;

  // Coordinate animation interpolation
  late final AnimationController _animController;
  final Map<String, LatLng> _previousPositions = {};
  final Map<String, LatLng> _targetPositions = {};
  final Map<String, LatLng> _animatedPositions = {};
  Map<String, LiveBusLocation> _latestLocations = {};

  @override
  void initState() {
    super.initState();

    // 1. Setup smooth 60fps animation for marker movements & camera following
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        final progress = Curves.easeInOut.transform(_animController.value);
        setState(() {
          _targetPositions.forEach((busId, target) {
            final prev = _previousPositions[busId] ?? target;
            final lat =
                prev.latitude + (target.latitude - prev.latitude) * progress;
            final lng =
                prev.longitude + (target.longitude - prev.longitude) * progress;
            _animatedPositions[busId] = LatLng(lat, lng);
          });
        });

        // If follow mode is active, smoothly lock the camera to the moving bus
        if (_isFollowingBus && _selectedBusId != null) {
          final rtdbId = AppConstants.toRtdbBusId(_selectedBusId!);
          final currentPos =
              _animatedPositions[rtdbId] ?? _animatedPositions[_selectedBusId!];
          if (currentPos != null) {
            _mapController.move(currentPos, _mapController.camera.zoom);
          }
        }
      });

    // 2. Listen to RTDB connection state (.info/connected)
    _connectionSubscription =
        _locationService.isConnectedStream.listen((connected) {
      if (mounted) {
        setState(() => _isRtdbConnected = connected);
      }
    });

    // 3. Listen to live GPS stream from bus_locations
    _locationSubscription =
        _locationService.allBusLocationsStream.listen((locations) {
      if (mounted) {
        _onLocationsReceived(locations);
      }
    }, onError: (error) {
      AppLogger.error('Error on live tracking stream', error);
      if (mounted) {
        setState(() {
          _isLoadingLocations = false;
          _streamErrorMessage = 'Could not sync real-time GPS stream';
        });
      }
    });

    // 4. Periodically refresh relative time stamps ("x seconds ago")
    _uiRefreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted && _selectedBusId != null) {
        setState(() {});
      }
    });

    // 5. Request initial user location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchUserLocation();
    });
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _connectionSubscription?.cancel();
    _uiRefreshTimer?.cancel();
    _animController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onLocationsReceived(Map<String, LiveBusLocation> locations) {
    setState(() {
      _latestLocations = locations;
      _isLoadingLocations = false;
      _streamErrorMessage = null;

      bool hasPositionChange = false;
      locations.forEach((busId, loc) {
        final newTarget = LatLng(loc.latitude, loc.longitude);
        final currentAnim = _animatedPositions[busId];

        if (currentAnim == null) {
          _previousPositions[busId] = newTarget;
          _targetPositions[busId] = newTarget;
          _animatedPositions[busId] = newTarget;
        } else if (currentAnim.latitude != newTarget.latitude ||
            currentAnim.longitude != newTarget.longitude) {
          _previousPositions[busId] = currentAnim;
          _targetPositions[busId] = newTarget;
          hasPositionChange = true;
        }
      });

      if (hasPositionChange) {
        _animController.forward(from: 0.0);
      }
    });

    // If camera is following the selected bus, re-center when new data lands
    if (_isFollowingBus && _selectedBusId != null) {
      final rtdbId = AppConstants.toRtdbBusId(_selectedBusId!);
      final loc = locations[rtdbId] ?? locations[_selectedBusId!];
      if (loc != null) {
        _mapController.move(
            LatLng(loc.latitude, loc.longitude), _mapController.camera.zoom);
      }
    }
  }

  Future<void> _fetchUserLocation({bool animateCamera = false}) async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Location permission denied. Showing campus area.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );

      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
          _hasUserLocation = true;
        });

        if (animateCamera) {
          _mapController.move(_userLocation, 16.0);
        }
      }
    } catch (e) {
      AppLogger.warning('User location fetch error: $e');
    }
  }

  List<BusStop> _getStopsForBus(String busId, List<Bus> staticBuses) {
    final modelId = AppConstants.toModelBusId(busId);
    if (modelId == 'bus-101') return DemoData.sonadangaStops;
    if (modelId == 'bus-102') return DemoData.daulatpurStops;
    if (modelId == 'bus-103') return DemoData.boyraStops;

    final bus = staticBuses.where((b) => b.id == modelId).firstOrNull;
    if (bus?.currentRouteId != null) {
      if (bus!.currentRouteId == 'route-sonadanga') return DemoData.sonadangaStops;
      if (bus.currentRouteId == 'route-daulatpur') return DemoData.daulatpurStops;
      if (bus.currentRouteId == 'route-boyra') return DemoData.boyraStops;
    }
    return DemoData.sonadangaStops;
  }

  Future<void> _loadRouteForBus(String busId, List<Bus> staticBuses) async {
    final stops = _getStopsForBus(busId, staticBuses);
    setState(() {
      _currentRouteStops = stops;
      _isLoadingRoute = true;
      _routeErrorMessage = null;
    });

    try {
      final points = await _routeService.getRoutePointsForStops(
        cacheKey: AppConstants.toModelBusId(busId),
        stops: stops,
      );
      if (mounted && _selectedBusId == busId) {
        setState(() {
          _currentRoutePoints = points;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      if (mounted && _selectedBusId == busId) {
        setState(() {
          _currentRoutePoints = [];
          _isLoadingRoute = false;
          _routeErrorMessage = 'Road routing unavailable for this route';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Road routing service unavailable. Route stops are marked on map.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _selectBus(String busId, List<Bus> staticBuses) {
    setState(() {
      if (_selectedBusId == busId) {
        _selectedBusId = null;
        _isFollowingBus = false;
        _currentRoutePoints = [];
        _currentRouteStops = [];
        _routeErrorMessage = null;
      } else {
        _selectedBusId = busId;
        _isFollowingBus = true;
      }
    });

    if (_selectedBusId != null) {
      final rtdbId = AppConstants.toRtdbBusId(_selectedBusId!);
      final loc = _animatedPositions[rtdbId] ?? _animatedPositions[busId];
      if (loc != null) {
        _mapController.move(loc, 16.5);
      }

      // Fetch or read from cache the true OSRM road geometry
      _loadRouteForBus(_selectedBusId!, staticBuses);
    }
  }

  void _recenterOnSelectedBus() {
    if (_selectedBusId == null) return;
    setState(() => _isFollowingBus = true);
    final rtdbId = AppConstants.toRtdbBusId(_selectedBusId!);
    final loc =
        _animatedPositions[rtdbId] ?? _animatedPositions[_selectedBusId!];
    if (loc != null) {
      _mapController.move(loc, 16.5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busProvider = context.watch<BusProvider>();
    final staticBuses = busProvider.buses;

    // Collect all markers: Campus + Stops + User + Live Buses
    final markers = <Marker>[];

    // 1. Campus Marker (Origin)
    markers.add(
      Marker(
        point: const LatLng(
          AppConstants.defaultLatitude,
          AppConstants.defaultLongitude,
        ),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.school_rounded,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );

    // 2. Route Stop Markers (Shown when a bus is selected)
    for (final stop in _currentRouteStops) {
      final isOrigin = stop.sequenceOrder == 1;
      final isDestination = stop.sequenceOrder == _currentRouteStops.length;

      final Color stopColor = isOrigin
          ? AppColors.primary
          : (isDestination ? AppColors.warning : AppColors.navyAccent);

      markers.add(
        Marker(
          point: LatLng(stop.latitude, stop.longitude),
          width: 100,
          height: 44,
          alignment: Alignment.topCenter,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: stopColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: Text(
                  stop.stopName,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: stopColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. User Student GPS Marker
    markers.add(
      Marker(
        point: _userLocation,
        width: 38,
        height: 38,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.5),
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person_rounded,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );

    // 4. Live Animated Bus Markers
    _latestLocations.forEach((busId, liveLoc) {
      final point = _animatedPositions[busId] ??
          LatLng(liveLoc.latitude, liveLoc.longitude);
      final modelId = AppConstants.toModelBusId(busId);
      final isSelected = _selectedBusId == modelId || _selectedBusId == busId;

      markers.add(
        Marker(
          point: point,
          width: 90,
          height: 48,
          alignment: Alignment.topCenter,
          child: BusMarkerWidget(
            busNumber: busId.replaceAll('_', ' '),
            status: liveLoc.status,
            isSelected: isSelected,
            speed: liveLoc.speed,
            onTap: () => _selectBus(modelId, staticBuses),
          ),
        ),
      );
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Live Bus Tracking',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: 8),
            // RTDB Connection Status Dot
            Tooltip(
              message: _isRtdbConnected
                  ? 'Connected to Firebase Realtime Database'
                  : 'Waiting for Firebase connection...',
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isRtdbConnected
                      ? AppColors.success
                      : AppColors.warning,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRtdbConnected
                              ? AppColors.success
                              : AppColors.warning)
                          .withValues(alpha: 0.6),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh GPS',
            onPressed: () {
              _fetchUserLocation();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing GPS positions...'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. The Interactive OpenStreetMap Canvas
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(
                AppConstants.defaultLatitude,
                AppConstants.defaultLongitude,
              ),
              initialZoom: AppConstants.defaultMapZoom,
              minZoom: 8.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
              // Detect user manual dragging or pinching to pause follow mode
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture && _isFollowingBus) {
                  setState(() => _isFollowingBus = false);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: AppConstants.osmTileUrl,
                userAgentPackageName: AppConstants.osmUserAgent,
                errorTileCallback: (tile, error, stackTrace) {
                  if (!_hasTileError && mounted) {
                    setState(() => _hasTileError = true);
                  }
                },
              ),
              // Road Polyline Layer (OSRM Road Geometry)
              if (_currentRoutePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _currentRoutePoints,
                      strokeWidth: 4.5,
                      color: AppColors.navyAccent,
                      borderStrokeWidth: 1.5,
                      borderColor: AppColors.primary,
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Tile Loading Error Warning Banner
          if (_hasTileError)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        color: AppColors.warning, size: 16),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Map tiles loading slowly or offline. GPS telemetry is active.',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _hasTileError = false),
                      child: const Icon(Icons.close_rounded,
                          size: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Top Floating Horizontal Bus Selector Bar
          Positioned(
            top: _hasTileError ? 56 : 12,
            left: 0,
            right: 0,
            child: _buildBusSelectorBar(staticBuses),
          ),

          // 4. Recenter Button (Shown when user panned away from the selected bus)
          if (_selectedBusId != null && !_isFollowingBus)
            Positioned(
              bottom: 270,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(
                          color: AppColors.navyAccent, width: 1.5),
                    ),
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.6),
                  ),
                  icon: const Icon(Icons.center_focus_strong_rounded,
                      size: 16, color: AppColors.navyAccent),
                  label: const Text(
                    'Recenter on Bus',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  onPressed: _recenterOnSelectedBus,
                ),
              ),
            ),

          // 5. Floating Map Navigation Control Buttons (Right Side)
          Positioned(
            right: 16,
            bottom: _selectedBusId != null ? 270 : 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Recenter on Campus Button
                _buildMapActionButton(
                  icon: Icons.school_rounded,
                  tooltip: 'Center on Campus',
                  onPressed: () {
                    _mapController.move(
                      const LatLng(
                        AppConstants.defaultLatitude,
                        AppConstants.defaultLongitude,
                      ),
                      AppConstants.defaultMapZoom,
                    );
                  },
                ),
                const SizedBox(height: 8),

                // Locate Me Button
                _buildMapActionButton(
                  icon: _hasUserLocation
                      ? Icons.my_location_rounded
                      : Icons.location_searching_rounded,
                  tooltip: 'My Location',
                  color: AppColors.success,
                  onPressed: () => _fetchUserLocation(animateCamera: true),
                ),
                const SizedBox(height: 8),

                // Zoom In
                _buildMapActionButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Zoom In',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                ),
                const SizedBox(height: 8),

                // Zoom Out
                _buildMapActionButton(
                  icon: Icons.remove_rounded,
                  tooltip: 'Zoom Out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                ),
              ],
            ),
          ),

          // 6. Bottom Bus Info Panel (Active when a bus is selected)
          if (_selectedBusId != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: _buildBusInfoPanel(staticBuses),
            ),
        ],
      ),
    );
  }

  /// Interactive Bottom Panel showing live telemetry, route info and track controls
  Widget _buildBusInfoPanel(List<Bus> staticBuses) {
    final busId = _selectedBusId!;
    final rtdbId = AppConstants.toRtdbBusId(busId);
    final modelId = AppConstants.toModelBusId(busId);

    // Resolve static bus details
    final bus = staticBuses.firstWhere(
      (b) => b.id == modelId || b.id == busId,
      orElse: () => Bus(
        id: modelId,
        busNumber: rtdbId.replaceAll('_', ' '),
        busName: 'Campus Express Shuttle',
        licensePlate: 'KLN-TRANS-01',
        capacity: 50,
        status: BusStatus.active,
      ),
    );

    // Resolve live telemetry from RTDB stream
    final liveLoc = _latestLocations[rtdbId] ?? _latestLocations[busId];
    final status = liveLoc?.status ?? LiveBusStatus.offline;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (status) {
      case LiveBusStatus.live:
        statusColor = AppColors.success;
        statusLabel = 'Active • Live GPS';
        statusIcon = Icons.sensors_rounded;
        break;
      case LiveBusStatus.stale:
        statusColor = AppColors.warning;
        statusLabel = 'Stale • Signal Lost (>60s)';
        statusIcon = Icons.warning_amber_rounded;
        break;
      case LiveBusStatus.offline:
        statusColor = AppColors.textSecondary;
        statusLabel = 'Offline • No Telemetry';
        statusIcon = Icons.cloud_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Bus Name, Number, Status Badge & Close
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.navyAccent, width: 1),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          bus.busNumber,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: statusColor.withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 10, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                statusLabel,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bus.busName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 20, color: AppColors.textSecondary),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Close Info Panel',
                onPressed: () {
                  setState(() {
                    _selectedBusId = null;
                    _isFollowingBus = false;
                    _currentRoutePoints = [];
                    _currentRouteStops = [];
                    _routeErrorMessage = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Telemetry Row: Speed, Coordinates, Last Updated
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTelemetryItem(
                  icon: Icons.speed_rounded,
                  iconColor: AppColors.navyAccent,
                  label: 'Speed',
                  value: liveLoc != null
                      ? '${liveLoc.speed.toStringAsFixed(1)} km/h'
                      : '--',
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.cardBorder,
                ),
                _buildTelemetryItem(
                  icon: Icons.my_location_rounded,
                  iconColor: AppColors.success,
                  label: 'Coordinates',
                  value: liveLoc != null
                      ? '${liveLoc.latitude.toStringAsFixed(3)}, ${liveLoc.longitude.toStringAsFixed(3)}'
                      : 'Unavailable',
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.cardBorder,
                ),
                _buildTelemetryItem(
                  icon: Icons.access_time_rounded,
                  iconColor: statusColor,
                  label: 'Updated',
                  value: liveLoc?.lastUpdatedText ?? 'Never',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Route & Driver summary
          Row(
            children: [
              const Icon(Icons.alt_route_rounded,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Route: ${bus.currentRouteName ?? "Campus Standard Route"}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isLoadingRoute) ...[
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: AppColors.navyAccent,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Routing...',
                  style: TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ] else if (_routeErrorMessage != null) ...[
                const Icon(Icons.info_outline_rounded,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 4),
                const Text(
                  'OSRM Offline',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.warning),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Action Button: Track This Bus (Toggle Camera Lock)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    _isFollowingBus ? AppColors.navyAccent : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: _isFollowingBus
                        ? Colors.white
                        : AppColors.navyAccent,
                    width: 1.2,
                  ),
                ),
                elevation: 3,
              ),
              icon: Icon(
                _isFollowingBus
                    ? Icons.gps_fixed_rounded
                    : Icons.track_changes_rounded,
                size: 18,
              ),
              label: Text(
                _isFollowingBus
                    ? 'Tracking Camera Active (Following Bus)'
                    : 'Track This Bus',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              onPressed: () {
                setState(() => _isFollowingBus = !_isFollowingBus);
                if (_isFollowingBus) {
                  _recenterOnSelectedBus();
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Horizontal scrolling selector allowing the student to inspect active buses
  Widget _buildBusSelectorBar(List<Bus> staticBuses) {
    if (_isLoadingLocations) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.navyAccent,
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Listening to real-time bus GPS...',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_streamErrorMessage != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.danger),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 16, color: AppColors.danger),
            const SizedBox(width: 8),
            Text(
              _streamErrorMessage!,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textPrimary),
            ),
          ],
        ),
      );
    }

    // List of buses to display
    final busesToDisplay = staticBuses.isNotEmpty
        ? staticBuses.where((b) => b.id != 'bus-104').toList()
        : [
            const Bus(
              id: 'bus-101',
              busNumber: 'Bus 101',
              busName: 'Campus Express Sonadanga',
              licensePlate: 'KLN-101',
              capacity: 50,
              status: BusStatus.active,
            ),
            const Bus(
              id: 'bus-102',
              busNumber: 'Bus 102',
              busName: 'Campus Express Daulatpur',
              licensePlate: 'KLN-102',
              capacity: 50,
              status: BusStatus.active,
            ),
            const Bus(
              id: 'bus-103',
              busNumber: 'Bus 103',
              busName: 'Campus Express Boyra',
              licensePlate: 'KLN-103',
              capacity: 50,
              status: BusStatus.active,
            ),
          ];

    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: busesToDisplay.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            // "All Buses" chip
            final isAllSelected = _selectedBusId == null;
            return ChoiceChip(
              label: const Text('All Buses'),
              selected: isAllSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              side: BorderSide(
                color: isAllSelected
                    ? AppColors.navyAccent
                    : AppColors.cardBorder,
              ),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAllSelected ? Colors.white : AppColors.textSecondary,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedBusId = null;
                  _isFollowingBus = false;
                  _currentRoutePoints = [];
                  _currentRouteStops = [];
                  _routeErrorMessage = null;
                });
                _mapController.move(
                  const LatLng(
                    AppConstants.defaultLatitude,
                    AppConstants.defaultLongitude,
                  ),
                  AppConstants.defaultMapZoom,
                );
              },
            );
          }

          final bus = busesToDisplay[index - 1];
          final rtdbId = AppConstants.toRtdbBusId(bus.id);
          final liveLoc = _latestLocations[rtdbId] ?? _latestLocations[bus.id];
          final isSelected = _selectedBusId == bus.id;

          Color statusDotColor;
          if (liveLoc != null && liveLoc.isLive) {
            statusDotColor = AppColors.success;
          } else if (liveLoc != null && liveLoc.isStale) {
            statusDotColor = AppColors.warning;
          } else {
            statusDotColor = AppColors.textSecondary;
          }

          return ChoiceChip(
            avatar: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusDotColor,
                shape: BoxShape.circle,
              ),
            ),
            label: Text(bus.busNumber),
            selected: isSelected,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.surface,
            side: BorderSide(
              color:
                  isSelected ? AppColors.navyAccent : AppColors.cardBorder,
              width: isSelected ? 1.8 : 1.0,
            ),
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            onSelected: (_) => _selectBus(bus.id, staticBuses),
          );
        },
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: color ?? AppColors.textPrimary),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
