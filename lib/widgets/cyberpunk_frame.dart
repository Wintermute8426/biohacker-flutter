import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Cyberpunk frame with corner brackets, glowing edges, and optional status LED
/// Perfect for cards, containers, and mechanical cyberdeck aesthetics
class CyberpunkFrame extends StatelessWidget {
  final Widget child;
  final double cornerSize;
  final double strokeWidth;
  final Color frameColor;
  final Color glowColor;
  final bool showStatusLed;
  final bool statusLedActive;
  final EdgeInsets padding;
  final bool showScanlines;

  const CyberpunkFrame({
    Key? key,
    required this.child,
    this.cornerSize = 12.0,
    this.strokeWidth = 1.5,
    this.frameColor = const Color(0xFF00FFFF),
    this.glowColor = const Color(0xFF00FFFF),
    this.showStatusLed = false,
    this.statusLedActive = true,
    this.padding = const EdgeInsets.all(12),
    this.showScanlines = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveFrameColor = frameColor == const Color(0xFF00FFFF) ? AppColors.primary : frameColor;
    final effectiveGlowColor = glowColor == const Color(0xFF00FFFF) ? AppColors.primary : glowColor;

    return Stack(
      children: [
        // Glow effect layer
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.3),
                blurRadius: 12,
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _CyberpunkFramePainter(
              cornerSize: cornerSize,
              strokeWidth: strokeWidth,
              frameColor: effectiveFrameColor,
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),

        // Status LED indicator
        if (showStatusLed)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: statusLedActive ? AppColors.accent : AppColors.textDim,
                shape: BoxShape.circle,
                boxShadow: statusLedActive
                    ? [
                        BoxShadow(
                          color: AppColors.accent.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}

class _CyberpunkFramePainter extends CustomPainter {
  final double cornerSize;
  final double strokeWidth;
  final Color frameColor;

  _CyberpunkFramePainter({
    required this.cornerSize,
    required this.strokeWidth,
    required this.frameColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = frameColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // Top-left corner bracket
    canvas.drawLine(Offset(0, cornerSize), Offset(0, 0), paint);
    canvas.drawLine(Offset(0, 0), Offset(cornerSize, 0), paint);

    // Top-right corner bracket
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);

    // Bottom-left corner bracket
    canvas.drawLine(Offset(0, size.height - cornerSize), Offset(0, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);

    // Bottom-right corner bracket
    canvas.drawLine(Offset(size.width - cornerSize, size.height), Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerSize), paint);

    // Optional: Add small decorative dashes at mid-points
    final dashSize = 4.0;

    // Top mid dash
    canvas.drawLine(
      Offset(size.width / 2 - dashSize, 0),
      Offset(size.width / 2 + dashSize, 0),
      paint,
    );

    // Bottom mid dash
    canvas.drawLine(
      Offset(size.width / 2 - dashSize, size.height),
      Offset(size.width / 2 + dashSize, size.height),
      paint,
    );

    // Left mid dash
    canvas.drawLine(
      Offset(0, size.height / 2 - dashSize),
      Offset(0, size.height / 2 + dashSize),
      paint,
    );

    // Right mid dash
    canvas.drawLine(
      Offset(size.width, size.height / 2 - dashSize),
      Offset(size.width, size.height / 2 + dashSize),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Terminal-style prompt indicator: >>
class TerminalPrompt extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const TerminalPrompt({
    Key? key,
    required this.text,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '>> ',
          style: TextStyle(
            color: AppColors.primary,
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
          ).merge(style),
        ),
        Text(
          text,
          style: TextStyle(
            color: AppColors.textLight,
            fontFamily: 'monospace',
          ).merge(style),
        ),
      ],
    );
  }
}

/// Pulsing glow animation for buttons
class PulsingGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final double minOpacity;
  final double maxOpacity;
  final Duration duration;

  const PulsingGlow({
    Key? key,
    required this.child,
    this.glowColor = const Color(0xFF00FFFF),
    this.minOpacity = 0.3,
    this.maxOpacity = 0.8,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  State<PulsingGlow> createState() => _PulsingGlowState();
}

class _PulsingGlowState extends State<PulsingGlow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: widget.minOpacity,
      end: widget.maxOpacity,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.glowColor == const Color(0xFF00FFFF) ? AppColors.primary : widget.glowColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withOpacity(_animation.value),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
