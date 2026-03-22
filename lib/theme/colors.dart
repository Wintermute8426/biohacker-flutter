import 'package:flutter/material.dart';

class AppColors {
  // Wintermute Cyberpunk
  static const Color primary = Color(0xFF00FFFF); // Cyan
  static const Color secondary = Color(0xFFFF00FF); // Magenta
  static const Color accent = Color(0xFF39FF14); // Neon Green
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0xFF0A0A0A); // Dark gray (cards) - fully opaque for readability
  static const Color surfaceAlt = Color(0xFF111111); // Slightly lighter gray - fully opaque
  static const Color border = Color(0xFF00FFFF); // Cyan border
  static const Color borderDim = Color(0xFF1A2540); // Dim border
  static const Color textLight = Color(0xFFFFFFFF); // White
  static const Color textMid = Color(0xFFA0A0A0); // Gray
  static const Color textDim = Color(0xFF606060); // Dark gray
  static const Color amber = Color(0xFFFFAA00); // Amber/Gold
  static const Color error = Color(0xFFFF0040); // Red

  // Glow effects (matte aesthetic)
  static BoxShadow cyanGlow = BoxShadow(
    color: Color(0xFF00FFFF).withOpacity(0.1),
    blurRadius: 6,
    spreadRadius: 0,
  );

  static BoxShadow greenGlow = BoxShadow(
    color: Color(0xFF39FF14).withOpacity(0.1),
    blurRadius: 6,
    spreadRadius: 0,
  );

  static BoxShadow redGlow = BoxShadow(
    color: Color(0xFFFF0040).withOpacity(0.1),
    blurRadius: 6,
    spreadRadius: 0,
  );
}
