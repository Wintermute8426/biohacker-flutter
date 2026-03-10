# Calendar Component Styling Guide

Component-by-component cyberpunk styling for Material Design 3 calendar widgets.

## 1. SegmentedButton (Cycle Filter)

**Location:** Top of calendar screen, filters active cycles  
**Material Default:** Light background, blue selection, standard ripple  
**Wintermute Override:** Black background, cyan border, green text, glow on selection

### Code Example
```dart
import '../theme/wintermute_calendar.dart';

// Replace Material SegmentedButton with custom container
Container(
  height: 40,
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
        duration: WintermuteCalendar.tapAnimationDuration,
        curve: WintermuteCalendar.animationCurve,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: WintermuteCalendar.filterChipDecoration(
          isSelected: selectedCycle == cycle.id,
        ),
        child: Text(
          cycle.name.toUpperCase(),
          style: WintermuteCalendar.filterChipStyle.copyWith(
            color: selectedCycle == cycle.id 
              ? AppColors.accent    // Green when selected
              : AppColors.textMid,  // Gray when not
          ),
        ),
      ),
    )).toList(),
  ),
)
```

**Critical:**
- NO `SegmentedButton` widget (Material)
- Use `AnimatedContainer` for smooth glow transition
- Text = JetBrains Mono, uppercase
- Border = 1px cyan, glow on selected

---

## 2. GridView (Week Calendar Grid)

**Location:** 7-column grid (Mon-Sun) showing day cells  
**Material Default:** Card widgets, light background, shadow  
**Wintermute Override:** Pure black grid, custom day cells, status-based borders

### Code Example
```dart
GridView.builder(
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(),
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 7,
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 0.8,
  ),
  itemCount: 7,  // One week
  itemBuilder: (context, index) {
    final date = weekStart.add(Duration(days: index));
    final hasScheduledDoses = _getScheduledDoses(date).isNotEmpty;
    final loggedDoses = _getLoggedDoses(date).length;
    final scheduledDoses = _getScheduledDoses(date).length;
    
    final statusColor = WintermuteCalendar.getStatusColor(
      scheduledDoses: scheduledDoses,
      loggedDoses: loggedDoses,
      date: date,
    );
    
    final isSelected = selectedDate?.day == date.day;
    final isToday = _isToday(date);
    
    return GestureDetector(
      onTap: () => _selectDate(date),
      child: AnimatedContainer(
        duration: WintermuteCalendar.tapAnimationDuration,
        curve: WintermuteCalendar.animationCurve,
        decoration: hasScheduledDoses 
          ? WintermuteCalendar.dayCellWithDosesDecoration(
              statusColor: statusColor,
              isSelected: isSelected,
            )
          : WintermuteCalendar.dayCellDecoration(isToday: isToday),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Day number
            Text(
              '${date.day}',
              style: WintermuteCalendar.dayNumberStyle.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textLight,
              ),
            ),
            SizedBox(height: 4),
            // Dose count indicator (if any)
            if (hasScheduledDoses)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: WintermuteCalendar.statusChipDecoration(statusColor),
                child: Text(
                  '$loggedDoses/$scheduledDoses',
                  style: WintermuteCalendar.doseCountStyle.copyWith(
                    color: statusColor,
                    fontSize: 9,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  },
)
```

**Critical:**
- NO `Card` widget (Material)
- Use `AnimatedContainer` for state transitions
- Border color = status-based (green/cyan/red)
- Glow = ONLY on selected cells or cells with doses
- Minimum touch target = 48dp (accessibility)

---

## 3. DraggableScrollableSheet (Day Detail Bottom Sheet)

**Location:** Bottom sheet that slides up when day is tapped  
**Material Default:** White background, rounded corners, handle  
**Wintermute Override:** Pure black, cyan top border, scanlines, JetBrains Mono

