import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/wintermute_styles.dart';

/// Reusable loading indicator with optional message
/// Consistent cyberpunk-themed loading spinner
class CyberLoading extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const CyberLoading({
    Key? key,
    this.message,
    this.color,
    this.size = 40.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              color: color ?? AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: WintermmuteStyles.bodyStyle.copyWith(
                color: AppColors.textMid,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
