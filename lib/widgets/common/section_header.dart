import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable section header with optional icon and trailing widget
/// Used to separate content sections with consistent styling
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final Color? iconColor;
  final Color? textColor;
  final EdgeInsets? padding;

  const SectionHeader({
    Key? key,
    required this.title,
    this.icon,
    this.trailing,
    this.iconColor,
    this.textColor,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              color: iconColor ?? AppColors.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: textColor ?? AppColors.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
