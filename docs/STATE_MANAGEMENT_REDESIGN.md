# State Management Redesign - Calendar Efficiency

## Executive Summary

Replace inefficient `FutureProvider` (refetches everything) with **StateNotifierProvider** + caching for surgical updates and <100ms cache hits.

**Key Changes:**
- ❌ Remove: `FutureProvider<List<DoseInstance>>`
- ✅ Add: `StateNotifierProvider<CalendarState>`
- ✅ Add: In-memory cache (week-level granularity)
- ✅ Add: Smart invalidation (only affected weeks)

---

## 1. Current State Management Problems

### 1.1 FutureProvider Issues

**Current Code (dose_schedule_service.dart):**
```dart
final upcomingDosesProvider = FutureProvider<List<DoseInstance>>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return [];

  final service = ref.watch(doseScheduleServiceProvider);
  return service.getUpcomingDoses(userId, daysAhead: 30);
});
```

**Problems:**
1. **Full refetch on any invalidation:** `ref.refresh(upcomingDosesProvider)` re-runs entire query
2. **No granular control:** Can't invalidate just one week or cycle
3. **No caching:** Every navigation = new network request
4. **No optimistic updates:** UI waits for server response
5. **No pre-fetching:** Can't load next week in background

**Impact:**
- User marks dose → 1.8s wait (full query + UI rebuild)
- Swipe to next week → 1.8s wait (full query)
- Return to previous week → 1.8s wait (no cache)

---

## 2. StateNotifierProvider Architecture

### 2.1 State Class Definition

**File:** `lib/providers/calendar_state.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/dose_schedule_service.dart';

// State model
class CalendarState {
  final DateTime currentWeekStart;
  final String? selectedCycleId; // null = "all cycles"
  final Map<String, WeekData> cache;
  final bool isLoading;
  final String? error;

  CalendarState({
    required this.currentWeekStart,
    this.selectedCycleId,
    required this.cache,
    this.isLoading = false,
    this.error,
  });

  CalendarState copyWith({
    DateTime? currentWeekStart,
    String? selectedCycleId,
    bool clearCycleId = false,
    Map<String, WeekData>? cache,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CalendarState(
      currentWeekStart: currentWeekStart ?? this.currentWeekStart,
      selectedCycleId: clearCycleId ? null : (selectedCycleId ?? this.selectedCycleId),
      cache: cache ?? this.cache,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Get cache key for week + cycle
  String _cacheKey(DateTime weekStart, String? cycleId) {
    final weekStr = DateFormat('yyyy-MM-dd').format(weekStart);
    return '$weekStr:${cycleId ?? "all"}';
  }

  // Check if week is cached
  bool hasCachedWeek(DateTime weekStart, String? cycleId) {
    final key = _cacheKey(weekStart, cycleId);
    final cached = cache[key];
    if (cached == null) return false;

    // Check TTL (5 minutes)
    final age = DateTime.now().difference(cached.fetchedAt);
    return age.inMinutes < 5;
  }

  // Get cached week data
  List<DoseInstance>? getCachedWeek(DateTime weekStart, String? cycleId) {
    if (!hasCachedWeek(weekStart, cycleId)) return null;
    final key = _cacheKey(weekStart, cycleId);
    return cache[key]?.doses;
  }

  // Get current week doses (from cache)
  List<DoseInstance> get currentWeekDoses {
    return getCachedWeek(currentWeekStart, selectedCycleId) ?? [];
  }
}

// Cached week data
class WeekData {
  final List<DoseInstance> doses;
  final DateTime fetchedAt;

  WeekData({
    required this.doses,
    required this.fetchedAt,
  });
}
```

### 2.2 StateNotifier Implementation

