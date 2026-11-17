import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../models/live_bus_location.dart';

/// Custom marker widget rendered on the OpenStreetMap canvas for each university bus.
/// - Live: Navy background with blue accent, crisp icon and live dot
/// - Stale: Greyed background with warning icon
/// - Offline: Dark muted grey with offline badge
class BusMarkerWidget extends StatelessWidget {
  final String busNumber;
  final LiveBusStatus status;
  final bool isSelected;
  final double speed;
  final VoidCallback? onTap;

  const BusMarkerWidget({
    super.key,
    required this.busNumber,
    required this.status,
    this.isSelected = false,
    this.speed = 0.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Widget statusBadge;

    switch (status) {
      case LiveBusStatus.live:
        backgroundColor = AppColors.primary;
        borderColor = isSelected ? AppColors.navyAccent : AppColors.cardBorder;
        statusBadge = Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.success,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.success,
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        );
        break;

      case LiveBusStatus.stale:
        backgroundColor = const Color(0xFF2D3748);
        borderColor = AppColors.warning;
        statusBadge = const Icon(
          Icons.warning_amber_rounded,
          size: 10,
          color: AppColors.warning,
        );
        break;

      case LiveBusStatus.offline:
        backgroundColor = const Color(0xFF1A202C);
        borderColor = const Color(0xFF4A5568);
        statusBadge = Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.textSecondary,
            shape: BoxShape.circle,
          ),
        );
        break;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Marker Body Container
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: isSelected ? 2.2 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.navyAccent.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.4),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.directions_bus_rounded,
                  size: 15,
                  color: status == LiveBusStatus.offline
                      ? AppColors.textSecondary
                      : Colors.white,
                ),
                const SizedBox(width: 4),
                Text(
                  busNumber,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: status == LiveBusStatus.offline
                        ? AppColors.textSecondary
                        : Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                statusBadge,
              ],
            ),
          ),
          // Downward pointer tip
          CustomPaint(
            size: const Size(10, 5),
            painter: _TrianglePainter(
              color: backgroundColor,
              strokeColor: borderColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  final Color strokeColor;

  _TrianglePainter({required this.color, required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.strokeColor != strokeColor;
  }
}

