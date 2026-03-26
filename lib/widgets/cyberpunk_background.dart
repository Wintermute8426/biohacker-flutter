import 'package:flutter/material.dart';
import 'city_background.dart';
import 'cyberpunk_rain.dart';

/// Reusable cyberpunk background with animated cityscape + Matrix rain effect.
/// 
/// Wraps any screen content with consistent visual theme matching biohacker.systems:
/// - Pixelated city skyline (bottom ~30% of screen)
/// - Matrix-style falling rain (green digital characters)
/// - Optimized for 60fps on mid-range devices
/// 
/// Usage:
/// ```dart
/// CyberpunkBackground(
///   child: Scaffold(...),
/// )
/// ```
class CyberpunkBackground extends StatelessWidget {
  /// The screen content to display on top of the background
  final Widget child;
  
  /// Whether to show the animated city skyline
  final bool showCity;
  
  /// Whether to show the Matrix rain effect
  final bool showRain;
  
  /// Opacity of the city background (0.0 to 1.0)
  /// Higher = more prominent, lower = more subtle
  final double cityOpacity;
  
  /// Opacity of the rain effect (0.0 to 1.0)
  final double rainOpacity;
  
  /// Number of rain particles
  /// Reduce for better performance on low-end devices
  final int rainParticleCount;

  const CyberpunkBackground({
    Key? key,
    required this.child,
    this.showCity = true,
    this.showRain = true,
    this.cityOpacity = 0.4,
    this.rainOpacity = 0.35,
    this.rainParticleCount = 50,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Layer 1: Animated city skyline (bottom portion of screen)
        if (showCity)
          Positioned.fill(
            child: CityBackground(
              enabled: true,
              animateLights: true,
              opacity: cityOpacity,
            ),
          ),
        
        // Layer 2: Matrix rain overlay (full screen)
        if (showRain)
          Positioned.fill(
            child: CyberpunkRain(
              enabled: true,
              particleCount: rainParticleCount,
              opacity: rainOpacity,
            ),
          ),
        
        // Layer 3: Screen content on top
        child,
      ],
    );
  }
}
