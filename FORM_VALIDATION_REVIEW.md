# Form Validation Review - CycleSetupFormV4

**Reviewed:** 2026-03-10  
**Commit:** cba424e  
**Build:** #279  

---

## 🔴 CRITICAL ISSUES

### 1. **Start Date Past Validation is Broken** (SEVERITY: HIGH)
**Location:** Line 144 (`_validateStartDate`)

```dart
} else if (_startDate!.isBefore(DateTime.now())) {
  _fieldErrors['startDate'] = 'Start date can\'t be in the past';
```

**Problem:** This check is fundamentally flawed:
- `DateTime.now()` includes time (hours, minutes, seconds)
- If user selects "today" in the date picker, it returns midnight (`2026-03-10 00:00:00`)
- But `DateTime.now()` returns current time (`2026-03-10 13:12:00`)
- Result: **TODAY is flagged as "in the past"** ❌

**Fix:**
```dart
} else if (_startDate!.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
  // Or better:
  final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  if (_startDate!.isBefore(today)) {
    _fieldErrors['startDate'] = 'Start date can\'t be in the past';
  }
```

**Impact:** Users cannot start cycles "today" - major UX blocker.

---

### 2. **Integer Parsing with Decimals** (SEVERITY: MEDIUM)
**Location:** Line 133 (`_validateCycleDuration`)

```dart
_cycleDurationWeeks = int.tryParse(value);
```

**Problem:** User enters "4.5" weeks → `int.tryParse` returns `null` → error shown, but WHY?
- Error message says "Cycle should be 1-52 weeks" 
- User has NO CLUE that decimals are invalid
- Silent failure creates confusion

**Fix:**
```dart
void _validateCycleDuration() {
  setState(() {
    if (_cycleDurationWeeks == null) {
      final rawValue = _cycleDurationController.text.trim();
      if (rawValue.isNotEmpty) {
        // User entered something but int.tryParse failed
        _fieldErrors['cycleDuration'] = 'Must be a whole number (no decimals)';
      } else {
        _fieldErrors['cycleDuration'] = 'Required';
      }
    } else if (_cycleDurationWeeks! < 1 || _cycleDurationWeeks! > 52) {
      _fieldErrors['cycleDuration'] = 'Cycle should be 1-52 weeks';
    } else {
      _fieldErrors['cycleDuration'] = null;
    }
  });
}
```

**Same issue for:**
- Phase duration fields (TextFields expecting integers)

---

### 3. **Validation Order Matters** (SEVERITY: LOW)
**Location:** Line 109 (`_validateDesiredDose`)

```dart
} else if (_totalPeptideMg != null && _desiredDosageMg! > _totalPeptideMg!) {
  _fieldErrors['desiredDose'] = 'Dose can\'t exceed vial size';
```

**Problem:** This cross-field validation only triggers when `_validateDesiredDose()` is called.
- User enters vial=5mg, dose=10mg (error shown ✓)
- User changes vial to 15mg (dose is now valid, but error persists ❌)
- WHY? Because `_validateDesiredDose()` wasn't re-called when vial changed

**Fix:** In `_validateVialSize()`, add:
```dart
void _validateVialSize() {
  setState(() {
    // ... existing validation ...
  });
  // Re-validate dose since vial size changed
  _validateDesiredDose();
}
```

---

## ⚠️ DESIGN FLAWS

### 4. **_isFormValid() Logic Gap**
**Location:** Line 170

```dart
bool _isFormValid() {
  return _selectedPeptide != null &&
      _totalPeptideMg != null &&
      _desiredDosageMg != null &&
      _concentrationMl != null &&
      _cycleDurationWeeks != null &&
      _startDate != null &&
      _phases.isNotEmpty &&
      _fieldErrors.values.every((error) => error == null);
}
```

**Problem:** This checks if fields are non-null AND no errors exist.
- BUT: Validation methods aren't called until user interacts with field
- Fresh form: all fields null, no errors → button shows "Complete form to create"
- User enters peptide → button STILL disabled (other validators never ran)

