import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable empty state widget for when there's no content to display
/// Shows icon, title, and optional message with consistent styling
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final Color? iconColor;

  const EmptyState({
    Key? key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: iconColor ?? AppColors.primary,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: WintermmuteStyles.titleStyle.copyWith(
              fontSize: 18,
            ),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.textMid,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    );
  }
}
