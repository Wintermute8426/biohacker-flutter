# Implementation Roadmap - Calendar Optimization Phase 10C

## Executive Summary

Transform calendar from inefficient timeline list (1.8s loads) to optimized week-grid with Material Design 3 (<500ms loads, 60fps scrolling).

**Timeline:** 3 builds (Build #280-282)  
**Complexity:** Medium (refactor state + UI, add indexes)  
**Risk:** Low (incremental changes, backward compatible)

---

## Build Overview

| Build | Focus | Files Changed | Duration | Validation |
|-------|-------|---------------|----------|------------|
| **#280** | Core Query Optimization + UI Layout | 5 files | 4-6 hours | Load time <500ms |
| **#281** | State Management + Caching | 3 files | 3-4 hours | Cache hit rate >80% |
| **#282** | Tablet/Landscape + Polish | 4 files | 2-3 hours | 60fps scrolling, tablet layout |

**Total Estimated Time:** 9-13 hours  
**Critical Path:** Database indexes → State refactor → UI rebuild

---

## Build #280: Core Query Optimization + Material Design 3 Layout

**Goal:** Replace timeline list with week-grid calendar, optimize database queries

### Phase 1: Database Optimization (1 hour)

#### 1.1 Add Indexes to Supabase

**Location:** Supabase SQL Editor

```sql
-- Run in production database
BEGIN;

-- Composite index for user + time queries
CREATE INDEX CONCURRENTLY idx_dose_logs_user_time 
ON dose_logs(user_id, logged_at DESC);

-- Composite index for cycle + time filtering
CREATE INDEX CONCURRENTLY idx_dose_logs_cycle_time 
ON dose_logs(cycle_id, logged_at DESC);

-- Verify indexes
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'dose_logs';

COMMIT;
```

**Validation:**
```sql
-- Check query plan uses indexes
EXPLAIN ANALYZE 
SELECT * FROM dose_logs 
WHERE user_id = 'user-id-here' 
  AND logged_at >= '2026-03-10' 
  AND logged_at < '2026-03-17'
ORDER BY logged_at;
```

Expected output: `Index Scan using idx_dose_logs_user_time` (not `Seq Scan`)

---

#### 1.2 Add getWeekDoses() to Service

**File:** `lib/services/dose_schedule_service.dart`

**Changes:**

```dart
// ADD: Week-based query method
Future<List<DoseInstance>> getWeekDoses(
  String userId, {
  DateTime? weekStart,
  String? cycleId,
}) async {
  try {
    final start = weekStart ?? _getWeekStart(DateTime.now());
    final end = start.add(Duration(days: 7));

    print('[SERVICE] Fetching week: ${DateFormat('yyyy-MM-dd').format(start)}');

    var query = _supabase
        .from('dose_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', start.toIso8601String())
        .lt('logged_at', end.toIso8601String());

    if (cycleId != null) {
      query = query.eq('cycle_id', cycleId);
    }

    final doseLogs = await query.order('logged_at', ascending: true);

    print('[SERVICE] Fetched ${(doseLogs as List).length} dose_logs');

    // Convert to DoseInstance (reuse existing logic from getUpcomingDoses)
    final instances = <DoseInstance>[];
    // ... conversion logic ...

    return instances;
  } catch (e) {
    print('[SERVICE ERROR] $e');
    return [];
  }
}

// ADD: Helper to get Monday of week
DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
}
```

**Keep:** `getUpcomingDoses()` for backward compatibility (delete in Build #281)

---

### Phase 2: Material Design 3 Setup (30 min)

#### 2.1 Enable Material 3

**File:** `lib/main.dart`

```dart
// MODIFY: MaterialApp
MaterialApp(
  title: 'Biohacker',
  theme: ThemeData(
    useMaterial3: true, // ADD THIS
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.accent,
      background: AppColors.background,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: wintermuteTextTheme, // Use existing
  ),
  home: MainScreen(),
)
```

#### 2.2 Create Wintermute TextTheme

**File:** `lib/theme/wintermute_theme.dart` (NEW)

```dart
import 'package:flutter/material.dart';
import 'wintermute_styles.dart';

TextTheme get wintermuteTextTheme => TextTheme(
  displayLarge: WintermmuteStyles.titleStyle,
  headlineMedium: WintermmuteStyles.headerStyle,
  titleMedium: WintermmuteStyles.subHeaderStyle,
  bodyMedium: WintermmuteStyles.bodyStyle,
  bodySmall: WintermmuteStyles.smallStyle,
  labelSmall: WintermmuteStyles.tinyStyle,
);
```

---

### Phase 3: UI Refactor (2.5-3 hours)

#### 3.1 Replace Timeline with Week Grid

**File:** `lib/screens/calendar_screen.dart`

**REMOVE:**
```dart
// Delete _buildUpcomingSummary()
// Delete _buildDoseTimeline()
// Delete _buildDoseCard()
```

**ADD:**
```dart
// NEW: Week navigation header
Widget _buildWeekHeader() {
  return Padding(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: Icon(Icons.chevron_left, size: 28),
          onPressed: () => _previousWeek(),
          color: AppColors.primary,
        ),
        Text(
          _formatWeekRange(_currentWeekStart),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        IconButton(
          icon: Icon(Icons.chevron_right, size: 28),
          onPressed: () => _nextWeek(),
          color: AppColors.primary,
        ),
      ],
    ),
  );
}

String _formatWeekRange(DateTime weekStart) {
  final weekEnd = weekStart.add(Duration(days: 6));
  if (weekStart.month == weekEnd.month) {
    return DateFormat('MMM dd-dd, yyyy').format(weekStart).toUpperCase()
        .replaceFirst(DateFormat('dd').format(weekStart), '${weekStart.day}-${weekEnd.day}');
  } else {
    return '${DateFormat('MMM dd').format(weekStart).toUpperCase()} - ${DateFormat('MMM dd, yyyy').format(weekEnd).toUpperCase()}';
  }
}

void _previousWeek() {
  setState(() {
    _currentWeekStart = _currentWeekStart.subtract(Duration(days: 7));
  });
  ref.refresh(upcomingDosesProvider); // Temporary, will replace with state provider in #281
}

void _nextWeek() {
  setState(() {
    _currentWeekStart = _currentWeekStart.add(Duration(days: 7));
  });
  ref.refresh(upcomingDosesProvider);
}

// NEW: 7-column week grid
Widget _buildWeekGrid(Map<DateTime, List<DoseInstance>> dosesByDate) {
  final weekDates = List.generate(7, (i) => _currentWeekStart.add(Duration(days: i)));

  return GridView.builder(
    shrinkWrap: true,
    physics: NeverScrollableScrollPhysics(),
    padding: EdgeInsets.symmetric(horizontal: 16),
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.75,
    ),
    itemCount: 7,
    itemBuilder: (context, index) {
      final date = weekDates[index];
      final doses = dosesByDate[DateTime(date.year, date.month, date.day)] ?? [];
      return _buildDayCell(date, doses);
    },
  );
}

// NEW: Day cell component
Widget _buildDayCell(DateTime date, List<DoseInstance> doses) {
  final isToday = _isToday(date);
  final status = _getDayStatus(doses);

  return Material(
    color: _getCellColor(status),
    borderRadius: BorderRadius.circular(8),
    child: InkWell(
      onTap: () => _showDayDetails(date, doses),
      borderRadius: BorderRadius.circular(8),
      splashColor: AppColors.primary.withOpacity(0.3),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
            Text(
              '${date.day}',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.textLight,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${doses.length}',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
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

String _getDayStatus(List<DoseInstance> doses) {
  if (doses.isEmpty) return 'none';
  final allCompleted = doses.every((d) => d.status == 'COMPLETED');
  final anyMissed = doses.any((d) => d.status == 'MISSED');
  if (allCompleted) return 'completed';
  if (anyMissed) return 'missed';
  return 'pending';
}

Color _getCellColor(String status) {
  switch (status) {
    case 'completed': return AppColors.accent.withOpacity(0.1);
    case 'pending': return AppColors.secondary.withOpacity(0.1);
    case 'missed': return AppColors.error.withOpacity(0.1);
    default: return AppColors.surface;
  }
}
```

#### 3.2 Add Bottom Sheet Details

**ADD:**
```dart
void _showDayDetails(DateTime date, List<DoseInstance> doses) {
  if (doses.isEmpty) return;

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
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textLight),
    ),
    subtitle: Text(
      '${dose.time} | ${dose.doseAmount}mg ${dose.route}',
      style: TextStyle(fontSize: 12, color: AppColors.textMid),
    ),
    trailing: _buildStatusBadge(dose.status),
    onTap: () {
      Navigator.pop(context);
      _showDoseDetails(dose); // Reuse existing modal
    },
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

#### 3.3 Add Status Bar

**ADD:**
```dart
Widget _buildStatusBar(List<DoseInstance> doses) {
  final counts = _getStatusCounts(doses);

  return Container(
    padding: EdgeInsets.all(16),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatusChip('LOGGED', counts['logged']!, AppColors.accent),
        _buildStatusChip('PENDING', counts['pending']!, AppColors.secondary),
        _buildStatusChip('MISSED', counts['missed']!, AppColors.error),
      ],
    ),
  );
}

