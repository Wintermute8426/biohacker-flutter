import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable progress bar widget with label and percentage display
/// Supports gradient fills and custom styling
class CyberProgressBar extends StatelessWidget {
  final String label;
  final double progress; // 0.0 to 1.0
  final String? valueText;
  final Color? fillColor;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double height;
  final bool showPercentage;
  final IconData? icon;

  const CyberProgressBar({
    Key? key,
    required this.label,
    required this.progress,
    this.valueText,
    this.fillColor,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.height = 24.0,
    this.showPercentage = true,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final displayText = valueText ?? (showPercentage ? '${(clampedProgress * 100).toInt()}%' : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.textMid,
                size: 16,
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: WintermmuteStyles.smallStyle.copyWith(
                color: AppColors.textMid,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Progress bar
        Stack(
          children: [
            // Background
            Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor ?? AppColors.background,
                border: Border.all(color: borderColor ?? AppColors.border),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Fill
            FractionallySizedBox(
              widthFactor: clampedProgress,
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  gradient: gradient ??
                      LinearGradient(
                        colors: [
                          fillColor ?? AppColors.primary,
                          (fillColor ?? AppColors.primary).withOpacity(0.7),
                        ],
                      ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (fillColor ?? AppColors.primary).withOpacity(0.1),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            // Text overlay
            if (displayText.isNotEmpty)
              Container(
                height: height,
                alignment: Alignment.center,
                child: Text(
                  displayText,
                  style: WintermmuteStyles.bodyStyle.copyWith(
                    color: AppColors.textLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    shadows: [
                      Shadow(
                        color: AppColors.background,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
