# Form Validation Requirements - CycleSetupFormV4

## Executive Summary

**Current State:** Zero form validation. Users can submit cycles with invalid data (0mg vials, negative dosages, 1000-week cycles).

**Impact:** 
- Invalid cycles crash the app
- Garbage data in database
- Poor user experience (errors happen at submit, not during input)
- No guidance for valid ranges

**Priority:** HIGH - Blocking issue for production release

---

## 1. Field-by-Field Validation Rules

### 1.1 Peptide Selection (Required)
**Current:** Optional, no validation  
**Required Validation:**
- ✅ **Required:** Must select a peptide
- ✅ **Error Message:** "Please select a peptide to continue"
- ✅ **Trigger:** On submit (immediate)

**Implementation:**
```dart
if (_selectedPeptide == null || _selectedPeptide!.isEmpty) {
  return ValidationError('Please select a peptide to continue');
}
```

---

### 1.2 Vial Size (Total Peptide mg)
**Current:** No range checking, accepts any number  
**Required Validation:**
- ✅ **Required:** Cannot be null or empty
- ✅ **Range:** 5mg - 500mg (reasonable pharmaceutical range)
- ✅ **Decimal places:** Max 2 decimal places (e.g., 10.50)
- ✅ **Edge cases:**
  - Reject: 0, negative, > 500
  - Warn (but allow): < 5mg (rare but possible for research peptides)

**Error Messages:**
- Empty: "Enter vial size in mg"
- Out of range: "Vial size must be between 5mg and 500mg"
- Too many decimals: "Use max 2 decimal places (e.g., 10.50)"

**Implementation:**
```dart
String? _validateVialSize(double? value) {
  if (value == null) return "Enter vial size in mg";
  if (value <= 0) return "Vial size must be greater than 0mg";
  if (value > 500) return "Vial size cannot exceed 500mg (check your units)";
  if (value < 5) return "⚠️ Unusually small vial (< 5mg). Is this correct?";
  return null;
}
```

---

