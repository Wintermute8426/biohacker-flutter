# PHASE 9: Wintermute Dashboard Style Refresh

## Overview
Complete aesthetic overhaul of the Biohacker Flutter app using the Wintermute cyberpunk design system. This phase applies visual polish to the fully functional Phase 8 interface (7 Reports tabs + 4 Labs tabs).

**Scope:** UI styling only. No functionality changes.  
**Timeline:** 2-3 hours  
**Testing:** All 11 tabs remain functional after styling applied.

---

## Color Palette

### Primary Colors (Wintermute Cyberpunk)
- **Cyan (Primary):** `#00FFFF` — Neon cyan, used for titles, active elements, glow accents
- **Green (Accent):** `#39FF14` — Neon green, secondary highlights, progress indicators
- **Black (Background):** `#060810` — Deep black, main background
- **Dark Surface:** `#0A0E1A` — Slightly lighter black for cards/containers

### Supporting Colors
- **Text Light:** `#E0E0E0` — Light gray for body text
- **Text Mid:** `#A8A8A8` — Medium gray for secondary text
- **Text Dim:** `#666666` — Dim gray for tertiary/disabled text
- **Magenta (Secondary):** `#FF00FF` — Magenta for accent alerts/warnings
- **Error:** `#FF1744` — Bright red for errors

### Glow Colors
- **Cyan Glow:** `#00FFFF with 20-40% opacity`
- **Green Glow:** `#39FF14 with 20-40% opacity`
- **Magenta Glow:** `#FF00FF with 20-40% opacity`

---

## Typography

### Font Family
- **Primary Font:** `JetBrains Mono` (monospaced, cyberpunk aesthetic)
  - Fallback: `Courier New`
  - Add to `pubspec.yaml`:
    ```yaml
    dependencies:
      google_fonts: ^6.0.0
    ```

### Font Sizes & Weights
- **Page Titles:** 22px, JetBrains Mono, bold, letter-spacing: 2px
- **Section Headers:** 18px, JetBrains Mono, bold, letter-spacing: 1px
- **Subheaders:** 14px, JetBrains Mono, regular, letter-spacing: 0.5px
- **Body Text:** 14px, JetBrains Mono, regular
- **Small Text:** 12px, JetBrains Mono, regular
- **Tiny Text:** 10px, JetBrains Mono, regular

### Text Styling
- **Tab Labels:** Cyan, JetBrains Mono, all-caps (1, 2, 3, etc.)
- **Chart Labels:** Cyan for active, dim-gray for inactive
- **Stat Values:** Cyan for primary, Green for accent, Magenta for secondary
- **Glowing Text (optional):** Apply text shadow with glow effect to important numbers

---

## Visual Effects

### Glow Effects
**Applied to:**
- Title text (cyan glow)
- Active tab indicator (cyan glow)
- Chart lines (subtle color glow matching line color)
- Stat value text (color-matched glow)
- Section headers (cyan glow)

**Implementation:**
```dart
BoxShadow(
  color: AppColors.primary.withOpacity(0.4),  // Cyan
  blurRadius: 8,
  spreadRadius: 2,
)
```

Or for text:
```dart
TextStyle(
  shadows: [
    Shadow(
      color: AppColors.primary.withOpacity(0.5),
      blurRadius: 8,
      offset: Offset(0, 0),
    ),
  ],
)
```

### Border Styling
- **Container Borders:** 1px solid, color-matched (cyan for primary, green for accent)
- **Border Opacity:** 30-50% opacity for subtle presence
- **Border Radius:** 4-8px for cards, charts; 0px for titles

### Scanline Overlay
**Effect:** Subtle horizontal lines overlay (like old CRT monitors)

**Implementation:**
```dart
// Add to AppBar/body Container
Stack(
  children: [
    // Content here
    Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/scanlines.png'), // or generated
              repeat: ImageRepeat.repeat,
            ),
          ),
        ),
      ),
    ),
  ],
)
```

**Alternative (procedural):** Generate via CustomPaint with horizontal lines every 2-3px, opacity 5-10%.

---

## Animations

### Entrance Animations
- **Page Load:** Fade-in (300ms) + slight scale (1.0 → 1.02)
- **Tab Switch:** Cross-fade (200ms) between TabBarView children
- **Cards:** Staggered entrance on list scroll (each card fades in 50ms apart)

### Pulse Effects
- **Active Tab Indicator:** Subtle pulse glow (1s loop, opacity 0.3 → 0.6 → 0.3)
- **Important Numbers:** Pulse on value change (brightness/glow increases 200ms)
- **Chart Points:** Subtle pulse on hover/interaction

### Hover States
- **Buttons/Tappables:** Opacity increase (0.8 → 1.0), glow increase
- **Cards:** Border glow increase on hover (web only, or long-press on mobile)

### Status LEDs (Decorative)
- **Dashboard Status Light:** Blinking pulse (400ms on, 100ms off), magenta glow
- **Data Sync Indicator:** Green pulse when syncing, solid when complete

---

## Component-Specific Styling

### AppBar
- **Background:** `#060810` (full black)
- **Title Color:** Cyan, JetBrains Mono, bold, 20px, letter-spacing: 2px
- **Title Glow:** Cyan shadow, blur 8px
- **TabBar Indicator:** Cyan, 3px height, full-width animated underline
- **Tab Text:** Cyan when active, dim-gray when inactive, ALL-CAPS

### Cards / Containers
- **Background:** `#0A0E1A` (dark surface)
- **Border:** 1px solid cyan with 30% opacity
- **Glow:** Subtle cyan shadow (blur 8px, spread 2px)
- **Corner Radius:** 4-8px
- **Padding:** 16px

