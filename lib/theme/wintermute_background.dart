import 'package:flutter/material.dart';
import 'colors.dart';

// Wintermute background with neon city lights effect (dashboard aesthetic)
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
        // Base background gradient with neon ads/lights
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF020408), // Top: very dark
                const Color(0xFF050a12),
                const Color(0xFF08101a),
                const Color(0xFF040810), // Bottom: dark
              ],
              stops: const [0.0, 0.3, 0.6, 1.0],
            ),
          ),
        ),
        // Neon city lights layer (floating ads from Wintermute Dashboard)
        Positioned.fill(
          child: CustomPaint(
            painter: _NeonLightsPainter(),
          ),
        ),
        // Main content
        child,
        // Grain/film noise overlay
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _GrainPainter(),
            ),
          ),
        ),
        // Scanlines (CRT effect)
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

// Neon city lights - radial gradients simulating ads/holograms
class _NeonLightsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Neon light positions and colors from dashboard aesthetic
    final lights = [
      (0.08, 0.15, const Color(0xFFFF0050), 0.04),   // Magenta top-left
      (0.88, 0.08, const Color(0xFF00C8FF), 0.035),  // Cyan top-right
      (0.72, 0.30, const Color(0xFFFFDC00), 0.05),   // Yellow center-top
      (0.18, 0.60, const Color(0xFFFF00FF), 0.04),   // Magenta left
      (0.94, 0.70, const Color(0xFF00FF64), 0.035),  // Green right
      (0.42, 0.88, const Color(0xFFFF7800), 0.045),  // Orange bottom
      (0.58, 0.12, const Color(0xFF64B4FF), 0.035),  // Light blue
      (0.28, 0.42, const Color(0xFFFF3296), 0.025),  // Hot pink
      (0.78, 0.52, const Color(0xFF00FFC8), 0.035),  // Cyan-green
      (0.52, 0.48, const Color(0xFFFF9632), 0.07),   // Orange center
      (0.12, 0.82, const Color(0xFF6400FF), 0.04),   // Purple bottom
      (0.68, 0.78, const Color(0xFFF7931A), 0.03),   // Orange-gold
      (0.03, 0.48, const Color(0xFF0096FF), 0.035),  // Bright blue
      (0.96, 0.42, const Color(0xFFFF0000), 0.025),  // Red right
    ];

    for (final (xPercent, yPercent, color, radiusPercent) in lights) {
      final dx = size.width * xPercent;
      final dy = size.height * yPercent;
      final radius = size.width * radiusPercent;

      // Radial gradient for each neon light
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [
            color.withOpacity(0.4),
            color.withOpacity(0.15),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCircle(center: Offset(dx, dy), radius: radius),
        );

      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Film grain/noise overlay
class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.08);
    final random = DateTime.now().millisecondsSinceEpoch;

    // Add random noise across canvas
    for (int x = 0; x < size.width.toInt(); x += 2) {
      for (int y = 0; y < size.height.toInt(); y += 2) {
        final seed = (random + x * 73 + y * 41) % 256;
        if (seed % 3 == 0) {
          canvas.drawCircle(
            Offset(x.toDouble(), y.toDouble()),
            1,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

// CRT scanlines effect
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..strokeWidth = 1;

    // Horizontal scanlines every 3 pixels
    for (double y = 0; y < size.height; y += 3) {
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
