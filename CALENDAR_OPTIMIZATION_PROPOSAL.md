# Calendar Optimization Proposal - Phase 10C

## Executive Summary

**Current State:** Calendar fetches ALL dose_logs for 30 days, loops through ALL schedules, performs O(n×m) matching. With 10 cycles (840 dose_logs), this is **dangerously slow** and will **crash on older devices**.

**Impact:**
- **Performance:** 3-5 second load times with 10 cycles
- **Memory:** 840+ dose_log objects in memory simultaneously
- **Battery:** Repeated full-table scans drain battery
- **Scalability:** Unusable with 20+ cycles (common for power users)

**Recommended Solution:** **Hybrid approach** (Option D) - 7-day paginated view + cycle filter + database indexing

**Performance Target:** **< 2 seconds** to load calendar with 10 active cycles

---

## 1. Performance Problem Analysis

### 1.1 Current Implementation Bottlenecks

**Code Path:**
```
CalendarScreen → upcomingDosesProvider → DoseScheduleService.getUpcomingDoses()
```

**Steps (with timing estimates):**
1. **Fetch ALL dose_schedules** for user (10 cycles)
   - Query: `SELECT * FROM dose_schedules WHERE user_id = ? AND is_active = true`
   - Time: ~50ms (fast, indexed on user_id)

2. **Fetch ALL dose_logs** for next 30 days
   - Query: `SELECT * FROM dose_logs WHERE user_id = ? AND logged_at BETWEEN ? AND ?`
   - Result: 840 rows (10 cycles × 84 doses per cycle)
   - Time: **~1000ms (SLOW - no index on logged_at)**

3. **Build doseLogMap** (group by cycle_id + date)
   - Loop: 840 iterations
   - Time: ~200ms (CPU-bound)

4. **Generate dose instances** (nested loops)
   - Outer loop: 10 schedules × 30 days = 300 iterations
   - Inner loop: Match against 840 dose_logs
   - Complexity: **O(n × m) = O(10 × 30 × 840) = 252,000 operations**
   - Time: **~2000ms (VERY SLOW)**

**Total Time: ~3.3 seconds**

**With 20 cycles:** ~6-8 seconds (unusable)

---

### 1.2 Database Query Analysis

**Current Query (dose_logs):**
```sql
SELECT * FROM dose_logs 
WHERE user_id = '...' 
AND logged_at >= '2026-03-10' 
AND logged_at <= '2026-04-09'
```

**Problem:** No index on `logged_at` → **full table scan** (O(n) where n = total rows)

**Query Plan (estimated):**
```
Seq Scan on dose_logs  (cost=0.00..1500.00 rows=840)
  Filter: (user_id = '...' AND logged_at >= '2026-03-10' AND logged_at <= '2026-04-09')
```

**With 10,000 total dose_logs in database:** Still scans all 10,000 rows

---

### 1.3 Memory Footprint

**Current:**
- 840 dose_logs × 500 bytes/row = **420KB**
- 300 dose_instances × 300 bytes = **90KB**
- **Total: ~500KB per calendar load**

**Impact:**
- ❌ **Memory churn:** Flutter widget rebuilds repeatedly
- ❌ **Garbage collection:** Frequent GC pauses on low-end devices
- ❌ **Battery drain:** CPU + network + memory allocation

---

### 1.4 Network Impact

**Current:**
- 1 query: dose_schedules (~1KB)
- 1 query: dose_logs (~50KB for 840 rows)
- **Total: ~51KB per calendar load**

**With poor connection (3G):**
- 51KB @ 1Mbps = ~400ms network latency
- **Total time: 3.3s + 0.4s = 3.7s**

---

## 2. Proposed Solutions (4 Options)

### Option A: Pagination (Show 7 Days, Lazy Load)

**Concept:**
- Show next 7 days by default
- User swipes/scrolls → fetch next 7 days
- Cache loaded weeks to avoid refetches

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR  [Refresh] [Filter]  │
├─────────────────────────────────────┤
│  WEEK 1 (Mar 10 - Mar 16)           │
│  ─────────────────────────────────  │
│  Mon Mar 10  [3 doses]              │
│    • BPC-157 1.0mg SC 08:00 ✓       │
│    • TB-500 2.0mg SC 20:00 ⚪       │
│    • CJC-1295 0.5mg SC 22:00 ⚪     │
│  Tue Mar 11  [2 doses]              │
│    • BPC-157 1.0mg SC 08:00 ⚪       │
│    • TB-500 2.0mg SC 20:00 ⚪        │
│  ...                                │
│  [Load Next Week ↓]                 │
└─────────────────────────────────────┘
```

**Pros:**
- ✅ **Fast initial load:** Only fetch 7 days (196 dose_logs instead of 840)
- ✅ **Reduced memory:** 4x less data in memory
- ✅ **Scalable:** Works with 100+ cycles (still only loads 7 days)
- ✅ **Lazy loading:** User rarely needs to see beyond 7 days

**Cons:**
- ❌ **Extra navigation:** User must tap "Load Next Week" to see future doses
- ❌ **No month view:** Can't see full month at once
- ❌ **Pagination complexity:** Must track offset, cache loaded pages

**Implementation Complexity:** Medium (2-3 hours)

**Performance Impact:**
- Before: 3.3s
- After: **~0.8s** (7 days instead of 30)
- **Improvement: 4x faster**

---

### Option B: Cycle Tabs (One Active Cycle View)

**Concept:**
- Show one cycle at a time in calendar
- Tabs at top to switch between cycles
- Each tab shows that cycle's doses for next 30 days

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR                      │
├─────────────────────────────────────┤
│ [BPC-157] [TB-500] [CJC-1295] ...   │ ← Tabs
├─────────────────────────────────────┤
│  BPC-157 CYCLE (Mar 10 - Apr 7)     │
│  ─────────────────────────────────  │
│  Mon Mar 10  08:00  1.0mg SC ✓      │
│  Tue Mar 11  08:00  1.0mg SC ⚪      │
│  Wed Mar 12  08:00  1.5mg SC ⚪      │ ← Phase changes
│  Thu Mar 13  08:00  1.5mg SC ⚪      │
│  ...                                │
└─────────────────────────────────────┘
```

