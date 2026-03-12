import 'dart:math';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Matrix-style digital rain effect for cyberpunk aesthetic
class CyberpunkRain extends StatefulWidget {
  final bool enabled;
  final Color? color;
  final int particleCount;
  final double minSpeed;
  final double maxSpeed;
  final double opacity;

  const CyberpunkRain({
    Key? key,
    this.enabled = true,
    this.color,
    this.particleCount = 50,
    this.minSpeed = 100,
    this.maxSpeed = 300,
    this.opacity = 0.3,
  }) : super(key: key);

  @override
  State<CyberpunkRain> createState() => _CyberpunkRainState();
}

class _CyberpunkRainState extends State<CyberpunkRain>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<RainDrop> _drops = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // Initialize rain drops
    _initializeDrops();
  }

  void _initializeDrops() {
    _drops.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _drops.add(RainDrop(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        speed: widget.minSpeed +
            _random.nextDouble() * (widget.maxSpeed - widget.minSpeed),
        length: 20 + _random.nextDouble() * 30,
        opacity: 0.3 + _random.nextDouble() * 0.4,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _RainPainter(
            drops: _drops,
            progress: _controller.value,
            color: widget.color ?? AppColors.primary,
            opacity: widget.opacity,
          ),
          child: child,
        );
      },
    );
  }
}

class RainDrop {
  double x; // Horizontal position (0-1)
  double y; // Vertical position (0-1)
  final double speed; // Pixels per second
  final double length; // Length of the raindrop trail
  final double opacity;

  RainDrop({
    required this.x,
    required this.y,
    required this.speed,
    required this.length,
    required this.opacity,
  });

  void update(double dt, double screenHeight) {
    y += (speed * dt) / screenHeight;
    if (y > 1.0) {
      y = -0.1;
      x = Random().nextDouble();
    }
  }
}

class _RainPainter extends CustomPainter {
  final List<RainDrop> drops;
  final double progress;
  final Color color;
  final double opacity;
  DateTime? _lastUpdate;

  _RainPainter({
    required this.drops,
    required this.progress,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();
    final dt = _lastUpdate == null
        ? 0.016
        : (now.difference(_lastUpdate!).inMilliseconds / 1000.0);
    _lastUpdate = now;

    for (final drop in drops) {
      drop.update(dt, size.height);

      final x = drop.x * size.width;
      final y = drop.y * size.height;

      // Create gradient from bright to transparent
      final rect = Rect.fromLTWH(x - 1, y - drop.length, 2, drop.length);
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0),
          color.withOpacity(drop.opacity * opacity),
          color.withOpacity(drop.opacity * opacity * 0.5),
        ],
        stops: const [0.0, 0.5, 1.0],
      );

      final paint = Paint()
        ..shader = gradient.createShader(rect)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, y - drop.length),
        Offset(x, y),
        paint,
      );

      // Add a bright dot at the bottom for extra effect
      final dotPaint = Paint()
        ..color = color.withOpacity(drop.opacity * opacity * 1.5)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;

      canvas.drawPoints(
        PointMode.points,
        [Offset(x, y)],
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RainPainter oldDelegate) => true;
}
