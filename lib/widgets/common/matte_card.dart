import 'package:flutter/material.dart';
import '../../theme/wintermute_styles.dart';
import '../../theme/colors.dart';

/// Reusable matte-style card widget with consistent Wintermute styling
/// Used throughout the app for content containers
class MatteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? borderColor;
  final BoxDecoration? decoration;
  final EdgeInsets? margin;

  const MatteCard({
    Key? key,
    required this.child,
    this.padding,
    this.borderColor,
    this.decoration,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      padding: padding ?? const EdgeInsets.all(12),
      decoration: decoration ??
          WintermmuteStyles.customCardDecoration(
            borderColor: borderColor ?? AppColors.primary,
            backgroundColor: AppColors.surface.withOpacity(0.15),
          ),
      child: child,
    );
  }
}