Map<String, int> _getStatusCounts(List<DoseInstance> doses) {
  return {
    'logged': doses.where((d) => d.status == 'COMPLETED').length,
    'pending': doses.where((d) => d.status == 'SCHEDULED').length,
    'missed': doses.where((d) => d.status == 'MISSED').length,
  };
}

Widget _buildStatusChip(String label, int count, Color color) {
  return FilterChip(
    label: Text(
      '$count $label',
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color, letterSpacing: 1),
    ),
    selected: false,
    onSelected: (_) {},
    side: BorderSide(color: color.withOpacity(0.4)),
    backgroundColor: AppColors.surface,
    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  );
}
```

---

### Phase 4: Temporary Week Filtering (30 min)

**Note:** This is a quick fix for Build #280. Will be replaced with proper state management in #281.

**File:** `lib/screens/calendar_screen.dart`

```dart
// MODIFY: upcomingDosesProvider consumer
Widget build(BuildContext context) {
  final upcomingDoses = ref.watch(upcomingDosesProvider);

  return upcomingDoses.when(
    data: (doses) {
      // FILTER: Only show current week
      final weekDoses = doses.where((dose) {
        final doseDate = DateTime(dose.date.year, dose.date.month, dose.date.day);
        final weekEnd = _currentWeekStart.add(Duration(days: 7));
        return doseDate.isAfter(_currentWeekStart.subtract(Duration(days: 1))) &&
               doseDate.isBefore(weekEnd);
      }).toList();

      // Group by date
      final dosesByDate = <DateTime, List<DoseInstance>>{};
      for (final dose in weekDoses) {
        final dateKey = DateTime(dose.date.year, dose.date.month, dose.date.day);
        dosesByDate.putIfAbsent(dateKey, () => []).add(dose);
      }

      return Column(
        children: [
          _buildWeekHeader(),
          _buildWeekGrid(dosesByDate),
          _buildStatusBar(weekDoses),
        ],
      );
    },
    loading: () => Center(child: CircularProgressIndicator()),
    error: (err, stack) => Center(child: Text('Error: $err')),
  );
}
```

---

### Build #280 Validation Checklist

- [ ] Database indexes verified (`idx_dose_logs_user_time`, `idx_dose_logs_cycle_time`)
- [ ] Query plan uses index scan (not seq scan)
- [ ] Week grid renders 7 columns
- [ ] Day cells show correct dose counts
- [ ] Bottom sheet opens on tap
- [ ] Status bar shows correct counts
- [ ] Week navigation (prev/next) works
- [ ] Load time <500ms (measured with Flutter DevTools)

**Test Commands:**
```bash
flutter clean
flutter pub get
flutter run --profile
# Open DevTools → Performance tab → measure timeline render
```

**Expected Performance:**
- Initial load: ~500ms (down from 1.8s)
- Week swipe: ~1.2s (will improve to <100ms in #281 with caching)

---

## Build #281: State Management + Caching

**Goal:** Replace FutureProvider with StateNotifierProvider + caching for <100ms cache hits

### Phase 1: Create State Management (1.5 hours)

#### 1.1 Create CalendarState Model

**File:** `lib/providers/calendar_state.dart` (NEW)

```dart
// Copy full implementation from STATE_MANAGEMENT_REDESIGN.md Section 2.1
```

#### 1.2 Create CalendarNotifier

**File:** `lib/providers/calendar_state.dart` (CONTINUED)

```dart
// Copy full implementation from STATE_MANAGEMENT_REDESIGN.md Section 2.2
```

#### 1.3 Create Providers

**File:** `lib/providers/calendar_provider.dart` (NEW)

```dart
// Copy full implementation from STATE_MANAGEMENT_REDESIGN.md Section 2.3
```

---

### Phase 2: Refactor CalendarScreen (1.5 hours)

#### 2.1 Replace FutureProvider with StateNotifierProvider

**File:** `lib/screens/calendar_screen.dart`

**REMOVE:**
```dart
final upcomingDoses = ref.watch(upcomingDosesProvider);
DateTime _currentWeekStart;
void _previousWeek() { ... }
void _nextWeek() { ... }
```

**REPLACE WITH:**
```dart
final calendarState = ref.watch(calendarProvider);
final dosesByDate = ref.watch(dosesByDateProvider);
final statusCounts = ref.watch(statusCountsProvider);

