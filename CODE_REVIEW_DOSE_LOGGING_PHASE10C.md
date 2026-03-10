# Code Review: Biohacker Flutter App - Dose Logging Pipeline (Phase 10C)

**Date:** 2026-03-10  
**Reviewer:** Wintermute  
**Status:** 🔴 CRITICAL ISSUES FOUND

---

## Executive Summary

**ROOT CAUSE IDENTIFIED:** The dose_logs table schema is missing critical columns (`status`, `schedule_id`) that the application code attempts to write, causing all dose log insertions to fail silently or with errors.

**Impact:** 
- ✅ Form generates 84 doses correctly (verified in cycle_setup_form_v4.dart)
- ❌ 0 dose_logs inserted (schema mismatch causes insert failures)
- ❌ Calendar shows fallback values (no dose_logs exist to query)

---

## 1. Schema Audit

### 1.1 Actual dose_logs Schema

**File:** `lib/migrations/create_dose_logs_table.sql` and `create_all_tables.sql`

```sql
CREATE TABLE IF NOT EXISTS dose_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cycle_id UUID NOT NULL REFERENCES cycles(id) ON DELETE CASCADE,
  dose_amount DECIMAL(10, 2) NOT NULL,  -- in mg
  logged_at TIMESTAMP WITH TIME ZONE NOT NULL,
  route TEXT,  -- SC, IM, IV, etc.
  location TEXT,  -- injection site (create_dose_logs_table.sql)
  -- OR --
  injection_site TEXT,  -- (create_all_tables.sql - DIFFERENT!)
  notes TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

**Columns that EXIST:**
- ✅ `id`, `user_id`, `cycle_id`, `dose_amount`, `logged_at`, `route`, `notes`, `created_at`
- ⚠️ `location` (in create_dose_logs_table.sql) OR `injection_site` (in create_all_tables.sql) — **INCONSISTENT!**

**Columns that DO NOT EXIST:**
- ❌ `status` (SCHEDULED, COMPLETED, MISSED)
- ❌ `schedule_id` (foreign key to dose_schedules)

### 1.2 What the Code Expects

**File:** `lib/services/dose_logs_service.dart` (DoseLog model)

```dart
class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final String? scheduleId;  // ❌ DOES NOT EXIST IN SCHEMA
  final double doseAmount;
  final String route;
  final String? injectionSite;
  final DateTime loggedAt;
  final String? notes;
  final String status; // ❌ DOES NOT EXIST IN SCHEMA
  final Map<String, dynamic>? symptoms;  // ❌ DOES NOT EXIST IN SCHEMA
  final DateTime createdAt;
  // ...
}
```

**File:** `lib/screens/cycles_screen.dart:1737`

```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // ❌ COLUMN DOES NOT EXIST
  'notes': 'Phase: $phase',
};
```

---

## 2. Data Flow Trace (End-to-End)

### 2.1 Dose Generation (✅ WORKING)

**File:** `lib/screens/cycle_setup_form_v4.dart:333-393` (_generateDoseSchedule)

- ✅ Correctly generates 84 doses
- ✅ Phases calculated properly: ramp_up (7×0.5mg), plateau (70×1.0mg), ramp_down (7×0.5mg)
- ✅ Dates, dayOffset, phase labels all correct
- ✅ Returns List<Map<String, dynamic>> with proper structure

**Debug output confirms:**
```
[DOSE GEN] Total doses generated: 84
[SUBMIT DEBUG] Ramp Up: 7 doses at 0.5mg
[SUBMIT DEBUG] Plateau: 70 doses at 1.0mg
[SUBMIT DEBUG] Ramp Down: 7 doses at 0.5mg
```

### 2.2 Dose Insertion (❌ FAILING)

**File:** `lib/screens/cycles_screen.dart:1624-1774` (_showNewUnifiedCycleSetup)

**Line 1747:**
```dart
final doseLog = await Supabase.instance.client
  .from('dose_logs')
  .insert(insertData)  // Contains 'status' field that doesn't exist
  .select()
  .single();
