import 'package:flutter/material.dart';

/// University Transportation Design System Color Palette
/// Dark theme: Black + Navy Blue Theme.
class AppColors {
  AppColors._();

  // University Brand Colors — Navy Blue Theme
  static const Color navy = Color(0xFF0A2463); // Main navy blue (NAVY)
  static const Color navyAccent = Color(0xFF3B82F6); // Lighter blue for readable elements on black (NAVY_ACCENT)
  static const Color primary = navy; // 0xFF0A2463 (Navy)
  static const Color primaryDark = Color(0xFF05153B); // Deeper Navy
  static const Color primaryLight = navyAccent; // 0xFF3B82F6 (Navy Accent)
  static const Color accent = navyAccent; // 0xFF3B82F6 (Navy Accent)
  static const Color secondary = Color(0xFF00897B); // Teal Accent
  static const Color secondaryLight = Color(0xFF004D40); // Dark Teal surface

  // Status & Semantic Feedback Colors
  static const Color success = Color(0xFF2E7D32); // Green (Active / Likely to catch)
  static const Color successLight = Color(0xFF1B3A1E); // Dark green surface

  static const Color warning = Color(0xFFEF6C00); // Orange (Hurry / Pending)
  static const Color warningLight = Color(0xFF3E2000); // Dark orange surface

  static const Color danger = Color(0xFFC62828); // Red (May miss / Rejected / Inactive)
  static const Color dangerLight = Color(0xFF3B0A0A); // Dark red surface

  static const Color info = Color(0xFF0277BD); // Info Blue
  static const Color infoLight = Color(0xFF012F4F); // Dark info surface

  // Neutral Background & Surface Colors
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0xFF0A1128); // Deep Blue-Black cards/tiles
  static const Color surfaceVariant = Color(0xFF0F1A30); // Slightly lighter dark surface
  static const Color cardBorder = Color(0xFF1B2A4E); // Dark blue border

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF); // White
  static const Color textSecondary = Color(0xFF9FB3D1); // Muted blue-gray
  static const Color textLight = Color(0xFF5F7A9E); // Dimmed text
  static const Color textWhite = Color(0xFFFFFFFF);

  // Map & Marker Specific Colors
  static const Color busMarker = navyAccent; // 0xFF3B82F6
  static const Color studentMarker = Color(0xFF00C853);
  static const Color stopMarker = Color(0xFF7C3AED);
  static const Color routePolyline = navyAccent; // 0xFF3B82F6

  // Splash Screen Theming (Clean White & Navy Theme)
  static const Color splashBackground = Color(0xFFFFFFFF);
  static const Color splashTitle = navy; // 0xFF0A2463
  static const Color splashSubtitle = Color(0xFF3B5998); // Lighter navy / blue-grey
  static const Color splashSpinner = navy; // 0xFF0A2463
  static const Color splashDecoPrimary = Color(0xFFBBD7F5); // Pale sky blue
  static const Color splashDecoSecondary = Color(0xFFD6E4F7); // Very light blue-grey
  static const Color splashShadow = Color(0x2E0A2463); // Soft navy shadow (~18% alpha)
  static const Color splashDecoShadow = Color(0x1A0A2463); // Subtle deco shadow (~10% alpha)
}