// Navigation now handled by provider
void _previousWeek() {
  ref.read(calendarProvider.notifier).previousWeek();
}

void _nextWeek() {
  ref.read(calendarProvider.notifier).nextWeek();
}
```

#### 2.2 Update Build Method

**REPLACE:**
```dart
return upcomingDoses.when(
  data: (doses) => ...,
  loading: () => ...,
  error: (err, stack) => ...,
);
```

**WITH:**
```dart
return Column(
  children: [
    _buildWeekHeader(),
    if (calendarState.isLoading)
      Center(child: CircularProgressIndicator())
    else if (calendarState.error != null)
      Center(child: Text('Error: ${calendarState.error}'))
    else
      _buildWeekGrid(dosesByDate),
    _buildStatusBar(statusCounts),
  ],
);
```

#### 2.3 Add Invalidation on Dose Updates

**ADD:**
```dart
Future<void> _markDoseComplete(DoseInstance dose) async {
  await doseLogsService.markComplete(dose.doseLogId);
  
  // Invalidate affected week
  final weekStart = CalendarNotifier._getWeekStart(dose.date);
  ref.read(calendarProvider.notifier).invalidateWeek(weekStart, dose.cycleId);
}
```

---

### Phase 3: Add Cycle Filtering (1 hour)

#### 3.1 Fetch Cycles List

**File:** `lib/screens/calendar_screen.dart`

```dart
final cycles = ref.watch(cyclesProvider); // Existing provider from cycles feature
```

#### 3.2 Add SegmentedButton

**ADD:**
```dart
Widget _buildCycleFilter(List<Cycle> cycles) {
  final calendarState = ref.watch(calendarProvider);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: SegmentedButton<String>(
      segments: [
        ButtonSegment(value: 'all', label: Text('ALL CYCLES')),
        ...cycles.map((c) => ButtonSegment(
          value: c.id, 
          label: Text(c.name.toUpperCase()),
        )),
      ],
      selected: {calendarState.selectedCycleId ?? 'all'},
      onSelectionChanged: (Set<String> newSelection) {
        final cycleId = newSelection.first == 'all' ? null : newSelection.first;
        ref.read(calendarProvider.notifier).setCycleFilter(cycleId);
      },
      style: ButtonStyle(
        side: MaterialStateProperty.all(BorderSide(color: AppColors.primary.withOpacity(0.3))),
        selectedForegroundColor: MaterialStateProperty.all(AppColors.background),
        selectedBackgroundColor: MaterialStateProperty.all(AppColors.primary),
      ),
    ),
  );
}
```

**UPDATE:** Build method
```dart
return Column(
  children: [
    _buildCycleFilter(cycles),
    _buildWeekHeader(),
    // ... rest
  ],
);
```

---

### Build #281 Validation Checklist

- [ ] StateNotifierProvider replaces FutureProvider
- [ ] Cache working (check logs for "Cache HIT/MISS")
- [ ] Week navigation <100ms (cached)
- [ ] Week navigation <400ms (uncached)
- [ ] Cycle filter updates calendar immediately
- [ ] Dose update invalidates only affected week
- [ ] Cache hit rate >80% after 3-4 week navigations

**Test Commands:**
```bash
flutter run --profile
# Navigate: Current week → Next week → Previous week → Current week
# Expected: 2nd visit to current week = cache hit (<100ms)
```

---

## Build #282: Tablet/Landscape + Polish

**Goal:** Add responsive layout for tablets, landscape orientation, final optimizations

### Phase 1: Responsive Layout (1.5 hours)

#### 1.1 Add Screen Size Detection

**File:** `lib/utils/responsive.dart` (NEW)

```dart
enum ScreenSize { small, medium, large }

