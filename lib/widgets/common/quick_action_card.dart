import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable quick action card for dashboard-style action buttons
/// Used in dashboard and other screens for quick access to features
class QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double? width;

  const QuickActionCard({
    Key? key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 6,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