**Current behavior:**
1. User enters peptide → `_validatePeptide()` called → error cleared
2. User enters vial → `_validateVialSize()` called → error cleared
3. User skips dose field → `_validateDesiredDose()` NEVER called → no error set
4. Button stays disabled because `_desiredDosageMg == null` (correct)
5. BUT: No error shown under dose field (confusing)

**Is this a bug?** Debatable. UX question: should errors appear on untouched fields?

**Options:**
- **A) Validate-on-blur:** Only show errors after user leaves field (industry standard)
- **B) Validate-all-on-submit:** Show all errors when "CREATE CYCLE" tapped
- **Current:** Validate-on-change (errors appear immediately) ← This is good for inline feedback

**Recommendation:** Keep validate-on-change, but call `_validateAllFields()` when submit button is tapped while disabled (give user full context).

---

### 5. **Phases Validation Incomplete**
**Location:** Line 151 (`_validatePhases`)

```dart
final totalPhaseDays = _phases.fold<int>(
  0,
  (sum, phase) => sum + (phase.endDate != null && phase.startDate != null
      ? phase.endDate!.difference(phase.startDate!).inDays + 1
      : 0),
);
if (totalPhaseDays > totalDays) {
  _fieldErrors['phases'] = 'Phases exceed cycle duration';
```

**Missing validations:**
1. **Overlapping phases:** User manually adjusts dates → phases overlap → no check
2. **Gap detection:** Ramp up ends March 5, plateau starts March 10 → 4-day gap → no warning
3. **Zero-duration phases:** User sets ramp up to 0 days → silently ignored
4. **Negative durations:** Edge case if dates are swapped

**Why it's low priority:** Phase dates are auto-calculated by `_recalculatePhaseDates()`, so user can't manually create overlaps. BUT if future versions allow manual date editing, this will break.

---

## ✅ WHAT WORKS WELL

### Strong Points:
1. **Real-time validation:** Errors shown immediately on field change (good UX)
2. **Helper text:** All fields have "5-500mg recommended" guidance (excellent)
3. **Validation summary:** Bottom of form shows all errors (helpful overview)
4. **Disabled button:** Can't submit invalid form (prevents bad data)
5. **Cross-field validation:** Dose > vial check exists (needs fix but concept is solid)

---

## 🎯 QUICK WINS (Easy Improvements)

### 1. **Fix DateTime comparison** (10 minutes)
Replace `DateTime.now()` with date-only comparison.

### 2. **Improve decimal error messages** (5 minutes)
Check if `int.tryParse` failed due to decimal input → show "Must be whole number".

### 3. **Add vial↔dose dependency** (5 minutes)
When vial size changes, re-validate dose field.

### 4. **Call _validateAllFields() on submit attempt** (10 minutes)
If button disabled and user taps it, run full validation to show all errors at once.

### 5. **Add "Save as Draft" option** (30 minutes)
Allow saving incomplete cycles for later (bypass validation) - good for long forms.

---

## 📊 PERFORMANCE ANALYSIS

### Current Complexity:
- **Per-field validation:** O(1) - fine
- **_isFormValid():** O(n) where n = number of errors (7) - trivial
- **_validatePhases():** O(p) where p = number of phases (typically 1-3) - fine
- **Total:** Negligible overhead, no concerns

### setState() Frequency:
- Every keystroke triggers `setState()` → widget rebuilds
- This is standard Flutter practice for forms
- Performance impact: **None** (form is small, no complex layouts)

---

## 🎨 UX IMPROVEMENTS

### Timing: Validate-on-Change vs Validate-on-Blur

**Current:** Validate-on-change (every keystroke)

**Pros:**
- Instant feedback (user knows immediately if input is invalid)
- Good for constrained fields (e.g., 5-500mg range)

**Cons:**
- Annoying for long inputs (error shows before user finishes typing)
- Example: User types "1" → error: "Dose should be 0.1-10mg" → types "0" → error gone
  - Better: wait until user finishes

