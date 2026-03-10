# Quick Fix: Dose Logs Schema Mismatch

**Issue:** dose_logs table missing 'status' column, causing all insertions to fail.

**Solution:** Remove 'status' from insert code (temporary) OR add column to schema (permanent).

---

## Option 1: Quick Fix (5 minutes - NO SCHEMA CHANGE)

### File 1: lib/screens/cycles_screen.dart

**Location:** Line 1737-1745

**BEFORE:**
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // ❌ REMOVE THIS LINE
  'notes': 'Phase: $phase',
};
```

**AFTER:**
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'notes': 'Phase: $phase',
};
```

### File 2: lib/services/dose_schedule_service.dart

**Location:** Line 186 (getUpcomingDoses method)

**BEFORE:**
```dart
final doseLogId = doseLog?['id'] as String? ?? '';
final status = doseLog?['status'] as String? ?? 'SCHEDULED';  // ❌ CHANGE THIS
```

**AFTER:**
```dart
final doseLogId = doseLog?['id'] as String? ?? '';
// Infer status from timestamp (past = completed, future = scheduled)
final now = DateTime.now();
final doseDateTime = doseLog != null ? DateTime.parse(doseLog['logged_at'] as String) : date;
final status = doseLog != null 
    ? (doseDateTime.isBefore(now) ? 'COMPLETED' : 'SCHEDULED')
    : 'SCHEDULED';
```

### File 3: lib/services/dose_logs_service.dart

**Location:** Line 96 (generateDosesFromSchedule method)

**BEFORE:**
```dart
final data = {
  'user_id': userId,
  'cycle_id': cycleId,
  'dose_amount': doseAmount,
  'logged_at': loggedAt.toIso8601String(),
  'status': 'SCHEDULED',  // ❌ REMOVE THIS LINE
};
```

**AFTER:**
```dart
final data = {
  'user_id': userId,
  'cycle_id': cycleId,
  'dose_amount': doseAmount,
  'logged_at': loggedAt.toIso8601String(),
};
```

---

## Option 2: Permanent Fix (15 minutes - WITH SCHEMA CHANGE)

### Step 1: Add columns to dose_logs table

Run this SQL in Supabase SQL Editor:

```sql
-- Add status column
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'SCHEDULED' 
CHECK (status IN ('SCHEDULED', 'COMPLETED', 'MISSED', 'SKIPPED'));

-- Add schedule_id foreign key (optional but recommended)
ALTER TABLE dose_logs 
ADD COLUMN IF NOT EXISTS schedule_id UUID REFERENCES dose_schedules(id) ON DELETE SET NULL;

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_dose_logs_status ON dose_logs(status);
CREATE INDEX IF NOT EXISTS idx_dose_logs_schedule_id ON dose_logs(schedule_id);

-- Comment for documentation
COMMENT ON COLUMN dose_logs.status IS 'Dose status: SCHEDULED (future), COMPLETED (logged), MISSED (past + not logged), SKIPPED (user skipped)';
```

### Step 2: Update insert code (cycles_screen.dart)

**Location:** Line 1737

Keep the status field:
```dart
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // ✅ Now this works!
  'notes': 'Phase: $phase',
};
```

### Step 3: Update DoseLog model (dose_logs_service.dart)

**Location:** Line 5-25

```dart
class DoseLog {
  final String id;
  final String userId;
  final String cycleId;
  final String? scheduleId;  // ✅ Re-enable
  final double doseAmount;
  final String? route;
  final String? injectionSite;
  final DateTime loggedAt;
  final String? notes;
  final String status;  // ✅ Re-enable (SCHEDULED, COMPLETED, MISSED, SKIPPED)
  final DateTime createdAt;

  DoseLog({
    required this.id,
    required this.userId,
    required this.cycleId,
    this.scheduleId,
    required this.doseAmount,
    this.route,
    this.injectionSite,
    required this.loggedAt,
    this.notes,
    this.status = 'SCHEDULED',  // ✅ Add default
    required this.createdAt,
  });

  factory DoseLog.fromJson(Map<String, dynamic> json) {
    return DoseLog(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      cycleId: json['cycle_id'] ?? '',
      scheduleId: json['schedule_id'] as String?,
      doseAmount: (json['dose_amount'] as num?)?.toDouble() ?? 0,
      route: json['route'],
      injectionSite: json['injection_site'],
      loggedAt: DateTime.parse(json['logged_at']),
      notes: json['notes'],
      status: json['status'] ?? 'SCHEDULED',  // ✅ Handle null
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'cycle_id': cycleId,
      if (scheduleId != null) 'schedule_id': scheduleId,
      'dose_amount': doseAmount,
      if (route != null) 'route': route,
      if (injectionSite != null) 'injection_site': injectionSite,
      'logged_at': loggedAt.toIso8601String(),
      if (notes != null) 'notes': notes,
      'status': status,
    };
  }
}
```

