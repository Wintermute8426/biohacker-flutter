import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Cyberpunk city skyline background with neon lights and atmospheric haze
class CityBackground extends StatefulWidget {
  final bool enabled;
  final bool animateLights;
  final double opacity;

  const CityBackground({
    Key? key,
    this.enabled = true,
    this.animateLights = true,
    this.opacity = 0.4,
  }) : super(key: key);

  @override
  State<CityBackground> createState() => _CityBackgroundState();
}

class _CityBackgroundState extends State<CityBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
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
          painter: _CityBackgroundPainter(
            progress: widget.animateLights ? _controller.value : 0.5,
            opacity: widget.opacity,
          ),
          child: child,
        );
      },
    );
  }
}

class _CityBackgroundPainter extends CustomPainter {
  final double progress;
  final double opacity;
  final Random _random = Random(42); // Fixed seed for consistent building layout

  _CityBackgroundPainter({
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw atmospheric gradient background
    _drawAtmosphere(canvas, size);

    // Draw layered city buildings
    _drawDistantBuildings(canvas, size);
    _drawMidgroundBuildings(canvas, size);
    _drawForegroundBuildings(canvas, size);

    // Draw fog overlay for depth
    _drawFog(canvas, size);
  }

  void _drawAtmosphere(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0A0A1F).withOpacity(opacity * 0.8),
        const Color(0xFF1A0A2E).withOpacity(opacity * 0.6),
        const Color(0xFF2A1A3E).withOpacity(opacity * 0.4),
      ],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  void _drawDistantBuildings(Canvas canvas, Size size) {
    final baseHeight = size.height * 0.7;
    final buildingCount = 15;

    for (int i = 0; i < buildingCount; i++) {
      _random.nextDouble(); // Consume random for consistency
      final x = (i / buildingCount) * size.width;
      final width = size.width / buildingCount + _random.nextDouble() * 20;
      final height = 80 + _random.nextDouble() * 120;

      final rect = Rect.fromLTWH(x, baseHeight - height, width, height);

      // Building silhouette
      final buildingPaint = Paint()
        ..color = const Color(0xFF0F0F2F).withOpacity(opacity * 0.5);
      canvas.drawRect(rect, buildingPaint);

      // Occasional distant lights (very dim)
      if (_random.nextDouble() > 0.7) {
        final lightX = x + width * 0.3;
        final lightY = baseHeight - height * 0.5;
        final lightPaint = Paint()
          ..color = AppColors.primary.withOpacity(opacity * 0.2 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(Offset(lightX, lightY), 2, lightPaint);
      }
    }
  }

  void _drawMidgroundBuildings(Canvas canvas, Size size) {
    final baseHeight = size.height * 0.8;
    final buildingCount = 10;

    for (int i = 0; i < buildingCount; i++) {
      _random.nextDouble(); // Consume random for consistency
      final x = (i / buildingCount) * size.width;
      final width = size.width / buildingCount + _random.nextDouble() * 30;
      final height = 120 + _random.nextDouble() * 180;

      final rect = Rect.fromLTWH(x, baseHeight - height, width, height);

      // Building silhouette (darker)
      final buildingPaint = Paint()
        ..color = const Color(0xFF1A1A3F).withOpacity(opacity * 0.7);
      canvas.drawRect(rect, buildingPaint);

      // Neon edge highlight (left or right edge)
      if (_random.nextDouble() > 0.5) {
        final edgePaint = Paint()
          ..color = AppColors.secondary.withOpacity(opacity * 0.3)
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(x, baseHeight - height),
          Offset(x, baseHeight),
          edgePaint,
        );
      }

      // Windows with lights
      _drawWindows(canvas, rect, opacity * 0.4);
    }
  }

  void _drawForegroundBuildings(Canvas canvas, Size size) {
    final baseHeight = size.height * 0.9;
    final buildingCount = 6;

    for (int i = 0; i < buildingCount; i++) {
      _random.nextDouble(); // Consume random for consistency
      final x = (i / buildingCount) * size.width;
      final width = size.width / buildingCount + _random.nextDouble() * 40;
      final height = 180 + _random.nextDouble() * 250;

      final rect = Rect.fromLTWH(x, baseHeight - height, width, height);

      // Building silhouette (darkest)
      final buildingPaint = Paint()
        ..color = const Color(0xFF0A0A1F).withOpacity(opacity * 0.9);
      canvas.drawRect(rect, buildingPaint);

      // Neon accent lines
      if (_random.nextDouble() > 0.6) {
        final accentPaint = Paint()
          ..color = AppColors.accent.withOpacity(opacity * 0.4 * progress)
          ..strokeWidth = 2
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

        // Vertical neon line
        canvas.drawLine(
          Offset(x + width * 0.5, baseHeight - height),
          Offset(x + width * 0.5, baseHeight),
          accentPaint,
        );
      }

      // Windows with animated lights
      _drawWindows(canvas, rect, opacity * 0.6);

      // Top antenna/spire
      if (_random.nextDouble() > 0.7) {
        final spireHeight = 20 + _random.nextDouble() * 30;
        final spirePaint = Paint()
          ..color = AppColors.error.withOpacity(opacity * 0.8 * progress)
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(x + width * 0.5, baseHeight - height),
          Offset(x + width * 0.5, baseHeight - height - spireHeight),
          spirePaint,
        );

        // Blinking red light on top
        final blinkPaint = Paint()
          ..color = AppColors.error.withOpacity(opacity * 0.9 * progress)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
        canvas.drawCircle(
          Offset(x + width * 0.5, baseHeight - height - spireHeight),
          3,
          blinkPaint,
        );
      }
    }
  }

  void _drawWindows(Canvas canvas, Rect buildingRect, double windowOpacity) {
    final windowWidth = 4.0;
    final windowHeight = 6.0;
    final spacing = 12.0;

    final rows = (buildingRect.height / spacing).floor();
    final cols = (buildingRect.width / spacing).floor();

    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        // Random window on/off
        if (_random.nextDouble() > 0.4) {
          final x = buildingRect.left + col * spacing + spacing / 2;
          final y = buildingRect.top + row * spacing + spacing / 2;

          // Alternate between cyan and orange lights
          final lightColor = _random.nextDouble() > 0.5
              ? AppColors.primary
              : const Color(0xFFFF6B00);

          final windowPaint = Paint()
            ..color = lightColor.withOpacity(
              windowOpacity * (0.5 + 0.5 * progress),
            );

          canvas.drawRect(
            Rect.fromLTWH(x - windowWidth / 2, y - windowHeight / 2,
                windowWidth, windowHeight),
            windowPaint,
          );
        }
      }
    }
  }

  void _drawFog(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, size.height * 0.6, size.width, size.height * 0.4);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF1A1A3F).withOpacity(0),
        const Color(0xFF1A1A3F).withOpacity(opacity * 0.3),
      ],
    );

    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _CityBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
