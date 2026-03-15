import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';

/// Reusable header widget following Flutter best practices.
/// Provides consistent header styling across all screens in the app.
///
/// Usage:
/// ```dart
/// AppHeader(
///   icon: Icons.dashboard,
///   iconColor: WintermmuteStyles.colorCyan,
///   title: 'DASHBOARD',
/// )
/// ```
///
/// With optional trailing widgets:
/// ```dart
/// AppHeader(
///   icon: Icons.autorenew,
///   iconColor: WintermmuteStyles.colorGreen,
///   title: 'CYCLES',
///   trailing: Row(
///     children: [
///       ElevatedButton(...),
///     ],
///   ),
/// )
/// ```
class AppHeader extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Widget? trailing;

  const AppHeader({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: Colors.orange.withOpacity(0.8),  // DEBUG: Bright orange to verify build
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: trailing != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: WintermmuteStyles.titleStyle,
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        Divider(
          color: AppColors.primary.withOpacity(0.3),
          thickness: 1,
          height: 1,
        ),
      ],
    );
  }
}
