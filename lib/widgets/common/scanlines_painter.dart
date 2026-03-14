import 'package:flutter/material.dart';
import '../../theme/colors.dart';

/// Reusable scanlines painter for CRT effect
/// Creates horizontal lines across the screen for retro aesthetic
class ScanlinesPainter extends CustomPainter {
  final double opacity;
  final double spacing;

  const ScanlinesPainter({
    this.opacity = 0.07,
    this.spacing = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget wrapper for scanlines overlay
class ScanlinesOverlay extends StatelessWidget {
  final double opacity;
  final double spacing;

  const ScanlinesOverlay({
    Key? key,
    this.opacity = 0.07,
    this.spacing = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: ScanlinesPainter(
            opacity: opacity,
            spacing: spacing,
          ),
        ),
      ),
    );
  }
}
