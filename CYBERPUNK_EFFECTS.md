# Cyberpunk Visual Effects

This document describes the cyberpunk visual effects added to the Biohacker app.

## Overview

Two new animated widgets create an immersive cyberpunk atmosphere:
1. **CyberpunkRain** - Matrix-style digital rain effect
2. **CityBackground** - Animated cyberpunk city skyline

## CyberpunkRain Widget

Located: `lib/widgets/cyberpunk_rain.dart`

### Features
- Vertical falling particles with gradient trails
- Random speeds and positions for natural effect
- Customizable particle count, speed, color, and opacity
- Performance-optimized using CustomPaint
- Bright dots at particle tips for extra visual appeal

### Usage
```dart
CyberpunkRain(
  enabled: true,           // Toggle on/off
  particleCount: 50,       // Number of rain drops
  minSpeed: 100,           // Minimum fall speed (pixels/sec)
  maxSpeed: 300,           // Maximum fall speed (pixels/sec)
  opacity: 0.3,            // Overall opacity (0.0-1.0)
  color: AppColors.primary, // Optional custom color
)
```

### Parameters
- `enabled` (bool): Master toggle for the effect
- `particleCount` (int): Number of simultaneous rain drops (default: 50)
- `minSpeed` (double): Minimum fall speed in pixels/second (default: 100)
- `maxSpeed` (double): Maximum fall speed in pixels/second (default: 300)
- `opacity` (double): Overall opacity multiplier (default: 0.3)
- `color` (Color?): Custom color for rain drops (default: AppColors.primary)

## CityBackground Widget

Located: `lib/widgets/city_background.dart`

### Features
- Three-layer depth system (distant, midground, foreground buildings)
- Animated neon lights and window illumination
- Atmospheric gradient background (dark purple/blue tones)
- Fog overlay for depth perception
- Building features:
  - Random heights and positions
  - Neon edge highlights (cyan/orange)
  - Animated windows (alternating cyan/orange lights)
  - Antenna spires with blinking red lights
- Consistent layout using fixed random seed

### Usage
```dart
CityBackground(
  enabled: true,        // Toggle on/off
  animateLights: true,  // Animate building lights
  opacity: 0.4,         // Overall opacity (0.0-1.0)
)
```

### Parameters
- `enabled` (bool): Master toggle for the effect
- `animateLights` (bool): Whether to animate building lights (default: true)
- `opacity` (double): Overall opacity multiplier (default: 0.4)

## Implementation in Screens

### Dashboard Screen
- Subtle effects (lower opacity)
- City opacity: 0.3
- Rain particle count: 40
- Rain opacity: 0.25

```dart
Stack(
  children: [
    // City background layer
    const Positioned.fill(
      child: CityBackground(
        enabled: true,
        animateLights: true,
        opacity: 0.3,
      ),
    ),
    // Rain effect layer
    const Positioned.fill(
      child: CyberpunkRain(
        enabled: true,
        particleCount: 40,
        opacity: 0.25,
      ),
    ),
    // Your content here
  ],
)
```

### Login/Signup Screens
- Stronger effects for mood setting
- City opacity: 0.5
- Rain particle count: 60
- Rain opacity: 0.35

### Profile Screen
- Balanced effects
- City opacity: 0.3
- Rain particle count: 40
- Rain opacity: 0.25

## Performance Considerations

### Optimization Techniques
1. **CustomPaint**: Both widgets use Flutter's CustomPaint for efficient rendering
2. **IgnorePointer**: Wrapped in IgnorePointer to avoid hit testing overhead
3. **shouldRepaint**: Optimized repaint logic
4. **Fixed Random Seed**: City uses seed(42) for consistent layout without recalculation
5. **Positioned.fill**: Efficient full-screen positioning

### Performance Impact
- Minimal CPU usage during steady animation
- No layout calculations needed
- No gesture handling overhead
- Smooth 60fps on most devices

## Visual Design Philosophy

### Aesthetic Inspiration
- **Blade Runner**: Dark cyberpunk cityscape, neon lights, atmospheric fog
- **Matrix**: Digital rain effect, falling code aesthetic
- **Cyberpunk 2077**: Modern cyberpunk UI elements

### Color Palette
- Primary cyan (#00FFFF) - Digital, tech feel
- Secondary orange (#FF6B00) - Warmth, contrast
- Accent green (#00FF41) - Matrix-style
- Error red - Warning lights, antenna beacons
- Dark purples/blues - Atmospheric background

### Design Principles
1. **Subtle by default**: Effects enhance without distracting
2. **Layered depth**: Multiple visual layers create atmosphere
3. **Living world**: Animated elements suggest active environment
4. **Consistent aesthetic**: Matches existing Wintermute theme
5. **Toggle-able**: Can be disabled if user prefers

## Customization

### Adjusting Intensity
To make effects more subtle:
```dart
// Reduce opacity
CityBackground(opacity: 0.2)
CyberpunkRain(opacity: 0.15, particleCount: 30)
```

To make effects more prominent:
```dart
// Increase opacity and particles
CityBackground(opacity: 0.6)
CyberpunkRain(opacity: 0.5, particleCount: 80)
```

### Disabling Effects
```dart
// Simply set enabled to false
CityBackground(enabled: false)
CyberpunkRain(enabled: false)
```

### Custom Colors
```dart
// Use custom color scheme
CyberpunkRain(
  color: const Color(0xFF00FF41), // Matrix green
  opacity: 0.4,
)
```

## Future Enhancements

Potential additions:
1. **User Settings**: Add toggle in app settings
2. **Parallax Scrolling**: Make city move with scroll
3. **Glitch Effects**: Random screen glitches for extra cyberpunk feel
4. **Lightning Flashes**: Occasional atmospheric lightning
5. **Flying Vehicles**: Small animated vehicles passing by
6. **Holographic Ads**: Floating billboard elements
7. **Performance Mode**: Reduced effects for lower-end devices

## Technical Notes

### Animation Controllers
- CyberpunkRain: Continuous repeat animation (1 second duration)
- CityBackground: Reverse repeat animation (3 seconds for light pulsing)

### Random Distribution
- Rain: New random seed each drop for varied appearance
- City: Fixed seed (42) for consistent building layout across renders

### Z-Index Ordering (bottom to top)
1. City background
2. Rain effect
3. Scanlines overlay
4. App content

## Troubleshooting

### Performance Issues
- Reduce `particleCount` (try 30 or 20)
- Reduce `opacity` (makes GPU work less)
- Disable `animateLights` in CityBackground
- Set `enabled: false` to completely disable

### Visual Conflicts
- Adjust opacity if effects overwhelm content
- Ensure content has sufficient contrast
- Consider screen-specific opacity values

### Not Visible
- Check that widgets are in Stack with Positioned.fill
- Verify opacity is not too low
- Ensure enabled is true
- Check z-index ordering in Stack children

## Credits

Implemented by: Claude Sonnet 4.5
Design Style: Wintermute cyberpunk aesthetic
Inspired by: Blade Runner, Matrix, Cyberpunk 2077
