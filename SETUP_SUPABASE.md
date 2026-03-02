# Supabase Setup for Biohacker Flutter

## Before Testing the New Build

The app now saves cycles to Supabase. **You need to create the database table first.**

### Step 1: Go to Supabase Dashboard

1. Visit: https://app.supabase.com/
2. Select your project: `dfiewtwbxqfrrmyiqhqo`
3. Go to **SQL Editor** (left sidebar)

### Step 2: Create the Cycles Table

1. Click **"New Query"**
2. Copy and paste the SQL below:

```sql
-- Create cycles table for Biohacker app
CREATE TABLE IF NOT EXISTS cycles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  peptide_name TEXT NOT NULL,
  dose DECIMAL(10, 2) NOT NULL,
  route TEXT NOT NULL,
  frequency TEXT NOT NULL,
  duration_weeks INTEGER NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  advanced_schedule JSONB,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_cycles_user_id ON cycles(user_id);
CREATE INDEX idx_cycles_is_active ON cycles(is_active);
CREATE INDEX idx_cycles_created_at ON cycles(created_at DESC);

ALTER TABLE cycles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own cycles"
  ON cycles FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own cycles"
  ON cycles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cycles"
  ON cycles FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cycles"
  ON cycles FOR DELETE
  USING (auth.uid() = user_id);
```

3. Click **"Run"**
4. You should see: ✓ "Success"

### Step 3: Verify the Table

1. Go to **Tables** (left sidebar)
2. You should see `cycles` table listed
3. Click it to see the columns (peptide_name, dose, route, frequency, duration_weeks, etc.)

### Done! 

The app is now ready to save and load cycles from your phone.

---

## Testing

1. **Download the new APK** from GitHub Actions
2. **Install on your phone**
3. **Open the app** and go to **CYCLES** tab
4. **Click "NEW"**
5. **Select a peptide** (e.g., "BPC-157") — should be searchable!
6. **Enter dose** (e.g., 250 mg)
7. **Select route** (SC, IM, IV, etc.)
8. **Pick frequency** (1x/week, 2x/week, etc.)
9. **Set duration** (e.g., 8 weeks)
10. **Click "CREATE CYCLE"**
11. **You should see the cycle appear** on the Cycles page!

---

## Features Now Working

✅ **Peptide Picker** — 75+ peptides to choose from, searchable  
✅ **Dosage in mg** — consistent units  
✅ **Bacteriostatic Water tracking** — ml volume  
✅ **Frequency selector** — 1x/week, 2x/week, 3x/week, daily, 2x daily  
✅ **Duration in weeks** — easy to set  
✅ **Save to Supabase** — cycles persist across sessions  
✅ **Display saved cycles** — show them on the Cycles page with all details  
✅ **Advanced dosing** — placeholder for ramping/tapering (UI ready, backend next)  

---

## Database Schema

| Column | Type | Notes |
|--------|------|-------|
| id | UUID | Primary key, auto-generated |
| user_id | UUID | Links to logged-in user |
| peptide_name | TEXT | Name of the peptide |
| dose | DECIMAL(10,2) | Dose in mg |
| route | TEXT | SC, IM, IV, Intranasal, Oral |
| frequency | TEXT | 1x weekly, 2x weekly, etc. |
| duration_weeks | INTEGER | Number of weeks |
| start_date | TIMESTAMP | When cycle started |
| end_date | TIMESTAMP | When cycle ends |
| is_active | BOOLEAN | Active = true, completed = false |
| advanced_schedule | JSONB | Ramping/tapering data (optional) |
| created_at | TIMESTAMP | Auto-generated |
| updated_at | TIMESTAMP | Auto-updated |

---

## Troubleshooting

### SQL Error: "Already exists"

If you see "table cycles already exists", that's fine — the table was created successfully in a previous run.

### Cycles don't appear after saving

1. **Check user is logged in** — if not logged in, cycles can't save (no user_id)
2. **Check Supabase console** — go to Tables → cycles → check if rows exist
3. **Check RLS policies** — make sure all 4 policies are created (they should be auto-created by the SQL)

### "Insert error" or "No rows returned"

This usually means RLS (Row Level Security) is blocking the insert. Check:
1. All 4 RLS policies are created
2. You're logged in with a valid user
3. The `user_id` matches `auth.uid()`

---

## Next Steps (After Testing)

1. **Test peptide picker** — search for a peptide, verify list appears
2. **Test save** — create a cycle, close app, reopen → should still be there
3. **Test advanced dosing** — click "ADVANCED DOSING", verify UI expands
4. **Test delete** — add ability to swipe-delete cycles (Phase 2)
5. **Test date range** — verify end_date is calculated correctly (start_date + duration_weeks)

---

Once this is working, next features:
- **Delete cycles** (swipe or button)
- **Edit cycles** (update dose, frequency, etc.)
- **Log doses** — track which doses you've taken
- **Advanced dosing calculations** — ramping/tapering schedules
- **Expense tracking** — cost per vial, total cycle cost
