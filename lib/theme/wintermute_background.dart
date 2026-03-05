import 'package:flutter/material.dart';
import 'colors.dart';
import 'dart:math';

// Wintermute background - Dashboard aesthetic with rain + scanlines
class WintermmuteBackground extends StatefulWidget {
  final Widget child;

  const WintermmuteBackground({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  State<WintermmuteBackground> createState() => _WintermmuteBackgroundState();
}

class _WintermmuteBackgroundState extends State<WintermmuteBackground>
    with TickerProviderStateMixin {
  late AnimationController _rainController;

  @override
  void initState() {
    super.initState();
    _rainController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _rainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Pure gradient background (deep, clean)
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
        // Rain effect layer
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _rainController,
            builder: (context, child) => CustomPaint(
              painter: _RainPainter(_rainController.value),
            ),
          ),
        ),
        // Main content
        widget.child,
        // Scanlines overlay (crisp CRT effect)
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

// Rain painter - animated falling raindrops with gradient
class _RainPainter extends CustomPainter {
  final double animationValue;
  late List<_Raindrop> raindrops;
  final Random _random = Random(42); // Fixed seed for consistency

  _RainPainter(this.animationValue) {
    // Initialize raindrops on first paint
    if (raindrops == null || raindrops.isEmpty) {
      _initRaindrops();
    }
  }

  void _initRaindrops() {
    raindrops = List.generate(150, (i) {
      return _Raindrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        length: _random.nextDouble() * 20 + 10,
        speed: _random.nextDouble() * 8 + 5,
        opacity: _random.nextDouble() * 0.4 + 0.2,
        width: _random.nextDouble() * 1.2 + 0.8,
      );
    });
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (raindrops.isEmpty) _initRaindrops();

    // Clear previous frame with slight fade
    final clearPaint = Paint()
      ..color = Colors.black.withOpacity(0.02)
      ..blendMode = BlendMode.srcOver;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      clearPaint,
    );

    // Draw each raindrop
    for (final drop in raindrops) {
      final x = drop.x * size.width;
      var y = (drop.y + animationValue * drop.speed) % 1.2 * size.height - drop.length;

      // Create gradient for raindrop
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFB4DCFF).withOpacity(0),
          Color(0xFFB4DCFF).withOpacity(drop.opacity * 0.7),
          const Color(0xFFB4DCFF).withOpacity(0),
        ],
      );

      final paint = Paint()
        ..shader = gradient.createShader(
          Rect.fromLTWH(x - 2, y, 4, drop.length),
        )
        ..strokeWidth = drop.width
        ..strokeCap = StrokeCap.round;

      // Draw raindrop line with slight wind effect
      canvas.drawLine(
        Offset(x, y),
        Offset(x - 3, y + drop.length),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RainPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class _Raindrop {
  double x;
  double y;
  final double length;
  final double speed;
  final double opacity;
  final double width;

  _Raindrop({
    required this.x,
    required this.y,
    required this.length,
    required this.speed,
    required this.opacity,
    required this.width,
  });
}

// CRT scanlines effect (crisp, minimal)
class _ScanlinesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Horizontal scanlines every 2 pixels
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