class ResponsiveUtils {
  static ScreenSize getScreenSize(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) return ScreenSize.small;
    if (width < 840) return ScreenSize.medium;
    return ScreenSize.large;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  static double getGridSpacing(ScreenSize size) {
    switch (size) {
      case ScreenSize.small: return 8.0;
      case ScreenSize.medium: return 12.0;
      case ScreenSize.large: return 16.0;
    }
  }

  static double getCellAspectRatio(ScreenSize size) {
    switch (size) {
      case ScreenSize.small: return 0.75;
      case ScreenSize.medium: return 0.85;
      case ScreenSize.large: return 0.95;
    }
  }
}
```

#### 1.2 Make Grid Adaptive

**File:** `lib/screens/calendar_screen.dart`

**MODIFY:** `_buildWeekGrid()`
```dart
Widget _buildWeekGrid(Map<DateTime, List<DoseInstance>> dosesByDate) {
  final screenSize = ResponsiveUtils.getScreenSize(context);
  final spacing = ResponsiveUtils.getGridSpacing(screenSize);
  final aspectRatio = ResponsiveUtils.getCellAspectRatio(screenSize);

  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 7,
      crossAxisSpacing: spacing,
      mainAxisSpacing: spacing,
      childAspectRatio: aspectRatio,
    ),
    // ... rest
  );
}
```

#### 1.3 Add Tablet Landscape Split-View

**ADD:**
```dart
Widget _buildTabletLandscapeLayout(Map<DateTime, List<DoseInstance>> dosesByDate) {
  return Row(
    children: [
      // Left: Calendar (60%)
      Expanded(
        flex: 6,
        child: Column(
          children: [
            _buildCycleFilter(_cycles),
            _buildWeekHeader(),
            _buildWeekGrid(dosesByDate),
            _buildStatusBar(statusCounts),
          ],
        ),
      ),
      
      // Right: Persistent detail pane (40%)
      Expanded(
        flex: 4,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border(left: BorderSide(color: AppColors.primary.withOpacity(0.3))),
          ),
          child: _selectedDate != null
              ? _buildDetailPane(_selectedDate!, dosesByDate[_selectedDate] ?? [])
              : Center(child: Text('Select a date', style: TextStyle(color: AppColors.textMid))),
        ),
      ),
    ],
  );
}

