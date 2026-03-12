import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Cyberpunk scanline overlay for modals, dialogs, and cards
/// Provides that classic CRT/terminal aesthetic
class ScanlineOverlay extends StatelessWidget {
  final Widget child;
  final double spacing;
  final double opacity;
  final Color lineColor;

  const ScanlineOverlay({
    Key? key,
    required this.child,
    this.spacing = 2.0,
    this.opacity = 0.03,
    this.lineColor = const Color(0xFF00FFFF),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinesPainter(
                spacing: spacing,
                opacity: opacity,
                lineColor: lineColor,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScanlinesPainter extends CustomPainter {
  final double spacing;
  final double opacity;
  final Color lineColor;

  _ScanlinesPainter({
    required this.spacing,
    required this.opacity,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (lineColor == const Color(0xFF00FFFF) ? AppColors.primary : lineColor).withOpacity(opacity)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