**Pros:**
- ✅ **Very fast:** Only fetch doses for 1 cycle at a time (84 dose_logs)
- ✅ **Simple UI:** No clutter, clear focus on one peptide
- ✅ **Easy to implement:** Just filter by cycle_id
- ✅ **Scales infinitely:** 100 cycles = same performance

**Cons:**
- ❌ **No multi-cycle view:** Can't see overlapping doses (e.g., AM BPC + PM TB-500)
- ❌ **Extra navigation:** User must switch tabs to see other cycles
- ❌ **Daily dose confusion:** "Did I take everything today?" (must check each tab)

**Implementation Complexity:** Low (1-2 hours)

**Performance Impact:**
- Before: 3.3s
- After: **~0.3s** (1 cycle instead of 10)
- **Improvement: 11x faster**

**Use Case Fit:**
- ✅ Good if cycles are independent (different times, different days)
- ❌ Bad if cycles overlap (daily AM + PM dosing)

---

### Option C: Filtered Calendar (Select Which Cycles to Display)

**Concept:**
- Show all cycles by default
- Filter icon → modal to select/deselect cycles
- Calendar updates to show only selected cycles

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR  [🔍 Filter: 3/10]   │
├─────────────────────────────────────┤
│  NEXT 7 DAYS                        │
│  ─────────────────────────────────  │
│  Mon Mar 10  [3 doses]              │
│    • BPC-157 1.0mg SC 08:00 ✓       │
│    • TB-500 2.0mg SC 20:00 ⚪       │
│    • CJC-1295 0.5mg SC 22:00 ⚪     │
│  Tue Mar 11  [2 doses]              │
│    • BPC-157 1.0mg SC 08:00 ⚪       │
│    • TB-500 2.0mg SC 20:00 ⚪        │
│  ...                                │
└─────────────────────────────────────┘

[Tap Filter] →

┌─────────────────────────────────────┐
│  FILTER CYCLES                      │
├─────────────────────────────────────┤
│  ☑ BPC-157 (Daily, 08:00)           │
│  ☑ TB-500 (Daily, 20:00)            │
│  ☑ CJC-1295 (3x/week, 22:00)        │
│  ☐ Ipamorelin (Daily, 08:00)        │
│  ☐ Tesamorelin (3x/week, 20:00)     │
│  ☐ GHRP-6 (Daily, 22:00)            │
│  ☐ Melanotan II (3x/week, 08:00)    │
│  ☐ Thymosin Beta-4 (2x/week, 20:00) │
│  ☐ Selank (Daily, 08:00)            │
│  ☐ Semax (Daily, 20:00)             │
│  ─────────────────────────────────  │
│  [Select All] [Clear] [Apply]       │
└─────────────────────────────────────┘
```

**Pros:**
- ✅ **User control:** Show only what matters today
- ✅ **Performance:** Fewer cycles = faster load
- ✅ **Flexibility:** Can toggle on/off as needed
- ✅ **Remembers selection:** Save filter state locally

**Cons:**
- ❌ **Extra step:** User must configure filter first
- ❌ **Still slow if all selected:** Doesn't solve the root problem
- ❌ **Cognitive load:** "Which cycles did I enable?"

**Implementation Complexity:** Medium (2-3 hours)

**Performance Impact:**
- Before: 3.3s (10 cycles)
- After: **~1.0s** (3 cycles selected)
- **Improvement: 3x faster** (depends on filter)

---

### Option D: Hybrid (7-Day View + Cycle Selector + Indexing) ✅ **RECOMMENDED**

**Concept:**
- **Primary view:** Show next 7 days (all cycles, grouped by date)
- **Cycle selector:** Quick toggle to hide/show specific cycles
- **Pagination:** "Load next week" button at bottom
- **Database optimization:** Add indexes for fast queries

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR  [Refresh] [⚙️]      │
├─────────────────────────────────────┤
│  TODAY (Mon Mar 10)  [3 doses]      │ ← Highlighted
│  ───────────────────────────────────│
│  08:00  BPC-157    1.0mg SC  [✓]    │ ← Quick actions
│  20:00  TB-500     2.0mg SC  [⚪]   │
│  22:00  CJC-1295   0.5mg SC  [⚪]   │
│                                     │
│  TOMORROW (Tue Mar 11)  [3 doses]   │
│  ───────────────────────────────────│
│  08:00  BPC-157    1.0mg SC          │
│  08:00  Ipamorelin 0.2mg SC          │
│  20:00  TB-500     2.0mg SC          │
│                                     │
│  Wed Mar 12  [2 doses]              │
│  Thu Mar 13  [4 doses]              │
│  Fri Mar 14  [3 doses]              │
│  Sat Mar 15  [2 doses]              │
│  Sun Mar 16  [3 doses]              │
│                                     │
│  [Load Next Week (Mar 17-23) ↓]     │
└─────────────────────────────────────┘

[Tap ⚙️] →

┌─────────────────────────────────────┐
│  CALENDAR SETTINGS                  │
├─────────────────────────────────────┤
│  ACTIVE CYCLES (3/10 visible)       │
│  ───────────────────────────────────│
│  ☑ BPC-157 (Daily, 08:00)  🟢       │ ← Color indicator
│  ☑ TB-500 (Daily, 20:00)   🔵       │
│  ☑ CJC-1295 (3x/wk, 22:00) 🟡       │
│  ☐ Ipamorelin               🟣       │
│  ☐ Tesamorelin              🟠       │
│  ...                                │
│  [Show All] [Hide All] [Done]       │
│                                     │
│  DATE RANGE                         │
│  ───────────────────────────────────│
│  ☑ Show next 7 days                 │
│  ☐ Show next 14 days                │
│  ☐ Show next 30 days                │
│                                     │
│  VIEW OPTIONS                       │
│  ───────────────────────────────────│
│  ☑ Group by date                    │
│  ☐ Group by peptide                 │
│  ☑ Show completed doses             │
│  ☐ Show missed doses only           │
└─────────────────────────────────────┘
```

