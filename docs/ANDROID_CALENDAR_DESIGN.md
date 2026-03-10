# Android Calendar Design - Material Design 3

## Executive Summary

Transform the calendar from a simple timeline view into a **week-grid calendar** with cycle filtering, responsive tablet support, and full Material Design 3 compliance.

**Key Changes:**
- ✅ Week-based 7-column grid (not list)
- ✅ Cycle filter dropdown (SegmentedButton)
- ✅ Bottom sheet dose details (DraggableScrollableSheet)
- ✅ Tablet landscape mode (split-view)
- ✅ Material Design 3 components (no custom containers)

---

## 1. Design System Foundation

### 1.1 Wintermute Theme Adaptation

**Color Palette (existing from `colors.dart`):**
```dart
primary: #00FFFF (Cyan)       → Primary action, borders
accent: #39FF14 (Neon Green)  → Success, completed states
secondary: #FF00FF (Magenta)  → Warning, pending states
error: #FF0040 (Red)          → Missed doses, errors
surface: #0A0E1A (Dark)       → Card backgrounds
background: #000000 (Black)   → Screen background
```

**Material Design 3 Integration:**
- Use `Material` widgets (not `Container` with manual borders)
- Apply `ColorScheme` based on Wintermute palette
- Enable Material 3: `useMaterial3: true` in `MaterialApp`
- Use `Theme.of(context).colorScheme` for consistency

### 1.2 Typography (JetBrains Mono)

Material Design 3 mapping:
```dart
displayLarge: 22px → Page titles (DOSE CALENDAR)
headlineMedium: 18px → Section headers (Mar 10-16, 2026)
titleMedium: 14px → Cycle filter labels
bodyMedium: 14px → Dose details
bodySmall: 12px → Timestamps
labelSmall: 10px → Status badges
```

Keep existing `WintermmuteStyles` but add Material variants:
```dart
// theme/wintermute_theme.dart (NEW)
TextTheme wintermuteTextTheme = TextTheme(
  displayLarge: WintermmuteStyles.titleStyle,
  headlineMedium: WintermmuteStyles.headerStyle,
  bodyMedium: WintermmuteStyles.bodyStyle,
  bodySmall: WintermmuteStyles.smallStyle,
  labelSmall: WintermmuteStyles.tinyStyle,
);
```

---

## 2. Layout Architecture

### 2.1 Screen Structure

```
┌─────────────────────────────────────────┐
│ AppBar: DOSE CALENDAR [Refresh]        │
├─────────────────────────────────────────┤
│ [Cycle Filter ▼] < WEEK   NEXT >       │ ← Sticky header
│ Mar 10-16, 2026                         │
├─────────────────────────────────────────┤
│ MON  TUE  WED  THU  FRI  SAT  SUN       │ ← Day labels
├─────────────────────────────────────────┤
│  10   11   12   13   14   15   16       │ ← Week grid
│ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐    │
│ │ 3│ │ 2│ │ 4│ │ 1│ │ 0│ │ 2│ │ 3│    │
│ │ •│ │ •│ │ •│ │ •│ │••│ │ •│ │ •│    │
│ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘ └──┘    │
├─────────────────────────────────────────┤
│ ✓ 18 Logged | ⚠ 3 Pending | ✗ 0 Missed │ ← Status chips
└─────────────────────────────────────────┘
```

**Hierarchy:**
1. AppBar (system status bar)
2. Sticky header (filters + navigation)
3. Week grid (7 columns, tap to expand)
4. Status bar (scrollable chips)
5. Bottom sheet (on tap, slides up from bottom)

---

## 3. Component Specifications

### 3.1 Cycle Filter (SegmentedButton)

**Location:** Below AppBar, left-aligned