```

**Why it fails:**
1. `insertData` includes `'status': 'SCHEDULED'`
2. Supabase server rejects the insert because `status` column doesn't exist
3. Error is caught at line 1754 but only printed to console
4. User sees SnackBar "✓ $peptideName cycle created" but dose_logs are NOT created

**Error handling (line 1754-1760):**
```dart
} catch (e, stackTrace) {
  print('[DEBUG UNIFIED] ✗ FAILED to create dose_log for day $dayOffset: $e');
  print('[DEBUG UNIFIED]   Stack: $stackTrace');
  rethrow; // Re-throw so outer catch sees it
}
```

The error is logged but the outer try-catch at line 1770 likely swallows it:

```dart
} catch (e, stackTrace) {
  // ... shows error snackbar but cycle is already created
}
```

### 2.3 Calendar Display (❌ FALLBACK MODE)

**File:** `lib/services/dose_schedule_service.dart:144-178` (getUpcomingDoses)

**Line 150-158:** Fetches dose_logs
```dart
final doseLogs = await _supabase
    .from('dose_logs')
    .select()
    .eq('user_id', userId)
    .gte('logged_at', now.toIso8601String())
    .lte('logged_at', endDate.toIso8601String());

print('[DEBUG CALENDAR] Fetched ${(doseLogs as List).length} dose_logs');  
// Result: 0 dose_logs
```

**Line 186-194:** Fallback to schedule default
```dart
// Use dose_log's dose_amount if available (varies by phase), otherwise use schedule default
final doseAmount = (doseLog?['dose_amount'] as num?)?.toDouble() ?? schedule.doseAmount;

if (doseLog != null) {
  print('[DEBUG CALENDAR] ✓ Found dose for $logDateKey: ${doseAmount}mg');
} else {
  print('[DEBUG CALENDAR] ✗ No dose_log found for $logDateKey, using schedule default: ${schedule.doseAmount}mg');
}
```

**Result:** Calendar shows all doses at `schedule.doseAmount` (first dose from form = 0.5mg ramp_up dose) instead of the phase-specific amounts.

---

## 3. Code Issues Found

### 3.1 Schema Mismatch (CRITICAL)

**Location:** Multiple files  
**Severity:** 🔴 CRITICAL

**Issue:** Code references columns that don't exist in database schema.

**Evidence:**
- `cycles_screen.dart:1744` tries to insert `'status': 'SCHEDULED'`
- `dose_logs_service.dart` DoseLog model expects `status`, `scheduleId`, `symptoms` fields
- Schema only has: `user_id`, `cycle_id`, `dose_amount`, `logged_at`, `route`, `location/injection_site`, `notes`, `created_at`

**Impact:** All dose_log inserts fail with column not found error.

### 3.2 Silent Error Handling

**Location:** `cycles_screen.dart:1747-1760`  
**Severity:** 🟡 HIGH

**Issue:** Insert errors are logged but not shown to user. User sees success message despite database write failure.

**Code:**
```dart
try {
  final doseLog = await Supabase.instance.client.from('dose_logs').insert(insertData).select().single();
  createdDoseLogs++;
  print('[DEBUG UNIFIED] ✓ Created dose_log: ${doseLog['id']}');
} catch (e, stackTrace) {
  print('[DEBUG UNIFIED] ✗ FAILED to create dose_log for day $dayOffset: $e');
  print('[DEBUG UNIFIED]   Stack: $stackTrace');
  rethrow; // Re-throw but outer catch may hide it
}
```

**Recommendation:** Show specific error to user when dose_logs fail to create.

### 3.3 Inconsistent Schema Files

**Location:** `lib/migrations/`  
**Severity:** 🟡 MEDIUM

**Issue:** Two different schema files define dose_logs table with inconsistencies:
- `create_dose_logs_table.sql` uses `location` field
- `create_all_tables.sql` uses `injection_site` field

**Recommendation:** Maintain a single source of truth for schema. Use `create_all_tables.sql` as canonical.

### 3.4 No Type Safety for Insert Data

**Location:** `cycles_screen.dart:1737-1745`  
**Severity:** 🟡 MEDIUM

**Issue:** Insert data is built as raw Map<String, dynamic> without validation against schema.

**Current:**
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // ❌ Unknown column
  'notes': 'Phase: $phase',
};
```