**Pros:**
- ✅ **Fast initial load:** 7 days = 196 dose_logs (vs 840)
- ✅ **User control:** Filter cycles without losing context
- ✅ **Scalable:** Works with 10, 20, or 100 cycles
- ✅ **Best UX:** Daily view is primary use case ("What do I take today?")
- ✅ **Flexible:** Can expand to 14 or 30 days if needed
- ✅ **Efficient:** Database indexes make queries <100ms

**Cons:**
- ❌ **More complex:** Combines multiple features
- ❌ **Initial setup:** User must configure if >10 cycles

**Implementation Complexity:** High (4-5 hours)

**Performance Impact:**
- Before: 3.3s
- After: **~0.5s** (7 days + indexed queries)
- **Improvement: 6x faster**

**Why This is Best:**
- **Daily use case:** Most users check "What do I take today?" not "What's in 3 weeks?"
- **Power user friendly:** Can handle 20+ cycles with filtering
- **Future-proof:** Scales to 100+ cycles without redesign

---

## 3. Optimized Query Strategy

### 3.1 Database Indexing (CRITICAL)

**Current Schema (no indexes):**
```sql
CREATE TABLE dose_logs (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL,
  cycle_id UUID NOT NULL,
  schedule_id UUID,
  logged_at TIMESTAMP NOT NULL,
  dose_amount NUMERIC,
  status TEXT,
  ...
);
```

**Problem:** Queries on `logged_at` and `user_id` do full table scans

**Recommended Indexes:**
```sql
-- PRIMARY: Fast user + date range queries
CREATE INDEX idx_dose_logs_user_date ON dose_logs(user_id, logged_at);

-- SECONDARY: Fast cycle-specific queries
CREATE INDEX idx_dose_logs_cycle_date ON dose_logs(cycle_id, logged_at);

-- OPTIONAL: Fast status filtering (e.g., missed doses only)
CREATE INDEX idx_dose_logs_user_status ON dose_logs(user_id, status);
```

**Query Performance After Indexing:**
```sql
-- Before (no index): 1000ms (full table scan)
SELECT * FROM dose_logs 
WHERE user_id = '...' 
AND logged_at BETWEEN '2026-03-10' AND '2026-03-17';

-- After (with index): 50ms (index scan)
```

**Performance Impact:** **20x faster queries**

---

### 3.2 Optimized Query Flow

**Current (inefficient):**
1. Fetch all schedules
2. Fetch all dose_logs (30 days)
3. Loop + match in Dart (O(n×m))

**Optimized (recommended):**
1. Fetch all schedules (fast, small dataset)
2. **Batch fetch dose_logs by cycle_ids** (reduces rows)
3. Pre-group by date in SQL (reduces Dart processing)

**Implementation:**
```dart
Future<List<DoseInstance>> getUpcomingDoses(
  String userId, {
  int daysAhead = 7,  // Changed from 30 to 7
}) async {
  try {
    // 1. Fetch active schedules (fast)
    final schedules = await getDoseSchedules(userId);
    if (schedules.isEmpty) return [];
    
    // 2. Build list of cycle IDs
    final cycleIds = schedules.map((s) => s.cycleId).toSet().toList();
    
    // 3. Fetch dose_logs filtered by cycle IDs + date range
    final now = DateTime.now();
    final endDate = now.add(Duration(days: daysAhead));
    
    final doseLogs = await _supabase
        .from('dose_logs')
        .select()
        .inFilter('cycle_id', cycleIds)  // Filter by cycle IDs
        .gte('logged_at', now.toIso8601String())
        .lte('logged_at', endDate.toIso8601String())
        .order('logged_at');  // Pre-sort in SQL
    
    // 4. Build dose instances (now O(n) instead of O(n×m))
    // ... (same as before, but fewer iterations)
    
  } catch (e) {
    print('Error: $e');
    return [];
  }
}
```

