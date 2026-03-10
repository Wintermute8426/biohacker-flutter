# Calendar Implementation Notes - Wintermute Theme Integration

**Critical:** This document outlines where Material Design 3 conflicts with the Wintermute cyberpunk aesthetic and how to override defaults.

## Material Design 3 Conflicts

### 1. Color Scheme Mismatch

**Material Default:**
- Light color schemes (whites, light grays, pastels)
- Soft shadows and elevation
- Blue/teal accent colors

**Wintermute Override:**
```dart
// ThemeData override in main.dart or calendar widget
ThemeData(
  useMaterial3: true,  // Keep M3 widgets but override colors
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Color(0xFF000000),  // Pure black
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF00FFFF),       // Neon cyan
    secondary: Color(0xFF39FF14),     // Neon green
    surface: Color(0xFF0A0E1A),       // Dark surface
    background: Color(0xFF000000),    // Pure black
    error: Color(0xFFFF0000),         // Red
    onPrimary: Color(0xFF000000),     // Black text on cyan
    onSecondary: Color(0xFF000000),   // Black text on green
    onSurface: Color(0xFFFFFFFF),     // White text on dark
    onBackground: Color(0xFFFFFFFF),  // White text on black
  ),
  fontFamily: 'JetBrains Mono',  // Override Material default fonts
  textTheme: TextTheme(
    // Override all text styles to use JetBrains Mono
    displayLarge: TextStyle(fontFamily: 'JetBrains Mono'),
    displayMedium: TextStyle(fontFamily: 'JetBrains Mono'),
    displaySmall: TextStyle(fontFamily: 'JetBrains Mono'),
    headlineLarge: TextStyle(fontFamily: 'JetBrains Mono'),
    headlineMedium: TextStyle(fontFamily: 'JetBrains Mono'),
    headlineSmall: TextStyle(fontFamily: 'JetBrains Mono'),
    titleLarge: TextStyle(fontFamily: 'JetBrains Mono'),
    titleMedium: TextStyle(fontFamily: 'JetBrains Mono'),
    titleSmall: TextStyle(fontFamily: 'JetBrains Mono'),
    bodyLarge: TextStyle(fontFamily: 'JetBrains Mono'),
    bodyMedium: TextStyle(fontFamily: 'JetBrains Mono'),
    bodySmall: TextStyle(fontFamily: 'JetBrains Mono'),
    labelLarge: TextStyle(fontFamily: 'JetBrains Mono'),
    labelMedium: TextStyle(fontFamily: 'JetBrains Mono'),
    labelSmall: TextStyle(fontFamily: 'JetBrains Mono'),
  ),
)
```

**Why:** Material Design 3 uses variable fonts (Roboto) and light color schemes by default. We need pure monospace (JetBrains Mono) and dark cyberpunk colors.

---

### 2. Ripple Effects

**Material Default:**
- Ripple animations on touch (InkWell, InkResponse)
- Splash colors (usually light blue or theme primary)

**Wintermute Override:**
```dart
// Disable ripples globally (in ThemeData)
splashFactory: NoSplash.splashFactory,

// OR disable per-widget
InkWell(
  splashColor: Colors.transparent,
  highlightColor: Colors.transparent,
  onTap: () {},
  child: /* ... */,
)

// BETTER: Replace InkWell with GestureDetector + AnimatedContainer
GestureDetector(
  onTap: () => setState(() => isSelected = !isSelected),
  child: AnimatedContainer(
    duration: Duration(milliseconds: 200),
    curve: Curves.easeOut,
    decoration: BoxDecoration(
      boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,
    ),
    child: /* ... */,
  ),
)
```

**Why:** Material ripples are jarring and don't fit the cyberpunk aesthetic. Smooth glow animations are more aligned with neon effects.

---

### 3. Elevation & Shadows

**Material Default:**
- Soft shadows (elevation 1-8)
- Material cards with subtle drop shadows

**Wintermute Override:**
```dart
// NO elevation on containers
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.primary.withOpacity(0.25)),
    // NO boxShadow here (unless neon glow)
  ),
)

// For "elevation" effect, use borders + glow instead
Container(
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.primary, width: 1),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.3),  // Neon glow
        blurRadius: 8,
        spreadRadius: 0,
      ),
    ],
  ),
)
```

