# Reports Screen Complete Redesign - Dystopian Cyberpunk

## Current Issues (from screenshot)
- Orange vertical line artifact running through screen
- Broken layout/alignment
- Empty/non-functional trend chart
- Generic styling, not dystopian enough

## Design Requirements

### Visual Aesthetic
- **Pure black background** (#000000)
- **Neon accent colors:**
  - Cyan: #00FFFF (primary data)
  - Magenta: #FF00FF (alerts/warnings)
  - Amber: #FF9800 (highlights)
  - Green: #39FF14 (success states)
- **CRT monitor effects:**
  - Scanlines overlay on all cards
  - Subtle glow on borders/text
  - Matte card backgrounds (rgba(10,10,10,0.9))
- **Typography:**
  - Monospace fonts throughout
  - Small caps for headers
  - Glitch effect on key numbers

### Animations
- Fade-in transitions for cards (stagger 100ms each)
- Shimmer effect on loading states
- Smooth chart line drawing animation
- Pulse effect on selected biomarker buttons
- Terminal-style typing effect for large numbers

### Layout Structure

**Tab 1: LAB REPORTS**
- Timeline view of all lab uploads
- Each card: date, source, biomarker count, status badges
- Expandable to show full biomarker list
- Icons for each biomarker category

**Tab 2: TRENDS**
- Multi-line chart with color-coded biomarkers
- X-axis: dates (not indices)
- Y-axis: dynamic range per biomarker
- Legend with toggle buttons (current design is good, keep icons)
- Add chart controls: zoom, date range selector
- Show data points on hover with tooltip
- Empty state: "AWAITING DATA • UPLOAD LABS TO TRACK BIOMARKERS"

**Tab 3: HISTORY**
- Cycle timeline integration
- Show biomarker changes during each cycle
- Before/after comparisons
- Visual diff indicators (arrows, percentages)

**Tab 4: PERFORMANCE**
- Overall health score (0-100)
- Radar chart for categories (Hormones, Metabolic, etc.)
- Trend arrows (improving/declining)
- AI insights (if available)

### Technical Implementation

**Fix the trends chart:**
1. Remove that orange vertical line (bug)
2. Use actual dates on X-axis (not 0,2,4,6...)
3. Dynamic Y-axis scaling per biomarker
4. Only show lines for biomarkers with data
5. Add touch interactions (zoom, pan)
6. Tooltip on tap showing exact values

**Animations:**
```dart
// Fade-in stagger
AnimatedBuilder with Interval(i * 0.1, 1.0)

// Shimmer loading
LinearGradient with AnimationController

// Chart line draw
CustomPainter with animation 0.0 → 1.0

// Number count-up
TweenAnimationBuilder<int>
```

**Data handling:**
- Properly map LabResultWithContext → chart data
- Handle missing data gracefully
- Sort by date ascending
- Normalize different biomarker ranges

## Files to modify
- `lib/screens/reports_screen.dart` (complete rewrite)
- Create `lib/widgets/reports/` for components:
  - `trend_chart.dart`
  - `lab_card.dart`
  - `biomarker_legend.dart`
  - `performance_radar.dart`

## Reference existing good designs
- Dashboard cards (matte + scanlines)
- Cycle cards (badges, monospace)
- Lab modal (biomarker prioritization)

## Acceptance criteria
- No visual artifacts (orange lines, etc.)
- All 4 tabs functional
- Smooth 60fps animations
- Trend chart shows real data with proper dates
- Touch interactions work (tap, zoom, pan)
- Dystopian cyberpunk aesthetic throughout
- Empty states are informative and styled