Widget _buildDetailPane(DateTime date, List<DoseInstance> doses) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          DateFormat('EEE, MMM dd').format(date).toUpperCase(),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
      Divider(color: AppColors.primary.withOpacity(0.2)),
      Expanded(
        child: ListView.builder(
          itemCount: doses.length,
          itemBuilder: (context, index) => _buildDoseListItem(doses[index]),
        ),
      ),
    ],
  );
}
```

**MODIFY:** Build method
```dart
Widget build(BuildContext context) {
  final screenSize = ResponsiveUtils.getScreenSize(context);
  final isLandscape = ResponsiveUtils.isLandscape(context);

  if (screenSize == ScreenSize.large && isLandscape) {
    return _buildTabletLandscapeLayout(dosesByDate);
  } else {
    return _buildPhoneLayout(dosesByDate);
  }
}
```

---

### Phase 2: Performance Optimizations (30 min)

#### 2.1 Add Pre-fetching

**File:** `lib/screens/calendar_screen.dart`

```dart
Timer? _prefetchTimer;

@override
void initState() {
  super.initState();
  _schedulePrefetch();
}

void _schedulePrefetch() {
  _prefetchTimer?.cancel();
  _prefetchTimer = Timer(Duration(seconds: 10), () {
    ref.read(calendarProvider.notifier).prefetchNextWeek();
  });
}