### 1.3 Desired Dosage Per Injection (mg)
**Current:** No range checking  
**Required Validation:**
- ✅ **Required:** Cannot be null or empty
- ✅ **Range:** 0.1mg - 50mg (covers most peptides)
- ✅ **Cross-field:** Must be ≤ total peptide mg (can't dose more than you have)
- ✅ **Decimal places:** Max 2 decimal places

**Error Messages:**
- Empty: "Enter desired dosage per injection"
- Too small: "Dosage must be at least 0.1mg"
- Too large: "Dosage cannot exceed 50mg per injection"
- Exceeds vial: "Dosage (Xmg) exceeds vial size (Ymg)"

**Edge Cases:**
- ⚠️ **Micro-dosing:** If < 0.5mg, show warning but allow (e.g., peptides like BPC-157)
- ❌ **Absurd values:** Block 0.0001mg or 500mg

**Implementation:**
```dart
String? _validateDesiredDosage(double? value, double? vialSize) {
  if (value == null) return "Enter desired dosage per injection";
  if (value < 0.1) return "Dosage must be at least 0.1mg";
  if (value > 50) return "Dosage cannot exceed 50mg (check your units)";
  if (vialSize != null && value > vialSize) {
    return "Dosage ($value mg) exceeds vial size ($vialSize mg)";
  }
  if (value < 0.5) return "⚠️ Micro-dose detected (< 0.5mg). Is this correct?";
  return null;
}
```

---

### 1.4 Draw Per Injection (ml)
**Current:** No range checking  
**Required Validation:**
- ✅ **Required:** Cannot be null or empty
- ✅ **Range:** 0.05ml - 1.0ml (standard syringe capacity)
- ✅ **Typical range:** 0.1ml - 0.5ml (most common)
- ✅ **Decimal places:** Max 3 decimal places (0.125ml)

**Error Messages:**
- Empty: "Enter draw volume in ml"
- Too small: "Draw must be at least 0.05ml (50 units)"
- Too large: "Draw cannot exceed 1.0ml per injection"
- Outside typical: "⚠️ Unusual draw volume (typical: 0.1-0.5ml)"

**Edge Cases:**
- ⚠️ **Very small draws:** < 0.1ml (50 units) - difficult to measure accurately
- ❌ **Absurd:** 0.001ml or 5ml

**Implementation:**
```dart
String? _validateDrawVolume(double? value) {
  if (value == null) return "Enter draw volume in ml";
  if (value < 0.05) return "Draw must be at least 0.05ml (50 units on syringe)";
  if (value > 1.0) return "Draw cannot exceed 1.0ml per injection";
  if (value < 0.1 || value > 0.5) {
    return "⚠️ Unusual draw volume (typical: 0.1-0.5ml). Is this correct?";
  }
  return null;
}
```

---

### 1.5 Cycle Duration (Weeks)
**Current:** No range checking  
**Required Validation:**
- ✅ **Required:** Cannot be null or empty
- ✅ **Range:** 1 - 52 weeks (1 week min, 1 year max)
- ✅ **Recommended:** 4-12 weeks (most peptide cycles)
- ✅ **Integer only:** No partial weeks (use days if needed)

**Error Messages:**
- Empty: "Enter cycle duration in weeks"
- Too short: "Cycle must be at least 1 week"
- Too long: "Cycle cannot exceed 52 weeks (1 year)"
- Outside typical: "⚠️ Cycle duration outside typical range (4-12 weeks)"

**Edge Cases:**
- ⚠️ **Very long cycles:** > 12 weeks - warn user about long-term peptide use
- ⚠️ **Very short:** < 4 weeks - may not see results

**Implementation:**
```dart
String? _validateCycleDuration(int? weeks) {
  if (weeks == null) return "Enter cycle duration in weeks";
  if (weeks < 1) return "Cycle must be at least 1 week";
  if (weeks > 52) return "Cycle cannot exceed 52 weeks (1 year)";
  if (weeks > 12) return "⚠️ Long cycle (> 12 weeks). Ensure this is intended.";
  if (weeks < 4) return "⚠️ Short cycle (< 4 weeks). May limit effectiveness.";
  return null;
}
```

---

### 1.6 Start Date
**Current:** Defaults to today, no validation  
**Required Validation:**
- ✅ **Required:** Cannot be null
- ✅ **Range:** Cannot be in the past (> yesterday)
- ✅ **Max future:** Reasonable limit (e.g., < 1 year from now)

**Error Messages:**
- Past date: "Start date cannot be in the past"
- Too far future: "Start date cannot be more than 1 year from now"

**Edge Cases:**
- ✅ **Allow today:** User may start cycle immediately
- ⚠️ **Far future:** Warn if > 30 days away (may forget)

**Implementation:**
```dart
String? _validateStartDate(DateTime? date) {
  if (date == null) return "Select a start date";
  final now = DateTime.now();
  final yesterday = now.subtract(Duration(days: 1));
  if (date.isBefore(yesterday)) return "Start date cannot be in the past";
  if (date.isAfter(now.add(Duration(days: 365)))) {
    return "Start date cannot be more than 1 year from now";
  }
  if (date.isAfter(now.add(Duration(days: 30)))) {
    return "⚠️ Start date is more than 30 days away. Is this correct?";
  }
  return null;
}
```

---

### 1.7 Phase Validation

#### 1.7.1 At Least One Phase Required
**Current:** Auto-adds plateau if none exist, but allows empty phases  
**Required Validation:**
- ✅ **Minimum:** At least 1 phase (plateau, ramp_up, or ramp_down)
- ✅ **Recommended:** Full 3-phase cycle (ramp_up → plateau → ramp_down)

**Error Messages:**
- No phases: "Add at least one phase (Taper Up, Plateau, or Taper Down)"
- Only ramps: "⚠️ No plateau phase. This will skip maintenance dosing."

**Implementation:**
```dart
String? _validatePhases(List<DosePhase> phases) {
  if (phases.isEmpty) return "Add at least one phase (Taper Up, Plateau, or Taper Down)";
  final hasPlateau = phases.any((p) => p.type == 'plateau');
  if (!hasPlateau) return "⚠️ No plateau phase detected. Add one for maintenance dosing.";
  return null;
}
```

#### 1.7.2 Phase Duration Validation
**Current:** Phases can exceed cycle duration  
**Required Validation:**
- ✅ **Each phase:** ≥ 1 day
- ✅ **Total phases:** Sum of ramp_up + plateau + ramp_down ≤ cycle duration
- ✅ **No gaps:** Phases should be contiguous (no gaps between)
- ✅ **No overlaps:** Phases should not overlap

**Error Messages:**
- Too short: "Phase must be at least 1 day"
- Exceeds cycle: "Phase durations (X days) exceed cycle duration (Y days)"
- Gaps detected: "Gap detected between phases (X days unscheduled)"
- Overlaps detected: "Phases overlap (check dates)"

**Implementation:**
```dart
String? _validatePhaseDurations(List<DosePhase> phases, int cycleDurationDays) {
  int totalDays = 0;
  for (final phase in phases) {
    final phaseDays = phase.durationDays;
    if (phaseDays < 1) return "Phase '${phase.type}' must be at least 1 day";
    totalDays += phaseDays;
  }
  
  if (totalDays > cycleDurationDays) {
    return "Phase durations ($totalDays days) exceed cycle duration ($cycleDurationDays days)";
  }
  
  // Check for gaps (allow if user wants gaps, but warn)
  if (totalDays < cycleDurationDays - 1) {
    final gap = cycleDurationDays - totalDays;
    return "⚠️ $gap day(s) not scheduled. Is this intentional?";
  }
  
  return null;
}
```

#### 1.7.3 Phase Dosage Validation
**Current:** No validation on phase dosages  
**Required Validation:**
- ✅ **Ramp up:** Should be ≤ plateau dosage
- ✅ **Ramp down:** Should be ≤ plateau dosage
- ✅ **Plateau:** Should match desired dosage
- ✅ **All phases:** Should be > 0 and ≤ vial size

**Error Messages:**
- Ramp up too high: "⚠️ Ramp up dosage (Xmg) exceeds plateau (Ymg)"
- Ramp down too high: "⚠️ Ramp down dosage (Xmg) exceeds plateau (Ymg)"
- Dosage mismatch: "⚠️ Plateau dosage (Xmg) doesn't match desired (Ymg)"

**Implementation:**
```dart
String? _validatePhaseDosages(List<DosePhase> phases, double desiredDosage) {
  final plateau = phases.firstWhere((p) => p.type == 'plateau', orElse: () => null);
  final plateauDose = plateau?.dosage ?? desiredDosage;
  
  for (final phase in phases) {
    if (phase.dosage <= 0) return "Phase '${phase.type}' dosage must be > 0mg";
    
    if (phase.type == 'taper_up' && phase.dosage > plateauDose) {
      return "⚠️ Ramp up (${phase.dosage}mg) exceeds plateau ($plateauDose mg)";
    }
    
    if (phase.type == 'taper_down' && phase.dosage > plateauDose) {
      return "⚠️ Ramp down (${phase.dosage}mg) exceeds plateau ($plateauDose mg)";
    }
  }
  
  return null;
}
```

---

### 1.8 Frequency Validation
**Current:** No validation for frequency vs cycle duration  
**Required Validation:**
- ✅ **Daily:** Always valid
- ✅ **3x/week:** Cycle must be ≥ 1 week
- ✅ **1x/week:** Cycle must be ≥ 1 week
- ✅ **Cross-check:** Total injections should make sense

**Error Messages:**
- Mismatch: "3x/week requires at least 1 week cycle duration"
- Too few injections: "Only X injections scheduled over Y weeks (unusually low)"

**Implementation:**
```dart
String? _validateFrequency(String frequency, int cycleDurationWeeks) {
  if (frequency == '3x/week' && cycleDurationWeeks < 1) {
    return "3x/week requires at least 1 week cycle duration";
  }
  if (frequency == '1x/week' && cycleDurationWeeks < 1) {
    return "1x/week requires at least 1 week cycle duration";
  }
  return null;
}
```

---

## 2. Validation Strategy

### 2.1 When to Validate

**Option A: Real-time (On Change) ✅ RECOMMENDED**
- **Pros:**
  - Immediate feedback
  - User corrects errors as they type
  - Less frustrating than batch errors at submit
- **Cons:**
  - Can be annoying if errors show too early
  - More complex to implement

**Option B: On Blur (Field Exit)**
- **Pros:**
  - Less intrusive than on-change
  - Still provides quick feedback
- **Cons:**
  - Delayed feedback
  - User may miss errors if they tab through

**Option C: On Submit Only**
- **Pros:**
  - Simplest to implement
  - No distractions during input
- **Cons:**
  - All errors shown at once (overwhelming)
  - User must re-navigate to fix each error
  - Poor UX

### 2.2 Recommended Hybrid Approach

**Phase 1: On-change validation for critical fields**
- Vial size, desired dosage, draw volume
- Show errors immediately if value is absurd (e.g., 0, negative)

**Phase 2: On-blur validation for complex fields**
- Phase durations (cross-field validation)
- Cycle dates

**Phase 3: On-submit validation for everything**
- Final validation pass before submission
- Catch any missed errors
- Show first error + count (e.g., "3 errors found. Fix to continue.")

---

### 2.3 Error Display Strategy

**Option A: Inline Messages (Below Field) ✅ RECOMMENDED**
- **UI:** Red text below input field
- **Pros:** Contextual, clear what's wrong
- **Cons:** Takes vertical space

**Option B: Snackbar (Bottom of Screen)**
- **UI:** Toast-style popup at bottom
- **Pros:** Non-intrusive, temporary
- **Cons:** Easy to miss, not contextual

**Option C: Bottom Sheet (Modal)**
- **UI:** Full-screen modal with all errors listed
- **Pros:** Forces user to acknowledge errors
- **Cons:** Interrupts flow, annoying for 1 error

**Recommended: Combination**
- **Inline errors** for individual field validation
- **Snackbar** for success messages ("Cycle created!")
- **Bottom sheet** only if ≥ 3 errors at submit (show list)

---

### 2.4 Button State Management

**Current:** CREATE CYCLE button always enabled  
**Recommendation:** Disable until form is valid

**Implementation:**
```dart
bool get _isFormValid {
  return _selectedPeptide != null &&
         _validateVialSize(_totalPeptideMg) == null &&
         _validateDesiredDosage(_desiredDosageMg, _totalPeptideMg) == null &&
         _validateDrawVolume(_concentrationMl) == null &&
         _validateCycleDuration(_cycleDurationWeeks) == null &&
         _validateStartDate(_startDate) == null &&
         _validatePhases(_phases) == null;
}

// Button
ElevatedButton(
  onPressed: _isFormValid ? _submit : null,  // Disable if invalid
  style: ElevatedButton.styleFrom(
    backgroundColor: _isFormValid ? AppColors.primary : AppColors.textDim,
  ),
  child: Text('CREATE CYCLE'),
)
```

**Visual Feedback:**
- **Enabled (valid):** Bright cyan, clickable
- **Disabled (invalid):** Gray, with tooltip "Fix errors to continue"

---

## 3. User Experience Recommendations

### 3.1 Error Message Appearance

**When:**
- ❌ **NOT on first focus:** Don't show "Required" before user types
- ✅ **On change (if value invalid):** Show immediately if absurd (e.g., negative)
- ✅ **On blur (if value invalid):** Show after user leaves field
- ✅ **On submit:** Show all errors if form is invalid

**Color Coding:**
- 🔴 **Red border + red text:** Critical error (blocks submit)
- 🟡 **Yellow border + orange text:** Warning (allows submit, but suspicious)
- 🟢 **Green checkmark:** Field valid (optional, for confidence)

**Example:**
```dart
// Error state
TextField(
  decoration: InputDecoration(
    labelText: 'VIAL SIZE (mg)',
    errorText: _vialSizeError,  // "Vial size must be between 5mg and 500mg"
    errorStyle: TextStyle(color: Color(0xFFFF0040)),
    border: OutlineInputBorder(
      borderSide: BorderSide(
        color: _vialSizeError != null ? Color(0xFFFF0040) : AppColors.textMid
      ),
    ),
  ),
)
```

---

### 3.2 Helper Text (Proactive Guidance)

**Add gray helper text below EVERY field:**

| Field | Helper Text |
|-------|-------------|
| Vial Size | "Typical: 5-50mg. Check your vial label." |
| Desired Dosage | "Typical: 0.5-5mg per injection. Consult dosing guide." |
| Draw Volume | "Typical: 0.1-0.5ml (10-50 units on syringe)" |
| Cycle Duration | "Recommended: 4-12 weeks for most peptides" |
| Phase Duration | "Ramp up/down: 7-14 days typical" |

**Implementation:**
```dart
TextField(
  decoration: InputDecoration(
    labelText: 'VIAL SIZE (mg)',
    hintText: 'e.g., 10',
    helperText: 'Typical: 5-50mg. Check your vial label.',
    helperStyle: TextStyle(color: AppColors.textMid, fontSize: 11),
  ),
)
```

---

### 3.3 Success Indicators (Optional)

**Show green checkmark when field is valid:**
- ✅ Builds user confidence
- ✅ Clear visual progress through form
- ❌ Can be distracting if overused

**Recommendation:** Use ONLY for complex fields
- Reconstitution calculation (show checkmark + "BAC: 2.0ml")
- Phase validation (show checkmark + "3 phases, 28 days total")

---

## 4. Edge Cases & Special Scenarios

### 4.1 Micro-dosing (Very Small Dosages)

**Scenario:** User enters 0.25mg dosage for BPC-157  
**Validation:**
- ✅ Allow (valid use case)
- ⚠️ Show warning: "Micro-dose detected (< 0.5mg). Ensure accurate measurement."

### 4.2 High-dose Peptides

**Scenario:** User enters 20mg dosage for collagen peptide  
**Validation:**
- ✅ Allow (valid for some peptides)
- ⚠️ Show warning: "High dose (> 10mg). Verify this is correct."

### 4.3 Very Long Cycles

**Scenario:** User creates 26-week (6-month) cycle  
**Validation:**
- ✅ Allow (valid for long-term therapy)
- ⚠️ Show warning: "Long cycle (> 12 weeks). Consider periodic blood work."

### 4.4 Phase Duration Mismatch

**Scenario:** User sets ramp_up=7, plateau=14, ramp_down=7, but cycle=30 days  
**Calculation:** 7+14+7 = 28 days (2 days unscheduled)  
**Validation:**
- ✅ Allow (maybe user wants 2 rest days at end)
- ⚠️ Show warning: "2 days not scheduled. Is this intentional?"

### 4.5 Editing Active Cycles

**Scenario:** User tries to edit a cycle that has already started  
**Current:** No protection  
**Recommendation:**
- ❌ Block editing if doses have been logged
- ✅ Allow editing future doses only
- ⚠️ Show warning: "Cycle is active. Changes will only affect future doses."

**Implementation:**
```dart
if (cycleHasStarted && hasLoggedDoses) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cannot Edit Active Cycle'),
      content: Text('This cycle has logged doses. Create a new cycle instead.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
  return;
}
```

---

## 5. Sample Error Messages (Copy-Paste Ready)

### Critical Errors (Red, Block Submit)
- "Please select a peptide to continue"
- "Vial size must be between 5mg and 500mg"
- "Dosage must be at least 0.1mg"
- "Dosage (10mg) exceeds vial size (5mg)"
- "Draw must be at least 0.05ml (50 units)"
- "Draw cannot exceed 1.0ml per injection"
- "Cycle must be at least 1 week"
- "Cycle cannot exceed 52 weeks (1 year)"
- "Start date cannot be in the past"
- "Add at least one phase (Taper Up, Plateau, or Taper Down)"
- "Phase durations (35 days) exceed cycle duration (28 days)"
- "Phase 'taper_up' must be at least 1 day"

### Warnings (Yellow, Allow Submit)
- "⚠️ Unusually small vial (< 5mg). Is this correct?"
- "⚠️ Micro-dose detected (< 0.5mg). Ensure accurate measurement."
- "⚠️ High dose (> 10mg). Verify this is correct."
- "⚠️ Unusual draw volume (typical: 0.1-0.5ml). Is this correct?"
- "⚠️ Draw < 0.1ml (100 units) may be difficult to measure accurately"
- "⚠️ Long cycle (> 12 weeks). Ensure this is intended."
- "⚠️ Short cycle (< 4 weeks). May limit effectiveness."
- "⚠️ Start date is more than 30 days away. Is this correct?"
- "⚠️ No plateau phase detected. Add one for maintenance dosing."
- "⚠️ Ramp up (1.5mg) exceeds plateau (1.0mg)"
- "⚠️ 2 day(s) not scheduled. Is this intentional?"

### Success Messages (Green, Snackbar)
- "✅ Cycle created! Check Calendar for doses."
- "✅ Add 2.0ml BAC | 1.0mg per 0.2ml draw"
- "✅ 28-day cycle scheduled (84 total injections)"

---

## 6. Implementation Checklist

### Phase 1: Basic Field Validation (2-3 hours)
- [ ] Add validation helper functions to `_CycleSetupFormV4State`
- [ ] Add `_vialSizeError`, `_desiredDosageError`, etc. state variables
- [ ] Update `TextField` `onChanged` handlers to call validation
- [ ] Add `errorText` parameter to each `TextField`
- [ ] Test with edge cases (0, negative, huge numbers)

### Phase 2: Cross-field Validation (2-3 hours)
- [ ] Implement `_validatePhaseDurations()`
- [ ] Implement `_validatePhaseDosages()`
- [ ] Add cycle duration vs phase duration check
- [ ] Add dosage vs vial size check
- [ ] Test with complex phase configurations

### Phase 3: Button State Management (1 hour)
- [ ] Add `_isFormValid` getter
- [ ] Update CREATE CYCLE button `onPressed` logic
- [ ] Add visual disabled state (gray)
- [ ] Test form submission with invalid data

### Phase 4: Helper Text & Warnings (1-2 hours)
- [ ] Add `helperText` to all TextFields
- [ ] Implement warning messages (yellow, allow submit)
- [ ] Add success indicators (optional)
- [ ] Polish UI/UX

### Phase 5: Edge Cases & Testing (2-3 hours)
- [ ] Test micro-dosing (< 0.5mg)
- [ ] Test high-dose peptides (> 10mg)
- [ ] Test long cycles (> 12 weeks)
- [ ] Test phase duration mismatches
- [ ] Test editing active cycles (block or warn)

---

## 7. Testing Scenarios

| Scenario | Input | Expected |
|----------|-------|----------|
| **Valid cycle** | BPC-157, 10mg vial, 1mg dose, 0.2ml draw, 4 weeks | ✅ Submit succeeds |
| **Zero vial size** | 0mg vial | ❌ "Vial size must be between 5mg and 500mg" |
| **Negative dosage** | -1mg dosage | ❌ "Dosage must be at least 0.1mg" |
| **Dosage > vial** | 10mg dose, 5mg vial | ❌ "Dosage (10mg) exceeds vial size (5mg)" |
| **Huge draw** | 5ml draw | ❌ "Draw cannot exceed 1.0ml per injection" |
| **100-week cycle** | 100 weeks | ❌ "Cycle cannot exceed 52 weeks (1 year)" |
| **Past start date** | Yesterday | ❌ "Start date cannot be in the past" |
| **No phases** | Empty phases list | ❌ "Add at least one phase" |
| **Phases exceed cycle** | 40 days of phases, 28-day cycle | ❌ "Phase durations (40 days) exceed cycle duration (28 days)" |
| **Micro-dose** | 0.25mg BPC-157 | ⚠️ "Micro-dose detected (< 0.5mg)" (allow) |
| **Long cycle** | 20 weeks | ⚠️ "Long cycle (> 12 weeks)" (allow) |

---

## 8. Performance Considerations

**Validation Performance:**
- ✅ **Fast:** All validations are O(1) or O(n) where n = number of phases (< 10)
- ✅ **Non-blocking:** Validation runs synchronously, no async calls
- ✅ **Debouncing:** For on-change validation, debounce by 300ms to avoid spam

**Debounce Implementation:**
```dart
Timer? _validationTimer;

void _onFieldChanged(String value) {
  _validationTimer?.cancel();
  _validationTimer = Timer(Duration(milliseconds: 300), () {
    setState(() {
      _vialSizeError = _validateVialSize(double.tryParse(value));
    });
  });
}
```

---

## 9. Success Metrics

**How to measure if validation is working:**

1. **User Submission Success Rate**
   - Target: > 95% of cycles created successfully on first try
   - Metric: `(successful_submits / total_submit_attempts) * 100`

2. **Error Correction Time**
   - Target: < 10 seconds to fix validation error
   - Metric: Time from error shown → field corrected

3. **Support Tickets**
   - Target: < 5% of tickets related to invalid data
   - Metric: Count of "I created a cycle but it's broken" tickets

4. **User Feedback**
   - Target: "Form is clear and helpful" (survey)
   - Metric: Post-feature NPS score

---

## 10. Future Enhancements (Not Phase 10C)

**Phase 11+:**
- [ ] Smart defaults based on peptide (e.g., BPC-157 → suggest 1mg/day, 0.2ml draw)
- [ ] Peptide-specific dosing guides (link to database)
- [ ] Advanced validation: Check if reconstitution math is correct
- [ ] Historical data: "You've used 0.5mg before for this peptide"
- [ ] Import from QR code (scan vial label)
- [ ] Voice input for hands-free cycle creation

---

**Document Version:** 1.0  
**Last Updated:** 2026-03-10  
**Next Review:** After Phase 10C implementation
