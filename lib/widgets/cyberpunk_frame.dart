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
    this.frameColor = AppColors.primary,
    this.glowColor = AppColors.primary,
    this.showStatusLed = false,
    this.statusLedActive = true,
    this.padding = const EdgeInsets.all(12),
    this.showHardware = true, // Default ON
    this.showPanelIndicators = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveFrameColor = frameColor == AppColors.primary ? AppColors.primary : frameColor;
    final effectiveGlowColor = glowColor == AppColors.primary ? AppColors.primary : glowColor;

    return Stack(
      children: [
        // Subtle matte glow effect (Wintermute dashboard style)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.05), // Dark matte background like dashboard
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withOpacity(0.05), // Much more subtle glow
                blurRadius: 4, // Reduced blur
                spreadRadius: 0, // No spread for cleaner look
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

        // Corner rivets/screws (hardware decorations) - REMOVED per user request
        // if (showHardware) ...[
        //   _buildRivet(Alignment.topLeft),
        //   _buildRivet(Alignment.topRight),
        //   _buildRivet(Alignment.bottomLeft),
        //   _buildRivet(Alignment.bottomRight),
        // ],

        // Status LED indicator (top right, inside frame) - REMOVED per user request
        // if (showStatusLed)
        //   Positioned(
        //     top: 10,
        //     right: 10,
        //     child: _buildStatusLed(statusLedActive, effectiveFrameColor),
        //   ),

        // Side panel LED indicators - REMOVED per user request
        // if (showPanelIndicators) ...[
        //   // Left side indicators
        //   Positioned(
        //     left: 4,
        //     top: 30,
        //     child: _buildPanelLED(Colors.green),
        //   ),
        //   Positioned(
        //     left: 4,
        //     top: 45,
        //     child: _buildPanelLED(Colors.orange),
        //   ),
        //   // Right side indicators
        //   Positioned(
        //     right: 4,
        //     top: 30,
        //     child: _buildPanelLED(Colors.red),
        //   ),
        // ],
      ],
    );
  }

  Widget _buildRivet(Alignment alignment) {
    final effectiveFrameColor = frameColor == AppColors.primary ? AppColors.primary : frameColor;
    return Align(
      alignment: alignment,
      child: Container(
        width: 10, // Reduced for cleaner look
        height: 10,
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              effectiveFrameColor.withOpacity(0.15),
              effectiveFrameColor.withOpacity(0.2),
            ],
          ),
          border: Border.all(
            color: effectiveFrameColor.withOpacity(0.5), // Subtle border
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: effectiveFrameColor.withOpacity(0.2), // Subtle glow
              blurRadius: 3,
              spreadRadius: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLed(bool active, Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.8) : AppColors.textDim,
        shape: BoxShape.circle,
        border: Border.all(
          color: active ? color.withOpacity(0.6) : AppColors.textDim,
          width: 1,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4), // Subtle glow
                  blurRadius: 4,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
    );
  }

  Widget _buildPanelLED(Color color) {
    return Container(
      width: 5, // Increased from 4 for better visibility
      height: 5,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15), // Increased from 0.5
            blurRadius: 4, // Increased from 3
            spreadRadius: 0, // Added for better glow
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
      ..color = frameColor.withOpacity(0.2) // Matte Wintermute style - subtle border
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

    // Hardware decorations REMOVED per user request (notches, struts, seams, ports)
    // Clean rectangular border only
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
    this.glowColor = AppColors.primary,
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
    final effectiveColor = widget.glowColor == AppColors.primary ? AppColors.primary : widget.glowColor;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withOpacity(_animation.value),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