```dart
class CalendarNotifier extends StateNotifier<CalendarState> {
  final DoseScheduleService _service;
  final String _userId;

  CalendarNotifier(this._service, this._userId)
      : super(CalendarState(
          currentWeekStart: _getWeekStart(DateTime.now()),
          cache: {},
        )) {
    // Auto-load current week on initialization
    fetchWeek(state.currentWeekStart, state.selectedCycleId);
  }

  // Get Monday of current week
  static DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday; // 1 = Monday, 7 = Sunday
    return DateTime(date.year, date.month, date.day)
        .subtract(Duration(days: weekday - 1));
  }

  // Fetch week data (with caching)
  Future<void> fetchWeek(DateTime weekStart, String? cycleId) async {
    // Check cache first
    if (state.hasCachedWeek(weekStart, cycleId)) {
      print('[CALENDAR] Cache HIT for week ${DateFormat('yyyy-MM-dd').format(weekStart)}');
      return; // Already cached, no fetch needed
    }

    print('[CALENDAR] Cache MISS for week ${DateFormat('yyyy-MM-dd').format(weekStart)}, fetching...');

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final doses = await _service.getWeekDoses(
        _userId,
        weekStart: weekStart,
        cycleId: cycleId,
      );

      // Add to cache
      final cacheKey = state._cacheKey(weekStart, cycleId);
      final newCache = Map<String, WeekData>.from(state.cache);
      newCache[cacheKey] = WeekData(
        doses: doses,
        fetchedAt: DateTime.now(),
      );

      state = state.copyWith(
        cache: newCache,
        isLoading: false,
      );

      print('[CALENDAR] Fetched ${doses.length} doses, cache size: ${newCache.length}');
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error loading week: $e',
      );
      print('[CALENDAR ERROR] $e');
    }
  }

  // Navigate to previous week
  Future<void> previousWeek() async {
    final newWeekStart = state.currentWeekStart.subtract(Duration(days: 7));
    state = state.copyWith(currentWeekStart: newWeekStart);
    await fetchWeek(newWeekStart, state.selectedCycleId);
  }

  // Navigate to next week
  Future<void> nextWeek() async {
    final newWeekStart = state.currentWeekStart.add(Duration(days: 7));
    state = state.copyWith(currentWeekStart: newWeekStart);
    await fetchWeek(newWeekStart, state.selectedCycleId);
  }

  // Change cycle filter
  Future<void> setCycleFilter(String? cycleId) async {
    state = state.copyWith(
      selectedCycleId: cycleId,
      clearCycleId: cycleId == null,
    );
    await fetchWeek(state.currentWeekStart, cycleId);
  }

  // Invalidate specific week (after dose update)
  Future<void> invalidateWeek(DateTime weekStart, String? cycleId) async {
    final cacheKey = state._cacheKey(weekStart, cycleId);
    final newCache = Map<String, WeekData>.from(state.cache);
    newCache.remove(cacheKey);

    // Also invalidate "all cycles" view if updating a specific cycle
    if (cycleId != null) {
      final allCyclesKey = state._cacheKey(weekStart, null);
      newCache.remove(allCyclesKey);
    }

    state = state.copyWith(cache: newCache);

    // Refetch if this is the current week
    if (weekStart == state.currentWeekStart) {
      await fetchWeek(weekStart, state.selectedCycleId);
    }

    print('[CALENDAR] Invalidated week $cacheKey');
  }

  // Pre-fetch next week (background)
  Future<void> prefetchNextWeek() async {
    final nextWeekStart = state.currentWeekStart.add(Duration(days: 7));
    if (!state.hasCachedWeek(nextWeekStart, state.selectedCycleId)) {
      print('[CALENDAR] Pre-fetching next week...');
      await fetchWeek(nextWeekStart, state.selectedCycleId);
    }
  }

  // Clear all cache (for logout or manual refresh)
  void clearCache() {
    state = state.copyWith(cache: {});
    print('[CALENDAR] Cache cleared');
  }
}
```

### 2.3 Provider Definition

