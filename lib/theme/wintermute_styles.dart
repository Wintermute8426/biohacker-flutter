import 'package:flutter/material.dart';
import 'colors.dart';

class WintermmuteStyles {
  // ==================== TEXT STYLES ====================
  
  // Page Titles: 22px, bold, cyan, letter-spacing 2px
  static const TextStyle titleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 2.0,
  );

  // Section Headers: 18px, bold, cyan, letter-spacing 1px
  static const TextStyle headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
  );

  // Subheaders: 14px, regular, cyan, letter-spacing 0.5px
  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 0.5,
  );

  // Body Text: 14px, regular, light gray
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    fontFamily: 'JetBrains Mono',
  );

  // Small Text: 12px, regular, mid gray
  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMid,
    fontFamily: 'JetBrains Mono',
  );

  // Tiny Text: 10px, regular, dim gray
  static const TextStyle tinyStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    fontFamily: 'JetBrains Mono',
  );

  // Tab Labels: Uppercase, cyan, JetBrains Mono
  static const TextStyle tabLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
  );

  // Stat Value (Primary): Cyan, clean
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
  );

  // Stat Value (Accent): Green, clean
  static const TextStyle statValueAccentStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
  );

  // ==================== BOX SHADOWS (MINIMAL) ====================

  // None needed - dashboard aesthetic uses clean borders, no glow

  // ==================== BOX DECORATIONS ====================

  // Standard card: Dark background, cyan border, clean (no glow)
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface, // Dark surface
    border: Border.all(
      color: AppColors.primary.withOpacity(0.3), // Cyan border, subtle
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Accent card: Dark background, green border, clean
  static BoxDecoration cardDecorationAccent = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(
      color: AppColors.accent.withOpacity(0.3), // Green border
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Chart tooltip: Dark bg, cyan border
  static BoxDecoration chartTooltipDecoration = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(
      color: AppColors.primary,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // ==================== HELPER METHODS ====================

  // Get glow color for a given base color
  static Color getGlowColor(Color baseColor) {
    if (baseColor == AppColors.primary) return Color(0x6600FFFF);
    if (baseColor == AppColors.accent) return Color(0x6639FF14);
    if (baseColor == AppColors.secondary) return Color(0x66FF00FF);
    return Color(0x66FFFFFF);
  }

  // Create a custom card decoration with specified border color (clean, no glow)
  static BoxDecoration customCardDecoration({
    required Color borderColor,
    Color backgroundColor = AppColors.surface,
    double borderWidth = 1.0,
    double borderRadius = 6.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(
        color: borderColor.withOpacity(0.3),
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }
}

// ==================== CUSTOM PAINTERS ====================

/// Scanlines overlay - horizontal CRT-style scanlines
class ScanlinesPainter extends CustomPainter {
  final double opacity;
  final double lineSpacing;

  ScanlinesPainter({
    this.opacity = 0.07,
    this.lineSpacing = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF606060).withOpacity(opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scanlines overlay widget
class ScanlinesOverlay extends StatelessWidget {
  final Widget child;
  final double opacity;
  final double lineSpacing;

  const ScanlinesOverlay({
    Key? key,
    required this.child,
    this.opacity = 0.07,
    this.lineSpacing = 3.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ScanlinesPainter(
                opacity: opacity,
                lineSpacing: lineSpacing,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
