import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Button style variants for consistency
enum CyberButtonStyle {
  primary, // Cyan filled
  accent, // Green filled
  secondary, // Orange filled
  outlined, // Transparent with border
  text, // Text only
}

/// Reusable cyberpunk-themed button with consistent styling
/// Supports multiple style variants and optional icons
class CyberButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final CyberButtonStyle style;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsets? padding;

  const CyberButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.style = CyberButtonStyle.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  }) : super(key: key);

  Color get _backgroundColor {
    switch (style) {
      case CyberButtonStyle.primary:
        return AppColors.primary;
      case CyberButtonStyle.accent:
        return AppColors.accent;
      case CyberButtonStyle.secondary:
        return AppColors.secondary;
      case CyberButtonStyle.outlined:
      case CyberButtonStyle.text:
        return Colors.transparent;
    }
  }

  Color get _foregroundColor {
    switch (style) {
      case CyberButtonStyle.primary:
      case CyberButtonStyle.accent:
      case CyberButtonStyle.secondary:
        return AppColors.background;
      case CyberButtonStyle.outlined:
        return AppColors.primary;
      case CyberButtonStyle.text:
        return AppColors.textMid;
    }
  }

  BorderSide? get _borderSide {
    switch (style) {
      case CyberButtonStyle.outlined:
        return BorderSide(color: AppColors.primary, width: 2);
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (icon != null) {
      button = ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_foregroundColor),
                ),
              )
            : Icon(icon, size: 18),
        label: Text(
          text,
          style: WintermmuteStyles.bodyStyle.copyWith(
            color: _foregroundColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
        style: _buildButtonStyle(),
      );
    } else {
      button = ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _buildButtonStyle(),
        child: isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(_foregroundColor),
                ),
              )
            : Text(
                text,
                style: WintermmuteStyles.bodyStyle.copyWith(
                  color: _foregroundColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
      );
    }

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }

  ButtonStyle _buildButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: _backgroundColor,
      foregroundColor: _foregroundColor,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: _borderSide ?? BorderSide.none,
      ),
    );
  }
}