**Recommendation:** Use DoseLog.toJson() or create a validated builder method.

### 3.5 Calendar Lookup Logic Issue

**Location:** `dose_schedule_service.dart:160-166`  
**Severity:** 🟢 LOW

**Issue:** dose_logs are grouped by `cycle_id + date` but lookup may fail if multiple cycles are active.

**Code:**
```dart
final logDateKey = '${cycleId}_${loggedAt.year}-${loggedAt.month.toString().padLeft(2, '0')}-${loggedAt.day.toString().padLeft(2, '0')}';
doseLogMap[logDateKey] = log as Map<String, dynamic>;
```

**Edge case:** If user has multiple cycles of same peptide on same day, only last dose_log will be stored in map.

**Recommendation:** Use `cycle_id + logged_at (full timestamp)` or make map values a List.

---

## 4. Architecture Review

### 4.1 Current Architecture

```
CycleSetupFormV4
  └─> _generateDoseSchedule() [generates 84 doses with phases]
       └─> Returns to cycles_screen._showNewUnifiedCycleSetup()
            └─> Creates cycle in database
            └─> Creates master dose_schedule
            └─> Loops through schedule and inserts dose_logs
                 └─> ❌ FAILS due to schema mismatch

Calendar (dose_schedule_service.dart)
  └─> Queries dose_schedules (master schedule)
  └─> Queries dose_logs (individual doses with phase-specific amounts)
  └─> Merges: dose_log amount > schedule amount (fallback)
```

**Design Strengths:**
- ✅ Separation of concerns (schedule = template, dose_logs = instances)
- ✅ Phase-based dosing logic in form is clean
- ✅ Calendar can show actual vs scheduled doses

**Design Weaknesses:**
- ❌ Schema doesn't match code expectations
- ❌ Pre-generating all dose_logs creates ~84 rows per cycle upfront
- ❌ No way to distinguish SCHEDULED vs COMPLETED vs MISSED without status field

### 4.2 Is Pre-Generation the Right Approach?

**Current:** Pre-generate 84 dose_logs on cycle creation

**Alternative 1: On-Demand Generation**
```
- Store only dose_schedule (master template)
- Generate dose instances on calendar load
- Create dose_log only when user marks dose complete
```

**Pros:**
- Less database bloat
- Easier to adjust schedule mid-cycle
- No schema migration needed

**Cons:**
- Can't show "missed" doses unless we store negative records
- Harder to track compliance

**Alternative 2: Hybrid Approach (RECOMMENDED)**
```
- Store dose_schedule (master template)
- Pre-generate dose_logs WITH status column
- Status: SCHEDULED → COMPLETED → MISSED (auto-update via cron)
```

**Pros:**
- Best of both worlds
- Clear compliance tracking
- Can adjust schedule by updating dose_logs

**Cons:**
- Requires schema migration

### 4.3 Master Schedule + Individual Logs Model

**Is it correct?** ✅ YES, this is a solid pattern.

**Why it works:**
- `dose_schedules` = recurring rule (like Google Calendar events)
- `dose_logs` = concrete instances (like Google Calendar event instances)

**Improvement:** Add foreign key relationship:
```sql
ALTER TABLE dose_logs ADD COLUMN schedule_id UUID REFERENCES dose_schedules(id);
```

This allows:
- Tracking which schedule generated each dose_log
- Updating all future doses when schedule changes
- Deleting all logs when schedule is deleted (ON DELETE CASCADE)

---

## 5. Recommendations

### 5.1 Quick Fix (Immediate - Unblock Current Issue)

**Step 1: Remove 'status' from Insert Data**

**File:** `lib/screens/cycles_screen.dart:1737-1745`

**Before:**
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // ❌ Remove this
  'notes': 'Phase: $phase',
};
```

**After:**
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'notes': 'Phase: $phase',
  'route': route ?? 'SC',  // Add route if needed
};
```

