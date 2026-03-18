import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/wintermute_styles.dart';

/// Biohacker branded header with neon brain logo
/// Used for main screens (Dashboard, etc.)
class BiohackerHeader extends StatelessWidget {
  final Widget? trailing;

  const BiohackerHeader({
    Key? key,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          color: AppColors.surface.withOpacity(0.3),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: trailing != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Neon brain logo
                  Image.asset(
                    'assets/logo/biohacker-brain.png',
                    height: 32,
                    width: 32,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'BIOHACKER',
                    style: WintermmuteStyles.titleStyle.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: const Color(0xFF00FFFF),
                    ),
                  ),
                ],
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ],
    );
  }
}