**Why:** Soft Material shadows look out of place in cyberpunk UI. Borders + selective neon glow is more appropriate.

---

### 4. Typography (Serif Headers)

**Material Default:**
- Variable fonts (Roboto)
- Serif fonts for display text (Material Design 3)

**Wintermute Override:**
```dart
// Force JetBrains Mono everywhere
import 'package:google_fonts/google_fonts.dart';

// In main.dart MaterialApp theme
theme: ThemeData(
  fontFamily: 'JetBrains Mono',
  textTheme: GoogleFonts.jetBrainsMonoTextTheme(
    ThemeData.dark().textTheme,
  ),
)

// Or manually in pubspec.yaml
fonts:
  - family: JetBrains Mono
    fonts:
      - asset: assets/fonts/JetBrainsMono-Regular.ttf
      - asset: assets/fonts/JetBrainsMono-Bold.ttf
        weight: 700
```

**Why:** Material Design 3 uses variable fonts and serif display text. Wintermute requires monospace (JetBrains Mono) for the cyberpunk code aesthetic.

---

### 5. Spacing & Gaps

**Material Default:**
- 8dp grid system (8, 16, 24, 32 spacing)
- Light backgrounds between widgets

**Wintermute Override:**
```dart
// Keep 8dp grid but ensure black gaps
ListView.separated(
  separatorBuilder: (context, index) => Container(
    height: 8,
    color: AppColors.background,  // Explicit black gap
  ),
  itemBuilder: (context, index) => /* ... */,
)

// OR explicit black containers
Column(
  children: [
    Widget1(),
    Container(height: 16, color: AppColors.background),  // Black gap
    Widget2(),
  ],
)
```

**Why:** Material Design uses light gray or transparent gaps. We need explicit black to maintain the dark cyberpunk aesthetic.

---

## Custom Widget Replacements

### SegmentedButton → Custom Selector

**Before (Material):**
```dart
SegmentedButton<int>(
  segments: [
    ButtonSegment(value: 1, label: Text('Cycle 1')),
    ButtonSegment(value: 2, label: Text('Cycle 2')),
  ],
  selected: {selectedCycle},
  onSelectionChanged: (Set<int> newSelection) {
    setState(() => selectedCycle = newSelection.first);
  },
)
```

**After (Wintermute):**
```dart
Container(
  decoration: BoxDecoration(
    color: AppColors.background,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: WintermuteCalendar.borderCyan),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: cycles.map((cycle) => GestureDetector(
      onTap: () => setState(() => selectedCycle = cycle.id),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: WintermuteCalendar.filterChipDecoration(
          isSelected: selectedCycle == cycle.id,
        ),
        child: Text(
          cycle.name.toUpperCase(),
          style: WintermuteCalendar.filterChipStyle,
        ),
      ),
    )).toList(),
  ),
)
```

---

### GridView Cells → Custom Day Cells

**Before (Material):**
```dart
GridView.builder(
  itemBuilder: (context, index) => Card(
    elevation: 2,
    child: InkWell(
      onTap: () => selectDate(date),
      child: Center(child: Text('${date.day}')),
    ),
  ),
)
```

**After (Wintermute):**
```dart
GridView.builder(
  itemBuilder: (context, index) {
    final date = weekStart.add(Duration(days: index));
    final statusColor = WintermuteCalendar.getStatusColor(/* ... */);
    
    return GestureDetector(
      onTap: () => setState(() => selectedDate = date),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        decoration: WintermuteCalendar.dayCellWithDosesDecoration(
          statusColor: statusColor,
          isSelected: selectedDate == date,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${date.day}', style: WintermuteCalendar.dayNumberStyle),
            // Status indicator, etc.
          ],
        ),
      ),
    );
  },
)
```

---

## Performance Notes

### Neon Glow Effects (BoxShadow)

**Performance:** ✅ Lightweight  
**Why:** Modern Flutter renders box-shadow efficiently using GPU acceleration. Blurring is handled by the graphics pipeline.

**Optimization:**
- Only apply glow to **active/selected** cells (not all 7 day cells)
- Use `const` for static shadow definitions
- Avoid nested/multiple shadows (max 1-2 per widget)