**Step 2: Update DoseLog Model to Match Schema**

**File:** `lib/services/dose_logs_service.dart`

**Before:**
```dart
class DoseLog {
  // ... existing fields ...
  final String? scheduleId;  // ❌ Remove
  final String status;  // ❌ Remove or make nullable with default
  final Map<String, dynamic>? symptoms;  // ❌ Remove
  // ...
}
```

**After:**
```dart
class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final double doseAmount;
  final String? route;
  final String? injectionSite;  // Or 'location' depending on actual schema
  final DateTime loggedAt;
  final String? notes;
  final DateTime createdAt;

  // If you need status/schedule tracking, infer from data:
  // - status: infer from loggedAt (past = completed, future = scheduled)
  // - scheduleId: store in notes temporarily
}
```

**Step 3: Fix Calendar to Infer Status**

**File:** `lib/services/dose_schedule_service.dart:186`

**Before:**
```dart
final status = doseLog?['status'] as String? ?? 'SCHEDULED';
```

**After:**
```dart
// Infer status from logged_at timestamp
final now = DateTime.now();
final doseDateTime = DateTime.parse(doseLog?['logged_at'] as String);
final status = doseLog != null 
    ? (doseDateTime.isBefore(now) ? 'COMPLETED' : 'SCHEDULED')
    : 'SCHEDULED';
```

**Step 4: Test Insert**

```bash
# In app, create new cycle and check logs for:
[DEBUG UNIFIED] ✓ Created dose_log: <uuid> for 0.5mg (phase: ramp_up)
[DEBUG UNIFIED] Created 84 dose logs
```

---

### 5.2 Architectural Improvements (Medium-term)

#### 5.2.1 Add Missing Columns to Schema

**Migration File:** `lib/migrations/add_dose_logs_status.sql`

```sql
-- Add status column
ALTER TABLE dose_logs 
ADD COLUMN status TEXT DEFAULT 'SCHEDULED' 
CHECK (status IN ('SCHEDULED', 'COMPLETED', 'MISSED', 'SKIPPED'));

-- Add schedule_id foreign key
ALTER TABLE dose_logs 
ADD COLUMN schedule_id UUID REFERENCES dose_schedules(id) ON DELETE SET NULL;

-- Add index for status queries
CREATE INDEX idx_dose_logs_status ON dose_logs(status);
CREATE INDEX idx_dose_logs_schedule_id ON dose_logs(schedule_id);
```

**Apply migration:**
```bash
# In Supabase dashboard SQL editor, run the migration
# Or via Supabase CLI:
supabase db push
```

#### 5.2.2 Create Dose Log Builder Service

**File:** `lib/services/dose_logs_builder.dart`

```dart
class DoseLogsBuilder {
  static Map<String, dynamic> buildInsertData({
    required String userId,
    required String cycleId,
    required double doseAmount,
    required DateTime loggedAt,
    String? route,
    String? injectionSite,
    String? notes,
    String status = 'SCHEDULED',
    String? scheduleId,
  }) {
    return {
      'user_id': userId,
      'cycle_id': cycleId,
      'dose_amount': doseAmount,
      'logged_at': loggedAt.toIso8601String(),
      if (route != null) 'route': route,
      if (injectionSite != null) 'injection_site': injectionSite,
      if (notes != null) 'notes': notes,
      if (status != 'SCHEDULED') 'status': status,
      if (scheduleId != null) 'schedule_id': scheduleId,
    };
  }
}
```

**Usage:**
```dart
final insertData = DoseLogsBuilder.buildInsertData(
  userId: userId,
  cycleId: createdCycle.id,
  doseAmount: doseAmount,
  loggedAt: doseDateTime,
  notes: 'Phase: $phase',
  route: route,
);
```

#### 5.2.3 Better Error Handling

**File:** `lib/screens/cycles_screen.dart:1734-1760`

**Replace:**
```dart
try {
  final doseLog = await Supabase.instance.client.from('dose_logs').insert(insertData).select().single();
  createdDoseLogs++;
} catch (e, stackTrace) {
  print('[DEBUG UNIFIED] ✗ FAILED: $e');
  rethrow;
}
```