### Step 4: Update calendar service (dose_schedule_service.dart)

**Location:** Line 186

```dart
final doseLogId = doseLog?['id'] as String? ?? '';
final status = doseLog?['status'] as String? ?? 'SCHEDULED';  // ✅ Now reads from DB
```

---

## Testing Instructions

### After applying Quick Fix (Option 1):

1. **Restart app** (hot reload may not be enough)

2. **Create new cycle:**
   - Peptide: Test Peptide
   - Vial: 10mg
   - Desired dose: 1.0mg
   - Draw: 0.2ml
   - Duration: 12 weeks
   - Add phases: Ramp Up (7 days) → auto-adds Plateau → Ramp Down (7 days)

3. **Check logs for:**
   ```
   [DEBUG UNIFIED] ✓ Created dose_log: <uuid> for 0.5mg (phase: taper_up)
   [DEBUG UNIFIED] ✓ Created dose_log: <uuid> for 1.0mg (phase: plateau)
   [DEBUG UNIFIED] Created 84 dose logs
   ```

4. **Go to calendar tab:**
   - Should see doses for next 30 days
   - Verify amounts match phases (0.5mg → 1.0mg → 0.5mg)
   - NOT all 0.5mg

5. **Verify in Supabase:**
   ```sql
   SELECT 
     dose_amount, 
     COUNT(*) as count,
     MIN(logged_at) as first_date,
     MAX(logged_at) as last_date
   FROM dose_logs 
   WHERE cycle_id = '<your_cycle_id>'
   GROUP BY dose_amount
   ORDER BY MIN(logged_at);
   ```
   
   Expected output:
   ```
   dose_amount | count | first_date | last_date
   0.50        | 7     | 2026-03-10 | 2026-03-16
   1.00        | 70    | 2026-03-17 | 2026-05-25
   0.50        | 7     | 2026-05-26 | 2026-06-01
   ```

### After applying Permanent Fix (Option 2):

Follow same testing as Option 1, PLUS:

6. **Verify status column:**
   ```sql
   SELECT status, COUNT(*) 
   FROM dose_logs 
   WHERE cycle_id = '<your_cycle_id>'
   GROUP BY status;
   ```
   
   Expected:
   ```
   status    | count
   SCHEDULED | 84
   ```

7. **Test status updates:**
   - Mark a dose as complete in app
   - Check database: `SELECT status FROM dose_logs WHERE id = '<dose_id>'`
   - Should show: `COMPLETED`

---

## Rollback Instructions

### If Quick Fix breaks something:

**Revert cycles_screen.dart:**
```dart
// Add back the status line
final insertData = {
  'user_id': userId,
  'cycle_id': createdCycle.id,
  'dose_amount': doseAmount,
  'logged_at': doseDateTime.toIso8601String(),
  'status': 'SCHEDULED',  // Revert
  'notes': 'Phase: $phase',
};
```

**Revert dose_schedule_service.dart:**
```dart
final status = doseLog?['status'] as String? ?? 'SCHEDULED';  // Revert
```

### If Permanent Fix breaks something:

**Remove columns from database:**
```sql
ALTER TABLE dose_logs DROP COLUMN IF EXISTS status;
ALTER TABLE dose_logs DROP COLUMN IF EXISTS schedule_id;
DROP INDEX IF EXISTS idx_dose_logs_status;
DROP INDEX IF EXISTS idx_dose_logs_schedule_id;
```

---

## Recommended Approach

**For immediate unblocking:** Use **Option 1** (Quick Fix)

**For production quality:** Apply **Option 2** (Permanent Fix) after testing Option 1

---

## Support

If issues persist after applying fixes:

1. Check Flutter console for error messages
2. Check Supabase logs (Project Settings → API → Logs)
3. Enable verbose logging:
   ```dart
   // Add at top of _showNewUnifiedCycleSetup()
   print('[DEBUG] Starting cycle creation at ${DateTime.now()}');
   ```
4. Share logs in GitHub issue or support channel

---

**Last Updated:** 2026-03-10  
**Verified By:** Wintermute (Code Review Agent)