**File:** `lib/providers/calendar_provider.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/dose_schedule_service.dart';
import 'calendar_state.dart';

// Current user ID
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

// Dose schedule service
final doseScheduleServiceProvider = Provider<DoseScheduleService>((ref) {
  return DoseScheduleService(Supabase.instance.client);
});

// Calendar state notifier
final calendarProvider = StateNotifierProvider<CalendarNotifier, CalendarState>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) {
    throw Exception('User not authenticated');
  }

  final service = ref.watch(doseScheduleServiceProvider);
  return CalendarNotifier(service, userId);
});

// Derived provider: current week doses
final currentWeekDosesProvider = Provider<List<DoseInstance>>((ref) {
  final state = ref.watch(calendarProvider);
  return state.currentWeekDoses;
});

// Derived provider: doses grouped by date
final dosesByDateProvider = Provider<Map<DateTime, List<DoseInstance>>>((ref) {
  final doses = ref.watch(currentWeekDosesProvider);
  final grouped = <DateTime, List<DoseInstance>>{};

  for (final dose in doses) {
    final dateKey = DateTime(dose.date.year, dose.date.month, dose.date.day);
    if (!grouped.containsKey(dateKey)) {
      grouped[dateKey] = [];
    }
    grouped[dateKey]!.add(dose);
  }

  return grouped;
});

// Derived provider: status counts
final statusCountsProvider = Provider<Map<String, int>>((ref) {
  final doses = ref.watch(currentWeekDosesProvider);
  final counts = {'logged': 0, 'pending': 0, 'missed': 0};

  for (final dose in doses) {
    if (dose.status == 'COMPLETED') {
      counts['logged'] = counts['logged']! + 1;
    } else if (dose.status == 'MISSED') {
      counts['missed'] = counts['missed']! + 1;
    } else {
      counts['pending'] = counts['pending']! + 1;
    }
  }

  return counts;
});
```

---

## 3. UI Integration

### 3.1 CalendarScreen Refactor

**Before (FutureProvider):**
```dart
final upcomingDoses = ref.watch(upcomingDosesProvider);

return upcomingDoses.when(
  data: (doses) => _buildCalendar(doses),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
);
```

**After (StateNotifierProvider):**
```dart
final calendarState = ref.watch(calendarProvider);
final dosesByDate = ref.watch(dosesByDateProvider);
final statusCounts = ref.watch(statusCountsProvider);

return Column(
  children: [
    // Cycle filter
    _buildCycleFilter(),
    
    // Week navigation
    _buildWeekNavigation(calendarState.currentWeekStart),
    
    // Week grid
    if (calendarState.isLoading)
      Center(child: CircularProgressIndicator())
    else if (calendarState.error != null)
      Text('Error: ${calendarState.error}')
    else
      _buildWeekGrid(dosesByDate),
    
    // Status bar
    _buildStatusBar(statusCounts),
  ],
);
```

### 3.2 Navigation Actions

```dart
// Previous week
IconButton(
  icon: Icon(Icons.chevron_left),
  onPressed: () {
    ref.read(calendarProvider.notifier).previousWeek();
  },
)

// Next week
IconButton(
  icon: Icon(Icons.chevron_right),
  onPressed: () {
    ref.read(calendarProvider.notifier).nextWeek();
  },
)
```

### 3.3 Cycle Filter

```dart
SegmentedButton<String>(
  segments: [
    ButtonSegment(value: 'all', label: Text('ALL CYCLES')),
    ...cycles.map((c) => ButtonSegment(value: c.id, label: Text(c.name))),
  ],
  selected: {calendarState.selectedCycleId ?? 'all'},
  onSelectionChanged: (Set<String> newSelection) {
    final cycleId = newSelection.first == 'all' ? null : newSelection.first;
    ref.read(calendarProvider.notifier).setCycleFilter(cycleId);
  },
)
```

### 3.4 Dose Update (Invalidation)

```dart
Future<void> _markDoseComplete(DoseInstance dose) async {
  await doseLogsService.markComplete(dose.doseLogId);
  
  // Invalidate affected week
  final weekStart = CalendarNotifier._getWeekStart(dose.date);
  ref.read(calendarProvider.notifier).invalidateWeek(
    weekStart,
    dose.cycleId,
  );
}
```

---

## 4. Service Layer Changes

### 4.1 New Method: getWeekDoses

**Add to `DoseScheduleService`:**

