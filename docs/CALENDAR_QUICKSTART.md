# Calendar Wintermute Theme - Quick Start

**For developers implementing Build #280 calendar redesign**

## TL;DR

1. Import `wintermute_calendar.dart` theme constants
2. Replace all Material widgets with custom components
3. Use JetBrains Mono for all text
4. Apply scanlines + film grain overlays
5. Test on real device (Pixel 4a)

---

## Step 1: Import Theme Constants

```dart
// In calendar_screen.dart
import '../theme/colors.dart';
import '../theme/wintermute_calendar.dart';
import '../theme/wintermute_styles.dart';
```

---

## Step 2: Widget Replacements

### SegmentedButton → Custom Container
```dart
// ❌ DON'T
SegmentedButton<int>(segments: [...])

// ✅ DO
Container(
  decoration: BoxDecoration(
    border: Border.all(color: WintermuteCalendar.borderCyan),
  ),
  child: Row(
    children: cycles.map((cycle) => GestureDetector(
      onTap: () => selectCycle(cycle.id),
      child: AnimatedContainer(
        duration: WintermuteCalendar.tapAnimationDuration,
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

### Card → Custom Container
```dart
// ❌ DON'T
Card(elevation: 2, child: ...)

// ✅ DO
Container(
  decoration: WintermuteCalendar.dayCellDecoration(),
  child: ...
)
```

### InkWell → GestureDetector + AnimatedContainer
```dart
// ❌ DON'T
InkWell(onTap: () {}, child: ...)

// ✅ DO
GestureDetector(
  onTap: () => setState(() => isSelected = !isSelected),
  child: AnimatedContainer(
    duration: WintermuteCalendar.tapAnimationDuration,
    decoration: BoxDecoration(
      boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,
    ),
    child: ...
  ),
)
```

---

## Step 3: Typography (JetBrains Mono Everywhere)

```dart
// ❌ DON'T
Text('MON TUE WED', style: TextStyle(fontSize: 12))

// ✅ DO
Text('MON TUE WED', style: WintermuteCalendar.weekHeaderStyle)

// All text styles available:
// - WintermuteCalendar.weekHeaderStyle (MON TUE WED)
// - WintermuteCalendar.dateRangeStyle (MAR 10-16, 2026)
// - WintermuteCalendar.dayNumberStyle (day number in cell)
// - WintermuteCalendar.doseCountStyle (dose count indicator)
// - WintermuteCalendar.sheetTitleStyle (bottom sheet title)
// - WintermuteCalendar.filterChipStyle (cycle filter text)
```

---

## Step 4: Color Palette

```dart
// Status colors (auto-calculated)
final statusColor = WintermuteCalendar.getStatusColor(
  scheduledDoses: 2,
  loggedDoses: 2,
  date: DateTime.now(),
);
// Returns: statusOnTrack (green), statusPending (cyan), 
//          statusMissed (red), or statusOverdue (orange)

// Manual colors
WintermuteCalendar.statusOnTrack   // #39FF14 (green)
WintermuteCalendar.statusPending   // #00FFFF (cyan)
WintermuteCalendar.statusMissed    // #FF0000 (red)
WintermuteCalendar.statusOverdue   // #FF6600 (orange)

// Borders
WintermuteCalendar.borderCyan      // Cyan at 25% opacity
WintermuteCalendar.borderGreen     // Green at 25% opacity
WintermuteCalendar.borderRed       // Red at 25% opacity

// Glow (use sparingly - only on selected/active cells)
WintermuteCalendar.neonGlowCyan    // Cyan glow (30% opacity)
WintermuteCalendar.neonGlowGreen   // Green glow (30% opacity)
WintermuteCalendar.neonGlowRed     // Red glow (30% opacity)
```

---

## Step 5: Effects (Scanlines + Film Grain)

### Scanlines Overlay
```dart
// Wrap calendar container with scanlines
import '../theme/wintermute_styles.dart';

