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
    shadows: [
      Shadow(
        color: Color(0x6600FFFF), // Cyan glow, 40% opacity
        blurRadius: 8,
        offset: Offset(0, 0),
      ),
    ],
  );

  // Section Headers: 18px, bold, cyan, letter-spacing 1px
  static const TextStyle headerStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary, // Cyan
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    shadows: [
      Shadow(
        color: Color(0x6600FFFF), // Cyan glow, 40% opacity
        blurRadius: 8,
        offset: Offset(0, 0),
      ),
    ],
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

  // Stat Value (Primary): Cyan with glow
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    shadows: [
      Shadow(
        color: Color(0x6600FFFF), // Cyan glow
        blurRadius: 6,
        offset: Offset(0, 0),
      ),
    ],
  );

  // Stat Value (Accent): Green with glow
  static const TextStyle statValueAccentStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    fontFamily: 'JetBrains Mono',
    letterSpacing: 1.0,
    shadows: [
      Shadow(
        color: Color(0x6639FF14), // Green glow
        blurRadius: 6,
        offset: Offset(0, 0),
      ),
    ],
  );

  // ==================== BOX SHADOWS (GLOW EFFECTS) ====================

  // Cyan glow: Strong (for primary elements)
  static const List<BoxShadow> cyanGlowStrong = [
    BoxShadow(
      color: Color(0x6600FFFF), // Cyan, 40% opacity
      blurRadius: 12,
      spreadRadius: 2,
    ),
  ];

  // Cyan glow: Subtle (for secondary elements)
  static const List<BoxShadow> cyanGlowSubtle = [
    BoxShadow(
      color: Color(0x3300FFFF), // Cyan, 20% opacity
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // Green glow: Subtle
  static const List<BoxShadow> greenGlowSubtle = [
    BoxShadow(
      color: Color(0x3339FF14), // Green, 20% opacity
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // Magenta glow: Subtle
  static const List<BoxShadow> magentaGlowSubtle = [
    BoxShadow(
      color: Color(0x33FF00FF), // Magenta, 20% opacity
      blurRadius: 8,
      spreadRadius: 1,
    ),
  ];

  // ==================== BOX DECORATIONS ====================

  // Standard card: Dark background, cyan border, glow
  static BoxDecoration cardDecoration = BoxDecoration(
    color: AppColors.surface, // Dark surface
    border: Border.all(
      color: AppColors.primary.withOpacity(0.4), // Cyan border, 40% opacity
      width: 1,
    ),
    borderRadius: BorderRadius.circular(6),
    boxShadow: cyanGlowSubtle,
  );

  // Accent card: Dark background, green border, glow
  static BoxDecoration cardDecorationAccent = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(
      color: AppColors.accent.withOpacity(0.4), // Green border
      width: 1,
    ),
    borderRadius: BorderRadius.circular(6),
    boxShadow: greenGlowSubtle,
  );

  // Chart tooltip: Dark bg, cyan border
  static BoxDecoration chartTooltipDecoration = BoxDecoration(
    color: AppColors.surface,
    border: Border.all(
      color: AppColors.primary,
      width: 1,
    ),
    borderRadius: BorderRadius.circular(4),
    boxShadow: cyanGlowSubtle,
  );

  // ==================== HELPER METHODS ====================

  // Get glow color for a given base color
  static Color getGlowColor(Color baseColor) {
    if (baseColor == AppColors.primary) return Color(0x6600FFFF);
    if (baseColor == AppColors.accent) return Color(0x6639FF14);
    if (baseColor == AppColors.secondary) return Color(0x66FF00FF);
    return Color(0x66FFFFFF);
  }

  // Create a custom card decoration with specified glow color
  static BoxDecoration customCardDecoration({
    required Color borderColor,
    Color backgroundColor = AppColors.surface,
    double borderWidth = 1.0,
    double borderRadius = 6.0,
  }) {
    return BoxDecoration(
      color: backgroundColor,
      border: Border.all(
        color: borderColor.withOpacity(0.4),
        width: borderWidth,
      ),
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: [
        BoxShadow(
          color: borderColor.withOpacity(0.3),
          blurRadius: 8,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
