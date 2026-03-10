# Calendar Theme Manifest - Build #280

**Status:** ✅ Complete  
**Task:** Ensure calendar redesign maintains Wintermute cyberpunk aesthetic  
**Timeline:** ~30 min implementation (theme layer, not new features)  
**Blocking:** Build #280 implementation

---

## 📦 Deliverables (All Created)

### 1. WINTERMUTE_CALENDAR_THEME.md
**Location:** `docs/WINTERMUTE_CALENDAR_THEME.md`  
**Content:** Complete theme specification with:
- ✅ Exact color hex values (cyan, green, black, status colors)
- ✅ Typography rules (JetBrains Mono, all variants)
- ✅ Effect specifications (scanlines opacity, film grain, glow intensity)
- ✅ Animation timing (200ms smooth, no ripples)
- ✅ Material Design 3 overrides (ThemeData, color scheme)
- ✅ Testing checklist (visual consistency, performance)

**Key Reference Values:**
```
Primary Cyan:    #00FFFF
Neon Green:      #39FF14
Pure Black:      #000000
Dark Surface:    #0A0E1A
Status Red:      #FF0000
Status Orange:   #FF6600
Text White:      #FFFFFF
Text Gray:       #A0A0A0
```

---

### 2. CYBERPUNK_COLOR_PALETTE.dart
**Location:** `lib/theme/wintermute_calendar.dart`  
**Content:** Reusable theme constants with:
- ✅ Color definitions (status, border, glow)
- ✅ Text style constants (week header, date range, day number, etc.)
- ✅ BoxDecoration helpers (day cells, filter chips, bottom sheet)
- ✅ Effect painters (scanlines, film grain)
- ✅ Animation durations & curves
- ✅ Helper methods (status color calculation, labels)

**Usage:**
```dart
import '../theme/wintermute_calendar.dart';

// Status colors auto-calculated
final color = WintermuteCalendar.getStatusColor(
  scheduledDoses: 2,
  loggedDoses: 1,
  date: date,
);

// Decorations ready to use
decoration: WintermuteCalendar.dayCellWithDosesDecoration(
  statusColor: color,
  isSelected: true,
)

// Text styles pre-configured
Text('MON', style: WintermuteCalendar.weekHeaderStyle)

// Effects
boxShadow: WintermuteCalendar.neonGlowCyan
```

---

### 3. CALENDAR_COMPONENT_STYLES.md
**Location:** `docs/CALENDAR_COMPONENT_STYLES.md`  
**Content:** Component-by-component styling guide with:
- ✅ SegmentedButton → Custom Container replacement (full code)
- ✅ GridView → Day cell grid with status indicators (full code)
- ✅ DraggableScrollableSheet → Bottom sheet styling (full code)
- ✅ FilterChip → Cycle selector with glow (full code)
- ✅ Week header (MON TUE WED...) styling
- ✅ Date range header (MAR 10-16, 2026) styling
- ✅ Touch feedback animations (no ripples)
- ✅ Material widget avoidance list
- ✅ Quick reference patterns

**Key Patterns:**
```dart
// AnimatedContainer pattern (instead of InkWell)
AnimatedContainer(
  duration: WintermuteCalendar.tapAnimationDuration,
  decoration: BoxDecoration(
    boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,
  ),
)

// Status-based styling
WintermuteCalendar.dayCellWithDosesDecoration(
  statusColor: statusColor,
  isSelected: isSelected,
)
```

---

### 4. IMPLEMENTATION_NOTES.md
**Location:** `docs/IMPLEMENTATION_NOTES.md`  
**Content:** Integration warnings and Material conflicts:
- ✅ Color scheme mismatch (Material light → Wintermute dark)
- ✅ Ripple effects (Material → glow animations)
- ✅ Elevation & shadows (Material cards → borders + glow)
- ✅ Typography (Material Roboto → JetBrains Mono)
- ✅ Spacing (Material light gaps → pure black)
- ✅ Custom widget replacements with before/after code
- ✅ Performance notes (BoxShadow ✅ fast, CustomPainter ⚠️ medium)
- ✅ Real device testing (ADB commands, checklist)
- ✅ Common pitfalls & solutions
- ✅ Build #280 integration requirements

**Critical Override:**
```dart
ThemeData(
  scaffoldBackgroundColor: Color(0xFF000000),
  colorScheme: ColorScheme.dark(
    primary: Color(0xFF00FFFF),       // Cyan
    secondary: Color(0xFF39FF14),     // Green
    surface: Color(0xFF0A0E1A),
    background: Color(0xFF000000),
    error: Color(0xFFFF0000),
  ),
  fontFamily: 'JetBrains Mono',
  splashFactory: NoSplash.splashFactory,  // Disable ripples
)
```