```dart
// Good: Conditional glow
boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,

// Bad: Always-on glow everywhere
boxShadow: WintermuteCalendar.neonGlowCyan,  // Even when not selected
```

---

### Scanlines (CustomPainter)

**Performance:** ✅ Lightweight  
**Why:** Drawn once, cached by Flutter's repaint boundary system

**Optimization:**
```dart
class ScanlinesPainter extends CustomPainter {
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;  // Never repaint
}

// Wrap in RepaintBoundary to isolate
RepaintBoundary(
  child: CustomPaint(
    painter: ScanlinesPainter(),
  ),
)
```

---

### Film Grain (SVG/CustomPainter)

**Performance:** ⚠️ Medium (use sparingly)  
**Why:** Random drawing can be expensive if done every frame

**Optimization:**
- Use `shouldRepaint: false` (draw once, cache)
- Seed random generator for consistency (no frame-to-frame changes)
- Apply only to **static containers** (calendar container, bottom sheet)
- Avoid on **scrolling widgets**

```dart
class FilmGrainPainter extends CustomPainter {
  final Random random = Random(42);  // Seeded for consistency
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;  // Never repaint
}
```

**Alternative:** Use a static PNG texture asset instead of CustomPainter:
```dart
Container(
  decoration: BoxDecoration(
    image: DecorationImage(
      image: AssetImage('assets/textures/film_grain.png'),
      repeat: ImageRepeat.repeat,
      opacity: 0.03,
    ),
  ),
)
```

---

## Testing on Real Device (Pixel 4a)

### Visual Consistency Checklist

1. **Side-by-side Tab Comparison**
   - Open Dashboard, then Calendar
   - Colors should match exactly (same cyan/green hex values)
   - Border thickness should be identical
   - Glow intensity should be consistent

2. **Scanlines Visibility**
   - Should be visible but not intrusive
   - Opacity ~5-7% (adjust if too faint or too strong)
   - Spacing 2-3px (adjust based on screen DPI)

3. **Glow Intensity**
   - Should be subtle, not overpowering
   - Opacity ~30% (adjust if too bright)
   - Blur radius 8px (adjust based on screen size)

4. **Font Rendering**
   - JetBrains Mono should be crisp (not blurry)
   - Check letter-spacing (should be readable, not cramped)
   - Verify all text is monospace (no Roboto fallbacks)

5. **Touch Feedback**
   - Tap should trigger smooth glow animation (not ripple)
   - Duration 200ms (should feel responsive, not laggy)
   - No jarring flashes or abrupt transitions

