# Profile Screen Implementation Guide

**Version:** 1.0  
**Estimated Time:** 2-3 hours  
**Difficulty:** Intermediate  

---

## Prerequisites

- Flutter 3.x installed
- Supabase Flutter SDK configured
- Riverpod for state management
- Existing `user_profiles` table in Supabase

---

## Implementation Steps

### Step 1: Run Database Migration (10 min)

1. Open Supabase Dashboard → SQL Editor
2. Copy contents of `DATABASE_MIGRATION.sql`
3. Execute migration
4. Verify columns exist:
   ```sql
   SELECT column_name, data_type 
   FROM information_schema.columns
   WHERE table_name = 'user_profiles'
     AND column_name IN ('username', 'age', 'gender', 'height_cm', 'allergies', 'medical_conditions');
   ```
5. Expected result: 6 rows (all new columns)

---

### Step 2: Update UserProfile Model (15 min)

**File:** `/lib/services/user_profile_service.dart`

1. Add new fields to `UserProfile` class:
   ```dart
   class UserProfile {
     final String userId;
     final String? username;
     final int? age;
     final String? gender;
     final int? heightCm;
     final String? allergies;
     final List<String> medicalConditions;
     final String experienceLevel;
     final List<String> healthGoals;
     final double? baselineWeight;
     final double? baselineBodyFat;
     final Map<String, dynamic>? baselineLabs;
     final String timezone;
     final bool onboardingCompleted;
     final DateTime? onboardingCompletedAt;
     
     // ... constructor, fromJson, toJson, copyWith
   }
   ```

2. Update `fromJson`:
   ```dart
   factory UserProfile.fromJson(Map<String, dynamic> json) {
     return UserProfile(
       userId: json['id'] ?? '',
       username: json['username'],
       age: json['age'],
       gender: json['gender'],
       heightCm: json['height_cm'],
       allergies: json['allergies'],
       medicalConditions: json['medical_conditions'] != null 
         ? List<String>.from(json['medical_conditions']) 
         : [],
       // ... existing fields
     );
   }
   ```

3. Update `toJson`:
   ```dart
   Map<String, dynamic> toJson() {
     return {
       'id': userId,
       'username': username,
       'age': age,
       'gender': gender,
       'height_cm': heightCm,
       'allergies': allergies,
       'medical_conditions': medicalConditions,
       // ... existing fields
     };
   }
   ```

4. Update `copyWith` method

---

### Step 3: Update UserProfileService (15 min)

**File:** `/lib/services/user_profile_service.dart`

Add method for updating profile:
```dart
Future<UserProfile?> updateProfileDetails(
  String userId, {
  String? username,
  int? age,
  String? gender,
  int? heightCm,
  String? allergies,
  List<String>? medicalConditions,
  String? timezone,
}) async {
  try {
    final updates = <String, dynamic>{};
    
    if (username != null) updates['username'] = username;
    if (age != null) updates['age'] = age;
    if (gender != null) updates['gender'] = gender;
    if (heightCm != null) updates['height_cm'] = heightCm;
    if (allergies != null) updates['allergies'] = allergies;
    if (medicalConditions != null) updates['medical_conditions'] = medicalConditions;
    if (timezone != null) updates['timezone'] = timezone;

    final response = await _supabase
        .from('user_profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();

    return UserProfile.fromJson(response);
  } catch (e) {
    print('Error updating profile: $e');
    rethrow;
  }
}
```

---

### Step 4: Create Weight Display Helper (10 min)

**File:** `/lib/services/weight_display_helper.dart`

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class WeightDisplayHelper {
  final SupabaseClient _supabase;

  WeightDisplayHelper(this._supabase);

  Future<String> getLatestWeightDisplay(String userId) async {
    try {
      final response = await _supabase
          .from('weight_logs')
          .select('weight_kg, logged_at')
          .eq('user_id', userId)
          .order('logged_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response == null) {
        return 'No weight logged yet';
      }

      final weightKg = response['weight_kg'] as double;
      final loggedAt = DateTime.parse(response['logged_at']);
      final timeAgo = timeago.format(loggedAt, locale: 'en_short');

      return '$weightKg kg (logged $timeAgo)';
    } catch (e) {
      print('Error fetching latest weight: $e');
      return 'Error loading weight';
    }
  }
}
```

**Add dependency to `pubspec.yaml`:**
```yaml
dependencies:
  timeago: ^3.5.0
