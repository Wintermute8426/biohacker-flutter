# 🚀 Deployment Instructions - Profile Fix + Imperial Height

**Status:** ✅ Code complete, awaiting deployment  
**Commit:** `b631df6` - fix: Profile save + convert height to imperial (feet/inches)  
**Date:** March 10, 2026

---

## ⚡ Quick Deploy (5 minutes)

### Step 1: Apply Database Migration
1. Open Supabase SQL Editor: https://supabase.com/dashboard
2. Navigate to: SQL Editor → New Query
3. Copy contents of `DATABASE_MIGRATION_IMPERIAL.sql`
4. Paste and click **Run**
5. Verify success:
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'user_profiles' 
   AND column_name IN ('height_feet', 'height_inches');
   ```
   Expected: 2 rows returned

### Step 2: Deploy Flutter App
```bash
cd biohacker-flutter

# Clean build
flutter clean
flutter pub get

# Build APK
flutter build apk --release

# Or run on device for testing
flutter run --release
```

### Step 3: Test
1. Open Profile screen
2. Fill height: `5` feet `11` inches
3. Click "Save Profile"
4. ✅ Success message should appear
5. Navigate away and back → height should persist

---

## 🔍 What Was Fixed

### Problem #1: Profile Save Not Working
**Root Cause:** Database columns didn't exist (migration never applied)  
**Solution:** Created `DATABASE_MIGRATION_IMPERIAL.sql` with all required columns  
**Evidence:** Console logs now show detailed error messages

### Problem #2: Height in Centimeters
**Root Cause:** U.S. users expect feet/inches, not cm  
**Solution:** Two input fields (feet 0-9, inches 0-11) with live preview  
**Example:** "Height: 5'11\""

---

## 📋 Pre-Deployment Checklist

- [x] Database migration script created (`DATABASE_MIGRATION_IMPERIAL.sql`)
- [x] Flutter code updated (profile_screen.dart, user_profile_service.dart)
- [x] Enhanced logging added (debug mode)
- [x] Error handling improved (specific error messages)
- [x] Git commit created (`b631df6`)
- [x] Documentation written (PROFILE_FIX_SUMMARY.md)
- [ ] **Database migration applied to Supabase** ⬅️ DO THIS FIRST
- [ ] Flutter app rebuilt (flutter build apk)
- [ ] Manual testing on device
- [ ] Verify height displays correctly ("5'11\"")
- [ ] Verify save works (success message)

---

## 🧪 Testing Scenarios

| Test | Expected Result | Pass/Fail |
|------|-----------------|-----------|
| Save profile with height 5'11" | Success message, data persists | ⏳ |
| Navigate away and back | Height shows "5'11\"" | ⏳ |
| Try feet = 10 | Error: "3-7" | ⏳ |
| Try inches = 12 | Error: "0-11" | ⏳ |
| Duplicate username | Error: "Username already taken" | ⏳ |
| Empty username | Error: "Username is required" | ⏳ |

---

## 🐛 Troubleshooting

### Error: "Database error: Missing columns"
→ Migration not applied yet. Run `DATABASE_MIGRATION_IMPERIAL.sql` in Supabase

### Error: "Username already taken"
→ Expected behavior. Username must be unique. Try a different username.

### Save button does nothing
→ Check console logs (`flutter run`). Look for `[ProfileScreen]` or `[UserProfile]` errors.

### Height not displaying
→ Verify `height_feet` and `height_inches` exist in database:
```sql
SELECT height_feet, height_inches FROM user_profiles WHERE id = '<user_id>';
```

---

## 🔄 Rollback Plan

If deployment fails:

1. **Rollback database:**
   ```sql
   -- See DATABASE_MIGRATION_IMPERIAL.sql (bottom of file)
   ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_feet CASCADE;
   ALTER TABLE user_profiles DROP COLUMN IF EXISTS height_inches CASCADE;
   -- etc. (see full script)
   ```

2. **Rollback code:**
   ```bash
   git revert b631df6
   flutter clean && flutter pub get
   flutter build apk
   ```

---

## 📊 Success Metrics

After deployment, verify:
- ✅ Profile save success rate: 100% (no silent failures)
- ✅ Height display accuracy: Correct format ("5'11\"")
- ✅ Validation working: Feet 3-7, inches 0-11
- ✅ Error messages helpful: Specific, actionable
- ✅ Console logs informative: Debug mode shows details

---

## 📞 Support

If issues arise:
1. Check console logs (`flutter run`) for `[ProfileScreen]` or `[UserProfile]` messages
2. Verify migration applied: Query `information_schema.columns`
3. Check RLS policies: Users should only update own profiles
4. Review `PROFILE_FIX_SUMMARY.md` for detailed debugging guide

---

## ✅ Next Steps

1. **DEPLOY MIGRATION FIRST** (must be done before deploying app)
2. Build and deploy Flutter app
3. Test on real device
4. Mark all test scenarios as passed
5. Monitor console logs for errors
6. Celebrate! 🎉

**Estimated Time:** 5-10 minutes  
**Risk Level:** Low (idempotent migration, includes rollback)  
**Dependencies:** Supabase access, Flutter SDK