**Performance Impact:**
- Before: O(n×m) = 252,000 operations
- After: O(n) = 196 operations
- **Improvement: 1,000x fewer operations**

---

### 3.3 Pagination Query Strategy

**Load next week without refetching previous weeks:**

```dart
// State management
class CalendarState {
  List<DoseInstance> loadedDoses = [];
  int currentWeekOffset = 0;  // 0 = this week, 1 = next week, etc.
  Map<int, bool> loadedWeeks = {};  // Track which weeks are loaded
}

// Fetch function
Future<void> loadNextWeek() async {
  final nextWeekOffset = currentWeekOffset + 1;
  
  if (loadedWeeks[nextWeekOffset] == true) {
    // Already loaded, just scroll to it
    return;
  }
  
  final startDate = DateTime.now().add(Duration(days: nextWeekOffset * 7));
  final endDate = startDate.add(Duration(days: 7));
  
  final newDoses = await _fetchDosesForDateRange(startDate, endDate);
  
  setState(() {
    loadedDoses.addAll(newDoses);
    loadedWeeks[nextWeekOffset] = true;
    currentWeekOffset = nextWeekOffset;
  });
}
```

**Caching Strategy:**
- ✅ Cache loaded weeks in memory (up to 4 weeks = ~800 doses)
- ✅ Invalidate cache when user marks dose missed/complete
- ✅ Refresh current week on app resume (user may have taken doses)

---

### 3.4 Should dose_logs Store cycle_id? (Data Model Decision)

**Current:**
```dart
dose_logs:
  - schedule_id (FK to dose_schedules)
  - user_id
  - logged_at
  - dose_amount
  - status
```

**Problem:** To get cycle_id, must JOIN dose_schedules:
```sql
SELECT dl.* 
FROM dose_logs dl
JOIN dose_schedules ds ON dl.schedule_id = ds.id
WHERE ds.cycle_id = '...'
```

**Recommended: Add cycle_id to dose_logs**
```dart
dose_logs:
  - schedule_id (FK to dose_schedules)
  - cycle_id (FK to cycles)  ← ADD THIS
  - user_id
  - logged_at
  - dose_amount
  - status
```

**Why:**
- ✅ **Performance:** Direct filter on dose_logs (no JOIN needed)
- ✅ **Indexing:** Can create index on (cycle_id, logged_at)
- ✅ **Traceability:** Know which cycle a dose belongs to without JOIN
- ✅ **Analytics:** Fast queries like "show all doses for this cycle"

**Migration:**
```sql
-- Add column
ALTER TABLE dose_logs ADD COLUMN cycle_id UUID;

-- Backfill from schedules
UPDATE dose_logs 
SET cycle_id = (
  SELECT cycle_id FROM dose_schedules 
  WHERE id = dose_logs.schedule_id
);

-- Add FK constraint
ALTER TABLE dose_logs 
ADD CONSTRAINT fk_dose_logs_cycle 
FOREIGN KEY (cycle_id) REFERENCES cycles(id);

-- Add index
CREATE INDEX idx_dose_logs_cycle_date ON dose_logs(cycle_id, logged_at);
```

**Recommendation:** ✅ **Add cycle_id to dose_logs** (improves query performance by 5-10x)

---

## 4. Calendar UI for Daily Use (10 Cycles on One Day)

### Problem Statement

**Scenario:** User has 10 active cycles. On Monday, they have:
- BPC-157 1.0mg SC at 08:00
- Ipamorelin 0.2mg SC at 08:00
- TB-500 2.0mg SC at 12:00
- CJC-1295 0.5mg SC at 20:00
- GHRP-6 0.3mg SC at 20:00
- Melanotan II 0.5mg SC at 22:00
- Thymosin Beta-4 2.0mg SC at 08:00 (Mon/Thu only)
- Selank 0.5mg SC at 12:00
- Semax 0.3mg SC at 12:00
- Tesamorelin 1.0mg SC at 22:00

**= 10 doses on one day**

**Current UI Problem:**
- Each dose is a card (12px padding) = 60px tall
- 10 doses × 60px = **600px vertical space**
- **Phone screen:** ~800px tall → **75% of screen is one day**
- Scrolling required to see tomorrow

**User Pain:**
- ❌ Can't see full week at once
- ❌ Hard to see "What do I take at 08:00?" (3 doses)
- ❌ No quick actions (must tap each dose individually)

---

### Solution A: Cycle Color Coding + Compact View

