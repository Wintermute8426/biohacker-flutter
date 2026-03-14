import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Status badge styles
enum BadgeStyle {
  primary, // Cyan
  accent, // Green
  warning, // Orange
  error, // Red
  neutral, // Gray
}

/// Reusable badge widget for status indicators and labels
/// Used for status displays, categories, tags, etc.
class BadgeWidget extends StatelessWidget {
  final String text;
  final BadgeStyle style;
  final IconData? icon;
  final EdgeInsets? padding;
  final bool outlined;

  const BadgeWidget({
    Key? key,
    required this.text,
    this.style = BadgeStyle.primary,
    this.icon,
    this.padding,
    this.outlined = false,
  }) : super(key: key);

  Color get _color {
    switch (style) {
      case BadgeStyle.primary:
        return AppColors.primary;
      case BadgeStyle.accent:
        return AppColors.accent;
      case BadgeStyle.warning:
        return const Color(0xFFFF6B00);
      case BadgeStyle.error:
        return AppColors.error;
      case BadgeStyle.neutral:
        return AppColors.textMid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: outlined ? Colors.transparent : _color.withOpacity(0.2),
        border: Border.all(
          color: _color.withOpacity(outlined ? 0.6 : 0.2),
          width: outlined ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 12,
              color: _color,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: WintermmuteStyles.smallStyle.copyWith(
              color: _color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