@override
void dispose() {
  _prefetchTimer?.cancel();
  super.dispose();
}
```

#### 2.2 Add Cache Eviction

**File:** `lib/providers/calendar_state.dart`

```dart
// ADD to CalendarNotifier (see STATE_MANAGEMENT_REDESIGN.md Section 5.1)
```

---

### Phase 3: Final Polish (1 hour)

#### 3.1 Add Ripple Animations

**File:** `lib/screens/calendar_screen.dart`

```dart
// MODIFY: _buildDayCell() InkWell
InkWell(
  onTap: () => _showDayDetails(date, doses),
  splashColor: AppColors.primary.withOpacity(0.3),
  highlightColor: AppColors.primary.withOpacity(0.1),
  borderRadius: BorderRadius.circular(8),
  child: ...,
)
```

#### 3.2 Add Accessibility Labels

```dart
// WRAP day cells with Semantics
Semantics(
  label: '${DateFormat('EEEE MMMM dd').format(date)}, ${doses.length} doses',
  button: true,
  child: _buildDayCell(date, doses),
)
```

#### 3.3 Add Error Retry

```dart
// MODIFY: Error state
if (calendarState.error != null)
  Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Error: ${calendarState.error}', style: TextStyle(color: AppColors.error)),
        SizedBox(height: 16),
        ElevatedButton(
          onPressed: () {
            ref.read(calendarProvider.notifier).fetchWeek(
              calendarState.currentWeekStart,
              calendarState.selectedCycleId,
            );
          },
          child: Text('RETRY'),
        ),
      ],
    ),
  )