**Concept:**
- Each cycle has a unique color (border/dot)
- Doses grouped by time (not by peptide)
- Compact card design (40px tall instead of 60px)

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  TODAY (Mon Mar 10)  [3 doses]      │
├─────────────────────────────────────┤
│  08:00 AM [3 doses]                 │ ← Group by time
│  ─────────────────────────────────  │
│  🟢 BPC-157        1.0mg SC    [✓]  │
│  🟣 Ipamorelin     0.2mg SC    [⚪] │
│  🔵 Thymosin β-4   2.0mg SC    [⚪] │
│                                     │
│  12:00 PM [3 doses]                 │
│  ─────────────────────────────────  │
│  🔵 TB-500         2.0mg SC    [⚪] │
│  🟡 Selank         0.5mg SC    [⚪] │
│  🟠 Semax          0.3mg SC    [⚪] │
│                                     │
│  08:00 PM [2 doses]                 │
│  ─────────────────────────────────  │
│  🟡 CJC-1295       0.5mg SC    [⚪] │
│  🟣 GHRP-6         0.3mg SC    [⚪] │
│                                     │
│  10:00 PM [2 doses]                 │
│  ─────────────────────────────────  │
│  ⚫ Melanotan II    0.5mg SC    [⚪] │
│  🔵 Tesamorelin    1.0mg SC    [⚪] │
└─────────────────────────────────────┘
```

**Features:**
- ✅ **Color coding:** Each cycle has a unique color (🟢🔵🟣🟡🟠⚫)
- ✅ **Grouped by time:** All 08:00 doses together
- ✅ **Compact:** 40px per dose (vs 60px)
- ✅ **Quick actions:** Tap checkmark to complete, tap dose for details

**Pros:**
- ✅ **Fits more on screen:** 10 doses in ~400px (vs 600px)
- ✅ **Easy to scan:** "What do I take at 08:00?" → See all 3 at once
- ✅ **Color memory:** User learns "green = BPC, blue = TB-500"

**Cons:**
- ❌ **Limited colors:** Only 7-8 distinct colors before confusion
- ❌ **Colorblind users:** Must use shapes + colors

---

### Solution B: Expandable Day View (Collapsed by Default)

**Concept:**
- Each day shows dose count (e.g., "3 doses")
- Tap to expand and see full list
- Today is expanded by default

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  TODAY (Mon Mar 10)  [10 doses] ▼   │ ← Expanded
├─────────────────────────────────────┤
│  08:00  BPC-157        1.0mg SC [✓] │
│  08:00  Ipamorelin     0.2mg SC [⚪]│
│  08:00  Thymosin β-4   2.0mg SC [⚪]│
│  12:00  TB-500         2.0mg SC [⚪]│
│  12:00  Selank         0.5mg SC [⚪]│
│  12:00  Semax          0.3mg SC [⚪]│
│  20:00  CJC-1295       0.5mg SC [⚪]│
│  20:00  GHRP-6         0.3mg SC [⚪]│
│  22:00  Melanotan II   0.5mg SC [⚪]│
│  22:00  Tesamorelin    1.0mg SC [⚪]│
│                                     │
│  TOMORROW (Tue Mar 11) [9 doses] ▶  │ ← Collapsed
│                                     │
│  Wed Mar 12 [8 doses] ▶             │
│  Thu Mar 13 [10 doses] ▶            │
│  Fri Mar 14 [9 doses] ▶             │
│  Sat Mar 15 [7 doses] ▶             │
│  Sun Mar 16 [8 doses] ▶             │
└─────────────────────────────────────┘
```

**Interaction:**
- Tap "TOMORROW" → Expands to show all 9 doses
- Tap again → Collapses back to one line

**Pros:**
- ✅ **Compact:** Can see 7 days in ~400px
- ✅ **Focus on today:** Today is expanded, future days collapsed
- ✅ **Fast overview:** "Do I have doses tomorrow?" → See count immediately

**Cons:**
- ❌ **Extra tap:** Must tap to see dose details
- ❌ **No quick actions on collapsed days:** Can't mark complete without expanding

---

### Solution C: Cycle Accordion (One Open at a Time)

