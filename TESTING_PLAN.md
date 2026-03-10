# Profile Screen Testing Plan

## Prerequisites
✅ Database migration applied (see MIGRATION_INSTRUCTIONS.md)
✅ App compiled successfully
✅ Test user logged in

## Test Scenarios

### 1. First-Time User (No Profile Data)
**Steps:**
1. Login with fresh account
2. Open hamburger menu → tap "Profile"
3. Observe empty form with default timezone
4. Latest Weight shows "No weight logged yet"

**Expected:**
- All fields empty except timezone (defaults to America/New_York)
- Save button enabled
- No validation errors shown

### 2. Fill Required Fields
**Steps:**
1. Enter username: "testuser123"
2. Enter age: "30"
3. Select gender: "Male"
4. Enter height: "180"
5. Select timezone: "Eastern Time"
6. Tap "Save Profile"

**Expected:**
- Success message appears: "Profile saved successfully"
- Message disappears after 3 seconds
- Data persists (reload screen to verify)

### 3. Validation: Empty Fields
**Steps:**
1. Clear username field
2. Tap "Save Profile"

**Expected:**
- Error shown: "Username is required"
- Save blocked

### 4. Validation: Invalid Username
**Steps:**
1. Enter username: "test user" (space)
2. Tap "Save Profile"

**Expected:**
- Error: "Only letters, numbers, and underscores allowed"

**Test cases:**
- "test user" → Error (space)
- "test-user" → Error (hyphen)
- "test_user" → Success
- "TestUser123" → Success
- "a" → Success (1 char)
- "a".repeat(51) → Error (too long)

### 5. Validation: Age Range
**Test cases:**
- Age: 9 → Error "Age must be between 10 and 120"
- Age: 10 → Success
- Age: 30 → Success
- Age: 120 → Success
- Age: 121 → Error

### 6. Validation: Height Range
**Test cases:**
- Height: 49 → Error "Height must be between 50 and 300 cm"
- Height: 50 → Success
- Height: 180 → Success
- Height: 300 → Success
- Height: 301 → Error

### 7. Validation: Duplicate Username
**Steps:**
1. Save profile with username "testuser123"
2. Logout, create new account
3. Try to save profile with same username "testuser123"

**Expected:**
- Error: "Username already taken"

### 8. Medical Conditions: None Selected
**Steps:**
1. Check "None" checkbox
2. Try to check "Diabetes"

**Expected:**
- "Diabetes" checkbox disabled/grayed out
- Only "None" can be checked

### 9. Medical Conditions: Multiple Selections
**Steps:**
1. Check "Diabetes"
2. Check "Hypertension"
3. Check "None"

**Expected:**
- Checking "None" clears all others
- Only "None" remains checked

### 10. Medical Conditions: Other
**Steps:**
1. Check "Other" checkbox
2. Text field appears
3. Enter "Asthma"
4. Save profile
5. Reload screen

**Expected:**
- Text field shows below "Other" checkbox
- Saved as "other: Asthma" in database
- Loads correctly on reload

### 11. Allergies: Long Text
**Steps:**
1. Enter 500 characters in allergies field
2. Save profile

**Expected:**
- Save succeeds
- Data persists

**Steps:**
1. Enter 501 characters
2. Try to type more

**Expected:**
- Character limit enforced at 500

### 12. Latest Weight Display
**Setup:**
1. First save profile (no weight logged)
2. Go to Weight Tracker
3. Log weight: 75.2 kg
4. Return to Profile screen

**Expected:**
- Shows: "75.2 kg (logged X minutes ago)"
- Time updates correctly (test after 1 hour, 1 day)

### 13. Returning User (Profile Exists)
**Steps:**
1. Save profile with all fields filled
2. Close app
3. Reopen, login
4. Open Profile screen

**Expected:**
- All fields pre-populated
- Username, age, gender, height, timezone loaded
- Allergies loaded
- Medical conditions checkboxes checked correctly
- Latest weight displayed

### 14. Edit Existing Profile
**Steps:**
1. Load existing profile
2. Change age from 30 to 31
3. Save

**Expected:**
- Success message shown
- Change persists

### 15. Network Error Handling
**Steps:**
1. Disable network
2. Open Profile screen

**Expected:**
- Loading indicator shows
- Error message: "Error loading profile: ..."

**Steps:**
1. Fill form
2. Disable network
3. Tap Save

**Expected:**
- Error: "Could not save profile. Please try again."

### 16. Navigation
**Steps:**
1. From home screen, tap hamburger menu
2. Tap "Profile"
3. Profile screen opens
4. Tap back arrow

**Expected:**
- Returns to home screen
- No crashes

### 17. Timezone Display
**Steps:**
1. Select each timezone from dropdown
2. Save
3. Verify saved correctly

**Timezones to test:**
- Eastern Time
- Pacific Time
- London
- Tokyo

## Edge Cases

### EC1: Very Young User
- Age: 10 → Should work
- Age: 9 → Should fail

### EC2: Very Old User
- Age: 120 → Should work
- Age: 121 → Should fail

### EC3: Very Short Person
- Height: 50 cm → Should work
- Height: 49 cm → Should fail

### EC4: Very Tall Person
- Height: 300 cm → Should work
- Height: 301 cm → Should fail

### EC5: Username Edge Cases
- Single char: "a" → Should work
- 50 chars: "a"*50 → Should work
- 51 chars: "a"*51 → Should fail
- Special chars: "test@user" → Should fail
- Underscore: "test_user" → Should work

### EC6: Empty Medical Conditions
- No checkboxes checked → Should work (empty array)

## Performance Tests

### P1: Large Allergies Text
- Enter 500 characters → No lag on save/load

### P2: Many Medical Conditions
- Check all conditions → No lag

### P3: Rapid Save Clicks
- Click Save multiple times rapidly → Only one save executes

## Security Tests

### S1: SQL Injection
**Steps:**
1. Username: "'; DROP TABLE user_profiles; --"
2. Save

**Expected:**
- Saved as literal text (Supabase parameterizes queries)
- No SQL injection

### S2: Cross-User Data Access
**Steps:**
1. User A saves profile
2. Logout, login as User B
3. Open Profile

**Expected:**
- User B sees empty form (RLS prevents cross-user access)

## Acceptance Criteria

✅ All required fields validated
✅ Latest weight displays correctly
✅ Medical conditions logic works
✅ Username uniqueness enforced
✅ Data persists across sessions
✅ Navigation works
✅ Error/success messages show
✅ No crashes or exceptions
✅ Timezone saved correctly
✅ Allergies save (optional field)

## Known Issues / Future Enhancements

- [ ] No offline support (requires network)
- [ ] No loading state for weight display
- [ ] No debouncing on rapid saves
- [ ] Medical conditions: "Other" field not validated if checkbox unchecked
- [ ] Timezone dropdown could be searchable for long list