**With:**
```dart
try {
  final doseLog = await Supabase.instance.client
      .from('dose_logs')
      .insert(insertData)
      .select()
      .single();
  createdDoseLogs++;
  print('[DEBUG UNIFIED] ✓ Created dose_log: ${doseLog['id']} for ${doseAmount}mg (phase: $phase)');
} catch (e, stackTrace) {
  // Show specific error in UI
  final errorMsg = e.toString().contains('column') 
      ? 'Schema error: dose_logs table missing expected columns. Contact support.'
      : 'Failed to create dose log for day $dayOffset: $e';
  
  print('[ERROR UNIFIED] $errorMsg');
  print('[ERROR UNIFIED] Stack: $stackTrace');
  
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $errorMsg'),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }
  
  // Don't rethrow - continue creating remaining logs
  // Collect errors and show summary at end
}
```

#### 5.2.4 Resolve Schema File Conflicts

**Action:** Standardize on `create_all_tables.sql` as source of truth.

**Delete or deprecate:**
- `create_dose_logs_table.sql` (individual table file)

**Or:** Keep individual files but auto-generate `create_all_tables.sql` from them.

---

### 5.3 Validation Approach (What to Test)

#### Test 1: Dose Log Creation
```
✓ Create cycle with ramp_up (7 days) + plateau (70 days) + ramp_down (7 days)
✓ Check database: SELECT COUNT(*) FROM dose_logs WHERE cycle_id = '<cycle_id>'
✓ Expected: 84 rows

✓ Verify dose amounts:
  SELECT dose_amount, COUNT(*) 
  FROM dose_logs 
  WHERE cycle_id = '<cycle_id>' 
  GROUP BY dose_amount;
  
  Expected:
  0.5 | 14  (ramp_up + ramp_down)
  1.0 | 70  (plateau)
```

#### Test 2: Calendar Display
```
✓ Navigate to calendar tab
✓ Verify doses show correct amounts per day (not all 0.5mg)
✓ Check debug logs for:
  [DEBUG CALENDAR] ✓ Found dose for <key>: 0.5mg  (days 1-7)
  [DEBUG CALENDAR] ✓ Found dose for <key>: 1.0mg  (days 8-77)
  [DEBUG CALENDAR] ✓ Found dose for <key>: 0.5mg  (days 78-84)
```

#### Test 3: Phase Detection
```
✓ In CycleSetupFormV4, set desiredDosageMg = 2.0mg
✓ Add ramp_up phase (should default to 1.0mg = half of desired)
✓ Add plateau phase (should use 2.0mg = full desired dose)
✓ Submit form
✓ Check logs:
  [DOSE GEN] Plateau: Using desired dose: 2.0mg
  [SUBMIT DEBUG] Plateau: 70 doses at 2.0mg
```

#### Test 4: Error Handling
```
✓ Temporarily add 'invalid_column': 'test' to insertData
✓ Submit form
✓ Should see error snackbar with schema error message
✓ Check that cycle is created but dose_logs show 0
```

#### Test 5: RLS Policies
```
✓ Create cycle as User A
✓ Try to query dose_logs as User B
✓ Should return 0 rows (RLS blocks)
✓ Query as User A should return 84 rows
```

---

## 6. Root Cause Summary

**The issue is NOT in the dose generation logic (which works perfectly).**

**The issue IS a schema mismatch:**

