# Dose Logging Fix - Executive Summary

**Status:** 🔴 ROOT CAUSE IDENTIFIED  
**Priority:** 🔥 CRITICAL  
**Impact:** Zero dose logs being created, calendar non-functional  
**Effort:** 5-15 minutes to fix  

---

## TL;DR

**Problem:** dose_logs table is missing the 'status' column that the code tries to write.

**Result:** All 84 doses generate correctly, but 0 get inserted into database.

**Fix:** Remove 'status' from insert code (quick) OR add column to schema (better).

---

## Root Cause

The form generates 84 perfect doses:
```
✅ Ramp Up:   7 doses × 0.5mg
✅ Plateau:  70 doses × 1.0mg  
✅ Ramp Down: 7 doses × 0.5mg
✅ TOTAL:    84 doses
```

But the insert fails because:
```dart
// Code tries to insert:
{
  'user_id': uuid,
  'cycle_id': uuid,
  'dose_amount': 0.5,
  'logged_at': '2026-03-10T08:00:00',
  'status': 'SCHEDULED',  // ❌ Column doesn't exist!
  'notes': 'Phase: ramp_up'
}

// Database schema only has:
// user_id, cycle_id, dose_amount, logged_at, route, location, notes, created_at
```

Supabase rejects the insert, error is logged to console, user sees "✓ Cycle created" but dose_logs = 0.

Calendar tries to fetch dose_logs, gets nothing, falls back to schedule default (0.5mg everywhere).

---

## The Fix

### Option A: Quick Fix (5 minutes, no schema change)

**File:** `lib/screens/cycles_screen.dart` line 1737

**Remove this line:**
```dart
'status': 'SCHEDULED',  // ❌ DELETE THIS
```

**File:** `lib/services/dose_schedule_service.dart` line 186

**Change:**
```dart
// BEFORE
final status = doseLog?['status'] as String? ?? 'SCHEDULED';

// AFTER (infer from timestamp)
final now = DateTime.now();
final doseDateTime = doseLog != null ? DateTime.parse(doseLog['logged_at']) : date;
final status = doseLog != null 
    ? (doseDateTime.isBefore(now) ? 'COMPLETED' : 'SCHEDULED')
    : 'SCHEDULED';
```

**File:** `lib/services/dose_logs_service.dart` line 96

**Remove:**
```dart
'status': 'SCHEDULED',  // ❌ DELETE THIS
```

**Result:** Dose logs will insert successfully. Status inferred from logged_at timestamp.

---

### Option B: Permanent Fix (15 minutes, with schema change)

**Step 1:** Run this SQL in Supabase:

```sql
ALTER TABLE dose_logs 
ADD COLUMN status TEXT DEFAULT 'SCHEDULED' 
CHECK (status IN ('SCHEDULED', 'COMPLETED', 'MISSED', 'SKIPPED'));

CREATE INDEX idx_dose_logs_status ON dose_logs(status);
```

**Step 2:** Keep code as-is (status field stays in insert).

**Step 3:** Update DoseLog model to handle nullable status with default 'SCHEDULED'.

**Result:** Proper status tracking, can mark doses COMPLETED/MISSED/SKIPPED.

---

## Testing

After applying fix:

1. **Create cycle** with phases
2. **Check logs** for:
   ```
   [DEBUG UNIFIED] ✓ Created dose_log: <uuid> for 0.5mg (phase: taper_up)
   [DEBUG UNIFIED] Created 84 dose logs
   ```
3. **Go to calendar** → should show correct dose amounts per phase
4. **Query database:**
   ```sql
   SELECT dose_amount, COUNT(*) FROM dose_logs WHERE cycle_id = '<id>' GROUP BY dose_amount;
   ```
   Expected:
   ```
   0.50 | 14
   1.00 | 70
   ```

---

## Why This Happened

**Schema drift:** Code evolved faster than schema.

**Likely timeline:**
1. Initial dose_logs table created without status
2. Feature added to track SCHEDULED/COMPLETED/MISSED status
3. Code updated to use status field
4. Schema migration never run (or didn't get applied to production DB)

**Prevention:**
- Keep schema files in sync with code models
- Use schema migration tool (Supabase migrations, dbmate, etc.)
- Add integration tests that validate schema matches code

---

## Other Issues Found (Not Critical)

### 1. Schema File Inconsistency

Two schema files define dose_logs differently:
- `create_dose_logs_table.sql` uses `location` field
- `create_all_tables.sql` uses `injection_site` field

**Recommendation:** Use `create_all_tables.sql` as canonical source.

### 2. Silent Error Handling

When insert fails, user sees "✓ Cycle created" but dose_logs aren't created.

**Recommendation:** Show specific error if dose_logs fail:
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('⚠️ Cycle created but dose scheduling failed. Contact support.'),
    backgroundColor: AppColors.error,
  ),
);
```

### 3. Calendar Lookup Edge Case

If user has multiple cycles of same peptide on same day, only last dose_log is stored in lookup map.

**Impact:** Low (rare scenario)  
**Fix:** Use list instead of single value in doseLogMap

---

## Files Changed

| File | Change | Lines |
|------|--------|-------|
| `cycles_screen.dart` | Remove 'status' from insert | ~1744 |
| `dose_schedule_service.dart` | Infer status from timestamp | ~186 |
| `dose_logs_service.dart` | Remove 'status' from insert | ~96 |

---

## Deliverables

1. ✅ **CODE_REVIEW_DOSE_LOGGING_PHASE10C.md** - Full analysis (21KB, ~8000 words)
2. ✅ **QUICK_FIX_PATCH.md** - Step-by-step fix instructions
3. ✅ **DOSE_LOGGING_FIX_SUMMARY.md** - This file (executive summary)

---

## Next Steps

**IMMEDIATE:**
1. Apply Quick Fix (Option A)
2. Test with new cycle
3. Verify calendar shows correct doses

**THIS WEEK:**
1. Apply Permanent Fix (Option B) - add status column
2. Add schedule_id foreign key
3. Improve error handling

**NEXT SPRINT:**
1. Resolve schema file conflicts
2. Add integration tests
3. Consider schema code generation tool

---

## Questions?

- **Q: Will this break existing cycles?**  
  A: No. Quick Fix only affects NEW cycles. Existing (broken) cycles will remain broken but won't get worse.

- **Q: Do I need to migrate existing data?**  
  A: Not for Quick Fix. For Permanent Fix, existing dose_logs will get default status='SCHEDULED'.

- **Q: Can I apply both fixes?**  
  A: Yes. Apply Quick Fix now, then Permanent Fix later. They're complementary.

- **Q: What if I already have dose_logs with 'status' column?**  
  A: You don't (schema audit confirms). But if you do, Quick Fix will break things - use Permanent Fix approach.

---

**Reviewed by:** Wintermute  
**Date:** 2026-03-10 12:31 EDT  
**Session:** agent:main:subagent:043ee893-3415-4f9c-8096-13fa1f3f2b6b
