import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bus_provider.dart';
import '../../../providers/location_provider.dart';
import '../../../routes/app_routes.dart';

/// Model representing a lightweight floating decorative element
class _DecoItem {
  final IconData icon;
  final bool isSecondary;
  final double relativeX; // Horizontal spread multiplier from center
  final double offsetY; // Vertical offset relative to center
  final double startInterval;
  final double endInterval;
  final double floatPhase;

  const _DecoItem({
    required this.icon,
    required this.isSecondary,
    required this.relativeX,
    required this.offsetY,
    required this.startInterval,
    required this.endInterval,
    required this.floatPhase,
  });
}

/// Restyled Splash & Session initialization screen
/// Clean White & Navy aesthetic with animated floating transportation motifs
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isFloating = false;

  // 6 balanced decorative transportation elements (bus, map pin, location marker, clock, route line, navigation)
  static const List<_DecoItem> _decoItems = [
    // 1. Clock (top-left)
    _DecoItem(
      icon: Icons.schedule_rounded,
      isSecondary: true,
      relativeX: -0.75,
      offsetY: -150,
      startInterval: 0.13,
      endInterval: 0.42,
      floatPhase: 0.0,
    ),
    // 2. Bus (top-right)
    _DecoItem(
      icon: Icons.directions_bus_rounded,
      isSecondary: false,
      relativeX: 0.75,
      offsetY: -150,
      startInterval: 0.22,
      endInterval: 0.50,
      floatPhase: 1.05,
    ),
    // 3. Map Pin (mid-left)
    _DecoItem(
      icon: Icons.location_on_rounded,
      isSecondary: false,
      relativeX: -0.95,
      offsetY: -76,
      startInterval: 0.30,
      endInterval: 0.59,
      floatPhase: 2.10,
    ),
    // 4. Route Line (mid-right)
    _DecoItem(
      icon: Icons.alt_route_rounded,
      isSecondary: false,
      relativeX: 0.95,
      offsetY: -76,
      startInterval: 0.39,
      endInterval: 0.67,
      floatPhase: 3.14,
    ),
    // 5. Location Marker (bottom-left)
    _DecoItem(
      icon: Icons.near_me_rounded,
      isSecondary: true,
      relativeX: -0.75,
      offsetY: 115,
      startInterval: 0.47,
      endInterval: 0.76,
      floatPhase: 4.19,
    ),
    // 6. Navigation Compass (bottom-right)
    _DecoItem(
      icon: Icons.navigation_rounded,
      isSecondary: false,
      relativeX: 0.75,
      offsetY: 115,
      startInterval: 0.56,
      endInterval: 0.84,
      floatPhase: 5.24,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Initial sequence: center logo pops in, deco items pop in staggered, texts fade in,
    // then seamlessly switches to a gentle looping float
    _controller.forward().then((_) {
      if (mounted) {
        setState(() => _isFloating = true);
        _controller.duration = const Duration(milliseconds: 2600);
        _controller.repeat(reverse: true);
      }
    });

    _initializeApp();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Artificial minimum delay for brand display
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();
    final busProvider = context.read<BusProvider>();
    final locationProvider = context.read<LocationProvider>();

    // Initialize session and prefetch transportation assets
    await Future.wait([
      authProvider.checkAuthStatus(),
      busProvider.fetchAllData(),
      locationProvider.fetchUserLocation(),
    ]);

    if (!mounted) return;

    // Navigate to Main Shell if authenticated, else Login
    if (authProvider.isAuthenticated) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.mainShell);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.splashBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final centerX = size.width / 2;
          final centerY = size.height / 2;

          // Responsive spread clamping so decorations stay inside screen boundaries on mobile & desktop
          final horizontalSpread =
              (size.width * 0.40).clamp(110.0, 230.0);

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final animVal = _controller.value;

              // Center Logo animations
              double logoScale;
              double logoOpacity;
              if (_isFloating) {
                logoScale = 1.0;
                logoOpacity = 1.0;
              } else {
                final t = (animVal / 0.32).clamp(0.0, 1.0);
                logoScale = 0.6 + (0.4 * Curves.easeOutBack.transform(t));
                logoOpacity = Curves.easeOut.transform(t);
              }

              // Title and Subtitle animations
              double textOpacity;
              double textSlide;
              if (_isFloating) {
                textOpacity = 1.0;
                textSlide = 0.0;
              } else {
                final t = ((animVal - 0.58) / 0.27).clamp(0.0, 1.0);
                textOpacity = Curves.easeOut.transform(t);
                textSlide = 14.0 * (1.0 - Curves.easeOutCubic.transform(t));
              }

              // Spinner animation
              double spinnerOpacity;
              if (_isFloating) {
                spinnerOpacity = 1.0;
              } else {
                final t = ((animVal - 0.70) / 0.25).clamp(0.0, 1.0);
                spinnerOpacity = Curves.easeOut.transform(t);
              }

              return Stack(
                fit: StackFit.expand,
                children: [
                  // Decorative Transportation Elements
                  for (final item in _decoItems)
                    _buildDecoWidget(
                      item: item,
                      centerX: centerX,
                      centerY: centerY,
                      horizontalSpread: horizontalSpread,
                      animVal: animVal,
                    ),

                  // Central Brand Unit (Logo, Title, Subtitle, Spinner)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Navy Logo Circle with White Bus Icon
                        Transform.scale(
                          scale: logoScale,
                          child: Opacity(
                            opacity: logoOpacity,
                            child: Container(
                              width: 112,
                              height: 112,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.splashShadow,
                                    blurRadius: 24,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_bus_rounded,
                                size: 56,
                                color: AppColors.splashBackground,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Title & Subtitle
                        Transform.translate(
                          offset: Offset(0, textSlide),
                          child: Opacity(
                            opacity: textOpacity,
                            child: Column(
                              children: const [
                                Text(
                                  AppConstants.appName,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.splashTitle,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Track your bus in real time',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.splashSubtitle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 48),

                        // Navy Spinner
                        Opacity(
                          opacity: spinnerOpacity,
                          child: const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.splashSpinner,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDecoWidget({
    required _DecoItem item,
    required double centerX,
    required double centerY,
    required double horizontalSpread,
    required double animVal,
  }) {
    // Staggered pop-in scale & opacity
    double scale;
    double opacity;
    if (_isFloating) {
      scale = 1.0;
      opacity = 1.0;
    } else {
      if (animVal < item.startInterval) {
        scale = 0.0;
        opacity = 0.0;
      } else if (animVal >= item.endInterval) {
        scale = 1.0;
        opacity = 1.0;
      } else {
        final t = ((animVal - item.startInterval) /
                (item.endInterval - item.startInterval))
            .clamp(0.0, 1.0);
        scale = Curves.easeOutBack.transform(t);
        opacity = Curves.easeOut.transform(t);
      }
    }

    if (opacity <= 0.0) return const SizedBox.shrink();

    // Gentle vertical float offset when in looping state
    final floatY = _isFloating
        ? math.sin((animVal * 2 * math.pi) + item.floatPhase) * 3.5
        : 0.0;

    final targetX = centerX + (item.relativeX * horizontalSpread);
    final targetY = centerY + item.offsetY + floatY;

    // Center the 40x40 circle on (targetX, targetY)
    return Positioned(
      left: targetX - 20,
      top: targetY - 20,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.isSecondary
                  ? AppColors.splashDecoSecondary
                  : AppColors.splashDecoPrimary,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: AppColors.splashDecoShadow,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 20,
              color: AppColors.splashBackground,
            ),
          ),
        ),
      ),
    );
  }
}
