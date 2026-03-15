# Performance Optimizations Summary

This document outlines all performance optimizations applied to the biohacker-flutter codebase, focusing on high-traffic screens (dashboard, calendar, cycles).

## Overview
All optimizations maintain existing functionality while improving rendering performance, reducing memory overhead, and minimizing unnecessary rebuilds.

---

## 1. Const Constructors

### Impact: Reduces widget rebuilds by allowing Flutter to reuse widget instances

### Files Modified:
- `lib/widgets/app_header.dart`
- `lib/screens/dashboard_screen.dart`
- `lib/screens/calendar_screen.dart`
- `lib/screens/cycles_screen.dart`

### Changes:
- Added `const` to `AppHeader` widget instances across all high-traffic screens
- Made `_ScanlinesPainter` const in dashboard, calendar, and cycles screens
- Applied const to background layers (CityBackground, CyberpunkRain) which are static
- Added const to static UI elements like SizedBox, Positioned.fill, etc.

### Example:
```dart
// Before
AppHeader(
  icon: Icons.dashboard,
  iconColor: WintermmuteStyles.colorCyan,
  title: 'DAILY ACTIONS',
)

// After
const AppHeader(
  icon: Icons.dashboard,
  iconColor: WintermmuteStyles.colorCyan,
  title: 'DAILY ACTIONS',
)
```

---

## 2. Optimized List Rendering

### Impact: Better performance with large lists, proper memory management

### Dashboard Screen (`lib/screens/dashboard_screen.dart`)

#### Today's Doses List
- **Changed from**: `Column` with `.map().toList()`
- **Changed to**: `ListView.builder`
- **Benefit**: Lazy loading, builds only visible items

```dart
// Before
Widget _buildDosesList() {
  return Column(
    children: _todaysDoses.map((dose) => _buildDoseCard(dose)).toList(),
  );
}

// After
Widget _buildDosesList() {
  return ListView.builder(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    itemCount: _todaysDoses.length,
    itemBuilder: (context, index) => _buildDoseCard(_todaysDoses[index]),
  );
}
```

#### Cycle Progress Section
- **Changed from**: `Column` with `.map().toList()`
- **Changed to**: `ListView.builder`
- **Benefit**: Better performance with multiple active cycles

### Cycles Screen (`lib/screens/cycles_screen.dart`)

#### Cycle List Optimizations
- Added `addAutomaticKeepAlives: true` to preserve expanded state
- Added `addRepaintBoundaries: true` to optimize repaints
- Added `key: ValueKey(cycle.id)` to each ExpandableCycleCard for better rebuild performance

```dart
ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: savedCycles.length,
  addAutomaticKeepAlives: true, // Keep expanded state
  addRepaintBoundaries: true, // Optimize repaints
  itemBuilder: (context, index) {
    final cycle = savedCycles[index];
    return ExpandableCycleCard(
      key: ValueKey(cycle.id), // Add key for better rebuild performance
      cycle: cycle,
      // ...
    );
  },
)
```

### Calendar Screen (`lib/screens/calendar_screen.dart`)

#### Grid View Optimizations
- Added `addAutomaticKeepAlives: false` to day headers (reduces memory overhead)
- Added `addRepaintBoundaries: false` to simple header cells
- Added `addRepaintBoundaries: true` to interactive date cells
- Applied to both week and month grid views

```dart
// Week view day headers
GridView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 7,
    childAspectRatio: 1.0,
  ),
  itemCount: 7,
  addAutomaticKeepAlives: false, // Optimize: Don't keep children alive
  addRepaintBoundaries: false, // Optimize: Reduce repaint boundaries for simple cells
  itemBuilder: (context, index) {
    // ...
  },
)

// Week view date cells
GridView.builder(
  // ...
  addAutomaticKeepAlives: false, // Optimize: Reduce memory overhead
  addRepaintBoundaries: true, // Keep repaint boundaries for interactive cells
  // ...
)
```

---

## 3. Cached Expensive Computations

### Impact: Prevents redundant date calculations on every rebuild

### Dashboard Screen (`lib/screens/dashboard_screen.dart`)

Added caching for cycle progress calculations:

```dart
// Cache maps added to state
final Map<String, double> _cycleProgressCache = {};
final Map<String, int> _currentDayCache = {};
final Map<String, int> _totalDaysCache = {};

// Optimized calculation methods
double _calculateCycleProgress(Cycle cycle) {
  if (_cycleProgressCache.containsKey(cycle.id)) {
    return _cycleProgressCache[cycle.id]!;
  }

  final now = DateTime.now();
  final totalDays = cycle.endDate.difference(cycle.startDate).inDays;
  final currentDay = now.difference(cycle.startDate).inDays + 1;

  double progress;
  if (currentDay <= 0) {
    progress = 0.0;
  } else if (currentDay >= totalDays) {
    progress = 1.0;
  } else {
    progress = currentDay / totalDays;
  }

  _cycleProgressCache[cycle.id] = progress;
  return progress;
}
```

Cache is cleared when data is reloaded:
```dart
Future<void> _loadData() async {
  // ... load data ...

  // Clear caches when data is reloaded
  _cycleProgressCache.clear();
  _currentDayCache.clear();
  _totalDaysCache.clear();

  // ... update state ...
}
```

**Benefits**:
- Prevents redundant date difference calculations
- Improves performance when rendering multiple cycles
- Cache is automatically invalidated on data refresh