### Code Example
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
              
              // Sheet title
              Text(
                _formatDate(selectedDate!),
                style: WintermuteCalendar.sheetTitleStyle,
              ),
              SizedBox(height: 8),
              
              // Status indicator
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: WintermuteCalendar.statusChipDecoration(
                  _getStatusColor(),
                ),
                child: Text(
                  _getStatusLabel(),
                  style: WintermuteCalendar.filterChipStyle.copyWith(
                    color: _getStatusColor(),
                    fontSize: 10,
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Scheduled doses list
              ..._getScheduledDoses(selectedDate!).map((dose) {
                final isLogged = _isDoseLogged(dose);
                return Container(
                  margin: EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(
                      color: isLogged 
                        ? WintermuteCalendar.borderGreen 
                        : WintermuteCalendar.borderCyan,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      // Status icon
                      Icon(
                        isLogged ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isLogged 
                          ? WintermuteCalendar.statusOnTrack 
                          : AppColors.textMid,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      // Dose details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dose.peptide,
                              style: WintermuteCalendar.dayNumberStyle.copyWith(
                                fontSize: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '${dose.amount} ${dose.unit}',
                              style: WintermuteCalendar.doseCountStyle.copyWith(
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Log button
                      if (!isLogged)
                        GestureDetector(
                          onTap: () => _logDose(dose),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              border: Border.all(
                                color: AppColors.accent,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'LOG',
                              style: WintermuteCalendar.filterChipStyle.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
          
          // Scanlines overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: ScanlinesPainter(
                  opacity: 0.05,
                  lineSpacing: 3.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  },
)
```

**Critical:**
- Background = Pure black (#000000)
- Top border = 2px cyan (#00FFFF)
- Scanlines overlay = 5% opacity
- All text = JetBrains Mono
- Button styling = bordered, not filled

---

## 4. FilterChip / Status Bar Chips

**Location:** Top of screen (cycle filter) and in day cells (status indicators)  
**Material Default:** Blue/teal chips with standard Material styling  
**Wintermute Override:** Black background, colored borders, mono font

### Code Example
```dart
// Status chip (in day cell or bottom sheet)
Container(
  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  decoration: WintermuteCalendar.statusChipDecoration(statusColor),
  child: Text(
    statusText.toUpperCase(),
    style: WintermuteCalendar.doseCountStyle.copyWith(
      color: statusColor,
      fontSize: 9,
      fontWeight: FontWeight.bold,
    ),
  ),
)

// Cycle filter chip (in top bar)
GestureDetector(
  onTap: () => selectCycle(cycleId),
  child: AnimatedContainer(
    duration: WintermuteCalendar.tapAnimationDuration,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: WintermuteCalendar.filterChipDecoration(
      isSelected: selectedCycle == cycleId,
    ),
    child: Text(
      cycleName.toUpperCase(),
      style: WintermuteCalendar.filterChipStyle.copyWith(
        color: selectedCycle == cycleId 
          ? AppColors.accent 
          : AppColors.textMid,
      ),
    ),
  ),
)
```

**Critical:**
- NO `FilterChip` widget (Material)
- Use `Container` with custom decoration
- Text = JetBrains Mono, uppercase
- Border colors = status-based (green/cyan/red/orange)
- Padding = tight (6-12px horizontal)

---

## 5. Week Header (MON TUE WED...)

**Location:** Top of calendar grid  
**Material Default:** Standard Material text style  
**Wintermute Override:** Cyan, uppercase, JetBrains Mono, letter-spaced

### Code Example
```dart
// Week header row
Container(
  padding: EdgeInsets.symmetric(vertical: 8),
  decoration: BoxDecoration(
    border: Border(
      bottom: BorderSide(
        color: WintermuteCalendar.borderCyan,
        width: 1,
      ),
    ),
  ),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
      .map((day) => Expanded(
        child: Text(
          day,
          textAlign: TextAlign.center,
          style: WintermuteCalendar.weekHeaderStyle,
        ),
      ))
      .toList(),
  ),
)
```

**Critical:**
- Text = Uppercase
- Font = JetBrains Mono, bold, 11px
- Color = Cyan (#00FFFF)
- Letter spacing = 1.5px
- Bottom border = 1px cyan

---

## 6. Date Range Header (MAR 10-16, 2026)

**Location:** Above week header, navigation controls  
**Material Default:** Material text style  
**Wintermute Override:** Cyan, JetBrains Mono, letter-spaced

### Code Example
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    // Previous week button
    IconButton(
      icon: Icon(Icons.chevron_left, color: AppColors.primary),
      onPressed: () => _previousWeek(),
      splashColor: Colors.transparent,  // Disable Material ripple
      highlightColor: AppColors.primary.withOpacity(0.1),
    ),
    
    // Date range text
    Text(
      _formatWeekRange(currentWeekStart),
      style: WintermuteCalendar.dateRangeStyle,
    ),
    
    // Next week button
    IconButton(
      icon: Icon(Icons.chevron_right, color: AppColors.primary),
      onPressed: () => _nextWeek(),
      splashColor: Colors.transparent,  // Disable Material ripple
      highlightColor: AppColors.primary.withOpacity(0.1),
    ),
  ],
)

// Format helper
String _formatWeekRange(DateTime weekStart) {
  final weekEnd = weekStart.add(Duration(days: 6));
  final monthName = DateFormat('MMM').format(weekStart).toUpperCase();
  return '$monthName ${weekStart.day}-${weekEnd.day}, ${weekStart.year}';
}
```

**Critical:**
- Font = JetBrains Mono, bold, 14px
- Color = Cyan (#00FFFF)
- Format = "MAR 10-16, 2026" (uppercase month)
- Letter spacing = 1.0px
- Navigation icons = Cyan, no ripple

---

## 7. Touch Feedback (Animations)

**Requirement:** Replace Material ripples with smooth glow animations

### Code Example
```dart
// Use AnimatedContainer instead of InkWell
GestureDetector(
  onTap: () {
    setState(() => selectedDate = date);
  },
  child: AnimatedContainer(
    duration: WintermuteCalendar.tapAnimationDuration,
    curve: WintermuteCalendar.animationCurve,
    decoration: BoxDecoration(
      color: isSelected ? AppColors.surface : Colors.transparent,
      border: Border.all(
        color: isSelected 
          ? AppColors.primary 
          : WintermuteCalendar.borderCyan,
        width: 1,
      ),
      borderRadius: BorderRadius.circular(4),
      boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,
    ),
    child: // ... cell content
  ),
)
```

**Critical:**
- NO `InkWell` or `InkResponse` (Material ripples)
- Use `AnimatedContainer` for state transitions
- Duration = 200ms
- Curve = `Curves.easeOut`
- Glow = box-shadow, 30% opacity, 8px blur

---

## Material Widgets to AVOID

| Material Widget | Wintermute Replacement |
|-----------------|------------------------|
| `SegmentedButton` | Custom `Container` + `AnimatedContainer` |
| `FilterChip` | Custom `Container` with borders |
| `Card` | `Container` with custom decoration |
| `InkWell` | `GestureDetector` + `AnimatedContainer` |
| `Material(ripple)` | `Material(type: MaterialType.transparency)` |
| `ElevatedButton` | Custom `Container` with borders |
| `TextButton` | Custom `GestureDetector` |

---

## Quick Reference: Common Patterns

### Selected State Toggle
```dart
AnimatedContainer(
  duration: Duration(milliseconds: 200),
  decoration: BoxDecoration(
    color: isSelected ? AppColors.surface : AppColors.background,
    border: Border.all(
      color: isSelected ? AppColors.primary : WintermuteCalendar.borderCyan,
    ),
    boxShadow: isSelected ? WintermuteCalendar.neonGlowCyan : null,
  ),
)
```

### Status-Based Border
```dart
Border.all(
  color: WintermuteCalendar.getStatusColor(
    scheduledDoses: scheduled,
    loggedDoses: logged,
    date: date,
  ).withOpacity(0.5),
  width: 1,
)
```

### Uppercase Text Pattern
```dart
Text(
  label.toUpperCase(),
  style: WintermuteCalendar.filterChipStyle,
)
```

### No-Ripple Button
```dart
Material(
  type: MaterialType.transparency,
  child: GestureDetector(
    onTap: onPressed,
    child: Container(/* styled container */),
  ),
)
```