**Recommendation:**
- **Keep validate-on-change for range checks** (5-500mg) - immediate feedback is good
- **Consider validate-on-blur for text fields** (notes, names) - less intrusive
- **Current implementation is acceptable** - not a blocker

### Validation Summary: Helpful or Clutter?

**Current:** Bottom of form shows list of errors when form invalid.

**Analysis:**
- **Helpful:** Shows ALL errors at once (user doesn't have to scroll to find issues)
- **Clutter:** Redundant (errors already shown under each field)

**Recommendation:** Keep it, BUT:
- Only show summary when user attempts to submit (taps disabled button)
- Don't show it by default (reduces visual noise)
- Change text: "⚠️ Fix the following to continue:" → "⚠️ Complete these fields:"

### Button Text: "Complete form to create"

**Current:** Button text changes when disabled: "Complete form to create"

**Analysis:**
- **Good:** Explains WHY button is disabled
- **Bad:** Vague (doesn't say WHICH fields are incomplete)

**Recommendation:** 
- Change to: "Complete X fields" (e.g., "Complete 3 fields")
- Or: Keep current text + show validation summary on tap

---

## 🐛 EDGE CASES ANALYSIS

### 1. User enters "5.5" in week field
**Current behavior:** `int.tryParse("5.5")` → `null` → error: "Cycle should be 1-52 weeks"  
**Issue:** Error message doesn't explain decimals aren't allowed  
**Fix:** Detect decimal input → show "Must be whole number"

### 2. User deletes all text
**Current behavior:** `int.tryParse("")` → `null` → error: "Required"  
**Works correctly** ✓

### 3. User corrects error
**Current behavior:** `onChanged` triggers → `_validateX()` called → error cleared  
**Works correctly** ✓

### 4. Start date validation for past dates
**Current behavior:** Broken (see Critical Issue #1)  
**Fix:** Use date-only comparison

### 5. User enters negative number
**Current behavior:** Passes parsing, fails range check → error: "Dose should be 0.1-10mg"  
**Works correctly** ✓

### 6. User enters "0" (zero dose/vial)
**Vial:** 0 < 5 → error: "Vial size should be 5-500mg" ✓  
**Dose:** 0 < 0.1 → error: "Dose should be 0.1-10mg" ✓  
**Works correctly** ✓

### 7. User enters extremely large number
**Example:** 9999mg vial  
**Current:** 9999 > 500 → error: "Vial size should be 5-500mg" ✓  
**Works correctly** ✓

### 8. User changes cycle duration after adding phases
**Current behavior:** `_updateCycleDuration()` → `_recalculatePhaseDates()` → phases adjusted  
**Works correctly** ✓

---

## 🏗️ ARCHITECTURE FEEDBACK

### Map<String, String?> _fieldErrors - Good or Bad?

**Current design:**
```dart
final Map<String, String?> _fieldErrors = {
  'peptide': null,
  'vialSize': null,
  'desiredDose': null,
  // ...
};
```

**Pros:**
- Simple, centralized error storage
- Easy to check all errors: `_fieldErrors.values.every((e) => e == null)`
- Easy to display: `errorText: _fieldErrors['vialSize']`

**Cons:**
- String keys are error-prone (typo risk: `_fieldErrors['vailSize']` compiles but breaks at runtime)
- No type safety (can't enforce which keys exist)

**Better approach:**
```dart
class FormErrors {
  String? peptide;
  String? vialSize;
  String? desiredDose;
  // ...
  
  bool get hasErrors => [peptide, vialSize, desiredDose, ...].any((e) => e != null);
}

final _errors = FormErrors();
```

**But:** Current Map approach is **fine for this form** (7 fields, low complexity).  
**Recommendation:** Keep Map, but add String constants to avoid typos:

```dart
// At top of class
static const _FIELD_PEPTIDE = 'peptide';
static const _FIELD_VIAL_SIZE = 'vialSize';
// ...

_fieldErrors[_FIELD_VIAL_SIZE] = 'Required';
```

---

## 🧪 TESTING RECOMMENDATIONS

### Unit Tests (High Priority)

```dart
testWidgets('Vial size validation rejects values outside 5-500mg', (tester) async {
  await tester.pumpWidget(CycleSetupFormV4());
  await tester.enterText(find.byKey(Key('vialSizeField')), '3');
  await tester.pump();
  expect(find.text('Vial size should be 5-500mg'), findsOneWidget);
});

testWidgets('Start date validation allows today', (tester) async {
  await tester.pumpWidget(CycleSetupFormV4());
  // Select today's date
  await tester.tap(find.text('START DATE'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('${DateTime.now().day}'));
  await tester.tap(find.text('OK'));
  await tester.pump();
  expect(find.text('Start date can\'t be in the past'), findsNothing);
});

testWidgets('Desired dose validation fails when exceeding vial size', (tester) async {
  await tester.pumpWidget(CycleSetupFormV4());
  await tester.enterText(find.byKey(Key('vialSizeField')), '10');
  await tester.enterText(find.byKey(Key('desiredDoseField')), '15');
  await tester.pump();
  expect(find.text('Dose can\'t exceed vial size'), findsOneWidget);
});
```

### Integration Tests (Medium Priority)

```dart
testWidgets('Form submission blocked when validation fails', (tester) async {
  await tester.pumpWidget(CycleSetupFormV4());
  final button = find.text('CREATE CYCLE');
  expect(tester.widget<ElevatedButton>(button).enabled, false);
  
  // Fill all fields
  await tester.enterText(find.byKey(Key('vialSizeField')), '10');
  await tester.enterText(find.byKey(Key('desiredDoseField')), '1');
  // ...
  await tester.pump();
  expect(tester.widget<ElevatedButton>(button).enabled, true);
});
```

### Manual Test Cases

| Test Case | Steps | Expected | Priority |
|-----------|-------|----------|----------|
| Decimal in weeks | Enter "4.5" in cycle duration | Show "Must be whole number" | HIGH |
| Start today | Select today's date | No error shown | HIGH |
| Dose > vial | Vial=5mg, Dose=10mg | Show error | HIGH |
| Change vial after error | Set vial=15mg | Dose error clears | MEDIUM |
| Submit with empty fields | Tap CREATE with missing fields | Show validation summary | MEDIUM |
| Add phases after cycle | Enter cycle duration → add phases | Phases fit within cycle | LOW |

---

## 📈 FUTURE EXTENSIBILITY

### What if you add more fields later?

**Current approach scales well:**
- Add entry to `_fieldErrors` Map
- Add `_validateNewField()` method
- Add `onChanged: (v) => _validateNewField()` to TextField
- Add field check to `_isFormValid()`

**Good:** Consistent pattern, easy to extend  
**Risk:** Forgetting to add validation to `_validateAllFields()` or `_isFormValid()` (no compile-time check)

**Recommendation:**
- Document the pattern in a comment at top of class
- Consider code generation (e.g., freezed) if form grows beyond 15 fields

---

## 🎯 SEVERITY SUMMARY

| Issue | Severity | Impact | Fix Time |
|-------|----------|--------|----------|
| Start date comparison (DateTime.now() bug) | **HIGH** | Users can't start today | 10 min |
| Integer parsing error messages | **MEDIUM** | Confusing UX | 5 min |
| Vial→dose dependency | **LOW** | Error persists after vial change | 5 min |
| Phase overlap detection | **LOW** | Future risk (not blocking now) | 30 min |
| Validation summary timing | **LOW** | Minor UX polish | 10 min |

**Total fix time for HIGH+MEDIUM issues:** ~20 minutes

---

## ✅ CONCLUSION

**Overall Grade:** B+ (Good, but needs critical date fix)

**Strengths:**
- Comprehensive field validation (7 validators)
- Real-time feedback (good UX)
- Helper text on all fields (excellent)
- Cross-field validation exists (dose vs vial)

**Weaknesses:**
- DateTime comparison broken (blocks "start today")
- Error messages don't explain decimal restrictions
- Cross-field validation is one-directional (vial change doesn't re-validate dose)

**Recommendation:** Fix the 2 critical issues, ship the rest as follow-up polish.
