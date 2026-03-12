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
    decoration: TextDecoration.none,
  );

  // Section Headers: 18px, bold, cyan, letter-spacing 1px
  static const TextStyle headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    decoration: TextDecoration.none,
  );

  // Subheaders: 14px, regular, cyan, letter-spacing 0.5px
  static const TextStyle subHeaderStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 0.5,
    decoration: TextDecoration.none,
  );

  // Body Text: 14px, regular, light gray
  static const TextStyle bodyStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textLight,
    fontFamily: 'JetBrains Mono',
    decoration: TextDecoration.none,
  );

  // Small Text: 12px, regular, mid gray
  static const TextStyle smallStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textMid,
    fontFamily: 'JetBrains Mono',
    decoration: TextDecoration.none,
  );

  // Tiny Text: 10px, regular, dim gray
  static const TextStyle tinyStyle = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    color: AppColors.textDim,
    fontFamily: 'JetBrains Mono',
    decoration: TextDecoration.none,
  );

  // Tab Labels: Uppercase, cyan, JetBrains Mono
  static const TextStyle tabLabelStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    decoration: TextDecoration.none,
  );

  // Stat Value (Primary): Cyan, clean
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    decoration: TextDecoration.none,
  );

  // Stat Value (Accent): Green, clean
  static const TextStyle statValueAccentStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    decoration: TextDecoration.none,
  );

  // ==================== BOX SHADOWS (GLOW EFFECTS) ====================

  // Cyan glow for buttons/inputs (ENHANCED)
  static List<BoxShadow> cyanGlowShadow = [
    BoxShadow(
      color: colorCyan.withOpacity(0.6),
      blurRadius: 20,
      spreadRadius: 3,
    ),
    BoxShadow(
      color: colorCyan.withOpacity(0.3),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // Green glow for accent elements (ENHANCED)
  static List<BoxShadow> greenGlowShadow = [
    BoxShadow(
      color: colorGreen.withOpacity(0.6),
      blurRadius: 20,
      spreadRadius: 3,
    ),
    BoxShadow(
      color: colorGreen.withOpacity(0.3),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // Red glow for errors/warnings (ENHANCED)
  static List<BoxShadow> redGlowShadow = [
    BoxShadow(
      color: Color(0xFFFF0040).withOpacity(0.6),
      blurRadius: 20,
      spreadRadius: 3,
    ),
    BoxShadow(
      color: Color(0xFFFF0040).withOpacity(0.3),
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // Subtle glow for cards
  static List<BoxShadow> cardGlowShadow = [
    BoxShadow(
      color: colorCyan.withOpacity(0.15),
      blurRadius: 12,
      spreadRadius: 0,
    ),
  ];

  // Intense glow for active/focused elements
  static List<BoxShadow> intenseCyanGlow = [
    BoxShadow(
      color: colorCyan.withOpacity(0.8),
      blurRadius: 24,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: colorCyan.withOpacity(0.4),
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  // ==================== BOX DECORATIONS (MULTI-COLOR) ====================

  // Color palette matching dashboard
  static const Color colorCyan = Color(0xFF00FFFF);
  static const Color colorGreen = Color(0xFF39FF14);
  static const Color colorOrange = Color(0xFFFF6600);
  static const Color colorMagenta = Color(0xFFFF00FF);
  static const Color colorBTC = Color(0xFFF7931A);

  // Standard card: Dark background, cyan border
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorCyan.withOpacity(0.25),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Glowing card: Standard card with subtle glow
  static BoxDecoration cardDecorationGlow = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorCyan.withOpacity(0.35),
      width: 1.5,
    ),
    borderRadius: BorderRadius.circular(4),
    boxShadow: cardGlowShadow,
  );

  // Accent card: Green border
  static BoxDecoration cardDecorationAccent = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorGreen.withOpacity(0.25),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Orange card: For secondary sections
  static BoxDecoration cardDecorationOrange = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorOrange.withOpacity(0.25),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Magenta card: For tertiary sections
  static BoxDecoration cardDecorationMagenta = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorMagenta.withOpacity(0.25),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // BTC/Bitcoin card: For financial data
  static BoxDecoration cardDecorationBTC = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorBTC.withOpacity(0.25),
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
  );

  // Chart tooltip: Cyan
  static BoxDecoration chartTooltipDecoration = BoxDecoration(
    color: AppColors.surface.withOpacity(0.05),
    border: Border.all(
      color: colorCyan.withOpacity(0.4),
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