ScanlinesOverlay(
  opacity: 0.05,      // Subtle (3-7% recommended)
  lineSpacing: 3.0,   // 2-3px spacing
  child: Container(
    // ... calendar grid
  ),
)
```

### Film Grain (Optional)
```dart
// Wrap main container
FilmGrainOverlay(
  opacity: 0.03,  // Very subtle
  child: Container(
    // ... calendar content
  ),
)
```

---

## Step 6: Day Cell Template

```dart
GestureDetector(
  onTap: () => setState(() => selectedDate = date),
  child: AnimatedContainer(
    duration: WintermuteCalendar.tapAnimationDuration,
    curve: WintermuteCalendar.animationCurve,
    decoration: WintermuteCalendar.dayCellWithDosesDecoration(
      statusColor: WintermuteCalendar.getStatusColor(
        scheduledDoses: _getScheduledCount(date),
        loggedDoses: _getLoggedCount(date),
        date: date,
      ),
      isSelected: selectedDate == date,
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Day number
        Text(
          '${date.day}',
          style: WintermuteCalendar.dayNumberStyle,
        ),
        SizedBox(height: 4),
        // Dose count indicator
        if (_getScheduledCount(date) > 0)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: WintermuteCalendar.statusChipDecoration(statusColor),
            child: Text(
              '${_getLoggedCount(date)}/${_getScheduledCount(date)}',
              style: WintermuteCalendar.doseCountStyle.copyWith(
                color: statusColor,
                fontSize: 9,
              ),
            ),
          ),
      ],
    ),
  ),
)
```

---

## Step 7: Bottom Sheet Template

```dart
DraggableScrollableSheet(
  initialChildSize: 0.4,
  minChildSize: 0.2,
  maxChildSize: 0.9,
  builder: (context, scrollController) {
    return Container(
      decoration: WintermuteCalendar.bottomSheetDecoration(),
      child: Stack(
        children: [
          // Main content
          ListView(
            controller: scrollController,
            padding: EdgeInsets.all(16),
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Title
              Text(
                _formatDate(selectedDate!),
                style: WintermuteCalendar.sheetTitleStyle,
              ),
              
              // ... dose list
            ],
          ),
          
          // Scanlines overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanlinesPainter(opacity: 0.05),
              ),
            ),
          ),
        ],
      ),
    );
  },
)
```

---

## Common Mistakes to Avoid

### ❌ Using Material Widgets
```dart
// DON'T use these:
SegmentedButton()
FilterChip()
Card()
InkWell()
ElevatedButton()
TextButton()
```

### ❌ Forgetting to Uppercase Text
```dart
// DON'T
Text('Cycle 1')

// DO
Text('CYCLE 1')  // or cycleName.toUpperCase()
```

### ❌ Using Wrong Font
```dart
// DON'T
Text('...', style: TextStyle(fontSize: 14))  // Uses Material default

// DO
Text('...', style: WintermuteCalendar.dayNumberStyle)  // Uses JetBrains Mono
```

### ❌ Applying Glow Everywhere
```dart
// DON'T (expensive, looks overdone)
boxShadow: WintermuteCalendar.neonGlowCyan  // Always on

// DO (selective, only when active)
boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null
```

---

## Testing Checklist

### Visual Consistency
- [ ] Compare Calendar tab with Dashboard tab (colors match)
- [ ] All text is JetBrains Mono (no Roboto)
- [ ] Background is pure black (#000000)
- [ ] Borders are 1px cyan/green (same thickness as Dashboard)
- [ ] Glow is subtle (not overpowering)
- [ ] Scanlines visible but not intrusive

### Functionality
- [ ] Tap day cell → smooth glow animation (no ripple)
- [ ] Select cycle filter → smooth border + glow transition
- [ ] Bottom sheet opens → black background, cyan header
- [ ] Status colors correct (green=on-track, cyan=pending, red=missed)
- [ ] Dose count indicators show correct numbers

### Performance
- [ ] Scroll is smooth (60fps)
- [ ] Animations are smooth (200ms duration)
- [ ] No janky transitions
- [ ] Glow effects render quickly

### Device Testing
- [ ] Test on Pixel 4a (real device, not emulator)
- [ ] Take screenshots (save to `docs/screenshots/`)
- [ ] Compare side-by-side with Dashboard
- [ ] Verify scanlines visible on real screen

---

## Quick Reference Links

- **Full Theme Spec:** `WINTERMUTE_CALENDAR_THEME.md`
- **Component Examples:** `CALENDAR_COMPONENT_STYLES.md`
- **Implementation Warnings:** `IMPLEMENTATION_NOTES.md`
- **Theme Constants:** `lib/theme/wintermute_calendar.dart`

---

## Need Help?

### Colors wrong?
→ Check `wintermute_calendar.dart` for correct hex values

### Font not monospace?
→ Verify `pubspec.yaml` has JetBrains Mono font
→ Run `flutter clean && flutter pub get`

### Ripple still showing?
→ Replace `InkWell` with `GestureDetector` + `AnimatedContainer`

### Glow not visible?
→ Test on real device (emulator glow looks different)
→ Adjust opacity to 0.3-0.5

### Scanlines invisible?
→ Increase opacity to 0.05-0.08
→ Reduce line spacing to 2.0-2.5px

---

**Build #280 Status:** Ready for implementation  
**Estimated Time:** 2-3 hours (Material widget replacements + styling)  
**Blocking:** None (all theme files ready)
