import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Floating data stream particles with binary/hex codes
class DataStreamOverlay extends StatefulWidget {
  final bool enabled;
  final int streamCount;
  final double opacity;

  const DataStreamOverlay({
    Key? key,
    this.enabled = true,
    this.streamCount = 5,
    this.opacity = 0.3,
  }) : super(key: key);

  @override
  State<DataStreamOverlay> createState() => _DataStreamOverlayState();
}

class _DataStreamOverlayState extends State<DataStreamOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<DataStream> _streams = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize data streams
    for (int i = 0; i < widget.streamCount; i++) {
      _streams.add(DataStream(
        x: _random.nextDouble(),
        speed: 0.02 + _random.nextDouble() * 0.03,
        offset: _random.nextDouble(),
        text: _generateRandomCode(),
      ));
    }
  }

  String _generateRandomCode() {
    const chars = '0123456789ABCDEF';
    return List.generate(4, (_) => chars[_random.nextInt(chars.length)]).join();
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
          painter: _DataStreamPainter(
            streams: _streams,
            progress: _controller.value,
            opacity: widget.opacity,
          ),
        );
      },
    );
  }
}

class DataStream {
  final double x;
  final double speed;
  final double offset;
  final String text;

  DataStream({
    required this.x,
    required this.speed,
    required this.offset,
    required this.text,
  });
}

class _DataStreamPainter extends CustomPainter {
  final List<DataStream> streams;
  final double progress;
  final double opacity;

  _DataStreamPainter({
    required this.streams,
    required this.progress,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var stream in streams) {
      final x = stream.x * size.width;
      final y = ((progress * stream.speed + stream.offset) % 1.0) * size.height;

      // Draw text
      final textPainter = TextPainter(
        text: TextSpan(
          text: stream.text,
          style: TextStyle(
            color: AppColors.primary.withOpacity(opacity * 0.6),
            fontSize: 10,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x, y));

      // Draw trailing line
      final linePaint = Paint()
        ..color = AppColors.primary.withOpacity(opacity * 0.2)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(x, y - 20),
        Offset(x, y),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DataStreamPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Animated scanning line effect
class ScanningLine extends StatefulWidget {
  final bool enabled;
  final Duration duration;
  final Color color;
  final double opacity;

  const ScanningLine({
    Key? key,
    this.enabled = true,
    this.duration = const Duration(seconds: 3),
    this.color = AppColors.accent,
    this.opacity = 0.3,
  }) : super(key: key);

  @override
  State<ScanningLine> createState() => _ScanningLineState();
}

class _ScanningLineState extends State<ScanningLine>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
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
          painter: _ScanningLinePainter(
            progress: _controller.value,
            color: widget.color,
            opacity: widget.opacity,
          ),
        );
      },
    );
  }
}

class _ScanningLinePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double opacity;

  _ScanningLinePainter({
    required this.progress,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final y = progress * size.height;

    // Main scanning line
    final linePaint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);

    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      linePaint,
    );

    // Glow trail
    final trailPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          color.withOpacity(opacity * 0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, y - 30, size.width, 60));

    canvas.drawRect(
      Rect.fromLTWH(0, y - 30, size.width, 60),
      trailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanningLinePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Corner brackets and status indicators
class CyberpunkCorners extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  final bool showStatusIndicators;

  const CyberpunkCorners({
    Key? key,
    this.size = 20,
    this.color = AppColors.primary,
    this.strokeWidth = 2,
    this.showStatusIndicators = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top-left corner
        Positioned(
          top: 0,
          left: 0,
          child: _buildCorner(true, true),
        ),
        // Top-right corner
        Positioned(
          top: 0,
          right: 0,
          child: _buildCorner(true, false),
        ),
        // Bottom-left corner
        Positioned(
          bottom: 0,
          left: 0,
          child: _buildCorner(false, true),
        ),
        // Bottom-right corner
        Positioned(
          bottom: 0,
          right: 0,
          child: _buildCorner(false, false),
        ),
      ],
    );
  }

  Widget _buildCorner(bool isTop, bool isLeft) {
    return CustomPaint(
      size: Size(size, size),
      painter: _CornerBracketPainter(
        color: color,
        strokeWidth: strokeWidth,
        isTop: isTop,
        isLeft: isLeft,
      ),
    );
  }
}

class _CornerBracketPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTop;
  final bool isLeft;

  _CornerBracketPainter({
    required this.color,
    required this.strokeWidth,
    required this.isTop,
    required this.isLeft,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    final path = Path();

    if (isTop && isLeft) {
      // Top-left: L shape
      path.moveTo(size.width, 0);
      path.lineTo(0, 0);
      path.lineTo(0, size.height);
    } else if (isTop && !isLeft) {
      // Top-right: mirrored L
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (!isTop && isLeft) {
      // Bottom-left: inverted L
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      // Bottom-right: inverted mirrored L
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Blinking status indicator dots
class StatusIndicators extends StatefulWidget {
  final List<Color> colors;
  final double spacing;
  final double size;

  const StatusIndicators({
    Key? key,
    this.colors = const [AppColors.accent, AppColors.primary, AppColors.error],
    this.spacing = 8,
    this.size = 6,
  }) : super(key: key);

  @override
  State<StatusIndicators> createState() => _StatusIndicatorsState();
}

class _StatusIndicatorsState extends State<StatusIndicators>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: widget.colors.asMap().entries.map((entry) {
            final index = entry.key;
            final color = entry.value;
            final opacity = 0.3 + (0.7 * _controller.value * (1 - index * 0.2));

            return Padding(
              padding: EdgeInsets.only(
                right: index < widget.colors.length - 1 ? widget.spacing : 0,
              ),
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: color.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(opacity * 0.5),
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

/// Glitch effect text
class GlitchText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final bool enabled;

  const GlitchText({
    Key? key,
    required this.text,
    required this.style,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<GlitchText> createState() => _GlitchTextState();
}

class _GlitchTextState extends State<GlitchText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();
  bool _isGlitching = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    // Random glitch intervals
    _scheduleNextGlitch();
  }

  void _scheduleNextGlitch() {
    Future.delayed(Duration(seconds: 3 + _random.nextInt(7)), () {
      if (mounted && widget.enabled) {
        setState(() => _isGlitching = true);
        _controller.forward().then((_) {
          _controller.reverse().then((_) {
            if (mounted) {
              setState(() => _isGlitching = false);
              _scheduleNextGlitch();
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || !_isGlitching) {
      return Text(widget.text, style: widget.style);
    }

    return Stack(
      children: [
        // Red channel offset
        Transform.translate(
          offset: Offset(-2 * _controller.value, 0),
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              color: Colors.red.withOpacity(0.5),
            ),
          ),
        ),
        // Blue channel offset
        Transform.translate(
          offset: Offset(2 * _controller.value, 0),
          child: Text(
            widget.text,
            style: widget.style.copyWith(
              color: Colors.blue.withOpacity(0.5),
            ),
          ),
        ),
        // Main text
        Text(widget.text, style: widget.style),
      ],
    );
  }
}
