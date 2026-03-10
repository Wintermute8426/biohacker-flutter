# Wintermute Calendar Theme Specification

**Critical:** Calendar must match the established cyberpunk aesthetic across Dashboard, Protocols, Research, Labs, and Reports tabs.

## Color Palette (Exact Values)

### Primary Colors
```dart
static const Color neonCyan = Color(0xFF00FFFF);      // Primary text, borders
static const Color neonGreen = Color(0xFF39FF14);     // Accent, success states
static const Color pureBlack = Color(0xFF000000);     // Backgrounds
static const Color darkSurface = Color(0xFF0A0E1A);   // Card backgrounds
static const Color deepBlack = Color(0xFF020408);     // Gradient top
```

### Status Colors
```dart
static const Color statusOnTrack = Color(0xFF39FF14);  // Green - all doses logged
static const Color statusPending = Color(0xFF00FFFF);  // Cyan - upcoming/pending
static const Color statusMissed = Color(0xFFFF0000);   // Red - missed doses
static const Color statusOverdue = Color(0xFFFF6600);  // Orange - warning
```

### Text Colors
```dart
static const Color textPrimary = Color(0xFF00FFFF);    // Cyan - headers
static const Color textLight = Color(0xFFFFFFFF);      // White - body text
static const Color textMid = Color(0xFFA0A0A0);        // Gray - secondary
static const Color textDim = Color(0xFF606060);        // Dark gray - disabled
```

### Border & Effects
```dart
static const Color borderCyan = Color(0x4000FFFF);     // 25% opacity cyan
static const Color borderGreen = Color(0x4039FF14);    // 25% opacity green
static const Color glowCyan = Color(0x6600FFFF);       // 40% opacity glow
static const Color glowGreen = Color(0x6639FF14);      // 40% opacity glow
```

## Typography (JetBrains Mono Required)

All calendar text uses **JetBrains Mono** monospace font:

```dart
// Week header ("MON TUE WED...")
static const TextStyle weekHeaderStyle = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 11,
  fontWeight: FontWeight.bold,
  color: Color(0xFF00FFFF),  // Cyan
  letterSpacing: 1.5,
);

// Date range ("MAR 10-16, 2026")
static const TextStyle dateRangeStyle = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 14,
  fontWeight: FontWeight.bold,
  color: Color(0xFF00FFFF),  // Cyan
  letterSpacing: 1.0,
);

// Day number in grid cell
static const TextStyle dayNumberStyle = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Color(0xFFFFFFFF),  // White
);

// Dose count indicator
static const TextStyle doseCountStyle = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 10,
  fontWeight: FontWeight.normal,
  color: Color(0xFF39FF14),  // Green
);

// Bottom sheet titles
static const TextStyle sheetTitleStyle = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 18,
  fontWeight: FontWeight.bold,
  color: Color(0xFF00FFFF),  // Cyan
  letterSpacing: 1.0,
);
```

## Effects Specifications

### Scanlines (CRT Effect)
```dart
// Subtle horizontal scanlines overlay
final scanlinesPaint = Paint()
  ..color = Colors.black.withOpacity(0.05)
  ..strokeWidth = 1.0;

// Spacing: 2-3 pixels (match existing)
// Applied to: Week grid, bottom sheet
```

### Film Grain
```dart
// SVG noise texture background
// Opacity: 0.03
// Pattern: Random noise, 256x256 tile
// Applied to: Calendar container, bottom sheet
```

### Neon Glow (Selective)
```dart
// Applied ONLY to day cells with active doses
static const List<BoxShadow> neonGlowCyan = [
  BoxShadow(
    color: Color(0x4D00FFFF),  // 30% opacity
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 0),
  ),
];

static const List<BoxShadow> neonGlowGreen = [
  BoxShadow(
    color: Color(0x4D39FF14),  // 30% opacity
    blurRadius: 8,
    spreadRadius: 0,
    offset: Offset(0, 0),
  ),
];

// DO NOT apply glow everywhere - only on:
// - Selected day cell
// - Day cells with logged doses
// - Active filter chips
```