### Charts (LineChart, BarChart)
- **Grid Lines:** Dim-gray (#666666), opacity 20%
- **Line Colors:** Cyan (primary), Green (secondary), Magenta (tertiary)
- **Area Fill Opacity:** 10-15% of line color
- **Axis Titles:** Dim-gray, 10px JetBrains Mono
- **Axis Values:** Dim-gray, 10px JetBrains Mono
- **Tooltip:** Dark background (#0A0E1A), cyan text, border 1px cyan

### Buttons / Tappables
- **Background:** Transparent or `#0A0E1A`
- **Border:** 1px solid cyan
- **Text:** Cyan, JetBrains Mono, all-caps
- **Hover:** Border glow + text glow increase, background opacity increase
- **Icon Color:** Cyan

### Empty States
- **Text:** `"NO DATA AVAILABLE"`, dim-gray, JetBrains Mono, all-caps, letter-spacing: 1px
- **Icon:** Dim-gray, 48px

### Section Headers
- **Title:** Cyan, 18px, JetBrains Mono, bold, letter-spacing: 1px
- **Subtitle:** Dim-gray, 12px, JetBrains Mono
- **Glow:** Subtle cyan shadow on title

---

## File Structure Changes

### 1. Update `AppColors` in `lib/theme/colors.dart`
- Add `jetbrainsMono` text style definitions
- Update all color hex values to Wintermute palette
- Add `glowShadow` / `primaryGlow` helper methods

### 2. Create `lib/theme/wintermute_styles.dart`
- Text style presets (title, header, body, small)
- Box decoration presets (card, chart, elevated)
- Shadow presets (glow, subtle, strong)

### 3. Assets (if using scanlines image)
- Add `assets/scanlines.png` (2px height, gray horizontal lines)
- Update `pubspec.yaml` with asset path

### 4. Update `pubspec.yaml`
```yaml
dependencies:
  google_fonts: ^6.0.0

assets:
  - assets/scanlines.png
```

---

## Implementation Checklist

### Phase 9A: Color & Typography (30 min)
- [ ] Update `AppColors` class with Wintermute palette
- [ ] Add JetBrains Mono font family (via google_fonts)
- [ ] Create text style helper methods in `wintermute_styles.dart`
- [ ] Test: All text renders in monospace, colors correct

### Phase 9B: AppBar & Tabs (30 min)
- [ ] Update AppBar styling (cyan title, glow)
- [ ] Update TabBar styling (cyan underline, glow)
- [ ] Update Tab text styling (uppercase, color-coded)
- [ ] Test: AppBar/tabs render with glow, colors match

### Phase 9C: Cards & Containers (30 min)
- [ ] Update all Container styling (dark background, cyan border glow)
- [ ] Update section headers (glow, color)
- [ ] Update empty state UI
- [ ] Test: Cards have glow, headers render correctly

### Phase 9D: Charts (30 min)
- [ ] Update LineChart styling (colors, grid, axes)
- [ ] Update BarChart styling (colors, axes)
- [ ] Update chart tooltips (dark bg, cyan border/text)
- [ ] Test: All charts render with correct colors, no artifacts

### Phase 9E: Animations & Effects (30 min)
- [ ] Add page fade-in on load (300ms)
- [ ] Add tab switch cross-fade (200ms)
- [ ] Add pulse animation to active tab indicator
- [ ] Add scanlines overlay (if using image or CustomPaint)
- [ ] Test: Animations smooth, no performance hits

### Phase 9F: Final Polish (30 min)
- [ ] Review all screens for visual consistency
- [ ] Test all 11 tabs for rendering issues
- [ ] Fix any glitches or misaligned text
- [ ] Commit: "Phase 9: Wintermute dashboard style refresh"

---

## Testing Checklist

### Visual Tests
- [ ] All text is monospaced (JetBrains Mono)
- [ ] Colors match Wintermute palette (cyan, green, black)
- [ ] Glow effects on text/borders visible (not too bright)
- [ ] Scanlines visible but not distracting
- [ ] Charts render correctly with new colors
- [ ] Empty states display properly

### Functional Tests
- [ ] All 7 Reports tabs work without crashes
- [ ] All 4 Labs tabs work without crashes
- [ ] Tab switching is smooth (no lag)
- [ ] Charts are interactive (tooltips work)
- [ ] Animations don't cause jank
- [ ] No text overflow or cutoff
- [ ] Colors work on both light & dark AMOLED screens

### Device Tests
- [ ] Test on Android 16 phone (primary)
- [ ] Test on multiple screen sizes (if possible)
- [ ] Verify text legibility at small sizes
- [ ] Check glow effects aren't too bright for eyes

---

## Success Criteria

✅ All 11 tabs (7 Reports + 4 Labs) functional and styled  
✅ Monospaced fonts throughout (JetBrains Mono)  
✅ Wintermute color palette applied (cyan, green, black)  
✅ Glow effects visible on titles, borders, active elements  
✅ No performance degradation (smooth animations)  
✅ Consistent aesthetic across all screens  
✅ Text legible and properly aligned  

---

## Estimated Timeline
- **Setup & Colors:** 30 min
- **Typography:** 20 min
- **AppBar/Tabs:** 30 min
- **Cards/Containers:** 30 min
- **Charts:** 30 min
- **Animations:** 30 min
- **Polish & Testing:** 30 min
- **Total:** 2.5-3 hours

---

## Next Steps (Post-Phase 9)
1. Full device testing on Android 16 phone
2. Screenshot/video for demo
3. Consider additional features (e.g., dark/light theme toggle, custom fonts)
4. Phase 10: Advanced analytics (if time permits)

