import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable info chip widget for displaying small pieces of labeled information
/// Used for route, site, frequency, etc. indicators
class InfoChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final Color? iconColor;
  final EdgeInsets? padding;

  const InfoChip({
    Key? key,
    this.icon,
    required this.label,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.iconColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background,
        border: Border.all(color: borderColor ?? AppColors.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: iconColor ?? AppColors.textMid,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: WintermmuteStyles.smallStyle.copyWith(
              color: textColor ?? AppColors.textMid,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