**Material Design 3 Widget:**
```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'all', label: Text('ALL CYCLES')),
    ...cycles.map((c) => ButtonSegment(
      value: c.id, 
      label: Text(c.name.toUpperCase()),
    )),
  ],
  selected: {selectedCycle ?? 'all'},
  onSelectionChanged: (Set<String> newSelection) {
    setState(() {
      selectedCycle = newSelection.first == 'all' ? null : newSelection.first;
    });
  },
  style: ButtonStyle(
    side: MaterialStateProperty.all(
      BorderSide(color: AppColors.primary.withOpacity(0.3)),
    ),
    selectedForegroundColor: MaterialStateProperty.all(AppColors.background),
    selectedBackgroundColor: MaterialStateProperty.all(AppColors.primary),
  ),
)
```

**Behavior:**
- Single-select (not multi-select)
- Default: "ALL CYCLES"
- Tap → filter calendar to single cycle
- Updates immediately (no "Apply" button)

**Dimensions:**
- Height: 48dp (Material touch target)
- Padding: 16dp horizontal, 12dp vertical
- Font: 12px, bold, uppercase, letter-spacing 1px

### 3.2 Week Navigation (IconButtons + Text)

**Layout:**
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    IconButton(
      icon: Icon(Icons.chevron_left),
      onPressed: () => _previousWeek(),
      color: AppColors.primary,
      iconSize: 28,
    ),
    Text(
      'MAR 10-16, 2026',
      style: Theme.of(context).textTheme.headlineMedium,
    ),
    IconButton(
      icon: Icon(Icons.chevron_right),
      onPressed: () => _nextWeek(),
      color: AppColors.primary,
      iconSize: 28,
    ),
  ],
)
```

**Date Format:**
- Current week: `MAR 10-16, 2026`
- Cross-month: `MAR 30 - APR 5, 2026`
- Today indicator: Cyan dot next to date (if current week)

### 3.3 Week Grid (GridView.builder)

**Component:** `GridView.builder` (not `ListView`)

**Grid Configuration:**
```dart
GridView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 7,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.75, // Slightly taller than wide
  ),
  itemCount: 7, // Always 7 days
  itemBuilder: (context, index) => _buildDayCell(dates[index]),
)
```

**Day Cell Design:**

```dart
Widget _buildDayCell(DateTime date) {
  final doses = _getDosesForDate(date);
  final status = _getDayStatus(doses); // 'completed', 'pending', 'none'
  final isToday = _isToday(date);

  return Material(
    color: _getCellColor(status),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: () => _showDayDetails(date),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day label (MON, TUE)
            Text(
              DateFormat('EEE').format(date).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: isToday ? AppColors.accent : AppColors.textMid,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 4),
            
            // Date number
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            
            // Dose count
            Text(
              '${doses.length}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            // Status indicator dots
            if (status == 'pending')
              Container(
                margin: EdgeInsets.only(top: 4),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.secondary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
```

**Cell Colors (status-based):**
```dart
Color _getCellColor(String status) {
  switch (status) {
    case 'completed': return AppColors.accent.withOpacity(0.1); // Green tint
    case 'pending': return AppColors.secondary.withOpacity(0.1); // Magenta tint
    case 'missed': return AppColors.error.withOpacity(0.1); // Red tint
    default: return AppColors.surface; // Neutral
  }
}
```

**Touch Target:**
- Minimum: 48dp × 48dp (Material spec)
- Ripple effect: `InkWell` with `borderRadius: 8`

### 3.4 Status Bar (Chip Row)

**Location:** Below week grid

**Material Design 3 Widget:**
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _buildStatusChip('LOGGED', loggedCount, AppColors.accent),
      SizedBox(width: 8),
      _buildStatusChip('PENDING', pendingCount, AppColors.secondary),
      SizedBox(width: 8),
      _buildStatusChip('MISSED', missedCount, AppColors.error),
    ],
  ),
)

Widget _buildStatusChip(String label, int count, Color color) {
  return FilterChip(
    label: Text(
      '$count $label',
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: color,
        letterSpacing: 1,
      ),
    ),
    selected: false,
    onSelected: (_) {}, // Future: filter by status
    side: BorderSide(color: color.withOpacity(0.4)),
    backgroundColor: AppColors.surface,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
```

**Behavior:**
- Scrollable horizontally (if chips exceed screen width)
- Non-interactive in Phase 10C (future: tap to filter)
- Updates in real-time when doses change

### 3.5 Bottom Sheet (Dose Details)

**Material Design 3 Widget:**
```dart
void _showDayDetails(DateTime date) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textDim,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEE, MMM dd').format(date).toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.textMid,
                  ),
                ],
              ),
            ),
            
            Divider(color: AppColors.primary.withOpacity(0.2)),
            
            // Dose list
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: doses.length,
                itemBuilder: (context, index) => _buildDoseListItem(doses[index]),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
```

**Dose List Item:**
```dart
Widget _buildDoseListItem(DoseInstance dose) {
  return ListTile(
    leading: CircleAvatar(
      backgroundColor: _getPeptideColor(dose.peptideName).withOpacity(0.2),
      child: Text(
        dose.peptideName[0],
        style: TextStyle(
          color: _getPeptideColor(dose.peptideName),
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    title: Text(
      dose.peptideName,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textLight,
      ),
    ),
    subtitle: Text(
      '${dose.time} | ${dose.doseAmount}mg ${dose.route}',
      style: TextStyle(
        fontSize: 12,
        color: AppColors.textMid,
      ),
    ),
    trailing: _buildStatusBadge(dose.status),
    onTap: () => _showDoseActions(dose),
  );
}

Widget _buildStatusBadge(String status) {
  final color = status == 'COMPLETED' 
      ? AppColors.accent 
      : status == 'MISSED' 
          ? AppColors.error 
          : AppColors.textMid;
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      status,
      style: TextStyle(
        fontSize: 10,
        color: color,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
      ),
    ),
  );
}
```

**Interactions:**
- Swipe down → close
- Tap X button → close
- Tap dose → show action buttons (Mark Missed, Add Symptoms)

---

## 4. Responsive Design (Tablet & Landscape)

### 4.1 Breakpoints

```dart
enum ScreenSize {
  small,  // <600dp width (phone portrait)
  medium, // 600-840dp (phone landscape, small tablet)
  large,  // >840dp (tablet)
}

ScreenSize _getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < 600) return ScreenSize.small;
  if (width < 840) return ScreenSize.medium;
  return ScreenSize.large;
}
```

### 4.2 Adaptive Layouts

**Phone Portrait (Small):**
- 7-column grid
- Cycle filter: full-width SegmentedButton
- Status bar: scrollable row
- Bottom sheet: modal

**Phone Landscape (Medium):**
- Same 7-column grid (more spacing)
- Cycle filter: compact chips (left-aligned)
- Status bar: inline row (no scroll)
- Bottom sheet: side panel (right 40% of screen)

**Tablet Portrait (Large):**
- 7-column grid (larger cell size)
- Font sizes: +2px across the board
- Cycle filter: inline chips
- Bottom sheet: modal (centered, 600dp max width)

**Tablet Landscape (Large):**
- Split-view:
  - Left 60%: Calendar grid
  - Right 40%: Persistent dose detail pane (no modal)
- Cycle filter: top toolbar
- Status bar: integrated into detail pane

### 4.3 Adaptive Grid Spacing

```dart
double _getGridSpacing(ScreenSize size) {
  switch (size) {
    case ScreenSize.small: return 8.0;
    case ScreenSize.medium: return 12.0;
    case ScreenSize.large: return 16.0;
  }
}

double _getCellAspectRatio(ScreenSize size) {
  switch (size) {
    case ScreenSize.small: return 0.75; // Taller
    case ScreenSize.medium: return 0.85;
    case ScreenSize.large: return 0.95; // More square
  }
}
```

### 4.4 Font Scaling

```dart
TextStyle _adaptiveTextStyle(TextStyle base, ScreenSize size) {
  final scaleFactor = size == ScreenSize.large ? 1.15 : 1.0;
  return base.copyWith(fontSize: base.fontSize! * scaleFactor);
}
```

---

## 5. Animations & Transitions

### 5.1 Week Swipe Animation

```dart
class CalendarPageView extends StatelessWidget {
  final int initialWeekIndex;
  final Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: PageController(initialPage: initialWeekIndex),
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) => _buildWeekGrid(index),
    );
  }
}
```

**Transition:** Material page transition (slide + fade)

### 5.2 Cell Tap Animation

- **InkWell ripple:** Cyan color, 300ms duration
- **Scale animation:** Cell slightly enlarges on press (1.0 → 1.05)

```dart
InkWell(
  onTap: () => _showDayDetails(date),
  splashColor: AppColors.primary.withOpacity(0.3),
  highlightColor: AppColors.primary.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
  child: ...,
)
```

### 5.3 Bottom Sheet Slide-Up

- **Entry:** 400ms ease-out curve
- **Exit:** 300ms ease-in curve
- **Drag handle:** Visible affordance (4dp tall, 40dp wide, rounded)

---

## 6. Accessibility

### 6.1 Touch Targets

- Minimum: 48dp × 48dp (Material spec)
- Day cells: 48dp+ (calculated from grid)
- IconButtons: 48dp (default Material size)
- Chips: 48dp height minimum

### 6.2 Semantics

```dart
Semantics(
  label: 'Monday March 10, 3 doses, 2 logged, 1 pending',
  button: true,
  child: _buildDayCell(date),
)
```

### 6.3 Screen Reader Support

- AppBar: "Dose Calendar"
- Cycle filter: "Select cycle: All Cycles, Cycle 1, Cycle 2..."
- Day cells: "Monday March 10, 3 doses, tap to view details"
- Status chips: "18 logged, 3 pending, 0 missed"

---

## 7. Dark Theme Compliance

Already compliant (Wintermute theme is dark-first):
- Background: `#000000` (pure black for OLED)
- Surface: `#0A0E1A` (dark blue-black)
- Text contrast ratio: 4.5:1 minimum (WCAG AA)

**Material Design 3 Dark Theme:**
```dart
ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.dark(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    background: AppColors.background,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  textTheme: wintermuteTextTheme,
);
```

---

## 8. Implementation Checklist

### Phase 1: Core Layout (Build #280)
- [ ] Replace `SingleChildScrollView` with `Column` + `GridView.builder`
- [ ] Add cycle filter `SegmentedButton`
- [ ] Implement week navigation (prev/next buttons)
- [ ] Build 7-column day cells

### Phase 2: Bottom Sheet (Build #280)
- [ ] Replace `showModalBottomSheet` with `DraggableScrollableSheet`
- [ ] Add drag handle
- [ ] Implement dose list (ListTile)
- [ ] Add close button

### Phase 3: Status Bar (Build #280)
- [ ] Add `FilterChip` row below grid
- [ ] Calculate logged/pending/missed counts
- [ ] Make scrollable horizontally

### Phase 4: Responsive (Build #281)
- [ ] Add breakpoint detection
- [ ] Implement adaptive grid spacing
- [ ] Add tablet landscape split-view
- [ ] Scale fonts for tablet

### Phase 5: Polish (Build #281)
- [ ] Add ripple animations
- [ ] Implement week swipe with PageView
- [ ] Add accessibility labels
- [ ] Test on Pixel 4a + Samsung Tab S7

---

## 9. Success Criteria

✅ **Material Design 3 compliant** (uses `Material`, `InkWell`, `SegmentedButton`, `FilterChip`)  
✅ **7-column week grid** (not linear list)  
✅ **Cycle filter works** (filters to single cycle)  
✅ **Bottom sheet responsive** (drag handle + smooth slide)  
✅ **Tablet landscape split-view** (calendar left, details right)  
✅ **Touch targets ≥48dp** (verified with layout inspector)  
✅ **Smooth animations** (60fps ripple + transitions)

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Author:** Wintermute (Subagent)  
**Status:** Ready for Implementation