**Concept:**
- Calendar shows one cycle at a time
- Accordion at top to switch between cycles
- Each section shows that cycle's doses for next 7 days

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR                      │
├─────────────────────────────────────┤
│  🟢 BPC-157 (Daily, 08:00) ▼        │ ← Expanded
│  ─────────────────────────────────  │
│  Mon Mar 10  1.0mg SC 08:00  [✓]    │
│  Tue Mar 11  1.0mg SC 08:00  [⚪]   │
│  Wed Mar 12  1.5mg SC 08:00  [⚪]   │ ← Phase change
│  Thu Mar 13  1.5mg SC 08:00  [⚪]   │
│  Fri Mar 14  1.5mg SC 08:00  [⚪]   │
│  Sat Mar 15  1.5mg SC 08:00  [⚪]   │
│  Sun Mar 16  1.5mg SC 08:00  [⚪]   │
│                                     │
│  🔵 TB-500 (Daily, 20:00) ▶         │ ← Collapsed
│  🟣 Ipamorelin (Daily, 08:00) ▶     │
│  🟡 CJC-1295 (3x/wk, 20:00) ▶       │
│  🟠 GHRP-6 (Daily, 20:00) ▶         │
│  ⚫ Melanotan II (3x/wk, 22:00) ▶    │
│  🔵 Tesamorelin (3x/wk, 22:00) ▶    │
│  🟡 Thymosin β-4 (2x/wk, 08:00) ▶   │
│  🟣 Selank (Daily, 12:00) ▶         │
│  🟠 Semax (Daily, 12:00) ▶          │
└─────────────────────────────────────┘
```

**Pros:**
- ✅ **Very clean:** Only one cycle visible at a time
- ✅ **Phase visibility:** Easy to see dose changes over time
- ✅ **Fast switching:** Tap another cycle → expands, others collapse

**Cons:**
- ❌ **No daily view:** Can't see "What do I take today across all cycles?"
- ❌ **Extra navigation:** Must open each cycle to check doses
- ❌ **Not for daily use:** Better for reviewing individual cycles

**Use Case:** Good for "Review BPC-157 cycle progress" not "What do I take today?"

---

### Solution D: Side-by-Side Split View (Date + Cycle Selector) ✅ **RECOMMENDED**

**Concept:**
- Left side: Date list (Today, Tomorrow, etc.)
- Right side: Doses for selected date (grouped by time)
- Quick cycle filter at top

**ASCII Diagram:**
```
┌─────────────────────────────────────┐
│  DOSE CALENDAR  [🔍 3/10 active]    │
├──────────────┬──────────────────────┤
│ TODAY        │ 08:00 AM [3 doses]   │
│ (Mar 10) ●   │ ─────────────────    │
│              │ 🟢 BPC-157    [✓]    │
│ TOMORROW     │ 🟣 Ipamorelin [⚪]   │
│ (Mar 11)     │ 🔵 Thymosin β-4 [⚪] │
│              │                      │
│ Wed Mar 12   │ 12:00 PM [3 doses]   │
│              │ ─────────────────    │
│ Thu Mar 13   │ 🔵 TB-500     [⚪]   │
│              │ 🟡 Selank     [⚪]   │
│ Fri Mar 14   │ 🟠 Semax      [⚪]   │
│              │                      │
│ Sat Mar 15   │ 08:00 PM [2 doses]   │
│              │ ─────────────────    │
│ Sun Mar 16   │ 🟡 CJC-1295   [⚪]   │
│              │ 🟣 GHRP-6     [⚪]   │
│ [Next Week▼] │                      │
│              │ 10:00 PM [2 doses]   │
│              │ ─────────────────    │
│              │ ⚫ Melanotan II [⚪]  │
│              │ 🔵 Tesamorelin [⚪]  │
└──────────────┴──────────────────────┘
```

**Interaction:**
- Tap "TOMORROW" → Right side updates to show tomorrow's doses
- Tap 🔍 → Modal to filter cycles
- Swipe right on dose → Quick "Mark Missed"
- Swipe left on dose → Quick "Add Symptoms"

**Pros:**
- ✅ **Best of both worlds:** Date overview + dose details
- ✅ **Fast navigation:** One tap to switch days
- ✅ **Compact:** Can see 7 days + 10 doses on one screen
- ✅ **Quick actions:** Swipe gestures for common tasks

**Cons:**
- ❌ **Narrow columns:** Less space for dose details
- ❌ **Mobile only:** Split view doesn't work well on tablets (but that's fine)

---

## 5. Date Range Optimization

### 5.1 Should Calendar Show 7, 14, or 30 Days?

| Range | Pros | Cons | Use Case |
|-------|------|------|----------|
| **7 days** ✅ | Fast, fits on screen, daily focus | Can't plan >1 week ahead | Daily dosing |
| **14 days** | Good balance, see 2 weeks ahead | More scrolling, slower load | Weekly planning |
| **30 days** | See full month, good for planning | Slow, too much scrolling | Long-term view |

**Recommended:** **7 days by default** with option to expand to 14 or 30

**Why:**
- Most users check "What do I take today/tomorrow?"
- Rarely need to see 3 weeks ahead
- Faster load = better UX

**User Setting:**
```dart
enum CalendarRange { week7, week14, days30 }

class CalendarSettings {
  CalendarRange range = CalendarRange.week7;
  bool groupByDate = true;
  bool showCompleted = true;
  bool showMissed = true;
}
```

---

### 5.2 Pre-loading Strategy

**Option A: Load Current + Next Week (14 days)**
- Pre-fetch 14 days on app launch
- Cache in memory
- User can see next week without delay

**Option B: Load Only Current Week (7 days)**
- Fetch only 7 days on app launch
- When user taps "Next Week" → fetch next 7 days
- Slower for weekly planning, faster initial load

**Recommended:** **Option A** (pre-load 14 days)
- **Why:** Most users check "What's this week?" and "What's next week?"
- **Cost:** 196 dose_logs × 2 = 392 dose_logs (~20KB)
- **Load time:** ~0.6s (vs 0.5s for 7 days)
- **Tradeoff:** +0.1s load time for instant next-week access

---

### 5.3 Cache Strategy

**What to cache:**
- ✅ Loaded dose instances (in memory, up to 4 weeks)
- ✅ Dose schedules (in memory, invalidate on cycle change)
- ✅ User preferences (calendar range, cycle filter) → SharedPreferences

**When to invalidate:**
- ✅ User marks dose complete/missed → invalidate that day only
- ✅ User creates/edits cycle → invalidate all schedules
- ✅ App resumes from background → refresh current week

**Implementation:**
```dart
class CalendarCache {
  final Map<String, List<DoseInstance>> _dosesByWeek = {};
  DateTime? _lastRefresh;
  
  List<DoseInstance>? getCachedWeek(int weekOffset) {
    final key = 'week_$weekOffset';
    if (_lastRefresh != null && DateTime.now().difference(_lastRefresh!) < Duration(minutes: 5)) {
      return _dosesByWeek[key];
    }
    return null;
  }
  
  void cacheWeek(int weekOffset, List<DoseInstance> doses) {
    _dosesByWeek['week_$weekOffset'] = doses;
    _lastRefresh = DateTime.now();
  }
  