```

---

### Build #282 Validation Checklist

- [ ] Tablet portrait layout scales properly
- [ ] Tablet landscape split-view works
- [ ] Phone landscape layout responsive
- [ ] Pre-fetching works (check logs after 10s)
- [ ] Cache eviction after 10 weeks (test by navigating 11+ weeks)
- [ ] Ripple animations smooth (60fps)
- [ ] Accessibility labels work (test with TalkBack)
- [ ] Error retry button works

**Test Devices:**
- Pixel 4a (phone baseline)
- Samsung Tab S7 (tablet test)

**Test Commands:**
```bash
flutter run --profile -d <device-id>
# Rotate device to landscape
# Check layout adapts
```

---

## Critical Files Summary

| File | Purpose | Builds |
|------|---------|--------|
| `lib/screens/calendar_screen.dart` | Main calendar UI | #280, #281, #282 |
| `lib/services/dose_schedule_service.dart` | Database queries | #280 |
| `lib/providers/calendar_state.dart` | State model + notifier | #281 |
| `lib/providers/calendar_provider.dart` | Riverpod providers | #281 |
| `lib/theme/wintermute_theme.dart` | Material 3 theme | #280 |
| `lib/utils/responsive.dart` | Responsive utilities | #282 |

---

## Testing Strategy

### Unit Tests

**File:** `test/providers/calendar_notifier_test.dart`

```bash
flutter test test/providers/calendar_notifier_test.dart
```

**Coverage:**
- State initialization
- Week navigation
- Cache hit/miss
- Invalidation logic

### Integration Tests

**File:** `integration_test/calendar_navigation_test.dart`

```bash
flutter drive --target=integration_test/calendar_navigation_test.dart
```

**Coverage:**
- Week swipe navigation
- Cycle filter changes
- Bottom sheet interactions
- Tablet split-view

### Performance Tests

**Manual Testing (DevTools):**
1. Open Performance tab
2. Record timeline
3. Navigate 5 weeks forward
4. Check frame times (<16.7ms = 60fps)
5. Check memory usage (<50MB)

**Automated (benchmark):**
```dart
// test/benchmarks/calendar_benchmark.dart
void main() {
  testWidgets('Week navigation performance', (tester) async {
    final stopwatch = Stopwatch()..start();
    
    await tester.pumpWidget(MyApp());
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    
    stopwatch.stop();
    expect(stopwatch.elapsedMilliseconds, lessThan(100)); // <100ms target
  });
}
```

---

## Rollback Plan

### Build #280 Rollback

```bash
git revert <commit-hash>
flutter clean && flutter build apk
```

**Database indexes:** Keep (won't hurt performance)

### Build #281 Rollback

```bash
# Restore upcomingDosesProvider
git checkout main -- lib/services/dose_schedule_service.dart
git checkout main -- lib/screens/calendar_screen.dart
flutter clean && flutter run
```

### Build #282 Rollback

```bash
# Remove responsive utilities
git rm lib/utils/responsive.dart
# Revert calendar_screen.dart
git checkout HEAD~1 -- lib/screens/calendar_screen.dart
flutter clean && flutter run
```

---

## Performance Validation

### Metrics Table

| Metric | Before (#279) | After (#280) | After (#281) | After (#282) | Target |
|--------|---------------|--------------|--------------|--------------|--------|
| Initial load | 1.8s | 500ms | 500ms | 500ms | <500ms |
| Week swipe (cached) | 1.8s | 1.2s | <100ms | <100ms | <100ms |
| Week swipe (uncached) | 1.8s | 1.2s | 400ms | 400ms | <400ms |
| Memory usage | ~12MB | ~8MB | ~5MB | ~5MB | <50MB |
| Scroll frame rate | 45fps | 50fps | 55fps | 60fps | 60fps |
| Database query | 800ms | 120ms | 80ms | 80ms | <100ms |

### Success Criteria (All Builds)

✅ **Database query time <100ms** (verified in Supabase Logs)  
✅ **Week view loads in <500ms** (cold start, no cache)  
✅ **Week swipe <100ms** (cached, 2nd+ visit)  
✅ **Cache hit rate >80%** (after 3-4 navigations)  
✅ **Smooth scrolling** (60fps sustained, no jank)  
✅ **Material Design 3 compliant** (uses Material widgets)  
✅ **Tablet layout works** (split-view in landscape)  
✅ **Memory usage <50MB** (for full week data)

---

## Post-Implementation

### Documentation Updates

- [ ] Update `CHANGELOG.md` with calendar improvements
- [ ] Add screenshots to `README.md` (phone + tablet)
- [ ] Document cache behavior in `ARCHITECTURE.md`

### User-Facing Changes

**Release Notes (Build #282):**

```markdown
## Calendar Optimization (Phase 10C)

🚀 **Performance:**
- 3.6x faster load times (<500ms)
- 18x faster week navigation (cached)
- Smooth 60fps scrolling

🎨 **Design:**
- Material Design 3 week-grid calendar
- Cycle filter dropdown
- Bottom sheet dose details
- Tablet landscape split-view

📊 **Efficiency:**
- Smart caching (80%+ cache hit rate)
- Pre-fetching next week
- Surgical updates (week-level invalidation)
```

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Author:** Wintermute (Subagent)  
**Status:** Ready for Implementation
