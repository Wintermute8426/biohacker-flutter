import 'package:flutter/material.dart';
import 'colors.dart';

// Wintermute background - Clean dashboard aesthetic (minimal, crisp)
class WintermmuteBackground extends StatelessWidget {
  final Widget child;

  const WintermmuteBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pure gradient background (clean, no bloat)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF020408), // Top: deep black
                const Color(0xFF050a12),
                const Color(0xFF08101a),
                const Color(0xFF040810), // Bottom: deep black
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Main content (with transparency so gradient shows)
        child,
        // Scanlines overlay (CRT effect - crisp, minimal)
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _ScanlinesPainter(),
            ),
          ),
        ),
      ],
    );
  }
}

// CRT scanlines effect (crisp, sharp lines)
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.12)
      ..strokeWidth = 1.0;

    // Horizontal scanlines every 2 pixels (sharper than 3)
    for (double y = 0; y < size.height; y += 2) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