6. **Black Levels**
   - Background should be pure black (#000000)
   - No light gray "Material gaps" between widgets
   - Verify AMOLED-friendly (true black, not dark gray)

### ADB Commands for Testing

```bash
# Take screenshot for comparison
adb exec-out screencap -p > calendar_screenshot.png

# Record video of animations
adb shell screenrecord /sdcard/calendar_test.mp4
adb pull /sdcard/calendar_test.mp4

# Check frame rate (verify smooth 60fps)
adb shell dumpsys gfxinfo com.biohacker.app | grep -A 120 "Frame"

# Monitor CPU/GPU usage (ensure glow effects aren't expensive)
adb shell top -m 10
```

---

## Common Pitfalls & Solutions

### Pitfall 1: Material Colors Leaking Through

**Problem:** FilterChip shows blue selection despite custom theme

**Solution:**
```dart
// Don't use Material FilterChip
// Use custom Container instead (see CALENDAR_COMPONENT_STYLES.md)
```

---

### Pitfall 2: Ripple Still Showing

**Problem:** InkWell ripple appears despite `splashColor: Colors.transparent`

**Solution:**
```dart
// Replace InkWell entirely
// Use GestureDetector + AnimatedContainer
GestureDetector(
  onTap: () {},
  child: AnimatedContainer(/* ... */),
)
```

---

### Pitfall 3: Font Not Monospace

**Problem:** Text renders in Roboto (Material default) instead of JetBrains Mono

**Solution:**
```dart
// Ensure font is in pubspec.yaml
fonts:
  - family: JetBrains Mono
    fonts:
      - asset: assets/fonts/JetBrainsMono-Regular.ttf
      - asset: assets/fonts/JetBrainsMono-Bold.ttf
        weight: 700

// Verify font is loaded
flutter clean
flutter pub get
flutter run

// Force font in every Text widget
Text('...', style: TextStyle(fontFamily: 'JetBrains Mono'))

// OR set global theme
theme: ThemeData(fontFamily: 'JetBrains Mono')
```

---

### Pitfall 4: Glow Too Bright/Dim

**Problem:** Neon glow looks washed out or invisible

**Solution:**
```dart
// Adjust opacity and blur radius
BoxShadow(
  color: Color(0xFF00FFFF).withOpacity(0.3),  // 30% (try 0.2-0.5)
  blurRadius: 8,  // 8px (try 6-12)
  spreadRadius: 0,  // Keep at 0
)

// Test on real device (emulator glow looks different)
```

---

### Pitfall 5: Scanlines Invisible or Too Strong

**Problem:** Scanlines too faint (can't see) or too dark (annoying)

**Solution:**
```dart
// Adjust opacity and spacing
final paint = Paint()
  ..color = Colors.black.withOpacity(0.05)  // 5% (try 0.03-0.08)
  ..strokeWidth = 1.0;

// Spacing: 2-3px (smaller spacing = more lines)
for (double y = 0; y < size.height; y += 2.5) {  // Try 2.0-4.0
  canvas.drawLine(/* ... */);
}
```

---

## Integration with Existing Screens

### Color Palette Consistency

**Verify:** Calendar uses same hex values as Dashboard, Protocols, etc.

```dart
// Extract shared colors to lib/theme/colors.dart
class AppColors {
  static const Color primary = Color(0xFF00FFFF);   // Cyan
  static const Color accent = Color(0xFF39FF14);    // Green
  static const Color background = Color(0xFF000000); // Black
  static const Color surface = Color(0xFF0A0E1A);   // Dark surface
  // ...
}

// Import in calendar_screen.dart
import '../theme/colors.dart';
```

---

### Border Thickness Match

**Verify:** Calendar borders = 1px (same as Dashboard cards)

```dart
// Dashboard card border
border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1)

// Calendar day cell border (should match)
border: Border.all(color: WintermuteCalendar.borderCyan, width: 1)

// Both should be 1px thick
```

---

### Glow Intensity Match

**Verify:** Calendar glow = same opacity/blur as Dashboard hover effects

```dart
// Dashboard hover glow (if any)
boxShadow: [
  BoxShadow(
    color: AppColors.primary.withOpacity(0.3),
    blurRadius: 8,
  ),
]

// Calendar selected cell glow (should match)
boxShadow: WintermuteCalendar.neonGlowCyan  // Same values
```

---

## Build Integration Notes

**Build #280 Requirements:**
1. Calendar tab added to main tab navigation
2. Theme constants imported from `wintermute_calendar.dart`
3. All Material widgets replaced with custom components
4. JetBrains Mono font loaded and verified
5. Scanlines + film grain overlays applied
6. Neon glow animations working smoothly
7. Side-by-side comparison with Dashboard (visual match)
8. Real device testing on Pixel 4a (screenshots saved)

**Blocking Issues:**
- [ ] Font not loading → Check `pubspec.yaml` + `flutter clean`
- [ ] Ripples still showing → Replace `InkWell` with `GestureDetector`
- [ ] Colors wrong → Verify hex values in `wintermute_calendar.dart`
- [ ] Glow not visible → Test on real device, adjust opacity
- [ ] Scanlines too strong → Reduce opacity to 0.03-0.05

---

## Final Validation

**Before merging to main:**
1. ✅ All text = JetBrains Mono (no Roboto)
2. ✅ Background = Pure black (#000000)
3. ✅ Borders = 1px cyan/green (same as Dashboard)
4. ✅ Glow = Selective (active cells only), 30% opacity
5. ✅ Animations = Smooth (200ms), no ripples
6. ✅ Scanlines visible but subtle (5% opacity)
7. ✅ Calendar matches Dashboard aesthetic
8. ✅ Tested on Pixel 4a (visual consistency confirmed)

**Screenshots required:**
- Calendar tab (full screen)
- Day cell selected (showing glow)
- Bottom sheet open (showing scanlines)
- Side-by-side Dashboard + Calendar (color match)