---

### 5. CALENDAR_QUICKSTART.md
**Location:** `docs/CALENDAR_QUICKSTART.md`  
**Content:** Quick-start guide for developers:
- ✅ TL;DR (5 key steps)
- ✅ Step-by-step implementation instructions
- ✅ Widget replacement examples (SegmentedButton, Card, InkWell)
- ✅ Typography quick reference
- ✅ Color palette (status colors, borders, glow)
- ✅ Effects (scanlines, film grain)
- ✅ Day cell template (ready to copy-paste)
- ✅ Bottom sheet template (ready to copy-paste)
- ✅ Common mistakes & how to avoid them
- ✅ Testing checklist
- ✅ Help section (FAQ)

**Copy-Paste Ready:**
```dart
// Day cell template
GestureDetector(
  onTap: () => setState(() => selectedDate = date),
  child: AnimatedContainer(
    duration: WintermuteCalendar.tapAnimationDuration,
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
        Text('${date.day}', style: WintermuteCalendar.dayNumberStyle),
        // Status indicator
      ],
    ),
  ),
)
```

---

## 🎨 Existing Theme Files (Reference)

### colors.dart
Already has base cyberpunk palette:
```dart
static const Color primary = Color(0xFF00FFFF);        // Cyan
static const Color accent = Color(0xFF39FF14);         // Green
static const Color background = Color(0xFF000000);     // Black
static const Color surface = Color(0xFF0A0E1A);        // Dark surface
```
✅ Calendar theme extends these values.

### wintermute_styles.dart
Already has text style patterns:
```dart
static const TextStyle titleStyle = ...    // 22px, bold, cyan, mono
static const TextStyle headerStyle = ...   // 18px, bold, cyan, mono
static const TextStyle bodyStyle = ...     // 14px, regular, white, mono
```
✅ Calendar extends with additional styles (dayNumberStyle, doseCountStyle, etc.).

### wintermute_background.dart
Already has scanlines & gradient:
```dart
// Gradient background (deep, clean)
// Scanlines overlay (crisp CRT effect, 2px spacing)
```
✅ Calendar reuses same gradient + scanlines pattern.

### wintermute_calendar.dart (NEW)
Calendar-specific theme constants:
```dart
// Status colors
// Glow definitions
// Calendar text styles
// Component decorations
// Helper methods
```
✅ Imported in calendar_screen.dart.

---

## 🚀 Integration Checklist

### Pre-Implementation
- [ ] Read `CALENDAR_QUICKSTART.md` (5 min)
- [ ] Review `wintermute_calendar.dart` constants (5 min)
- [ ] Understand Material → Wintermute widget replacements (5 min)

### Implementation
- [ ] Replace SegmentedButton with custom container
- [ ] Replace GridView cards with custom decorations
- [ ] Replace InkWell with GestureDetector + AnimatedContainer
- [ ] Apply WintermuteCalendar text styles to all text
- [ ] Add scanlines overlay to calendar container
- [ ] Add film grain overlay (optional, performance-dependent)
- [ ] Implement day cell template
- [ ] Implement bottom sheet styling
- [ ] Test on emulator (quick check)

### Testing & Validation
- [ ] Test on real device (Pixel 4a required)
- [ ] Side-by-side comparison with Dashboard tab
- [ ] Visual consistency check (colors, borders, glow, scanlines)
- [ ] Touch feedback check (smooth animations, no ripples)
- [ ] Performance check (60fps, smooth scrolling)
- [ ] Font check (all text = JetBrains Mono)
- [ ] Screenshot comparison (save to `docs/screenshots/`)

### Code Quality
- [ ] No Material ripples remaining
- [ ] No InkWell widgets
- [ ] No light gray/white backgrounds
- [ ] All text uses JetBrains Mono
- [ ] Consistent border thickness (1px)
- [ ] Consistent glow values (30% opacity, 8px blur)
- [ ] Scanlines opacity correct (5% visible but subtle)

---

## 📋 Critical Success Criteria

```
✅ Calendar looks like it belongs in the Wintermute app (not generic Material Design)
✅ All text uses JetBrains Mono (monospace font)
✅ Color palette is consistent across all tabs (same cyan/green values)
✅ Neon glow effects are subtle but visible (not overdone)
✅ Scanlines and grain are present but not intrusive (opacity <0.1)
✅ Touch feedback is glow (not ripple), animations are smooth
✅ Black background everywhere (no Material light colors)
✅ Tested on real Android device (Pixel 4a, visual consistency verified)
```

---

## 🎯 File Structure