```dart
Future<List<DoseInstance>> getWeekDoses(
  String userId, {
  DateTime? weekStart,
  String? cycleId,
}) async {
  try {
    final start = weekStart ?? _getWeekStart(DateTime.now());
    final end = start.add(Duration(days: 7));

    print('[SERVICE] Fetching week: ${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('yyyy-MM-dd').format(end)}');

    // Build query
    var query = _supabase
        .from('dose_logs')
        .select()
        .eq('user_id', userId)
        .gte('logged_at', start.toIso8601String())
        .lt('logged_at', end.toIso8601String());

    // Add cycle filter if specified
    if (cycleId != null) {
      query = query.eq('cycle_id', cycleId);
    }

    final doseLogs = await query.order('logged_at', ascending: true);

    print('[SERVICE] Fetched ${(doseLogs as List).length} dose_logs');

    // Convert to DoseInstance (similar to getUpcomingDoses logic)
    final instances = <DoseInstance>[];
    // ... conversion logic ...

    return instances;
  } catch (e) {
    print('[SERVICE ERROR] Error fetching week doses: $e');
    return [];
  }
}

DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return DateTime(date.year, date.month, date.day)
      .subtract(Duration(days: weekday - 1));
}
```

---

## 5. Cache Performance Optimization

### 5.1 Cache Size Management

**Problem:** Unbounded cache grows indefinitely

**Solution:** LRU eviction after 10 weeks

```dart
class CalendarNotifier extends StateNotifier<CalendarState> {
  static const int maxCacheWeeks = 10;

  void _evictOldCache() {
    if (state.cache.length <= maxCacheWeeks) return;

    // Sort by fetchedAt, remove oldest
    final sortedKeys = state.cache.entries.toList()
      ..sort((a, b) => a.value.fetchedAt.compareTo(b.value.fetchedAt));

    final newCache = Map<String, WeekData>.from(state.cache);
    final toRemove = sortedKeys.length - maxCacheWeeks;

    for (int i = 0; i < toRemove; i++) {
      newCache.remove(sortedKeys[i].key);
    }

    state = state.copyWith(cache: newCache);
    print('[CALENDAR] Evicted ${toRemove} old weeks from cache');
  }

  Future<void> fetchWeek(...) async {
    // ... existing fetch logic ...

    _evictOldCache(); // Run after successful fetch
  }
}
```

### 5.2 Background Pre-fetching

**Trigger:** After user stays on week for 10 seconds

```dart
class CalendarScreen extends ConsumerStatefulWidget {
  // ...
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
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
}
```

### 5.3 Real-time Updates (Supabase Realtime)

**Optional:** Listen to dose_logs changes

```dart
class CalendarNotifier extends StateNotifier<CalendarState> {
  RealtimeChannel? _realtimeChannel;

  void _subscribeToRealtimeUpdates() {
    _realtimeChannel = Supabase.instance.client
        .channel('dose_logs_changes')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'UPDATE',
            schema: 'public',
            table: 'dose_logs',
          ),
          (payload, [ref]) {
            // Extract updated dose
            final updatedDose = payload['new'] as Map<String, dynamic>;
            final loggedAt = DateTime.parse(updatedDose['logged_at']);
            final cycleId = updatedDose['cycle_id'] as String;

            // Invalidate affected week
            final weekStart = _getWeekStart(loggedAt);
            invalidateWeek(weekStart, cycleId);
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }
}
```

---

## 6. Testing Strategy

### 6.1 Unit Tests

**File:** `test/providers/calendar_notifier_test.dart`

```dart
void main() {
  late MockDoseScheduleService mockService;
  late CalendarNotifier notifier;

  setUp(() {
    mockService = MockDoseScheduleService();
    notifier = CalendarNotifier(mockService, 'test-user-id');
  });

  test('initial state has current week', () {
    final weekStart = CalendarNotifier._getWeekStart(DateTime.now());
    expect(notifier.state.currentWeekStart, weekStart);
  });

  test('fetchWeek adds to cache', () async {
    when(mockService.getWeekDoses(any, weekStart: any, cycleId: any))
        .thenAnswer((_) async => [/* mock doses */]);

    await notifier.fetchWeek(DateTime(2026, 3, 10), null);

    expect(notifier.state.cache.length, 1);
    expect(notifier.state.hasCachedWeek(DateTime(2026, 3, 10), null), true);
  });

  test('cache hit skips network request', () async {
    // Pre-populate cache
    final weekStart = DateTime(2026, 3, 10);
    notifier.state = notifier.state.copyWith(
      cache: {
        notifier.state._cacheKey(weekStart, null): WeekData(
          doses: [],
          fetchedAt: DateTime.now(),
        ),
      },
    );

    await notifier.fetchWeek(weekStart, null);

    verifyNever(mockService.getWeekDoses(any, weekStart: any, cycleId: any));
  });

  test('invalidateWeek removes from cache', () async {
    // Pre-populate cache
    final weekStart = DateTime(2026, 3, 10);
    notifier.state = notifier.state.copyWith(
      cache: {
        notifier.state._cacheKey(weekStart, null): WeekData(
          doses: [],
          fetchedAt: DateTime.now(),
        ),
      },
    );

    await notifier.invalidateWeek(weekStart, null);

    expect(notifier.state.cache.isEmpty, true);
  });
}
```