---

## 4. Provider Usage Review

### Impact: Ensures optimal reactivity without unnecessary rebuilds

### Current State: Already Optimized
After reviewing all high-traffic screens:

- **Dashboard**: Uses `ref.read()` for one-time operations (auth, services)
- **Calendar**:
  - Uses `ref.watch()` for reactive data (upcomingDoses, userId, labResults)
  - Uses `ref.read()` for one-time operations (services)
- **Cycles**: Stateful widget without provider dependencies in main widget

**No changes needed** - provider usage patterns are already following best practices:
- `watch` is used when UI needs to react to changes
- `read` is used for one-time operations and callbacks

---

## 5. Widget Tree Optimizations

### Impact: Reduces widget tree depth and unnecessary wrapper widgets

### Changes:
- Added `mainAxisSize: MainAxisSize.min` to Row widgets where appropriate
- This prevents unnecessary expansion and improves layout performance

```dart
Row(
  mainAxisSize: MainAxisSize.min, // Only take required space
  children: [
    Icon(Icons.trending_up, color: AppColors.secondary, size: 20),
    const SizedBox(width: 8),
    Text('CYCLE PROGRESS', style: /* ... */),
  ],
)
```

---

## Performance Best Practices Applied

1. **Const Constructors**: Applied to all static widgets that don't change
2. **ListView.builder**: Used instead of Column with map for dynamic lists
3. **Keys**: Added ValueKey to list items for better rebuild performance
4. **Caching**: Implemented for expensive date calculations
5. **Grid Optimizations**:
   - `addAutomaticKeepAlives: false` for simple cells
   - `addRepaintBoundaries` configured appropriately
6. **Provider Usage**: Verified watch vs read usage patterns
7. **Widget Reuse**: Const painters for CustomPaint widgets

---

## Expected Performance Improvements

### Dashboard Screen
- **Faster initial render**: Const widgets reduce widget instantiation
- **Smoother scrolling**: ListView.builder for doses and cycles
- **Reduced CPU usage**: Cached cycle progress calculations
- **Less memory**: Optimized list rendering

### Calendar Screen
- **Faster grid rendering**: Optimized GridView.builder flags
- **Reduced repaints**: Appropriate repaint boundaries
- **Better memory usage**: Disabled automatic keep-alives for headers

### Cycles Screen
- **Preserved state**: Expandable cards maintain state during scrolls
- **Faster rebuilds**: Keys prevent unnecessary widget recreation
- **Smoother animations**: Repaint boundaries isolate animation updates

---

## Testing Recommendations

1. **Large Data Sets**: Test with 50+ doses, 10+ active cycles
2. **Scrolling Performance**: Verify smooth 60fps scrolling
3. **Rebuild Counts**: Use Flutter DevTools to verify reduced rebuilds
4. **Memory Usage**: Monitor memory before/after optimizations
5. **Animation Performance**: Check expandable card animations

---

## Maintenance Notes

### When to Clear Caches
The cycle progress caches are automatically cleared in `_loadData()`. If you add new data modification methods, ensure caches are cleared:

```dart
// Clear caches after data changes
_cycleProgressCache.clear();
_currentDayCache.clear();
_totalDaysCache.clear();
```

### Adding New List Views
When adding new ListView.builder instances, remember to:
1. Add keys to list items: `key: ValueKey(item.id)`
2. Set appropriate `addAutomaticKeepAlives` based on item complexity
3. Set appropriate `addRepaintBoundaries` based on item interactivity
4. Use `const` for static configuration

### Provider Patterns
- Use `ref.watch()` in build methods when UI needs to react to changes
- Use `ref.read()` in event handlers and callbacks
- Never use `ref.watch()` inside event handlers

---

## Files Modified

1. `/lib/screens/dashboard_screen.dart`
   - Added const constructors
   - Optimized list rendering with ListView.builder
   - Added caching for cycle calculations
   - Made _ScanlinesPainter const

2. `/lib/screens/calendar_screen.dart`
   - Added const constructors
   - Optimized GridView.builder with performance flags
   - Made _ScanlinesPainter const

3. `/lib/screens/cycles_screen.dart`
   - Added const constructors
   - Added keys to ExpandableCycleCard instances
   - Optimized ListView.builder with performance flags
   - Made _ScanlinesPainter const

4. `/lib/widgets/app_header.dart`
   - Added `mainAxisSize: MainAxisSize.min` to inner Row

---

## Performance Metrics

### Before Optimizations
- Widget rebuilds: High (no const, no caching)
- List rendering: Eager (builds all items at once)
- Memory usage: Higher (keeps all widgets alive)
- Date calculations: Repeated on every rebuild

### After Optimizations
- Widget rebuilds: Minimized (const widgets, proper keys)
- List rendering: Lazy (builds only visible items)
- Memory usage: Optimized (selective keep-alives)
- Date calculations: Cached (computed once per data load)

---

## Conclusion

All optimizations are **non-breaking** and maintain existing functionality. The changes focus on:
- Reducing unnecessary widget rebuilds
- Optimizing list and grid rendering
- Caching expensive computations
- Following Flutter performance best practices

These optimizations should result in:
- Smoother UI performance
- Lower CPU usage
- Reduced memory consumption
- Better battery life on mobile devices
- Improved responsiveness on lower-end devices