```
biohacker-flutter/
├── lib/
│   └── theme/
│       ├── colors.dart                    (existing, unchanged)
│       ├── wintermute_styles.dart         (existing, unchanged)
│       ├── wintermute_background.dart     (existing, unchanged)
│       └── wintermute_calendar.dart       (NEW - theme constants)
│
├── screens/
│   └── calendar_screen.dart               (TO IMPLEMENT - uses new theme)
│
└── docs/
    ├── WINTERMUTE_CALENDAR_THEME.md       (NEW - full spec)
    ├── CALENDAR_COMPONENT_STYLES.md       (NEW - component guide)
    ├── IMPLEMENTATION_NOTES.md            (NEW - integration warnings)
    ├── CALENDAR_QUICKSTART.md             (NEW - quick start)
    └── CALENDAR_THEME_MANIFEST.md         (THIS FILE)
```

---

## 🔗 Document Cross-References

### For Quick Overview
1. Start: **CALENDAR_QUICKSTART.md** (5-10 min read)
2. Then: **WINTERMUTE_CALENDAR_THEME.md** (full spec, 15 min reference)

### For Component Implementation
1. **CALENDAR_COMPONENT_STYLES.md** (copy-paste code examples)
2. **wintermute_calendar.dart** (constants and decorations)

### For Troubleshooting
1. **IMPLEMENTATION_NOTES.md** (Material conflicts, pitfalls, solutions)
2. **CALENDAR_QUICKSTART.md** (FAQ, common mistakes)

### For Testing
1. **WINTERMUTE_CALENDAR_THEME.md** (Testing Checklist section)
2. **IMPLEMENTATION_NOTES.md** (Device testing & validation)

---

## 🎬 Implementation Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| **Setup** | 15 min | Import theme, understand constants |
| **Components** | 60 min | Week grid, day cells, bottom sheet |
| **Styling** | 30 min | Colors, borders, glow, scanlines |
| **Testing** | 30 min | Emulator + real device validation |
| **Polish** | 15 min | Screenshot comparison, edge cases |
| **TOTAL** | **2.5 hours** | Production-ready calendar theme |

---

## ⚠️ Known Material Design 3 Issues

### Issue: Colors don't match
→ See `IMPLEMENTATION_NOTES.md` → "Color Scheme Mismatch"  
→ Override ThemeData colorScheme with Wintermute palette

### Issue: Ripples still showing
→ See `IMPLEMENTATION_NOTES.md` → "Ripple Effects"  
→ Replace InkWell with GestureDetector + AnimatedContainer

### Issue: Font renders as Roboto
→ See `IMPLEMENTATION_NOTES.md` → "Typography"  
→ Force JetBrains Mono in ThemeData.fontFamily

### Issue: Glow doesn't look right on device
→ See `IMPLEMENTATION_NOTES.md` → "Performance Notes"  
→ Adjust opacity (0.2-0.5) and blur radius (6-12px) based on screen

---

## 📞 Support References

**Theme Constants:** `lib/theme/wintermute_calendar.dart`  
**Full Theme Spec:** `docs/WINTERMUTE_CALENDAR_THEME.md`  
**Quick Start:** `docs/CALENDAR_QUICKSTART.md`  
**Component Styles:** `docs/CALENDAR_COMPONENT_STYLES.md`  
**Integration Help:** `docs/IMPLEMENTATION_NOTES.md`

---

## 🎯 Sign-Off for Build #280

**Theme Review Status:** ✅ **APPROVED**

**Deliverables Complete:**
- ✅ WINTERMUTE_CALENDAR_THEME.md (theme specification)
- ✅ wintermute_calendar.dart (color constants, text styles, decorations)
- ✅ CALENDAR_COMPONENT_STYLES.md (component styling guide)
- ✅ IMPLEMENTATION_NOTES.md (integration warnings)
- ✅ CALENDAR_QUICKSTART.md (quick-start guide)

**Ready for Developer Implementation:**
- ✅ All files created and documented
- ✅ Code examples provided (copy-paste ready)
- ✅ Theme constants reusable across app
- ✅ Material conflicts identified with solutions
- ✅ Testing requirements specified
- ✅ Performance notes included

**No Blockers:** Implementation can start immediately.

**Estimated Build #280 Impact:**
- Theme layer: Ready (no code changes needed)
- Integration: 2-3 hours (Material widget replacement + styling)
- Testing: 30-45 min (device validation)
- **Total:** ~3.5 hours to production

---

**Created:** March 10, 2026  
**Last Updated:** March 10, 2026  
**Status:** Ready for implementation  
**Next Step:** Developer picks up calendar_screen.dart implementation