### 6.2 Integration Tests

**File:** `integration_test/calendar_navigation_test.dart`

```dart
void main() {
  testWidgets('week navigation updates calendar', (tester) async {
    await tester.pumpWidget(MyApp());

    // Find next week button
    final nextButton = find.byIcon(Icons.chevron_right);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // Verify week changed
    expect(find.text('MAR 17-23, 2026'), findsOneWidget);
  });

  testWidgets('cycle filter updates doses', (tester) async {
    await tester.pumpWidget(MyApp());

    // Tap cycle filter
    final cycleButton = find.text('CYCLE 1');
    await tester.tap(cycleButton);
    await tester.pumpAndSettle();

    // Verify filtered doses (fewer than "All Cycles")
    // ... verify dose count ...
  });
}
```

---

## 7. Performance Metrics

### 7.1 Cache Hit Rate

**Target:** >80% cache hits after first week

**Measurement:**
```dart
class CacheMetrics {
  static int hits = 0;
  static int misses = 0;

  static double get hitRate {
    final total = hits + misses;
    return total == 0 ? 0 : hits / total;
  }

  static void recordHit() {
    hits++;
    print('[CACHE METRICS] Hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
  }

  static void recordMiss() {
    misses++;
    print('[CACHE METRICS] Hit rate: ${(hitRate * 100).toStringAsFixed(1)}%');
  }
}
```

### 7.2 Load Time Comparison

| Action | Before (FutureProvider) | After (StateNotifier + Cache) | Improvement |
|--------|------------------------|-------------------------------|-------------|
| Initial load | ~1.8s | ~500ms | 3.6x faster |
| Week swipe (cached) | ~1.8s | <100ms | 18x faster |
| Week swipe (uncached) | ~1.8s | ~400ms | 4.5x faster |
| Dose update | ~1.8s (full refetch) | ~100ms (invalidate + refetch week) | 18x faster |
| Cycle filter change | ~1.8s | ~200ms (if cached) | 9x faster |

---

## 8. Migration Plan

### Step 1: Add New Providers (Non-Breaking)
```bash
git checkout -b calendar-state-management
mkdir -p lib/providers
touch lib/providers/calendar_state.dart
touch lib/providers/calendar_provider.dart
```

### Step 2: Update Service
```dart
// Add getWeekDoses() method to DoseScheduleService
// Keep getUpcomingDoses() for backward compatibility
```

### Step 3: Refactor CalendarScreen
```dart
// Replace upcomingDosesProvider with calendarProvider
// Update all ref.watch() calls
```

### Step 4: Test & Validate
```bash
flutter test
flutter run --profile
# Measure performance with DevTools
```

### Step 5: Remove Old Code
```dart
// Delete upcomingDosesProvider
// Remove getUpcomingDoses() if unused elsewhere
```

---

## 9. Success Criteria

✅ **Cache hit rate >80%** for week navigation  
✅ **Week swipe <100ms** (cached)  
✅ **Week swipe <400ms** (uncached)  
✅ **Dose update <100ms** (invalidate + refetch)  
✅ **Memory usage <10MB** for cache (10 weeks × ~84 doses × ~1KB = ~840KB)  
✅ **Zero jank during navigation** (60fps sustained)

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Author:** Wintermute (Subagent)  
**Status:** Ready for Implementation