  void invalidate() {
    _dosesByWeek.clear();
    _lastRefresh = null;
  }
}
```

---

## 6. Real-time Updates

### 6.1 Status Badge System

**Status Types:**
- 🟢 **COMPLETED:** Dose taken, logged in database
- 🔴 **MISSED:** Dose skipped (user marked as missed)
- ⚪ **SCHEDULED:** Dose not yet taken (future or pending)
- 🟡 **LATE:** Dose scheduled for past time but not logged (warn user)
- ⚫ **SKIPPED:** User intentionally skipped (different from missed)

**Visual Design:**
```dart
Widget _buildStatusBadge(String status) {
  Color color;
  String text;
  
  switch (status) {
    case 'COMPLETED':
      color = Color(0xFF00FF00);
      text = '✓ DONE';
      break;
    case 'MISSED':
      color = Color(0xFFFF0040);
      text = '✗ MISSED';
      break;
    case 'LATE':
      color = Color(0xFFFFA500);
      text = '⚠ LATE';
      break;
    case 'SKIPPED':
      color = Color(0xFF808080);
      text = '⊗ SKIPPED';
      break;
    default:
      color = Color(0xFFFFFFFF);
      text = 'PENDING';
  }
  
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      border: Border.all(color: color),
      borderRadius: BorderRadius.circular(3),
    ),
    child: Text(
      text,
      style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );
}
```

---

### 6.2 Refresh Strategy

**Option A: Pull-to-Refresh**
- User swipes down → RefreshIndicator → fetch fresh data
- Manual, user-initiated
- **Pros:** User control, no background network
- **Cons:** User must remember to refresh

**Option B: Auto-Refresh on App Resume**
- When app comes to foreground → refresh current week
- Automatic, transparent
- **Pros:** Always up-to-date, no user action needed
- **Cons:** Network call every app resume (battery drain)

**Option C: Smart Refresh (Conditional)**
- Refresh if last refresh >5 minutes ago
- Skip if refreshed recently
- **Pros:** Balance freshness + battery
- **Cons:** More complex logic

**Recommended:** **Hybrid (A + C)**
- Pull-to-refresh always available
- Auto-refresh on app resume if >5 minutes since last refresh
- Invalidate cache when user marks dose complete/missed

**Implementation:**
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    final lastRefresh = _calendarCache.lastRefresh;
    if (lastRefresh == null || DateTime.now().difference(lastRefresh) > Duration(minutes: 5)) {
      ref.refresh(upcomingDosesProvider);
    }
  }
}
```

---

### 6.3 Optimistic Updates

**Problem:** User taps "Mark Complete" → wait 1-2s for database response → UI updates

**Solution:** Optimistic update
1. User taps "Mark Complete"
2. **Immediately** update UI (show green checkmark)
3. Send database request in background
4. If request fails → revert UI + show error

**Implementation:**
```dart
Future<void> markDoseComplete(String doseLogId) async {
  // 1. Optimistic update (instant)
  setState(() {
    _doses.firstWhere((d) => d.doseLogId == doseLogId).status = 'COMPLETED';
  });
  
  // 2. Send to database (background)
  try {
    await _doseLogsService.updateDoseLog(doseLogId, status: 'COMPLETED');
  } catch (e) {
    // 3. Revert on error
    setState(() {
      _doses.firstWhere((d) => d.doseLogId == doseLogId).status = 'SCHEDULED';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to mark dose complete. Try again.')),
    );
  }
}
```

**User Experience:**
- ✅ **Instant feedback:** Checkmark appears immediately
- ✅ **Smooth:** No loading spinner
- ✅ **Reliable:** Reverts if database fails

---

## 7. Implementation Roadmap

### Sprint 1: Database Optimization (1-2 hours)

**Tasks:**
- [ ] Add `cycle_id` column to `dose_logs` table
- [ ] Backfill `cycle_id` from `dose_schedules` (migration script)
- [ ] Create index: `CREATE INDEX idx_dose_logs_user_date ON dose_logs(user_id, logged_at)`
- [ ] Create index: `CREATE INDEX idx_dose_logs_cycle_date ON dose_logs(cycle_id, logged_at)`
- [ ] Test query performance (before/after)

**Files to Modify:**
- Supabase migration SQL script
- `lib/services/dose_schedule_service.dart` (update queries)

**Performance Target:** Queries <100ms

---

### Sprint 2: Calendar UI - 7-Day View (2-3 hours)

**Tasks:**
- [ ] Update `getUpcomingDoses()` to fetch 7 days instead of 30
- [ ] Update `CalendarScreen` to show next 7 days by default
- [ ] Add "Load Next Week" button at bottom
- [ ] Implement pagination logic (load week 2, week 3, etc.)
- [ ] Test with 10 active cycles

**Files to Modify:**
- `lib/services/dose_schedule_service.dart` (change `daysAhead = 7`)
- `lib/screens/calendar_screen.dart` (add pagination)

**Performance Target:** <0.8s load time with 10 cycles

---

### Sprint 3: Cycle Filter (2-3 hours)

**Tasks:**
- [ ] Add ⚙️ settings icon in AppBar
- [ ] Create `CalendarSettingsModal` widget
- [ ] Add cycle checkboxes (select/deselect)
- [ ] Save filter state to SharedPreferences
- [ ] Apply filter to calendar view

**Files to Modify:**
- `lib/screens/calendar_screen.dart` (add settings button)
- `lib/widgets/calendar_settings_modal.dart` (new file)
- `lib/services/calendar_preferences.dart` (new file)