## Animation Timing

Replace Material ripples with smooth glow animations:

```dart
// Tap feedback: Glow fade-in
AnimatedContainer(
  duration: const Duration(milliseconds: 200),
  curve: Curves.easeOut,
  decoration: BoxDecoration(
    color: isSelected ? Color(0xFF0A0E1A) : Colors.transparent,
    border: Border.all(
      color: isSelected ? Color(0xFF00FFFF) : Color(0x4000FFFF),
      width: 1,
    ),
    boxShadow: isSelected ? neonGlowCyan : null,
  ),
);

// NO RIPPLE: Remove InkWell, replace with GestureDetector
// NO SPLASH: Material(type: MaterialType.transparency)
```

## Material Design 3 Overrides

### Theme Extensions
```dart
// Override Material colors in ThemeData
final calendarTheme = ThemeData(
  scaffoldBackgroundColor: Color(0xFF000000),  // Pure black
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF00FFFF),        // Cyan
    secondary: Color(0xFF39FF14),      // Green
    surface: Color(0xFF0A0E1A),        // Dark surface
    background: Color(0xFF000000),     // Black
    error: Color(0xFFFF0000),          // Red
  ),
  fontFamily: 'JetBrains Mono',  // Override Material fonts
  useMaterial3: true,
);

// Disable Material ripples globally for calendar
splashFactory: NoSplash.splashFactory,
```

### Component Overrides
- **SegmentedButton:** Custom painter for borders + glow
- **GridView:** Custom decoration, no Material card
- **FilterChip:** Custom container, not Material chip
- **DraggableScrollableSheet:** Pure black background, cyan header

## Gradient Backgrounds (Dashboard Match)

Calendar background must match dashboard:

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFF020408),  // Deep black
        Color(0xFF050a12),
        Color(0xFF08101a),
        Color(0xFF040810),
      ],
      stops: [0.0, 0.3, 0.6, 1.0],
    ),
  ),
);
```

## Touch Targets (48dp Minimum)

Material accessibility guidelines still apply:

```dart
// Minimum touch target: 48dp × 48dp
// Styled as bordered boxes (not Material buttons)
Container(
  height: 48,
  width: 48,
  decoration: BoxDecoration(
    color: Color(0xFF0A0E1A),
    border: Border.all(color: Color(0x4000FFFF)),
    borderRadius: BorderRadius.circular(4),
  ),
);
```

## Critical Success Checklist

- ✅ All text = JetBrains Mono
- ✅ Background = Pure black (#000000)
- ✅ Primary color = Cyan (#00FFFF)
- ✅ Accent color = Green (#39FF14)
- ✅ Borders = 1px cyan/green at 25% opacity
- ✅ Glow effects = Selective (active cells only), 30% opacity
- ✅ Scanlines = 2-3px spacing, 5% opacity
- ✅ Film grain = SVG texture, 3% opacity
- ✅ Animations = Smooth (200ms), no ripples
- ✅ Matches dashboard styling exactly

## Reference Hex Values (Copy-Paste Ready)

```
Neon Cyan:      #00FFFF
Neon Green:     #39FF14
Pure Black:     #000000
Dark Surface:   #0A0E1A
Deep Black:     #020408
Status Red:     #FF0000
Status Orange:  #FF6600
Text White:     #FFFFFF
Text Gray:      #A0A0A0
Text Dim:       #606060
```

## Testing Checklist

- [ ] View on real Android device (Pixel 4a)
- [ ] Compare side-by-side with Dashboard tab
- [ ] Check glow intensity (should be subtle, not overpowering)
- [ ] Verify scanlines visible but not intrusive
- [ ] Confirm all text uses JetBrains Mono
- [ ] Test tap animations (smooth glow, no ripple)
- [ ] Validate color consistency across tabs
- [ ] Check landscape/tablet responsiveness
