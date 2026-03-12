import 'package:flutter/material.dart';
import '../theme/colors.dart';

/// Cyberpunk frame with FULL BORDERS and hardware elements
/// Industrial cyberdeck aesthetic with rivets, LEDs, and panel indicators
class CyberpunkFrame extends StatelessWidget {
  final Widget child;
  final double strokeWidth;
  final Color frameColor;
  final Color glowColor;
  final bool showStatusLed;
  final bool statusLedActive;
  final EdgeInsets padding;
  final bool showHardware; // Show rivets, ports, indicators
  final bool showPanelIndicators; // Show LED indicators on sides

  const CyberpunkFrame({
    Key? key,
    required this.child,
    this.strokeWidth = 2.0, // Thicker for hardware feel
    this.frameColor = const Color(0xFF00FFFF),
    this.glowColor = const Color(0xFF00FFFF),
    this.showStatusLed = false,
    this.statusLedActive = true,
    this.padding = const EdgeInsets.all(12),
    this.showHardware = true, // Default ON
    this.showPanelIndicators = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveFrameColor = frameColor == const Color(0xFF00FFFF) ? AppColors.primary : frameColor;
    final effectiveGlowColor = glowColor == const Color(0xFF00FFFF) ? AppColors.primary : glowColor;

    return Stack(
      children: [
        // Minimal glow effect (subtle outer shadow only)
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.15), // Reduced from 0.3
                blurRadius: 6, // Reduced from 12
                spreadRadius: 0,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _HardwareFramePainter(
              strokeWidth: strokeWidth,
              frameColor: effectiveFrameColor,
              showHardware: showHardware,
              showPanelIndicators: showPanelIndicators,
            ),
            child: Container(
              margin: EdgeInsets.all(strokeWidth + 2), // Space for full border
              child: Padding(
                padding: padding,
                child: child,
              ),
            ),
          ),
        ),

        // Corner rivets/screws (hardware decorations)
        if (showHardware) ...[
          _buildRivet(Alignment.topLeft),
          _buildRivet(Alignment.topRight),
          _buildRivet(Alignment.bottomLeft),
          _buildRivet(Alignment.bottomRight),
        ],

        // Status LED indicator (top right, inside frame)
        if (showStatusLed)
          Positioned(
            top: 10,
            right: 10,
            child: _buildStatusLed(statusLedActive, effectiveFrameColor),
          ),

        // Side panel LED indicators
        if (showPanelIndicators) ...[
          // Left side indicators
          Positioned(
            left: 4,
            top: 30,
            child: _buildPanelLED(Colors.green),
          ),
          Positioned(
            left: 4,
            top: 45,
            child: _buildPanelLED(Colors.orange),
          ),
          // Right side indicators
          Positioned(
            right: 4,
            top: 30,
            child: _buildPanelLED(Colors.red),
          ),
        ],
      ],
    );
  }

  Widget _buildRivet(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 8,
        height: 8,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.background,
          border: Border.all(
            color: frameColor == const Color(0xFF00FFFF) ? AppColors.primary : frameColor,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ),
        child: Container(
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (frameColor == const Color(0xFF00FFFF) ? AppColors.primary : frameColor).withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusLed(bool active, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color : AppColors.textDim,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color : AppColors.textDim,
          width: 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.6),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildPanelLED(Color color) {
    return Container(
      width: 4,
      height: 4,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 3,
          ),
        ],
      ),
    );
  }
}

class _HardwareFramePainter extends CustomPainter {
  final double strokeWidth;
  final Color frameColor;
  final bool showHardware;
  final bool showPanelIndicators;

  _HardwareFramePainter({
    required this.strokeWidth,
    required this.frameColor,
    required this.showHardware,
    required this.showPanelIndicators,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = frameColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    // FULL RECTANGULAR BORDER (like dashboard cards)
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    canvas.drawRect(rect, paint);

    if (showHardware) {
      // Top edge notches/cuts (hardware aesthetic)
      final notchPaint = Paint()
        ..color = frameColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.fill;

      // Small rectangular notches on top edge
      final notchWidth = 8.0;
      final notchHeight = 4.0;

      // Left notch
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.25 - notchWidth / 2, 0, notchWidth, notchHeight),
        notchPaint,
      );

      // Right notch
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.75 - notchWidth / 2, 0, notchWidth, notchHeight),
        notchPaint,
      );

      // Corner reinforcement lines (diagonal struts)
      final strutPaint = Paint()
        ..color = frameColor.withOpacity(0.5)
        ..strokeWidth = strokeWidth * 0.5
        ..style = PaintingStyle.stroke;

      final strutLength = 12.0;

      // Top-left corner strut
      canvas.drawLine(
        Offset(strokeWidth / 2 + 5, strokeWidth / 2),
        Offset(strokeWidth / 2, strokeWidth / 2 + strutLength),
        strutPaint,
      );

      // Top-right corner strut
      canvas.drawLine(
        Offset(size.width - strokeWidth / 2 - 5, strokeWidth / 2),
        Offset(size.width - strokeWidth / 2, strokeWidth / 2 + strutLength),
        strutPaint,
      );

      // Bottom-left corner strut
      canvas.drawLine(
        Offset(strokeWidth / 2 + 5, size.height - strokeWidth / 2),
        Offset(strokeWidth / 2, size.height - strokeWidth / 2 - strutLength),
        strutPaint,
      );

      // Bottom-right corner strut
      canvas.drawLine(
        Offset(size.width - strokeWidth / 2 - 5, size.height - strokeWidth / 2),
        Offset(size.width - strokeWidth / 2, size.height - strokeWidth / 2 - strutLength),
        strutPaint,
      );

      // Panel seam lines (vertical lines on sides)
      final seamPaint = Paint()
        ..color = frameColor.withOpacity(0.3)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;

      // Left side seam
      canvas.drawLine(
        Offset(strokeWidth + 2, size.height * 0.3),
        Offset(strokeWidth + 2, size.height * 0.7),
        seamPaint,
      );

      // Right side seam
      canvas.drawLine(
        Offset(size.width - strokeWidth - 2, size.height * 0.3),
        Offset(size.width - strokeWidth - 2, size.height * 0.7),
        seamPaint,
      );
    }

    if (showPanelIndicators) {
      // Port indicators (small rectangles on bottom edge)
      final portPaint = Paint()
        ..color = frameColor
        ..style = PaintingStyle.fill;

      final portWidth = 6.0;
      final portHeight = 3.0;

      // Bottom left port
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.3 - portWidth / 2,
          size.height - portHeight,
          portWidth,
          portHeight,
        ),
        portPaint,
      );

      // Bottom right port
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.7 - portWidth / 2,
          size.height - portHeight,
          portWidth,
          portHeight,
        ),
        portPaint,
      );
    }
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
