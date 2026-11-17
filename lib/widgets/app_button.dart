import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum AppButtonType { primary, secondary, outline, text }

/// Reusable application button supporting loading indicator, icons and disabled states
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonType type;
  final IconData? icon;
  final Color? customColor;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.type = AppButtonType.primary,
    this.icon,
    this.customColor,
    this.height = 48,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    if (type == AppButtonType.outline) {
      return SizedBox(
        height: height,
        width: width ?? double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: customColor ?? AppColors.navyAccent,
            side: BorderSide(color: customColor ?? AppColors.navyAccent, width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _buildChild(context, customColor ?? AppColors.navyAccent),
        ),
      );
    }

    if (type == AppButtonType.text) {
      return SizedBox(
        height: height,
        child: TextButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildChild(context, customColor ?? AppColors.navyAccent),
        ),
      );
    }

    // Default: Primary ElevatedButton
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: customColor ?? (type == AppButtonType.secondary ? AppColors.secondary : AppColors.primary),
          foregroundColor: AppColors.textWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _buildChild(context, AppColors.textWhite),
      ),
    );
  }

  Widget _buildChild(BuildContext context, Color textColor) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.2,
          valueColor: AlwaysStoppedAnimation<Color>(textColor),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