```

---

### Step 5: Create Profile Screen UI (60 min)

**File:** `/lib/screens/profile_screen.dart`

See `CODE_EXAMPLES.dart` for full implementation.

Key components:
1. `ProfileScreenState` class (holds form data)
2. Text controllers for all editable fields
3. Validation logic
4. Form submission logic
5. Success/error messages

---

### Step 6: Add Navigation (5 min)

**In main navigation/bottom bar:**
```dart
// Add Profile tab/screen
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => ProfileScreen()),
);
```

---

### Step 7: Testing Checklist (30 min)

#### Unit Tests
- [ ] UserProfile model serialization/deserialization
- [ ] Validation logic (username, age, height)
- [ ] Weight display helper with mock data

#### Integration Tests
- [ ] Save profile with all fields
- [ ] Save profile with only required fields
- [ ] Handle duplicate username error
- [ ] Display latest weight correctly
- [ ] Display "No weight logged yet" when no logs

#### Manual Tests
1. **First-time user:**
   - Open Profile screen
   - Fill required fields
   - Save → Success message
   - Reload screen → Data persists

2. **Existing user:**
   - Open Profile screen
   - Data pre-populated
   - Edit field → Save → Success

3. **Validation:**
   - Leave username empty → Error
   - Enter age 5 → Error (must be 10-120)
   - Enter height 20 → Error (must be 50-300)
   - Username with spaces → Error (alphanumeric + underscore only)

4. **Weight display:**
   - No weight logged → "No weight logged yet"
   - Weight logged → "75.2 kg (logged 2 hours ago)"

5. **Medical conditions:**
   - Select "None" → Other checkboxes disabled
   - Select "Other" → Text field appears
   - Select multiple → Saves as JSON array

---

## Dependencies

**Required packages:**
```yaml
dependencies:
  flutter:
    sdk: flutter
  supabase_flutter: ^2.0.0
  flutter_riverpod: ^2.4.0
  timeago: ^3.5.0
```

**Optional (for better UI):**
```yaml
dependencies:
  flutter_form_builder: ^9.1.0  # Advanced form handling
  intl: ^0.18.0                 # Date/time formatting
```

---

## File Structure

```
lib/
├── screens/
│   └── profile_screen.dart          (NEW)
├── services/
│   ├── user_profile_service.dart    (MODIFY)
│   └── weight_display_helper.dart   (NEW)
├── widgets/
│   ├── profile_form_field.dart      (OPTIONAL - reusable field widget)
│   └── medical_conditions_selector.dart (OPTIONAL - checkbox group widget)
└── models/
    └── user_profile.dart            (MODIFY - if separated from service)
```

---

## Common Issues & Solutions

### Issue: Duplicate username error
**Solution:** Check username uniqueness before save:
```dart
final existing = await supabase
  .from('user_profiles')
  .select('id')
  .eq('username', username)
  .maybeSingle();

if (existing != null && existing['id'] != userId) {
  throw Exception('Username already taken');
}
```

### Issue: Weight not displaying
**Solution:** Verify `weight_logs` table has data:
```sql
SELECT * FROM weight_logs WHERE user_id = 'xxx' ORDER BY logged_at DESC LIMIT 1;
```

### Issue: Medical conditions not saving
**Solution:** Ensure JSON array format:
```dart
// Correct:
medicalConditions: ['diabetes', 'hypertension']

// Incorrect:
medicalConditions: 'diabetes, hypertension'  // NOT a JSON array!
```

### Issue: Timezone dropdown slow to load
**Solution:** Use static list of common timezones:
```dart
const commonTimezones = [
  'America/New_York',
  'America/Chicago',
  'America/Denver',
  'America/Los_Angeles',
  'Europe/London',
  'Europe/Paris',
  'Asia/Tokyo',
  // ... add more
];
```

---

## Performance Optimization

1. **Cache profile data:** Use Riverpod's `FutureProvider` with auto-refresh
2. **Debounce form validation:** Use `Timer` to validate after 500ms
3. **Lazy-load timezones:** Only fetch full list when dropdown opens
4. **Offline support (future):** Use Hive/SQFlite to cache profile locally

---

## Security Checklist

- [x] Row Level Security (RLS) enabled on `user_profiles`
- [x] Users can only update their own profile
- [x] Username uniqueness enforced at database level
- [x] Input sanitization (no SQL injection risk with Supabase client)
- [x] Sensitive data (allergies, medical conditions) protected by RLS

---

## Next Steps (Future Enhancements)

1. **Avatar upload:** Add profile picture using Supabase Storage
2. **Email verification:** Send verification link on email change
3. **2FA setup:** Add two-factor authentication UI
4. **Data export:** Allow user to download their profile as JSON
5. **Account deletion:** Add "Delete Account" button with confirmation

---

## Support & Troubleshooting

**Supabase Dashboard:** Check RLS policies if save fails  
**Flutter DevTools:** Inspect network requests for errors  
**Console logs:** Look for `print()` statements with error details

---

**End of Implementation Guide**
