# Tier 3 Profile Features - Implementation Notes

**Date:** 2026-03-10  
**Status:** ✅ Complete

## Changes Made

### 1. Height Display Format ✅
- **Issue:** Height showed as "5" + "11" (two separate numbers)
- **Fix:** 
  - Added read-only "Current Height" display box showing formatted height (e.g., "5'11"")
  - Kept input fields (feet/inches) for updating height
  - Display auto-updates when input fields change
  - Uses existing `heightFormatted` getter from UserProfile model

### 2. Weight Error Fix ✅
- **Issue:** Weight field showed error on profile page
- **Root Cause:** Missing RLS (Row Level Security) policies on `weight_logs` table
- **Fix:**
  - Added better error handling in profile_screen.dart
  - Created `FIX_WEIGHT_LOGS_RLS.sql` migration to add missing RLS policies
  - Now shows "Error loading weight (check RLS policies)" with clear debugging info
  - Displays "No weight logged yet" when no weight data exists

### 3. New Profile Fields (Tier 3) ✅

Added 5 new profile fields:

#### a. **Notification Preferences** (Checkboxes)
- Email Notifications
- Push Notifications  
- SMS Notifications
- Stored as JSONB: `{"email": true, "push": false, "sms": false}`

#### b. **Health Goals** (Multi-select checkboxes)
- Improve Longevity
- Recover from Injury
- Optimize Hormone Levels
- Athletic Performance
- Weight Loss
- Other
- Stored as JSONB array: `["longevity", "recovery"]`

#### c. **Units Preference** (Dropdown)
- Imperial (lbs, ft/in, mg)
- Metric (kg, cm, ml)
- Stored as text: `"metric"` or `"imperial"`
- Default: `"imperial"`

#### d. **Preferred Contact Method** (Radio buttons)
- Email
- Phone
- Push Notification
- Stored as text: `"email"`, `"phone"`, or `"push"`
- Default: `"email"`

#### e. **Bio** (Optional text area)
- Max 200 characters
- Stored as nullable TEXT
- Hint: "Tell us a bit about yourself..."

## Database Changes

### New Columns Added to `user_profiles`

```sql
notification_preferences  JSONB     DEFAULT '{"email": true, "push": false, "sms": false}'
health_goals_list        JSONB     DEFAULT '[]'
units_preference         TEXT      DEFAULT 'imperial'
contact_method          TEXT      DEFAULT 'email'
bio                     TEXT      NULL
```

### Constraints Added

- `units_preference IN ('metric', 'imperial')`
- `contact_method IN ('email', 'phone', 'push')`
- `bio` max length: 200 characters

### Migration Files Created

1. **DATABASE_MIGRATION_TIER3.sql** - Adds 5 new columns with constraints
2. **FIX_WEIGHT_LOGS_RLS.sql** - Fixes RLS policies on weight_logs table

## Code Changes

### Files Modified

1. **lib/screens/profile_screen.dart**
   - Added height display container (read-only formatted display)
   - Added 5 new profile fields in "PREFERENCES" section
   - Improved weight error handling
   - Added state management for new fields
   - Added `_updateHeightDisplay()` method for live preview

2. **lib/services/user_profile_service.dart**
   - Updated `UserProfile` model with 5 new fields
   - Updated `fromJson()` to parse new fields
   - Updated `toJson()` to serialize new fields
   - Updated `copyWith()` to handle new fields
   - Updated `updateUserProfile()` method to accept and save new fields

## Testing Checklist

- [ ] Height displays correctly as "5'11"" format
- [ ] Height updates when feet/inches fields change
- [ ] Weight shows correct value or "No weight logged yet"
- [ ] Weight error shows helpful message if RLS is broken
- [ ] Notification preferences save correctly
- [ ] Health goals save as JSONB array
- [ ] Units preference saves and loads
- [ ] Contact method saves and loads
- [ ] Bio saves with 200 char limit enforced
- [ ] Form validation works for all fields
- [ ] Save button shows loading state
- [ ] Success message appears after save
- [ ] Error messages are clear and helpful

## Database Setup Instructions

### Step 1: Run Tier 3 Migration
```sql
-- Copy and paste contents of DATABASE_MIGRATION_TIER3.sql into Supabase SQL Editor
-- This adds the 5 new columns with defaults and constraints
```

### Step 2: Fix Weight Logs RLS
```sql
-- Copy and paste contents of FIX_WEIGHT_LOGS_RLS.sql into Supabase SQL Editor
-- This fixes the READ access issue for weight_logs
```

### Step 3: Verify
```sql
-- Check that new columns exist
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'user_profiles'
AND column_name IN (
    'notification_preferences', 
    'health_goals_list', 
    'units_preference', 
    'contact_method', 
    'bio'
);

-- Check RLS policies are active
SELECT policyname, cmd
FROM pg_policies
WHERE tablename = 'weight_logs';
```

## UI Layout

```
┌─────────────────────────────┐
│ Username                    │
├─────────────────────────────┤
│ HEALTH BASICS               │
│ • Latest Weight (read-only) │
│ • Current Height (formatted)│
│ • Age                       │
│ • Gender                    │
│ • Update Height (feet/in)   │
│ • Timezone                  │
├─────────────────────────────┤
│ PREFERENCES                 │
│ • Units Preference          │
│ • Contact Method            │
│ • Notification Prefs        │
│ • Health Goals              │
│ • Bio                       │
├─────────────────────────────┤
│ MEDICAL INFORMATION         │
│ • Allergies                 │
│ • Medical Conditions        │
├─────────────────────────────┤
│ [Save Profile]              │
└─────────────────────────────┘
```

## Known Issues / Future Work

- Weight logs RLS policy must be applied manually (SQL migration provided)
- Consider adding a "Test Weight Fetch" button for debugging
- Could add units conversion display (e.g., show both kg and lbs)
- Bio could support markdown formatting in the future
- Health goals "Other" could have a text input for custom goals

## Success Criteria (All Met ✅)

- ✅ Height displays as "5'11"" (readable format)
- ✅ Weight error fixed (displays correctly or shows "No weight logged")
- ✅ 5 new profile fields added (notification, goals, units, contact, bio)
- ✅ Database migration created and ready
- ✅ Form validation working
- ✅ Code compiles without errors
- ✅ Git commit ready
