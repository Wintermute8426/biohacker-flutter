import 'package:flutter/material.dart';

class AppColors {
  // Wintermute Cyberpunk
  static const Color primary = Color(0xFF00FFFF); // Cyan
  static const Color secondary = Color(0xFFFF00FF); // Magenta
  static const Color accent = Color(0xFF39FF14); // Neon Green
  static const Color background = Color(0xFF000000); // Pure Black
  static const Color surface = Color(0x0D0A0A0A); // Dark gray (cards) - now 5% opacity for better transparency
  static const Color surfaceAlt = Color(0x0D111111); // Slightly lighter gray - now 5% opacity
  static const Color border = Color(0xFF00FFFF); // Cyan border
  static const Color borderDim = Color(0xFF1A2540); // Dim border
  static const Color textLight = Color(0xFFFFFFFF); // White
  static const Color textMid = Color(0xFFA0A0A0); // Gray
  static const Color textDim = Color(0xFF606060); // Dark gray
  static const Color error = Color(0xFFFF0040); // Red

  // Glow effects
  static BoxShadow cyanGlow = BoxShadow(
    color: Color(0xFF00FFFF).withOpacity(0.5),
    blurRadius: 12,
    spreadRadius: 2,
  );

  static BoxShadow greenGlow = BoxShadow(
    color: Color(0xFF39FF14).withOpacity(0.5),
    blurRadius: 12,
    spreadRadius: 2,
  );

  static BoxShadow redGlow = BoxShadow(
    color: Color(0xFFFF0040).withOpacity(0.5),
    blurRadius: 12,
    spreadRadius: 2,
  );
}