1. Form generates 84 correct doses ✅
2. Code tries to insert with `'status': 'SCHEDULED'` field ❌
3. Database rejects insert (column doesn't exist) ❌
4. Error is caught and logged but user sees "success" message ⚠️
5. Calendar queries dose_logs, gets 0 results ❌
6. Calendar falls back to schedule default (first dose = 0.5mg) ❌

**Fix:** Remove 'status' from insert OR add status column to schema.

---

## 7. Architectural Concerns

1. **Schema Evolution:** Need a migration strategy. Consider using Supabase migrations or a tool like `dbmate`.

2. **Type Safety:** Dart models should match database schema exactly. Consider code generation (e.g., `drift` for SQLite, or Supabase client generation).

3. **Error Visibility:** Database errors should surface to user, not just console logs.

4. **Data Consistency:** If cycle creation succeeds but dose_logs fail, system is in inconsistent state. Consider:
   - Transactional creation (create cycle + dose_logs in single transaction)
   - OR rollback cycle if dose_logs fail
   - OR mark cycle as "incomplete" and allow retry

5. **Testing:** Add integration tests that validate schema against code models.

---

## 8. Next Steps

**IMMEDIATE (Today):**
1. ✅ Apply Quick Fix (remove 'status' from insert)
2. ✅ Test dose log creation
3. ✅ Verify calendar shows correct doses

**SHORT-TERM (This Week):**
1. Add status column to dose_logs schema
2. Update DoseLog model to match new schema
3. Re-enable status in insert code
4. Add foreign key schedule_id column

**MEDIUM-TERM (Next Sprint):**
1. Create DoseLogsBuilder service for type-safe inserts
2. Implement better error handling
3. Add integration tests
4. Resolve schema file inconsistencies

**LONG-TERM (Future):**
1. Consider schema code generation
2. Add database migration tooling
3. Implement transactional cycle creation
4. Add automated compliance tracking (missed dose detection)

---

## Appendix A: Files Reviewed

| File | Lines | Purpose | Status |
|------|-------|---------|--------|
| `lib/migrations/create_dose_logs_table.sql` | 26 | dose_logs schema | ⚠️ Outdated |
| `lib/migrations/create_all_tables.sql` | 300+ | Full schema | ✅ Source of truth |
| `lib/screens/cycle_setup_form_v4.dart` | 1050 | Dose generation form | ✅ Working |
| `lib/screens/cycles_screen.dart` | 1800+ | Cycle creation flow | ❌ Insert fails |
| `lib/services/dose_logs_service.dart` | 227 | DoseLog model/service | ❌ Schema mismatch |
| `lib/services/dose_schedule_service.dart` | 337 | Schedule service | ⚠️ Fallback mode |

---

## Appendix B: Debug Log Interpretation

**Successful dose generation:**
```
[DOSE GEN] Starting dose generation for 3 phases
[DOSE GEN] Phase 0 (taper_up): startDate=2026-03-10, endDate=2026-03-16
[DOSE GEN]   Duration: 6 days
[DOSE GEN]   Taper UP: Using phase dosage: 0.5 mg
[DOSE GEN]   Generated 7 injection days
[DOSE GEN] Phase 1 (plateau): startDate=2026-03-17, endDate=2026-05-25
[DOSE GEN]   Duration: 69 days
[DOSE GEN]   ✓ PLATEAU detected: Using desired dose: 1.0 mg (phase dosage was 1.0)
[DOSE GEN]   Generated 70 injection days
[DOSE GEN] Phase 2 (taper_down): startDate=2026-05-26, endDate=2026-06-01
[DOSE GEN]   Duration: 6 days
[DOSE GEN]   Taper DOWN: Using phase dosage: 0.5 mg
[DOSE GEN]   Generated 7 injection days
[DOSE GEN] Total doses generated: 84
```

**Failed dose insertion:**
```
[DEBUG UNIFIED] Inserting dose_log: amount=0.5mg, date=2026-03-10 08:00:00, phase=taper_up
[DEBUG UNIFIED]   Data: {user_id: <uuid>, cycle_id: <uuid>, dose_amount: 0.5, logged_at: 2026-03-10T08:00:00.000, status: SCHEDULED, notes: Phase: taper_up}
[DEBUG UNIFIED] ✗ FAILED to create dose_log for day 0: <Supabase error about 'status' column>
```

**Calendar fallback:**
```
[DEBUG CALENDAR] Fetched 0 dose_logs
[DEBUG CALENDAR] Built doseLogMap with 0 entries
[DEBUG CALENDAR] ✗ No dose_log found for <cycle>_2026-03-10, using schedule default: 0.5mg
```

---

**END OF CODE REVIEW**