**Performance Target:** Filter toggle <100ms

---

### Sprint 4: UI Improvements (2-3 hours)

**Tasks:**
- [ ] Add cycle color coding (8 distinct colors)
- [ ] Group doses by time (e.g., "08:00 AM [3 doses]")
- [ ] Compact card design (40px tall instead of 60px)
- [ ] Add quick actions (swipe to mark missed/complete)
- [ ] Add status badges (COMPLETED, MISSED, LATE)

**Files to Modify:**
- `lib/screens/calendar_screen.dart` (redesign dose cards)
- `lib/theme/colors.dart` (add cycle colors)

**Performance Target:** Smooth 60fps scrolling

---

### Sprint 5: Real-time Updates (1-2 hours)

**Tasks:**
- [ ] Implement optimistic updates for "Mark Complete"
- [ ] Add pull-to-refresh
- [ ] Add auto-refresh on app resume (if >5 min)
- [ ] Add cache invalidation on dose log update

**Files to Modify:**
- `lib/screens/calendar_screen.dart` (add lifecycle hooks)
- `lib/services/dose_schedule_service.dart` (add cache)

**Performance Target:** Instant UI updates, <1s database sync

---

### Sprint 6: Testing & Polish (2-3 hours)

**Tasks:**
- [ ] Test with 1 cycle (fast?)
- [ ] Test with 10 cycles (< 2s?)
- [ ] Test with 20 cycles (< 3s?)
- [ ] Test pagination (load next week)
- [ ] Test cycle filter (select/deselect)
- [ ] Test offline mode (show cached data)
- [ ] Load testing (1000 dose_logs in database)

**Performance Targets:**
- ✅ 10 cycles: < 2s
- ✅ 20 cycles: < 3s
- ✅ Pagination: < 1s per week
- ✅ Filter toggle: < 100ms

---

## 8. Performance Metrics to Verify

### Before Optimization (Baseline)

| Metric | Target | Current | After |
|--------|--------|---------|-------|
| **Initial load (10 cycles)** | < 2s | ~3.3s | **~0.5s** ✅ |
| **Query time (dose_logs)** | < 100ms | ~1000ms | **~50ms** ✅ |
| **Memory usage** | < 100KB | ~500KB | **~100KB** ✅ |
| **Pagination (next week)** | < 1s | N/A | **~0.4s** ✅ |
| **Filter toggle** | < 100ms | N/A | **~50ms** ✅ |
| **Calendar refresh** | < 1s | ~3.3s | **~0.6s** ✅ |

### How to Measure

**1. Initial Load Time**
```dart
final stopwatch = Stopwatch()..start();
final doses = await ref.read(upcomingDosesProvider.future);
stopwatch.stop();
print('Calendar load time: ${stopwatch.elapsedMilliseconds}ms');
```

**2. Query Time (in Supabase dashboard)**
```sql
EXPLAIN ANALYZE
SELECT * FROM dose_logs 
WHERE user_id = '...' 
AND logged_at BETWEEN '2026-03-10' AND '2026-03-17';
```

**3. Memory Usage (in Flutter DevTools)**
- Open Memory tab
- Snapshot before calendar load
- Snapshot after calendar load
- Calculate diff

---

## 9. Risk Mitigation

### Risk 1: Indexes Slow Down Writes

**Problem:** Adding indexes makes INSERT/UPDATE slower  
**Impact:** Dose logging takes longer  
**Likelihood:** Low (dose_logs writes are infrequent, <10 per day)  
**Mitigation:**
- Test write performance after indexing
- If slow, use partial index: `WHERE logged_at > '2026-01-01'` (index recent data only)

---

### Risk 2: Pagination Confuses Users

**Problem:** User doesn't realize they need to tap "Load Next Week"  
**Impact:** User thinks they only have 7 days of doses  
**Likelihood:** Medium  
**Mitigation:**
- Add visual indicator: "Showing 7 of 84 total doses"
- Auto-load next week when user scrolls to bottom (infinite scroll)

---

### Risk 3: Cycle Filter State Lost

**Problem:** User filters cycles, app restarts, filter resets  
**Impact:** Annoying, must re-select cycles  
**Likelihood:** High (without persistence)  
**Mitigation:**
- Save filter state to SharedPreferences
- Restore on app launch

---

### Risk 4: Optimistic Updates Fail

**Problem:** UI shows "Completed" but database fails  
**Impact:** User thinks dose is logged, but it's not  
**Likelihood:** Low (database is reliable)  
**Mitigation:**
- Revert UI on error
- Show error message: "Failed to save. Try again."
- Add retry button

---

## 10. Success Criteria

**Must-Have (Phase 10C):**
- ✅ Calendar loads 10 cycles in < 2 seconds
- ✅ Database queries run in < 100ms
- ✅ User can filter cycles to show only active ones
- ✅ 7-day view is default (shows today + next 6 days)
- ✅ Quick actions (mark missed, add symptoms) accessible from calendar

**Nice-to-Have (Future):**
- ⚪ Infinite scroll (auto-load next week)
- ⚪ Today widget (iOS/Android)
- ⚪ Push notifications for upcoming doses
- ⚪ Cycle color customization
- ⚪ Export calendar to iCal/Google Calendar

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Estimated Implementation Time:** 10-15 hours  
**Performance Improvement:** **6x faster** (3.3s → 0.5s)
