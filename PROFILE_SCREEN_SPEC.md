# Profile Screen Specification (Function-First)

**Version:** 1.0  
**Status:** Design Complete  
**Target:** Production-ready profile management with Tier 1 + Tier 2 user data  

---

## Overview

Function-first profile screen for editing user data. Clean, simple form layout. No complex styling. All fields editable except latest weight (read-only display from weight_logs).

---

## Data Fields

### Tier 1: User Identity & Health Basics
- **Username** (text, unique, required)
- **Latest Weight** (READ-ONLY, kg - pulled from weight_logs)
- **Age** (integer, required)
- **Gender** (dropdown: Male, Female, Other, Prefer not to say)
- **Height** (integer, cm, required)
- **Timezone** (dropdown, common timezones)

### Tier 2: Medical Information
- **Allergies** (text area, nullable)
- **Medical Conditions** (multi-select checkboxes):
  - Diabetes
  - Hypertension
  - Heart Disease
  - Thyroid Issues
  - None
  - Other (with text field)

---

## Screen Layout

```
┌────────────────────────────────────────┐
│  [<] Profile                           │
├────────────────────────────────────────┤
│                                        │
│  Username                              │
│  [___________________________]         │
│                                        │
│  ──────────────────────────────        │
│  HEALTH BASICS                         │
│  ──────────────────────────────        │
│                                        │
│  Latest Weight (Read-only)             │
│  75.2 kg (logged 2 hours ago)          │
│                                        │
│  Age                                   │
│  [___________________________]         │
│                                        │
│  Gender                                │
│  [▼ Select gender___________]          │
│                                        │
│  Height (cm)                           │
│  [___________________________]         │
│                                        │
│  Timezone                              │
│  [▼ Select timezone_________]          │
│                                        │
│  ──────────────────────────────        │
│  MEDICAL INFORMATION                   │
│  ──────────────────────────────        │
│                                        │
│  Allergies                             │
│  [___________________________]         │
│  [___________________________]         │
│  [___________________________]         │
│                                        │
│  Medical Conditions                    │
│  □ Diabetes                            │
│  □ Hypertension                        │
│  □ Heart Disease                       │
│  □ Thyroid Issues                      │
│  □ None                                │
│  □ Other: [______________]             │
│                                        │
│                                        │
│  [Save Profile]                        │
│                                        │
│  ✓ Profile saved successfully          │
│                                        │
└────────────────────────────────────────┘
```

---

## User Experience Flow

### First-Time User (No Profile)
1. Opens Profile screen
2. Sees empty form with defaults
3. Fills in required fields (username, age, gender, height)
4. Optionally fills medical info
5. Taps "Save Profile" → Success message
6. Latest Weight shows "No weight logged yet" with CTA to log weight

### Returning User
1. Opens Profile screen
2. Form pre-populated with existing data
3. Latest Weight shows most recent log with timestamp
4. User edits any field
5. Taps "Save Profile" → Success message

### No Weight Logged Yet
- Display: "No weight logged yet"
- CTA: "Log your weight in the Weight Tracker"
- Does NOT block profile save

---

## Validation Rules

### Required Fields
- Username (1-50 characters, alphanumeric + underscore, unique)
- Age (10-120)
- Gender (must select one option)
- Height (50-300 cm)
- Timezone (must select from dropdown)

### Optional Fields
- Allergies (max 500 characters)
- Medical Conditions (can select multiple)

### Edge Cases
- Duplicate username → "Username already taken"
- Age out of range → "Age must be between 10 and 120"
- Height out of range → "Height must be between 50 and 300 cm"
- Network error → "Could not save profile. Please try again."

---

## Database Integration

### Weight Display Logic
```dart
// Fetch latest weight log
final latestWeight = await supabase
  .from('weight_logs')
  .select('weight_kg, logged_at')
  .eq('user_id', userId)
  .order('logged_at', ascending: false)
  .limit(1)
  .maybeSingle();

if (latestWeight != null) {
  // Display: "75.2 kg (logged 2 hours ago)"
  final timeAgo = formatTimeAgo(latestWeight['logged_at']);
  return "${latestWeight['weight_kg']} kg (logged $timeAgo)";
} else {
  return "No weight logged yet";
}
```

### Save Profile Logic
```dart
// Validate all fields
if (!validateForm()) {
  showError("Please fill in all required fields");
  return;
}

// Update user_profiles table
final response = await supabase
  .from('user_profiles')
  .update({
    'username': usernameController.text,
    'age': int.parse(ageController.text),
    'gender': selectedGender,
    'height_cm': int.parse(heightController.text),
    'timezone': selectedTimezone,
    'allergies': allergiesController.text,
    'medical_conditions': selectedMedicalConditions,
  })
  .eq('id', userId);

if (response.error == null) {
  showSuccess("Profile saved successfully");
} else {
  showError("Could not save profile. Please try again.");
}
```

---

## Success Criteria

✅ All Tier 1 + Tier 2 data fields designed  
✅ Function-first (no complex styling, just clean form layout)  
✅ Latest weight displays correctly (read-only)  
✅ Validation logic designed  
✅ Database schema clear  
✅ Implementation guide ready for coding  

---

## Future Enhancements (NOT in scope)

- Avatar upload
- Email/phone verification
- 2FA settings
- App theme preferences
- Data export
- Account deletion
- Premium subscription UI
- Payment method integration (placeholder for later)

---

## Figma Wireframe (Text-Based)

```
Header
├─ Back button (<)
├─ Title: "Profile"

Body (Scrollable)
├─ Section: User Identity
│  ├─ TextField: Username
│  
├─ Section: Health Basics
│  ├─ ReadOnlyDisplay: Latest Weight
│  ├─ TextField: Age
│  ├─ Dropdown: Gender
│  ├─ TextField: Height (cm)
│  ├─ Dropdown: Timezone
│  
├─ Section: Medical Information
│  ├─ TextArea: Allergies
│  ├─ CheckboxGroup: Medical Conditions
│     ├─ Checkbox: Diabetes
│     ├─ Checkbox: Hypertension
│     ├─ Checkbox: Heart Disease
│     ├─ Checkbox: Thyroid Issues
│     ├─ Checkbox: None
│     ├─ Checkbox: Other (with text field)

Footer
├─ Button: Save Profile (primary, full-width)
├─ SuccessMessage (conditional)
```

---

## Notes

- **Function over form:** Clean Material Design widgets, no custom theming yet
- **Weight logging:** User logs weight in Weight Tracker (separate screen), not here
- **Privacy:** All profile data protected by RLS (Row Level Security)
- **Offline support:** Future enhancement (cache profile, sync on reconnect)
- **Payment placeholder:** No UI for payment yet; reserved for later phase

---

**End of Spec**
